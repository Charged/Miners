// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.importer.folders;

import std.math;
import std.string;

import charge.util.base36;
import charge.platform.homefolder;

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
 * Return the region filename for a Beta chunk.
 */
char[] getBetaRegionName(char[] dir, int x, int z)
{
	return format("%s/region/r.%s.%s.mcr", dir,
		      encode(cast(uint)floor(x/32.0)),
		      encode(cast(uint)floor(z/32.0)));
}
