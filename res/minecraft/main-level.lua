-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).



----
-- This is the main lua script for a level.
--
-- When a level is started this file is loaded and exectuted.
--


dofile("script/exported.lua")
dofile("script/defaults.lua")
dofile("script/input.lua")
dofile("script/physics.lua")
dofile("script/player.lua")


----
--
-- These are the global vars set by Charged-Miners
--
-- light
-- world
-- camera
-- terrain
-- options
--

local light = _G.light
local world = _G.world
local camera = _G.camera
local terrain = _G.terrain
local options = _G.options


----
--
-- Some commenly used locals to spead things up
--

local move = _G.move
local print = _G.print
local stringFormat = _G.string.format
local floor = _G.math.floor

local printf = function(str, ...)
	print(stringFormat(str, ...))
end

----
--
-- Setup some initial state
--

----
-- Sets light and camera defaults from a default table.
--
function setDefaults(def)
	if not def then
		def = defaults
	end

	camera.far = def.cameraFar
	camera.near = def.cameraNear
	camera.position = def.cameraPosition
	camera.rotation = Quat(def.cameraHeading, def.cameraPitch, 0)

	light.position = def.lightPosition
	light.rotation = def.lightRotation
	light.diffuse = def.lightDayDiffuse
	light.ambient = def.lightDayAmbient
	light.fogStart = def.fogStart
	light.fogStop = def.fogStop
	light.fogColor = def.fogDayColor
end

setDefaults(defaults)
setKeyBindings(defaults)


player.pos = world.spawn + Vector(0.5, 1.5, 0.5)


-- Set the camera position
camera.position = player.pos + player.headHeight
camera.rotation = Quat(move.heading, move.pitch, 0)

mouse.grab = false
mouse.show = not mouse.grab


----
--
-- This function is called each logic step
--
function logic()
	-- Rotate the sun slowly
	light.rotation = Quat(0.0001, 0, 0) * light.rotation

	player:logic()
end


----
--
-- This function is called when the window is resized.
--
function resize(width, height)
	camera.ratio = width / height
end
