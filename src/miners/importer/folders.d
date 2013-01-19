// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.importer.folders;

import std.math : floor;
import std.string : format;

import charge.util.base36;
import charge.platform.homefolder;


/**
 * Return the folder where the Minecraft config, saves & texture packs lives.
 */
string getMinecraftFolder()
{
	// The minecraft config folder move around a bit.
	version(linux) {
		string mcFolder = homeFolder ~ "/.minecraft";
	} else version (darwin) {
		string mcFolder = applicationConfigFolder ~ "/minecraft";
	} else version (Windows) {
		string mcFolder = applicationConfigFolder ~ "/.minecraft";
	} else {
		static assert(false);
	}

	return mcFolder;
}

/**
 * Returns the save folder for Minecraft.
 */
string getMinecraftSaveFolder(string dir = null)
{
	if (dir is null)
		dir = getMinecraftFolder();

	return dir ~ "/saves";
}

/**
 * Returns the bin folder for Minecraft.
 */
string getMinecraftBinFolder(string dir = null)
{
	if (dir is null)
		dir = getMinecraftFolder();

	return dir ~ "/bin";
}

/**
 * Returns the bin folder for Minecraft.
 */
string getMinecraftJarFilePath(string dir = null)
{
	if (dir is null)
		dir = getMinecraftBinFolder();

	return dir ~ "/minecraft.jar";
}

/**
 * Return the file name for a Alpha chunk.
 */
string getAlphaChunkName(string dir, int x, int z)
{
	uint px = cast(uint)x % 64;
	uint pz = cast(uint)z % 64;

	auto ret = format("%s/%s/%s/c.%s.%s.dat", dir,
			  encode(px), encode(pz),
			  encode(x), encode(z));
	return ret;
}

/**
 * Return the region filename for a Beta chunk.
 */
string getBetaRegionName(string dir, int x, int z)
{
	int px = cast(int)floor(x/32.0);
	int pz = cast(int)floor(z/32.0);

	return format("%s/region/r.%s.%s.mcr", dir,
		      encode(px), encode(pz));
}
