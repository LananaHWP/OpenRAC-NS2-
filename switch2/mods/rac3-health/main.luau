-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2026 the OpenRAC contributors
--
-- RAC3-style health for Going Commando (PAL, SCES_516.07): health as a number from 10 to 200.
--
-- The game's health is already points: 4 at the start, 1 for each nanotech level and boost, 80 at most, drawn as one segment a point.
-- This keeps the game's own numbers, 2.5 times as big (4 -> 10, 80 -> 200), so every hit and heal keeps its share of your health:
--   * the most health the game works out is stored 2.5 times as big (and handed back to the game as its own when it works it out again,
--     so its level ups happen when they did; with the mod off, the game's next count restores its own numbers);
--   * a hit takes what the game took after your armour, 2.5 times as big, and on later planets up to 30% more (a setting);
--   * nanotech heals 2.5 times as much, up to the most;
--   * in place of the segments the port draws "health / most" in a box like the ammo box's, with the nanotech experience on its hooked line until 80 of
--     the game's points.
-- Clank (and Giant Clank's own health) are left as they are.

local HEALTH = 0x0018C36C      -- Ratchet's health, an int: 0 is dead
local MOST = 0x001A7A88        -- the most health (in the save)
local FORM = 0x0018C154        -- 0 Ratchet; anything else is Clank or another form (the hero record +0x22B4)
local LEVEL = 0x001A7A78       -- the level's number

local function scale(native: number): number
	return native * 5 // 2
end

-- The game's own number from a scaled one: scale(n) is back n for every n (the half rounded up).
local function unscale(points: number): number
	return (points * 2 + 4) // 5
end

local function read(address: number): number
	return openrac.read("i32", address)
end

local function write(address: number, value: number)
	openrac.write("i32", address, value)
end

local function ratchet(): boolean
	return openrac.read("u8", FORM) == 0
end

-- ---- the most health ----
openrac.hook("rac2.player.max_health.update", function(original)
	local stored = read(MOST)
	local native = unscale(stored)
	write(MOST, native)
	original()
	local now = read(MOST)
	if now ~= native then
		-- The game worked out another most (a level up, a new save, the mod just turned on) and filled the health to it.
		write(MOST, scale(now))
		write(HEALTH, scale(now))
		openrac.log(string.format("health: the most is %d (the game's %d)", scale(now), now))
	else
		write(MOST, stored)
	end
end)

-- ---- hits ----
-- Later planets, in the order the story visits them; the side places take a neighbour's.
local SIDE = { [22] = 9, [23] = 18, [24] = 10, [25] = 15, [26] = 20 }

local function hardness(): number
	if openrac.setting("later_planets_harder") == false then
		return 1.0
	end
	local level = read(LEVEL)
	local order = (level >= 0 and level <= 20) and level or (SIDE[level] or 0)
	return 1.0 + 0.3 * order / 20
end

local PROBE = 100000

openrac.hook("rac2.player.take_damage", function(original, amount)
	if amount == 0 or not ratchet() then
		original(amount)
		return
	end
	-- What the game takes after the armour: taken from a health nothing can empty, then from the real one, scaled.
	local before = read(HEALTH)
	write(HEALTH, PROBE)
	original(amount)
	local taken = PROBE - read(HEALTH)
	local points = math.floor(taken * 2.5 * hardness() + 0.5)
	if taken > 0 then
		points = math.max(points, 1)
	end
	write(HEALTH, math.clamp(before - points, 0, math.max(before, read(MOST))))
end)

-- ---- nanotech ----
local owed = 0.0 -- the half points left over from one heal to the next

openrac.hook("rac2.moby.nanotech_ball.update", function(original, moby)
	local before = read(HEALTH)
	original(moby)
	local gained = read(HEALTH) - before
	if gained > 0 and ratchet() then
		local points = gained * 2.5 + owed
		local whole = math.floor(points)
		owed = points - whole
		write(HEALTH, math.min(read(MOST), before + whole))
	end
end)

-- ---- the meter ----
-- The number itself is drawn by the port (rac2-pal/host/health_hud.c), in place of the segments, while this mod is loaded: the ammo
-- box's frame and font, a gauge of the health left, and the experience bar under it. The bar shows while the most is under 80 in the
-- game's own numbers:
openrac.hook("rac2.hud.health_meter.experience", function(original, meter)
	local stored = read(MOST)
	write(MOST, unscale(stored))
	original(meter)
	write(MOST, stored)
end)
