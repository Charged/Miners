// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.network;

import charge.charge;
import charge.math.ints;



bool diffAndWrite(void[] dst, ref int consumed, int left, int right)
{
	auto diff = left - right;
	if (!diff)
		return false;

	uint v = toDiffCode(diff);
	consumed += writeDiffCode(dst[consumed .. $], v);

	return true;
}

struct SyncData
{
	const int numSteps = 10;
	const float scale = 128.0;
	const float rotScale = ushort.max;

	uint id;
	uint count;

	union {
		struct {
			int posX;
			int posY;
			int posZ;

			int quatW;
			int quatX;
			int quatY;
			int quatZ;

			int velX;
			int velY;
			int velZ;

			int angVelX;
			int angVelY;
			int angVelZ;
		}
		int[13] array;
	}

	enum {
		ShiftPosX,
		ShiftPosY,
		ShiftPosZ,
		ShiftQuatW,
		ShiftQuatX,
		ShiftQuatY,
		ShiftQuatZ,
		ShiftVelX,
		ShiftVelY,
		ShiftVelZ,
		ShiftAngVelX,
		ShiftAngVelY,
		ShiftAngVelZ,

		BitPosX = 1 << ShiftPosX,
		BitPosY = 1 << ShiftPosY,
		BitPosZ = 1 << ShiftPosZ,
		BitQuatW = 1 << ShiftQuatW,
		BitQuatX = 1 << ShiftQuatX,
		BitQuatY = 1 << ShiftQuatY,
		BitQuatZ = 1 << ShiftQuatZ,
		BitVelX = 1 << ShiftVelX,
		BitVelY = 1 << ShiftVelY,
		BitVelZ = 1 << ShiftVelZ,
		BitAngVelX = 1 << ShiftAngVelX,
		BitAngVelY = 1 << ShiftAngVelY,
		BitAngVelZ = 1 << ShiftAngVelZ,
	}

	void reset()
	{
		array[] = 0;
	}

	RealiblePacket diff(SyncData* left)
	{
		ubyte[100] b;
		int consumed;

		uint flags;
		flags |= diffAndWrite(b, consumed, posX, left.posX) << ShiftPosX;
		flags |= diffAndWrite(b, consumed, posY, left.posY) << ShiftPosY;
		flags |= diffAndWrite(b, consumed, posZ, left.posZ) << ShiftPosZ;

		flags |= diffAndWrite(b, consumed, quatW, left.quatW) << ShiftQuatW;
		flags |= diffAndWrite(b, consumed, quatX, left.quatX) << ShiftQuatX;
		flags |= diffAndWrite(b, consumed, quatY, left.quatY) << ShiftQuatY;
		flags |= diffAndWrite(b, consumed, quatZ, left.quatZ) << ShiftQuatZ;

		flags |= diffAndWrite(b, consumed, velX, left.velX) << ShiftVelX;
		flags |= diffAndWrite(b, consumed, velY, left.velY) << ShiftVelY;
		flags |= diffAndWrite(b, consumed, velZ, left.velZ) << ShiftVelZ;

		flags |= diffAndWrite(b, consumed, angVelX, left.angVelX) << ShiftAngVelX;
		flags |= diffAndWrite(b, consumed, angVelY, left.angVelY) << ShiftAngVelY;
		flags |= diffAndWrite(b, consumed, angVelZ, left.angVelZ) << ShiftAngVelZ;

		//if (!flags)
		//	return null;

		foreach(g; b[0 .. consumed])
			assert(g != 0);

		auto mark = consumed;
		consumed += writeDiffCode(b[consumed .. $], id);
		consumed += writeDiffCode(b[consumed .. $], flags);
		consumed += writeDiffCode(b[consumed .. $], ++left.count);

		auto p = new RealiblePacket(consumed);
		auto dst = cast(ubyte[])p.data[8 .. $];

		dst[0 .. consumed - mark] = b[mark .. consumed];
		dst[consumed - mark .. consumed] = b[0 .. mark];
		//p.debugPrint = true;

		return p;
	}

	void readDiff(void[] data)
	{
		int index;

		uint id = fromDiffCode(readDiffCode(data, index));
		uint flags = readDiffCode(data, index);
		count = readDiffCode(data, index);

		assert(this.id == id);
		if (!flags)
			return;

		foreach(uint i, ref a; array) {
			if (!(flags & (1 << i)))
				continue;
			auto diff = fromDiffCode(readDiffCode(data, index));
			a -= diff;
		}
	}

	void predict()
	{
		// Assuming no gravity
		if (velY != 0)
			velY -= cast(int)(((9.82 * scale) / 100) * numSteps);
		posX += velX / numSteps;
		posY += velY / numSteps;
		posZ += velZ / numSteps;
	}

	void writeCube(PhyCube c)
	{
		float[4+3+3+3] a;

		c.getRotPosVel(a);

		// Dear compiler, please vectorize.
		quatW = cast(int)(a[0] * rotScale);
		quatX = cast(int)(a[1] * rotScale);
		quatY = cast(int)(a[2] * rotScale);
		quatZ = cast(int)(a[3] * rotScale);

		posX = cast(int)(a[4] * scale);
		posY = cast(int)(a[5] * scale);
		posZ = cast(int)(a[6] * scale);

		velX = cast(int)(a[7] * scale);
		velY = cast(int)(a[8] * scale);
		velZ = cast(int)(a[9] * scale);

		angVelX = cast(int)(a[10] * scale);
		angVelY = cast(int)(a[11] * scale);
		angVelZ = cast(int)(a[12] * scale);
	}

	void readCube(PhyCube c)
	{
		float[4+3+3+3] a;

		// Dear compiler, please vectorize.
		a[0] = cast(float)(quatW / rotScale);
		a[1] = cast(float)(quatX / rotScale);
		a[2] = cast(float)(quatY / rotScale);
		a[3] = cast(float)(quatZ / rotScale);

		a[4] = cast(float)(posX / scale);
		a[5] = cast(float)(posY / scale);
		a[6] = cast(float)(posZ / scale);

		a[7] = cast(float)(velX / scale);
		a[8] = cast(float)(velY / scale);
		a[9] = cast(float)(velZ / scale);

		a[10] = cast(float)(angVelX / scale);
		a[11] = cast(float)(angVelY / scale);
		a[12] = cast(float)(angVelZ / scale);

		/// @todo is this really needed, just in case.
		float len = a[0]*a[0] + a[1]*a[1] + a[2]*a[2] + a[3]*a[3];
		if (len == 0)
			a[0] = 1; // Unit.

		c.setRotPosVel(a);
		auto r = Quatd(a[0], a[1], a[2], a[3]);
		c.setRotation(r);
	}
}


