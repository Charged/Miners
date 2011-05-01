// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.actors.cube;

import std.math;
import std.stdio;

import charge.charge;
import robbers.player;
import robbers.network;
import robbers.world;

class Cube : public GameActor, public NetworkObject, public GameTicker
{
protected:
	uint id;
	PhyCube phy;
	GfxActor gfx;

	SfxSource source;
	SfxBuffer buffer;
	World w;

public:
	this(World w, uint id, bool server)
	{
		super(w);
		this.w = w;
		this.id = id;

		w.addTicker(this);
		w.net.add(this, id);

		gfx = GfxRigidModel(w.gfx, "res/cube.bin");
		phy = new PhyCube(w.phy, Point3d(0.0, 1.0, 0.0));
		
		source = new SfxSource();
		buffer = SfxBufferManager("res/beep.wav");
		if (buffer !is null)
			source.play(buffer);
		source.looping = true;
	}

	~this()
	{
		w.remTicker(this);
		w.net.rem(id);
	}

	void netPacket(NetPacket p)
	{
		float data[];
		float f;

		if (w.server) {

		} else {
			scope auto ps = new NetInStream(p, 4);

			data.length = phy.getSyncDataLength();

			for (int i; i < data.length; i++) {
				ps >> *cast(uint*)&(cast(float*)data.ptr)[i];
			}

			phy.setSyncData(data);
		}
	}

	RealiblePacket netCreateOnClient(size_t skip)
	{
		auto p = new RealiblePacket(skip+4+4);
		scope auto o = new NetOutStream(p, skip);
		uint type = 2;
		o << id;
		o << type;

		return p;
	}

	void tick()
	{
		gfx.position = phy.position;
		gfx.rotation = phy.rotation;

		if (source !is null) {
			source.position = phy.position;
			source.velocity = phy.velocity;
		}

		if (w.server) {
			float[] data;
			data.length = phy.getSyncDataLength;

			phy.getSyncData(data);

			auto p = new UnrealiblePacket(4 + data.length * 4);
			scope auto ps = new NetOutStream(p);
			ps << id;

			for (int i; i < phy.getSyncDataLength(); i++)
				ps << *cast(uint*)&(cast(float*)data.ptr)[i];

			w.net.send(p);
		}
	}

}
