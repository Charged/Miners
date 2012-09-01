// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.player;

import std.math;

import charge.charge;
import robbers.world;
import robbers.network;

import robbers.actors.car;

import lib.sdl.sdl;

class Player : GameTicker
{
public:

	mixin SysLogging;

	enum : uint
	{
		ClientJoinTeam,
		ClientUpdateHeading,
		ClientReset,
		ClientSay,
		ServerJoinTeam,
		ServerSetCar
	}

	this(World w, NetConnection c, bool server, bool player)
	{
		this.w = w;
		w.addTicker(this);
		this.c = c;
		this.server = server;
		this.player = player;

		if (!player)
			return;

		listener = new SfxListener;
		listener.active = true;
	}

	~this()
	{
		w.remTicker(this);
	}

	void setCar(Car car, uint id)
	{
		if (!player) {
			auto p = new RealiblePacket(4+4+4);
			scope auto ps = new NetOutStream(p);
			ps << cast(uint)1;
			ps << ServerSetCar;
			ps << id;
			c.send(p);
		}
		this.car = car;
	}

	Car getCar()
	{
		return car;
	}

	void packet(NetPacket p)
	{
		scope ps = new NetInStream(p, 4);
		uint cmd;
		ps >> cmd;

		if (server && cmd >= ServerJoinTeam) {
			l.warn("Invalid command to Player on server");
			return;
		} else if(!server && cmd < ServerJoinTeam) {
			l.warn("Invalid command to Player on client");
			return;
		}

		switch(cmd)
		{
			case ClientJoinTeam:
				break;

			case ClientUpdateHeading:	
				ps >> forward >> right >> left >> backward;
				break;

			case ClientReset:
				car.resetCar();
				break;

			case ClientSay:
				break;

			case ServerJoinTeam:
				break;

			case ServerSetCar:
				serverSetCar(ps);
				break;

			default:
				l.warn("Invalid command to Player");
		}
	}

	void serverSetCar(NetInStream ps)
	{
		uint id;
		ps >> id;
		auto carCast = cast(Car)w.net.get(id);
		if (carCast !is null) {
			car = carCast;
		} else {
			l.error("Server player told me wrong id ", id);
		}
	}

	void tick()
	{
		static uint tjo = 0;
		if (!server) {
			auto p = new UnrealiblePacket(4+4+5);
			scope auto ps = new NetOutStream(p);
			ps << cast(uint)1;
			ps << ClientUpdateHeading;
			ps << forward << right << left << backward;
			c.send(p);
		}
		if (server && car !is null) {
			car.move(car.Forward, forward);
			car.move(car.Right, right);
			car.move(car.Left, left);
			car.move(car.Backward, backward);
		}

		if ((server && !player) || car is null)
			return;

		auto v = car.rotation.rotateHeading;
		v.y = 0;
		v.normalize();
		v.scale(-10.0);
		v.y = 3.0;
		v = (car.position + v) - w.camera.position;
		double scale = v.lengthSqrd * 0.002 + v.length * 0.04;
		scale = fmin(v.length, scale);
		v.normalize();
		v.scale(scale);
		w.camera.position = w.camera.position + v;
		listener.position = w.camera.position;
		/* 100 fps */
		v.scale(100);
		listener.velocity = v;

		auto v2 = car.position - w.camera.position;
		v2.y = 0;
		v2.normalize();
		auto angle = acos(Vector3d.Heading.dot(v2));

		/* since we actualy don't do a cross to get the axis */
		if (v2.x > 0)
			angle = -angle;

		w.camera.rotation = Quatd(angle, Vector3d.Up);
		listener.rotation = w.camera.rotation;
	}

	void keydown(SDLKey sym)
	{
		if (sym == SDLK_w) {
			forward = true;
		} if(sym == SDLK_d) {
			right = true;
		} if(sym == SDLK_a) {
			left = true;
		} if(sym == SDLK_s) {
			backward = true;
		} else if(sym == SDLK_e) {
			if (server) {
				if (car !is null)
					car.resetCar();
			} else {
				auto p = new UnrealiblePacket(4+4);
				scope auto ps = new NetOutStream(p);
				ps << cast(uint)1;
				ps << ClientReset;
				c.send(p);
			}
		}
	}

	void keyup(SDLKey sym)
	{
		if (sym == SDLK_w) {
			forward = false;
		} else if(sym == SDLK_d) {
			right = false;
		} else if(sym == SDLK_a) {
			left = false;
		} else if(sym == SDLK_s) {
			backward = false;
		}
	}

	NetConnection net()
	{
		return c;
	}

protected:

	bool server;
	bool forward;
	bool right;
	bool left;
	bool backward;

	bool player;
	Car car;
	World w;
	NetConnection c;
	SfxListener listener;
}
