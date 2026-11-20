--!strict
-- Quick Select pauses the game: while the Quick Select ring is up (Triangle held) the world stands still, as in the later games.
--
-- How, from rac-rs (src/rac1/retail/qs_pause.rs, GPL-3.0-or-later, whose addresses and findings this uses): the gameplay tick tests an
-- update mask before each world step, one word in each level's overlay: bit 1 the hero's update, bit 2 the mobys (and the frame counter),
-- bit 4 the particles, bit 8 the camera. The level start sets it to 0xF. While the ring is up and Triangle is held, this clears the word for
-- the tick, so nothing moves while the pad, the pause menu, the map, the HUD (the ring turns, picks), the help boxes and the sound still
-- run; after the tick it is put back. The tick in which Triangle is let go runs as the game's own (the item is equipped, the ring fades
-- out), and everything goes on from where it stood.
--
-- The word is written only while it reads 0xF and the camera word beside it (+0xC) reads 0, so a debug state or a wrong address is never
-- written.

local ntsc = openrac.version == "ntsc"

-- world_update's update mask, per level 0..18 (PAL, and the same words on the USA disc).
local MASK_PAL = { 0x16c060, 0x16c460, 0x16c5e0, 0x16c0e0, 0x16c160, 0x16c460, 0x16c760, 0x16c060, 0x16c7e0, 0x16c160,
	0x16c460, 0x16c9e0, 0x16c460, 0x16c2e0, 0x16c760, 0x16c5e0, 0x16c3e0, 0x16c8e0, 0x16c9e0 }
local MASK_USA = { 0x16c060, 0x16c4e0, 0x16c660, 0x16c160, 0x16c1e0, 0x16c460, 0x16c7e0, 0x16c0e0, 0x16c860, 0x16c1e0,
	0x16c4e0, 0x16ca60, 0x16c4e0, 0x16c360, 0x16c760, 0x16c660, 0x16c460, 0x16c960, 0x16ca60 }
-- The HUD element array (stride 0x90, slot 0 the ammo box), per level; the Quick Select ring is slot 3 and its fade byte is at +0x70.
local ELEM_PAL = { 0x17dc50, 0x17e050, 0x17e1d0, 0x17dcd0, 0x17dd50, 0x17e0d0, 0x17e350, 0x17dc50, 0x17e3d0, 0x17dd50,
	0x17e050, 0x17e5d0, 0x17e050, 0x17ded0, 0x17e350, 0x17e1d0, 0x17e050, 0x17e4d0, 0x17e5d0 }
local ELEM_USA = { 0x17dc50, 0x17e0d0, 0x17e250, 0x17dd50, 0x17ddd0, 0x17e0d0, 0x17e3d0, 0x17dcd0, 0x17e450, 0x17ddd0,
	0x17e0d0, 0x17e650, 0x17e0d0, 0x17df50, 0x17e350, 0x17e250, 0x17e0d0, 0x17e550, 0x17e650 }

local MASK = if ntsc then MASK_USA else MASK_PAL
local ELEM = if ntsc then ELEM_USA else ELEM_PAL

local PLAY = 0xF -- the mask in play
local TRIANGLE = 0x1000 -- in the pad's button word; a bit is clear while its button is held

local held = 0 -- the mask word cleared for this tick (0: none)
local said = false

local function put_back()
	if held ~= 0 then
		-- only our own zero: if the game wrote the word meanwhile, it stays
		if openrac.read("u32", held) == 0 then
			openrac.write("u32", held, PLAY)
		end
		held = 0
	end
end

-- Before the tick reads the pad: decides whether the world stands still in it.
openrac.on_pad(function(port: number, report: buffer)
	if port ~= 0 then
		return
	end
	put_back() -- a tick that did not reach on_frame
	local level = omni.level()
	if level == nil or level < 0 or level > 18 or omni.mode() ~= "gameplay" then
		return
	end
	if bit32.band(buffer.readu16(report, 0), TRIANGLE) ~= 0 then
		return -- Triangle is not held in this tick's pad: the game's own tick (the release equips the item)
	end
	local mask = MASK[level + 1]
	if openrac.read("u32", mask) ~= PLAY or openrac.read("u32", mask + 0xC) ~= 0 then
		return
	end
	if openrac.read("u8", ELEM[level + 1] + 3 * 0x90 + 0x70) == 0 then
		return -- the ring is not up
	end
	openrac.write("u32", mask, 0)
	held = mask
	if not said then
		said = true
		openrac.log("the Quick Select ring is up: the world stands still while it is")
	end
end)

-- After the tick: the word back to its play value.
openrac.on_frame(put_back)
