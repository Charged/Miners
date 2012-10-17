// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Car.
 */
module charge.phy.car;

import std.math : abs, fmin;

import charge.math.movable;

import charge.sys.logger;
import charge.phy.ode;
import charge.phy.actor;
import charge.phy.world;


/**
 * A four wheeled car
 */
class Car : Body, PhysicsTicker
{
private:
	mixin Logging;

public:
	/**
	 * Interface to a wheel
	 */
	static struct Wheel
	{
		/*
		 * These fields are updated every physics step
		 */

		/// Current distance from starting position to object
		double height;
		/// Current turning angle for wheel
		double turn;
		/// Current status of the wheel
		bool touched;

		/*
		 * Read from every physics step
		 */

		/// Opposit wheel to this, used for swaybar calculation
		int opposit;
		/// Radius of tire
		double radius;
		/// Is the wheel powered
		bool powered;
		/// How much the wheel should be affected by steer
		double turnFactor;
		/// Ray starting position
		Vector3d rayOffset;
		/// length of ray to shoot
		double rayLength;
		/// The direction the ray is shot
		Vector3d rayDirection;
	}

	float carPower;
	float carBreakingMuFactor;
	float carBreakingMuLimit;
	float carDesiredVel;

	float carSpringMu;
	float carSpringMu2;
	float carSpringErp;
	float carSpringCfm;

	float carDesiredTurn; /// How much you want the car to turn
	float carTurnSpeed; /// Radias per time step that carTurn aproaches carDesiredTurn
	float carTurn; /// Current turn angle

	float carSwayFactor;
	float carSwayForceLimit;
	float carSlip2Factor;
	float carSlip2Limit;

	Wheel wheel[4];

public:
	this(World w, Point3d pos)
	{
		super(w, pos);

		w.addPostColl(this);

		/* default wheel setup */
		createWheel(0, Point3d( 1.0, 0.5, -1.5), 0.5);
		createWheel(1, Point3d(-1.0, 0.5, -1.5), 0.5);
		createWheel(2, Point3d( 1.0, 0.5,  1.5), 0.5);
		createWheel(3, Point3d(-1.0, 0.5,  1.5), 0.5);

		/* default car values */
		carPower = 0;
		carDesiredVel = 0;
		carBreakingMuFactor = 0.2;
		carBreakingMuLimit = 2;

		carSpringMu = 0.01;
		carSpringMu2 = 2.5;

		carSpringErp = 0.4;
		carSpringCfm = 0.04;

		carDesiredTurn = 0;
		carTurnSpeed = 0;
		carTurn = 0;

		carSwayFactor = 4;
		carSwayForceLimit = 20;

		carSlip2Factor = 0.004;
		carSlip2Limit = 0.04;
	}

	~this()
	{
		w.removePostColl(this);
	}

	size_t getSyncDataLength()
	{
		return (3 + 4 + 3 + 3);
	}

	void setSyncData(in float data[])
	{
		if (data.length != getSyncDataLength) {
			l.warn("to little data: ", data.length);
			return;
		}
		int k;

		dBodySetPosition(dBody, data[k], data[k + 1], data[k + 2]);
		k += 3;
		dBodySetQuaternion(dBody, [data[k], data[k + 1], data[k + 2], data[k + 3]]);
		k += 4;
		dBodySetLinearVel(dBody, data[k], data[k + 1], data[k + 2]);
		k += 3;
		dBodySetAngularVel(dBody, data[k], data[k + 1], data[k + 2]);
		k += 3;

		data.length = getSyncDataLength;
	}

	void getSyncData(out float data[])
	{
		size_t ds = 3 + 4 + 3 + 3;
		data.length = ds * 5 + 1;
		int k;

		data[k .. k + 3] = *cast(float[3]*)dBodyGetPosition(dBody);
		k += 3;
		data[k .. k + 4] = *cast(float[4]*)dBodyGetQuaternion(dBody);
		k += 4;
		data[k .. k + 3] = *cast(float[3]*)dBodyGetLinearVel(dBody);
		k += 3;
		data[k .. k + 3] = *cast(float[3]*)dBodyGetAngularVel(dBody);
		k += 3;

		data.length = getSyncDataLength;
	}

