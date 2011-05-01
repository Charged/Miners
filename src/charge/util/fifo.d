// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.util.fifo;

/**
 * Small fifo class.
 * Its not the most optimal code but thats what you get when you spend ten
 * minutes writing something. Heck this comment took longer to write then
 * the actual code.
 *
 * Anyway it only works for pointer type objects since it sets the object
 * in the internal array to null at pop, this is to make sure that objects that
 * where once inserted into the fifo can be collected.
 */
class Fifo(T)
{
	this()
	{
		array.length = 4;
		num = 0;
	}

	void add(T t)
	{
		if (num >= array.length) {
			array.length = array.length * 2 + 1;
		}

		array[num++] = t;
	}

	T pop()
	{
		if (num == 0)
			return null;

		T t = array[0];
		array[0] = null;
		array = array[1 .. array.length];

		num--;

		return t;
	}

	size_t length()
	{
		return num;
	}

protected:
	size_t num;
	T array[];
}
