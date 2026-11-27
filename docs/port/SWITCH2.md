# OpenRAC on the Nintendo Switch 2 (OunceDevKit)

Status (2026-11-19): the NTSC Ratchet & Clank program compiles and links into `openrac.nro`. It has **not been run on a console yet**
(hardware results are what the next step needs). Everything Switch 2 specific is in `port/platform_switch2/`, `port/cmake/OpenracSwitch2.cmake`
and small `OPENRAC_SWITCH2` branches in a few shared files.

## Build

`switch2/build.sh` (Docker image `openrac-switch2-builder`: the Switch 2 devkit plus Clang for hostgen). It syncs the
sources into a Docker volume (building from the Windows bind mount stalls), configures with the devkit's `Switch2.cmake` toolchain and
`-DOPENRAC_PORT_WINDOW=ON -DOPENRAC_VULKAN=OFF -DOPENRAC_ENHANCED_RENDERING=OFF`, builds `openrac-rac1-ntsc` and makes
`out/openrac.nro` with `elf2nro`.

hostgen needs the disc and five rows in `port/game/rac1-ntsc/checks/assembly_allow.tsv` (functions the decomp has no C for and translates
from the retail instructions: FUN_001251e8, func_00118338, func_001271D8, func_0012A2D8, malloc_extend_top).

## What replaces what

| PC | Switch 2 |
|---|---|
| SDL3 window, GL context, pad, audio, timers | `platform_switch2/sdl3_shim.cpp`: SDL3's own headers, the ~110 functions the port calls, on libounce: the NWindow + EGL (OunceVK + Zink, OpenGL 4.1 core), libnx pad, audout |
| `mmap` of the 4 GB game address space | `runtime/memory.cpp` Switch 2 branch: `virtmemFindAslr(4 GB)` + `svcMapPhysicalMemory` per region (no uncached RAM aliases) |
| signals, `dlopen`, `execinfo`, `sysinfo`, `uname`, `statfs` | `platform_switch2/compat/` headers and `compat.c` stand-ins; `runtime_crash.cpp` (no fault reports) |
| the retail libc inside the generated game C | built with `-D_SYS_REENT_H_` so newlib's `struct _reent` and friends do not meet the generated copies |
| libGL for Dear ImGui's loader | `dlopen("libGL")` answers with an EGL `eglGetProcAddress` lookup (`compat.c`) |
| the Vulkan renderer (volk) | off: volk's global function names clash with the console's Vulkan library |

Data lives on the SD card: `sdmc:/switch/openrac/` (saves, settings, controls, logs) and `sdmc:/switch/openrac/data/iso_data/rac1/` (the
disc image as `disc.iso`, `SCUS_971.99`, `SYSTEM.CNF`: `python tools/extractor.py IMAGE --game rac1 --extract --boot-only --proj-path DIR`).
Nothing is ever read from or written to the console's own storage.

**Logging is off unless the file `sdmc:/switch/openrac/debug.txt` exists** (any content, checked once at start): without it neither boot.txt nor the program's own log
(`openrac-rac1-ntsc.log`) is written. With it: `sdmc:/switch/openrac/boot.txt` is a trace written at each start-up step (main, memory, window, GL context, first swaps, clocks): the last line
left after a crash or a silent exit says how far the start got.

## Speed (from the RAC-RS tests on this console)

`platform_switch2/perf.c` carries the findings over:
- docked the CPU defaults to 998 MHz, in hand 1100 MHz; `appletSetCpuBoostMode(FastLoad)` lifts it to 1523 MHz but throttles the GPU to
  306 MHz, so the GPU is put back to 1007 MHz and kept there; the memory clock is set to the top step of its list (3750 MHz)
- the system resets the clocks when the console is docked or undocked: a keeper thread (once a second) notices and applies it again
- **in hand the CPU really runs at about half the reported clock** (a dependent-add loop measured 759 MHz at a reported 1523; memory read
  11 GB/s against 16 GB/s docked); no performance configuration or clock setting changes it. The in-hand budget is one 760 MHz thread.
- `sdmc:/switch/openrac/perf_off.txt` turns all of it off

The game is native C, so the 760 MHz budget is not expected to be a problem (RAC-RS's emulation of the PS2 CPU cost 3 to 4 host cycles per
guest cycle; this has none of that).

## Not verified on hardware yet

1. `svcMapPhysicalMemory` inside the 4 GB reservation (needs a system resource size for the process); the probe
   (`switch2/probe/` (probe.c, Makefile.sh)) reports the region sizes and tries it, and logs `sdmc:/switch/openrac-probe/log.txt`.
2. OpenGL 4.1 core through EGL on this driver (version strings, shader compile time, frame rate); the same probe.
3. The game itself: whether it boots, and at what speed.

## Arsenal Mastery (optional mod)

