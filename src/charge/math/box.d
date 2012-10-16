// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for a 2D box.
 */
module charge.math.box;


/**
 * A simple 2D box used for collision detection.
 *
 * @ingroup Math
 */
struct Box(T, V)
{
public:
	T x;
	T y;
	V w;
	V h;

public:
	bool collides(ref Box!(T, V) b)
	{
		T xw = x + w;
		T yw = y + h;

		T x2 = b.x;
		T y2 = b.y;
		T xw2 = x2 + b.w;
		T yw2 = y2 + b.h;

		if (x < xw2 && x2 < xw)
			if (y < yw2 && y2 < yw)
				return true;

		return false;
	}

	bool collides(T px, T py)
	{
		if (x <= px && x + w > px)
			if (y <= py && y + h > py)
				return true;

		return false;
	}
}


alias Box!(int, uint) BoxI;
