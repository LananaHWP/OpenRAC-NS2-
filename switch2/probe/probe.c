// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// Memory-layout probe for the OpenRAC Switch 2 port: what address-space and mapping calls this console allows.
// Writes sdmc:/switch/openrac-probe/log.txt. Reads/writes only the SD card.
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <switch.h>
#include <time.h>
#include <math.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glext.h>

static FILE* g;
static void say(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(g, fmt, ap);
    va_end(ap);
    fputc('\n', g);
    fflush(g);
}

static void info(const char* name, u32 id) {
    u64 v = 0;
    Result rc = svcGetInfo(&v, id, CUR_PROCESS_HANDLE, 0);
    say("info %-22s = 0x%016llx (rc 0x%x)", name, (unsigned long long)v, rc);
}


// 5. OpenGL 4.1 core through EGL on the default window (what OpenRAC's renderer needs)
static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

static void gl_test(void) {
    EGLDisplay dpy = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    say("eglGetDisplay = %p", dpy);
    EGLint maj = 0, min = 0;
    if (!eglInitialize(dpy, &maj, &min)) { say("eglInitialize failed 0x%x", eglGetError()); return; }
    say("EGL %d.%d vendor '%s' version '%s'", maj, min, eglQueryString(dpy, EGL_VENDOR), eglQueryString(dpy, EGL_VERSION));
    say("EGL apis '%s'", eglQueryString(dpy, EGL_CLIENT_APIS));
    if (!eglBindAPI(EGL_OPENGL_API)) { say("eglBindAPI(OPENGL) failed 0x%x", eglGetError()); return; }
    EGLint cfg_attr[] = {EGL_SURFACE_TYPE, EGL_WINDOW_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_BIT, EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8,
                         EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_DEPTH_SIZE, 24, EGL_STENCIL_SIZE, 8, EGL_NONE};
    EGLConfig cfg; EGLint n = 0;
    if (!eglChooseConfig(dpy, cfg_attr, &cfg, 1, &n) || n < 1) { say("eglChooseConfig failed 0x%x n=%d", eglGetError(), n); return; }
    EGLSurface surf = eglCreateWindowSurface(dpy, cfg, nwindowGetDefault(), NULL);
    say("eglCreateWindowSurface = %p (err 0x%x)", surf, eglGetError());
    if (surf == EGL_NO_SURFACE) return;
    EGLint ctx_attr[] = {EGL_CONTEXT_MAJOR_VERSION, 4, EGL_CONTEXT_MINOR_VERSION, 1, EGL_CONTEXT_OPENGL_PROFILE_MASK, EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT, EGL_NONE};
    EGLContext ctx = eglCreateContext(dpy, cfg, EGL_NO_CONTEXT, ctx_attr);
    say("eglCreateContext(4.1 core) = %p (err 0x%x)", ctx, eglGetError());
    if (ctx == EGL_NO_CONTEXT) return;
    if (!eglMakeCurrent(dpy, surf, surf, ctx)) { say("eglMakeCurrent failed 0x%x", eglGetError()); return; }
    say("GL_VERSION  '%s'", (const char*)glGetString(GL_VERSION));
    say("GL_RENDERER '%s'", (const char*)glGetString(GL_RENDERER));
    say("GL_VENDOR   '%s'", (const char*)glGetString(GL_VENDOR));
    say("GLSL        '%s'", (const char*)glGetString(GL_SHADING_LANGUAGE_VERSION));
    GLint v = 0;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &v); say("GL_MAX_TEXTURE_SIZE %d", v);
    glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &v); say("GL_MAX_COLOR_ATTACHMENTS %d", v);
    glGetIntegerv(GL_NUM_EXTENSIONS, &v); say("GL_NUM_EXTENSIONS %d", v);
    eglSwapInterval(dpy, 1);
    // a shader pair: how long does a compile + link take through this driver?
    const char* vs = "#version 410 core\nlayout(location=0) in vec2 p; out vec2 uv; void main(){ uv = p*0.5+0.5; gl_Position = vec4(p,0.,1.); }\n";
    const char* fs = "#version 410 core\nin vec2 uv; out vec4 c; uniform sampler2D t; uniform vec4 k; void main(){ vec4 a = texture(t, uv); for (int i=0;i<8;i++) a = a*0.9 + k*sin(a*float(i)); c = a; }\n";
    double t0 = now_ms();
    GLuint pv = glCreateShader(GL_VERTEX_SHADER), pf = glCreateShader(GL_FRAGMENT_SHADER), pr = glCreateProgram();
    glShaderSource(pv, 1, &vs, NULL); glCompileShader(pv);
    glShaderSource(pf, 1, &fs, NULL); glCompileShader(pf);
    glAttachShader(pr, pv); glAttachShader(pr, pf); glLinkProgram(pr);
    GLint ok = 0; glGetProgramiv(pr, GL_LINK_STATUS, &ok);
    glFinish();
    say("shader compile+link %.1f ms, link status %d", now_ms() - t0, ok);
    // frames: flash red / green / blue for ~3 s each at the display rate, and time them
    double start = now_ms();
    int frames = 0;
    for (int i = 0; i < 360; i++) {
        float c[3] = {0, 0, 0};
        c[(i / 120) % 3] = 1.0f;
        glClearColor(c[0], c[1], c[2], 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        eglSwapBuffers(dpy, surf);
        frames++;
        if (i == 119 || i == 239 || i == 359) { double t = now_ms(); say("%d frames in %.1f ms = %.1f fps", frames, t - start, frames * 1000.0 / (t - start)); start = t; frames = 0; }
    }
    eglMakeCurrent(dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroySurface(dpy, surf);
    eglDestroyContext(dpy, ctx);
    eglTerminate(dpy);
    say("gl test done");
}

int main(int argc, char** argv) {
    mkdir("sdmc:/switch/openrac-probe", 0777);
    g = fopen("sdmc:/switch/openrac-probe/log.txt", "w");
    if (!g) return 1;
    say("openrac probe start");
    info("AliasRegionAddress", InfoType_AliasRegionAddress);
    info("AliasRegionSize", InfoType_AliasRegionSize);
    info("HeapRegionAddress", InfoType_HeapRegionAddress);
    info("HeapRegionSize", InfoType_HeapRegionSize);
    info("TotalMemorySize", InfoType_TotalMemorySize);
    info("UsedMemorySize", InfoType_UsedMemorySize);
    info("AslrRegionAddress", InfoType_AslrRegionAddress);
    info("AslrRegionSize", InfoType_AslrRegionSize);
    info("StackRegionAddress", InfoType_StackRegionAddress);
    info("StackRegionSize", InfoType_StackRegionSize);
    info("SystemResourceSizeTotal", InfoType_SystemResourceSizeTotal);
    info("SystemResourceSizeUsed", InfoType_SystemResourceSizeUsed);

    // 1. a 4 GB address reservation
    virtmemLock();
    void* base = virtmemFindAslr(0x100000000ull, 0);
    say("virtmemFindAslr(4GB) = %p", base);
    VirtmemReservation* rv = base ? virtmemAddReservation(base, 0x100000000ull) : NULL;
    virtmemUnlock();
    say("reservation %p", (void*)rv);

    // 2. svcMapPhysicalMemory inside the reservation (sparse map of new memory at fixed offsets)
    if (base) {
        struct { const char* n; u64 off; u64 size; } t[] = {
            {"RAM 32MB at +0", 0, 0x2000000}, {"regs 64K at +0x10000000", 0x10000000, 0x10000},
            {"scratchpad 16K at +0x70000000", 0x70000000, 0x4000}, {"port 16MB at +0xE0000000", 0xE0000000, 0x1000000},
        };
        for (int i = 0; i < 4; i++) {
            void* a = (char*)base + t[i].off;
            Result rc = svcMapPhysicalMemory(a, t[i].size);
            say("svcMapPhysicalMemory %-30s at %p -> rc 0x%x", t[i].n, a, rc);
            if (R_SUCCEEDED(rc)) {
                memset(a, 0xA5, t[i].size < 0x10000 ? t[i].size : 0x10000);
                say("  wrote ok, first byte 0x%02x", *(volatile unsigned char*)a);
            }
        }
    }

    // 3. svcMapMemory into the stack region from a heap block
    {
        void* heap = NULL;
        u64 cur = 0;
        svcGetInfo(&cur, InfoType_HeapRegionAddress, CUR_PROCESS_HANDLE, 0);
        u64 hsz = 0;
        Result rc = svcSetHeapSize(&heap, 0x4000000);
        say("svcSetHeapSize(64MB) -> rc 0x%x heap=%p", rc, heap);
        u64 sa = 0, ss = 0;
        svcGetInfo(&sa, InfoType_StackRegionAddress, CUR_PROCESS_HANDLE, 0);
        svcGetInfo(&ss, InfoType_StackRegionSize, CUR_PROCESS_HANDLE, 0);
        if (R_SUCCEEDED(rc) && heap && ss) {
            memset(heap, 0x5A, 0x10000);
            void* dst = (void*)(sa + 0x10000000ull);
            rc = svcMapMemory(dst, heap, 0x2000);
            say("svcMapMemory dst %p src %p size 8K -> rc 0x%x", dst, heap, rc);
            if (R_SUCCEEDED(rc)) {
                say("  dst first byte 0x%02x", *(volatile unsigned char*)dst);
                svcUnmapMemory(dst, heap, 0x2000);
            }
        }
        (void)hsz;
    }

    // 4. how much heap can be committed
    {
        u64 sizes[] = {0x20000000ull, 0x40000000ull, 0x80000000ull, 0xC0000000ull, 0x100000000ull};
        for (int i = 0; i < 5; i++) {
            void* heap = NULL;
            Result rc = svcSetHeapSize(&heap, sizes[i]);
            say("svcSetHeapSize(0x%llx) -> rc 0x%x", (unsigned long long)sizes[i], rc);
            if (R_FAILED(rc)) break;
        }
        info("TotalMemorySize(after)", InfoType_TotalMemorySize);
        info("UsedMemorySize(after)", InfoType_UsedMemorySize);
    }
    gl_test();
    say("probe done");
    fclose(g);
    return 0;
}
