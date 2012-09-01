// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.isle.world;

import charge.charge;

import charge.math.noise;

import miners.world;
import miners.options;
import miners.builder.beta;
import miners.terrain.beta;
import miners.terrain.chunk;
import miners.terrain.common;
import miners.importer.info;


/**
 * World containing a infite floating island world.
 */
class IsleWorld : World
{
public:
	BetaTerrain bt;

public:
	this(Options opts)
	{
		this.spawn = Point3d(-10, 64, -10);
		super(opts);

		auto builder = new BetaMeshBuilder();
		t = bt = new BetaTerrain(this, opts, &newChunk, builder);

		// Find the actuall spawn height
		auto x = cast(int)spawn.x;
		auto y = cast(int)spawn.y;
		auto z = cast(int)spawn.z;
		auto xPos = x < 0 ? (x - 15) / 16 : x / 16;
		auto yPos = y < 0 ? (y - 15) / 16 : y / 16;
		auto zPos = z < 0 ? (z - 15) / 16 : z / 16;

		bt.setCenter(xPos, yPos, zPos);
		bt.loadChunk(xPos, zPos);

		auto p = bt.getTypePointer(x, z);
		bool foundFilled;
		for (int i = y; i < 128; i++) {
			if (tile[p[i]].filled) {
				foundFilled = true;
				continue;
			}
			if (tile[p[i+1]].filled)
				continue;
			if (!foundFilled)
				continue;

			spawn.y = i;
			break;
		}
	}

	void newChunk(Chunk c)
	{
		// Allocte valid data for the chunk
		c.allocBlocksAndData();

		// For each block pillar in the chunk.
		for (int x; x < 16; x++) {
			for (int z; z < 16; z++) {
				// Get the pointer to the first block in a pillar.
				auto ptr = c.getTypePointerUnsafe(x, z);

				// Go from local chunk coords to global scaled coords.
				auto xU = (x + c.xPos * 16) / 64.0;
				auto zU = (z + c.zPos * 16) / 64.0;

				// Get the noise value for this location.
				auto g = pnoise(xU, 0, zU);

				g += 1;
				g *= 64.0;
				g += 5;

				for (int y = 64; y > g; y--)
					ptr[y] = 1;
			}
		}
				
		c.valid = true;
		c.loaded = true;
	}
}
