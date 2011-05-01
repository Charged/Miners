// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.util.base36;

char[] encode(int v)
{
	const char[] array = "0123456789abcdefghijklmnopqrstuvwxyz";
	char[] buf;
	char[] sign;

	if (v < 0) {
		sign = "-";
		v = -v;
	} else {
		sign = "";
	}

	do {
		buf = array[v % 36] ~ buf;
		v /= 36;
	} while(v);

	return sign ~ buf;
}
