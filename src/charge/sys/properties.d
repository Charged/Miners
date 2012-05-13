// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.properties;

import std.file;
import std.conv;
import std.stdio;
import std.stream;
import std.regexp;
import std.string : toString, toStringz;

import charge.sys.logger;

final class Properties
{
	mixin Logging;
protected:
	char[][char[]] map;
	char[][] order;

public:
	bool opIn_r(char[] key)
	{
		return (key in map) !is null;
	}

	void addIfNotSet(char[] key, char[] value)
	{
		if (key in this)
			return;
		order ~= key;
		map[key] = value;
	}

	void addIfNotSet(char[] key, bool value) { addIfNotSet(key, .toString(value)); }
	void addIfNotSet(char[] key, double value) { addIfNotSet(key, .toString(value)); }

	char[] getNotFoundSet(char[] key, char[] value)
	{
		if (key in this)
			return map[key];
		addKeyNotFound(key, value);
		return value;
	}

	int getIfNotFoundSet(char[] key, int def)
	{
		if (key in this)
			return toIntOrDef(map[key], def);
		addIfNotSet(key, .toString(def));
		return def;
	}

	uint getIfNotFoundSet(char[] key, uint def)
	{
		if (key in this)
			return toUintOrDef(map[key], def);
		addIfNotSet(key, .toString(def));
		return def;
	}

	double getIfNotFoundSet(char[] key, double def)
	{
		if (key in this)
			return toDoubleOrDef(map[key], def);
		addIfNotSet(key, .toString(def));
		return def;
	}

	bool getIfNotFoundSet(char[] key, bool def)
	{
		if (key in this)
			return toBoolOrDef(map[key], def);
		addIfNotSet(key, .toString(def));
		return def;
	}

	void add(char[] key, char[] value)
	{
		if ((key in map) is null)
			order ~= key;
		map[key] = value;
	}

	void add(char[] key, bool value) { add(key, .toString(value)); }
	void add(char[] key, double value) { add(key, .toString(value)); }

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

	int getInt(char[] key, int def) { return toIntOrDef(safeGet(key), def); }
	uint getUint(char[] key, uint def) { return toUintOrDef(safeGet(key), def); }
	double getDouble(char[] key, double def) { return toDoubleOrDef(safeGet(key), def); }
	bool getBool(char[] key, bool def) { return toBoolOrDef(safeGet(key), def); }

	void print()
	{
		writefln(map);
	}

	bool save(char[] filename)
	{
		BufferedFile f;

		try {
			f = new BufferedFile(filename, FileMode.OutNew);
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

	/**
	 * Helper function to add a key know to be not there.
	 */
	void addKeyNotFound(char[] key, char[] value)
	{
		order ~= key;
		map[key] = value;
	}


	/*
	 *
	 * Conversion keys.
	 *
	 */


	uint toUintOrDef(char[] str, uint def)
	{
		try {
			return toUint(str);
		} catch (Exception e) {
			return def;
		}
	}

	double toDoubleOrDef(char[] str, double def)
	{
		try {
			return toDouble(str);
		} catch (Exception e) {
			return def;
		}
	}

	int toIntOrDef(char[] str, int def)
	{
		try {
			return toInt(str);
		} catch (Exception e) {
			return def;
		}
	}

	bool toBoolOrDef(char[] str, bool def)
	{
		try {
			if (str is null)
				return def;
			else if (str == "true")
				return true;
			else if (str == "false")
				return false;
		} catch (Exception e) {
			return def;
		}

		return def;
	}
}
