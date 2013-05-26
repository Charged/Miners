// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.all;

public
{
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
}

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
alias charge.game.actors.primitive.Primitive GamePrimitive;
alias charge.game.actors.primitive.Cube GameCube;
alias charge.game.actors.primitive.Static GameStatic;
alias charge.game.actors.primitive.StaticCube GameStaticCube;
alias charge.game.actors.primitive.StaticRigid GameStaticRigid;
