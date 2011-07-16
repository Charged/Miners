-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).



----
-- This file contains input functions.
--


----
-- Movement state
--
move = {
	heading = 0,
	pitch = 0,

	forward = false,
	backward = false,
	left = false,
	right = false,
	up = false,
	speed = false,
}

local move = _G.move


----
-- Key mappings.
--

local keyForward
local keyBackward
local keyRight
local keyLeft
local keySpeed
local keyJump

local keyTest

local keyScreenshot
local keyAA
local keyShadows
local keyRenderer
local keyShowDebug
local keyGrab


----
-- Set the keybindings from a table
--
function setKeyBindings(def)
	keyForward = def.keyForward
	keyBackward = def.keyBackward
	keyRight = def.keyRight
	keyLeft = def.keyLeft
	keySpeed = def.keySpeed
	keyJump = def.keyJump

	keyTest = def.keyTest

	keyScreenshot = def.keyScreenshot
	keyAA = def.keyAA
	keyShadows = def.keyShadows
	keyRenderer = def.keyRenderer
	keyShowDebug = def.keyShowDebug
	keyGrab = def.keyGrab
end


----
-- Called when a key on the keyboard is released.
--
-- sym: which key was released, a raw keycode not what was inputted.
--
function keyUp(sym)
	if sym == keyForward then move.forward = false end
	if sym == keyBackward then move.backward = false end
	if sym == keyRight then move.right = false end
	if sym == keyLeft then move.left = false end
	if sym == keyJump then move.up = false end
	if sym == keySpeed then move.speed = false end


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
	if sym == keyForward then move.forward = true end
	if sym == keyBackward then move.backward = true end
	if sym == keyRight then move.right = true end
	if sym == keyLeft then move.left = true end
	if sym == keyJump then move.up = true end
	if sym == keySpeed then move.speed = true end

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

	move.heading = move.heading - xrel / 500.0
	move.pitch = move.pitch - yrel / 500.0

end
