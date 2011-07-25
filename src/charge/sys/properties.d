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
	char[][] order;

public:
	void add(char[] key, char[] value)
	{
		if ((key in map) is null)
			order ~= key;
		map[key] = value;
	}

	void add(char[] key, bool value)
	{
		add(key, std.string.toString(value));
	}

	void add(char[] key, real value)
	{
		add(key, std.string.toString(value));
	}

	char[] get(char[] key, char[] def)
	{
		auto v = safeGet(key);
		if (v is null)
			return def;
		return v.dup;
	}

	char* getStringz(char[] key, char[] def)
	{
		return toStringz(get(key, def));
	}

	int getUint(char[] key, uint def)
	{
		try {
			return toUint(safeGet(key));
		} catch (Exception e) {
			return def;
		}
	}

	double getDouble(char[] key, double def)
	{
		try {
			return toDouble(safeGet(key));
		} catch (Exception e) {
			return def;
		}
	}

	int getInt(char[] key, int def)
	{
		try {
			return toInt(safeGet(key));
		} catch (Exception e) {
			return def;
		}
	}

	bool getBool(char[] key, bool def)
	{
		try {
			auto v = safeGet(key);

			if (v is null)
				return def;
			else if (v == "true")
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

	bool save(char[] filename)
	{
		BufferedFile f;

		try {
			f = new BufferedFile(filename, FileMode.Out);
		} catch (Exception e) {
			return false;
		}

		foreach(o; order) {
			f.writefln(o, ":", map[o]);
		}
		f.flush();
		f.close();

		return true;
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

private:
	/**
	 * Fixes problems with -O3.
	 */
	char[] safeGet(char[] key)
	{
		auto v = key in map;
		if (v is null)
			return null;
		return *v;
	}
}
