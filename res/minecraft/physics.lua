-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).



----
-- This is script holds physics related functions.
--

----
-- Some defines
--
local playerSize = 0.32

local floor = _G.math.floor


----
-- Get the block to where the player moved.
--
local getMovedBodyPosition = function(pos, vel, minVal, maxVal)
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
local collidesInRange = function(minX, minY, minZ, maxX, maxY, maxZ)
	minX = floor(minX)
	minY = floor(minY)
	minZ = floor(minZ)
	maxX = floor(maxX)
	maxY = floor(maxY)
	maxZ = floor(maxZ)

	for x = minX, maxX do
		for y = minY, maxY do
			for z = minZ, maxZ do
				local b = terrain:block(x, y, z)
				if b ~= 0 then
					return true
				end
			end
		end
	end
	return false
end


----
-- Applie physics to a player and move it
--
function doPlayerPhysics(pos, vec)

	if not vec then
		vec = Vector()
	end

	local x = pos.x
	local y = pos.y
	local z = pos.z

	local size = playerSize
	local minX = x - size
	local minY = y - size
	local minZ = z - size
	local maxX = x + size
	local maxY = y + size
	local maxZ = z + size

	--if collidesInRange(minX, minY, minZ, maxX, maxY, maxZ) then
	--	--collidesInRange(minX, minY, minZ, maxX, maxY, maxZ, true)
	--end

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

	return Point(x, y, z)
end
