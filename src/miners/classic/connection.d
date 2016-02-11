// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.connection;

import std.socket : Socket, SocketFlags, SocketOption, SocketOptionLevel,
                    TcpSocket, SocketShutdown, InternetAddress;
import std.string : format;
import std.zlib : ZlibException;
import etc.c.zlib : z_stream, inflate, inflateInit2, inflateEnd,
                    Z_STREAM_END, Z_DATA_ERROR, Z_MEM_ERROR, Z_NO_FLUSH;

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
class ClassicConnection : ClassicClientConnection
{
public:
	// Track some per connection global state.

	// Mostly controls if we can delete Admin-crate.
	bool isAdmin;

	// Controls the admin flag.
	ubyte playerType;


private:
	mixin SysLogging;

	// Server details
	string hostname;
	ushort port;

	/// Username that was authenticated to mc.net
	string username;

	/// Verification recieved from mc.net
	string verificationKey;

	/// Stored data when receiving the level
	ubyte[] inData;

	/// Receiver of packages
	ClassicClientListener cl;

	/// Receiver of messages.
	ClassicClientMessageListener ml;

	// For packet processing.
	size_t packetLength;
	size_t packetPos;
	ServerPacketUnion packets;

	/// The important stuff
	TcpSocket s;

public:
	this(ClassicClientListener cl, ClassicClientMessageListener ml, ClassicServerInfo csi)
	{
		this.cl = cl;
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

	void setListener(ClassicClientListener l)
	{
		this.cl = l;
	}

	void setMessageListener(ClassicClientMessageListener ml)
	{
		this.ml = ml;
	}

	ClassicClientMessageListener getMessageListener()
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

	void setPlayerType(ubyte type)
	{
		playerType = type;
		isAdmin = type >= 100;
	}


	/*
	 *
	 * Client send functions.
	 *
	 */


	void sendClientIdentification(string name, string key)
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

	void sendClientMessage(string msg)
	{
		ClientMessage cm;

		cm.packetId = cm.constId;
		cm.pad = 0xff;
		cm.message[0 .. msg.length] = msg;
		cm.message[msg.length .. $] = ' ';

		sendPacket!(cm)(s);
	}

	void sendPing()
	{
		ubyte b = 0x01;
		s.send((&b)[0 .. 1]);
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
		ubyte ver = si.protocolVersion;
		string name = removeTrailingSpaces(si.name);
		string motd = removeTrailingSpaces(si.motd);
		ubyte type = si.playerType;

		setPlayerType(type);

		cl.indentification(ver, name, motd, type);
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

		cl.levelLoadUpdate(sldc.percent);
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
			throw new ZlibException(Z_MEM_ERROR);
		scope(exit)
			cFree(ptr);
		ubyte[] decomp = ptr[0 .. size];

		// Used as arguments for zlib
		z_stream zs;
		zs.next_in = inData.ptr;
		zs.avail_in = cast(uint)inData.length;
		zs.next_out = decomp.ptr;
		zs.avail_out = cast(uint)size;

		// Initialize zlib with argument struct
		int err = inflateInit2(&zs, 15 + 16);
		if (err)
			throw new ZlibException(err);
		scope(exit)
			cast(void)inflateEnd(&zs);

		// Do the decompressing
		err = inflate(&zs, Z_NO_FLUSH);
		switch (err) {
		case Z_STREAM_END:
			// All ok!
			break;
		case Z_DATA_ERROR:
			// Work around checksum errors
			if (zs.avail_out == 0 && zs.avail_in == 4)
				break;
			// Otherwise error!
			goto default;
		default:
			throw new ZlibException(err);
		}

		// No point in keeping the read data around
		delete inData;

		// Skip the size in the begining
		auto d = decomp[4 .. $];

		cl.levelFinalize(xSize, ySize, zSize, d);
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

		if (cl !is null)
			cl.setBlock(x, y, z, type);
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

		if (cl !is null)
			cl.playerSpawn(id, name, x, y, z, heading, pitch);
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

		if (cl !is null)
			cl.playerMoveTo(id, x, y, z, heading, pitch);
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

		if (cl !is null)
			cl.playerMove(id, x, y, z, heading, pitch);
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

		if (cl !is null)
			cl.playerMove(id, x, y, z);
	}

	/**
	 * 0x0b
	 */
	void playerUpdateOri(ServerPlayerUpdateOri *spuo)
	{
		auto id = spuo.playerId;
		double heading, pitch;
		fromYawPitch(spuo.yaw, spuo.pitch, heading, pitch);

		if (cl !is null)
			cl.playerMove(id, heading, pitch);
	}

	/**
	 * 0x0c
	 */
	void playerDespawn(ServerPlayerDespawn *spd)
	{
		auto id = spd.playerId;

		if (cl !is null)
			cl.playerDespawn(id);
		if (ml !is null)
			ml.removePlayer(id);
	}

	/**
	 * 0x0d
	 */
	void message(ServerMessage *sm)
	{
		byte player = sm.playerId;
		string msg = removeTrailingSpaces(sm.message);

		if (ml !is null)
			ml.archive(player, msg);
	}

	/**
	 * 0x0e
	 */
	void disconnect(ServerDisconnect *sd)
	{
		string reason = removeTrailingSpaces(sd.reason);

		cl.disconnect(reason);
	}

	/**
	 * 0x0f
	 */
	void updateType(ServerUpdateType *sut)
	{
		ubyte type = sut.type;

		setPlayerType(type);

		cl.playerType(type);
	}

	void packet(ubyte *pkg)
	{
		switch(*pkg) {
		case ServerIdentification.constId:
			serverIdentification(&packets.identification);
			break;
		case ServerPing.constId:
			if (cl !is null)
				cl.ping();
			break;
		case ServerLevelInitialize.constId:
			if (cl !is null)
				cl.levelInitialize();
			if (ml !is null)
				ml.removeAllPlayers();
			break;
		case ServerLevelDataChunk.constId:
			levelDataChunk(&packets.levelDataChunk);
			break;
		case ServerLevelFinalize.constId:
			levelFinalize(&packets.levelFinalize);
			break;
		case ServerSetBlock.constId:
			setBlock(&packets.setBlock);
			break;
		case ServerPlayerSpawn.constId:
			playerSpawn(&packets.playerSpawn);
			break;
		case ServerPlayerTeleport.constId:
			playerTeleport(&packets.playerTeleport);
			break;
		case ServerPlayerUpdatePosOri.constId:
			playerUpdatePosOri(&packets.playerUpdatePosOri);
			break;
		case ServerPlayerUpdatePos.constId:
			playerUpdatePos(&packets.playerUpdatePos);
			break;
		case ServerPlayerUpdateOri.constId:
			playerUpdateOri(&packets.playerUpdateOri);
			break;
		case ServerPlayerDespawn.constId:
			playerDespawn(&packets.playerDespawn);
			break;
		case ServerMessage.constId:
			message(&packets.message);
			break;
		case ServerDisconnect.constId:
			disconnect(&packets.disconnect);
			break;
		case ServerUpdateType.constId:
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
		ptrdiff_t n;

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
			s.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
			sendClientIdentification(username, verificationKey);
			return true;
		} catch (Exception e) {
			cl.disconnect(e.toString);
			return false;
		}
	}
}

private class ConnectionException : Exception
{
	this(string str)
	{
		string s = format("Connection error (%s)", str);
		super(s);
	}
}

private class InvalidPacketException : Exception
{
	this()
	{
		super("Invalid packet length");
	}

	this(ubyte b)
	{
		string s = format("Invalid packet type (0x%02x)", b);
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
