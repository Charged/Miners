// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.net.threaded;

version(Unix) {
	import std.c.unix.unix;
}
import std.c.stdlib;

import std.thread;
import std.socket;
import std.outofmemory;

/**
 * A TCP connection that listens in a seperate thread.
 *
 * You need to implement both the run method and loop. But this class
 * has code for queue up packets in a queue that can be accesses from
 * another thread. It is only intended to be a one shot connection.
 *
 * Protected functions are less safe then the public ones.
 */
class ThreadedTcpConnection : public Thread
{
protected:
	TcpSocket s;

public:
	bool connected()
	{
		synchronized (this) {
			return s !is null;
		}
	}

	void shutdown()
	{
		synchronized (this) {
			if (s is null)
				throw new Exception("Not connected");
		}

		s.shutdown(SocketShutdown.BOTH);
	}

	void close()
	{
		synchronized (this) {
			if (s is null)
				throw new Exception("Not connected");
		}

		s.close();
	}

protected:
	this(bool start = true, TcpSocket s = null)
	{
		this.s = s;
		if (start)
			this.start();
	}

	/**
	 * Connect to a remote host.
	 */
	void connect(char[] hostname, ushort port)
	{
		auto a = new InternetAddress(hostname, port);
		connect(a);
	}

	/**
	 * Connect to a remote host.
	 */
	synchronized void connect(Address addr)
	{
		if (s !is null)
			throw new Exception("Allready connected");
		s = new TcpSocket(addr);
	}

	/**
	 * Handle getting interupts from the GC on Unix.
	 */
	int receive(void[] buf, bool peek = false)
	{
		SocketFlags flags = cast(SocketFlags)0;
		flags |= SocketFlags.NOSIGNAL;
		flags |= peek ? SocketFlags.PEEK : 0;

		version(Unix) {
			int n;
			while(true) {
				n = s.receive(buf, flags);
				if (n < 0 && getErrno() == EINTR)
					continue;
				return n;
			}
		} else {
			return cast(int)s.receive(buf, flags);
		}
	}
}

class ThreadedPacketQueue : public ThreadedTcpConnection
{
private:
	/* Packet list protected by synchronized (this) */
	Packet *first;
	Packet *last;

protected:
	this(bool start = true, TcpSocket s = null)
	{
		super(start, s);
	}

	/**
	 * Internal class representing a fixed length packet.
	 *
	 * Has functions to allocate it from the C heap.
	 */
	static struct Packet {
		Packet *next;

		static Packet* cAlloc(size_t len)
		{
			auto p = cast(Packet*)malloc((void*).sizeof + len);
			if (!p)
				throw new OutOfMemoryException();
			p.next = null;
			return p;
		}

		void cFree()
		{
			free(this);
		}

		ubyte* data()
		{
			return (cast(ubyte*)&(this[1]));
		}
	}

	/**
	 * Return all the queued packets.
	 */
	Packet* getPackets()
	{
		Packet *msg;

		// Safely get all the messages
		synchronized (this) {
			msg = first;
			first = null;
			last = null;
		}

		return msg;
	}

	/**
	 * Pop all queued packets and call into the delegate.
	 */
	void popPackets(void delegate(ubyte *) dg)
	{
		Packet *msg, next;

		// Loop over all the messages
		for (msg = getPackets(); msg; msg = next) {
			next = msg.next;
			dg(msg.data);
			msg.cFree();
		}
	}

	/**
	 * Convinience function, should not be used from a dtor.
	 */
	void freePackets()
	{
		Packet *msg, next;

		// Loop over all the messages
		for (msg = getPackets(); msg; msg = next) {
			next = msg.next;
			msg.cFree();
		}
	}

	/**
	 * Since it is not safe to lock a class inside the GC use this
	 * function instead of freePackets in any dtors.
	 */
	void freePacketsUnsafe()
	{
		Packet *msg, next;

		msg = first;
		first = null;
		last = null;

		// Loop over all the messages
		for (msg = getPackets(); msg; msg = next) {
			next = msg.next;
			msg.cFree();
		}
	}

	/**
	 * Append a packet at the end of the message queue.
	 */
	void pushPacket(Packet *msg)
	{
		synchronized (this) {
			if (!first) {
				first = msg;
				last = msg;
			} else {
				last.next = msg;
				last = msg;
			}
		}
	}

	/**
	 * Allocate a packet.
	 */
	Packet* allocPacket(size_t len, ref ubyte[] data)
	{
		auto p = Packet.cAlloc(len);
		data = p.data[0 .. len];
		return p;
	}
}
