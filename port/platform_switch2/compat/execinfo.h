// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// OpenRAC on Switch 2: no libc backtrace on Horizon; these report an empty stack.
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
int backtrace(void** buffer, int size);
char** backtrace_symbols(void* const* buffer, int size);
void backtrace_symbols_fd(void* const* buffer, int size, int fd);
#ifdef __cplusplus
}
#endif