The mod (rac-rs `bundled/mods/arsenal-mastery`, Luau, manifest format 2, api 1.3) is already in OpenRAC's script mod format and stays a
separate, removable folder: `sdmc:/switch/openrac/mods/arsenal-mastery/`. The original game is the game without that folder (or `--no-mods`).
It needs the **omni extension** that rac-rs's loader adds to the `openrac` table.

Done (2026-11-19):
- `switch2/tools/find_ntsc_hooks.py` finds the NTSC address of each hook function by rac-rs's masked code hash (FNV-1a over the
  code words, relocated fields masked; rac-rs `oracle/src/hs_reloc.rs`) in the NTSC level 0 overlay (extracted from the disc by the decomp's
  `scripts/overlay-extract.py --iso`) and the boot executable. 54 of the 57 `rac1.omni.*` hooks matched one function.
- Merged into `sdk/bindings/rac1.json`: 51 hook points (17 are aliases of hook points OpenRAC already had: the catalogue's moby updates and a
  few table hooks, whose ids stay), 81 `omni.*` fields; `gen_binding.py` regenerated the script binding, types, id lock and hook rows;
  the omni table hooks have hand-written `hook` rows in `port/game/rac1-ntsc/libraries.tsv`; `parity.tsv` says why they are NTSC only.
- Left out for now: hooks on functions the port wraps itself (`moby_delete`, `fx_explode`, `weapon_ryno_fire`), on code hostgen has no
  function for (`menu.weapons_page.update/draw`, `projectile.hit_face_id`), and `goldcase.update` (its function is in another level).
  The mod checks `omni.has(...)` and works without them.
- The PAL rows of the merged hooks are anchors only (their PAL symbols are guesses from rac-rs's PAL entry addresses): the PAL program was
  not built or checked.

To do: (1) the `omni` table in C++ in `port/game/common/mod_scripts.cpp`: `has`, `struct` / `struct_set` (layouts in rac-rs's binding
`structs`), `mobys`, `moby_valid`, `is_enemy`, `fn` (`functions`), events (`save_loaded`, `level_loaded`, `mode`, `pause_page`), `save` (per save
slot), `draw`, `pose`, `raycast`, `with_stack` / `unwound`; (2) the mod on the Switch: ship it in `sd/switch/openrac/mods/`, with a switch
(a file on the SD card) and the original game when it is off; (3) check all of it on the console.

### Notes for the omni layer (found while scoping it)

- rac-rs derives its events (`level_loaded`, `level_unloading`, `mode`, `pause_page`) once per field from RAM words (rac-rs `engine/omni/events.rs`,
  `rac1/omni_bind.rs`): level word `0x15ed84` (0..18 = a level is loaded; same address on PAL and NTSC), level-loop exit word, game-mode word
  (0 gameplay, 1 movie, 2 cutscene, 3 pause, 4 dialog, 5 vendor, 6 ship, 7 screen) and the open pause page's id. Addresses above `0x15ef00` are
  the level overlay's data and move per level and per disc (rac-rs `disc_map.rs`; NTSC L00's mode word is `D_L00_0015F5C4`), so the OpenRAC host
  must read them through its own per-level names, as `port/game/rac1/host/boot.c` does (`LEVEL_MODE`, `loaded_level`, `in_level()`), from
  `openrac_game_on_frame`.
- `save_loaded` / `saving` / `new_game` come from rac-rs's memory-card watcher (`rac1/omni_bind/card.rs`) and its New Game+ spec; OpenRAC's
  equivalent is its own memory card layer (`lib/mc.c`, `host/save_marks.c`).
- The mod's own gate is `omni.has("omni.save") and omni.has("omni.events")`: until both exist it logs one line and does nothing, so enabling it
  before the omni layer is written is harmless.
- OpenRAC's own memory card layer already tells the host which save slot is in play (`port/game/common/lib/mc.c`: `openrac_game_card_slot`,
  `openrac_game_card_write`, the `save<N>.bin.mods` marks, `save_slot_of`): the omni `save_loaded` / `saving` events and the per-save store can be
  built on it rather than on rac-rs's card watcher. The script host's services (`Services` in `mod_scripts.h`) have no data directory yet: add
  `api_data_dir` (mods.cpp) to it for the store, and `openrac_game_loaded_overlay()` / `openrac_game_mode()` (game_host.h) give the level and mode.

### The omni table: first version (compiled, not run)

