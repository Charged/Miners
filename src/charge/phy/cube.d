// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.phy.cube;

import charge.math.movable;

import charge.sys.logger;

import charge.phy.ode;
import charge.phy.actor;
import charge.phy.world;


class Cube : Body
{
	mixin Logging;

	this(World phy, Point3d pos)
	{
		super(phy, pos);

		massSetBox(1.0, 1.0, 1.0, 1.0);
		collisionBox(1.0, 1.0, 1.0);
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

protected:
	dGeomID dGeom;
}
