// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Properties.
 */
module charge.util.properties;

import std.conv : toInt, toUint, toDouble;
import std.stream : BufferedFile, FileMode;
import std.regexp : RegExp;
import std.string : toString, toStringz;


/**
 * Parsers and saves to java like properties files.
 */
final class Properties
{
private:
	string[string] map;
	string[] order;

public:
	bool opIn_r(string key)
	{
		return (key in map) !is null;
	}

	void addIfNotSet(string key, string value)
	{
		if (key in this)
			return;
		order ~= key;
		map[key] = value;
	}

	void addIfNotSet(string key, bool value) { addIfNotSet(key, .toString(value)); }
	void addIfNotSet(string key, double value) { addIfNotSet(key, .toString(value)); }

	string getIfNotFoundSet(string key, string value)
	{
		if (key in this)
			return map[key];
		addKeyNotFound(key, value);
		return value;
	}

	int getIfNotFoundSet(string key, int def)
	{
		if (key in this)
			return toIntOrDef(map[key], def);
		addIfNotSet(key, .toString(def));
		return def;
	}

	uint getIfNotFoundSet(string key, uint def)
	{
		if (key in this)
			return toUintOrDef(map[key], def);
		addIfNotSet(key, .toString(def));
		return def;
	}

	double getIfNotFoundSet(string key, double def)
	{
		if (key in this)
			return toDoubleOrDef(map[key], def);
		addIfNotSet(key, .toString(def));
		return def;
	}

	bool getIfNotFoundSet(string key, bool def)
	{
		if (key in this)
			return toBoolOrDef(map[key], def);
		addIfNotSet(key, .toString(def));
		return def;
	}

	void add(string key, string value)
	{
		if ((key in map) is null)
			order ~= key;
		map[key] = value;
	}

	void add(string key, bool value) { add(key, .toString(value)); }
	void add(string key, double value) { add(key, .toString(value)); }

	string get(string key, string def)
	{
		auto v = safeGet(key);
		if (v is null)
			return def;
		return v.dup;
	}

	char* getStringz(string key, string def)
	{
		return toStringz(get(key, def));
	}

	int getInt(string key, int def) { return toIntOrDef(safeGet(key), def); }
	uint getUint(string key, uint def) { return toUintOrDef(safeGet(key), def); }
	double getDouble(string key, double def) { return toDoubleOrDef(safeGet(key), def); }
	bool getBool(string key, bool def) { return toBoolOrDef(safeGet(key), def); }

	bool save(string filename)
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

	static Properties opCall(string filename)
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

		foreach(ulong n, string line; f) {
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
		}

		return p;
	}

private:
	/**
	 * Fixes problems with -O3.
	 */
	string safeGet(string key)
	{
		auto v = key in map;
		if (v is null)
			return null;
		return *v;
	}

	/**
	 * Helper function to add a key know to be not there.
	 */
	void addKeyNotFound(string key, string value)
	{
		order ~= key;
		map[key] = value;
	}


	/*
	 *
	 * Conversion keys.
	 *
	 */


	uint toUintOrDef(string str, uint def)
	{
		try {
			return toUint(str);
		} catch (Exception e) {
			return def;
		}
	}

	double toDoubleOrDef(string str, double def)
	{
		try {
			return toDouble(str);
		} catch (Exception e) {
			return def;
		}
	}

	int toIntOrDef(string str, int def)
	{
		try {
			return toInt(str);
		} catch (Exception e) {
			return def;
		}
	}

	bool toBoolOrDef(string str, bool def)
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
