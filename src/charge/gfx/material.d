// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Material.
 */
module charge.gfx.material;

import std.conv : ConvException, ConvOverflowException;
import std.string : format;
import stdx.conv : toInt, toFloat;
import stdx.regexp : RegExp;

import lib.xml.xml;

import charge.math.color;
import charge.sys.logger;
import charge.gfx.gl;
import charge.gfx.shader;
import charge.gfx.light;
import charge.gfx.texture;
import charge.gfx.renderqueue;

import charge.sys.resource : Pool, reference;


struct MaterialProperty
{
	enum {
		TEXTURE  = 0,
		COLOR3   = 3,
		COLOR4   = 4,
		OPTION   = 5,
	}
	string name;
	int type;
}

class Material
{
public:
	Pool pool;

public:
	this(Pool p)
	{
		this.pool = p;
	}

	abstract void breakApart();

	final bool opIndexAssign(string tex, string name)
	{
		return setTexture(name, tex);
	}

	final bool opIndexAssign(Texture tex, string name)
	{
		return setTexture(name, tex);
	}

	final bool opIndexAssign(Color3f color, string name)
	{
		return setColor3f(name, color);
	}

	final bool opIndexAssign(Color4f color, string name)
	{
		return setColor4f(name, color);
	}

	final bool opIndexAssign(bool option, string name)
	{
		return setOption(name, option);
	}

	final bool setTexture(string name, string filename)
	{
		if (name is null)
			return false;

		Texture tex;

		if (filename !is null)
			tex = Texture(pool, filename);

		auto ret = setTexture(name, tex);
		reference(&tex, null);

		return ret;
	}

	bool setTexture(string name, Texture tex)
	{
		return false;
	}

	bool setColor3f(string name, Color3f value)
	{
		return false;
	}

	bool setColor4f(string name, Color4f value)
	{
		return false;
	}

	bool setOption(string name, bool value)
	{
		return false;
	}

	bool getTexture(string name, out Texture tex)
	{
		return false;
	}

	bool getColor3f(string name, out Color3f value)
	{
		return false;
	}

	bool getColor4f(string name, out Color4f value)
	{
		return false;
	}

	bool getOption(string name, out bool value)
	{
		return false;
	}

	MaterialProperty[] getPropList()
	{
		return [];
	}
}

class SimpleMaterial : Material
{
public:
	Color4f color;
	Texture tex; /**< Does not hold a reference */
	Texture texSafe; /**< Will always be valid */
	bool fake;
	bool stipple;
	bool skel; /**< This is here temporary */

public:
	this(Pool p)
	{
		super(p);
		this.color = Color4f.White;

		texSafe = ColorTexture(pool, color);

		assert(texSafe !is null);
	}

	~this()
	{
		assert(tex is null);
		assert(texSafe is null);
	}

	override void breakApart()
	{
		reference(&texSafe, null);
		// Does not hold a reference
		tex = null;
	}

	override MaterialProperty[] getPropList()
	{
		static MaterialProperty[] list = [
			{"tex", MaterialProperty.TEXTURE},
			{"color", MaterialProperty.COLOR3},
			{"fake", MaterialProperty.OPTION},
			{"stipple", MaterialProperty.OPTION}
		];
		return list;
	}

	override bool setTexture(string name, Texture texture)
	{
		if (name is null)
			return false;

		switch(name) {
			case "tex":
				// Tex does not hold a reference
				tex = texture;

				// Update the safe texture
				reference(&texSafe, tex);

				// Must always be safe to access, set to color
				if (texSafe is null)
					texSafe = ColorTexture(pool, color);
				break;
			default:
				return false;
		}

		return true;
	}

	override bool setColor3f(string name, Color3f color)
	{
		if (name is null)
			return false;

		switch(name) {
			case "color":
				this.color = Color4f(color);
				// Update the color texture if set
				setTexture("tex", tex);
				break;
			default:
				return false;
		}

		return true;
	}

