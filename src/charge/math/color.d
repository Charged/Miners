// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for colors used in graphics.
 */
module charge.math.color;

import std.string : format;


struct Color4b
{
public:
	ubyte r, g, b, a;

	const static Color4b White = {255, 255, 255, 255};
	const static Color4b Black = {  0,   0,   0, 255};

public:
	static Color4b opCall(ubyte r, ubyte g, ubyte b, ubyte a)
	{
		Color4b res = {r, g, b, a};
		return res;
	}

	static Color4b opCall(uint value)
	{
		Color4b res = {
			cast(ubyte)((value >> 24) & 0xff),
			cast(ubyte)((value >> 16) & 0xff),
			cast(ubyte)((value >>  8) & 0xff),
			cast(ubyte)((value >>  0) & 0xff),
		};
		return res;
	}

	inout(ubyte)* ptr() @property inout { return &r; }

	void modulate(Color4b c)
	{
		Color4f c1 = Color4f(this);
		Color4f c2 = Color4f(c);

		r = cast(ubyte)(c1.r * c2.r * 255);
		g = cast(ubyte)(c1.g * c2.g * 255);
		b = cast(ubyte)(c1.b * c2.b * 255);
		a = cast(ubyte)(c1.a * c2.a * 255);
	}

	void blend(Color4b c)
	{
		Color4f c1 = Color4f(this);
		Color4f c2 = Color4f(c);

		float alpha = c2.a;
		float alpha_minus_one = 1.0 - c2.a;

		r = cast(ubyte)((c1.r * alpha_minus_one + c2.r * alpha) * 255);
		g = cast(ubyte)((c1.g * alpha_minus_one + c2.g * alpha) * 255);
		b = cast(ubyte)((c1.b * alpha_minus_one + c2.b * alpha) * 255);
		a = cast(ubyte)((c1.a * alpha_minus_one + c2.a * alpha) * 255);
	}

	string toString()
	{
		return format("(%s, %s, %s, %s)", r, g, b, a);
	}
}


struct Color3f
{
public:
	float r, g, b;

	const static Color3f White = {1.0f, 1.0f, 1.0f};
	const static Color3f Black = {0.0f, 0.0f, 0.0f};

public:
	static Color3f opCall(float r, float g, float b)
	{
		Color3f res = {r, g, b};
		return res;
	}

	static Color3f opCall(Color4b c)
	{
		return Color3f(c.r / 255f, c.g / 255f, c.b / 255f);
	}

	inout(float)* ptr() @property inout { return &r; }

	string toString()
	{
		return format("(%s, %s, %s)", r, g, b);
	}
}


struct Color4f
{
public:
	float r, g, b, a;

	const static Color4f White = {1.0f, 1.0f, 1.0f, 1.0f};
	const static Color4f Black = {0.0f, 0.0f, 0.0f, 1.0f};

public:
	static Color4f opCall()
	{
		return Black;
	}

	static Color4f opCall(Color4b c)
	{
		return Color4f(c.r / 255f, c.g / 255f, c.b / 255f, c.a / 255f);
	}

	static Color4f opCall(Color3f c)
	{
		return Color4f(c.r, c.g, c.b, 1.0f);
	}

	static Color4f opCall(float r, float g, float b)
	{
		return Color4f(r, g, b, 1.0f);
	}

	static Color4f opCall(float r, float g, float b, float a)
	{
		Color4f res = {r, g, b, a};
		return res;
	}

	inout(float)* ptr() @property inout { return &r; }

	string toString()
	{
		return format("(%s, %s, %s, %s)", r, g, b, a);
	}
}
