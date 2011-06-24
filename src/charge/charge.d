// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright at the bottom of this file (GPLv2 only).
module charge.charge;

/*
 * Includes all of charge into one namespace.
 * Also prefixing classes for due to name collision otherwise.
 */

public
{
	static import charge.util.memory;
	static import charge.util.vector;

	static import charge.math.mesh;
	static import charge.math.picture;
	static import charge.math.color;
	static import charge.math.vector3d;
	static import charge.math.point3d;
	static import charge.math.quatd;
	static import charge.math.movable;
	static import charge.math.matrix3x3d;
	static import charge.math.matrix4x4d;

	static import charge.net.util;
	static import charge.net.packet;
	static import charge.net.client;
	static import charge.net.server;
	static import charge.net.connection;

	static import charge.sfx.sfx;
	static import charge.sfx.buffer;
	static import charge.sfx.buffermanager;
	static import charge.sfx.listener;
	static import charge.sfx.source;

	static import charge.gfx.gfx;
	static import charge.gfx.cube;
	static import charge.gfx.draw;
	static import charge.gfx.font;
	static import charge.gfx.rigidmodel;
	static import charge.gfx.skeleton;
	static import charge.gfx.light;
	static import charge.gfx.texture;
	static import charge.gfx.material;
	static import charge.gfx.world;
	static import charge.gfx.camera;
	static import charge.gfx.renderer;

	static import charge.phy.phy;
	static import charge.phy.actor;
	static import charge.phy.material;
	static import charge.phy.cube;
	static import charge.phy.sphere;
	static import charge.phy.car;
	static import charge.phy.world;

	static import charge.ctl.input;
	static import charge.ctl.device;
	static import charge.ctl.keyboard;
	static import charge.ctl.mouse;

	static import charge.sys.logger;
	static import charge.sys.properties;

	static import charge.game.world;
	static import charge.game.app;
	static import charge.game.lua;
	static import charge.game.runner;
	static import charge.game.movers;
	static import charge.game.actors.car;
	static import charge.game.actors.playerspawn;
	static import charge.game.actors.primitive;

	static import charge.core;
}

alias charge.util.memory.cMemoryArray cMemoryArray;
alias charge.util.vector.Vector Vector;
alias charge.util.vector.VectorData VectorData;

alias charge.math.mesh.RigidMesh RigidMesh;
alias charge.math.mesh.RigidMeshBuilder RigidMeshBuilder;
alias charge.math.picture.Picture Picture;
alias charge.math.movable.Movable Movable;
alias charge.math.vector3d.Vector3d Vector3d;
alias charge.math.point3d.Point3d Point3d;
alias charge.math.quatd.Quatd Quatd;
alias charge.math.color.Color4b Color4b;
alias charge.math.color.Color3f Color3f;
alias charge.math.color.Color4f Color4f;
alias charge.math.matrix3x3d.Matrix3x3d Matrix3x3d;
alias charge.math.matrix4x4d.Matrix4x4d Matrix4x4d;

alias charge.net.packet.Packet NetPacket;
alias charge.net.packet.RealiblePacket RealiblePacket;
alias charge.net.packet.UnrealiblePacket UnrealiblePacket;
alias charge.net.packet.PacketInStream NetInStream;
alias charge.net.packet.PacketOutStream NetOutStream;
alias charge.net.client.Client NetClient;
alias charge.net.server.Server NetServer;
alias charge.net.connection.Connection NetConnection;
alias charge.net.connection.ConnectionListener NetConnectionListener;

alias charge.sfx.sfx.sfxLoaded sfxLoaded;
alias charge.sfx.buffer.Buffer SfxBuffer;
alias charge.sfx.buffermanager.BufferManager SfxBufferManager;
alias charge.sfx.listener.Listener SfxListener;
alias charge.sfx.source.Source SfxSource;

