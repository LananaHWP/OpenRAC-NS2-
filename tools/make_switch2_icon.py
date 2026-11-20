#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
"""Writes switch2/icon.jpg: the 256 x 256 icon the Homebrew Launcher shows for openrac.nro. It is drawn here (a gear on a dark blue sky, the
word OpenRAC set in Orbitron), with nothing of the games' artwork; replace the file with a picture of your own to change it.

    python tools/make_switch2_icon.py
"""
import math
import pathlib

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
FONT = ROOT / "port/game/common/fonts/Orbitron.ttf"
S = 4  # drawn at four times the size, then scaled down


def gradient(size):
    image = Image.new("RGB", (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / (size - 1)
        colour = (int(14 + 40 * t), int(18 + 46 * t), int(52 + 90 * t))
        for x in range(size):
            pixels[x, y] = colour
    return image


def gear(draw, cx, cy, outer, inner, teeth, fill, outline):
    points = []
    for i in range(teeth * 4):
        angle = 2 * math.pi * i / (teeth * 4)
        radius = outer if i % 4 in (0, 1) else inner
        points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    draw.polygon(points, fill=fill, outline=outline)


def main():
    size = 256 * S
    image = gradient(size)
    draw = ImageDraw.Draw(image)
    cx, cy = size // 2, int(size * 0.42)
    gear(draw, cx, cy, int(size * 0.34), int(size * 0.27), 10, (232, 130, 30), (120, 60, 10))
    draw.ellipse((cx - size * 0.2, cy - size * 0.2, cx + size * 0.2, cy + size * 0.2), fill=(30, 40, 90), outline=(120, 60, 10), width=S * 2)
    draw.ellipse((cx - size * 0.1, cy - size * 0.1, cx + size * 0.1, cy + size * 0.1), fill=(232, 130, 30))
    for angle in (45, 135, 225, 315):  # four bolts
        x = cx + size * 0.155 * math.cos(math.radians(angle))
        y = cy + size * 0.155 * math.sin(math.radians(angle))
        draw.ellipse((x - S * 5, y - S * 5, x + S * 5, y + S * 5), fill=(170, 175, 190))
    big = ImageFont.truetype(str(FONT), int(size * 0.125))
    small = ImageFont.truetype(str(FONT), int(size * 0.075))
    for text, font, y, colour in (("OpenRAC", big, int(size * 0.755), (245, 245, 250)), ("SWITCH 2", small, int(size * 0.885), (240, 160, 60))):
        width = draw.textlength(text, font=font)
        draw.text(((size - width) / 2, y), text, font=font, fill=colour)
    out = ROOT / "switch2" / "icon.jpg"
    image.resize((256, 256), Image.LANCZOS).save(out, quality=92)
    print("written", out)


main()
