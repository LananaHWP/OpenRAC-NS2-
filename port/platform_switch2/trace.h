// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// OpenRAC on Switch 2: a boot trace. One line per call is appended to sdmc:/switch/openrac/boot.txt and flushed at once, so the last
// line left after a crash or a silent exit says how far the start got. (The program's own log opens later and can be lost.)
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
/* The program's folder on the card (sdmc:/switch/<OPENRAC_SWITCH2_HOME>, "openrac" unless a build says otherwise: cmake/OpenracSwitch2.cmake). */
#ifndef OPENRAC_S2_HOME
#define OPENRAC_S2_HOME "sdmc:/switch/openrac"
#endif

/* Whether sdmc:/switch/openrac/debug.txt exists: only then is anything logged (boot.txt, the program's own log). */
int openrac_switch2_debug(void);
void openrac_switch2_trace(const char* fmt, ...) __attribute__((format(printf, 1, 2)));
// The clocks (perf.c): the CPU boost with the GPU kept at its own clock, kept up across dock changes. Idempotent.
void openrac_switch2_perf_start(void);

/* With debug.txt: stderr goes to stderr.txt (after the program has started). */
void openrac_switch2_stderr_to_file(void);

/* OPENRAC_SWITCH2_CALL_RING builds only: logs the last functions the game entered (and left, marked "<") as offsets from the ring's own
 * function, to be looked up in the program's symbols. */
void openrac_switch2_ring_dump(void);
#ifdef __cplusplus
}
#endif
