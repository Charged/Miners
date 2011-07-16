-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).



----
-- This lua scripts holds shared defaults and settings.
--

----
-- Defaults which more then one derive from
--
local viewDistance = 240 -- Minecraft far ~250


local defaults = {

	--
	-- Camera
	--

	viewDistance = viewDistance,

	cameraPosition = Point(),
	cameraRotation = Quat(),
	cameraFar = viewDistance,
	cameraNear = 0.1,


	--
	-- SunLight
	--

	lightPosition = Point(),
	lightRotation = Quat(math.pi / 3, math.pi / -6, 0),
	lightDayDiffuse = Color(165/255, 165/255, 165/255),
	lightDayAmbient = Color(100/255, 100/255, 100/255),

	fogStop = viewDistance,
	fogStart = viewDistance - viewDistance / 4,
	fogDayColor = Color(89/255, 178/255, 220/255),


	--
	-- Keybindings
	--

	keyForward = string.byte('w'),
	keyBackward = string.byte('s'),
	keyRight = string.byte('d'),
	keyLeft = string.byte('a'),
	keySpeed = 304, --SDLK_LSHIFT
	keyJump = 32, --SDLK_SPACE
	keyTest = string.byte('t'),
	keyScreenshot = string.byte('o'),
	keyAA = string.byte('b'),
	keyShadows = string.byte('v'),
	keyRenderer = string.byte('r'),
	keyShowDebug = 284, --SDLK_F3
	keyGrab = string.byte('g'),
}

_G.defaults = defaults
