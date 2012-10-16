// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright at the bottom of this file (GPLv2 only).

/**
 * Source file that includes all of charge into one namespace.
 *
 * Also prefixing classes due to name collision.
 */
module charge.charge;


/*!
@mainpage
@section start Where to start looking
If you want to look up math related things look at the
@link Math Math group @endlink.
@n@n
For Charged Miners classic a good as place as any is the
@link miners.classic.runner.ClassicRunner ClassicRunner @endlink
@link src/miners/classic/runner.d [code] @endlink which holds most of the
gameplay logic for Charged Miners and links to the other parts of it.
*/

/*!
@defgroup Math Math related structs, classes and functions.

Charge uses a OpenGL based convetions for axis, so Y+ is up, X+ is right and
Z- is forward. For rotations the convention is to use Quatd to represent them,
which might be harder to understand in the beginning but has advantages over
other methods.
*/

public
{
	import charge.util.memory : cMemoryArray;
	import charge.util.vector : Vector, VectorData;

	import charge.math.mesh : RigidMesh, RigidMeshBuilder;
	import charge.math.picture : Picture;
	import charge.math.color : Color4b, Color3f, Color4f;
	import charge.math.vector3d : Vector3d;
	import charge.math.point3d : Point3d;
	import charge.math.quatd : Quatd;
	import charge.math.movable : Movable;
	import charge.math.matrix3x3d : Matrix3x3d;
	import charge.math.matrix4x4d : Matrix4x4d;
}

public
{
	static import charge.net.util;
	static import charge.net.http;
	static import charge.net.packet;
	static import charge.net.client;
	static import charge.net.server;
	static import charge.net.threaded;
	static import charge.net.download;
	static import charge.net.connection;

	static import charge.sfx.sfx;
	static import charge.sfx.buffer;
	static import charge.sfx.buffermanager;
	static import charge.sfx.listener;
	static import charge.sfx.source;

	static import charge.gfx.gfx;
	static import charge.gfx.vbo;
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
	static import charge.ctl.mouse;
	static import charge.ctl.keyboard;
	static import charge.ctl.joystick;

	static import charge.sys.logger;
	static import charge.sys.properties;
	static import charge.sys.resource;

	static import charge.game.world;
	static import charge.game.app;
	static import charge.game.lua;
	static import charge.game.menu;
	static import charge.game.runner;
	static import charge.game.movers;
	static import charge.game.update;
	static import charge.game.background;
	static import charge.game.actors.car;
	static import charge.game.actors.playerspawn;
	static import charge.game.actors.primitive;

	static import charge.core;
}

alias charge.net.packet.Packet NetPacket;
alias charge.net.packet.RealiblePacket RealiblePacket;
alias charge.net.packet.UnrealiblePacket UnrealiblePacket;
alias charge.net.packet.PacketInStream NetInStream;
alias charge.net.packet.PacketOutStream NetOutStream;
alias charge.net.client.Client NetClient;
alias charge.net.server.Server NetServer;
alias charge.net.threaded.ThreadedPacketQueue NetThreadedPacketQueue;
alias charge.net.threaded.ThreadedTcpConnection NetThreadedTcpConnection;
alias charge.net.http.HttpConnection NetHttpConnection;
alias charge.net.http.ThreadedHttpConnection NetThreadedHttpConnection;
alias charge.net.download.DownloadListener NetDownloadListener;
alias charge.net.download.DownloadConnection NetDownloadConnection;
alias charge.net.connection.Connection NetConnection;
alias charge.net.connection.ConnectionListener NetConnectionListener;

alias charge.sfx.sfx.sfxLoaded sfxLoaded;
alias charge.sfx.buffer.Buffer SfxBuffer;
alias charge.sfx.buffermanager.BufferManager SfxBufferManager;
alias charge.sfx.listener.Listener SfxListener;
alias charge.sfx.source.Source SfxSource;

alias charge.gfx.gfx.gfxLoaded gfxLoaded;
alias charge.gfx.vbo.VBO GfxVBO;
alias charge.gfx.vbo.RigidMeshVBO GfxRigidMeshVBO;
alias charge.gfx.cube.Cube GfxCube;
alias charge.gfx.draw.Draw GfxDraw;
alias charge.gfx.font.BitmapFont GfxBitmapFont;
alias charge.gfx.font.BitmapFont.defaultFont gfxDefaultFont;
alias charge.gfx.rigidmodel.RigidModel GfxRigidModel;
alias charge.gfx.skeleton.Bone GfxSkeletonBone;
alias charge.gfx.skeleton.SimpleSkeleton GfxSimpleSkeleton;
alias charge.gfx.light.Light GfxLight;
alias charge.gfx.light.SimpleLight GfxSimpleLight;
alias charge.gfx.light.PointLight GfxPointLight;
alias charge.gfx.light.SpotLight GfxSpotLight;
alias charge.gfx.light.Fog GfxFog;
alias charge.gfx.texture.Texture GfxTexture;
alias charge.gfx.texture.ColorTexture GfxColorTexture;
alias charge.gfx.texture.TextureArray GfxTextureArray;
alias charge.gfx.texture.TextureTarget GfxTextureTarget;
alias charge.gfx.texture.DynamicTexture GfxDynamicTexture;
alias charge.gfx.texture.WrappedTexture GfxWrappedTexture;
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
alias charge.ctl.input.Mouse CtlMouse;
alias charge.ctl.input.Keyboard CtlKeyboard;
alias charge.ctl.input.Joystick CtlJoystick;

alias charge.sys.logger.Logger SysLogger;
alias charge.sys.logger.Logging SysLogging;
alias charge.sys.properties.Properties SysProperties;
alias charge.sys.file.File SysFile;
alias charge.sys.file.FileManager SysFileManager;
alias charge.sys.file.ZipFile SysZipFile;
alias charge.sys.resource.reference sysReference;

alias charge.game.world.Ticker GameTicker;
alias charge.game.world.Actor GameActor;
alias charge.game.world.World GameWorld;
alias charge.game.app.App GameApp;
alias charge.game.app.SimpleApp GameSimpleApp;
alias charge.game.app.RouterApp GameRouterApp;
alias charge.game.lua.LuaState GameLuaState;
alias charge.game.menu.MenuRunner GameMenuRunner;
alias charge.game.runner.Runner GameRunner;
alias charge.game.runner.Router GameRouter;
alias charge.game.movers.Mover GameMover;
alias charge.game.movers.IsoCameraMover GameIsoCameraMover;
alias charge.game.movers.ProjCameraMover GameProjCameraMover;
alias charge.game.update.UpdateRunner GameUpdateRunner;
alias charge.game.update.UpdateDownloader GameUpdateDownloader;
alias charge.game.background.BackgroundRunner GameBackgroundRunner;
alias charge.game.actors.car.Car GameCar;
alias charge.game.actors.playerspawn.PlayerSpawn GamePlayerSpawn;
alias charge.game.actors.primitive.StaticCube GameStaticCube;
alias charge.game.actors.primitive.StaticRigid GameStaticRigid;

alias charge.core.Core Core;
alias charge.core.CoreOptions CoreOptions;
alias charge.core.coreFlag coreFlag;



string licenseText = r"
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
";

import license;

static this() {
	licenseArray ~= licenseText;
}
