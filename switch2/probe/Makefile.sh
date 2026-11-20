# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 the OpenRAC contributors
set -e
cd /work/probe
aarch64-none-elf-gcc -mcpu=cortex-a78c+crypto -mtp=soft -ftls-model=local-exec -ffunction-sections -fdata-sections -D__SWITCH__ -D__SWITCH2__ -O2 -isystem /opt/devkitpro/libounce/include -isystem /opt/devkitpro/portlibs/switch2/include -fPIE -specs=/opt/devkitpro/libounce/switch.specs -L/opt/devkitpro/portlibs/switch2/lib -L/opt/devkitpro/libounce/lib probe.c -o probe.elf -lEGL -lnx -lm
/opt/devkitpro/tools/bin/elf2nro probe.elf openrac-probe.nro
ls -l openrac-probe.nro
