#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
# Builds OpenRAC Ratchet & Clank: Going Commando (Europe/Australia, SCES_516.07) for the Nintendo Switch 2 in Docker: writes
# switch2/out/openrac-rac2.nro.
#
#   OPENRAC_RAC2_ISO=/path/to/your/disc.iso switch2/build_rac2.sh [ninja targets...]     (default target: openrac-rac2-pal)
#
# As build.sh, with its own build volume (`openrac-build-rac2`) and its own data folder on the card (switch/openrac-rac2, the build's
# OPENRAC_SWITCH2_HOME). Environment: CFG=1 forces a fresh configure; RING=ON (with CFG=1) builds the freeze finder: every generated function
# notes its entry, and with debug.txt on the card the last ones are logged to boot.txt every 3 s (it slows the game down).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
ISO="${OPENRAC_RAC2_ISO:-}"
if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then
  echo "Set OPENRAC_RAC2_ISO to the image (.iso) of your own Going Commando (PAL, SCES_516.07) disc." >&2
  exit 2
fi
LOG="${LOG:-$HERE/build_rac2.log}"
TARGETS="${*:-openrac-rac2-pal}"
mkdir -p "$HERE/out"
if ! docker image inspect openrac-switch2-builder >/dev/null 2>&1; then
  docker build -t openrac-switch2-builder -f "$HERE/Dockerfile" "$HERE"
fi
path() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi; }
MSYS_NO_PATHCONV=1 docker run --rm --name openrac-build-rac2 \
  -v "$(path "$REPO"):/src:ro" -v "openrac-src:/work/openrac" -v "openrac-build-rac2:/build" -v "$(path "$HERE/out"):/out" -v "$(path "$HERE/icon.jpg"):/icon.jpg:ro" \
  -v "$(path "$ISO"):/work/openrac/baserom/SCES_516.07.iso:ro" -w /work/openrac \
  openrac-switch2-builder bash -c '
set -e
cd /src && tar --exclude=./baserom --exclude=./build --exclude=./.git --exclude=./dist --exclude=./switch2/out --exclude=./games/rac1/ntsc-decomp/build --exclude=./games/rac1/ntsc-decomp/dumps --exclude=./games/rac2/decomp/.git --exclude=./games/rac2/decomp/build -cf - port tools sdk docs games/rac1/ntsc-decomp-patches games/rac2 2>/dev/null | tar -xf - -C /work/openrac
cd /work/openrac
if [ ! -f /build/s2/build.ninja ] || [ "'"${CFG:-0}"'" = 1 ]; then
  cmake -S port -B /build/s2 -G Ninja -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/libounce/cmake/Switch2.cmake -DCMAKE_BUILD_TYPE=Release \
    -DOPENRAC_PORT_WINDOW=ON -DOPENRAC_VULKAN=OFF -DOPENRAC_ENHANCED_RENDERING=OFF -DOPENRAC_SWITCH2_HOME=openrac-rac2 -DOPENRAC_SWITCH2_CALL_RING='"${RING:-OFF}"' \
    -DOPENRAC_RAC2_PAL_RETAIL_IMAGE=/work/openrac/baserom/SCES_516.07.iso 2>&1 | tail -25
fi
set +e
ninja -C /build/s2 -k 0 '"$TARGETS"'
rc=$?
if [ $rc -eq 0 ] && [ -f /build/s2/openrac-rac2-pal.elf ]; then
  /opt/devkitpro/tools/bin/nacptool --create "OpenRAC (Going Commando)" "Lanana420" "0.3" /out/openrac-rac2.nacp
  /opt/devkitpro/tools/bin/elf2nro /build/s2/openrac-rac2-pal.elf /out/openrac-rac2.nro --nacp=/out/openrac-rac2.nacp --icon=/icon.jpg && ls -l /out/openrac-rac2.nro
fi
echo "build-exit $rc"
' 2>&1 | tee "$LOG"
