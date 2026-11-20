// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
//
// The button pictures in the game's text ("press X to ..."): ten 24 x 16 cells of the font sheet that show the PlayStation's buttons.
// A style other than the original's draws other pictures into those cells when the sheet is converted. The pictures are made here
// from code (a disc or a pill with a letter set in a built-in pixel font): no picture file, nothing taken from the disc or from
// anyone's artwork.

#pragma once

#include "renderer/textures/texture.h"

namespace openrac::renderer::button_glyphs {

enum class Style {
    PlayStation = 0,  // the game's own pictures, nothing is touched
    Letters = 1,      // A at the foot, B right, X left, Y top (an Xbox pad); LB RB LT RT L3 R3
    Switch = 2,       // B at the foot, A right, Y left, X top (a Switch pad); L R ZL ZR L3 R3
};

// The style the sheets are made in; set before the first game texture is converted.
void set_style(int style);
Style style();

// While a menu is up the game's Cross and Circle buttons are on the pad's other face buttons (platform/input.h set_menu_context_query): the two
// pictures trade places so a prompt shows the button that answers it. Set from the pad's thread; read when a sheet is converted.
void set_menu_context(bool menu);
// 0 unless the pictures are drawn in a style and a menu is up now: what tells the two ways a font sheet is made apart.
unsigned variant();

// A font sheet (256 x 128 as the port converted an 8-bit upload, alpha as the chip has it) gets the style's pictures in its ten
// button cells; any other picture is left alone. True when it was changed.
bool patch(Rgba8Image& image);

}  // namespace openrac::renderer::button_glyphs
