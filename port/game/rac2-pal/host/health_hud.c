/* SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (c) 2026 the OpenRAC contributors
 *
 * Going Commando (PAL): the health meter as a number, for the RAC3-style health mod (switch2/mods/rac3-health). Only while that mod is
 * loaded; otherwise the game's own meter of segments is drawn (host/hud.c). The meter is a twin of the ammo box: its pieces and its
 * number font, drawn from the HUD's own widgets in the middle of the screen at the ammo box's height. Inside its bar, behind the
 * number, a gauge of the health left (orange at a quarter or less; at full health it fills the bar). The ammo box's hooked line, which
 * shows a weapon's experience, shows the nanotech experience to the next level (the game's own long bar is not drawn). A cross sits
 * where the weapon's picture is in the ammo box.
 *
 * The HUD record (func_0034D490 sets it up; func_0034FD60 draws it): the ammo box's frame pieces at +0x0 and +0x4C, its experience
 * line at +0x98, its text element at +0x100 (printing the buffer at +0xE4), the health meter at +0x808. A widget's words point at its place (+0x0: x, y), scale (+0x4),
 * colour (+0xC) and visibility (+0x10, a float); a text element adds its string (+0x40) and alignment (+0x44, 1 centred). The pieces
 * borrowed are put back exactly as they were. */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "game_protos.h"
#include "openrac/game_host.h"
#include "openrac/guest.h"
#include "rac2.h"
#include "../../common/lib/ui_quad.h"

#define HUD_METER 0x808u
#define AMMO_TEXT 0xE4u
#define AMMO_TEXT_SIZE 0x18u
#define AMMO_ELEMENT 0x100u
/* The ammo box's third piece: the hooked line the weapon's experience fills, from 0 to 30, set 8.5 below the box's other pieces. */
#define XP_PIECE 0x98u
#define XP_PIECE_DOWN 8.5f
#define XP_FULL 30.0f

/* The 2D layer's offset and display list, as host/ui2d.c has them. */
#define SCREEN_OFX GREF(int, RAC2_ADDR(0x001A7350u))
#define SCREEN_OFY GREF(int, RAC2_ADDR(0x001A7354u))
#define LIST_CURSOR OPENRAC_DATA(RAC2_ADDR(0x001B22A8u))

/* The meter record (0x404 bytes). */
#define METER_HEALTH 0x0u
#define METER_MOST 0x4u
#define METER_SHOWN 0xCu
#define METER_FRAME 92u   /* its first frame piece: its colour says how far the HUD has faded */
#define METER_XP_BAR 244u /* its full width at +60 (an int), the width filled through +4 */
#define METER_LEVEL_UP_FRAMES 1016u

/* Colours (the chip's R, G, B from the low byte, alpha 0x80 opaque). The frame and the number are the ammo box's own, as shown. */
#define FRAME_BACK 0x60442D00u
#define FRAME_LINE 0x55F0C070u
#define TEXT_WHITE 0x80F0F0F0u
#define TEXT_LOW 0x80B0D9FFu
#define XP_COLOUR 0x80001EFFu /* the ammo box's experience line, as shown */
#define CROSS_EDGE 0x80FFE03Fu
#define CROSS_FILL 0x80FFFCE8u

static unsigned fade(unsigned colour, unsigned alpha, unsigned full) {
    const unsigned a = ((colour >> 24) * alpha + full / 2) / full;
    return (colour & 0x00FFFFFFu) | (a << 24);
}

static unsigned word_at(gaddr widget, unsigned offset) {
    return GREF(uint32_t, GREF(gaddr, widget + offset));
}

/* A four-cornered shape: corners (x, y) in screen pixels, top left, top right, bottom left, bottom right, its top and bottom colours. */
static void shape(const float x[4], const float y[4], unsigned top_colour, unsigned bottom_colour) {
    openrac_game_ui_rect q;
    memset(&q, 0, sizeof(q));
    for (int i = 0; i < 4; ++i) {
        q.x[i] = (uint32_t)((int)(x[i] * 16.0f) + SCREEN_OFX - 8) & 0xFFFFu;
        q.y[i] = (uint32_t)((int)(y[i] * 16.0f) + SCREEN_OFY - 8) & 0xFFFFu;
        q.corners[i] = i < 2 ? top_colour : bottom_colour;
    }
    q.z = 0xFFFFF0u;
    q.rgba = top_colour;
    q.flags = 4u | 8u | 32u;
    openrac_ui_send(&q, LIST_CURSOR);
}

static void box(float left, float top, float right, float bottom, unsigned colour) {
    const float x[4] = {left, right, left, right};
    const float y[4] = {top, top, bottom, bottom};
    shape(x, y, colour, colour);
}

