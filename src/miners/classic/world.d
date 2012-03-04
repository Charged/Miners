// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.world;

import charge.charge;
import charge.util.memory;

import miners.types;
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
		scope(exit)
			cFree(b.ptr);

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

		t = ft = new FiniteTerrain(this, opts, x, y, z, true);
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

					// Should we shift the meta data to the higher coords.
					int shift = (4 * (y % 2));

					// Get the mask of bits we need to mask out,
					// data is uninitialized.
					ubyte mask = cast(ubyte)~(0xf << shift);

					// Mask out old bits and mask in new.
					*pm = (*pm & mask) | meta << shift;

					p += 1;
					pm += y % 2;
					src += ySrcStride;
				}

				// If height is uneaven we need to increment
				// this. Also remove uninitialized bits in the
				// high part of the bytes.
				if (ySize % 2) {
					(*pm) &= 0xf;
					pm++;
				}
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
				for (int y; y < ct.ySize; y++) {
					ubyte type;

					if (y == 0)
						type = 7;
					else if (y < 64)
						type = 1;
					else if (y == 64)
						type = 3;
					else if (y == 65)
						type = 3;
					else if (y == 66)
						type = 2;
					else
						type = 0;

					ct.setType(type, x, y, z);
				}
			}
		}

		for (ubyte i; i < 50; i++) {
			ubyte block, meta;
			convertClassicToBeta(i, block, meta);
			ct[32+i, 67, 32] = Block(block, meta);
		}
	}
}
