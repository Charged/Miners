-- Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
-- See copyright notice in src/charge/charge.d (GPLv2 only).



----
-- This script describes the objects exported from charge and minecraft.
--


----
--
-- These are the global vars set by Charged-Miners
--
-- light, SunLight
-- world, World
-- camera, Camera
-- terrain, ClassicTerrain/BetaTerrain
-- options, Options
--


----
--
-- Types
--

----
-- Color
--
-- c.r, number.
-- c.g, number.
-- c.b, number.
-- c.a, number.
--
-- TODO
--

----
-- Point
--
-- p.x, number.
-- p.y, number.
-- p.z, number.
--
-- TODO
--

----
-- Vector, three component vector.
--
-- v.x, number.
-- v.y, number.
-- v.z, number.
--
-- TODO
--

----
-- Quat, quaternation rotation.
--
-- TODO
--


----
-- Light, controls the lighting of the world.
--
-- All fields are read and writeable.
--
-- light.position, Point, the position of the light, has no effect.
-- light.rotation, Quat, controls from where the sun is shining.
-- light.diffuse, Color, the direct portion of the light.
-- light.ambient, Color, uniformely applied contribution of this light.
-- light.fog, bool, XXX
-- light.fogStart, number, where the fog starts to take effect.
-- light.fogStop, number, where the for has full effect.
-- light.fogColor, Color, objects beyond fogStop has this color.
--

----
-- World, holds everything in this world and related data.
--
-- Readable fields:
--
-- world.spawn, Point, player spawn point.
--

----
-- Camera, from where the view of the world is rendered.
--
-- camera.position, Point, the position of the camera.
-- camra.rotation, Quat, where the camera is pointing -Z is forwards.
--
