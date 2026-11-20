// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// OpenRAC on Switch 2: uname() for the system-information text (compat.c).
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
struct utsname {
    char sysname[65];
    char nodename[65];
    char release[65];
    char version[65];
    char machine[65];
};
int uname(struct utsname* name);
#ifdef __cplusplus
}
#endif
