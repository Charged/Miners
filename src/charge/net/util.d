// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.net.util;

import std.intrinsic : bswap;


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
	return (v >> 8) | (v << 8);
}

short ntoh(short v)
{
	return cast(short)ntoh(cast(ushort)v);
}

alias ntoh hton;