alias charge.gfx.gfx.gfxLoaded gfxLoaded;
alias charge.gfx.cube.Cube GfxCube;
alias charge.gfx.draw.Draw GfxDraw;
alias charge.gfx.font.Font GfxFont;
alias charge.gfx.rigidmodel.RigidModel GfxRigidModel;
alias charge.gfx.skeleton.SimpleSkeleton GfxSimpleSkeleton;
alias charge.gfx.light.Light GfxLight;
alias charge.gfx.light.SimpleLight GfxSimpleLight;
alias charge.gfx.light.PointLight GfxPointLight;
alias charge.gfx.light.SpotLight GfxSpotLight;
alias charge.gfx.light.Fog GfxFog;
alias charge.gfx.texture.Texture GfxTexture;
alias charge.gfx.texture.TextureArray GfxTextureArray;
alias charge.gfx.texture.TextureTarget GfxTextureTarget;
alias charge.gfx.texture.DynamicTexture GfxDynamicTexture;
alias charge.gfx.material.Material GfxMaterial;
alias charge.gfx.material.SimpleMaterial GfxSimpleMaterial;
alias charge.gfx.material.MaterialManager GfxMaterialManager;
alias charge.gfx.world.Actor GfxActor;
alias charge.gfx.world.World GfxWorld;
alias charge.gfx.camera.Camera GfxCamera;
alias charge.gfx.camera.ProjCamera GfxProjCamera;
alias charge.gfx.camera.OrthoCamera GfxOrthoCamera;
alias charge.gfx.camera.IsoCamera GfxIsoCamera;
alias charge.gfx.renderer.Renderer GfxRenderer;
alias charge.gfx.fixed.FixedRenderer GfxFixedRenderer;
alias charge.gfx.forward.ForwardRenderer GfxForwardRenderer;
alias charge.gfx.deferred.DeferredRenderer GfxDeferredRenderer;
alias charge.gfx.target.RenderTarget GfxRenderTarget;
alias charge.gfx.target.DefaultTarget GfxDefaultTarget;
alias charge.gfx.target.DoubleTarget GfxDoubleTarget;

alias charge.phy.phy.phyLoaded phyLoaded;
alias charge.phy.actor.Actor PhyActor;
alias charge.phy.actor.Body PhyBody;
alias charge.phy.actor.Static PhyStatic;
alias charge.phy.material.Material PhyMaterial;
alias charge.phy.geom.Geom PhyGeom;
alias charge.phy.geom.GeomCube PhyGeomCube;
alias charge.phy.geom.GeomSphere PhyGeomSphere;
alias charge.phy.geom.GeomMesh PhyGeomMesh;
alias charge.phy.cube.Cube PhyCube;
alias charge.phy.sphere.Sphere PhySphere;
alias charge.phy.car.Car PhyCar;
alias charge.phy.world.World PhyWorld;

alias charge.ctl.input.Input CtlInput;
alias charge.ctl.input.Device CtlDevice;
alias charge.ctl.input.Keyboard CtlKeyboard;
alias charge.ctl.input.Mouse CtlMouse;

alias charge.sys.logger.Logger SysLogger;
alias charge.sys.logger.Logging SysLogging;
alias charge.sys.properties.Properties SysProperties;
alias charge.sys.file.File SysFile;
alias charge.sys.file.FileManager SysFileManager;
alias charge.sys.file.ZipFile SysZipFile;

alias charge.game.world.Ticker GameTicker;
alias charge.game.world.Actor GameActor;
alias charge.game.world.World GameWorld;
alias charge.game.app.App GameApp;
alias charge.game.app.SimpleApp GameSimpleApp;
alias charge.game.lua.LuaState GameLuaState;
alias charge.game.runner.Runner GameRunner;
alias charge.game.runner.Router GameRouter;
alias charge.game.movers.Mover GameMover;
alias charge.game.movers.IsoCameraMover GameIsoCameraMover;
alias charge.game.movers.ProjCameraMover GameProjCameraMover;
alias charge.game.actors.car.Car GameCar;
alias charge.game.actors.playerspawn.PlayerSpawn GamePlayerSpawn;
alias charge.game.actors.primitive.StaticCube GameStaticCube;
alias charge.game.actors.primitive.StaticRigid GameStaticRigid;

alias charge.core.Core Core;



char[] licenseText = `
Copyright © 2011, Jakob Bornecrantz.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation version 2 (GPLv2)
of the License only.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
`;

import license;

static this() {
	licenseArray ~= licenseText;
}
