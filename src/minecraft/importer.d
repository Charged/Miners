// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.importer;

import std.math;
import std.file;
import std.string;
import std.stream;

import charge.math.point3d;
import charge.util.base36;
import charge.util.vector;
import charge.platform.homefolder;

import lib.nbt.nbt;

/**
 * Return the folder where the Minecraft config, saves & texture packs lives.
 */
char[] getMinecraftFolder()
{
	// The minecraft config folder move around a bit.
	version(linux) {
		char[] mcFolder = homeFolder ~ "/.minecraft";
	} else version (darwin) {
		char[] mcFolder = applicationConfigFolder ~ "/minecraft";
	} else version (Windows) {
		char[] mcFolder = applicationConfigFolder ~ "/.minecraft";
	} else {
		static assert(false);
	}

	return mcFolder;
}

/**
 * Returns the save folder for Minecraft.
 */
char[] getMinecraftSaveFolder(char[] dir = null)
{
	if (dir is null)
		dir = getMinecraftFolder();

	return format("%s/saves", dir);
}

/**
 * Holds information about a single minecraft level.
 */
struct MinecraftLevelInfo
{
	char[] name;   /**< Level name */
	char[] dir;    /**< Directory holding this level */
	bool beta;     /**< Is this level a beta level */
	bool nether;   /**< Does this level have a nether directory */
	Point3d spawn; /**< Spawn point */
}

/**
 * Gets information from a level.dat.
 */
bool getInfoFromLevelDat(char[] level, out char[] name, out Point3d spawn)
{
	auto dat = format(level, "/level.dat\0");
	nbt_node *data;
	nbt_node *levelName;
	nbt_node *spwn;

	auto file = nbt_parse_path(dat.ptr);
	if (!file)
		return false;
	scope(exit)
		nbt_free(file);

	data = nbt_find_by_name(file, "Data");
	if (!data)
		return false;

	levelName = nbt_find_by_name(data, "LevelName");
	if (levelName && levelName.type == TAG_STRING)
		name = toString(levelName.tag_string).dup; // Need to dup

	spawn = Point3d(0, 64, 0);
	foreach(int i, n; ["SpawnX", "SpawnY", "SpawnZ"]) {
		spwn = nbt_find_by_name(data, n.ptr);
		if (!spwn || spwn.type != TAG_INT)
			continue;

		(&spawn.x)[i] = spwn.tag_int;
	}

	return true;
}

/**
 * Checks a Minecraft level.
 *
 * Returns null if no level.dat was found inside the directory.
 */
MinecraftLevelInfo* checkMinecraftLevel(char[] level)
{
	auto region = format(level, "/region");
	auto nether = format(level, "/DIM-1");
	char[] name;
	Point3d spawn;

	if (!getInfoFromLevelDat(level, name, spawn))
		return null;

	auto li = new MinecraftLevelInfo();

	li.name = name;
	li.dir = level;
	li.spawn = spawn;

	if (exists(region))
		li.beta = true;

	if (exists(nether))
		li.nether = true;

	return li;
}

/**
 * Scan a directory for Minecraft worlds.
 *
 * If null or no argument given scans the guesstimated Minecraft save folder.
 *
 * Returns a array of MinecraftLevelInfo's.
 */
MinecraftLevelInfo[] scanForLevels(char[] dir = null)
{
	VectorData!(MinecraftLevelInfo) levels;

	// If no directory given guesstimate the Minecraft save folder.
	if (dir is null)
		dir = getMinecraftSaveFolder();

	// Called for each file/directory found in directory
	bool cb(DirEntry *de) {

		// Early out any files that are in the save directory
		if (!de.isdir)
			return true;

		// Check if the level is okay
		auto li = checkMinecraftLevel(de.name);
		if (li is null)
			return true;

		levels ~= *li;
		return true;
	}

	listdir(dir, &cb);

	return levels.adup;
}

/**
 * Return the file name for a Alpha chunk.
 */
