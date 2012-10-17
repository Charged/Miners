// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for udp based Packet.
 */
module charge.net.packet;

import std.stdint : uint8_t, uint16_t, uint32_t;
import std.gc : hasNoPointers;

import charge.net.util;


class PacketOutStream
{
	this(Packet p) {
		this(p, 0);
	}

	this(Packet p, size_t skip) {
		this.p = p;
		this.writePos = 8 + skip;
	}

	static PacketOutStream opCall(Packet p) {
		return new PacketOutStream(p);
	}

	PacketOutStream opShl(uint8_t v)
	{
		if (writePos > p.data.length)
			assert(0);

		*cast(uint8_t*)(&p.ptr[writePos]) = v;
		writePos = writePos + v.sizeof;

		return this;
	}

	PacketOutStream opShl(double v)
	{
		if (writePos + v.sizeof > p.data.length)
			assert(0);

		*cast(typeof(v)*)(&p.ptr[writePos]) = v;
		writePos = writePos + v.sizeof;

		return this;
	}

	PacketOutStream opShl(uint v)
	{
		if (writePos + v.sizeof > p.data.length)
			assert(0, "writeing to much data into packet");

		*cast(typeof(v)*)(&p.ptr[writePos]) = v;
		writePos = writePos + v.sizeof;

		return this;
	}

	PacketOutStream opShl(bool v)
	{
		return opShl(cast(ubyte)(v ? 1 : 0));
	}

private:
	size_t writePos;
	Packet p;
}

class PacketInStream
{
	this(Packet p) {
		this(p, 0);
	}

	this(Packet p, uint skip) {
		this.p = p;
		this.readPos = 8 + skip;
	}

	PacketInStream opShr(out uint8_t v)
	{
		if (readPos > p.data.length)
			assert(0);

		v = *cast(uint8_t*)(&p.ptr[readPos]);
		readPos = readPos + v.sizeof;

		return this;
	}

	PacketInStream opShr(out bool v)
	{
		uint8_t val;
		opShr(val);
		v = val == 0 ? false : true;
		return this;
	}

	PacketInStream opShr(out uint v)
	{
		if (readPos + v.sizeof > p.data.length)
			assert(0);

		v = *cast(typeof(v)*)(&p.ptr[readPos]);
		readPos = readPos + v.sizeof;

		return this;
	}

	PacketInStream opShr(out double v)
	{
		if (readPos + v.sizeof > p.data.length)
			assert(0);

		v = *cast(typeof(v)*)(&p.ptr[readPos]);
		readPos = readPos + v.sizeof;

		return this;
	}

private:
	size_t readPos;
	Packet p;
}

abstract class Packet
{
public:
	struct Header
	{
		uint8_t  type;
		uint8_t  reserved;
		uint16_t length;
		uint32_t orderId;

		enum : uint8_t
		{
			Ack,
			Unrealible,
			Realible,
			Connect,
			Ping,
			Disconnect,
			In
		}

		void hton()
		{
			length = .hton(length);
			orderId = .hton(orderId);
		}

		void ntoh()
		{
			length = .ntoh(length);
			orderId = .ntoh(orderId);
		}

	}

	void* ptr()
	{
		return data.ptr;
	}

	void[] data()
	{
		return d;
	}

	uint8_t type()
	{
		return t;
	}

	void debugPrint(bool debugPrint)
	{
		(cast(Header*)d.ptr).reserved = cast(uint8_t)(debugPrint ? 1 : 0);
	}

	bool debugPrint()
	{
		return  (cast(Header*)d.ptr).reserved == 1;
	}

package:
	this(ubyte type)
	{
		this(0, type);
	}

	this(size_t size, uint8_t type)
	{
		d.length = Header.sizeof + size;
		hasNoPointers(d.ptr);
		this.t = type;
	}

	this(void[] data, uint8_t type)
	{
		this.d = data;
		this.t = type;
	}

private:
	void[] d;
	uint8_t t;
}

class RealiblePacket : Packet
{
	this(size_t size)
	{
		super(size, Header.Realible);
	}

	this(void[] data)
	{
		super(data, Header.Realible);
	}

}

class UnrealiblePacket : Packet
{
	this(size_t size)
	{
		super(size, Header.Unrealible);
	}

	this(void[] data)
	{
		super(data, Header.Unrealible);
	}

}

class AckPacket : Packet
{
	this()
	{
		super(Header.Ack);
	}
}

class ConnectPacket : Packet
{
	this()
	{
		super(Header.Connect);
	}
}

class PingPacket : Packet
{
	this()
	{
		super(Header.Ping);
	}
}

class InPacket : Packet
{
	this(void[] data)
	{
		super(data, Header.In);
	}
}

class DisconnectPacket : Packet
{
	this()
	{
		super(Header.Disconnect);
	}
}
