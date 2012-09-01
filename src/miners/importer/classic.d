// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.importer.classic;

import std.stdio;
import std.stream;
import std.mmfile;
import std.zlib;

import charge.util.zip;


void saveClassicTerrain(string file, uint x, uint y, uint z, ubyte *blocks)
{
	int size = x * y * z;

	auto comp = compress(cast(void[])blocks[0 .. size]);

	auto o = new File(file, FileMode.OutNew);

	o.write(cast(ubyte[])"CHRG MCSave v01\0");
	o.write(x);
	o.write(y);
	o.write(z);
	o.write(cast(uint)comp.length);
	o.write(cast(ubyte[])comp);
	o.flush();
	o.close();
}

ubyte[] loadClassicTerrain(string file, out uint x, out uint y, out uint z)
{
	auto mmap = new MmFile(file);
	int i;

	auto ptr = mmap[].ptr;
	if (mmap[].length <= 34)
		return null;

	char[16] str = cast(char[])ptr[0 .. 16];

	if (str[15] != 0)
		return null;

	ptr += 16;
	x = *cast(uint*)ptr;
	ptr += 4;
	y = *cast(uint*)ptr;
	ptr += 4;
	z = *cast(uint*)ptr;
	ptr += 4;
	uint size = *cast(uint*)ptr;
	ptr += 4;

	return cast(ubyte[])cUncompress(ptr[0 .. size], x * y * z);
}