	void createWheel(int i, Point3d pos, double radius)
	{
		/* we add radius to the position to get the top most part of the ray */
		wheel[i].rayOffset = Vector3d(pos.x, pos.y + radius, pos.z);
		wheel[i].radius = radius;
		wheel[i].height = radius * 2;
		wheel[i].turn = 0.0;
		wheel[i].turnFactor = 0.0;
		wheel[i].rayLength = radius * 2;
		wheel[i].rayDirection = -Vector3d.Up;
		wheel[i].powered = false;

		if (i < 2) {
			wheel[i].powered = false;
			wheel[i].turnFactor = 1.0;
		} else {
			wheel[i].powered = true;
		}
	}

	void setMoveWheel(int i, Movable m)
	{
		Vector3d v = Vector3d(
			wheel[i].rayOffset.x,
			wheel[i].rayOffset.y - wheel[i].height + wheel[i].radius,
			wheel[i].rayOffset.z);

		m.position = (rotation * v) + position;
		m.rotation = rotation * Quatd(wheel[i].turn, Vector3d.Up);
	}

	void setAllWheelPower(double vel, double power)
	{
		carDesiredVel = vel;
		carPower = power; 
	}

	void setTurning(double desiredTurn, double speed)
	{
		carDesiredTurn = desiredTurn;
		carTurnSpeed = speed;
	}

protected:
	void physicsTick()
	{
		// Variables used fo calculating the contact points
		float mu = carSpringMu;
		float mu2 = carSpringMu2;
		float slip2;
		float soft_erp = carSpringErp;
		float soft_cfm = carSpringCfm;


		// Is the car rolling
		bool rolling;
		// calculated power to each wheel
		float power;

		// Lets update the turning first
		if (carTurn < carDesiredTurn) {
			carTurn += carTurnSpeed;
			if (carTurn > carDesiredTurn)
				carTurn = carDesiredTurn;

		} else if (carTurn > carDesiredTurn) {
			carTurn -= carTurnSpeed;
			if (carTurn < carDesiredTurn)
				carTurn = carDesiredTurn;
		}

		for(uint i; i < wheel.length; i++) {
			auto we = &wheel[i];
			we.turn = we.turnFactor * carTurn;
		}


		// Since rotation and postion is calculated on every get, lets make local copies.
		Quatd rot = rotation; 
		Point3d pos = position; 

		// Lets figgure out how fast we are going in the direction of the car
		double vel;
		Vector3d velVec;
		{
			float *vec = dBodyGetLinearVel(dBody);
			velVec = Vector3d(vec[0], vec[1], vec[2]);
			vel = velVec.length();
		}

		if (vel > 0.0001) {
			velVec.normalize();
			vel *= velVec.dot(rot.rotateHeading);
		}


		if (carDesiredVel > 0.0 && vel > -0.1) {
			mu = 0.01;
			power = carPower;
		} else if (carDesiredVel < 0.0 && vel < 0.1) {
			mu = 0.01;
			power = -carPower;
		} else if (carDesiredVel == 0.0) {
			rolling = true;
			mu = 0.01;
		} else {
			mu = fmin(carBreakingMuFactor * mu2, carBreakingMuLimit);
			rolling = true;
		}

		// This lets the wheels skid, this helps a lot for turning over.
		slip2 = fmin(abs(vel) * carSlip2Factor, carSlip2Limit);

		// Lets setup the contact first
		dContact c;
		c.surface.mode =
			dContactFDir1 |
			dContactMu2 |
			/*dContactSlip1 |*/
			/*dContactBounce |*/
			dContactSlip2 |
			dContactApprox1 |
			dContactSoftERP |
			dContactSoftCFM;

		c.surface.mu = mu;
		c.surface.mu2 = mu2;
		c.surface.slip2 = slip2; // Calculated from speed
		c.surface.soft_erp = soft_erp;
		c.surface.soft_cfm = soft_cfm;

		for(uint i; i < wheel.length; i++) {
			auto we = &wheel[i];

			if (rayCast(pos + rot * we.rayOffset, rot * we.rayDirection, we.rayLength, c.geom)) {
				we.touched = true;
				we.height = c.geom.depth;
				auto vd = rot * Quatd(we.turn, Vector3d.Up) * Vector3d.Heading;
				c.fdir1[0] = vd.x;
				c.fdir1[1] = vd.y;
				c.fdir1[2] = vd.z;
				c.geom.depth = (we.rayLength - c.geom.depth);
				c.geom.g1 = null;

				dJointID j = dJointCreateContact(w.world, w.contactgroup, &c);
				dJointAttach(j, dBody, dGeomGetBody(c.geom.g2));

				// Swaybar calculations
				if (we.opposit != -1) {
					auto swayForce = carSwayFactor * (we.rayLength - we.height);

					if (swayForce > carSwayForceLimit)
						swayForce = carSwayForceLimit;

					auto p = we.rayOffset;
					auto v = we.rayDirection;
					v.scale(-swayForce);
					dBodyAddRelForceAtRelPos(dBody, v.x, v.y, v.z, p.x, p.y, p.z);
					p = wheel[we.opposit].rayOffset;
					v = wheel[we.opposit].rayDirection;
					v.scale(swayForce);
					dBodyAddRelForceAtRelPos(dBody, v.x, v.y, v.z, p.x, p.y, p.z);
				}

			} else {
				we.touched = false;
				we.height = we.rayLength;
			}

		}

		// Apply power now that we know the state of all the wheels
		for(uint i; i < wheel.length; i++) {
			auto we = &wheel[i];

			if (!we.touched || rolling || !we.powered)
				continue;

			auto p = we.rayOffset;
			auto v = Quatd(we.turn, Vector3d.Up) * Vector3d.Heading;
			v.scale(power);
			dBodyAddRelForceAtRelPos(dBody, v.x, v.y, v.z, p.x, p.y - we.height, p.z);
		}

	}
	struct Result
	{
		dBodyID ignore;
		float depth;
		dContactGeom geom;
	}

