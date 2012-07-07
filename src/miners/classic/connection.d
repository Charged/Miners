// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.connection;

import std.socket;
import std.string;
private static import etc.c.zlib;
private import std.zlib : ZlibException;

import charge.charge;
import charge.util.memory;

import miners.types;
import miners.classic.proto;
import miners.classic.interfaces;
import miners.importer.network;


alias charge.net.util.ntoh ntoh;

/**
 * A threaded TCP connection to a server that handles protocol parsing. 
 */
class ClientConnection : public Connection
{
private:
	// Server details
	char[] hostname;
	ushort port;

	/// Username that was authenticated to mc.net
	char[] username;

	/// Verification recieved from mc.net
	char[] verificationKey;

	/// Stored data when receiving the level
	ubyte[] inData;

	/// Receiver of packages
	ClientListener l;

	/// Receiver of messages.
	ClientMessageListener ml;

	// For packet processing.
	size_t packetLength;
	size_t packetPos;
	ServerPacketUnion packets;

	/// The important stuff
	TcpSocket s;

public:
	this(ClientListener l, ClientMessageListener ml, ClassicServerInfo csi)
	{
		this.l = l;
		this.ml = ml;

		this.hostname = csi.hostname;
		this.port = csi.port;

		this.username = csi.username;
		this.verificationKey = csi.verificationKey;

		this.packetLength = size_t.max;
	}

	~this()
	{
	}

	void setListener(ClientListener l)
	{
		this.l = l;
	}

	void setMessageListener(ClientMessageListener ml)
	{
		this.ml = ml;
	}

	ClientMessageListener getMessageListener()
	{
		return ml;
	}

	/**
	 * Push all the packages to the listener.
	 */
	void doPackets()
	{
		if (s is null)
			if (!doConnect())
				return;

		while(eatPacket()) {}
	}

	void close()
	{
		if (s is null)
			return;

		s.shutdown(SocketShutdown.BOTH);
		s.close();
		s = null;
	}


	/*
	 *
	 * Client send functions.
	 *
	 */


	void sendClientIdentification(char[] name, char[] key)
	{
		ClientIdentification ci;

		ci.packetId = ci.constId;
		ci.protocolVersion = 0x07;
		ci.username[0 .. name.length] = name[0 .. $];
		ci.username[name.length .. $] = ' ';
		ci.verificationKey[0 .. key.length] = key[0 .. $];
		ci.verificationKey[key.length .. $] = ' ';
		ci.pad = 0;

		sendPacket!(ci)(s);
	}

	void sendClientSetBlock(short x, short y, short z, ubyte mode, ubyte type)
	{
		ClientSetBlock csb;

		csb.packetId = csb.constId;
		csb.x = ntoh(x);
		csb.y = ntoh(y);
		csb.z = ntoh(z);
		csb.mode = mode;
		csb.type = type;

		sendPacket!(csb)(s);
	}

	void sendClientPlayerUpdate(double x, double y, double z, double heading, double look)
	{
		ClientPlayerUpdatePosOri cpupo;

		ubyte yaw, pitch;

		toYawPitch(heading, look, yaw, pitch);

		cpupo.packetId = cpupo.constId;
		cpupo.playerId = -1;
		cpupo.x = ntoh(cast(short)(x * 32.0));
		cpupo.y = ntoh(cast(short)(y * 32.0));
		cpupo.z = ntoh(cast(short)(z * 32.0));
		cpupo.yaw = yaw;
		cpupo.pitch = pitch;

		sendPacket!(cpupo)(s);
	}

	void sendClientMessage(char[] msg)
	{
		ClientMessage cm;

		cm.packetId = cm.constId;
		cm.pad = 0xff;
		cm.message[0 .. msg.length] = msg;
		cm.message[msg.length .. $] = ' ';

		sendPacket!(cm)(s);
	}


protected:
	/*
	 *
	 * Protocol decoding functions.
	 *
	 */


	/**
	 * 0x00
	 */
	void serverIdentification(ServerIdentification *si)
	{
		ubyte ver = si.playerType;
		char[] name = removeTrailingSpaces(si.name);
		char[] motd = removeTrailingSpaces(si.motd);
		ubyte type = si.playerType;

		l.indentification(ver, name, motd, type);
	}

	/*
	 * Ping 0x01 and LevelIntialized 0x02 routed directly.
	 */

	/**
	 * 0x03
	 */
	void levelDataChunk(ServerLevelDataChunk *sldc)
	{
		short len = ntoh(sldc.length);

		if (len > sldc.data.length)
			throw new InvalidPacketException(sldc.packetId);

		inData ~= sldc.data[0 .. len];

		l.levelLoadUpdate(sldc.percent);
	}

