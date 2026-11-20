#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
"""Writes the Controls help picture for the Switch 2 pad as an OpenRAC texture pack (docs/port/TEXTURE_PACKS.md): two pictures named by the
hashes of the two 256 x 256 textures the game draws its Help > Controls page from (side by side, 512 x 256). The pictures are made here, from
"Switch Button Icons and Controls" by Zacksly (CC BY 3.0: https://zacksly.itch.io, see THIRD_PARTY_NOTICES.md: the controller drawing, edited:
its logo covered, set with labels) and the repository's Orbitron font. Nothing of the game's own picture is used: only its two file names.

    python tools/make_controls_help.py "PATH/Switch 2 Button Icons and Controls" OUTDIR

OUTDIR is the pack's Interface folder: <data>/texture_packs/rac1-ntsc/Interface (English NTSC-U: other languages draw other textures).
"""
import argparse
import pathlib

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
FONT = HERE.parent / "port/game/common/fonts/Orbitron.ttf"

# The hashes of the two halves (a dump of the game's textures: the left and the right 256 x 256 of the 512 x 256 picture).
LEFT, RIGHT = "075e1a75c1f609bd", "7cc69b89815e4ec3"
# The menu's small preview of the page (a 256 x 256 texture, its picture in the top left 145 x 135).
PREVIEW = "e83f392474667e79"

S = 4  # the picture is made at four times the 512 x 256 the game lays out
W, H = 512 * S, 256 * S
BACKGROUND = (8, 8, 16, 255)
LINE = (176, 128, 40, 255)
INK = (236, 236, 240, 255)
TEXT = int(9.5 * S)  # pixel height of the labels' letters (the game's are about 9)

# Where the controls are on the pack's controller drawing (its 1024 x 540 preview; the drawing itself is four times that).
ANCHORS = {
    "L": (381, 123), "R": (650, 123), "minus": (459, 173), "plus": (563, 173),
    "lstick": (396, 206), "rstick": (563, 268), "X": (622, 175), "Y": (588, 208), "A": (657, 207), "B": (622, 238),
}
# The logo on the drawing is Nintendo's: covered.
LOGO = (1930, 540, 2170, 770)
LOGO_FROM = (1880, 560)


def icon(root, name, height):
    image = Image.open(root / "Buttons Full Solid/White/256w" / (name + ".png")).convert("RGBA")
    image = image.crop(image.split()[3].getbbox())
    return image.resize((max(1, round(image.width * height / image.height)), height), Image.LANCZOS)


