-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).

local _G = _G
local require = _G.require
module(...)


----
-- This lua scripts holds shared defaults and settings.
--

require "charge"

local Point = _G.charge.Point
local Vector = _G.charge.Vector
local Quat = _G.charge.Quat
local Color = _G.charge.Color

local math = _G.math
local string = _G.string


----
-- Defaults which more then one derive from
--

local viewDistance = 256 -- Minecraft far ~250

local defaults = {

	--
	-- Camera
	--

	viewDistance = viewDistance,

	cameraPosition = Point(),
	cameraRotation = Quat(),


	--
	-- SunLight
	--

	lightPosition = Point(),
	lightRotation = Quat(math.pi / 3, math.pi / -6, 0),
	lightDayDiffuse = Color(165/255, 165/255, 165/255),
	lightDayAmbient = Color(100/255, 100/255, 100/255),

	fogProcent = .35,
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
	keyDistance = string.byte('f'),
	keyIso = string.byte('i'),
	keyShowDebug = 284, --SDLK_F3
	keyGrab = string.byte('g'),
}

_G.defaults = defaults
