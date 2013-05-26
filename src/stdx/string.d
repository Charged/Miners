// Taken pretty much directly from D1 phobos.
// See original header at end of file.
/**
 * Helper file during transition to D2.
 */
module stdx.string;

import core.stdc.string : memchr, memcmp;
import std.conv : to;


string toString(const(char)* v) { return to!string(v); }
string toString(bool v) { return to!string(v); }
string toString(char v) { return to!string(v); }
string toString(byte v) { return to!string(v); }
string toString(ubyte v) { return to!string(v); }
string toString(short v) { return to!string(v); }
string toString(ushort v) { return to!string(v); }
string toString(int v) { return to!string(v); }
string toString(uint v) { return to!string(v); }
string toString(long v) { return to!string(v); }
string toString(ulong v) { return to!string(v); }
string toString(float v) { return to!string(v); }
string toString(double v) { return to!string(v); }

inout(char)[][] splitlines(inout(char)[] s)
{
	size_t i;
	size_t istart;
	size_t nlines;
	inout(char)[][] lines;

	nlines = 0;
	for (i = 0; i < s.length; i++) {
		char c;

		c = s[i];
		if (c == '\r' || c == '\n') {
			nlines++;
			istart = i + 1;
			if (c == '\r' && i + 1 < s.length && s[i + 1] == '\n') {
				i++;
				istart++;
			}
		}
	}
	if (istart != i)
		nlines++;

	lines = new inout(char)[][nlines];
	nlines = 0;
	istart = 0;
	for (i = 0; i < s.length; i++) {
		char c;

		c = s[i];
		if (c == '\r' || c == '\n') {
			lines[nlines] = s[istart .. i];
			nlines++;
			istart = i + 1;
			if (c == '\r' && i + 1 < s.length && s[i + 1] == '\n') {
				i++;
				istart++;
			}
		}
	}
	if (istart != i) {
		lines[nlines] = s[istart .. i];
		nlines++;
	}

	assert(nlines == lines.length);
	return lines;
}

ptrdiff_t find(const(char)[] s, dchar c)
{
	if (c <= 0x7F) {
		// Plain old ASCII
		auto p = cast(char*)memchr(s.ptr, c, s.length);
		if (p)
			return p - cast(char *)s;
		else
			return -1;
	}

	// c is a universal character
	foreach(size_t i, dchar c2; s) {
		if (c == c2)
			return i;
	}

	return -1;
}

ptrdiff_t find(const(char)[] s, const(char)[] sub)
out (result) {
	if (result == -1) {
	} else {
		assert(0 <= result && result < s.length - sub.length + 1);
		assert(memcmp(&s[result], sub.ptr, sub.length) == 0);
	}
}
body {
	auto sublength = sub.length;

	if (sublength == 0)
		return 0;

	if (s.length >= sublength) {
		auto c = sub[0];
		if (sublength == 1) {
			auto p = cast(char*)memchr(s.ptr, c, s.length);
			if (p)
				return p - &s[0];
		} else {
			size_t imax = s.length - sublength + 1;

			// Remainder of sub[]
			const(char) *q = &sub[1];
			sublength--;

			for (size_t i = 0; i < imax; i++) {
				char *p = cast(char*)memchr(&s[i], c, imax - i);
				if (!p)
					break;
				i = p - &s[0];
				if (memcmp(p + 1, q, sublength) == 0)
					return i;
			}
		}
	}
	return -1;
}

ptrdiff_t rfind(const(char)[] s, dchar c)
{
	size_t i;

	if (c <= 0x7F) {
		// Plain old ASCII
		for (i = s.length; i-- != 0;) {
			if (s[i] == c)
				break;
		}
		return i;
	}

	throw new Exception("Error badly implemented rfind");
}

/* 
 * String handling functions. 
 * 
 * To copy or not to copy? 
 * When a function takes a string as a parameter, and returns a string, 
 * is that string the same as the input string, modified in place, or 
 * is it a modified copy of the input string? The D array convention is 
 * "copy-on-write". This means that if no modifications are done, the 
 * original string (or slices of it) can be returned. If any modifications 
 * are done, the returned string is a copy. 
 * 
 * Source: $(PHOBOSSRC std/_string.d) 
 * Macros: 
 *      WIKI = Phobos/StdString 
 * Copyright: 
 *      Public Domain 
 */ 
 
/* Author: 
 *      Walter Bright, Digital Mars, www.digitalmars.com 
 */
