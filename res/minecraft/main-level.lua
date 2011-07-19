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


player = {
	pos = Point(),
	vel = Vector(),
	headHeight = Vector(0, 1.25, 0),
	ground = false,
}

local player = _G.player


player.pos = world.spawn + Vector(0.5, 1.5, 0.5)


-- Set the camera position
camera.position = player.pos + player.headHeight
camera.rotation = Quat(move.heading, move.pitch, 0)

mouse.grab = false
mouse.show = not mouse.grab

--_G.ticksPerSeconds = 100
local ticksPerSeconds = 100
local playerMaxGroundSpeed = 0.1
local playerMaxAirSpeed = 1
local playerAirAcceleration = 0.04 / ticksPerSeconds
local playerGroundAcceleration = 4.2 / ticksPerSeconds
local playerJumpAcceleration = 0.13

----
--
-- This function is called each logic step
--
function logic()
	-- Rotate the sun slowly
	light.rotation = Quat(0.0001, 0, 0) * light.rotation

	local ground = player.ground
	local vec = Vector()

	if move.forward then vec = vec + Vector(0, 0, -1) end
	if move.backward then vec = vec + Vector(0, 0, 1) end
	if move.right then vec = vec + Vector(1, 0, 0) end
	if move.left then vec = vec + Vector(-1, 0, 0) end

	vec = Quat(move.heading, 0, 0) * vec

	if vec:lengthSqrd() ~= 0 then

		vec:normalize()

		local v = playerAirAcceleration
		if move.speed then v = 0.6 end
		if ground then v = playerGroundAcceleration end

		vec:scale(v)
	end

	local vel = player.vel
	local maxSpeed

	if ground then
		vel.y = 0

		local l = vel:lengthSqrd()
		if l ~= 0 then
			l = math.max(0, l - playerGroundAcceleration)
			l = math.sqrt(l)
			vel:normalize()
			vel:scale(l)
		end

		if move.jump then
			vel.y = playerJumpAcceleration

			-- We are going to go air borne
			maxSpeed = playerMaxAirSpeed
		else
			maxSpeed = playerMaxGroundSpeed
		end
	else
		maxSpeed = playerMaxAirSpeed
	end

	vel = vec + vel

	local l = vel:lengthSqrd()
	l = math.min(l, maxSpeed)
	l = math.sqrt(l)
	vel:normalize()
	vel:scale(l)

	player.pos, player.vel, player.ground = doPlayerPhysics(player, vel)

	camera.position = player.pos + player.headHeight
	camera.rotation = Quat(move.heading, move.pitch, 0)
end

----
--
-- This function is called when the window is resized.
--
function resize(width, height)
	camera.ratio = width / height
end
