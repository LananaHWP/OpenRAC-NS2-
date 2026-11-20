#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
"""Finds the NTSC address of each rac-rs hook function by its masked code hash (rac-rs oracle/src/hs_reloc.rs: FNV-1a over the code words,
relocated fields masked, absolute j targets made base-relative) in the NTSC level overlay (level_00) and the boot executable.

  find_ntsc_hooks.py RELOC_TXT OVERLAYS_DIR BOOT_ELF [IDPREFIX ...]  ->  JSON lines: id, region, address, name
"""
import json, struct, sys
import numpy as np

FNV_O = 0xCBF29CE484222325
FNV_P = 0x100000001B3

def parse(path):
    specs, cur = [], None
    for line in open(path, encoding='utf8'):
        w = line.split()
        if not w:
            continue
        if w[0] == 'hook':
            cur = {'id': w[1], 'masks': {}, 'jabs': [], 'mhash': 0, 'len': 0, 'entry': 0, 'name': ''}
            specs.append(cur)
        elif cur is None:
            continue
        elif w[0] == 'reloc' and len(w) >= 6:
            cur['name'], cur['entry'], cur['len'] = w[1], int(w[3], 16), int(w[5], 16)
        elif w[0] == 'mhash':
            cur['mhash'] = int(w[1], 16)
        elif w[0] == 'mask' and len(w) >= 3:
            o = int(w[1], 16) // 4
            cur['masks'][o] = cur['masks'].get(o, 0) | int(w[2], 16)
        elif w[0] == 'jabs':
            cur['jabs'].append(int(w[1], 16) // 4)
    return [s for s in specs if s['len']]

def elf_text(path):
    d = open(path, 'rb').read()
    phoff, phentsize, phnum = struct.unpack_from('<I', d, 0x1c)[0], struct.unpack_from('<H', d, 0x2a)[0], struct.unpack_from('<H', d, 0x2c)[0]
    segs = []
    for i in range(phnum):
        p_type, p_off, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags = struct.unpack_from('<IIIIIII', d, phoff + i * phentsize)
        if p_type == 1 and p_flags & 1:  # PT_LOAD, executable
            segs.append((p_vaddr, d[p_off:p_off + p_filesz]))
    return segs

def search(words, base_addr, spec):
    L = spec['len'] // 4
    n = len(words) - L + 1
    if n <= 0:
        return []
    pos = np.arange(n, dtype=np.uint32)
    base = (np.uint32(base_addr) + pos * np.uint32(4)).astype(np.uint32)
    h = np.full(n, FNV_O, dtype=np.uint64)
    for k in range(L):
        w = words[k:k + n].copy()
        if k in spec['jabs']:
            t = (((w & np.uint32(0x03FFFFFF)) << np.uint32(2)) - base) & np.uint32(0x0FFFFFFF)
            w = (w & np.uint32(0xFC000000)) | (t >> np.uint32(2))
        m = spec['masks'].get(k, 0)
        if m:
            w = w & np.uint32(~m & 0xFFFFFFFF)
        h = (h ^ w.astype(np.uint64)) * np.uint64(FNV_P)
    hits = np.nonzero(h == np.uint64(spec['mhash']))[0]
    return [int(base_addr + 4 * i) for i in hits]

def main():
    reloc, overlays, boot = sys.argv[1:4]
    prefixes = sys.argv[4:]
    specs = [s for s in parse(reloc) if not prefixes or any(s['id'].startswith(p) for p in prefixes)]
    regions = []
    import os
    for lv in os.environ.get('LEVELS', '00').split(','):
        man = json.load(open(overlays + '/level_%s/manifest.json' % lv))
        text = [r for r in man['records'] if r['name'] == 'text'][0]
        regions.append(('L' + lv, text['address'], np.frombuffer(open(overlays + '/level_%s/text.bin' % lv, 'rb').read(), dtype='<u4')))
    for i, (va, data) in enumerate(elf_text(boot)):
        data = data[:len(data) // 4 * 4]
        regions.append(('boot', va, np.frombuffer(data, dtype='<u4')))
    for s in specs:
        found = []
        for name, addr, words in regions:
            for a in search(words, addr, s):
                found.append((name, a))
        print(json.dumps({'id': s['id'], 'rac_rs_entry': hex(s['entry']), 'len': hex(s['len']), 'ntsc': [(n, hex(a)) for n, a in found]}), flush=True)

main()
