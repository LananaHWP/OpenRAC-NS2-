# RAC3-style health (Going Commando)

Health as a number, like in Ratchet & Clank 3. PAL Going Commando only, off by default.

- You start with 10 health and reach 200 with every nanotech level and boost.
- It's the game's own health made 2.5 times bigger (4 to 80 becomes 10 to 200), so hits and nanotech keep the same share of your health.
- On later planets enemies hit a bit harder, up to 30% more at the end. You can turn that off in the mod's settings.
- In place of the health segments there's a box like the ammo box, with "health/max", a gauge of the health you have left (orange when you're low) and the experience bar under it.
- Clank and Giant Clank are unchanged.

To turn it off, set `"enabled"` to `false` for `rac3-health` in `data/plugins/plugins.json`, or turn it off in the mods list. The game goes back to its own health numbers within a moment of loading.

Settings: `later_planets_harder`.
