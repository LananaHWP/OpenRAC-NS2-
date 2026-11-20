#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
"""Collects the Switch 2 setup (tools/switch2_setup.py) into a folder to give to players: the setup itself, the extractors it runs, and
the bundle it copies onto the SD card (the program, the pictures, the optional mods).

    python tools/make_switch2_bundle.py --nro PATH/openrac.nro [--textures DIR] [--mods DIR] [--out dist/OpenRAC-Switch2-Setup]

  --textures  the texture pack folder (its rac1-ntsc/Interface/*.png: the Switch button prompts' help screen, the preview and the logo)
  --mods      a folder of mod folders (each with its openrac-mod.json: arsenal-mastery, quickselect-pause, steady-strafe), each a choice
              in the setup; left out of the bundle when not given. --mod DIR adds one mod folder, under the folder's own name

The folder holds nothing of the game itself, only OpenRAC's own program and the pictures made for it.
"""
import argparse
import pathlib
import shutil

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent

SKIP = shutil.ignore_patterns("__pycache__", "*.pyc", "test_*.py", "tests", "*.orig")

BAT = """@echo off
rem OpenRAC for Switch 2: puts the game on your console from your own disc image (an SD card in this PC, or over FTP).
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 "%~dp0switch2_setup.py" %*
) else (
  python "%~dp0switch2_setup.py" %*
)
if errorlevel 1 (
  echo.
  echo The setup needs Python 3.9 or newer: https://www.python.org/downloads/ ^(tick "Add python.exe to PATH"^).
  pause
)
"""

SH = """#!/bin/sh
# OpenRAC for Switch 2: puts the game on your console from your own disc image (an SD card in this PC, or over FTP).
# A window opens when python3-tk is installed; otherwise it asks its questions here in the terminal.
here="$(cd "$(dirname "$0")" && pwd)"
if command -v python3 >/dev/null 2>&1; then
  exec python3 "$here/switch2_setup.py" "$@"
fi
echo "The setup needs Python 3.9 or newer: install python3 (for example: sudo apt install python3 python3-tk)." >&2
exit 1
"""

README = """OpenRAC for the Nintendo Switch 2 - setup
==========================================

You need: the image (.iso) of your own Ratchet & Clank disc (NTSC-U), about 6 GB of free space on the console's SD card (exFAT), and
Python 3.9 or newer on this PC.

  Windows:  double-click install.bat
  Linux, macOS: sh install.sh   (a window needs python3-tk; without it the setup asks its questions in the terminal)

Then pick how the game gets to the console:

  Over FTP (the console on your network)
    Start an FTP server homebrew on the console, note the address it shows (the default port is 1337, with no user name or password), and type it in. The setup checks the disc,
    exports the levels on this PC and uploads everything to the game's folder under switch/ on the SD card, about 5 GB. An upload that stops is resumed:
    run the setup again. The work folder (about 1 GB) is made next to the disc image and deleted afterwards.

  Onto an SD card in this PC
    Put the card in the PC, pick its drive or folder, and the files are written straight onto it.

  Into a folder on this PC
    Pick any folder: the setup writes the card's switch folder into it, and you copy that onto the SD card's root yourself
    (a card reader, FileZilla, a file manager).

Nothing is written to the console's own storage: everything is in the game's own folder under switch/ on the card. Start the game from the homebrew menu.

The mods are optional, each its own tick box in the setup (all unticked is the original game):
  Arsenal Mastery    weapon and health levels as in Ratchet & Clank 3 (from rac-rs)
  Quick Select pause the world stands still while the Quick Select ring is up (from rac-rs)
  Steady strafe      hold R2 to strafe facing the camera, as in Ratchet & Clank 2 (from rac-rs; USA disc)
To turn one off later, delete its folder in switch/openrac/data/plugins, or set "enabled" to false in plugins.json there.

Logs are off. To make one for a bug report, create an empty file switch/openrac/debug.txt on the card (over FTP too), play, and fetch
switch/openrac/boot.txt and the log files in switch/openrac/data. Delete debug.txt afterwards.

Hold + and - together for OpenRAC's own menu. The game's A and B swap in menus (A confirms, B goes back).

From a terminal (both systems):
  python3 switch2_setup.py --cli --iso GAME.iso --ftp 192.168.1.50:1337
  python3 switch2_setup.py --cli --iso GAME.iso --sd E:\\
  python3 switch2_setup.py --cli --iso GAME.iso --folder D:\\OpenRAC-out
"""


