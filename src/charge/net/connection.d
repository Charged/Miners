// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.net.connection;

import std.stdio : writef;
import std.socket : Socket, Address, InternetAddress;
import std.stdint : uint8_t;

import lib.sdl.sdl;

import charge.util.fifo;
import charge.util.vector;
import charge.net.packet;


private void dump(string append, uint8_t[] data)
{
	writef(append);
	foreach(i, c; data) {
		if (i % 4 == 0)
			writef(" ");
		writef("%02x", c);
		if (i >= 23) {
			writef(" ...");
			break;
		}
	}

	writef("\n");
}

interface ConnectionListener
{
	void packet(Connection c, Packet p);
	void closed(Connection c);
	void opened(Connection c);
}

struct AddressKey
{

	static AddressKey opCall(uint addr, ushort port)
	{
		AddressKey a;
		a.addr = addr;
		a.port = port;
		return a;
	}

	static AddressKey opCall(Address addy)
	{
		auto a = cast(InternetAddress) addy;

		if (a is null) {
			assert(0, "unsupported address type");
		} else {
			return AddressKey(a.addr(), a.port());
		}
	}

	uint toHash()
	{
		return addr * port;
	}

	int opCmp(AddressKey *k)
	{
		if (addr < k.addr) {
			return -1;
		} else if (addr == k.addr) {
			return cast(int)port - cast(int)k.port;
		} else {
			return 1;
		}
	}

	string toString()
	{
		auto a = *cast(ubyte[4]*)&addr;
		// XXX Byte order
		return std.string.format(
			"(%s.%s.%s.%s:%s)",
			a[3], a[2], a[1], a[0],
			port);
	}

	uint addr;
	ushort port;
}

class Connection
{
	enum {
		Connecting,
		Connected,
		Closeing, // Closed by our side
		TimedOut, // Connection timedout
		Disconnected, // Closed by remote site
		Closed, // Socket fully closed
	}

	this(Socket s, Address a, ConnectionListener l)
	{
		this.s = s;
		this.a = a;
		this.l = l;
		this.fifo = new PacketFifo();

		auto cp = new ConnectPacket();
		sendTo(cp, realibleNumOut);
		addRealible(cp, realibleNumOut++);
		lastReceived = lastSent = SDL_GetTicks();
		state = Connecting;
		k = AddressKey(a);
	}

	void close()
	{
		if (state <= Connected) {
			state = Closeing;
			auto dp = new DisconnectPacket();
			sendTo(dp, 0);
		}
	}

	AddressKey key()
	{
		return k;
	}

	ConnectionListener listener()
	{
		return l;
	}

	void listener(ConnectionListener l)
	{
		this.l = l;
	}

	Packet receive()
	{
		return fifo.pop();
	}

	bool send(RealiblePacket p)
	{
		if (state > Connected)
			return false;

		sendTo(p, realibleNumOut);
		addRealible(p, realibleNumOut++);
		return true;
	}

	bool send(UnrealiblePacket p)
	{
		if (state > Connected)
			return false;

		sendTo(p, unrealibleNumOut++);
		return true;
	}

	void tick()
	{
		if (state == Closed)
			return;

		uint time = SDL_GetTicks();
		foreach(p; unAckedPackets) {
			if (p.t > time)
				continue;

			sendTo(p.p, p.id);
			p.t = time + timeout;
		}

		if ((time > timeout * 2 + lastSent) && state == Connected) {
			lastSent = time;
			sendTo(new PingPacket(), 0);
		}

		if (time > timeout * 10 + lastReceived) {
			state = TimedOut;
		}
	}

	Address address()
	{
		return a;
	}

	int status()
	{
		return state;
	}

package:
	alias Packet.Header Header;

	/* Callback for Server and Client to realy close the connection */
	void finalizeClose()
	{
		if (l !is null)
			l.closed(this);

		l = null;
		s = null;
		a = null;
		state = Closed;
	}

	void processData(void[] data)
	{
		lastReceived = SDL_GetTicks();

		auto h = cast(Header*)data.ptr;

		if ((cast(bool[])data)[1])
			dump("c<<", cast(uint8_t[])data);

		h.ntoh();

		if (h.type == Header.Ack) {
			processAck(*h);
		} else if (h.type == Header.Unrealible) {
			processUnrealible(data);
		} else if (h.type == Header.Realible) {
			processRealible(data);
		} else if (h.type == Header.Connect) {
			if (realibleNumIn == 0) {
				realibleNumIn++;
				checkFuturePackets();
				state = Connected;
				if (l !is null)
					l.opened(this);
			}

			scope auto ack = new AckPacket();
			sendTo(ack, 0);
		} else if (h.type == Header.Disconnect) {
			state = Disconnected;
		}
	}

private:
	void processAck(Header h)
	{
		foreach(p; unAckedPackets) {
			// We check against stored value since buffers might be shared
			// And stored in network byte order
			if (p.id <> h.orderId)
				continue;

			unAckedPackets.remove(p);
			break;
		}
	}

	void processUnrealible(void[] data)
	{
		auto h = cast(Header*)data.ptr;

		if (h.orderId <= unrealibleNumIn)
			return;

		unrealibleNumIn = h.orderId;

		receive(new UnrealiblePacket(data));
	}

	void processRealible(void[] data)
	{
		auto h = cast(Header*)data.ptr;
		scope auto ack = new AckPacket();
		sendTo(ack, h.orderId);

		if (h.orderId == realibleNumIn) {
			realibleNumIn++;
			receive(new RealiblePacket(data));
		} else if (h.orderId > realibleNumIn) {
			outOfOrderPackets.add(new RealiblePacket(data));
		} else {

		}
	}

	void checkFuturePackets()
	{
		start:

		foreach(p; outOfOrderPackets) {
			auto h = cast(Header*)p.ptr;
			if (h.orderId <> realibleNumIn)
				continue;

			realibleNumIn++;
			outOfOrderPackets.remove(p);

			receive(p);

			goto start;
		}
	}

	void receive(Packet p)
	{
		if (l is null)
			fifo.add(p);
		else
			l.packet(this, p);
	}

	void sendTo(Packet p, int orderId)
	{
		auto h = cast(Header*)p.ptr;
		h.type = p.type;
		h.length = cast(ushort)p.data.length;
		h.orderId = orderId;
		h.reserved = cast(uint8_t)(p.debugPrint ? 1 : 0);
		h.hton();

		s.sendTo(p.data, a);
		lastSent = SDL_GetTicks();

		if (p.debugPrint)
			dump("c>>", cast(uint8_t[])p.data);
	}

	void addRealible(Packet p, int orderId)
	{
		unAckedPackets.add(new Pair(SDL_GetTicks() + timeout, orderId, p));
	}

	static class Pair
	{
	public:
		this(uint time, int id, Packet packet)
		{
			this.t = time;
			this.id = id;
			this.p = packet;
		}

		uint t;
		int id;
		Packet p;
	}

	int state;

	Socket s;
	Address a;
	ConnectionListener l;
	AddressKey k;

	int realibleNumOut;
	int unrealibleNumOut;
	int realibleNumIn;
	int unrealibleNumIn;

	uint timeout = 1000;
	uint lastSent;
	uint lastReceived;

	alias Vector!(Packet) PacketVector;
	PacketVector outOfOrderPackets;

	alias Vector!(Pair) PacketPairVector;
	PacketPairVector unAckedPackets;

	alias Fifo!(Packet) PacketFifo;
	PacketFifo fifo;
}
