// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for OpenAL helpers and importer.
 */
module charge.sfx.al;

import std.stdio : writefln;


public {
	import lib.al.al;
}

void aluGetError()
{
	auto e = alGetError();
	if (e)
		writefln("error: ", e, " ", alGetString(e));
}