class Page:
    def __init__(self, root):
        self.root = root
        self.image = Image.new("RGBA", (W, H), BACKGROUND)
        self.draw = ImageDraw.Draw(self.image)
        self.font = ImageFont.truetype(str(FONT), int(TEXT * 1.25))
        self.height = int(TEXT * 1.25)

    def runs(self, parts):
        """Widths of a line made of text and icon names ("@L")."""
        out = []
        for part in parts:
            if part.startswith("@"):
                pic = icon(self.root, part[1:], int(self.height * 0.95))
                out.append((pic, pic.width))
            else:
                out.append((part, int(self.draw.textlength(part, font=self.font))))
        return out

    def line_width(self, parts):
        return sum(w for _, w in self.runs(parts)) + 8 * (len(parts) - 1)

    def put(self, x, y, parts):
        """One line of text and icons with its left edge at x and its top at y; returns its width."""
        start = x
        for item, width in self.runs(parts):
            if isinstance(item, str):
                self.draw.text((x, y), item, font=self.font, fill=INK)
            else:
                self.image.alpha_composite(item, (x, y + (self.height - item.height) // 2 + 2))
            x += width + 8
        return x - 8 - start

    def block(self, x, y, lines, align):
        """Lines of text (each a list of parts) with their left (align 'l'), right ('r') or middle ('c') edge at x; returns the box."""
        widths = [self.line_width(parts) for parts in lines]
        step = int(self.height * 1.3)
        box_w = max(widths)
        left = x if align == "l" else x - box_w if align == "r" else x - box_w // 2
        for i, parts in enumerate(lines):
            offset = 0 if align == "l" else box_w - widths[i] if align == "r" else (box_w - widths[i]) // 2
            self.put(left + offset, y + i * step, parts)
        return left, y, left + box_w, y + step * len(lines)

    def line(self, points):
        self.draw.line(points, fill=LINE, width=S + 1, joint="curve")
        x, y = points[-1]
        self.draw.ellipse((x - 2 * S, y - 2 * S, x + 2 * S, y + 2 * S), fill=LINE)


def controller(root):
    image = Image.open(root / "Controller Images/Pro Controller 2/Pro Controller 2 Colored.png").convert("RGBA")
    body = image.getpixel(LOGO_FROM)
    ImageDraw.Draw(image).rectangle(LOGO, fill=body)
    box = image.split()[3].point(lambda v: 255 if v > 40 else 0).getbbox()
    return image, box


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pack")
    ap.add_argument("out")
    args = ap.parse_args()
    root = pathlib.Path(args.pack)
    if not (root / "Controller Images").is_dir():
        root = next(p for p in root.iterdir() if p.is_dir() and (p / "Controller Images").is_dir())
    page = Page(root)
    image, box = controller(root)
    # the game shows less than the whole picture at its left and right edges: the labels keep inside 130 to 1870 (of 2048)
    scale = 760 / (box[2] - box[0])
    ox, oy = 644, 250

    def at(name):
        px, py = ANCHORS[name]
        return int(ox + (px * 4 - box[0]) * scale), int(oy + (py * 4 - box[1]) * scale)

    picture = image.crop(box).resize((round((box[2] - box[0]) * scale), round((box[3] - box[1]) * scale)), Image.LANCZOS)
    page.image.alpha_composite(picture, (ox, oy))
    step = int(page.height * 1.3)

    # ---- the left side (the dots stop at a button's edge, so its letter shows)
    lx, ly = at("L")
    x0, y0, x1, y1 = page.block(200, 100, [["First person"], ["targeting"], ["(", "@L", "/", "@ZL", ")"]], "l")
    page.line([(x1 + 20, y0 + step // 2 + 4), (lx - 90, y0 + step // 2 + 4), (lx, ly)])
    mx, my = at("minus")
    x0, y0, x1, y1 = page.block(mx - 10, 175, [["Map"]], "r")
    page.line([(mx, y1 + 10), (mx, my - 30)])
    px_, py_ = at("plus")
    x0, y0, x1, y1 = page.block(px_ + 10, 175, [["Menu"]], "l")
    page.line([(px_, y1 + 10), (px_, py_ - 30)])
    wx, wy = at("lstick")
    x0, y0, x1, y1 = page.block(max(wx - 200, 330), 840, [["Walk/Run"]], "r")
    page.line([(x1 + 20, y0 + step // 2), (wx - 90, y0 + step // 2), (wx, wy)])

    # ---- the right side
    rx, ry = at("R")
    x0, y0, x1, y1 = page.block(1450, 100, [["Crouch"], ["(", "@R", "/", "@ZR", ")"]], "l")
    page.line([(x0 - 20, y0 + step // 2 + 4), (rx + 120, y0 + step // 2 + 4), (rx, ry)])
    xx, xy = at("X")
    x0, y0, x1, y1 = page.block(1450, 235, [["Quick select"]], "l")
    page.line([(x0 - 20, y0 + step // 2), (xx + 70, y0 + step // 2), (xx + 36, xy)])
    ax, ay = at("A")
    x0, y0, x1, y1 = page.block(1450, 355, [["Fire weapon/"], ["Use gadget"]], "l")
    page.line([(x0 - 20, y0 + step // 2), (ax + 90, y0 + step // 2), (ax + 36, ay)])
    bx, by = at("B")
    x0, y0, x1, y1 = page.block(1450, 530, [["Jump"]], "l")
    page.line([(x0 - 20, y0 + step // 2), (bx + 90, y0 + step // 2), (bx + 36, by)])
    yx, yy = at("Y")
    x0, y0, x1, y1 = page.block(1450, 655, [["Swing wrench"]], "l")
    page.line([(x0 - 20, y0 + step // 2), (yx, y0 + step // 2), (yx, yy + 36)])
    rsx, rsy = at("rstick")
    x0, y0, x1, y1 = page.block(1450, 790, [["Look around"]], "l")
    page.line([(x0 - 20, y0 + step // 2), (rsx + 90, y0 + step // 2), (rsx, rsy)])

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    # the preview: the right half of the pad, with its face buttons, in the top left of a texture four times the size
    pw, ph = 145 * S, 135 * S
    preview = Image.new("RGBA", (256 * S, 256 * S), (0, 0, 0, 0))
    preview.alpha_composite(Image.new("RGBA", (pw, ph), (24, 24, 48, 255)), (0, 0))
    left, top, right, bottom = (int(v * 4) for v in (500, 110, 740, 335))
    crop = image.crop((left, top, right, bottom))
    crop = crop.resize((pw - 20, round((pw - 20) * crop.height / crop.width)), Image.LANCZOS)
    if crop.height > ph - 10:
        crop = crop.crop((0, 0, crop.width, ph - 10))
    preview.alpha_composite(crop, (10, 5))
    preview.save(out / (PREVIEW + ".png"))
    half = W // 2
    page.image.crop((0, 0, half, H)).save(out / (LEFT + ".png"))
    page.image.crop((half, 0, W, H)).save(out / (RIGHT + ".png"))
    page.image.convert("RGB").resize((1024, 512), Image.LANCZOS).save(out.parent / "controls_help_preview.png")
    print("written to", out)


main()
