// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.loader;

import std.string : tolower;
import std.regexp : RegExp;
import std.conv : toDouble, ConvError, ConvOverflowError;
import std.math : PI;

static import lib.xml.xml;

alias lib.xml.xml.XmlException XmlException;
alias lib.xml.xml.Node XmlNode;
alias lib.xml.xml.Text XmlText;
alias lib.xml.xml.Element XmlElement;
alias lib.xml.xml.Attribute XmlAttribute;
alias lib.xml.xml.Handle XmlHandle;
alias lib.xml.xml.DomParser XmlDomParser;

import charge.charge;
import robbers.world;

import robbers.actors.levelinfo;
import robbers.actors.light;
import robbers.actors.playerspawn;
import robbers.actors.primitive;
import robbers.actors.gold;


alias void function(World w, XmlHandle e) LoaderFunc;

class Loader
{
private:
	mixin SysLogging;

	static LoaderFunc[string] map;
	static RegExp pos;
	static RegExp rot;

public:

	static this()
	{
		addLoader("fixedcube", &loadFixedCube);
		addLoader("fixedrigid", &loadFixedRigid);
		addLoader("playerspawn", &loadPlayerSpawn);
		addLoader("goldspawn", &loadGoldSpawn);
		addLoader("levelinfo", &loadLevelInfo);
		addLoader("sunlight", &loadSunLight);
		pos = RegExp(`(\S+)\s+(\S+)\s+(\S+)`);
		rot = RegExp(`(\S+)\s+(\S+)\s+(\S+)\s+(\S+)`);
	}

	static void load(World w, string filename)
	{
		XmlElement level;

		auto f = w.pool.load(filename);
		if (f is null)
			return l.error("could not load %s", filename);
		scope (exit)
			delete f;

		auto p = new XmlDomParser();
		scope (exit)
			delete p;

		try {
			level = p.parseData(cast(string)f.peekMem());
		} catch (XmlException xe) {
			l.error(xe.msg);
			return;
		}

		foreach(XmlElement e; level) {
			auto name = e.value;
			if (name in map)
				map[name](w, XmlHandle(e));
			else
				l.warn(`could not load actor "`, name ,`"`);
		}
	}

	static void loadFixedRigid(World w, XmlHandle e)
	{
		Point3d pos;
		Quatd rot;
		if (!extractPosRot(e, pos, rot)) {
			l.warn("could not extract position and/or rotation from fixed rigid");
			return;
		}

		auto gfx = e.first("phy").first.text;
		auto phy = e.first("phy").first.text;

		if (gfx is null) {
			l.warn("gfx text not found in fixed rigid");
			return;
		}

		if (phy is null) {
			l.warn("phy text not found in fixed rigid");
			return;
		}

		auto fr = new FixedRigid(w, pos, rot, gfx.data, phy.data);
		l.trace("loaded ", fr.classinfo.name);
	}

	static void loadFixedCube(World w, XmlHandle e)
	{
		Point3d pos;
		Point3d size;
		Quatd rot;
		if (!extractPosRot(e, pos, rot)) {
			l.warn("could not extract position and/or rotation from primitive");
			return;
		}

		auto s = e.first("size").first.text;
		if (s !is null) {
			if (!exPoint(s.value, size))
				size = Point3d(1.0, 1.0, 1.0);
		}

		auto fc = new FixedCube(w, pos, rot, size.x, size.y, size.z);
		l.trace("loaded ", fc.classinfo.name);
	}

	static void loadPlayerSpawn(World w, XmlHandle e)
	{
		Point3d pos;
		Quatd rot;
		if (!extractPosRot(e, pos, rot)) {
			l.warn("could not extract position and/or rotation from playerspawn");
			return;
		}

		auto ps = new PlayerSpawn(w, pos, rot);
		l.trace("loaded ", ps.classinfo.name);
	}

	static void loadGoldSpawn(World w, XmlHandle e)
	{
		Point3d pos;
		Quatd rot;
		if (!extractPosRot(e, pos, rot)) {
			l.warn("could not extract position and/or rotation from goldspawn");
			return;
		}

		auto gs = w.gm.newSpawn(pos, rot);
		l.trace("loaded ", gs.classinfo.name);
	}

	static void loadLevelInfo(World w, XmlHandle e)
	{
/*		auto li = new LevelInfo(w); */
	}

	static void loadSunLight(World w, XmlHandle e)
	{
		Point3d pos;
		Quatd rot;
		bool shadow;

		if (!extractPosRot(e, pos, rot)) {
			l.warn("could not extract position and/or rotation from sunlight");
			return;
		}
		auto s = e.first("shadow").first.text;
		if (s !is null)
			exBool(s.value, shadow);			

		auto sl = new SunLight(w, pos, rot, shadow);
		l.trace("loaded ", sl.classinfo.name);
	}

	/*
	 * Utility methods
	 */

	static bool extractPosRot(XmlHandle e, ref Point3d pos, ref Quatd rot)
	{
		auto p = e.first("pos").first.text;
		auto r = e.first("rot").first.text;

		if (p is null || r is null)
			return false;

		if (!exPoint(p.value, pos) || !exRotation(r.value, rot))
			return false;

		return true;
	}

	static bool exPoint(string text, ref Point3d posi)
	{
		Point3d r;
		auto p = pos.exec(text);
		if (p.length < 2)
			return false;

		try {
			r.x = toDouble(p[1]);
			r.y = toDouble(p[2]);
			r.z = toDouble(p[3]);
		} catch (ConvError ce) {
			return false;
		} catch (ConvOverflowError cof) {
			return false;
		}

		posi = r;
		return true;
	}

	static bool exRotation(string text, ref Quatd rota)
	{
		return exRotation4(text, rota) || exRotation3(text, rota);
	}

	static bool exRotation3(string text, ref Quatd rota)
	{
		Quatd r;
		auto p = pos.exec(text);
		if (p.length < 2)
			return false;
		double x, y, z;
		try {
			x = toDouble(p[1]) / 180 * PI;
			y = toDouble(p[2]) / 180 * PI;
			z = toDouble(p[3]) / 180 * PI;
		} catch (ConvError ce) {
			return false;
		} catch (ConvOverflowError cof) {
			return false;
		}

		rota = Quatd(x, y, z);

		return true;
	}

	static bool exRotation4(string text, ref Quatd rota)
	{
		Quatd r;
		auto p = rot.exec(text);
		if (p.length < 2)
			return false;

		try {
			r.w = toDouble(p[1]);
			r.x = toDouble(p[2]);
			r.y = toDouble(p[3]);
			r.z = toDouble(p[4]);
		} catch (ConvError ce) {
			return false;
		} catch (ConvOverflowError cof) {
			return false;
		}

		if (r.sqrdLength == 0.0)
			rota = Quatd();
		else
			rota = r;

		return true;
	}

	static bool exBool(string text, out bool output)
	{
		if (text is null)
			return false;

		if (tolower(text) == "true")
			output = true;

		return true;
	}

	static bool addLoader(string key, LoaderFunc f)
	{
		if (key in map)
			return false;

		map[key] = f;
		return true;
	}

	static bool delLoader(string key)
	{
		if (key in map) {
			map.remove(key);
			return true;
		}

		return false;
	}
	
}
