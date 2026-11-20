--!strict
-- Steady strafe: hold R2 (ZR) and Ratchet side-steps and walks backwards facing where the camera looks, as in Ratchet & Clank 2.
-- The shots of the direct-fire weapons leave along the camera's heading. The camera is the game's own and does not change.
--
-- How, from rac-rs (src/rac1/retail/modcam.rs `face`, strafe.rs, aim.rs and modcam/steady.rs, GPL-3.0-or-later, whose addresses and
-- findings this uses): the game moves Ratchet along the stick as always (his path is the stick's, which is the strafe). What changes is
-- where he faces: while R2 is held
--   - standing still, his facing and the yaw he wishes to face turn to the camera's heading at once (the game's own state);
--   - moving (and in the run, walk, stop-skid and flip states), only his drawn facing (the moby's yaw) is set to the camera's heading
--     after each tick, so his body keeps facing it while his path is the stick's;
--   - the weapons' manual aim words are set to the camera's heading, which the gun updaters read in place of Ratchet's own facing
--     (the shots, and the targets they look for, follow the camera).
-- R2 is not passed on to the game while it is the strafe button (it is the game's crouch). Only Ratchet in his own body strafes (not
-- Clank, Giant Clank or the Hologuise), in gameplay only.
--
-- What it does not do (the later rac-rs steps): the legs do not twist toward the path or run backwards for a backpedal (the run
-- clip plays forward under a body that faces the camera), and nothing here changes the camera (no aim lift, no shoulder camera, no
-- aim circle, no lock-on).

local ntsc = openrac.version == "ntsc" -- the words below are the USA disc's

-- The game's camera yaw (hero_stick_wish_yaw adds it to the stick's angle), one word in each level's overlay, per level 0..18.
local CAM_YAW_PAL = { 0x166dd8, 0x1671d8, 0x167358, 0x166e58, 0x166ed8, 0x1671d8, 0x1674d8, 0x166dd8, 0x167558, 0x166ed8,
	0x1671d8, 0x167758, 0x1671d8, 0x167058, 0x1674d8, 0x167358, 0x167158, 0x167658, 0x167758 }
local CAM_YAW_USA = { 0x166dd8, 0x167258, 0x1673d8, 0x166ed8, 0x166f58, 0x1671d8, 0x167558, 0x166e58, 0x1675d8, 0x166f58,
	0x167258, 0x1677d8, 0x167258, 0x1670d8, 0x1674d8, 0x1673d8, 0x1671d8, 0x1676d8, 0x1677d8 }
local CAM_YAW = if ntsc then CAM_YAW_USA else CAM_YAW_PAL

-- The executable's own words (the same on both discs).
local HERO_YAW = 0x13f3e8 -- the hero's logic facing
local HERO_WISH = 0x13f4d0 -- the yaw he wishes to face
local HERO_MOBY = 0x1413d0 -- his moby (a pointer)
local HERO_STATE = 0x1413d4
local BODY_FORM = 0x1413f4 -- 0 while he is Ratchet in his own body
local HELD = 0x1403e0 -- the moby of the weapon in his hand (word 0 of his first item slot)
local AIM_ON = 0x140600 -- the guns' manual aim override
local AIM_YAW = 0x14060c

local R2 = 0x0200 -- in the pad's button word; a bit is clear while its button is held
local TWO_PI = 2 * math.pi

-- Hero states the drawn facing is set in: stand 0, 0x1e, run 2, walk 0x73, the stop skid 3, the crouch flip 0xb, and 0x65, which the first
-- test showed at a level's start (not known from rac-rs: drawn only).
local DRAWN_STATES = { [0] = true, [0x1e] = true, [2] = true, [0x73] = true, [3] = true, [0xb] = true, [0x65] = true }

local strafing = false -- R2 is held in the newest pad report
local still = true -- the left stick is at rest in it
local aim_poked = false
local said = 0
local ticks = 0
local near_said = 0
-- the mobys a weapon in his hand holds in turn
local ATTACHED = { 121 }

local function wrap(a: number): number
	a = a % TWO_PI
	if a > math.pi then
		a -= TWO_PI
	end
	return a
end

