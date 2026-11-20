#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
"""Writes a title logo for the main menu as an OpenRAC texture pack picture (docs/port/TEXTURE_PACKS.md): the picture named by the hash of the
256 x 128 texture the game draws its logo from (a dump of the game's textures), made from a logo picture of your own.

    python tools/make_logo_pack.py LOGO.png OUTDIR

The game stretches that texture over a 2:1 area, so the picture is centred on a transparent 2:1 canvas (kept in proportion), and scaled down to
1024 x 512 when it is larger. OUTDIR is the pack's Interface folder: <data>/texture_packs/rac1-ntsc/Interface (English NTSC-U).
"""
import argparse
import pathlib

import numpy as np
from PIL import Image

# The hash of the logo's texture in a dump (the title screen's "Ratchet & Clank" picture, 256 x 128).
LOGO = "f2b759a866bbdb0d"
WIDTH, HEIGHT = 1024, 512


def clear_black_background(logo):
    """A logo picture saved on opaque black: the black that is joined to the picture's border becomes transparent (a flood fill, so the
    dark parts inside the logo stay), with a soft edge."""
    rgba = np.array(logo)
    if rgba[..., 3].min() < 255:
        return logo  # it has transparency of its own
    height, width = rgba.shape[:2]
    dark = rgba[..., :3].max(axis=2) <= 10
    outside = np.zeros((height, width), dtype=bool)
    stack = [(0, x) for x in range(width)] + [(height - 1, x) for x in range(width)] + [(y, 0) for y in range(height)] + [(y, width - 1) for y in range(height)]
    while stack:
        y, x = stack.pop()
        if outside[y, x] or not dark[y, x]:
            continue
        outside[y, x] = True
        if y > 0:
            stack.append((y - 1, x))
        if y < height - 1:
            stack.append((y + 1, x))
        if x > 0:
            stack.append((y, x - 1))
        if x < width - 1:
            stack.append((y, x + 1))
    # the ring around it (up to 3 pixels in) fades with how dark each pixel is
    near = outside.copy()
    for _ in range(3):
        grown = near.copy()
        grown[1:] |= near[:-1]
        grown[:-1] |= near[1:]
        grown[:, 1:] |= near[:, :-1]
        grown[:, :-1] |= near[:, 1:]
        near = grown
    brightness = rgba[..., :3].max(axis=2).astype(np.int32)
    alpha = np.full((height, width), 255, dtype=np.int32)
    alpha[near] = np.clip((brightness[near] - 10) * 10, 0, 255)
    alpha[outside] = 0
    rgba[..., 3] = alpha.astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("logo")
    ap.add_argument("out")
    args = ap.parse_args()
    logo = clear_black_background(Image.open(args.logo).convert("RGBA"))
    box = logo.split()[3].point(lambda v: 255 if v > 8 else 0).getbbox()
    if box is not None:
        logo = logo.crop(box)  # no empty border: the logo fills what the game gives it
    # fit into 2:1 with a small margin
    scale = min(WIDTH * 0.98 / logo.width, HEIGHT * 0.98 / logo.height)
    size = (max(1, round(logo.width * scale)), max(1, round(logo.height * scale)))
    logo = logo.resize(size, Image.LANCZOS)
    canvas = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    canvas.alpha_composite(logo, ((WIDTH - size[0]) // 2, (HEIGHT - size[1]) // 2))
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    canvas.save(out / (LOGO + ".png"))
    print("written to", out / (LOGO + ".png"))


main()
