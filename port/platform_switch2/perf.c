// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// OpenRAC on Switch 2: the clocks, from what RAC-RS's speed tests on this console found (docs/port/SWITCH2.md):
//  - docked the CPU runs at 998 MHz and in hand at 1100 MHz by default; appletSetCpuBoostMode(FastLoad) lifts it to 1523 MHz, but the
//    system then throttles the GPU to 306 MHz, so the GPU is put back to its own clock (1007 MHz, the docked one, in hand too) and kept
//  - the system resets all of it when the console is docked or undocked: a keeper thread notices and applies it again
//  - in hand the CPU really runs at about half of what the clock service reports (measured 759 MHz at a reported 1523): the game's
//    budget in hand is 760 MHz, docked 1520 MHz; nothing available to a program changes that
//  - memory: the highest step of its list (3750 MHz here) is set too
// Every clock set is a step of the module's own list, and nothing is set above a clock the system itself uses. Files on the SD card:
//    sdmc:/switch/openrac/perf_off.txt     present: touch no clock at all
//    sdmc:/switch/openrac/cpu_max.txt      present: also ask for the CPU's own clock (see try_cpu_clock; the file may name a clock in MHz)
// The answers are logged to the boot trace (sdmc:/switch/openrac/boot.txt).
#include <pthread.h>
#include <stdint.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include <switch.h>

#include "trace.h"

#define GPU_DEFAULT_HZ 1007250000u

static uint32_t read_hz(PcvModuleId id) {
    uint32_t hz = 0;
    ClkrstSession s;
    if (R_SUCCEEDED(clkrstInitialize())) {
        if (R_SUCCEEDED(clkrstOpenSession(&s, id, 3))) {
            if (R_FAILED(clkrstGetClockRate(&s, &hz))) hz = 0;
            clkrstCloseSession(&s);
        }
        clkrstExit();
    }
    return hz;
}

static Result set_hz(PcvModuleId id, uint32_t hz) {
    Result rc = 0xFFFF;
    ClkrstSession s;
    if (R_SUCCEEDED(clkrstInitialize())) {
        if (R_SUCCEEDED(clkrstOpenSession(&s, id, 3))) {
            rc = clkrstSetClockRate(&s, hz);
            clkrstCloseSession(&s);
        }
        clkrstExit();
    }
    return rc;
}

// The highest step of the module's own list (a discrete list, or the top of a range), or 0.
static uint32_t max_step(PcvModuleId id) {
    uint32_t best = 0, rates[64];
    ClkrstSession s;
    if (R_SUCCEEDED(clkrstInitialize())) {
        if (R_SUCCEEDED(clkrstOpenSession(&s, id, 3))) {
            PcvClockRatesListType type = 0;
            s32 n = 0;
            if (R_SUCCEEDED(clkrstGetPossibleClockRates(&s, rates, 64, &type, &n))) {
                if (type == PcvClockRatesListType_Range && n >= 2) {
                    best = rates[1];
                } else {
                    for (s32 i = 0; i < n && i < 64; i++) {
                        if (rates[i] > best) best = rates[i];
                    }
                }
            }
            clkrstCloseSession(&s);
        }
        clkrstExit();
    }
    return best;
}

typedef struct {
    uint32_t gpu, cpu, emc;
} Targets;

static void sleep_ms_for_cpu(void);
static uint32_t g_cpu_forced;  // the clock cpu_max.txt got, asked for again whenever the system takes it back

// What a dependent chain of adds measures: the clock the core really runs at (about 100 ms on the calling thread, not the game's).
static unsigned measured_mhz(void) {
    struct timespec a, b;
    uint64_t x = 0, loops = 0;
    clock_gettime(CLOCK_MONOTONIC, &a);
    do {
        for (int i = 0; i < 4096; i++) {
            __asm__ volatile("add %0, %0, #1; add %0, %0, #1; add %0, %0, #1; add %0, %0, #1; add %0, %0, #1; add %0, %0, #1; add %0, %0, #1; add %0, %0, #1"
                             : "+r"(x));
        }
        loops += 4096 * 8;
        clock_gettime(CLOCK_MONOTONIC, &b);
    } while ((b.tv_sec - a.tv_sec) * 1000000000ll + (b.tv_nsec - a.tv_nsec) < 100000000ll);
    const double ns = (double)((b.tv_sec - a.tv_sec) * 1000000000ll + (b.tv_nsec - a.tv_nsec));
    return (unsigned)((double)loops / ns * 1000.0);
}

// cpu_max.txt on the card (an experiment, off without it): the CPU's own clock is asked for directly, as a melonDS port for this console does,
// from the highest of these down to the first the system takes (the file may hold a clock in MHz to try first).
static uint32_t try_cpu_clock(void) {
    FILE* f = fopen(OPENRAC_S2_HOME "/cpu_max.txt", "r");
    if (f == NULL) return 0;
    unsigned wanted_mhz = 0;
    if (fscanf(f, "%u", &wanted_mhz) != 1) wanted_mhz = 0;
    fclose(f);
    static const uint32_t rates[] = {1785000000u, 1683000000u, 1581000000u, 1326000000u, 1224000000u, 1020000000u};
    uint32_t list[8];
    int n = 0;
    if (wanted_mhz >= 100 && wanted_mhz <= 3000) list[n++] = wanted_mhz * 1000000u;
    for (unsigned i = 0; i < sizeof rates / sizeof rates[0] && n < 8; i++) list[n++] = rates[i];
    const unsigned before = measured_mhz();
    for (int i = 0; i < n; i++) {
        const Result rc = set_hz(PcvModuleId_CpuBus, list[i]);
        openrac_switch2_trace("perf: cpu_max.txt: asked for %u MHz: rc %#x", list[i] / 1000000, (unsigned)rc);
        if (R_SUCCEEDED(rc)) {
            sleep_ms_for_cpu();
            const uint32_t now = read_hz(PcvModuleId_CpuBus);
            openrac_switch2_trace("perf: cpu_max.txt: the clock service says %u MHz; measured %u MHz before, %u MHz now", now / 1000000, before, measured_mhz());
            // What the system took (it clamps to its own highest step: 1785 MHz asked, 1702 MHz kept), not what was asked: asking for the
            // clock it kept again every second made the clocks change every second, and the GPU was lost at the start of a run.
            g_cpu_forced = now > 100000000u ? now : list[i];
            return list[i];
        }
    }
    openrac_switch2_trace("perf: cpu_max.txt: no clock was taken; measured %u MHz", before);
    return 0;
}