openrac.on_pad(function(port: number, report: buffer)
	if port ~= 0 then
		return
	end
	local buttons = buffer.readu16(report, 0)
	strafing = bit32.band(buttons, R2) == 0
	local lx, ly = buffer.readu8(report, 4), buffer.readu8(report, 5)
	still = math.abs(lx - 128) < 40 and math.abs(ly - 128) < 40
	if strafing then
		-- R2 is the strafe button, not the game's crouch
		buffer.writeu16(report, 0, bit32.bor(buttons, R2))
		buffer.writeu8(report, 17, 0)
	end
end)

-- The renderer draws a moby from its three rotation rows (+0xC0, +0xD0, +0xE0: the images of its model axes), which the game builds from
-- its Euler angles in each update; the yaw word alone changes nothing on screen after the update. So the rows are turned about the
-- vertical axis by the change of yaw, as the yaw word is.
local function turn_rows(moby: number, c: number, s: number)
	for i = 0, 2 do
		local a = moby + 0xC0 + i * 0x10
		local x, y = openrac.read("f32", a), openrac.read("f32", a + 4)
		openrac.write("f32", a, x * c - y * s)
		openrac.write("f32", a + 4, x * s + y * c)
	end
end

-- Turns a moby about the point (cx, cy) by delta: its place, its rows and its yaw word.
local function turn_about(m: number, cx: number, cy: number, c: number, s: number, delta: number)
	local x, y = openrac.read("f32", m + 0x10) - cx, openrac.read("f32", m + 0x14) - cy
	if x == x and y == y and math.abs(x) < 50 and math.abs(y) < 50 then
		openrac.write("f32", m + 0x10, cx + x * c - y * s)
		openrac.write("f32", m + 0x14, cy + x * s + y * c)
		turn_rows(m, c, s)
		openrac.write("f32", m + 0x48, wrap(openrac.read("f32", m + 0x48) + delta))
	end
end