`port/game/common/mod_omni.luau` (+ `mod_omni_structs.luau`, `gen_omni_prelude.py` -> `mod_omni_prelude.inc`, run by `install_omni` in `mod_scripts.cpp`
before a script mod's own scripts, inside a pcall, so a fault in it only leaves that mod without `omni`). Host helpers: `level` (the loaded level
program), `mode` (the game-mode word while a level is loaded), `has_hook`, and `read_file` / `write_file` in the mod's data folder (`Services::data_dir`).
Provided: the basics (log, setting, read, write, fields, hook, before, after, on_frame, on_pad, ticks_per_second, unwound), `struct`, `struct_set`
(nil address = probe, as in rac-rs), `out_f32`, `level`, `mode`, `pause_page` (always nil), events `level_loaded`, `level_unloading`, `mode`, and
`save` (get / set / keys / clear / version, one store for all saves, written to `omni-save.dat` every 5 s while dirty). Missing: `mobys`,
`moby_valid`, `is_enemy`, `fn`, `draw`, `pose`, `raycast`, `with_stack`, and the events `save_loaded`, `saving`, `new_game`, `pause_page`, `setting`.
Arsenal Mastery's gate (`omni.has("omni.save") and omni.has("omni.events")`) now passes, so with the mod enabled it runs its modules that need only
these; the log (`sdmc:/switch/openrac/data/`) says which it skipped. Its XP is not kept per save slot until the card events exist.

## Button pictures, rename, scripts' time budget (2026-11-20)

- The game's own button pictures (the ten cells of the font sheet, `port/renderer/textures/button_glyphs.cpp`) are redrawn when the sheet is
  converted: Switch style (the default on the console: B at the foot, A right, Y left, X top, L R ZL ZR and the sticks, from the CC BY 4.0
  *Switch Button Icons* pack, `tools/make_switch_glyphs.py`) or Letters (A B X Y, drawn in code). Setting `game_button_glyphs = 0|1|2`
  (PlayStation, Letters, Switch). The sheet is recognised by its structure (the ten cells' dither background), not by a hash.
  Remapped buttons are not followed. The Controls tab's pad names are the console's (`debug/menu_controls.cpp`).
- Horizon's file system refuses `rename()` onto an existing file: the link wraps it (`--wrap=rename`, `compat.c`): the target is moved aside and put back
  if the rename fails.
- `sdmc:/switch/openrac/env.txt` (`NAME=value` lines) sets OPENRAC_* variables at start (there is no shell): for example
  `OPENRAC_DUMP_TEXTURES=sdmc:/switch/openrac/dump`.
- A script mod's first run (its files compiled and set up) has a 1 s budget on the console; hooks keep 25 ms (a desktop's is 2 ms).
- The window is on by default (no command line on the console), and the extracted levels are needed in `data/port/ntsc/`
  (`python editor/extract.py port IMAGE build/ntsc-levels`, copied to `sdmc:/switch/openrac/data/port/ntsc`).

## Setup for players (2026-11-20)

`tools/switch2_setup.py` (a window, or `--cli`; started by `install.bat` on Windows and `install.sh` on Linux) puts the game on the console from the
player's own disc image, **onto an SD card in the PC** (`--sd E:\`) **or over FTP** (`--ftp HOST[:PORT]`, the Switch 2 FTP server's default port is 1337 with
no user or password). It checks the disc (tools/extractor.py), writes the boot files and the image (`data/iso_data/rac1/`), exports the levels
(`editor/extract.py port`, to `data/port/ntsc/`), copies `openrac.nro`, the texture pack (Switch help screen, preview, logo) and, when ticked, the
Arsenal Mastery mod (`data/plugins/`, an optional extra: the original game is the game without that folder). For FTP the files are made in a work folder
next to the image (the image is hard-linked, not copied, on the same drive), then uploaded with Python's own ftplib (no system `ftp` program is needed,
so Windows and Linux behave the same): small files first, an upload that stops is resumed (REST, or from the start for a server without it), a size check
follows each file, and the work folder is deleted after. Without python3-tk the setup asks its questions in the terminal.
`tools/make_switch2_bundle.py --nro ... --textures ... --mod ...` collects the setup, the extractors and the card's files into
`dist/OpenRAC-Switch2-Setup/` (install.bat, install.sh, README.txt): nothing of the game itself is in it. Tested end to end: to a folder, and over FTP
(15,674 files, 4.86 GB, to a local server; a disc image cut at 1.5 GB resumed and matched byte for byte). Not tested: the window, a Linux machine, a real console's FTP server.

## Arsenal Mastery on the console: what works (2026-11-20)

Works: enemies found (`omni.mobys`, `is_enemy`), XP and levels per save, the HUD drawn over the game (`omni.draw`), the hooks the mod uses
(damage resolver in the executable, hit victim, blast, the weapon fire hooks, wrench, ammo, health draw, moby delete, R.Y.N.O. fire, the gold
case). Not yet: `omni.fn`, `omni.with_stack`, `omni.pose`, `omni.raycast` and the `collide.sphere_mobys` hook (a host function of the port's,
which hostgen cannot put a hook under): the perks that need them (the minibomb, dual blasters, glove of doom, hit path, pyrocitor, tesla claw's
line of sight, the sphere radius perks) stay off, and the mod says so in the log.

