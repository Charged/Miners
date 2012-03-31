// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.importer.blocks;

import std.math;
import std.file;
import std.string;
import std.stream;
import std.mmfile;

import charge.util.zip;
import charge.util.memory;
import charge.util.base36;

import lib.nbt.nbt;

import miners.importer.folders;


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
	auto region = getBetaRegionName(dir, x, z);
	int hX = x % 32;
	int hZ = z % 32;
	hX = hX < 0 ? 32 + hX : hX;
	hZ = hZ < 0 ? 32 + hZ : hZ;

	int headerOffset = 4 * (hX + hZ * 32);
	ubyte headerData[4];

	uint chunkSize;
	uint chunkExactSize;
	uint chunkOffset;
	cMemoryArray!(ubyte) chunkData;
	scope(exit)
		chunkData.free();

	File f;

	try {
		f = new File(region);
	} catch(Exception e) {
		return false;
	}

	scope(exit) {
		f.close();
		delete f;
	}

	// Seek and read 4 bytes
	f.seek(headerOffset, SeekPos.Set);
	f.readExact(headerData.ptr, headerData.length);

	chunkOffset = (headerData[2] | headerData[1] << 8 | headerData[0] << 16) * 4096;
	chunkSize = headerData[3] * 4096;

	if (chunkSize == 0)
		return false;

	// Alloc data
	chunkData.length = chunkSize;

	// Seek and read chunkSize bytes
	f.seek(chunkOffset, SeekPos.Set);
	f.readExact(chunkData.ptr, chunkData.length);

	chunkExactSize = chunkData[3] | chunkData[2] << 8 | chunkData[1] << 16 | chunkData[0] << 24;
	assert(chunkExactSize <= chunkSize);

	// Parse the data
	auto tree = nbt_parse_compressed(chunkData.ptr+5, chunkExactSize-1);
	scope(exit)
		nbt_free(tree);

	return getBlocksFromNode(tree, blocks, data);
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
	// These should be stdlib.free
	std.c.stdlib.free(blocks_out);
	std.c.stdlib.free(data_out);
	blocks_out = null;
	data_out = null;
	return false;
}
