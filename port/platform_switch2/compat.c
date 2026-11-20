// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// OpenRAC on Switch 2: the few POSIX calls Horizon's libc lacks and the port only uses for diagnostics or optional features.
// Nothing here touches any storage.
#include <errno.h>
#include <stddef.h>
#include <string.h>
#include <switch.h>
#include <EGL/egl.h>
#include "dlfcn.h"
#include "execinfo.h"
#include "sys/sysinfo.h"

static const char* g_dl_error = "dynamic loading is not available on this platform";

// Dear ImGui's GL loader (imgui_impl_opengl3_loader.h) finds its functions through libGL's glXGetProcAddressARB: here that name is
// an EGL lookup. "libGL" opens to a marker; everything else fails.
static void* gl_proc_address(const unsigned char* name) {
    return (void*)eglGetProcAddress((const char*)name);
}
static char g_libgl_marker;

void* dlopen(const char* file, int mode) {
    (void)mode;
    if (file != NULL && strstr(file, "libGL") != NULL) {
        return &g_libgl_marker;
    }
    return NULL;
}
void* dlsym(void* handle, const char* name) {
    if (handle == &g_libgl_marker) {
        if (strcmp(name, "glXGetProcAddressARB") == 0 || strcmp(name, "glXGetProcAddress") == 0) {
            return (void*)gl_proc_address;
        }
        return (void*)eglGetProcAddress(name);
    }
    return NULL;
}
int dlclose(void* handle) {
    (void)handle;
    return 0;
}
char* dlerror(void) {
    return (char*)g_dl_error;
}
int dladdr(const void* addr, Dl_info* info) {
    (void)addr;
    if (info) memset(info, 0, sizeof(*info));
    return 0;
}

int backtrace(void** buffer, int size) {
    (void)buffer;
    (void)size;
    return 0;
}
char** backtrace_symbols(void* const* buffer, int size) {
    (void)buffer;
    (void)size;
    return NULL;
}
void backtrace_symbols_fd(void* const* buffer, int size, int fd) {
    (void)buffer;
    (void)size;
    (void)fd;
}

int sysinfo(struct sysinfo* info) {
    u64 total = 0, used = 0;
    if (!info) {
        errno = EINVAL;
        return -1;
    }
    memset(info, 0, sizeof(*info));
    svcGetInfo(&total, InfoType_TotalMemorySize, CUR_PROCESS_HANDLE, 0);
    svcGetInfo(&used, InfoType_UsedMemorySize, CUR_PROCESS_HANDLE, 0);
    info->totalram = (unsigned long)total;
    info->freeram = (unsigned long)(total > used ? total - used : 0);
    info->mem_unit = 1;
    return 0;
}

#include "sys/utsname.h"
#include "sys/vfs.h"

int uname(struct utsname* name) {
    if (!name) {
        errno = EINVAL;
        return -1;
    }
    memset(name, 0, sizeof(*name));
    strcpy(name->sysname, "Horizon");
    strcpy(name->nodename, "switch2");
    strcpy(name->release, "libounce");
    strcpy(name->version, "OunceDevKit");
    strcpy(name->machine, "aarch64");
    return 0;
}

int statfs(const char* path, struct statfs* buf) {
    (void)path;
    if (buf) memset(buf, 0, sizeof(*buf));
    errno = ENOSYS;
    return -1;
}

#include <unistd.h>

long sysconf(int name) {
    switch (name) {
    case _SC_PAGESIZE:
        return 4096;
    case _SC_NPROCESSORS_ONLN:
    case _SC_NPROCESSORS_CONF:
        return 6; // the cores a program may use (mask 0x3f)
    case _SC_CLK_TCK:
        return 100;
    case _SC_OPEN_MAX:
        return 1024;
    default:
        errno = EINVAL;
        return -1;
    }
}

#include <signal.h>
#include <sys/resource.h>
#include <sys/types.h>

