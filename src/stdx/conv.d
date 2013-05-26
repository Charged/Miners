// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Helper file during transition to D2.
 */
module stdx.conv;

import std.conv : to;


int toInt(const(char)[] str)
{
	return to!int(str);
}

uint toUint(const(char)[] str)
{
	return to!uint(str);
}

short toShort(const(char)[] str)
{
	return to!short(str);
}

ushort toUshort(const(char)[] str)
{
	return to!ushort(str);
}

float toFloat(const(char)[] str)
{
	return to!float(str);
}

double toDouble(const(char)[] str)
{
	return to!double(str);
}
