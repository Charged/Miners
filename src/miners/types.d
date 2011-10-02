// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.types;


/**
 * Used to control which mesh type that the terrain build.
 */
enum TerrainBuildTypes {
	RigidMesh,
	CompactMesh,
}


/**
 * Struct to hold information about a block.
 */
struct Block
{
	ubyte type;        /**< [0 - 255] */
	ubyte meta;        /**< [0 - 16] Mening is dependant on type */
	ubyte sunlight;    /**< [0 - 16] */
	ubyte torchlight;  /**< [0 - 16] */
}


/**
 * Information needed to connect to a classic server.
 */
class ClassicServerInfo
{
	char[] webName; /**< Name as given by the webpage. */
	char[] webId; /**< Id on the webpage */

	char[] hostname; /**< Hostname to connect to */
	ushort port; /**< Port number to connect to */
	char[] username; /**< Username used in slat */
	char[] verificationKey; /**< Retrived from webpage */
}
