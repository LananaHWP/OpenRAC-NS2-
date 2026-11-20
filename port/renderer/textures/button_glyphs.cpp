// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors

#include "renderer/textures/button_glyphs.h"

#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstddef>
#include <cstdint>

#include "common/log.h"

namespace openrac::renderer::button_glyphs {
namespace {

constexpr int kSheetWidth = 256;
constexpr int kSheetHeight = 128;
constexpr int kCellWidth = 24;
constexpr int kCellHeight = 16;
// The art sits in a 16-wide window at x 2 of its cell, where the game's own pictures are; the rest of the cell is the font's background.
constexpr int kArtX = 2;
constexpr int kCellRow = 96;
constexpr std::uint32_t kOpaque = 128;  // the chip's alpha: 128 is fully opaque

enum class Shape { Disc, Bumper, Trigger, Stick };

struct Cell {
    int u;
    Shape shape;
    const char* letters;         // in the Letters style
    const char* switch_letters;  // in the Switch style
};

// The game's order on the sheet: Cross, Square, Triangle, Circle, L1, L2, R1, R2, right stick, left stick.
constexpr std::array<Cell, 10> kCells = {{
    {0, Shape::Disc, "A", "B"},         // Cross: the button at the foot
    {24, Shape::Disc, "X", "Y"},        // Square: left
    {48, Shape::Disc, "Y", "X"},        // Triangle: top
    {72, Shape::Disc, "B", "A"},        // Circle: right
    {96, Shape::Bumper, "LB", "L"},     // L1
    {120, Shape::Trigger, "LT", "ZL"},  // L2
    {144, Shape::Bumper, "RB", "R"},    // R1
    {168, Shape::Trigger, "RT", "ZR"},  // R2
    {208, Shape::Stick, "R3", "R3"},    // right stick
    {232, Shape::Stick, "L3", "L3"},    // left stick
}};

Style g_style = Style::PlayStation;
std::atomic<bool> g_menu{false};

// The Switch style's pictures: 24 x 16 RGBA, one per cell of the sheet (tools/make_switch_glyphs.py, whose source pack is credited in
// THIRD_PARTY_NOTICES.md).
constexpr std::uint8_t kSwitchArt[10][kCellWidth * kCellHeight * 4] =
#include "renderer/textures/switch_glyph_art.inc"
    ;

using Picture = std::array<std::uint32_t, kCellWidth * kCellHeight>;

Picture switch_picture(std::size_t cell) {
    Picture out{};
    for (int i = 0; i < kCellWidth * kCellHeight; ++i) {
        const std::uint8_t* texel = &kSwitchArt[cell][i * 4];
        if (texel[3] != 0) {
            // the chip's alpha runs 0 to 128
            out[static_cast<std::size_t>(i)] =
                rgba(texel[0], texel[1], texel[2], (static_cast<std::uint32_t>(texel[3]) * kOpaque + 127u) / 255u);
        }
    }
    return out;
}

// 5 x 7 letters, one byte a row (bit 4 is the left column).
std::array<std::uint8_t, 7> letter(char c) {
    switch (c) {
        case 'A': return {0x0e, 0x11, 0x11, 0x1f, 0x11, 0x11, 0x11};
        case 'B': return {0x1e, 0x11, 0x11, 0x1e, 0x11, 0x11, 0x1e};
        case 'X': return {0x11, 0x11, 0x0a, 0x04, 0x0a, 0x11, 0x11};
        case 'Y': return {0x11, 0x11, 0x0a, 0x04, 0x04, 0x04, 0x04};
        case 'L': return {0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1f};
        case 'R': return {0x1e, 0x11, 0x11, 0x1e, 0x14, 0x12, 0x11};
        case 'T': return {0x1f, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04};
        case 'Z': return {0x1f, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1f};
        case '3': return {0x0e, 0x11, 0x01, 0x06, 0x01, 0x11, 0x0e};
        default: return {};
    }
}

// The distance (negative inside) from a point to a rounded box.
float rounded_box(float px, float py, float cx, float cy, float hx, float hy, float r) {
    const float qx = std::fabs(px - cx) - (hx - r);
    const float qy = std::fabs(py - cy) - (hy - r);
    const float ox = std::max(qx, 0.0f);
    const float oy = std::max(qy, 0.0f);
    return std::sqrt(ox * ox + oy * oy) + std::min(std::max(qx, qy), 0.0f) - r;
}

struct Colours {
    std::uint32_t fill, rim, ink;
};

std::uint32_t grey(std::uint32_t v) {
    return rgba(v, v, v, kOpaque);
}

// A 24 x 16 picture: 0 where nothing is drawn (the font's background shows).
Picture draw(const Cell& cell, const char* letters) {
    Colours c{grey(228), grey(96), grey(16)};
    float hx = 7.75f;
    float hy = 7.75f;
    float radius = 7.75f;
    float cy = 8.0f;
    switch (cell.shape) {
        case Shape::Disc:
            break;
        case Shape::Bumper:
            hx = 8.0f;
            hy = 5.5f;
            radius = 5.5f;
            cy = 8.5f;
            break;
        case Shape::Trigger:
            hx = 8.0f;
            hy = 7.5f;
            radius = 4.0f;
            cy = 8.5f;
            c.fill = grey(196);
            break;
        case Shape::Stick:
            c = {grey(64), grey(210), grey(244)};
            break;
    }
    const float cx = static_cast<float>(kArtX) + 8.0f;
    Picture out{};
    for (int y = 0; y < kCellHeight; ++y) {
        for (int x = 0; x < kCellWidth; ++x) {
            const float d = rounded_box(
                static_cast<float>(x) + 0.5f, static_cast<float>(y) + 0.5f, cx, cy, hx, hy, radius
            );
            if (d <= 0.0f) {
                out[static_cast<std::size_t>(y * kCellWidth + x)] = d > -1.0f ? c.rim : c.fill;
            }
        }
    }
    int count = 0;
    while (letters[count] != 0) {
        ++count;
    }
    const int width = count * 5 + (count - 1);
    const int x0 = static_cast<int>(std::floor(cx - static_cast<float>(width) / 2.0f + 0.5f));
    const int y0 = static_cast<int>(std::floor(cy - 3.5f));
    for (int i = 0; i < count; ++i) {
        const auto rows = letter(letters[i]);
        for (int row = 0; row < 7; ++row) {
            for (int col = 0; col < 5; ++col) {
                if (((rows[static_cast<std::size_t>(row)] >> (4 - col)) & 1) != 0) {
                    out[static_cast<std::size_t>((y0 + row) * kCellWidth + x0 + i * 6 + col)] = c.ink;
                }
            }
        }
    }
    return out;
}

// How many texels of a box of the sheet are at least this opaque (alpha 0 to 128).
int opaque_in(const Rgba8Image& image, int x0, int y0, int x1, int y1) {
    int count = 0;
    for (int y = y0; y < y1; ++y) {
        for (int x = x0; x < x1; ++x) {
            if ((image.texel(x, y) >> 24) >= 64) {
                ++count;
            }
        }
    }
    return count;
}

// Whether `image` is one of the game's font sheets (it has three, one per font): the ten button cells in its row 96, as measured on dumped sheets.
// The four round buttons are filled in their first 16 columns (from x 2) and clear after them, the four shoulder and trigger pills fill most of
// 21 x 13 from (3, 2), the two stick cells hold a picture. Nothing else is both 256 x 128 and that.
bool is_font_sheet(const Rgba8Image& image) {
    if (image.width != kSheetWidth || image.height != kSheetHeight) {
        return false;
    }
    for (const Cell& cell : kCells) {
        const int u = cell.u;
        switch (cell.shape) {
            case Shape::Disc:
                if (opaque_in(image, u + kArtX, kCellRow, u + kArtX + 16, kCellRow + kCellHeight) < 150
                    || opaque_in(image, u + 19, kCellRow, u + kCellWidth, kCellRow + kCellHeight) != 0) {
                    return false;
                }
                break;
            case Shape::Bumper:
            case Shape::Trigger:
                if (opaque_in(image, u + 3, kCellRow + 2, u + 24, kCellRow + 15) < 200
                    || opaque_in(image, u, kCellRow, u + 3, kCellRow + kCellHeight) != 0) {
                    return false;
                }
                break;
            case Shape::Stick:
                if (opaque_in(image, u + 1, kCellRow + 2, u + 15, kCellRow + 15) < 100) {
                    return false;
                }
                break;
        }
    }
    return true;
}

}  // namespace

void set_style(int style) {
    g_style = style == 1 ? Style::Letters : style == 2 ? Style::Switch : Style::PlayStation;
}

Style style() {
    return g_style;
}

void set_menu_context(bool menu) {
    g_menu.store(menu, std::memory_order_relaxed);
}

unsigned variant() {
    return g_style != Style::PlayStation && g_menu.load(std::memory_order_relaxed) ? 1u : 0u;
}

bool patch(Rgba8Image& image) {
    if (g_style == Style::PlayStation || !is_font_sheet(image)) {
        return false;
    }
    for (std::size_t k = 0; k < kCells.size(); ++k) {
        const Cell& cell = kCells[k];
        // In a menu the Cross cell (the foot) shows what answers it, the pad's right button, and the Circle cell the foot.
        const std::size_t from = variant() != 0 && (k == 0 || k == 3) ? 3 - k : k;
        const Picture art = g_style == Style::Switch ? switch_picture(from) : draw(cell, kCells[from].letters);
        // What is behind a picture: the sheet's own background (the cell's first texel; the pictures start further in).
        const std::uint32_t background = image.texel(cell.u, kCellRow);
        for (int y = 0; y < kCellHeight; ++y) {
            for (int x = 0; x < kCellWidth; ++x) {
                const std::uint32_t picture = art[static_cast<std::size_t>(y * kCellWidth + x)];
                image.set_texel(cell.u + x, kCellRow + y, picture != 0 ? picture : background);
            }
        }
    }
    static int told = 0;
    if (told++ < 4) {
        log::info(
            "button glyphs: a font sheet got the {} pictures",
            g_style == Style::Switch ? "Switch" : "letters"
        );
    }
    return true;
}

}  // namespace openrac::renderer::button_glyphs