char[] getAlphaChunkName(char[] dir, int x, int z)
{
	auto ret = format("%s/%s/%s/c.%s.%s.dat", dir,
			  encode(cast(uint)x % 64),
			  encode(cast(uint)z % 64),
			  encode(x), encode(z));
	return ret;
}

/**
 * Extract the blocks and metadata from a NBT node.
 *
 * Tested with Beta, should work with Alpha.
 */
bool getBlocksFromNode(nbt_node *file, out ubyte *blocks_out, out ubyte *data_out)
{
	nbt_node *level;
	nbt_node *blocks;
	nbt_node *data;

	level = nbt_find_by_name(file, "Level");
	if (!level)
		goto err;

	data = nbt_find_by_name(level, "Data");
	blocks = nbt_find_by_name(level, "Blocks");

	if (!data || data.type != TAG_BYTE_ARRAY)
		goto err;

	if (!blocks || blocks.type != TAG_BYTE_ARRAY)
		goto err;

	assert(blocks.tag_byte_array.length == 32768);
	assert(data.tag_byte_array.length == 32768/2);

	// Steal the data, HACK but it works
	blocks_out = blocks.tag_byte_array.data;
	blocks.tag_byte_array.data = null;
	blocks.tag_byte_array.length = 0;

	data_out = data.tag_byte_array.data;
	data.tag_byte_array.data = null;
	data.tag_byte_array.length = 0;

	return true;

err:
	std.c.stdlib.free(blocks_out);
	std.c.stdlib.free(data_out);
	blocks_out = null;
	data_out = null;
	return false;
}

/**
 * Gets the blocks from a alpha chunk at (x, z).
 */
bool getAlphaBlocksForChunk(char[] dir, int x, int z,
			      out ubyte *blocks, out ubyte *data)
{
	nbt_node *file;
	auto filename = getAlphaChunkName(dir, x, z);

	file = nbt_parse_path(toStringz(filename));
	if (!file)
		return false;

	scope(exit)
		nbt_free(file);

	return getBlocksFromNode(file, blocks, data);
}

/**
 * Gets the blocks and data from a beta level directory from chunk at (x, z).
 */
bool getBetaBlocksForChunk(char[] dir, int x, int z,
			   out ubyte *blocks, out ubyte *data)
{
	auto region = format("%s/region/r.%s.%s.mcr", dir,
			     encode(cast(uint)floor(x/32.0)),
			     encode(cast(uint)floor(z/32.0)));
	int hX = x % 32;
	int hZ = z % 32;
	hX = hX < 0 ? 32 + hX : hX;
	hZ = hZ < 0 ? 32 + hZ : hZ;

	int headerOffset = 4 * (hX + hZ * 32);
	ubyte headerData[4];

	uint chunkSize;
	uint chunkExactSize;
	uint chunkOffset;
	ubyte chunkData[];

	BufferedFile f;

	try {
		f = new BufferedFile(region);
	} catch(Exception e) {
		return false;
	}

	scope(exit)
		f.close();

	// Seek and read 4 bytes
	f.seek(headerOffset, SeekPos.Set);
	f.read(headerData);

	chunkOffset = (headerData[2] | headerData[1] << 8 | headerData[0] << 16) * 4096;
	chunkSize = headerData[3] * 4096;

	if (chunkSize == 0)
		return false;

	// Alloc data
	chunkData.length = chunkSize;

	// Seek and read chunkSize bytes
	f.seek(chunkOffset, SeekPos.Set);
	f.read(chunkData);

	chunkExactSize = chunkData[3] | chunkData[2] << 8 | chunkData[1] << 16 | chunkData[0] << 24;
	assert(chunkExactSize <= chunkSize);

	// Parse the data
	auto tree = nbt_parse_compressed(chunkData.ptr+5, chunkExactSize-1);
	scope(exit)
		nbt_free(tree);

	return getBlocksFromNode(tree, blocks, data);
}
