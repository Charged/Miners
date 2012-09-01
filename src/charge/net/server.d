// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.net.server;

import std.stdint;
import std.socket;

import charge.util.fifo;

import charge.sys.logger;

import charge.net.packet;
import charge.net.connection;


class Server
{
public:

	mixin Logging;

	this(ushort port, ConnectionListener cl)
	{
		fifo = new ConnectionFifo();
		auto add = new InternetAddress(InternetAddress.ADDR_ANY, port);
		s = new UdpSocket();
		set = new SocketSet(1);
		s.bind(add);
		s.blocking(false);
		set.add(s);
		this.cl = cl;
	}

	Connection accept()
	{
		if (fifo.length)
			return fifo.pop;
		return null;
	}

	void close()
	{
		foreach(c; connections.values) {
			close(c);
		}
	}

	void close(Connection c)
	{
		Key k = c.key;

		if (!(k in connections))
			return;

		c.close();
		c.finalizeClose();
		connections.remove(k);
	}

	void sendAll(RealiblePacket p)
	{
		foreach(c; connections.values)
			c.send(p);
	}

	void sendAll(UnrealiblePacket p)
	{
		foreach(c; connections.values)
			c.send(p);
	}

	void tick()
	{
		alias Packet.Header Header;
		Address a;
		Header *h;
		// Windows is stupid and you must take the entire package
		uint8_t peek[1024];

		while(true) {
			auto n = s.receive(peek, SocketFlags.PEEK);

			void buffer[];

			if (n <= 0) {
				break;
			} else if (n < Header.sizeof) {
				l.warn("invalid header for packet");
				// Safe because n can not be < 0
				buffer.length = cast(size_t)n;
				s.receiveFrom(buffer, a);
				break;
			}

			h = cast(Header*)peek.ptr;
			h.ntoh;

			if (h.length < Header.sizeof) {
				l.warn("invalid packet received");
				s.receiveFrom(peek, a);
				continue;
			}

			buffer.length = h.length;
			n = s.receiveFrom(buffer, a);

			if (n <> buffer.length) {
				l.warn("invalid length");
				continue;
			}

			auto c = Key(a) in connections;
			if (c is null) {

				// Stray packet?
				if (h.type <> h.Connect || h.orderId <> 0)
					continue;

				auto cnew = new Connection(s, a, cl);
				connections[cnew.key] = cnew;
				if (l is null)
					fifo.add = cnew;
				c = &cnew;
			}

			c.processData(buffer);
		}

		foreach(c; connections.values) {
			c.tick();

			if (c.status > c.Connected) {
				close(c);
			}
		}
	}

private:
	alias AddressKey Key;

	Connection[Key] connections;

	alias Fifo!(Connection) ConnectionFifo;
	ConnectionFifo fifo;
	UdpSocket s;
	SocketSet set;
	ConnectionListener cl;
}
