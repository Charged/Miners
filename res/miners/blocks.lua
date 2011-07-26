-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).

local _G = _G
local require = _G.require
module(...)


----
-- This module contains a table for describing blocks.
--

local print = _G.print


----
-- Helper function
--
local BI = function(solid, t, u, v, name)
	return { solid = solid, name = name } 
end

----
-- Type of blocks
--
local Air = 0
local Block = 1
local BlockData = 2
local NA = 3
local Stuff = 4

----
-- Table describing blocks
--
local blocks = {
	-- Can't index zero in lua tables but that is okay.
	--( false, Air,       {  0,  0 }, {  0,  0 }, "air" ),                  -- 0
	BI(  true, Block,     {  1,  0 }, {  1,  0 }, "stone" ),
	BI(  true, Block,     {  3,  0 }, {  0,  0 }, "grass" ),
	BI(  true, Block,     {  2,  0 }, {  2,  0 }, "dirt" ),
	BI(  true, Block,     {  0,  1 }, {  0,  1 }, "clobb" ),
	BI(  true, Block,     {  4,  0 }, {  4,  0 }, "wooden plank" ),
	BI( false, Stuff,     { 15,  0 }, { 15,  0 }, "sapling" ),
	BI(  true, Block,     {  1,  1 }, {  1,  1 }, "bedrock" ),
	BI( false, Stuff,     { 15, 13 }, { 15, 13 }, "water" ),                 -- 8
	BI( false, Stuff,     { 15, 13 }, { 15, 13 }, "spring water" ),
	BI(  true, Stuff,     { 15, 15 }, { 15, 15 }, "lava" ),
	BI(  true, Stuff,     { 15, 15 }, { 15, 15 }, "spring lava" ),
	BI(  true, Block,     {  2,  1 }, {  2,  1 }, "sand" ),
	BI(  true, Block,     {  3,  1 }, {  3,  1 }, "gravel" ),
	BI(  true, Block,     {  0,  2 }, {  0,  2 }, "gold ore" ),
	BI(  true, Block,     {  1,  2 }, {  1,  2 }, "iron ore" ),
	BI(  true, Block,     {  2,  2 }, {  2,  2 }, "coal ore" ),              -- 16
	BI(  true, DataBlock, {  4,  1 }, {  5,  1 }, "log" ),
	BI( false, Stuff,     {  4,  3 }, {  4,  3 }, "leaves" ),
	BI(  true, Block,     {  0,  3 }, {  0,  3 }, "sponge" ),
	BI( false, Stuff,     {  1,  3 }, {  1,  3 }, "glass" ),
	BI(  true, Block,     {  0, 10 }, {  0, 10 }, "lapis lazuli ore" ),
	BI(  true, Block,     {  0,  9 }, {  0,  9 }, "lapis lazuli block" ),
	BI(  true, DataBlock, { 13,  2 }, { 14,  3 }, "dispenser" ),
	BI(  true, Block,     {  0, 12 }, {  0, 11 }, "sand Stone" ),            -- 24
	BI(  true, Block,     { 10,  4 }, { 10,  4 }, "note block" ),
	BI( false, Stuff,     {  0,  4 }, {  0,  4 }, "bed" ),
	BI( false, Stuff,     {  0,  4 }, {  0,  4 }, "powered rail" ),
	BI( false, Stuff,     {  0,  4 }, {  0,  4 }, "detector rail" ),
	BI( false, NA,        {  0,  4 }, {  0,  4 }, "n/a" ),
	BI( false, Stuff,     {  0,  4 }, {  0,  4 }, "web" ),
	BI( false, Stuff,     {  7,  2 }, {  7,  2 }, "tall grass" ),
	BI( false, NA,        {  7,  3 }, {  7,  3 }, "dead shrub" ),            -- 32
	BI( false, NA,        {  0,  4 }, {  0,  4 }, "n/a" ),
	BI( false, NA,        {  0,  4 }, {  0,  4 }, "n/a" ),
	BI(  true, DataBlock, {  0,  4 }, {  0,  4 }, "wool" ),
	BI( false, NA,        {  0,  4 }, {  0,  4 }, "n/a" ),
	BI( false, Stuff,     { 13,  0 }, { 13,  0 }, "yellow flower" ),
	BI( false, Stuff,     { 12,  0 }, { 12,  0 }, "red rose" ),
	BI( false, Stuff,     { 13,  1 }, {  0,  0 }, "brown myshroom" ),
	BI( false, Stuff,     { 12,  1 }, {  0,  0 }, "red mushroom" ),          -- 40
	BI(  true, Block,     {  7,  1 }, {  7,  1 }, "gold block" ),
	BI(  true, Block,     {  6,  1 }, {  6,  1 }, "iron block" ),
	BI(  true, DataBlock, {  5,  0 }, {  6,  0 }, "double slab" ),
	BI( false, Stuff,     {  5,  0 }, {  6,  0 }, "slab" ),
	BI(  true, Block,     {  7,  0 }, {  7,  0 }, "brick block" ),
	BI(  true, Block,     {  8,  0 }, {  9,  0 }, "tnt" ),
	BI(  true, Block,     {  3,  2 }, {  4,  0 }, "bookshelf" ),
	BI(  true, Block,     {  4,  2 }, {  4,  2 }, "moss stone" ),            -- 48
	BI(  true, Block,     {  5,  2 }, {  5,  2 }, "obsidian" ),
	BI( false, Stuff,     {  0,  5 }, {  0,  5 }, "torch" ),
	BI( false, Stuff,     {  0,  0 }, {  0,  0 }, "fire" ),
	BI( false, Stuff,     {  1,  4 }, {  1,  4 }, "monster spawner" ),
	BI( false, Stuff,     {  4,  0 }, {  4,  0 }, "wooden stairs" ),
	BI(  true, DataBlock, { 10,  1 }, {  9,  1 }, "chest" ),
	BI( false, Stuff,     {  4, 10 }, {  4, 10 }, "redstone wire" ),
	BI(  true, Block,     {  2,  3 }, {  2,  3 }, "diamond ore" ),           -- 56
	BI(  true, Block,     {  8,  1 }, {  8,  1 }, "diamond block" ),
	BI(  true, DataBlock, { 11,  3 }, { 11,  2 }, "crafting table" ),
	BI( false, Stuff,     {  0,  0 }, {  0,  0 }, "crops" ),
	BI(  true, Stuff,     {  2,  0 }, {  6,  5 }, "farmland" ),
	BI(  true, DataBlock, { 13,  2 }, { 14,  3 }, "furnace" ),
	BI(  true, DataBlock, { 13,  2 }, { 14,  3 }, "burning furnace" ),
	BI( false, Stuff,     {  4,  0 }, {  0,  0 }, "sign post" ),
	BI( false, Stuff,     {  1,  5 }, {  1,  6 }, "wooden door" ),           -- 64
	BI( false, Stuff,     {  3,  5 }, {  3,  5 }, "ladder" ),
	BI( false, Stuff,     {  0,  8 }, {  0,  8 }, "rails" ),
	BI( false, Stuff,     {  0,  1 }, {  0,  1 }, "clobblestone stairs" ),
	BI( false, Stuff,     {  4,  0 }, {  4,  0 }, "wall sign" ),
	BI( false, Stuff,     {  0,  0 }, {  0,  0 }, "lever" ),
	BI( false, Stuff,     {  1,  0 }, {  1,  0 }, "stone pressure plate" ),
	BI( false, Stuff,     {  2,  5 }, {  2,  6 }, "iron door" ),
	BI( false, Stuff,     {  4,  0 }, {  4,  0 }, "wooden pressure plate" ), -- 72
	BI(  true, Block,     {  3,  3 }, {  3,  3 }, "redostone ore" ),
	BI(  true, Block,     {  3,  3 }, {  3,  3 }, "glowing rstone ore" ),
	BI( false, Stuff,     {  3,  7 }, {  3,  7 }, "redstone torch off" ),
	BI( false, Stuff,     {  3,  6 }, {  3,  6 }, "redstone torch on" ),
	BI( false, Stuff,     {  1,  0 }, {  1,  0 }, "stone button" ),
	BI( false, Stuff,     {  2,  4 }, {  2,  4 }, "snow" ),
	BI(  true, Block,     {  3,  4 }, {  3,  4 }, "ice" ),
	BI(  true, Block,     {  2,  4 }, {  2,  4 }, "snow block" ),            -- 80
	BI( false, Stuff,     {  6,  4 }, {  5,  4 }, "cactus" ),
	BI(  true, Block,     {  8,  4 }, {  8,  4 }, "clay block" ),
	BI( false, Stuff,     {  9,  4 }, {  0,  0 }, "sugar cane" ),
	BI(  true, Block,     { 10,  4 }, { 11,  4 }, "jukebox" ),
	BI( false, Stuff,     {  4,  0 }, {  4,  0 }, "fence" ),
	BI(  true, DataBlock, {  6,  7 }, {  6,  6 }, "pumpkin" ),
	BI(  true, Block,     {  7,  6 }, {  7,  6 }, "netherrack" ),
	BI(  true, Block,     {  8,  6 }, {  8,  6 }, "soul sand" ),             -- 88
	BI(  true, Block,     {  9,  6 }, {  9,  6 }, "glowstone block" ),
	BI( false, Stuff,     {  0,  0 }, {  0,  0 }, "portal" ),
	BI(  true, DataBlock, {  6,  7 }, {  6,  6 }, "jack-o-lantern" ),
	BI( false, Stuff,     { 10,  7 }, {  9,  7 }, "cake block" ),
	BI( false, Stuff,     {  3,  8 }, {  3,  8 }, "redstone repeater off" ),
	BI( false, Stuff,     {  3,  9 }, {  3,  9 }, "redstone repeater on" ),
	BI( false, NA,        {  0,  0 }, {  0,  0 }, "n/a" ),
	BI( false, Stuff,     {  4,  5 }, {  4,  5 }, "trap door" ),             -- 96
}

function getSolid(num)
	if num == 0 then
		return false
	end

	local b = blocks[num]
	if b == nil then
		error("invalid block")
	else
		--print(num, b.name, b.solid)
		return b.solid
	end
end
