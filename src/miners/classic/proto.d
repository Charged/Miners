// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.proto;


uint[16] clientPacketSizes = [
	ClientIdentification.sizeof,     // 0x00
	0,                               // 0x01
	0,                               // 0x02
	0,                               // 0x03
	0,                               // 0x04
	ClientSetBlock.sizeof,           // 0x05
	0,                               // 0x06
	0,                               // 0x07
	ClientPlayerUpdatePosOri.sizeof, // 0x08
	0,                               // 0x09
	0,                               // 0x0a
	0,                               // 0x0b
	0,                               // 0x0c
	ClientMessage.sizeof,            // 0x0d
	0,                               // 0x0f
];

uint[16] serverPacketSizes = [
	ServerIdentification.sizeof,     // 0x00
	ServerPing.sizeof,               // 0x01
	ServerLevelInitialize.sizeof,    // 0x02
	ServerLevelDataChunk.sizeof,     // 0x03
	ServerLevelFinalize.sizeof,      // 0x04
	0,                               // 0x05
	ServerSetBlock.sizeof,           // 0x06
	ServerPlayerSpawn.sizeof,        // 0x07
	ServerPlayerTeleport.sizeof,     // 0x08
	ServerPlayerUpdatePosOri.sizeof, // 0x09
	ServerPlayerUpdatePos.sizeof,    // 0x0a
	ServerPlayerUpdateOri.sizeof,    // 0x0b
	ServerPlayerDespawn.sizeof,      // 0x0c
	ServerMessage.sizeof,            // 0x0d
	ServerDisconnect.sizeof,         // 0x0e
	ServerUpdateType.sizeof,         // 0x0f
];


align(1): // setup correct alignment for packets


/**
 * All server packets in easy to access union.
 */
union ServerPacketUnion {
	ServerIdentification     identification;     // 0x00
	ServerPing               ping;               // 0x01
	ServerLevelInitialize    levelInitialize;    // 0x02
	ServerLevelDataChunk     levelDataChunk;     // 0x03
	ServerLevelFinalize      levelFinalize;      // 0x04
	//                                           // 0x05
	ServerSetBlock           setBlock;           // 0x06
	ServerPlayerSpawn        playerSpawn;        // 0x07
	ServerPlayerTeleport     playerTeleport;     // 0x08
	ServerPlayerUpdatePosOri playerUpdatePosOri; // 0x09
	ServerPlayerUpdatePos    playerUpdatePos;    // 0x0a
	ServerPlayerUpdateOri    playerUpdateOri;    // 0x0b
	ServerPlayerDespawn      playerDespawn;      // 0x0c
	ServerMessage            message;            // 0x0d
	ServerDisconnect         disconnect;         // 0x0e
	ServerUpdateType         updateType;         // 0x0f
	ubyte[ServerLevelDataChunk.sizeof] data;
}

static assert(ServerPacketUnion.sizeof == ServerPacketUnion.data.length);



/*
 *
 * Client to server packets
 *
 */


struct ClientIdentification
{
	enum ubyte constId = cast(ubyte)0x00;

align(1):
	ubyte packetId;
	ubyte protocolVersion;
	char[64] username;
	char[64] verificationKey;
	ubyte pad;
}

struct ClientSetBlock
{
	enum ubyte constId = cast(ubyte)0x05;

align(1):
	ubyte packetId;
	short x;
	short y;
	short z;
	ubyte mode;
	ubyte type;
}

struct ClientPlayerUpdatePosOri
{
	enum ubyte constId = cast(ubyte)0x08;

align(1):
	ubyte packetId;
	byte playerId; // Allways 255
	short x;
	short y;
	short z;
	ubyte yaw;
	ubyte pitch;
}

struct ClientMessage
{
	enum ubyte constId = cast(ubyte)0x0d;

align(1):
	ubyte packetId;
	ubyte pad;
	char[64] message;
}


/*
 *
 * Server to client packages
 *
 */


struct ServerIdentification
{
	enum ubyte constId = cast(ubyte)0x00;

align(1):
	ubyte packetId;
	ubyte protocolVersion;
	char[64] name;
	char[64] motd;
	ubyte playerType;
}

struct ServerPing
{
	enum ubyte constId = cast(ubyte)0x01;

align(1):
	ubyte packetId;
}

struct ServerLevelInitialize
{
	enum ubyte constId = cast(ubyte)0x02;

align(1):
	ubyte packetId;
}

struct ServerLevelDataChunk
{
	enum ubyte constId = cast(ubyte)0x03;

align(1):
	ubyte packetId;
	short length;
	ubyte[1024] data;
	ubyte percent;
}

struct ServerLevelFinalize
{
	enum ubyte constId = cast(ubyte)0x04;

align(1):
	ubyte packetId;
	short x;
	short y;
	short z;
}

struct ServerSetBlock
{
	enum ubyte constId = cast(ubyte)0x06;

align(1):
	ubyte packetId;
	short x;
	short y;
	short z;
	ubyte type;
}

struct ServerPlayerSpawn
{
	enum ubyte constId = cast(ubyte)0x07;

align(1):
	ubyte packetId;
	byte playerId;
	char[64] playerName;
	short x;
	short y;
	short z;
	ubyte yaw;
	ubyte pitch;
}

struct ServerPlayerTeleport
{
	enum ubyte constId = cast(ubyte)0x08;

align(1):
	ubyte packetId;
	byte playerId;
	short x;
	short y;
	short z;
	ubyte yaw;
	ubyte pitch;
}

struct ServerPlayerUpdatePosOri
{
	enum ubyte constId = cast(ubyte)0x09;

align(1):
	ubyte packetId;
	byte playerId;
	byte x;
	byte y;
	byte z;
	ubyte yaw;
	ubyte pitch;
}

struct ServerPlayerUpdatePos
{
	enum ubyte constId = cast(ubyte)0x0a;

align(1):
	ubyte packetId;
	byte playerId;
	byte x;
	byte y;
	byte z;
}

struct ServerPlayerUpdateOri
{
	enum ubyte constId = cast(ubyte)0x0b;

align(1):
	ubyte packetId;
	byte playerId;
	ubyte yaw;
	ubyte pitch;
}

struct ServerPlayerDespawn
{
	enum ubyte constId = cast(ubyte)0x0c;

align(1):
	ubyte packetId;
	byte playerId;
}

struct ServerMessage
{
	enum ubyte constId = cast(ubyte)0x0d;

align(1):
	ubyte packetId;
	byte playerId;
	char[64] message;
}

struct ServerDisconnect
{
	enum ubyte constId = cast(ubyte)0x0e;

align(1):
	ubyte packetId;
	char[64] reason;
}

struct ServerUpdateType
{
	enum ubyte constId = cast(ubyte)0x0f;

align(1):
	ubyte packetId;
	ubyte type;
}
