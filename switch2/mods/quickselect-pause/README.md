# Quick Select pause

Ratchet & Clank 1: while the Quick Select ring is up (Triangle held, Y on the Switch's layout), the world stands still,
as in Ratchet & Clank 3 and Up Your Arsenal. Enemies, shots, platforms, particles, Ratchet and the camera wait; the ring still
turns and the pause menu, the map and the help boxes still work. When Triangle is let go the game goes on from where it stood.

It clears the world's update mask (one word in each level's overlay) for the ticks the ring is up, and puts it back after each
tick. The word is written only while it holds its normal value, so nothing else is touched.

## Credits

This is [rac-rs](https://github.com/AsobiCodes/rac-rs)'s "Quick Select pauses the game" (`src/rac1/retail/qs_pause.rs`) written as a
script mod for OpenRAC: the update mask, its addresses on both discs and the ring's fade byte are rac-rs's findings.
GPL-3.0-or-later, like rac-rs.
