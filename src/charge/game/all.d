// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.all;

public
{
	static import charge.game.world;
	static import charge.game.app;
	static import charge.game.lua;
	static import charge.game.movers;
	static import charge.game.update;
	static import charge.game.scene.app;
	static import charge.game.scene.menu;
	static import charge.game.scene.scene;
	static import charge.game.scene.update;
	static import charge.game.scene.startup;
	static import charge.game.scene.debugger;
	static import charge.game.scene.background;
	static import charge.game.actors.car;
	static import charge.game.actors.playerspawn;
	static import charge.game.actors.primitive;
}

alias charge.game.world.Ticker GameTicker;
alias charge.game.world.Actor GameActor;
alias charge.game.world.World GameWorld;
alias charge.game.app.App GameApp;
alias charge.game.lua.LuaState GameLuaState;
alias charge.game.scene.app.SceneManagerApp GameSceneManagerApp;
alias charge.game.scene.menu.MenuScene GameMenuScene;
alias charge.game.scene.scene.Scene GameScene;
alias charge.game.scene.scene.SceneManager GameSceneManager;
alias charge.game.scene.update.UpdateScene GameUpdateScene;
alias charge.game.scene.startup.Task GameTask;
alias charge.game.scene.startup.StartupScene GameStartupScene;
alias charge.game.scene.debugger.DebuggerScene GameDebuggerScene;
alias charge.game.scene.background.BackgroundScene GameBackgroundScene;
alias charge.game.movers.Mover GameMover;
alias charge.game.movers.IsoCameraMover GameIsoCameraMover;
alias charge.game.movers.ProjCameraMover GameProjCameraMover;
alias charge.game.update.UpdateDownloader GameUpdateDownloader;
alias charge.game.actors.car.Car GameCar;
alias charge.game.actors.playerspawn.PlayerSpawn GamePlayerSpawn;
alias charge.game.actors.primitive.Primitive GamePrimitive;
alias charge.game.actors.primitive.Cube GameCube;
alias charge.game.actors.primitive.Static GameStatic;
alias charge.game.actors.primitive.StaticCube GameStaticCube;
alias charge.game.actors.primitive.StaticRigid GameStaticRigid;
