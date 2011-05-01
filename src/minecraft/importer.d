// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.importer;

import std.math;
import std.string;
import std.stream;
import charge.util.base36;
import lib.nbt.nbt;

char[] getChunkName(char[] dir, int x, int z)
{
	struct Position {
		union {
			uint pos;
			struct {
				ubyte pad;
				ubyte b3;
				ubyte b2;
				ubyte b1;
			}
		}
		ubyte size;
	}
	Position p;

	auto region = format("r.%s.%s.mcr",
			     encode(cast(uint)floor(x/32.0)),
			     encode(cast(uint)floor(z/32.0)));
	int hX = x % 32;
	int hZ = z % 32;
	hX = hX < 0 ? 32 + hX : hX;
	hZ = hZ < 0 ? 32 + hZ : hZ;

	int hoffset = 4 * (hX + hZ * 32);

	auto f = new BufferedFile(format("%s/region/%s", dir, region));
	f.seek(hoffset, SeekPos.Set);
	f.read(p.b1);
	f.read(p.b2);
	f.read(p.b3);
	f.read(p.size);
	f.close();

	std.stdio.writefln("(% 3s, % 3s), @%04s (%s) @%08s %sPages", x, z, hoffset, region, p.pos, p.size);

	auto ret = format("%s/%s/%s/c.%s.%s.dat", dir,
			  encode(cast(uint)x % 64),
			  encode(cast(uint)z % 64),
			  encode(x), encode(z));
	return ret;
}

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

ubyte* getBlocksFromFile(char[] filename)
{
	nbt_node *file;


	file = nbt_parse_path(toStringz(filename));
	if (!file)
		return null;

	scope(exit)
		nbt_free(file);

	ubyte *blocks;
	ubyte *data;
	if (!getBlocksFromNode(file, blocks, data))
		return null;
	
	std.c.stdlib.free(data);
	return blocks;
}


bool getBlocksForChunk(char[] dir, int x, int z, out ubyte *blocks, out ubyte *data)
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

	//std.stdio.writefln("(% 3s, % 3s), (% 3s, % 3s), @% 5s @% 16s %s KiB (%s)" , x, z, hX, hZ, headerOffset, chunkOffset, (chunkSize)/1024, region);

	return getBlocksFromNode(tree, blocks, data);
}
