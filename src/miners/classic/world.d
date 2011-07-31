// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.world;

import charge.charge;

import miners.world;
import miners.options;
import miners.terrain.finite;
import miners.importer.classic;
import miners.importer.converter;


/**
 * A world containing a classic level.
 */
class ClassicWorld : public World
{
private:
	mixin SysLogging;

	FiniteTerrain ft;

public:
	this(Options opts)
	{
		this.spawn = Point3d(64, 67, 64);

		super(opts);

		// Create initial terrain
		newLevel(128, 128, 128);

		// Set the level with some sort of valid data
		generateLevel(ft);
	}

	this(Options opts, char[] filename)
	{
		this.spawn = Point3d(64, 67, 64);

		super(opts);

		uint x, y, z;
		auto b = loadClassicTerrain(filename, x, y, z);
		if (b is null)
			throw new Exception("Failed to load level");
		scope (exit)
			std.c.stdlib.free(b.ptr);

		// Setup the terrain from the data.
		newLevelFromClassic(x, y, z, b[0 .. x * y * z]);
	}

	~this()
	{
		// Incase super class decieded to deleted t
		if (t is null)
			ft = null;

		delete ft;
		t = ft = null;
	}

	/**
	 * Change the current level
	 */
	void newLevel(uint x, uint y, uint z)
	{
		delete ft;
		t = ft = null;

		t = ft = new FiniteTerrain(this, opts, x, y, z);
	}

	/**
	 * Replace the current level with one from classic data.
	 *
	 * Flips and convert the data.
	 */
	void newLevelFromClassic(uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		auto ySrcStride = zSize * xSize;

		newLevel(xSize, ySize, zSize);

		// Get the pointer directly to the data
		auto p = ft.getTypePointerUnsafe(0, 0, 0);
		auto pm = ft.getMetaPointerUnsafe(0, 0, 0);

		// Flip & convert the world
		for (int z; z < zSize; z++) {
			for (int x; x < xSize; x++) {
				auto src = &data[(zSize*0 + z) * xSize + x];

				for (int y; y < ySize; y++) {
					ubyte block, meta;
					convertClassicToBeta(*src, block, meta);

					*p = block;
					*pm |= meta << (4 * (y % 2));

					p += 1;
					pm += y % 2;
					src += ySrcStride;
				}

				// If height is uneaven we need to increment this.
				pm += ySize % 2;
			}
		}
	}

	/**
	 * "Generate" a level.
	 */
	void generateLevel(FiniteTerrain ct)
	{
		for (int x; x < ct.xSize; x++) {
			for (int z; z < ct.zSize; z++) {
				ct[x, 0, z] =  7;
				for (int y = 1; y < ct.ySize; y++) {
					if (y < 64)
						ct[x, y, z] = 1;
					else if (y == 64)
						ct[x, y, z] = 3;
					else if (y == 65)
						ct[x, y, z] = 3;
					else if (y == 66)
						ct[x, y, z] = 2;
					else
						ct[x, y, z] = 0;
				}
			}
		}
	}
}
