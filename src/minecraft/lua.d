module minecraft.lua;

import std.file;

import charge.charge;
import charge.game.lua;

import minecraft.world;
import minecraft.terrain.vol;
import minecraft.terrain.chunk;

/*
 *
 * Simple actors
 *
 */

class Camera : public GameActor
{
public:
	GfxProjCamera c;

public:
	this(World w)
	{
		super(w);
		c = new GfxProjCamera();
	}

	~this()
	{

	}

	void setPosition(ref Point3d pos) { c.setPosition(pos); }
	void getPosition(out Point3d pos) { c.getPosition(pos); }
	void setRotation(ref Quatd rot) { c.setRotation(rot); }
	void getRotation(out Quatd rot) { c.getRotation(rot); }
}

class SunLight : public GameActor
{
private:
	GfxSimpleLight gfx;

public:
	this(World w)
	{
		super(w);
		gfx = new GfxSimpleLight();
		w.gfx.add(gfx);
	}

	~this()
	{
		delete gfx;
	}


	void setPosition(ref Point3d pos) { gfx.setPosition(pos); }
	void getPosition(out Point3d pos) { gfx.getPosition(pos); }
	void setRotation(ref Quatd rot) { gfx.setRotation(rot); }
	void getRotation(out Quatd rot) { gfx.getRotation(rot); }
}


class ScriptRunner
{
public:
	World w;
	LuaState s;
	SunLight sl;
	Camera c;

private:
	mixin SysLogging;

public:
	this(World w, char[] filename)
	{
		this.w = w;

		if (!exists(filename)) {
			l.warn("No such file (%s) (this is not a error)", filename);
			throw new Exception("Error initalizing lua script");
		}

		// Create a lua state
		s = new LuaState();
		// Push standard libraries
		s.openLibs();

		// Registers classes
		Color4fWrapper.register(s);
		Vector3dWrapper.register(s);
		Point3dWrapper.register(s);
		QuatdWrapper.register(s);
		WorldWrapper.register(s);
		CameraWrapper.register(s);
		SunLightWrapper.register(s);

		setNil("World");
		setNil("Game");
		setNil("Camera");
		setNil("SunLight");

		auto ret = s.loadFile(filename);
		if (ret == 3) {
			l.warn("loadFile failed \n",
			       s.toString(-3), "\n",
			       s.toString(-2), "\n",
			       s.toString(-1), "\n");
			throw new Exception("Error initalizing lua script");
		}

		sl = new SunLight(w);
		c = new Camera(w);

		s.pushStringz("world");
		s.pushClass(w);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		s.pushStringz("camera");
		s.pushClass(c);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		s.pushStringz("light");
		s.pushClass(sl);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		ret = s.call();
		if (ret == 2) {
			l.warn("call failed\n", s.toString(-1));
			throw new Exception("Error initalizing lua script");
		}

		auto kb = CtlInput().keyboard;
		kb.up ~= &this.keyUp;
		kb.down ~= &this.keyDown;

		auto m = CtlInput().mouse;
		m.up ~= &this.mouseUp;
		m.down ~= &this.mouseDown;
		m.move ~= &this.mouseMove;
	}

	~this()
	{
		auto kb = CtlInput().keyboard;
		kb.up.disconnect(&this.keyUp);
		kb.down.disconnect(&this.keyDown);

		auto m = CtlInput().mouse;
		m.up.disconnect(&this.mouseUp);
		m.down.disconnect(&this.mouseDown);
		m.move.disconnect(&this.mouseMove);

		delete s;
		delete c;
		delete sl;
	}

	void logic()
	{
		s.getGlobalz("logic");
		if (s.call() == 2) {
			l.warn(s.toString(-1));
		}
	}

