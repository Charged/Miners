-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).

local _G = _G
local require = _G.require
-- Not a module


----
-- This is the main lua script for a level.
--
-- When a level is started this file is loaded and exectuted.
--

require "charge"   -- Basic types from Charge
require "exported" -- Setup exported/imported globals
require "defaults" -- Default values
require "input"    -- Needed to handle callbacks
require "player"   -- The player

local Quat = _G.charge.Quat
local Vector = _G.charge.Vector

local light = _G.light
local world = _G.world
local camera = _G.camera


----
--
-- Some commenly used locals to spead things up
--

local move = _G.input.move
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
	camera:resize(width, height)
end