/* One band of the gauge, from `left` to a right edge that runs from `top_end` to `bottom_end`, filled as far as `fill`. */
static void row(
    float left, float fill, float top, float bottom, float top_end, float bottom_end, unsigned top_colour, unsigned bottom_colour
) {
    const float x[4] = {left, top_end < fill ? top_end : fill, left, bottom_end < fill ? bottom_end : fill};
    const float y[4] = {top, top, bottom, bottom};
    shape(x, y, top_colour, bottom_colour);
}

/* One of the ammo box's frame pieces, drawn as shown (full size, its colour) at (x, y), cut to `digits` more characters, then put back. */
static void frame_piece(gaddr widget, float x, float y, float digits, unsigned colour) {
    const gaddr place = GREF(gaddr, widget + 0x0u), size = GREF(gaddr, widget + 0x4u), tint = GREF(gaddr, widget + 0xCu),
                visible = GREF(gaddr, widget + 0x10u), wide = (gaddr)func_00337FF8(widget);
    const float old_x = GREF(float, place), old_y = GREF(float, place + 4u), old_sx = GREF(float, size), old_sy = GREF(float, size + 4u),
                old_visible = GREF(float, visible), old_wide = GREF(float, wide);
    const uint32_t old_colour = GREF(uint32_t, tint);
    GREF(float, place) = x;
    GREF(float, place + 4u) = y;
    GREF(float, size) = 1.0f;
    GREF(float, size + 4u) = 1.0f;
    GREF(float, visible) = 1.0f;
    GREF(float, wide) = digits;
    GREF(uint32_t, tint) = colour;
    func_00338000(widget);
    GREF(float, place) = old_x;
    GREF(float, place + 4u) = old_y;
    GREF(float, size) = old_sx;
    GREF(float, size + 4u) = old_sy;
    GREF(float, visible) = old_visible;
    GREF(float, wide) = old_wide;
    GREF(uint32_t, tint) = old_colour;
}

/* The string in the ammo box's font and size (0.9, as the setup gives its element), centred on x: through the ammo text element and its
 * buffer, drawn as the GUI draws it (alignment 1), then put back. */
static void ammo_font_print(gaddr hud, float x, float y, unsigned colour, const char* text) {
    const gaddr element = hud + AMMO_ELEMENT, buffer = hud + AMMO_TEXT;
    const gaddr place = GREF(gaddr, element + 0x0u), size = GREF(gaddr, element + 0x4u), tint = GREF(gaddr, element + 0xCu),
                visible = GREF(gaddr, element + 0x10u);
    uint8_t old[AMMO_TEXT_SIZE];
    memcpy(old, G(buffer), sizeof(old));
    const float old_x = GREF(float, place), old_y = GREF(float, place + 4u), old_size = GREF(float, size),
                old_visible = GREF(float, visible);
    const uint32_t old_colour = GREF(uint32_t, tint);
    const gaddr old_string = GREF(gaddr, element + 0x40u);
    const int old_align = GREF(int, element + 0x44u);
    memset(G(buffer), 0, sizeof(old));
    memcpy(G(buffer), text, strnlen(text, sizeof(old) - 1));
    GREF(float, place) = x;
    GREF(float, place + 4u) = y;
    GREF(float, size) = 0.9f;
    GREF(float, visible) = 1.0f;
    GREF(uint32_t, tint) = colour;
    GREF(gaddr, element + 0x40u) = buffer;
    GREF(int, element + 0x44u) = 1;
    func_00338770(element);
    GREF(float, place) = old_x;
    GREF(float, place + 4u) = old_y;
    GREF(float, size) = old_size;
    GREF(float, visible) = old_visible;
    GREF(uint32_t, tint) = old_colour;
    GREF(gaddr, element + 0x40u) = old_string;
    GREF(int, element + 0x44u) = old_align;
    memcpy(G(buffer), old, sizeof(old));
}

/* The line's value for the nanotech experience, worked out as the HUD works out a weapon's (func_0034F068): 30 at full, a little
 * experience stretched so that it shows (by the executable's constant at 0x1AE75C), full once the health is maxed (the mod's most is
 * 200; the game's own experience bar, which holds the width filled and the full width, is kept only under 80 of its points). */
static float xp_line(gaddr meter, int most) {
    if (most >= 200) {
        return XP_FULL;
    }
    const gaddr bar = meter + METER_XP_BAR;
    const float full = (float)GREF(uint32_t, bar + 60u);
    float part = full > 0.0f ? GREF(float, GREF(gaddr, bar + 0x4u)) / full : 0.0f;
    part = part > 1.0f ? 1.0f : part < 0.0f ? 0.0f : part;
    float stretch = GREF(float, OPENRAC_DATA(0x001AE75Cu)) * (0.5f - part * 0.5f);
    stretch = stretch > 1.0f ? stretch : 1.0f;
    const float value = part * XP_FULL * stretch;
    return value < XP_FULL ? value : XP_FULL;
}

