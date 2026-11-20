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
// The answers are logged to the boot trace (sdmc:/switch/openrac/boot.txt).
#include <pthread.h>
#include <stdint.h>
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

static void sleep_ms(unsigned ms) {
    usleep(ms * 1000u);
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
    for (unsigned tick = 1;; tick++) {
        sleep_ms(1000);
        const AppletOperationMode now = appletGetOperationMode();
        if (now != mode) {
            openrac_switch2_trace("perf: operation mode changed to %s", now == AppletOperationMode_Console ? "docked" : "handheld");
            mode = now;
            t = apply("mode change");
            continue;
        }
        const uint32_t cpu = read_hz(PcvModuleId_CpuBus), gpu = read_hz(PcvModuleId_GPU);
        if (t.cpu && cpu + 100000000u < t.cpu) {
            openrac_switch2_trace("perf: boost dropped (cpu %u MHz), asking again", cpu / 1000000);
            t = apply("boost dropped");
        } else if (t.gpu && gpu + 5000000u < t.gpu) {
            set_hz(PcvModuleId_GPU, t.gpu);
        }
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
    if (access("sdmc:/switch/openrac/perf_off.txt", F_OK) == 0) {
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
