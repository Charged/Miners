// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.importer.converter;

import miners.classic.data;

/**
 * Convert a single block of classic type to a beta block and meta.
 */
void convertClassicToBeta(ubyte from, out ubyte type, out ubyte meta)
{
	if (from >= 50)
		return;

	auto to = &classicBlocks[from];
	type = to.type;
	meta = to.meta;
}
