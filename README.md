# OpenRAC for Switch 2

This is my port of Ratchet & Clank 1 to the Nintendo Switch 2, built on top of [OpenRAC](https://github.com/OpenRAC/OpenRAC). OpenRAC takes the PS2 games, decompiles them back to C and builds them as normal native programs. I got the NTSC-U version of the first game running that way on the Switch 2, using [OunceDevKit](https://github.com/ouncebrew/ounce-devkit). There's no emulation going on.

You need your own copy of the game. The setup reads your disc image, and nothing from the game is in this repo.

Ratchet & Clank belongs to Sony and Insomniac, and Nintendo Switch belongs to Nintendo. This is a fan project and has nothing to do with any of them.

## Where it's at

It runs docked and in handheld, and in the testing I did (mostly the first level) it ran about as fast as it should. It's NTSC-U Ratchet & Clank 1 only for now. I haven't played through everything, so expect bugs.

Version 0.2 adds two more optional mods, Quick Select pause and Steady strafe, and each mod is now its own choice in the setup (see "Mods" below). The engineering notes are in [docs/port/SWITCH2.md](docs/port/SWITCH2.md) if you want the details.

Going Commando (PAL) also builds with `switch2/build_rac2.sh`. It boots, plays the menus and the videos and loads the first level, but it isn't released: the first level froze, and the loading screens and the ship's thruster fire drew wrong, and I haven't been able to check them since the last fix. The 0.2 release is Ratchet & Clank 1 only.

## What I added to OpenRAC

- A Switch 2 platform layer in `port/platform_switch2/`. It covers the window and OpenGL, the pad and the audio, plus a few things Horizon doesn't have. The console wouldn't give me one big 4 GB block of memory, so the game's memory is a handful of normal buffers that get looked up by address. There's also a small thread that keeps the CPU boost on without dragging the GPU clock down.
- Switch button prompts. The button icons in the game's text, the Help > Controls screen and the menu overlay all show Switch buttons. In menus A and B are swapped so A confirms and B goes back. You can turn that off with `game_menu_swap_ab = 0` in the settings.
- Three optional script mods, all from rac-rs's work: Arsenal Mastery, Quick Select pause and Steady strafe, and the layer the first needs to run on OpenRAC (`port/game/common/mod_omni.luau`).
- A setup tool that gets the game onto the console over FTP, onto an SD card, or into a folder on your PC.
- Logging is off by default. Put an empty `switch/openrac/debug.txt` on the card if you want `boot.txt` and the log files for a bug report.

## Installing

You need an image (.iso) of your own NTSC-U disc, a Switch 2 that can run homebrew, a bit over 6 GB free on the SD card (exFAT), and Python 3.9 or newer on your PC.

Build the setup bundle (see below) or grab one from the releases, then:

1. Windows: run `install.bat`. Linux and macOS: `sh install.sh`.
2. Pick your disc image, then choose FTP, an SD card or a folder. For FTP, start an FTP server on the console and type in its address. The Switch 2 one uses port 1337 and no login. For an SD card, point it at the card. For a folder, pick any folder on your PC: the setup writes a `switch` folder into it and you copy that onto the card's root yourself.
3. Tick the mods you want: Arsenal Mastery, Quick Select pause, Steady strafe. Each is its own tick box and all of them off is the plain game.
4. Press Install. It checks the disc, exports the levels on your PC and sends everything to `switch/openrac` on the card. That's around 5 GB, and an FTP upload that gets interrupted picks up where it stopped if you run it again.
5. Start OpenRAC from the homebrew menu.

You can also run it from a terminal: `python3 switch2_setup.py --cli --iso GAME.iso --ftp 192.168.1.50`, `--sd E:\` for a card, or `--folder D:\OpenRAC-out` for a folder.

Files on the card, in `switch/openrac/`:

- `data/` holds the game's data and `data/plugins/` the mods. To turn a mod off, delete its folder there or set its `"enabled"` to `false` in `plugins.json`.
- `settings/` has the settings. `game_button_glyphs` is 0, 1 or 2 for PlayStation, letter or Switch prompts.
- `env.txt` sets `OPENRAC_*` variables, one `NAME=value` per line.
- `perf_off.txt` turns the clock changes off.
- `cpu_max.txt` is an experiment, off without the file: 20 seconds after the start the program also asks for the CPU's own clock, which the console clamps to its highest step, 1702 MHz (the file may name a clock in MHz to try first). It held 60 frames a second docked on the first planets here. Asked at the very start, while the GPU was being set up, it lost the GPU, which is why it waits.

## Building

You only need Docker. The image has devkitA64, OunceDevKit and Clang in it.

```sh
OPENRAC_RAC1_ISO=/path/to/your/disc.iso switch2/build.sh        # makes switch2/out/openrac.nro
python3 tools/make_switch2_bundle.py --nro switch2/out/openrac.nro --mods switch2/mods --out dist/OpenRAC-Switch2-Setup
```

The build needs your disc image because hostgen translates the decompilation from it, along with a few functions the decompilation doesn't have C for. The bundle can also take a folder of texture pack pictures with `--textures`. The help screen pictures come from `tools/make_controls_help.py` and the Switch button icons from `tools/make_switch_glyphs.py`. Both need the icon pack listed in the credits. `tools/make_logo_pack.py` makes a title logo from an image you give it.

Most of the Switch 2 code is in `port/platform_switch2/` and `port/cmake/OpenracSwitch2.cmake`, with small `OPENRAC_SWITCH2` branches in `port/runtime`, `port/platform`, `port/renderer/textures`, `port/game/common` and `port/game/rac1*`. The build script, the Docker image and the rest are in `switch2/`.

## Mods

All three are script mods in `switch2/mods/`, off unless you tick them in the setup.

- **Arsenal Mastery** gives every weapon levels and XP, like Ratchet & Clank 3, and makes health work the same way. Enemies, XP, levels, the HUD bars and the damage scaling all run. A few of its perks still need pieces I haven't written (`omni.fn`, `omni.with_stack`, `omni.pose`, `omni.raycast`, and one hook that sits on a function the port implements itself). Those perks stay off and the mod says so in the log.
- **Quick Select pause** stops the world while the Quick Select ring is up (hold Y), as in the later games. It clears the game's world-update mask for those ticks and puts it back after each one.
- **Steady strafe** is rac-rs's Steady strafe aiming, USA disc only: hold ZR and Ratchet side-steps and backpedals facing where the camera looks, with the weapon in his hand and the Bomb Glove's bomb turning with him, and the shots following the camera. ZR is the strafe button while it's on (the game uses it to crouch). What's missing: the legs don't twist or run backwards for a backpedal, the Mine Glove, Devastator and R.Y.N.O. aim as the game does, and the camera doesn't change (no Raised or Shoulder modes, aim circle or lock-on).

## If it won't start

A black screen at the start with `debug.txt` on and `stderr.txt` saying `VK_ERROR_DEVICE_LOST` means the GPU was lost and a cache kept something bad. Delete the folder `.cache/openrac` at the root of the card and the files in `config/ouncevk/shader-cache/`; both are rebuilt. Pressing + to skip the startup video in its first moments did it here, so the program now ignores Start for the first two seconds of a video, and the OpenGL state warm-up that kept the states is off on the console (`OPENRAC_RENDER_OPT_OFF=gl-state-warmup` is the default there).

## Credits

- [OpenRAC](https://github.com/OpenRAC/OpenRAC) and its contributors. Everything here sits on their work: the decompilations, the tools that turn them into a native program, the renderer, the mod SDK and the script host. They credit the decompilation projects they use in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and [LICENSE.md](LICENSE.md) says which license covers which folder. OpenRAC's own README is [README.openrac.md](README.openrac.md).
- [rac-rs](https://github.com/AsobiCodes/rac-rs) by AsobiCodes. Arsenal Mastery is theirs ([AsobiCodes/arsenal-mastery](https://github.com/AsobiCodes/arsenal-mastery), MIT, Copyright (c) 2026 AsobiCodes). The copy in `switch2/mods/arsenal-mastery` is unchanged except that I wrote its manifest as `openrac-mod.json`. The mod was written for rac-rs's OmniLoader, so `mod_omni.luau` reimplements that for OpenRAC's script host, using rac-rs's published binding for the hook points and their code hashes, the record layouts and the way it walks the moby pool. `switch2/tools/find_ntsc_hooks.py` uses those hashes to find each function on the NTSC disc. The clock and speed findings from the RAC-RS tests on the Switch 2 shaped `platform_switch2/perf.c`. Quick Select pause and Steady strafe are rac-rs's "Quick Select pauses the game" and Steady strafe aiming written as script mods, with rac-rs's addresses and findings (the update mask, the camera's yaw word, the aim words, how the hero is faced): GPL-3.0-or-later, like rac-rs.
- [Switch Button Icons and Controls](https://zacksly.itch.io) by Zacksly, licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/). The button icons in the game's text and the Controls help screen are based on this pack. I changed them: I cut them to shape, scaled them into the game's button cells, covered the logo on the controller drawing and added labels. Button Icons and Controls by Zacksly (CC BY 3.0 Licensed | zacksly.itch.io).
- [OunceDevKit](https://github.com/ouncebrew/ounce-devkit) ([libounce](https://github.com/ouncebrew/libounce), [OunceVK](https://github.com/ouncebrew/ouncevk), [libkaihen](https://github.com/ouncebrew/kaihen)) on top of [devkitPro](https://devkitpro.org/). Without these there's no Switch 2 program at all, and no OpenGL.
- [SDL](https://libsdl.org/) (zlib license). The platform layer implements SDL3's API using SDL's own headers. The help screen lettering is Orbitron, which comes with OpenRAC (SIL Open Font License).

## License

What's new here is GPL-3.0-or-later, same as OpenRAC's top level ([COPYING](COPYING), [LICENSE.md](LICENSE.md)). Every file keeps the license of the folder or notice it came with. `switch2/mods/arsenal-mastery` is MIT under its own [LICENSE](switch2/mods/arsenal-mastery/LICENSE). None of this covers the game itself: there is no game code or art in this repo.
