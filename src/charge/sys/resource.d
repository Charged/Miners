// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Resource and Pool.
 */
module charge.sys.resource;

import std.string : format;

import charge.sys.file;
import charge.sys.logger;
import charge.sys.builtins;


/**
 * Increments and decrements resource refcounts.
 *
 * @ingroup Resource
 */
void reference(void* _oldRes, Resource newRes)
{
	// Stupid D type system
	auto oldRes = cast(Resource*)_oldRes;

	assert(oldRes !is null);

	if (newRes !is null)
		newRes.incRef();

	if (*oldRes !is null)
		(*oldRes).decRef();

	*oldRes = newRes;
}

/**
 * Reference base class for all Resources.
 *
 * @ingroup Resource
 */
abstract class Resource
{
private:
	Pool pool;
	uint refcount;

	string name;
	string uri;

public:
	this(Pool p, string uri, string name)
	{
		this.pool = p;
		this.name = name;
		this.uri = uri;
		this.refcount = 1;

		if (name !is null) {
			p.resource(uri, name, this);
		} else {
			assert(p is null);
		}
	}

	final string getName()
	{
		return name;
	}

private:
	final void incRef()
	{
		if (refcount++ == 0) {
			assert(name !is null);
			pool.unmark(uri, name);
		}

		assert(refcount > 0);
	}

	final void decRef()
	{
		if (--refcount == 0) {
			if (name is null)
				delete this;
			else
				pool.mark(uri, name);
		}
	}
}

/**
 * Pool for named resources.
 *
 * @ingroup Resource
 */
class Pool
{
public:
	enum Mode {
		ONDISK_FIRST = 0,
		ONDISK_LAST = 1,
		ZIP_FIRST = ONDISK_LAST,
		ZIP_LAST = ONDISK_FIRST,
		ZIP_ONLY = 2,
	}

private:
	Pool parent;

	Mode fileMode;
	ZipFile[] zips;

	Entry[string] map;
	Resource[string] marked;

	static struct Entry {
		Resource res;
		uint refcount;
	};

	static Pool instance;

	mixin Logging;

public:
	this(Pool parent, ZipFile[] zips, Mode fileMode = Mode.ONDISK_FIRST)
	{
		this.zips = zips;
		this.parent = parent;
		this.fileMode = fileMode;
	}

	static Pool opCall()
	{
		if (instance is null)
			instance = new Pool(null, null);
		return instance;
	}


	/*
	 *
	 * File related functions.
	 *
	 */


	/**
	 * Loads a file checks all available sources.
	 *
	 * The order is this:
	 * @li Ondisk file if mode is set to @p ONDISK_FIRST.
	 * @li From zip files from this first and then any parent.
	 * @li Ondisk file if mode is set to @p ONDISK_LAST.
	 * @li Any inbuilt file.
	 */
	File load(string filename)
	{
		File f;

		if (fileMode == Mode.ONDISK_FIRST &&
		    (f = loadDisk(filename)) !is null)
			return f;

		// Load zip files from this or any parent.
		Pool p = this;
		while (p is null) {
			f = p.loadZip(filename);
			if (f !is null)
				return f;
			p = p.parent;
		}

		if (fileMode == Mode.ONDISK_LAST &&
		    (f = loadDisk(filename)) !is null)
			return f;

		return loadBuiltin(filename);
	}

	/**
	 * Loads a file from only this Pool's zip files.
	 */
	File loadZip(string filename)
	{
		File f;
		foreach(zip; zips) {
			f = zip.load(filename);
			if (f !is null)
				return f;
		}
		return null;
	}

	/**
	 * Loads a file from disk.
	 */
	File loadDisk(string filename)
	{
		void[] data;

		try {
			data = read(filename);
		} catch (Exception e) {
			return null;
		}

		auto df = new DMemFile(data);

		return df;
	}

	/**
	 * Loads a file from the inbuilt files.
	 */
	File loadBuiltin(string filename)
	{
		auto data = filename in builtins;
		if (data is null)
			return null;

		return new BuiltinFile(*data);
	}


	/*
	 *
	 * Resource related functions.
	 *
	 */


	Object resource(string uri, string name)
	{
		if (name is null)
			return null;

		string full = uri~name;

		auto e = full in map;
		if (!e)
			return null;

		Resource r = e.res;
		r.incRef;
		return r;
	}

	void collect()
	{
		while (marked.length > 0) {
			auto values = marked.values.dup;
			auto keys = marked.keys.dup;

			marked = null;

			foreach(k; keys)
				map.remove(k.dup);
			foreach(v; values)
				delete v;
		}
	}

	void clean()
	{
		collect();
		auto values = map.values;
		auto keys = map.keys;

		foreach (k; keys)
			l.warn("did not properly collect \"%s\"", k);
	}

package:
	void mark(string uri, string name)
	{
		string full = uri~name;

		auto e = full in map;
		if (e is null) {
			l.error("tried to mark \"%s\" but it is not found", full);
			assert(false);
		}
		debug {
			auto r = full in marked;
			if (r !is null) {
				l.error("tried to unmark \"%s\" but it is already in the marked list", full);
				assert(false);
			}
		}

		marked[full] = e.res;
	}

	void unmark(string uri, string name)
	{
		string full = uri~name;

		debug {
			auto e = full in map;
			if (e is null) {
				l.error("tried to unmark \"%s\" but it is not found", full);
				assert(false);
			}

			auto r = full in marked;
			if (r is null) {
				l.error("tried to unmark \"%s\" but it is not in the marked list", full);
				assert(false);
			}
		}

		marked.remove(full);
	}

	void resource(string uri, string name, Resource r)
	{
		string full = uri~name;

		assert((full in map) is null);
		assert(r);

		map[full] = Entry(r, 1);
	}
}
