// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Light (s).
 */
module charge.gfx.light;

import charge.math.movable;
import charge.math.color;

import charge.gfx.gl;
import charge.gfx.texture;

import charge.sys.resource : reference;


class Light : Movable
{
}

class SimpleLight : Light
{
public:

	Color4f ambient;
	Color4f diffuse;
	Color4f specular;
	bool shadow;

	this()
	{
		ambient = Color4f(0.2, 0.2, 0.2);
		diffuse = Color4f(0.8, 0.8, 0.8);
		specular = Color4f();
	}

}

class PointLight : Light
{
public:
	Color4f diffuse;
	float size;
	bool shadow;

	this()
	{
		diffuse = Color4f(0.8, 0.8, 0.8);
		size = 10.0;
	}

}

class SpotLight : Light
{
public:
	Color4f diffuse;
	float angle;
	float ratio;
	float near;
	float far;
	bool shadow;
	Texture texture;

	this()
	{
		diffuse = Color4f(0.8, 0.8, 0.8);
		far = 100.0;
		near = 0.1;
		ratio = 1.0;
		angle = 20.0;

		texture = Texture("res/spotlight.png");
	}

	~this()
	{
		reference(&texture, null);
	}

}

class Fog : Movable
{
public:
	double start;
	double stop;
	Color4f color;

	this()
	{
		color = Color4f.White;
		start = 100000.0;
		stop = 100000.0;
	}
}