	extern(C) static void callback(void *data, dGeomID g1, dGeomID g2)
	{
		dContact c;
		auto result = cast(Result*)data;

		if (data is null) {
			l.warn("Data is null this should not happen!");
			return;
		}

		if((result.ignore && dGeomGetBody(g1) == result.ignore) || (result.ignore && result.ignore && dGeomGetBody(g2) == result.ignore))
			return;

		/* We flip the normal contact normal by haveing the g2 and g1 in this order */
		if(dCollide(g1, g2, 1, &c.geom, c.sizeof) == 1) {
			if(c.geom.depth < result.depth) {
				result.depth = c.geom.depth;
				result.geom = c.geom;
			}
		}
	}

	bool rayCast(Point3d p, Vector3d v, float length, out dContactGeom geom)
	{

		Result result;
		result.ignore = dBody;
		result.depth = float.max;

		auto ray = dCreateRay(null, geom.depth);
		dGeomRaySetClosestHit(ray, 1);
		dGeomRaySet(ray, p.x, p.y, p.z, v.x, v.y, v.z);
		dGeomRaySetLength(ray, length);
		dSpaceCollide2(ray, w.body_space, &result, &callback);
		dSpaceCollide2(ray, w.static_space, &result, &callback);

		dGeomDestroy(ray);

		geom = result.geom;
		if (result.depth < length) {
			return true;
		}

		return false;
	}




}
