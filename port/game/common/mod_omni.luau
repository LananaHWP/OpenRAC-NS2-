--!nonstrict
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2026 the OpenRAC contributors
-- The `omni` table: the host extension Arsenal Mastery was written against (rac-rs's loader), built on OpenRAC's own `openrac` table and a
-- few host helpers (H). Experimental and partly written: what it does not provide, `omni.has(name)` says false, and a mod that probes
-- first (Arsenal Mastery does) works without it. Run once per script mod, before its scripts, inside a pcall.
--   Provided: the basics (game, version, platform, api, log, setting, read, write, fields, hook, before, after, on_frame, on_pad,
--   ticks_per_second, unwound), struct / struct_set / out_f32, level / mode / pause_page, events (level_loaded, level_unloading, mode),
--   save (one store, kept in the mod's data folder).
--   Not provided yet: mobys, moby_valid, is_enemy, fn, draw, pose, raycast, with_stack, the save_loaded / saving / new_game events.
local H = ...
local openrac = openrac

local omni = {}

omni.game = openrac.game
omni.version = openrac.version
omni.platform = openrac.platform
omni.api = openrac.api
omni.loader_version = "openrac-omni-0.1"
omni.log = openrac.log
omni.warn = openrac.warn
omni.setting = openrac.setting
omni.read = openrac.read
omni.write = openrac.write
omni.fields = openrac.fields

-- Hook points whose functions the decompilation declares with a float among the integers where the omni binding lists it first (the same
-- registers: a float goes in its own register whatever its place): the scripts are given the arguments in the binding's order, `perm[i]` being
-- the place in the host's order of the script's i-th argument.
local PERMS = {
	["rac1.omni.damage.build_hit"] = { 4, 1, 2, 3, 5 },
	["rac1.omni.weapon.flame.create"] = { 4, 1, 2, 3 },
	["rac1.omni.weapon.visibomb.fire"] = { 3, 4, 1, 2 },
	["rac1.omni.weapon.blaster.fire"] = { 4, 5, 6, 7, 1, 2, 3 },
	["rac1.omni.weapon.ryno.fire"] = { 4, 5, 6, 1, 2, 3 },
	["rac1.omni.blast.apply"] = { 9, 10, 11, 1, 2, 3, 4, 5, 6, 7, 8 },
}

local function permuted(id, fn, with_original)
	local p = PERMS[id]
	if p == nil then return fn end
	local n = #p
	return function(...)
		local host = { ... }
		local first = 0
		local original = nil
		if with_original then
			original = host[1]
			first = 1
		end
		local mine = {}
		for i = 1, n do mine[i] = host[first + p[i]] end
		if not with_original then return fn(table.unpack(mine, 1, n)) end
		local function orig(...)
			if select("#", ...) == 0 then return original() end
			local given, back = { ... }, {}
			for i = 1, n do back[p[i]] = given[i] end
			return original(table.unpack(back, 1, n))
		end
		return fn(orig, table.unpack(mine, 1, n))
	end
end

-- How often each hook point a script holds is called: said at its first call and after 50 and 500 (to see in the log that a hook is live).
local calls = {}
local function counted(id, fn)
	return function(...)
		local n = (calls[id] or 0) + 1
		calls[id] = n
		if n == 1 or n == 50 or n == 500 then openrac.log(string.format("omni: %s called %d time(s)", id, n)) end
		return fn(...)
	end
end

-- The first hits the damage resolver is given (an entry is a hit on the victim), with what it made of them: seen in the log, to tell what a script gets.
local resolver_hits = 0
local function traced_resolve(fn)
	return function(original, victim, entry, comp, a3, status, sptr, extra, mode)
		if entry == 0 or entry == nil or resolver_hits >= 12 then return fn(original, victim, entry, comp, a3, status, sptr, extra, mode) end
		resolver_hits += 1
		local n = resolver_hits
		local function orig(...)
			local r = original(...)
			local ok, text = pcall(function()
				local after = H.out_f32(sptr) or -1
				local hp = comp ~= 0 and openrac.read("f32", comp) or -1
				local atk = openrac.read("u32", entry + 0x20)
				return string.format("omni: damage.resolve hit #%d victim=%x entry=%x comp=%x mode=%d -> ret %s, strength %.3f, health %.2f, attacker %x", n, victim, entry, comp, mode, tostring(r), after, hp, atk)
			end)
			openrac.log(ok and text or ("omni: damage.resolve hit #" .. n .. " could not be read: " .. tostring(text)))
			return r
		end
		return fn(orig, victim, entry, comp, a3, status, sptr, extra, mode)
	end
end

omni.hook = function(id, fn)
	if id == "rac1.omni.damage.resolve" then fn = traced_resolve(fn) end
	return openrac.hook(id, counted(id, permuted(id, fn, true)))
end
omni.before = function(id, fn) return openrac.before(id, counted(id, permuted(id, fn, false))) end
omni.after = function(id, fn) return openrac.after(id, counted(id, permuted(id, fn, false))) end
omni.on_frame = openrac.on_frame
omni.on_pad = openrac.on_pad

omni.ticks_per_second = function()
	if openrac.version == "pal" then return 50 end
	return 60
end
omni.unwound = function() return false end

local RAM = 32 * 1024 * 1024

-- ---- records by layout ----
local function def_of(name)
	local d = STRUCTS[name]
	if d == nil then error("unknown struct " .. tostring(name), 3) end
	return d
end

omni.struct = function(name, addr)
	local d = def_of(name)
	if type(addr) ~= "number" or addr <= 0 or addr >= RAM then return nil end
	return setmetatable({}, {
		__index = function(_, k)
			local f = d[k]
			if f == nil then return nil end
			return openrac.read(f[2], addr + f[1])
		end,
		__newindex = function(_, k, v)
			error("a struct is read through omni.struct and written with omni.struct_set", 2)
		end,
	})
end

omni.struct_set = function(name, addr, field, value)
	local d = def_of(name)
	local f = d[field]
	if f == nil then error("struct " .. name .. " has no field " .. tostring(field), 2) end
	if f[3] then error("field " .. name .. "." .. field .. " is read-only", 2) end
	if type(value) ~= "number" then error("field " .. name .. "." .. field .. " takes a number", 2) end
	-- a nil address is the mods' "is this field there" probe: everything is checked, nothing written
	if type(addr) ~= "number" or addr <= 0 or addr >= RAM then return false end
	openrac.write(f[2], addr + f[1], value)
	return true
end

omni.out_f32 = function(ptr, v)
	if type(ptr) ~= "number" then return nil end
	if v == nil then return H.out_f32(ptr) end
	return H.out_f32(ptr, v)
end

-- ---- the game's state ----
local MODES = { [0] = "gameplay", "movie", "cutscene", "pause", "dialog", "vendor", "ship", "screen" }

local function mode_name()
	local lv = H.level()
	if lv < 0 then return "title" end
	local m = H.mode()
	if m < 0 then return "loading" end
	return MODES[m] or "unknown"
end

omni.level = function() return H.level() end
omni.mode = function() return mode_name() end
omni.pause_page = function() return nil end

-- ---- events: read once per tick, one event per change ----
local EVENTS = { "level_loaded", "level_unloading", "mode", "pause_page", "new_game", "save_loaded", "saving", "setting" }
local handlers = {}
local loading = true
for _, e in ipairs(EVENTS) do handlers[e] = {} end

omni.on = function(name, fn)
	if not loading then error("omni.on is for the mod's first run", 2) end
	local list = handlers[name]
	if list == nil then error("unknown event " .. tostring(name) .. ": " .. table.concat(EVENTS, ", "), 2) end
	table.insert(list, fn)
end

local function fire(name, a, b)
	for _, fn in ipairs(handlers[name]) do fn(a, b) end
end

local last_level, last_mode = -1, "unknown"
openrac.on_frame(function()
	loading = false
	local lv = H.level()
	if lv ~= last_level then
		if last_level >= 0 then fire("level_unloading", last_level) end
		last_level = lv
		if lv >= 0 then fire("level_loaded", lv) end
	end
	local m = mode_name()
	if m ~= last_mode then
		local old = last_mode
		last_mode = m
		fire("mode", m, old)
	end
end)

-- ---- the save store: one table, kept in the mod's data folder ----
local LIMIT = 65536
local store, store_dirty = {}, false

local function encode(v)
	local t = type(v)
	if v == nil then return "n" end
	if t == "boolean" then return v and "T" or "F" end
	if t == "number" then return "d" .. string.format("%.17g", v) .. ";" end
	if t == "string" then return "s" .. #v .. ":" .. v end
	if t == "table" then
		local out = { "{" }
		for k, x in pairs(v) do
			table.insert(out, encode(k))
			table.insert(out, encode(x))
		end
		table.insert(out, "}")
		return table.concat(out)
	end
	error("only nil, booleans, numbers, strings and tables of those can be saved", 3)
end

local function decode(s, i)
	local c = string.sub(s, i, i)
	if c == "n" then return nil, i + 1 end
	if c == "T" then return true, i + 1 end
	if c == "F" then return false, i + 1 end
	if c == "d" then
		local j = string.find(s, ";", i, true)
		return tonumber(string.sub(s, i + 1, j - 1)), j + 1
	end
	if c == "s" then
		local j = string.find(s, ":", i, true)
		local n = tonumber(string.sub(s, i + 1, j - 1))
		return string.sub(s, j + 1, j + n), j + n + 1
	end
	if c == "{" then
		local t = {}
		i += 1
		while string.sub(s, i, i) ~= "}" do
			local k, x
			k, i = decode(s, i)
			x, i = decode(s, i)
			if k ~= nil then t[k] = x end
		end
		return t, i + 1
	end
	error("bad save data")
end

local function load_store()
	local text = H.save_get()
	store = {}
	if text == nil or text == "" then return end
	local ok, t = pcall(function() return (decode(text, 1)) end)
	if ok and type(t) == "table" then store = t end
end

-- The store goes with the save the game is playing (the port writes a mod's data beside each save): written through at the end of a tick
-- in which a script changed it.
local function flush_store()
	if not store_dirty then return end
	store_dirty = false
	local ok, text = pcall(encode, store)
	if ok then H.save_put(text) end
end

-- The game in progress changed (a save loaded, or a new game): the store is that save's, and the mods are told.
local last_saving = 0
openrac.on_frame(function()
	local ev = H.save_event()
	if ev == 1 then
		load_store()
		store_dirty = false
		fire("save_loaded", 0)
	elseif ev == 2 then
		store = {}
		store_dirty = false
		fire("new_game", false)
	end
	-- the mods set what they keep in a `saving` event: here every few seconds of play, so the save written at any time holds it
	last_saving += 1
	if last_saving >= 1800 and H.level() >= 0 and H.mode() >= 0 then
		last_saving = 0
		fire("saving")
	end
	flush_store()
end)

omni.save = {
	get = function(key) return store[key] end,
	set = function(key, v)
		if type(key) ~= "string" then error("save keys are strings", 2) end
		local before = store[key]
		store[key] = v
		local ok, text = pcall(encode, store)
		if not ok or #text > LIMIT then
			store[key] = before
			error("the save data of a mod is at most " .. LIMIT .. " bytes", 2)
		end
		store_dirty = true
	end,
	keys = function()
		local out = {}
		for k in pairs(store) do table.insert(out, k) end
		table.sort(out)
		return out
	end,
	clear = function()
		store = {}
		store_dirty = true
	end,
	version = function() return openrac.version end,
	flush = flush_store,
}

-- ---- moby queries ----
local NEAR, ENEMY = 1, 2
if H.can_mobys() then
	-- { class = number or {numbers}, enemy = true, near = {x, y, z} or {x=, y=, z=}, radius = n, max = n }: the live mobys' addresses, nearest first with `near`
	omni.mobys = function(q)
		q = q or {}
		local flags, x, y, z = 0, 0, 0, 0
		if q.near ~= nil then
			flags += NEAR
			x, y, z = q.near[1] or q.near.x or 0, q.near[2] or q.near.y or 0, q.near[3] or q.near.z or 0
		end
		if q.enemy then flags += ENEMY end
		local classes = q.class
		if type(classes) == "number" then classes = { classes } end
		return H.mobys(flags, x, y, z, q.radius or 0, q.max or 0, classes)
	end
	omni.moby_valid = function(addr) return H.moby_valid(addr) end
	omni.is_enemy = function(addr) return H.is_enemy(addr) end
	-- how many mobys and living enemies the level has, said a few times (to see in the log that the queries find them)
	local seen_ticks, seen_said = 0, 0
	openrac.on_frame(function()
		seen_ticks += 1
		if seen_ticks % 600 == 0 and seen_said < 8 and H.level() >= 0 and H.mode() == 0 then
			seen_said += 1
			local enemies = omni.mobys{ enemy = true, max = 256 }
			local by_class = {}
			for _, a in ipairs(enemies) do
				local ok, m = pcall(omni.struct, "moby", a)
				local c = ok and m and m.class or -1
				by_class[c] = (by_class[c] or 0) + 1
			end
			local parts = {}
			for c, n in pairs(by_class) do table.insert(parts, string.format("%d x%d", c, n)) end
			table.sort(parts)
			openrac.log(string.format("omni: %d moby(s), %d living enemy(ies): classes %s", #omni.mobys{ max = 256 }, #enemies, table.concat(parts, ", ")))
		end
	end)
end

-- ---- drawing over the game (the game's 512 x 448 picture) ----
if H.can_draw then
	local ALIGN = { left = 0, center = 1, right = 2 }
	local function opt(o, k, d)
		if o == nil or o[k] == nil then return d end
		return o[k]
	end
	omni.draw = {
		rect = function(x, y, w, h, color, o) H.draw_cmd(1, x, y, w, h, 0, color or 0xFFFFFFFF, 0, 1, 0, nil) end,
		bar = function(x, y, w, h, value, color, back, o) H.draw_cmd(3, x, y, w, h, value or 0, color or 0xFFFFFFFF, back or 0, 1, 0, nil) end,
		text = function(x, y, s, o)
			H.draw_cmd(2, x, y, 0, 0, 0, opt(o, "color", 0xFFFFFFFF), opt(o, "shadow", 0), opt(o, "size", 1), ALIGN[opt(o, "align", "left")] or 0, tostring(s))
		end,
		icons = function() return {} end,
		icon = function() end,
	}
	local draw_ticks, draw_said = 0, 0
	openrac.on_frame(function()
		local n = H.draw_begin()
		draw_ticks += 1
		if draw_ticks % 900 == 0 and draw_said < 6 then
			draw_said += 1
			openrac.log(string.format("omni.draw: %d command(s) in the last tick", n))
		end
	end)
end

-- ---- what is there ----
local FEATURES = {
	["omni"] = true, ["omni.events"] = true, ["omni.save"] = true, ["omni.struct"] = true, ["omni.struct_set"] = true,
	["omni.ticks_per_second"] = true, ["omni.out_f32"] = true, ["omni.unwound"] = true,
}
omni.has = function(name)
	if FEATURES[name] then return true end
	if name == "omni.mobys" or name == "omni.moby_valid" or name == "omni.is_enemy" then return omni.mobys ~= nil end
	if name == "omni.draw" then return omni.draw ~= nil end
	if type(name) == "string" and string.sub(name, 1, 5) == "rac1." then return H.has_hook(name) end
	return false
end

return omni
