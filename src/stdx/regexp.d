// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Helper file during transition to D2.
 */
module stdx.regexp;

import std.regex;


/**
 * Crappy implementation of RegExp from D1.
 */
class RegExp
{
public:
	Regex!char reg;

public:
	static RegExp opCall(string reg)
	{
		return new RegExp(reg);
	}

	this(string reg)
	{
		this.reg = regex(reg);
	}

	const(char)[][] exec(const(char)[] str)
	{
		auto m = .match(str, reg);
		if (m.empty)
			return null;

		auto c = m.captures;
		const(char)[][] ret;

		foreach(cap; c) {
			ret ~= cap;
		}

		return ret;
	}

	alias exec match;

	ptrdiff_t find(const(char)[] str)
	{
		auto m = .match(str, reg);
		if (m.empty)
			return -1;

		return 0;
	}

	const(char)[][] split(const(char)[] str)
	{
		throw new Exception("Not implemented");
	}
}