CREDITS = """OpenRAC for the Nintendo Switch 2 0.2

Source code (GPL-3.0-or-later; openrac.nro is built from it): https://github.com/LananaHWP/OpenRAC-NS2-
The license text is in COPYING. Files keep the license of the folder they come from; see LICENSE.md and THIRD_PARTY_NOTICES.md in the source.

Credits
- OpenRAC and its contributors: https://github.com/OpenRAC/OpenRAC (the decompilations, the tools and the renderer this is built on)
- rac-rs by AsobiCodes: https://github.com/AsobiCodes/rac-rs. Arsenal Mastery (bundle/mods/arsenal-mastery) is theirs,
  https://github.com/AsobiCodes/arsenal-mastery, MIT, Copyright (c) 2026 AsobiCodes (its LICENSE is in the folder).
  Quick Select pause and Steady strafe (bundle/mods) are rac-rs's "Quick Select pauses the game" and its Steady strafe aiming written as script
  mods for OpenRAC, using rac-rs's addresses and findings: GPL-3.0-or-later, like rac-rs.
- Switch Button Icons and Controls by Zacksly (CC BY 3.0 Licensed | zacksly.itch.io), https://zacksly.itch.io,
  https://creativecommons.org/licenses/by/3.0/. The button icons in the game and the help screen pictures in
  bundle/texture_packs are based on it and were changed: cut to shape, scaled, the logo on the controller covered, labels added.
- OunceDevKit (libounce, OunceVK, libkaihen) by ouncebrew: https://github.com/ouncebrew/ounce-devkit, on devkitPro.
- SDL (zlib license), https://libsdl.org. Orbitron (SIL Open Font License) lettered the help screen.

Ratchet & Clank belongs to Sony Interactive Entertainment and Insomniac Games; Nintendo Switch belongs to Nintendo. This is a fan
project. No part of the game is included: the setup reads the disc image you give it.
"""

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--nro", required=True)
    ap.add_argument("--textures")
    ap.add_argument("--mod")
    ap.add_argument("--mods")
    ap.add_argument("--out", default=str(ROOT / "dist" / "OpenRAC-Switch2-Setup"))
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    if out.exists():
        shutil.rmtree(out, ignore_errors=True)
    out.mkdir(parents=True, exist_ok=True)
    # the setup and what it runs
    shutil.copy2(HERE / "switch2_setup.py", out / "switch2_setup.py")
    (out / "tools").mkdir(exist_ok=True)
    shutil.copy2(HERE / "extractor.py", out / "tools" / "extractor.py")
    shutil.copytree(HERE / "openrac_common", out / "tools" / "openrac_common", ignore=SKIP, dirs_exist_ok=True)
    shutil.copytree(ROOT / "editor", out / "editor", ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "test_*.py", "tests", "*.orig", "addons", "*.md"), dirs_exist_ok=True)
    # the games' tables the extractors read
    for game in (ROOT / "games").glob("*/game.json"):
        target = out / "games" / game.parent.name
        target.mkdir(parents=True, exist_ok=True)
        shutil.copy2(game, target / "game.json")
    # what goes on the card
    bundle = out / "bundle"
    bundle.mkdir(exist_ok=True)
    shutil.copy2(args.nro, bundle / "openrac.nro")
    if args.textures:
        shutil.copytree(args.textures, bundle / "texture_packs", ignore=SKIP, dirs_exist_ok=True)
    if args.mod:
        shutil.copytree(args.mod, bundle / "mods" / pathlib.Path(args.mod).name, ignore=SKIP, dirs_exist_ok=True)
    if args.mods:
        for folder in sorted(pathlib.Path(args.mods).iterdir()):
            if (folder / "openrac-mod.json").is_file():
                shutil.copytree(folder, bundle / "mods" / folder.name, ignore=SKIP, dirs_exist_ok=True)
    # the marker that tells the tools this is a copy of OpenRAC, not a checkout (tools/openrac_common/paths.py)
    (out / "STANDALONE").write_text("", encoding="utf8")
    (out / "CREDITS.txt").write_text(CREDITS, encoding="utf8", newline="\r\n")
    shutil.copy2(ROOT / "COPYING", out / "COPYING")
    (out / "install.bat").write_text(BAT, encoding="utf8", newline="\r\n")
    (out / "install.sh").write_text(SH, encoding="utf8", newline="\n")
    (out / "README.txt").write_text(README, encoding="utf8", newline="\r\n")
    print("bundle written to", out)


main()
