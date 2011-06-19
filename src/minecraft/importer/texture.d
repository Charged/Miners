// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.importer.importer;

import std.mmfile;
import charge.util.zip;
import minecraft.importer.folders;

/**
 * Locate minecraft.jar and extract terrain.png.
 *
 * Returns the terrain.png file a C allocated array.
 */
void[] extractMinecraftTexture(char[] dir = null)
{
	if (dir is null)
		dir = getMinecraftFolder();

	auto file = dir ~ "/bin/minecraft.jar";
	void[] data;

	auto mmap = new MmFile(file);
	data = cUncompressFromFile(mmap[], "terrain.png");
	delete mmap;

	return data;
}
