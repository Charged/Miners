// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.importer.network;


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
