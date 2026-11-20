# Steady strafe

Ratchet & Clank 1, in the style of Ratchet & Clank 2: hold R2 (ZR on the Switch) and Ratchet side-steps and walks backwards while he
faces where the camera looks. The direct-fire weapons shoot along the camera's heading. The camera is the game's own and stays as it is.
R2 is the strafe button while the mod is on (the game uses it for the crouch).

This first version is the movement and the aim only. Not there yet: the legs twisting toward the path and the run clip playing
backwards for a backpedal (he runs forward under a body that faces the camera), the aim lift, the shoulder camera, the aim circle
and the lock-on.

It changes where Ratchet faces, not where he goes: the game moves him along the stick as always. Standing still he turns to the camera's heading
at once. Moving, only his drawn facing is set to it after each tick. The guns' own manual-aim words are set to it, so the shots and
the target search follow the camera. Only Ratchet in his own body strafes, in gameplay only.

## Credits

[rac-rs](https://github.com/AsobiCodes/rac-rs)'s strafe aiming (`modcam.rs` `face`, `strafe.rs`, `aim.rs`, `modcam/steady.rs`) written as a
script mod for OpenRAC: the camera yaw word, the aim words, the hero's words and the way of facing him are rac-rs's findings.
GPL-3.0-or-later, like rac-rs.
