// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.resource;

import std.string;
import std.stdio;

import charge.sys.logger;

abstract class Resource
{
private:
	Pool pool;
	uint refcount;

	char[] name;
	char[] uri;

public:
	static void reference(void* _oldRes, Resource newRes)
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

	this(Pool p, char[] uri, char[] name)
	{
		this.pool = p;
		this.name = name;
		this.uri = uri;
		this.refcount = 1;

		if (name !is null)
			p.resource(uri, name, this);
	}

	final char[] getName()
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

class Pool
{
private:
	mixin Logging;
	Pool parent;
	Entry[char[]] map;
	Resource[char[]] marked;
	uint dynamic;

	static Pool instance;

	static struct Entry {
		Resource res;
		uint refcount;
	};

public:
	static Pool opCall()
	{
		if (instance is null)
			instance = new Pool();
		return instance;
	}

	Object resource(char[] uri, char[] name)
	{
		if (name is null)
			return null;

		char[] full = uri~name;

		auto e = full in map;
		if (!e)
			return null;

		Resource r = e.res;
		r.incRef;
		return r;
	}

	void collect()
	{
		if (marked.length < 1)
			return;

		auto values = marked.values.dup;
		auto keys = marked.keys.dup;

		foreach(k; keys)
			map.remove(k.dup);
		foreach(v; values)
			delete v;

		marked = null;
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
	void mark(char[] uri, char[] name)
	{
		char[] full = uri~name;

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

	void unmark(char[] uri, char[] name)
	{
		char[] full = uri~name;

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

	void resource(char[] uri, char[] name, Resource r)
	{
		char[] full = uri~name;

		assert((full in map) is null);
		assert(r);

		map[full] = Entry(r, 1);
	}
}
