// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for udp based Client.
 */
module charge.net.client;

import std.stdint : uint8_t;
import std.socket : UdpSocket, SocketFlags, InternetAddress, AddressException;

import charge.sys.logger;

import charge.net.packet;
import charge.net.connection;


class Client
{
public:
	mixin Logging;

	this(ConnectionListener cl)
	{
		this.cl = cl;
	}

	bool connect(string host, ushort port)
	{
		if (s !is null)
			return false;

		s = new UdpSocket();
		s.blocking(false);

		InternetAddress a;

		try {
			a = new InternetAddress(host, port);
		} catch (AddressException ae) {
			l.warn(ae);
			return false;
		}

		s.connect(a);
		c = new Connection(s, a, cl);

		return true;
	}

	void close()
	{
		if (c !is null) {
			c.close();
			c.finalizeClose();
		}
		if (s !is null)
			s.close();

		s = null;
		c = null;
	}

	void tick()
	{
		if (s is null)
			return;

		alias Packet.Header Header;

		Header *h;
		// Windows is stupid and you must take the entire packege
		uint8_t peek[1024];

		while(true) {
			// Don't need receiveFrom since we have connected.
			auto n = s.receive(peek, SocketFlags.PEEK);

			void[] buffer;
			if (n <= 0) {
				break;
			} else if (n < cast(int)Header.sizeof) {
				l.warn("invalid header for packet");
				buffer.length = n;
				s.receive(buffer);
				continue;
			}

			h = cast(Header*)peek.ptr;
			h.ntoh();

			if (h.length < Header.sizeof) {
				l.warn("invalid packet received");
				buffer.length = n;
				s.receive(buffer);
				continue;
			}

			buffer.length = h.length;
			n = s.receive(buffer);

			if (n <> buffer.length) {
				l.warn("invalid length");
				continue;
			}

			c.processData(buffer);
		}

		c.tick();

		if (c.status > c.Connected) {
			close();
		}
	}

	Connection connection()
	{
		return c;
	}

private:
	bool connecting;
	UdpSocket s;
	Connection c;
	ConnectionListener cl;
}
