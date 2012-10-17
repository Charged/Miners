// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for base36 encoding.
 */
module charge.util.base36;


/**
 * Encodes a value into base64 encoding.
 *
 * XXX Optimize
 */
string encode(int v)
{
	const string array = "0123456789abcdefghijklmnopqrstuvwxyz";
	string buf;
	string sign;

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
