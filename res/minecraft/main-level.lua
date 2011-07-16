-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).



----
-- This is the main lua script for a level.
--
-- When a level is started this file is loaded and exectuted.
--

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

-- Minecraft far ~250
local viewDistance = 240

local cameraFar = viewDistance
local cameraNear = 0.1

local fogStop = viewDistance
local fogStart = viewDistance - viewDistance / 4

local cameraHeading = 0 --math.pi / -2
local cameraPitch = 0 --math.pi / -5
local cameraDragging = false
local cameraForward = false
local cameraBackward = false
local cameraLeft = false
local cameraRight = false
local cameraUp = false

camera.far = cameraFar
camera.near = cameraNear
camera.position = world.spawn + Vector(0.5, 1.5, 0.5)
camera.rotation = Quat(cameraHeading, cameraPitch, 0)

light.diffuse = Color(165/255, 165/255, 165/255)
light.ambient = Color(100/255, 100/255, 100/255)
light.rotation = Quat(math.pi / 3, math.pi / -6, 0)
light.fogStart = fogStart
light.fogStop = fogStop

mouse.grab = false
mouse.show = not mouse.grab


----
--
-- Helper functions
--

function getMovedBodyPosition(pos, vel, minVal, maxVal)
	if vel < 0 then
		return floor(pos + vel + minVal)
	else
		return floor(pos + vel + maxVal)
	end
end


----
-- Collides a axis aligned bounding box against the terrain.
--
-- minX, minY, minZ: Smallest corner of box.
-- maxX, maxY, maxZ: Smallest corner of box.
--
function collidesInRange(minX, minY, minZ, maxX, maxY, maxZ, prt)
	minX = floor(minX)
	minY = floor(minY)
	minZ = floor(minZ)
	maxX = floor(maxX)
	maxY = floor(maxY)
	maxZ = floor(maxZ)

	if prt then
		printf("c (%g, %g, %g) (%g, %g, %g)", minX, minY, minZ, maxX, maxY, maxZ)
	end

	for x = minX, maxX do
		for y = minY, maxY do
			for z = minZ, maxZ do
				local b = terrain:block(x, y, z)
				if prt then printf("  (%g, %g, %g) %g", x, y, z, b) end
				if b ~= 0 then
					return true
				end
			end
		end
	end
	return false
end


----
--
-- This function is called each logic step
--
function logic()
	-- Rotate the sun slowly
	light.rotation = Quat(0.0001, 0, 0) * light.rotation

	local vec = Vector()

	if cameraForward then vec = vec + Vector(0, 0, -1) end
	if cameraBackward then vec = vec + Vector(0, 0, 1) end
	if cameraRight then vec = vec + Vector(1, 0, 0) end
	if cameraLeft then vec = vec + Vector(-1, 0, 0) end

	vec = camera.rotation * vec
	if cameraUp then vec = vec + Vector(0, 1, 0) end
	

	local pos = camera.position

	if vec:lengthSqrd() ~= 0 then

		vec:normalize()

		local vel = 0.1
		if cameraSpeed then vel = 0.6 end

		vec:scale(vel)
	end

	local x = pos.x
	local y = pos.y
	local z = pos.z

	local size = 0.32 -- player size
	local minX = x - size
	local minY = y - size
	local minZ = z - size
	local maxX = x + size
	local maxY = y + size
	local maxZ = z + size

	if collidesInRange(minX, minY, minZ, maxX, maxY, maxZ) then
		printf("collides %s", tostring(pos))
		collidesInRange(minX, minY, minZ, maxX, maxY, maxZ, true)
	end

	local vel

	vel = vec.x
	if vel ~= 0 then
		local cx = getMovedBodyPosition(pos.x, vel, -size, size)
		if collidesInRange(cx, minY, minZ, cx, maxY, maxZ) then
			if vel < 0 then
				x = cx + 1 + size + 0.01
			else
				x = cx - size - 0.01
			end
		else
			x = x + vel 
		end

		-- Update for next axis
		minX = x - size
		maxX = x + size
	end

	vel = vec.z
	if vel ~= 0 then
		local cz = getMovedBodyPosition(z, vel, -size, size)
		if collidesInRange(minX, minY, cz, maxX, maxY, cz) then
			if vel < 0 then
				z = cz + 1 + size + 0.01
			else
				z = cz - size - 0.01
			end
		else
			z = z + vel 
		end

		-- Update for next axis
		minZ = z - size
		maxZ = z + size
	end

	vel = vec.y
	if vel ~= 0 then
		local cy = getMovedBodyPosition(y, vel, -size, size)
		if collidesInRange(minX, cy, minZ, maxX, cy, maxZ) then
			if vel < 0 then
				y = cy + 1 + size + 0.01
			else
				y = cy - size - 0.01
			end
		else
			y = y + vel 
		end

		-- Not needed
		--minY = y - size
		--maxY = y + size
	end

	camera.position = Point(x, y, z)
