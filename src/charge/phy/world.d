// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for World and PhysicsTicker.
 */
module charge.phy.world;

import charge.util.vector;

import charge.phy.phy;
import charge.phy.ode;
import charge.phy.actor;
import charge.phy.material;
import charge.sys.resource : Pool;


interface PhysicsTicker
{
	void physicsTick();
}

class World
{
public:
	Pool pool;

package:
	dWorldID world;
	dSpaceID body_space;
	dSpaceID static_space;
	dJointGroupID contactgroup;
	double step;
	uint stepLength;

protected:
	Vector!(PhysicsTicker) pre;
	Vector!(PhysicsTicker) post;

public:

	this()
	{
		if (!phyLoaded)
			throw new Exception("phy module not loaded");

		this.pool = Pool();

		world = dWorldCreate();
		body_space = dSimpleSpaceCreate(null);
		static_space = dSimpleSpaceCreate(null);

		contactgroup = dJointGroupCreate(0);
		dWorldSetGravity(world, 0, -9.8, 0);
		dWorldSetCFM(world, 1e-5);
		dWorldSetERP(world, 0.8);
		dWorldSetQuickStepNumIterations(world, 20);
	}

	void setStepLength(uint millis)
	{
		step = millis / 1000.0;
	}

	void tick()
	{
		foreach (ticker; pre)
			ticker.physicsTick();

		// Collide all movers
		dSpaceCollide(body_space, &this, &nearCallback);
		dSpaceCollide2(body_space, static_space, &this, &nearCallback);

		foreach (ticker; post)
			ticker.physicsTick();

/*		dWorldStep(world, step);*/
/*		dWorldStepFast1(world, step, numSteps);*/
		dWorldQuickStep(world, step);
		dJointGroupEmpty(contactgroup);
	}

	void addPreColl(PhysicsTicker t)
	{
		pre.add(t);
	}

	void removePreColl(PhysicsTicker t)
	{
		pre.remove(t);
	}

	void addPostColl(PhysicsTicker t)
	{
		post.add(t);
	}

	void removePostColl(PhysicsTicker t)
	{
		post.remove(t);
	}

protected:

	static Actor getActor(dGeomID o)
	{
		dBodyID b = dGeomGetBody(o);
		Actor a = null;

		if (b)
			a = cast(Actor)dBodyGetData(b);

		if (!a)
			a = cast(Actor)dGeomGetData(o);

		return a;
	}

	extern(C) static void nearCallback(void *data, dGeomID o1, dGeomID o2)
	{
		int i,n;
		World *phy = cast(World*)data;

		dBodyID b1 = dGeomGetBody(o1);
		dBodyID b2 = dGeomGetBody(o2);

		if (b1 && b2 && dAreConnected(b1, b2))
			return;

		const int N = 8;
		dContact contact[N];
		n = dCollide(o1, o2, N, &contact[0].geom, dContact.sizeof);

		if (n > 0) {

			Actor a1 = getActor(o1);
			Actor a2 = getActor(o2);

			Material m1 = a1 is null ? Material() : a1.material;
			Material m2 = a2 is null ? Material() : a2.material;

			if (m1.collision !is null)
				m1.collision(a1, a2);

			if (m2.collision !is null)
				m2.collision(a1, a2);

			for (i = 0; i < n; i++) {
				contact[i].surface.mode =
					dContactSlip1 |
					dContactSlip2 |
					dContactSoftERP |
					dContactSoftCFM |
					dContactApprox1;

				contact[i].surface.mu = 1.5;
				contact[i].surface.slip1 = 0.01;
				contact[i].surface.slip2 = 0.01;
				contact[i].surface.soft_erp = 0.3;
				contact[i].surface.soft_cfm = 0.01;

				dJointID c = dJointCreateContact(phy.world,
								phy.contactgroup, &contact[i]);
				dJointAttach(c, dGeomGetBody(o1), dGeomGetBody(o2));
			}

		}

	}

}