static void sleep_ms(unsigned ms) {
    usleep(ms * 1000u);
}
static void sleep_ms_for_cpu(void) {
    usleep(300000u);
}

// Cancels the boost for a moment to read the system's own GPU clock, then boosts and puts the clocks where they belong.
static Targets apply(const char* why) {
    Targets t = {0, 0, 0};
    appletSetCpuBoostMode(ApmCpuBoostMode_Normal);
    sleep_ms(1500);
    const uint32_t natural_gpu = read_hz(PcvModuleId_GPU);
    const uint32_t natural_cpu = read_hz(PcvModuleId_CpuBus);
    t.gpu = natural_gpu > GPU_DEFAULT_HZ ? natural_gpu : GPU_DEFAULT_HZ;
    const Result rc = appletSetCpuBoostMode(ApmCpuBoostMode_FastLoad);
    sleep_ms(300);
    t.cpu = read_hz(PcvModuleId_CpuBus);
    t.emc = max_step(PcvModuleId_EMC);
    const Result rg = set_hz(PcvModuleId_GPU, t.gpu);
    const Result re = t.emc ? set_hz(PcvModuleId_EMC, t.emc) : 0xFFFF;
    openrac_switch2_trace("perf: %s: natural cpu %u MHz gpu %u MHz; boost rc %#x -> cpu %u MHz; gpu set %u MHz rc %#x; emc set %u MHz rc %#x",
                          why, natural_cpu / 1000000, natural_gpu / 1000000, (unsigned)rc, t.cpu / 1000000, t.gpu / 1000000, (unsigned)rg,
                          t.emc / 1000000, (unsigned)re);
    return t;
}

static void* keeper(void* arg) {
    (void)arg;
    AppletOperationMode mode = appletGetOperationMode();
    Targets t = apply("start");
    // The CPU experiment (cpu_max.txt) waits for the game to be up: asked at the start, while the GPU was being set up, the GPU was lost.
    // t.cpu stays the boost's clock, the mark for "the boost dropped".
    unsigned cpu_wait = 20;
    for (unsigned tick = 1;; tick++) {
        sleep_ms(1000);
        if (cpu_wait > 0 && --cpu_wait == 0) {
            try_cpu_clock();
        }
        const AppletOperationMode now = appletGetOperationMode();
        if (now != mode) {
            openrac_switch2_trace("perf: operation mode changed to %s", now == AppletOperationMode_Console ? "docked" : "handheld");
            mode = now;
            t = apply("mode change");
            if (g_cpu_forced != 0) cpu_wait = 20;  // the system reset the clocks: the experiment again, once the change has settled
            continue;
        }
        const uint32_t cpu = read_hz(PcvModuleId_CpuBus), gpu = read_hz(PcvModuleId_GPU);
        if (t.cpu && cpu + 100000000u < t.cpu) {
            openrac_switch2_trace("perf: boost dropped (cpu %u MHz), asking again", cpu / 1000000);
            t = apply("boost dropped");
        } else if (t.gpu && gpu + 5000000u < t.gpu) {
            set_hz(PcvModuleId_GPU, t.gpu);
        }
        if (g_cpu_forced != 0 && cpu_wait == 0 && cpu + 20000000u < g_cpu_forced) {
            const Result rc = set_hz(PcvModuleId_CpuBus, g_cpu_forced);
            openrac_switch2_trace("perf: cpu_max.txt: the system had the CPU at %u MHz, asked for %u MHz again: rc %#x", cpu / 1000000, g_cpu_forced / 1000000, (unsigned)rc);
        }
#if defined(OPENRAC_SWITCH2_CALL_RING)
        if (tick % 3 == 0) openrac_switch2_ring_dump();
#endif
        if (tick % 30 == 0) {
            openrac_switch2_trace("perf[%us]: %s cpu %u MHz gpu %u MHz emc %u MHz", tick, mode == AppletOperationMode_Console ? "docked" : "handheld",
                                  cpu / 1000000, gpu / 1000000, read_hz(PcvModuleId_EMC) / 1000000);
        }
    }
    return NULL;
}

void openrac_switch2_perf_start(void) {
    static int started;
    if (started) return;
    started = 1;
    openrac_switch2_stderr_to_file();
    if (access(OPENRAC_S2_HOME "/perf_off.txt", F_OK) == 0) {
        openrac_switch2_trace("perf: perf_off.txt present, no clock is touched");
        return;
    }
    pthread_t th;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 256 * 1024);
    if (pthread_create(&th, &attr, keeper, NULL) == 0) {
        pthread_detach(th);
    } else {
        openrac_switch2_trace("perf: could not start the keeper thread");
    }
}
