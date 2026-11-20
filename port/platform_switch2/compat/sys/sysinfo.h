// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// OpenRAC on Switch 2: sysinfo(2) as the memory figures the process can read from the kernel (compat.c).
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
struct sysinfo {
    long uptime;
    unsigned long loads[3];
    unsigned long totalram;
    unsigned long freeram;
    unsigned long sharedram;
    unsigned long bufferram;
    unsigned long totalswap;
    unsigned long freeswap;
    unsigned short procs;
    unsigned long totalhigh;
    unsigned long freehigh;
    unsigned int mem_unit;
};
int sysinfo(struct sysinfo* info);
#ifdef __cplusplus
}
#endif