	/**
	 * 0x04
	 */
	void levelFinalize(ServerLevelFinalize *slf)
	{
		// Get the level size
		short xSize = ntoh(slf.x);
		short ySize = ntoh(slf.y);
		short zSize = ntoh(slf.z);
		size_t size = uint.sizeof + xSize * ySize * zSize;


		// Need somewhere to store the uncompressed data
		auto ptr = cast(ubyte*)cMalloc(size);
		if (!ptr)
			throw new ZlibException(etc.c.zlib.Z_MEM_ERROR);
		scope(exit)
			cFree(ptr);
		ubyte[] decomp = ptr[0 .. size];

		// Used as arguments for zlib
		etc.c.zlib.z_stream zs;
		zs.next_in = inData.ptr;
		zs.avail_in = cast(uint)inData.length;
		zs.next_out = decomp.ptr;
		zs.avail_out = cast(uint)size;

		// Initialize zlib with argument struct
		int err = etc.c.zlib.inflateInit2(&zs, 15 + 16);
		if (err)
			throw new ZlibException(err);
		scope(exit)
			cast(void)etc.c.zlib.inflateEnd(&zs);

		// Do the decompressing
		err = etc.c.zlib.inflate(&zs, etc.c.zlib.Z_NO_FLUSH);
		switch (err) {
		case etc.c.zlib.Z_STREAM_END:
			// All ok!
			break;
		case etc.c.zlib.Z_DATA_ERROR:
			// Work around checksum errors
			if (zs.avail_out == 0 && zs.avail_in == 4)
				break;
			// Otherwise error!
		default:
			throw new ZlibException(err);
		}

		// No point in keeping the read data around
		delete inData;

		// Skip the size in the begining
		auto d = decomp[4 .. $];

		l.levelFinalize(xSize, ySize, zSize, d);
	}

	/**
	 * 0x06
	 */
	void setBlock(ServerSetBlock *ssb)
	{
		short x = ntoh(ssb.x);
		short y = ntoh(ssb.y);
		short z = ntoh(ssb.z);
		ubyte type = ssb.type;

		if (l !is null)
			l.setBlock(x, y, z, type);
	}

	/**
	 * 0x07
	 */
	void playerSpawn(ServerPlayerSpawn *sps)
	{
		auto id = sps.playerId;
		auto name = removeTrailingSpaces(sps.playerName);
		double x = cast(double)ntoh(sps.x) / 32.0;
		double y = cast(double)ntoh(sps.y) / 32.0;
		double z = cast(double)ntoh(sps.z) / 32.0;
		double heading, pitch;
		fromYawPitch(sps.yaw, sps.pitch, heading, pitch);

		if (l !is null)
			l.playerSpawn(id, name, x, y, z, heading, pitch);
		if (ml !is null)
			ml.addPlayer(id, name);
	}

	/**
	 * 0x08
	 */
	void playerTeleport(ServerPlayerTeleport *spt)
	{
		auto id = spt.playerId;
		double x = cast(double)ntoh(spt.x) / 32.0;
		double y = cast(double)ntoh(spt.y) / 32.0;
		double z = cast(double)ntoh(spt.z) / 32.0;
		double heading, pitch;
		fromYawPitch(spt.yaw, spt.pitch, heading, pitch);

		if (l !is null)
			l.playerMoveTo(id, x, y, z, heading, pitch);
	}

	/**
	 * 0x09
	 */
	void playerUpdatePosOri(ServerPlayerUpdatePosOri *spupo)
	{
		auto id = spupo.playerId;
		double x = spupo.x / 32.0;
		double y = spupo.y / 32.0;
		double z = spupo.z / 32.0;
		double heading, pitch;
		fromYawPitch(spupo.yaw, spupo.pitch, heading, pitch);

		if (l !is null)
			l.playerMove(id, x, y, z, heading, pitch);
	}

	/**
	 * 0x0a
	 */
	void playerUpdatePos(ServerPlayerUpdatePos *spup)
	{
		auto id = spup.playerId;
		double x = spup.x / 32.0;
		double y = spup.y / 32.0;
		double z = spup.z / 32.0;

		if (l !is null)
			l.playerMove(id, x, y, z);
	}

	/**
	 * 0x0b
	 */
	void playerUpdateOri(ServerPlayerUpdateOri *spuo)
	{
		auto id = spuo.playerId;
		double heading, pitch;
		fromYawPitch(spuo.yaw, spuo.pitch, heading, pitch);

		if (l !is null)
			l.playerMove(id, heading, pitch);
	}

