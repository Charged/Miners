// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.actors.car;

import std.math;
import std.stdio;

import charge.charge;
import robbers.network;
import robbers.world;

import robbers.actors.playerspawn;

class Car : GameActor, NetworkObject, GameTicker
{
private:

	mixin SysLogging;

	bool forward;
	bool left;
	bool right;
	bool backward;

	Point3d pos;
	Quatd rot;

	SfxSource source;
	SfxBuffer buffer;

	// Model
	GfxRigidModel c;
	GfxRigidModel wheels[4];

	PhyCar car;
	World w;
	uint id;

public:

	enum {
		Forward,
		Left,
		Right,
		Backward
	}

	this(World w, uint id, bool server)
	{
		super(w);
		this.w = w;
		w.addTicker(this);
		this.id = id; // this must be set before adding to the NetworkSender
		w.net.add(this, id);

		if (!w.server)
			w.sync.registerActor(this, id);

		source = new SfxSource();
		//buffer = SfxBufferManager("res/beep.wav");
		if (buffer !is null)
			source.play(buffer);
		source.looping = true;

		c = GfxRigidModel(w.gfx, "res/car.bin");

		car = new PhyCar(w.phy, pos);

		car.massSetBox(15.0, 2.0, 1.0, 3.0);

		car.collisionBoxAt(Point3d(0, 0.475, 0.075), 2.0, 0.75, 4.75);
		car.collisionBoxAt(Point3d(0, 1.0075, 0.85), 1.3, 0.45, 2.4);

		car.wheel[0].powered = true;
		car.wheel[0].radius = 0.36;
		car.wheel[0].rayLength = 0.76;
		car.wheel[0].rayOffset = Vector3d( 0.82, 0.36, -1.5);
		car.wheel[0].opposit = 1;

		car.wheel[1].powered = true;
		car.wheel[1].radius = 0.36;
		car.wheel[1].rayLength = 0.76;
		car.wheel[1].rayOffset = Vector3d(-0.82, 0.36, -1.5);
		car.wheel[1].opposit = 0;

		car.wheel[2].powered = false;
		car.wheel[2].radius = 0.36;
		car.wheel[2].rayLength = 0.76;
		car.wheel[2].rayOffset = Vector3d( 0.82, 0.36, 1.5);
		car.wheel[2].opposit = 3;

		car.wheel[3].powered = false;
		car.wheel[3].radius = 0.36;
		car.wheel[3].rayLength = 0.76;
		car.wheel[3].rayOffset = Vector3d(-0.82, 0.36, 1.5);
		car.wheel[3].opposit = 2;

		car.carPower = 0;
		car.carDesiredVel = 0;
		car.carBreakingMuFactor = 0.2;
		car.carBreakingMuLimit = 2;

		car.carSpringMu = 0.01;
		car.carSpringMu2 = 2.5;

		car.carSpringErp = 0.3;
		car.carSpringCfm = 0.1;

		car.carDesiredTurn = 0;
		car.carTurnSpeed = 0;
		car.carTurn = 0;

		car.carSwayFactor = 25.0;
		car.carSwayForceLimit = 20000;

		car.carSlip2Factor = 0.004;
		car.carSlip2Limit = 0.04;

		for (int i; i < 4; i++) {
			wheels[i] = GfxRigidModel(w.gfx, "res/wheel2.bin");
		}

		car.material = new PhyMaterial();
		car.material.collision = &this.collide;

		//if (w.server)
			resetCar();
	}

	void collide(PhyActor a1, PhyActor a2)
	{

	}

	~this()
	{
		if (!w.server)
			w.sync.unregisterActor(id);

		foreach(wheel; wheels)
			delete wheel;

		delete c;
		delete car;

		w.net.rem(id);
		w.rem(this);
		w.remTicker(this);
	}

	void resetCar()
	{
		auto ps = PlayerSpawn.random;
		car.position = ps.position;
		car.rotation = ps.rotation;
	}

	RealiblePacket netCreateOnClient(size_t skip)
	{
		auto p = new RealiblePacket(skip+4+4);
		scope auto o = new NetOutStream(p, skip);

		o << id;
		o << 1u;

		return p;
	}

	void netPacket(NetPacket p)
	{
		float data[];
		float f;
		uint gen;

		if (w.server) {
			scope auto ps = new NetInStream(p, 4);
			ps >> forward >> right >> left >> backward;
		} else {
			scope auto ps = new NetInStream(p, 4);
			ps >> forward >> right >> left >> backward;
			ps >> gen;

			if (w.gen < gen) {
				auto s = w.sync();
				s.addPacket(id, gen, p);
				return;
			}

			data.length = car.getSyncDataLength();

			for (int i; i < data.length; i++) {
				ps >> *cast(uint*)&(cast(float*)data.ptr)[i];
			}

			car.setSyncData(data);
		}
	}

	void tick()
	{
		float data[];

		static int tjo = 0;
		if (w.server) {
			car.getSyncData(data);

			auto p = new UnrealiblePacket(4 + 4 + 4 + data.length * 4);
			scope auto ps = new NetOutStream(p);
			ps << id;
			ps << forward << right << left << backward;
			ps << w.gen;

			for (int i; i < car.getSyncDataLength(); i++)
				ps << *cast(uint*)&(cast(float*)data.ptr)[i];

			w.net.send(p);
		}

		double s = PI * 0.10;
		if (forward && !backward)
			car.setAllWheelPower(40.0, 50.0);
		else if(backward && !forward)
			car.setAllWheelPower(-10.0, 50.0);
		else
			car.setAllWheelPower(0.0, 1.0);

		if (right && !left) {
			car.setTurning(-s, 0.01);
		} else if (left && !right) {
			car.setTurning(s, 0.01);
		} else {
			car.setTurning(0, 0.15);
		}

		c.position = car.position;
		c.rotation = car.rotation * Quatd(PI, Vector3d.Up);

		if (source !is null) {
			source.position = car.position;
			source.velocity = car.velocity;
		}

		for (int i; i < 4; i++)
			car.setMoveWheel(i, wheels[i]);

		/* apply air friction */
		auto v = car.velocity;
		auto l = v.length;
		v.normalize;
		auto a = pow(cast(real)l, cast(uint)2);
		v.scale(-0.015 * a);
		car.addForce(v);

		/* don't hardcode this */
		if (car.position.y < -50)
			resetCar();
	}

	void move(int dir, bool v)
	{
		if (dir == Forward)
			forward = v;
		else if (dir == Left)
			left = v;
		else if (dir == Right)
			right = v;
		else if (dir == Backward)
			backward = v;
	}

	void getPosition(out Point3d pos)
	{
		pos = car.position;
	}

	void getRotation(out Quatd rot)
	{
		rot = car.rotation;
	}

	Vector3d velocity()
	{
		return car.velocity;
	}
}
