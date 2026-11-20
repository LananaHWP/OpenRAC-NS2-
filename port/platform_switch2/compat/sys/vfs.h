// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// OpenRAC on Switch 2: statfs() as "unknown file system" (compat.c); the native-mod library check that asks is off here.
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
struct statfs {
    long f_type;
    long f_bsize;
};
int statfs(const char* path, struct statfs* buf);
#ifdef __cplusplus
}
#endif