	/**
	 * 0x0c
	 */
	void playerDespawn(ServerPlayerDespawn *spd)
	{
		auto id = spd.playerId;

		if (l !is null)
			l.playerDespawn(id);
		if (ml !is null)
			ml.removePlayer(id);
	}

	/**
	 * 0x0d
	 */
	void message(ServerMessage *sm)
	{
		byte player = sm.playerId;
		char[] msg = removeTrailingSpaces(sm.message);

		if (ml !is null)
			ml.archive(player, msg);
	}

	/**
	 * 0x0e
	 */
	void disconnect(ServerDisconnect *sd)
	{
		char[] reason = removeTrailingSpaces(sd.reason);

		l.disconnect(reason);
	}

	/**
	 * 0x0f
	 */
	void updateType(ServerUpdateType *sut)
	{
		ubyte type = sut.type;

		l.playerType(type);
	}

	void packet(ubyte *pkg)
	{
		switch(*pkg) {
		case 0x00:
			serverIdentification(&packets.identification);
			break;
		case 0x01:
			if (l !is null)
				l.ping();
			break;
		case 0x02:
			if (l !is null)
				l.levelInitialize();
			if (ml !is null)
				ml.removeAllPlayers();
			break;
		case 0x03:
			levelDataChunk(&packets.levelDataChunk);
			break;
		case 0x04:
			levelFinalize(&packets.levelFinalize);
			break;
		//se 0x05: // Ignore
		case 0x06:
			setBlock(&packets.setBlock);
			break;
		case 0x07:
			playerSpawn(&packets.playerSpawn);
			break;
		case 0x08:
			playerTeleport(&packets.playerTeleport);
			break;
		case 0x09:
			playerUpdatePosOri(&packets.playerUpdatePosOri);
			break;
		case 0x0a:
			playerUpdatePos(&packets.playerUpdatePos);
			break;
		case 0x0b:
			playerUpdateOri(&packets.playerUpdateOri);
			break;
		case 0x0c:
			playerDespawn(&packets.playerDespawn);
			break;
		case 0x0d:
			message(&packets.message);
			break;
		case 0x0e:
			disconnect(&packets.disconnect);
			break;
		case 0x0f:
			updateType(&packets.updateType);
			break;
		default: // Error 
			assert(false);
		}
	}


	/*
	 *
	 * Socket functions.
	 *
	 */


	/**
	 * Consume a single packet from the socket.
	 *
	 * Returns true if more data is available.
	 */
	bool eatPacket()
	{
		ubyte peek;
		int n;

		if (packetLength == size_t.max) {
			// Peek to see which packet it is
			n = s.receive((&peek)[0 .. 1], SocketFlags.PEEK);
			if (n <= 0) {
				if (s.isAlive)
					return false;
				else
					throw new Exception("connection failed");
			} else if (peek >= serverPacketSizes.length) {
				throw new InvalidPacketException(peek);
			}

			// Get the length of this packet type
			auto len = serverPacketSizes[peek];
			if (len == 0)
				throw new InvalidPacketException();

			packetLength = len;
			packetPos = 0;
		}

		// We should never get here without know the packet size.
		assert(packetLength != size_t.max);

		n = s.receive(packets.data[packetPos .. packetLength]);

		if (n <= 0) {
			if (s.isAlive)
				return false;
			else
				throw new Exception("connection failed");
		} else {
			packetPos += cast(size_t)n;
			if (packetPos != packetLength)
				return false;

			packet(packets.data.ptr);
			packetLength = size_t.max;
			packetPos = 0;
			return true;
		}
	}

	bool doConnect()
	{
		auto a = new InternetAddress(hostname, port);

		try {
			s = new TcpSocket(a);
			s.blocking = false;
			sendClientIdentification(username, verificationKey);
			return true;
		} catch (Exception e) {
			l.disconnect(e.toString);
			return false;
		}
	}
}

private class ConnectionException : public Exception
{
	this(char[] str)
	{
		char[] s = format("Connection error (%s)", str);
		super(s);
	}
}

private class InvalidPacketException : public Exception
{
	this()
	{
		super("Invalid packet length");
	}

	this(ubyte b)
	{
		char[] s = format("Invalid packet type (0x%02x)", b);
		super(s);
	}
}

private template sendPacket(alias T)
{
	void sendPacket(Socket s)
	{
		s.send((cast(ubyte*)&T)[0 .. typeof(T).sizeof]);
	}
}