	void render()
	{
		s.getGlobalz("render");
		if (s.call() == 2) {
			l.warn(s.toString(-1));
		}

	}

protected:
	void setNil(char* str)
	{
		s.pushStringz(str);
		s.pushNil();
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		s.getGlobalz("keyUp");
		s.pushNumber(sym);

		if (s.call(1) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void keyDown(CtlKeyboard kb, int sym)
	{
		s.getGlobalz("keyDown");
		s.pushNumber(sym);

		if (s.call(1) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void mouseUp(CtlMouse m, int button)
	{
		s.getGlobalz("mouseUp");
		s.pushNumber(button);

		if (s.call(1) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void mouseDown(CtlMouse m, int button)
	{
		s.getGlobalz("mouseDown");
		s.pushNumber(button);

		if (s.call(1) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void mouseMove(CtlMouse mouse, int xrel, int yrel)
	{
		s.getGlobalz("mouseMove");
		s.pushNumber(xrel);
		s.pushNumber(yrel);

		if (s.call(2) == 2) {
			l.warn(s.toString(-1));
		}
	}
}



struct WorldWrapper
{
	const static char *namez = "d_class_minecraft_world_World";
	const static char[] name = "d_class_minecraft_world_World";

	extern (C) static int newWorld(lua_State *l)
	{
		auto s = LuaState(l);
		World w;

		try {
			// TODO
			//w = new World(level, g.rm);
			throw new Exception("Not implemented this new World yet");
		} catch (Exception e) {
			s.error(e);
		}

		s.pushClass(w);
		return 1;
	}

	extern (C) static int switchRenderer(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(World)(1, false);

		try {
			w.switchRenderer();
		} catch (Exception e) {
			s.error(e);
		}

		return 0;
	}

	extern (C) static int toggleAA(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(World)(1, false);

		try {
			w.rm.aa = !w.rm.aa;
		} catch (Exception e) {
			s.error(e);
		}

		s.pushBool(w.rm.aa);
		return 1;
	}

	extern (C) static int screenshot(lua_State *l)
	{
		auto s = LuaState(l);

		try {
			Core().screenShot();
		} catch (Exception e) {
			s.error(e);
		}

		return 1;
	}

	static void register(LuaState s)
	{
		s.registerClass!(World);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&switchRenderer);
		s.setFieldz(-2, "switchRenderer");
		s.pushCFunction(&toggleAA);
		s.setFieldz(-2, "toggleAA");
		s.pushCFunction(&screenshot);
		s.setFieldz(-2, "screenshot");
		s.pop();

		s.pushString("World");
		s.pushCFunction(&newWorld);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}
}

struct CameraWrapper
{
	const static char *namez = "d_class_minecraft_lua_Camera";
	const static char[] name = "d_class_minecraft_lua_Camera";

	extern (C) static int newCamera(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(World)(1, false);
		Camera c;

		try
			c = new Camera(w);
		catch (Exception e)
			s.error(e);

		s.pushClass(c);
		return 1;
	}

	static void register(LuaState s)
	{
		s.registerClass!(Camera);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&MovableWrapper.index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&MovableWrapper.newIndex);
		s.setFieldz(-2, "__newindex");
		s.pop();

		s.pushString("Camera");
		s.pushCFunction(&newCamera);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}
}

struct SunLightWrapper
{
	const static char *namez = "d_class_minecraft_lua_SunLight";
	const static char[] name = "d_class_minecraft_lua_SunLight";

	extern (C) static int newSunLight(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(World)(1, false);
		SunLight sl;

		try
			sl = new SunLight(w);
		catch (Exception e)
			s.error(e);

		s.pushClass(sl);
		return 1;
	}

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto sl = s.checkClass!(SunLight)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "position":
			sl.gfx.getPosition(*Point3dWrapper.push(s));
			break;
		case "rotation":
			sl.gfx.getRotation(*QuatdWrapper.push(s));
			break;
		case "diffuse":
			s.pushColor4f(sl.gfx.diffuse);
			break;
		case "ambient":
			s.pushColor4f(sl.gfx.ambient);
			break;
		case "shadow":
			s.pushBool(sl.gfx.shadow);
			break;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int newIndex(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto sl = s.checkClass!(SunLight)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "position":
			auto p = Point3dWrapper.check(s, 3);
			try {
				sl.gfx.setPosition(*p);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		case "rotation":
			auto q = QuatdWrapper.check(s, 3);
			try {
				sl.gfx.setRotation(*q);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		case "diffuse":
			auto color = 
			sl.gfx.diffuse = *s.checkColor4f(3);
			break;
		case "ambient":
			sl.gfx.ambient = *s.checkColor4f(3);
			break;
		case "shadow":
			sl.gfx.shadow = s.toBool(3);
			break;
		default:
			s.error("No memeber of that that name");
			break;
		}

		return 0;
	}

	static void register(LuaState s)
	{
		s.registerClass!(SunLight);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&newIndex);
		s.setFieldz(-2, "__newindex");
		s.pop();

		s.pushString("SunLight");
		s.pushCFunction(&newSunLight);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}
}