end

----
--
-- This function is called when the window is resized.
--
function resize(width, height)
	camera.ratio = width / height
end


----
--
-- Key mappings.
--
local keyForward = string.byte('w')
local keyBackward = string.byte('s')
local keyRight = string.byte('d')
local keyLeft = string.byte('a')
local keySpeed = 304 --SDLK_LSHIFT
local keyJump = 32 --SDLK_SPACE

local keyTest = string.byte('t')

local keyScreenshot = string.byte('o')
local keyAA = string.byte('b')
local keyShadows = string.byte('v')
local keyRenderer = string.byte('r')
local keyShowDebug = 284 --SDLK_F3
local keyGrab = string.byte('g')


----
--
-- These functions are called when input is processed.
--


----
-- Called when a key on the keyboard is released.
--
-- sym: which key was released, a raw keycode not what was inputted.
--
function keyUp(sym)
	if sym == keyForward then cameraForward = false end
	if sym == keyBackward then cameraBackward = false end
	if sym == keyRight then cameraRight = false end
	if sym == keyLeft then cameraLeft = false end
	if sym == keyJump then cameraUp = false end
	if sym == keySpeed then cameraSpeed = false end

	if sym == keyScreenshot then options:screenshot() end
	if sym == keyAA then options.aa = not options.aa end
	if sym == keyShadows then options.shadow = not options.shadow end
	if sym == keyShowDebug then options.showDebug = not options.showDebug end
	if sym == keyRenderer then options:switchRenderer() end
	if sym == keyGrab and keyboard.ctrl then
		mouse.grab = not mouse.grab
		mouse.show = not mouse.grab
	end
end

----
-- Called when a key on the keyboard is pressed.
--
-- sym: which key was released, a raw keycode not what was inputted.
--
function keyDown(sym)
	if sym == keyForward then cameraForward = true end
	if sym == keyBackward then cameraBackward = true end
	if sym == keyRight then cameraRight = true end
	if sym == keyLeft then cameraLeft = true end
	if sym == keyJump then cameraUp = true end
	if sym == keySpeed then cameraSpeed = true end
	if sym == keyTest then test() end
end

----
-- Called on mouse button up.
--
-- button: which button was released starting with 1.
--
function mouseUp(button)
	if button == 1 then
		cameraDragging = false
	end
end

----
-- Called on mouse button down.
--
-- button: which button was pressed starting with 1.
--
function mouseDown(button)
	if button == 1 then
		cameraDragging = true
	end
end

----
-- Called on mouse move.
--
-- xrel: Relative mouse motion in x axis.
-- yrel: Relative mouse motion in x axis.
--
function mouseMove(xrel, yrel)
	-- If we are not holding down the mouse button don't do anything
	if not cameraDragging and not mouse.grab then return end

	if not mouse.grab then
		xrel = -xrel
		yrel = -yrel
	end

	cameraHeading = cameraHeading - xrel / 500.0
	cameraPitch = cameraPitch - yrel / 500.0

	camera.rotation = Quat(cameraHeading, cameraPitch, 0)
end