local function turn_to(moby: number, yaw: number)
	local old = openrac.read("f32", moby + 0x48)
	if old ~= old then
		return
	end
	local delta = wrap(yaw - old)
	openrac.write("f32", moby + 0x48, yaw)
	if math.abs(delta) < 0.0001 then
		return
	end
	local c, s = math.cos(delta), math.sin(delta)
	turn_rows(moby, c, s)
	-- what he holds was placed on his hand before the turn: it turns about him by the same angle, or it would stay where his hand was
	local cx, cy = openrac.read("f32", moby + 0x10), openrac.read("f32", moby + 0x14)
	local held = bit32.band(openrac.read("u32", HELD), 0x01ffffff)
	if held ~= 0 and held ~= moby then
		turn_about(held, cx, cy, c, s, delta)
	end
	-- and so does what the weapon holds in turn (the Bomb Glove's bomb, class 121), near him
	local near = omni.mobys({ near = { cx, cy, openrac.read("f32", moby + 0x18) }, radius = 2.5, max = 24, class = ATTACHED })
	for _, a in ipairs(near) do
		if a ~= moby and a ~= held then
			turn_about(a, cx, cy, c, s, delta)
		end
	end
end

local function release_aim()
	if aim_poked then
		openrac.write("u32", AIM_ON, 0)
		aim_poked = false
	end
end

-- The camera's heading while the strafe is on, or nil: R2 held, in gameplay, Ratchet in his own body.
local function camera_heading(): (number?, number?)
	local level = omni.level()
	if not strafing or level == nil or level < 0 or level > 18 or omni.mode() ~= "gameplay" or openrac.read("u32", BODY_FORM) ~= 0 then
		return nil, nil
	end
	local yaw = wrap(openrac.read("f32", CAM_YAW[level + 1]))
	-- a yaw that is not an angle means the address is not the camera's here: touch nothing
	if yaw ~= yaw or yaw < -4 or yaw > 4 then
		return nil, nil
	end
	return yaw, level
end

-- Before the hero's update: standing still, his facing and the yaw he wishes to face turn to the camera's heading (the game's own state).
openrac.before("rac1.player.update", function()
	local yaw = camera_heading()
	if yaw == nil or not still then
		return
	end
	local state = openrac.read("u32", HERO_STATE)
	if state == 0 or state == 0x1e then
		openrac.write("f32", HERO_YAW, yaw)
		openrac.write("f32", HERO_WISH, yaw)
	end
end)

-- After it, once his moby and its matrices are built and before the frame is taken: his drawn body faces the camera's heading while he
-- moves (any state) and in the standing, run, walk, skid and flip states.
openrac.after("rac1.player.update", function()
	local yaw, level = camera_heading()
	if yaw == nil then
		return
	end
	local state = openrac.read("u32", HERO_STATE)
	local moby = bit32.band(openrac.read("u32", HERO_MOBY), 0x01ffffff)
	if moby ~= 0 and (not still or DRAWN_STATES[state]) then
		turn_to(moby, yaw)
	end
	ticks += 1
	-- the classes of everything near him, said a few times, to find what else a weapon holds
	if moby ~= 0 and near_said < 8 and ticks % 90 == 0 then
		local cx, cy, cz = openrac.read("f32", moby + 0x10), openrac.read("f32", moby + 0x14), openrac.read("f32", moby + 0x18)
		local parts = {}
		for _, a in ipairs(omni.mobys({ near = { cx, cy, cz }, radius = 2.5, max = 24 })) do
			if a ~= moby then
				table.insert(parts, tostring(openrac.read("i16", a + 0xA6)))
			end
		end
		near_said += 1
		openrac.log("strafe: near him: classes " .. table.concat(parts, " ") .. string.format(" (held %#x)", bit32.band(openrac.read("u32", HELD), 0x01ffffff)))
	end
	if said < 12 and (said < 3 or ticks % 60 == 0) then
		said += 1
		openrac.log(string.format("strafe: level %d camera yaw %.3f hero state %d moby %#x moving %s", level or -1, yaw, state, moby, tostring(not still)))
	end
end)

-- After each tick: the guns' manual aim follows the camera (read by their updaters in the next tick), and ends with the strafe.
openrac.on_frame(function()
	local yaw = camera_heading()
	if yaw == nil then
		release_aim()
		return
	end
	openrac.write("u32", AIM_ON, 1)
	openrac.write("f32", AIM_YAW, yaw)
	aim_poked = true
end)

-- The Bomb Glove (class 192) aims from the hero's frame, which the game keeps as copies of his moby's rows at 0x13f990, 0x13f9a0, 0x13f9b0,
-- the heading at 0x13f9c0 and his logic facing: all turned for the call of its held updater by the turn his drawn body has made (the camera's
-- heading less his logic facing, while he moves), as rac-rs does, so its target (straight ahead of the camera), its lock-on and the point he
-- throws from are those of a Ratchet who faces the camera's heading. What the game itself wrote in the call is kept; the rest goes back.
local BOMB_WORDS = { 0x13f990, 0x13f994, 0x13f9a0, 0x13f9a4, 0x13f9b0, 0x13f9b4, 0x13f9c0, 0x13f9c4, HERO_YAW }
local bomb_old: { number }? = nil
local bomb_new: { number }? = nil

openrac.before("rac1.moby.moby192.update", function(_moby: number)
	bomb_old, bomb_new = nil, nil
	local yaw = camera_heading()
	if yaw == nil or still then
		return
	end
	local delta = wrap(yaw - openrac.read("f32", HERO_YAW))
	if delta ~= delta or math.abs(delta) < 0.0001 then
		return
	end
	local c, s = math.cos(delta), math.sin(delta)
	local old, new = {}, {}
	for k = 0, 3 do
		local ax, ay = BOMB_WORDS[2 * k + 1], BOMB_WORDS[2 * k + 2]
		local x, y = openrac.read("f32", ax), openrac.read("f32", ay)
		old[2 * k + 1], old[2 * k + 2] = x, y
		openrac.write("f32", ax, x * c - y * s)
		openrac.write("f32", ay, x * s + y * c)
		new[2 * k + 1], new[2 * k + 2] = openrac.read("f32", ax), openrac.read("f32", ay)
	end
	old[9] = openrac.read("f32", HERO_YAW)
	openrac.write("f32", HERO_YAW, wrap(old[9] + delta))
	new[9] = openrac.read("f32", HERO_YAW)
	bomb_old, bomb_new = old, new
end)

openrac.after("rac1.moby.moby192.update", function(_moby: number)
	local old, new = bomb_old, bomb_new
	if old == nil or new == nil then
		return
	end
	for i = 1, #BOMB_WORDS do
		if openrac.read("f32", BOMB_WORDS[i]) == new[i] then
			openrac.write("f32", BOMB_WORDS[i], old[i])
		end
	end
	bomb_old, bomb_new = nil, nil
end)
