// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.math.matrix3x3d;

import charge.math.quatd;

struct Matrix3x3d
{
	union {
		double[3][3] m;
		struct {
			double a, b, c;
			double d, e, f;
			double g, h, i;
		}
	}

	void opAssign(Quatd q) {
		a = 1 - 2 * q.y * q.y - 2 * q.z * q.z;
		b =     2 * q.x * q.y - 2 * q.w * q.z;
		c =     2 * q.x * q.z + 2 * q.w * q.y;

		d =     2 * q.x * q.y + 2 * q.w * q.z;
		e = 1 - 2 * q.x * q.x - 2 * q.z * q.z;
		f =     2 * q.y * q.z - 2 * q.w * q.x;

		g =     2 * q.x * q.z - 2 * q.w * q.y;
		h =     2 * q.y * q.z + 2 * q.w * q.x;
		i = 1 - 2 * q.x * q.x - 2 * q.y * q.y;
	}
}
