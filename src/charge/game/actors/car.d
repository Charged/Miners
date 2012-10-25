// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.actors.car;

import std.math : pow, PI;

import charge.math.quatd;
import charge.math.point3d;
import charge.math.movable;
import charge.math.vector3d;

static import charge.gfx.rigidmodel;
static import charge.phy.material;
static import charge.phy.actor;
static import charge.phy.world;
static import charge.phy.car;

import charge.game.world;
import charge.game.actors.playerspawn;


class Car : Actor, Ticker
{
private:
	bool forward;
	bool left;
	bool right;
	bool backward;

	Point3d pos;
	Quatd rot;

	// Model
	charge.gfx.rigidmodel.RigidModel c;
	charge.gfx.rigidmodel.RigidModel wheels[4];

	charge.phy.car.Car car;

public:

	enum {
		Forward,
		Left,
		Right,
		Backward
	}

	this(World w)
	{
		super(w);
		w.addTicker(this);

		c = charge.gfx.rigidmodel.RigidModel(w.gfx, "res/car.bin");

		car = new charge.phy.car.Car(w.phy, pos);

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
			wheels[i] = charge.gfx.rigidmodel.RigidModel(w.gfx, "res/wheel2.bin");
		}

		car.material = new charge.phy.material.Material();
		car.material.collision = &this.collide;

		resetCar();
	}

	void collide(charge.phy.actor.Actor a1, charge.phy.actor.Actor a2)
	{

	}

	~this()
	{
		assert(c is null);
		assert(car is null);
	}

	void breakApart()
	{
		w.remTicker(this);
		breakApartAndNull(c);
		breakApartAndNull(car);

		foreach(ref wheel; wheels)
			breakApartAndNull(wheel);

		super.breakApart();
	}

	void resetCar()
	{
		auto ps = PlayerSpawn.random;
		car.position = ps.position;
		car.rotation = ps.rotation;
	}

	void tick()
	{
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

		for (int i; i < 4; i++)
			car.setMoveWheel(i, wheels[i]);

		/* apply air friction */
		auto v = car.velocity;
		auto l = v.length;
		v.normalize;
		auto a = pow(cast(real)l, cast(uint)2);
		v.scale(-0.015 * a);
		car.addForce(v);

		/* XXX don't hardcode this */
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
		car.getPosition(pos);
	}

	void getRotation(out Quatd rot)
	{
		car.getRotation(rot);
	}

	Vector3d velocity()
	{
		return car.velocity;
	}

}