	override bool setColor4f(string name, Color4f color)
	{
		if (name is null)
			return false;

		switch(name) {
			case "color":
				this.color = color;
				this.color.a = 1.0f;
				// Update the color texture if set
				setTexture("tex", tex);
				break;
			default:
				return false;
		}

		return true;
	}

	override bool setOption(string name, bool option)
	{
		switch(name) {
			case "fake":
				fake = option;
				break;
			case "stipple":
				stipple = option;
				break;
			default:
				return false;
		}

		return true;
	}

	override bool getTexture(string name, out Texture tex)
	{
		if (name is null)
			return false;

		switch(name) {
			case "tex":
				tex = tex;
				break;
			default:
				return false;
		}

		return true;
	}

	override bool getColor3f(string name, out Color3f color)
	{
		if (name is null)
			return false;

		switch(name) {
			case "color":
				color = Color3f(this.color.r, this.color.g, this.color.b);
				break;
			default:
				return false;
		}

		return true;
	}

	override bool getOption(string name, out bool option)
	{
		switch(name) {
			case "fake":
				option = this.fake;
				break;
			default:
				return false;
		}

		return true;
	}

}

class MaterialManager
{
private:
	mixin Logging;

	static RegExp value3;
	static RegExp value4;
	static Material defaultMaterial;

	static this()
	{
		value3 = RegExp(`(\S+)\s+(\S+)\s+(\S+)`);
		value4 = RegExp(`(\S+)\s+(\S+)\s+(\S+)\s+(\S+)`);
	}

public:

	static Material getDefault(Pool p)
	{
		return new SimpleMaterial(p);
	}

	static Material opCall(Pool p, string filename)
	{
		Element f;

		try {
			f = DomParser(filename);
		} catch (XmlException xe) {
			l.error(xe.msg);
			return null;
		}

		auto m = new SimpleMaterial(p);

		try {
			process(m, Handle(f));
		} catch (Exception e) {
			l.error(e.msg);
		}

		l.info("Loaded material ", filename);
		return m;
	}

	static void process(Material m, Handle f)
	{
		auto list = m.getPropList();
		foreach(prop; list) {
			auto e = f.first(prop.name).first().text;

			if (e is null)
				continue;

			switch(prop.type) {
				case MaterialProperty.TEXTURE:
					string t = e.value;
					m[prop.name] = t;
					break;
				case MaterialProperty.COLOR3:
					Color3f c;
					string t = e.value;
					if (exColor3f(t, c))
						m[prop.name] = c;
					break;
				case MaterialProperty.COLOR4:
					Color4f c;
					string t = e.value;
					if (exColor4f(t, c))
						m[prop.name] = c;
					break;
				case MaterialProperty.OPTION:
					bool b;
					string t = e.value;
					if (exBool(t, b))
						m[prop.name] = b;
					break;
				default:
					break;
			}
		}
	}

	static bool exColor3f(string text, out Color3f r)
	{
		auto p = value3.exec(text);
		if (p.length < 4)
			return false;

		try {
			r.r = toFloat(p[1]);
			r.g = toFloat(p[2]);
			r.b = toFloat(p[3]);
		} catch (ConvOverflowException cof) {
			return false;
		} catch (ConvException ce) {
			return false;
		}

		return true;
	}

	static bool exColor4f(string text, out Color4f r)
	{
		auto p = value4.exec(text);
		if (p.length < 5)
			return false;

		try {
			r.r = toFloat(p[1]);
			r.g = toFloat(p[2]);
			r.b = toFloat(p[3]);
			r.a = toFloat(p[4]);
		} catch (ConvOverflowException cof) {
			return false;
		} catch (ConvException ce) {
			return false;
		}

		return true;
	}

	static bool exBool(string text, out bool b)
	{
		if (text == "true") {
			b = true;
		} else if (text == "false") {
			b = false;
		} else {
			return false;
		}
		return true;
	}
}
