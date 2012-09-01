// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.network;

import charge.charge;


interface NetworkObject
{
	/// Used by both the server and client
	void netPacket(NetPacket p);

	/// When a object is created on a client this the object is to fillout
	/// this packet with the creation info.
	/// Only on server
	RealiblePacket netCreateOnClient(size_t skip);
}

interface NetworkServerObject: public NetworkObject
{

}

/**
 * Class for managing network objects for both clients and servers. 
 */
class NetworkSender
{
protected:
	mixin SysLogging;

	NetServer s;
	NetClient c;
	uint number;
public:
	NetworkObject[uint] objects;

public:
	this(NetServer s, NetClient c)
	{
		this.s = s;	
		this.c = c;
		assert(s !is null || c !is null, "both s and c can't be null");
		number = 5;
	}

	void send(RealiblePacket pa)
	{
		if (c is null)
			s.sendAll(pa);
		else
			c.connection.send(pa);
	}

	void send(UnrealiblePacket pa)
	{
		if (c is null)
			s.sendAll(pa);
		else
			c.connection.send(pa);
	}

	uint newId()
	{
		return number++;
	}

	NetworkObject get(uint d)
	{
		auto o = d in objects;
		if (o)
			return *o;

		return null;
	}

	/**
	 * The caller doesn't need to tell the
	 * clients that the object was added.
	 */
	bool add(NetworkObject obj, uint id)
	{
		l.bug("Adding a ", (cast(Object)obj).classinfo.name, " with id ", id);

		auto o = id in objects;
		if (o)
			return false;

		objects[id] = obj;

		if (s !is null) {
			addNetObj(obj);
		}

		return true;
	}

	/**
	 * The caller doesn't need to tell the
	 * clients that the object was removed.
	 */
	bool rem(uint id)
	{
		auto o = id in objects;
		if (o is null)
			return false;

		objects.remove(id);
		if (s !is null)
			remNetObj(id);

		return true;
	}

private:
	void addNetObj(NetworkObject obj)
	{
		auto p = obj.netCreateOnClient(4+4);
		scope auto o = new NetOutStream(p);
		o << 0u; // To game on the other side;
		o << 1u; // Create
		s.sendAll(p);
	}

	void remNetObj(uint id)
	{
		auto p = new RealiblePacket(4+4+4);
		scope auto os = new NetOutStream(p);
		os << 0u; // Game
		os << 2u; // Remove
		os << id;
		s.sendAll(p);
	}
}

/**
 * Networked objects might receive packets from state
 * that are in the future, this class has code to manage
 * those packates and push them at a later time.
 */
class SyncPacketManager
{
private:
	SyncData[uint] data;
	uint gen;

public:
	this(uint gen)
	{
		this.gen = gen;
	}

	bool registerActor(NetworkObject obj, uint id)
	{
		if (id in data)
			return false;

		data[id] = new SyncData(obj);

		return true;
	}

	bool unregisterActor(uint id)
	{
		if (id in data) {
			auto d = data[id];
			data.remove(id);
			delete d;
			return true;
		}

		return false;		
	}

	bool addPacket(uint id, uint gen, NetPacket packet)
	{
		auto sync = id in data;
		if (!sync)
			return false;

		sync.addPacket(gen, packet);

		return true;
	}

	void pushPackets()
	{
		foreach(sync; data.values)
			sync.push();		
	}

	void setGen(uint gen)
	{
		this.gen = gen;
	}

protected:
	class SyncData
	{
		VectorData!(Tuple) data;
		NetworkObject obj;

		this(NetworkObject obj)
		{
			this.obj = obj;
		}

		~this()
		{
			data.removeAll();
			obj = null;
		}

		void addPacket(uint gen, NetPacket packet)
		{
			data.add(Tuple(gen, packet));
		}

		void push()
		{
			uint num;
			foreach(d; data) {
				if (d.gen <= gen) {
					obj.netPacket(d.packet);
					num++;
				} else
					break;
			}

			for (int i = 0; i < num; i++)
				data.remove(0);
		}
	}

	static struct Tuple
	{
		uint gen;
		NetPacket packet;
	}

}