static int mod_loaded(void) {
    return openrac_game_loaded_mods != 0 && strstr(openrac_game_loaded_mods, "\"rac3-health\"") != 0;
}

/* Draws the number meter in the segments' place; 0 when the mod is not loaded (the game's meter is then to be drawn). */
int rac2_numeric_health(gaddr meter) {
    static unsigned full_alpha;
    if (!mod_loaded()) {
        return 0;
    }
    if (GREF(int, meter + METER_SHOWN) == 0) {
        return 1;
    }
    const gaddr hud = meter - HUD_METER;
    const float top = GREF(float, GREF(gaddr, meter + 0x8u) + 4u);

    /* How far the HUD has faded the meter in, by its frame's alpha against the most seen. */
    const unsigned alpha = word_at(meter + METER_FRAME, 0xCu) >> 24;
    if (alpha > full_alpha) {
        full_alpha = alpha;
    }
    if (alpha == 0 || full_alpha == 0) {
        return 1;
    }

    int health = GREF(int, meter + METER_HEALTH);
    const int most = GREF(int, meter + METER_MOST);
    if (health < 0) {
        health = 0;
    }
    char text[AMMO_TEXT_SIZE], widest[AMMO_TEXT_SIZE];
    snprintf(text, sizeof(text), "%d/%d", health, most);
    snprintf(widest, sizeof(widest), "%d/%d", most, most);
    /* The ammo box's width follows its text: three characters and up to five more. Sized for the most health, it keeps still. */
    const int length = (int)strlen(widest);
    const int more = length - 3 < 0 ? 0 : length - 3 > 5 ? 5 : length - 3;
    const int low = most > 0 && health * 4 <= most;

    int level_up = GREF(int, meter + METER_LEVEL_UP_FRAMES);
    if (level_up > 0) {
        GREF(int, meter + METER_LEVEL_UP_FRAMES) = level_up - 1;
    }

    /* The middle of the box (its drawn width runs from 2 to 92 + 12 a character past three) in the middle of the screen. */
    const float wide = 12.0f * (float)more;
    const float left = 256.0f - (2.0f + 92.0f + wide) * 0.5f;

    frame_piece(hud + 0x0u, left, top, (float)more, fade(FRAME_BACK, alpha, full_alpha));
    frame_piece(hud + 0x4Cu, left, top, (float)more, fade(FRAME_LINE, alpha, full_alpha));
    /* The ammo box's hooked line, where it shows the weapon's experience: here the nanotech experience to the next health level. */
    frame_piece(hud + XP_PIECE, left, top + XP_PIECE_DOWN, xp_line(meter, most), fade(XP_COLOUR, alpha, full_alpha));

    /* Inside the bar: from 50, its pointed end from 84 (top) over 89 (middle) back to 78 (bottom), each past the characters. */
    const float inner = left + 50.0f, end_top = left + 84.0f + wide, end_mid = left + 89.0f + wide, end_bottom = left + 78.0f + wide;

    /* The gauge of the health left, lighter at the top, filling the bar's pointed shape. */
    float part = most > 0 ? (float)health / (float)most : 0.0f;
    part = part > 1.0f ? 1.0f : part;
    if (part > 0.0f) {
        const float fill = inner + (end_mid - inner) * part;
        unsigned shine = low ? 0x7060C8FFu : 0x70FFF090u, middle = low ? 0x703C9AFFu : 0x70E8B020u,
                 deep = low ? 0x702060C8u : 0x70A86810u;
        if (level_up > 0 && (level_up & 4) != 0) {
            shine = middle = deep = 0x70FFFFFFu;
        }
        row(inner, fill, top + 5.0f, top + 14.0f, end_top, end_mid, fade(shine, alpha, full_alpha), fade(middle, alpha, full_alpha));
        row(inner, fill, top + 14.0f, top + 23.0f, end_mid, end_bottom, fade(middle, alpha, full_alpha), fade(deep, alpha, full_alpha));
    }

    ammo_font_print(hud, left + 68.0f + wide * 0.5f, top + 4.0f, fade(low ? TEXT_LOW : TEXT_WHITE, alpha, full_alpha), text);

    /* The cross, in the middle of where the weapon's picture sits in the ammo box. */
    const float cx = left + 26.5f, cy = top + 21.5f;
    box(cx - 4.5f, cy - 9.0f, cx + 4.5f, cy + 9.0f, fade(CROSS_EDGE, alpha, full_alpha));
    box(cx - 9.0f, cy - 4.5f, cx + 9.0f, cy + 4.5f, fade(CROSS_EDGE, alpha, full_alpha));
    box(cx - 2.5f, cy - 7.0f, cx + 2.5f, cy + 7.0f, fade(CROSS_FILL, alpha, full_alpha));
    box(cx - 7.0f, cy - 2.5f, cx + 7.0f, cy + 2.5f, fade(CROSS_FILL, alpha, full_alpha));
    return 1;
}