// Process control and signal stacks: a program on Horizon starts no children and has no alternate signal stack.
pid_t waitpid(pid_t pid, int* status, int options) {
    (void)pid;
    (void)status;
    (void)options;
    errno = ECHILD;
    return -1;
}
int execvp(const char* file, char* const argv[]) {
    (void)file;
    (void)argv;
    errno = ENOSYS;
    return -1;
}
int getrusage(int who, struct rusage* usage) {
    (void)who;
    if (usage) memset(usage, 0, sizeof(*usage));
    return 0;
}
int sigaltstack(const stack_t* ss, stack_t* old) {
    (void)ss;
    (void)old;
    errno = ENOSYS;
    return -1;
}

#include <stdarg.h>
#include <stdio.h>
#include <sys/stat.h>
#include <time.h>
#include "trace.h"

// Logging is off unless sdmc:/switch/openrac/debug.txt exists (looked for once, at the first question): then boot.txt and the program's own log are written.
int openrac_switch2_debug(void) {
    static int known = -1;
    if (known < 0) {
        struct stat st;
        known = stat("sdmc:/switch/openrac/debug.txt", &st) == 0 ? 1 : 0;
    }
    return known;
}

void openrac_switch2_trace(const char* fmt, ...) {
    if (!openrac_switch2_debug()) return;
    // One FILE kept open for the whole run, with a buffer of its own: a line costs no allocation, so the trace still works while the
    // allocator or the address space is being rearranged (memory.cpp), and every line is flushed to the card at once.
    static FILE* f;
    static char buffer[1024];
    static int started;
    if (!started) {
        started = 1;
        mkdir("sdmc:/switch", 0777);
        mkdir("sdmc:/switch/openrac", 0777);
        f = fopen("sdmc:/switch/openrac/boot.txt", "w"); // a new start, a new trace
        if (f) setvbuf(f, buffer, _IOFBF, sizeof buffer);
    }
    if (!f) return;
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    fprintf(f, "[%6ld.%03ld] ", (long)ts.tv_sec, ts.tv_nsec / 1000000);
    va_list ap;
    va_start(ap, fmt);
    vfprintf(f, fmt, ap);
    va_end(ap);
    fputc(10, f);
    fflush(f);
}

// rename() onto an existing file fails on Horizon's FAT file system (EEXIST). The port writes a temporary and renames it over the target
// everywhere (settings, saves, logs, mod data), so the target is moved aside first and put back if the rename then fails. libstdc++'s
// std::filesystem::rename and std::rename reach this too (the link wraps the symbol).
#include <unistd.h>
int __real_rename(const char* from, const char* to);
int __wrap_rename(const char* from, const char* to) {
    int rc = __real_rename(from, to);
    if (rc == 0 || (errno != EEXIST && errno != EACCES && errno != EPERM)) {
        return rc;
    }
    struct stat st;
    if (stat(to, &st) != 0 || !S_ISREG(st.st_mode)) {
        return rc;
    }
    char aside[1100];
    snprintf(aside, sizeof aside, "%s.replaced", to);
    unlink(aside);
    if (__real_rename(to, aside) != 0) {
        errno = EEXIST;
        return -1;
    }
    rc = __real_rename(from, to);
    if (rc != 0) {
        int saved = errno;
        __real_rename(aside, to);
        errno = saved;
        return -1;
    }
    unlink(aside);
    return 0;
}

// There is no shell to set OPENRAC_* variables from: sdmc:/switch/openrac/env.txt holds NAME=value lines (for example
// OPENRAC_DUMP_TEXTURES=sdmc:/switch/openrac/dump). common/env.cpp reads the environment once, early (before main, from static initialisers),
// so this is called from there as well as from main.
#include <stdlib.h>
void openrac_switch2_load_env(void) {
    static int done;
    if (done) return;
    done = 1;
    FILE* f = fopen("sdmc:/switch/openrac/env.txt", "r");
    if (f) {
        char line[512];
        while (fgets(line, sizeof line, f) != NULL) {
            char* eq = strchr(line, 0x3d);
            if (eq == NULL || line[0] == 0x23) continue;
            *eq = 0;
            char* value = eq + 1;
            char* end = value + strlen(value);
            while (end > value && (end[-1] == 10 || end[-1] == 13 || end[-1] == 32)) *--end = 0;
            setenv(line, value, 1);
        }
        fclose(f);
    }
}
