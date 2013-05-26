// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Vector class.
 */
module charge.util.vector;

import core.exception : onRangeError;


/**
 * Small vector class. Only works on classes and pointers.
 */
struct Vector(T)
{
private:
	size_t num;
	T[] data;

public:
	void add(T t)
	{
		if (data.length <= num)
			data.length = data.length * 2 + 4;

		data[num] = t;
		num++;
	}

	void remove(T t)
	{
		remove(find(t));
	}

	void remove(size_t n)
	{
		if (n >= num)
			return;

		data = data[0 .. n] ~ data[n+1 .. data.length];
		num--;
	}

	int find(T t)
	{
		for (int i; i < num; i++)
			if (t is data[i])
				return i;

		return -1;
	}

	/*
	 * Returns object i
	 * Unlike arrays does not throw Error, instead returns null.
	 */
	T opIndex(size_t i)
	{
		if (i >= num)
			return null;

		return data[i];
	}

	T opIndexAssign(T t, size_t i)
	{
		if (i >= num)
			onRangeError();

		data[i] = t;
		return t;
	}

	void opCatAssign(T t)
	{
		add(t);
	}

	void opCatAssign(T[] tarr)
	{
		if (data.length < tarr.length + num)
			data.length = data.length * 2 + tarr.length;

		data[num .. num + tarr.length] = tarr[0 .. $];
		num += tarr.length;
	}

	int opApply(int delegate(ref T) dg)
	{
		int r;
		for (int i; i < num; i++) {
			r = dg(data[i]);
			if (r)
				break;
		}
		return r;
	}

	int opApplyReverse(int delegate(ref T) dg)
	{
		int r;
		for (int i = cast(int)num-1; i >= 0; i--) {
			r = dg(data[i]);
			if (r)
				break;
		}
		return r;
	}

	T[] opSlice()
	{
		if (num)
			return data[0 .. num];
		return null;
	}

	/*
	 * Returns a array that is the copy of the content.
	 */
	T[] adup()
	{
		if (num)
			return data[0 .. num].dup;
		return [];
	}

	size_t length()
	{
		return num;
	}

	size_t length(size_t len)
	{
		if (len < num)
			foreach(ref d; data[len .. num])
				d = null;

		num = len;

		if (num < data.length)
			return num;

		while (data.length < num)
			data.length = data.length * 2 + 3;

		return num;
	}

	void removeAll()
	{
		data = null;
		num = 0;
	}

}


/**
 * Small vector class. Works for other data types.
 */
struct VectorData(T)
{
private:
	size_t num;
	T[] data;

public:
	void add(T t)
	{
		if (data.length <= num)
			data.length = data.length * 2 + 4;

		data[num] = t;
		num++;
	}

	void remove(T t)
	{
		remove(find(t));
	}

	void remove(int n)
	{
		if (n < 0 || n >= num)
			return;

		data = data[0 .. n] ~ data[n+1 .. data.length];
		num--;
	}

	int find(T t)
	{
		for (int i; i < num; i++)
			if (t is data[i])
				return i;

		return -1;
	}

	/*
	 * Returns object i
	 * Throws ArrayBoundsError
	 */
	T opIndex(size_t i)
	{
		
		if (i >= num)
			onRangeError();

		return data[i];
	}

	void opCatAssign(T t)
	{
		add(t);
	}

	void opCatAssign(T[] tarr)
	{
		if (data.length < tarr.length + num)
			data.length = data.length * 2 + tarr.length;

		data[num .. num + tarr.length] = tarr[0 .. $];
		num += tarr.length;
	}

	int opApply(int delegate(inout T) dg)
	{
		int r;
		for (int i; i < num; i++) {
			r = dg(data[i]);
			if (r)
				break;
		}
		return r;
	}

	/*
	 * Returns a array that is the copy of the content.
	 */
	T[] adup()
	{
		if (num)
			return data[0 .. num].dup;
		return [];
	}

	size_t length()
	{
		return num;
	}

	void removeAll()
	{
		data = null;
		num = 0;
	}

}
