// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.properties;

import std.file;
import std.conv;
import std.stdio;
import std.stream;
import std.regexp;
import std.string;

import charge.sys.logger;

class Properties
{
	mixin Logging;
protected:
	char[][char[]] map;

public:
	void add(char[] key, char[] value)
	{
		map[key] = value;
	}

	char[] get(char[] key, char[] def)
	{
		try {
			return map[key].dup;
		} catch (Exception e) {
			return def;
		}
	}

	char* getStringz(char[] key, char[] def)
	{
		return toStringz(get(key, def));
	}

	int getUint(char[] key, uint def)
	{
		try {
			return toUint(map[key]);
		} catch (Exception e) {
			return def;
		}
	}

	double getDouble(char[] key, double def)
	{
		try {
			return toDouble(map[key]);
		} catch (Exception e) {
			return def;
		}
	}

	int getInt(char[] key, int def)
	{
		try {
			return toInt(map[key]);
		} catch (Exception e) {
			return def;
		}
	}

	bool getBool(char[] key, bool def)
	{
		try {
			auto v = map[key];

			if (v == "true")
				return true;
			else if (v == "false")
				return false;

		} catch (Exception e) {
			return def;
		}

		return def;
	}

	void print()
	{
		writefln(map);
	}

	static Properties opCall(char[] filename)
	{
		BufferedFile f;

		try {
			f = new BufferedFile(filename);
		} catch (Exception e) {
			return null;
		}

		auto comment = RegExp(`^\s*#`);
		auto setting = RegExp(`^\s*(\S*)\s*=\s*(\S*)`);
		auto semsett = RegExp(`^\s*(\S*)\s*=?\s*:(.*)`);

		auto p = new Properties();

		char[][char[]] map;
		foreach(ulong n, char[] line; f) {
			if (line.length == 0)
				continue;

			if (comment.find(line) >= 0)
				continue;

			auto m = semsett.exec(line);
			if (m.length > 2) {
				// Need to dup them
				p.add(m[1].dup, m[2].dup);
				continue;
			}

			m = setting.exec(line);
			if (m.length > 2) {
				// Need to dup them
				p.add(m[1].dup, m[2].dup);
				continue;
			}

			l.warn("Could not parse line: ", n, " in file ", filename);
			l.warn(line);
		}

		return p;
	}

}
