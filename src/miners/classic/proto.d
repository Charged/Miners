// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.proto;


uint clientPacketSizes[16+16+2] = [
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
	0,                               // 0x0e
	0,                               // 0x0f

	0, 0, 0, 0,  0, 0, 0, 0,         // 0x10 - 0x17
	0, 0, 0, 0,  0, 0, 0, 0,         // 0x17 - 0x1f

	ExtInfo.sizeof,                  // 0x20
	ExtEntry.sizeof                  // 0x21
];

uint serverPacketSizes[16+16+2] = [
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

	0, 0, 0, 0,  0, 0, 0, 0,         // 0x10 - 0x17
	0, 0, 0, 0,  0, 0, 0, 0,         // 0x17 - 0x1f

	ExtInfo.sizeof,                  // 0x20
	ExtEntry.sizeof                  // 0x21
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
	ExtInfo                  extInfo;            // 0x10
	ExtEntry                 extEntry;           // 0x11
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
	const constId = 0x00;

	ubyte packetId;
	ubyte protocolVersion;
	char[64] username;
	char[64] verificationKey;
	ubyte pad;
}

struct ClientSetBlock
{
	const constId = 0x05;

	ubyte packetId;
	short x;
	short y;
	short z;
	ubyte mode;
	ubyte type;
}

struct ClientPlayerUpdatePosOri
{
	const constId = 0x08;

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
	const constId = 0x0d;

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
	const constId = 0x00;

	ubyte packetId;
	ubyte protocolVersion;
	char[64] name;
	char[64] motd;
	ubyte playerType;
}

struct ServerPing
{
	const constId = 0x01;

	ubyte packetId;
}

struct ServerLevelInitialize
{
	const constId = 0x02;

	ubyte packetId;
}

struct ServerLevelDataChunk
{
	const constId = 0x03;

	ubyte packetId;
	short length;
	ubyte[1024] data;
	ubyte percent;
}

struct ServerLevelFinalize
{
	const constId = 0x04;

	ubyte packetId;
	short x;
	short y;
	short z;
}

struct ServerSetBlock
{
	const constId = 0x06;

	ubyte packetId;
	short x;
	short y;
	short z;
	ubyte type;
}

struct ServerPlayerSpawn
{
	const constId = 0x07;

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
	const constId = 0x08;

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
	const constId = 0x09;

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
	const constId = 0x0a;

	ubyte packetId;
	byte playerId;
	byte x;
	byte y;
	byte z;
}

struct ServerPlayerUpdateOri
{
	const constId = 0x0b;

	ubyte packetId;
	byte playerId;
	ubyte yaw;
	ubyte pitch;
}

struct ServerPlayerDespawn
{
	const constId = 0x0c;

	ubyte packetId;
	byte playerId;
}

struct ServerMessage
{
	const constId = 0x0d;

	ubyte packetId;
	byte playerId;
	char[64] message;
}

struct ServerDisconnect
{
	const constId = 0x0e;

	ubyte packetId;
	char[64] reason;
}

struct ServerUpdateType
{
	const constId = 0x0f;

	ubyte packetId;
	ubyte type;
}

struct ExtInfo
{
	const constId = 0x20;

	ubyte packetId;
	char[64] name;
	int numExts;
}

struct ExtEntry
{
	const constId = 0x21;

	ubyte packetId;
	char[64] name;
	int ver;
}
