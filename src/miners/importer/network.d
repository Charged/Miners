// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.importer.network;

import std.math;


/**
 * String to parse a minecraft url.
 *
 * hostname = r[1]
 * port = r[3]
 * username = r[5]
 * password = r[7]
 */
const mcUrlStr = "mc://([^/:]+)" "(:([^/]+))?" "(/([^/]+))?" "(/([^/]+))?";

/**
 * String to parse a minecraft play string.
 *
 * username = r[1]
 * password = r[3]
 * id = r[5]
 */
const httpUrlStr = "http://([^/:]+)" "(:([^@]+))?" "@" "(www\\.)?"
		   "minecraft.net/classic/play/" "(.+)";

/**
 * Remove any trailing spaces from a string.
 *
 * Used to deal with strings from classic servers.
 */
char[] removeTrailingSpaces(char[] arg)
{
	size_t len = arg.length;
	while(len) {
		if (arg[len-1] != ' ')
			break;
		len--;
	}

	if (!len)
		return null;

	char[] ret;
	ret.length = len;
	ret[0 .. $] = arg[0 .. len];

	return ret;
}

/**
 * Remove any classic color tags from a string.
 *
 * Used to deal with strings from classic servers.
 */
char[] removeColorTags(char[] arg)
{
	char[] ret;
	int k;

	ret.length = arg.length;

	for (int i; i < arg.length; k++, i++) {
		// Found a color tag, skip it and the next.
		if (arg[i] == '&') {
			k--;
			i++;
			continue;
		}

		ret[k] = arg[i];
	}

	ret.length = k;
	return ret;
}

/**
 * Convert from notchian yaw pitch to the coord system we use.
 */
void fromYawPitch(ubyte yaw, ubyte pitch, out double heading, out double look)
{
	heading = -(yaw * 2.0 * std.math.PI / 256.0);
	look = -(pitch * 2.0 * std.math.PI / 256.0);
}

/**
 * Convert to notchian yaw pitch from the coord system we use.
 */
void toYawPitch(double heading, double look, out ubyte yaw, out ubyte pitch)
{
	yaw = cast(ubyte)-(heading / (2.0 * std.math.PI / 256.0));
	pitch = cast(ubyte)-(look / (2.0 * std.math.PI / 256.0));
}
