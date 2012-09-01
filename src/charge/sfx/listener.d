// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sfx.listener;

import charge.math.movable;
import charge.sfx.al;

class Listener : Movable
{
private:
	static Listener current;
	ALuint listener;
	Vector3d vel;

public:
	this()
	{
		super();

		if (current is null)
			current = this;
		
		position = Point3d();
		rotation = Quatd();
		velocity = Vector3d();
	}

	~this()
	{
		if (active)
			return;

		current = null;
	}

	void setPosition(ref Point3d pos)
	{
		float[3] temp;

		super.setPosition(pos);

		if (!active)
			return;

		temp[0] = cast(float)pos.x;
		temp[1] = cast(float)pos.y;
		temp[2] = cast(float)pos.z;

		alListenerfv(AL_POSITION, temp.ptr);
	}

	void setRotation(ref Quatd rot)
	{
		float[6] temp;

		super.setRotation(rot);

		if (!active)
			return;

		auto head = rot.rotateHeading;
		auto up = rot.rotateUp;

		temp[0] = cast(float)head.x;
		temp[1] = cast(float)head.y;
		temp[2] = cast(float)head.z;
		
		temp[3] = cast(float)up.x;
		temp[4] = cast(float)up.y;
		temp[5] = cast(float)up.z;

		alListenerfv(AL_ORIENTATION, temp.ptr);
	}

	void active(bool val)
	{
		if (val) {
			current = this;
			position = pos;
			rotation = rot;
			velocity = vel;
		} else {
			if (active)
				current = null;
		}
	}

	bool active()
	{
		return current is this;
	}

	void velocity(Vector3d vel)
	{
		float[3] temp;

		this.vel = vel;

		if (!active)
			return;

		temp[0] = cast(float)vel.x;
		temp[1] = cast(float)vel.y;
		temp[2] = cast(float)vel.z;

		alListenerfv(AL_VELOCITY, temp.ptr);
	}

	Vector3d velocity()
	{
		return vel;
	}

}
