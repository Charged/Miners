// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for network helpers.
 *
 * @todo fold into math.ints.
 */
module charge.net.util;

import core.bitop : bswap;


uint ntoh(uint v)
{
	return bswap(v);
}

int ntoh(int v)
{
	return cast(int)ntoh(cast(uint)v);
}

ushort ntoh(ushort v)
{
	return cast(ushort)((v >> 8) | (v << 8));
}

short ntoh(short v)
{
	return cast(short)ntoh(cast(ushort)v);
}

alias ntoh hton;
