// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sfx.source;

import charge.math.movable;

import charge.sfx.buffer;
import charge.sfx.al;

class Source : public Movable
{
private:
	ALuint source;
	Vector3d vel;

public:
	this()
	{
		super();
		alGenSources(1, &source);

		position = Point3d();
		rotation = Quatd();
		velocity = Vector3d();
	}

	~this()
	{
		alDeleteSources(1, &source);
	}

	void setPosition(ref Point3d pos)
	{
		float[3] temp;

		super.setPosition(pos);

		temp[0] = cast(float)pos.x;
		temp[1] = cast(float)pos.y;
		temp[2] = cast(float)pos.z;

		alSourcefv(source, AL_POSITION, temp.ptr);
	}

	void velocity(Vector3d vel)
	{
		float[3] temp;

		this.vel = vel;

		temp[0] = cast(float)vel.x;
		temp[1] = cast(float)vel.y;
		temp[2] = cast(float)vel.z;

		alSourcefv(source, AL_VELOCITY, temp.ptr);
	}

	Vector3d velocity()
	{
		return vel;
	}

	void looping(bool val)
	{
		alSourcei(source, AL_LOOPING, val);
	}

	bool looping()
	{
		int val;
		alGetSourcei(source, AL_LOOPING, &val);

		return val ? true : false;
	}

	void play(Buffer b)
	{
		alSourcei(source, AL_BUFFER, b.id);
		alSourcePlay(source);
	}

}
