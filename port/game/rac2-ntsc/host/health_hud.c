/* SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (c) 2026 the OpenRAC contributors
 *
 * The number health meter (the RAC3-style health mod) is PAL's only so far (rac2-pal/host/health_hud.c): this release draws the game's. */
#include "openrac/guest.h"

int rac2_numeric_health(gaddr meter) {
    (void)meter;
    return 0;
}
