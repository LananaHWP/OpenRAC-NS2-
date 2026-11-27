/* SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (c) 2026 the OpenRAC contributors
 *
 * Going Commando (PAL), level 0's opening object (func_L00_00386100, libraries.tsv port = wrap). On its first tick (state 0) it puts Ratchet
 * at its pose, the level's start, and it has no spawn condition, so the reload after a death makes it anew. The reload puts him back at the
 * saved continue point (func_L00_0035B058) and then ticks every object (func_L00_0032F058), this one with them: on the console build every
 * death sent him back to the start. The disc's code has the same order and no guard that was found; how the PS2 keeps him at the continue
 * point is not known.
 *
 * So: made anew while the level has a continue point saved, it is made finished. A level loaded afresh zeroes the saved block
 * (func_L00_0035ADD0), so the opening runs there as it always did, and so does a death before the first continue point. */
#include "game_protos.h"
#include "openrac/guest.h"

/* The saved continue point's block (func_002E01C8 writes it): its first word is set once there is one. */
#define CONTINUE_POINT 0x0021DE20u
/* A moby's state byte, and the opening's last state, as it is at every save made after it (its code does nothing there but keep what it
 * put away hidden). */
#define MOBY_STATE 0x20u
#define FINISHED 5

void func_L00_00386100__game(gaddr moby);

void func_L00_00386100(gaddr moby) {
    if (GREF(uint8_t, moby + MOBY_STATE) == 0 && GREF(int, CONTINUE_POINT) != 0) {
        GREF(uint8_t, moby + MOBY_STATE) = FINISHED;
    }
    func_L00_00386100__game(moby);
}
