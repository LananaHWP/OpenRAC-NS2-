#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
# Builds OpenRAC (Ratchet & Clank, NTSC-U) for the Nintendo Switch 2 in Docker: writes switch2/out/openrac.nro.
#
#   OPENRAC_RAC1_ISO=/path/to/your/disc.iso switch2/build.sh [ninja targets...]     (default target: openrac-rac1-ntsc)
#
# The first run builds the image `openrac-switch2-builder` (switch2/Dockerfile: devkitA64, OunceDevKit, Clang). Sources are copied into a Docker
# volume (`openrac-src`) first: building from a Windows bind mount is far too slow for CMake and ninja. The build lives in the volume
# `openrac-build`, so later runs only rebuild what changed. hostgen needs your own disc image: it translates the decompilation, and the
# few functions the decompilation has no C for, from it. Nothing of the disc is written outside the Docker volumes.
#
# Environment: CFG=1 forces a fresh configure; LOG=file keeps the build output (default switch2/build.log).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
ISO="${OPENRAC_RAC1_ISO:-}"
if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then
  echo "Set OPENRAC_RAC1_ISO to the image (.iso) of your own Ratchet & Clank (NTSC-U, SCUS-97199) disc." >&2
  exit 2
fi
LOG="${LOG:-$HERE/build.log}"
TARGETS="${*:-openrac-rac1-ntsc}"
mkdir -p "$HERE/out"
if ! docker image inspect openrac-switch2-builder >/dev/null 2>&1; then
  docker build -t openrac-switch2-builder -f "$HERE/Dockerfile" "$HERE"
fi
path() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi; }
MSYS_NO_PATHCONV=1 docker run --rm --name openrac-build \
  -v "$(path "$REPO"):/src:ro" -v "openrac-src:/work/openrac" -v "openrac-build:/build" -v "$(path "$HERE/out"):/out" -v "$(path "$HERE/icon.jpg"):/icon.jpg:ro" \
  -v "$(path "$ISO"):/work/openrac/baserom/SCUS_971.99.iso:ro" -w /work/openrac \
  openrac-switch2-builder bash -c '
set -e
cd /src && tar --exclude=./baserom --exclude=./build --exclude=./.git --exclude=./dist --exclude=./switch2/out --exclude=./games/rac1/ntsc-decomp/build --exclude=./games/rac1/ntsc-decomp/dumps -cf - port tools sdk docs games/rac1/ntsc-decomp-patches 2>/dev/null | tar -xf - -C /work/openrac
cd /work/openrac
if [ ! -f /build/s2/build.ninja ] || [ "'"${CFG:-0}"'" = 1 ]; then
  cmake -S port -B /build/s2 -G Ninja -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/libounce/cmake/Switch2.cmake -DCMAKE_BUILD_TYPE=Release \
    -DOPENRAC_PORT_WINDOW=ON -DOPENRAC_VULKAN=OFF -DOPENRAC_ENHANCED_RENDERING=OFF -DOPENRAC_RAC1_NTSC_RETAIL_IMAGE=/work/openrac/baserom/SCUS_971.99.iso 2>&1 | grep -v "^  \|^$\|Warning\|Call Stack\|openrac-rac[2-9]\|openrac-rac1-p\|openrac-rac1-j" | tail -15
fi
set +e
ninja -C /build/s2 -k 0 '"$TARGETS"'
rc=$?
if [ $rc -eq 0 ] && [ -f /build/s2/openrac-rac1-ntsc.elf ]; then
  /opt/devkitpro/tools/bin/nacptool --create "OpenRAC (Ratchet & Clank)" "Lanana420" "0.1" /out/openrac.nacp
  /opt/devkitpro/tools/bin/elf2nro /build/s2/openrac-rac1-ntsc.elf /out/openrac.nro --nacp=/out/openrac.nacp --icon=/icon.jpg && ls -l /out/openrac.nro
fi
echo "build-exit $rc"
' 2>&1 | tee "$LOG"