## 0.2 (2026-11-20)

- **Mods.** Quick Select pause and Steady strafe are script mods in `switch2/mods/` beside Arsenal Mastery, each its own choice in the setup
  (`plugins.json` lists the ones installed; all off is the plain game). Both come from rac-rs: the update mask and the Quick Select ring's fade
  byte for the pause, the camera's yaw word (per level), the aim words (0x140600, 0x14060c) and the hero's words for the strafe, with the USA
  disc's addresses taken from rac-rs's PAL to USA map. A script sees only game RAM through `openrac.read` and `openrac.write`; what the renderer
  draws of a moby is its three rotation rows (+0xC0, +0xD0, +0xE0), which the game rebuilds from the Euler angles in each update, so the strafe
  turns the rows and not only the yaw word, from a hook after the hero's update (`rac1.player.update`) and before the frame is taken. What the
  hero holds is turned about him by the same angle: the weapon in his hand (item slot 0 at 0x1403e0), and the Bomb Glove's bomb (class 121). The
  Bomb Glove's own update (class 192) runs with the hero's frame words (0x13f990, 0x13f9a0, 0x13f9b0, 0x13f9c0 and his logic facing) turned to
  the camera's heading, as rac-rs does, so a thrown bomb goes where the camera looks.
- **Clocks.** `cpu_max.txt` on the card asks for the CPU's own clock 20 seconds after the start (`perf.c`): the console clamps 1785 MHz to its
  highest step, 1702 MHz, which a timed loop measured (1516 MHz before, 1700 MHz after) and which held 60 frames a second docked on the first
  planets. Asked at the start, while the GPU was being set up, it lost the GPU.
- **GPU lost at the start.** `VK_ERROR_DEVICE_LOST` right after the first frame left bad cache files (`.cache/openrac`, and OunceVK's
  `config/ouncevk/shader-cache`), and every later start failed until they were deleted. Skipping the startup video in its first moments did it,
  so Start is ignored for a video's first 120 blanks on the console (`movie.cpp`), and the OpenGL state warm-up, the cache's writer, is off
  there by default (`OPENRAC_RENDER_OPT_OFF=gl-state-warmup`, set in `openrac_switch2_load_env` unless `env.txt` names its own list). No crash
  followed in the tests after that.
- **Going Commando (PAL), experimental.** `switch2/build_rac2.sh`, its own folder on the card (`OPENRAC_SWITCH2_HOME`, `switch/openrac-rac2`).
  The PAL disc's frame is at block 0x1E00, where the USA discs' is 0x1E80 (`profile.cpp`), the audio layer mixes every open stream (a video
  used to take the game's sound over), the card's folder listing carries `.` and `..` (Horizon's file system has neither, the game counts
  its nine entries) and a video's picture is drawn over an earlier off-screen target at its block. Open: the first level froze at a dialog,
  and the loading screens and the thruster fire drew wrong, before the last of these fixes; not checked since. The build's freeze finder
  (`RING=ON`) writes the last functions the game ran to `boot.txt` every 3 seconds.

## 0.3: Going Commando released (2026-11-27)

Tested on the console: the first level and most of the second without problems, about 40 frames a second in places with the game at full speed.

- **The first enemy's freeze.** The animation step (`rac2-pal/hand/func_002A0F68.c`) divided by zero. The EE's divide and multiply saturate; the
  host's make an infinity, then a NaN, which the stepping loops never left. Both saturate now, and the loops are bounded. Not reported since.
- **Glows through walls.** With the profile's precise depth (glClipControl) the effect quads showed through walls and the ship's hull on the
  console. Leaving the quads out removed them. `precise_depth()` is off on the Switch (`rac2/profile.cpp`); why the precise path leaks is not
  established. At 24 bits and a near of 0.05, Maktar's dome may flicker (not seen).
- **The continue point.** After a death the first level's opening object was made anew and moved Ratchet back to the level's start, after the
  game had put him at the saved continue point. `rac2-pal/host/launch.c` makes it finished when a continue point is saved. How the PS2 avoids
  this is not known.
- **RAC3-style health** (`switch2/mods/rac3-health`, PAL). Two new hook points, `rac2.player.max_health.update` and
  `rac2.hud.health_meter.experience`. The number box is native (`rac2-pal/host/health_hud.c`), drawn from the HUD's own ammo box pieces and font
  while the mod is loaded; without it the game's segments are drawn. The NTSC releases have stubs. A weak reference does not pull a host file out
  of the game's static library, so `rac2/host/hud.c` names it with a plain one.
- **The setup** knows both discs (`SCUS_971.99`, `SCES_516.07`), each with its own program, folder on the card and mods; the bundle takes
  `--nro-rac2`.
