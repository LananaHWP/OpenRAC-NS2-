#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
"""Writes mod_omni_prelude.inc, the Luau source of the `omni` table as a C++ raw string, from mod_omni.luau and the record layouts.

    python3 port/game/common/gen_omni_prelude.py [--structs rac1.json]

The layouts (`structs` of rac-rs's omni binding: moby, hit, hit_desc, the weapons' projectiles ...) are read from the JSON given, and
written to mod_omni_structs.luau (checked in), which the include is made from; without --structs the checked-in file is used.
"""
import argparse
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
TYPES = ("u8", "i8", "u16", "i16", "u32", "i32", "f32")


def structs_luau(path):
    data = json.loads(pathlib.Path(path).read_text(encoding="utf8"))
    lines = ["local STRUCTS = {"]
    for name, s in data["structs"].items():
        fs = []
        for f in s["fields"]:
            if f["type"] not in TYPES:
                continue
            fs.append('%s={%d,"%s",%s}' % (f["name"], int(f["offset"], 16), f["type"], "true" if f.get("readonly") else "false"))
        lines.append("\t%s = { %s }," % (name, ", ".join(fs)))
    lines.append("}")
    return "\n".join(lines) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--structs")
    a = ap.parse_args()
    structs_file = HERE / "mod_omni_structs.luau"
    if a.structs:
        structs_file.write_text(structs_luau(a.structs), encoding="utf8", newline="\n")
    body = (HERE / "mod_omni.luau").read_text(encoding="utf8").replace("\r\n", "\n")
    structs = structs_file.read_text(encoding="utf8").replace("\r\n", "\n")
    # `local H = ...` stays the first statement of the chunk; the layouts follow it
    body = body.replace("local H = ...\n", "local H = ...\n" + structs, 1)
    out = ('// Generated from mod_omni.luau and mod_omni_structs.luau by port/game/common/gen_omni_prelude.py. Do not edit.\n'
           'R"OMNILUAU(\n' + body + ')OMNILUAU"\n')
    (HERE / "mod_omni_prelude.inc").write_text(out, encoding="utf8", newline="\n")
    print("mod_omni_prelude.inc:", len(out), "bytes")


main()
