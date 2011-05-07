// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.runner;

import std.math;
import lib.sdl.sdl;

import charge.charge;

import minecraft.world;
import minecraft.terrain.chunk;
import minecraft.terrain.vol;

/**
 * Inbuilt GameLogic handler
 */
class GameLogic
{
public:
	World w;

	/* Light related */
	GfxSimpleLight sl;
	double light_heading;
	double light_pitch;
	bool light_moveing;

	/* Camera related */
	GfxCamera cam;
	GameMover m;
	double cam_heading;
	double cam_pitch;
	bool cam_moveing;

private:
	mixin SysLogging;

public:
	this(World w)
	{
		this.w = w;

		GfxDefaultTarget rt = GfxDefaultTarget();
		cam = new GfxProjCamera(45.0, cast(double)rt.width / rt.height, .1, 250);
		m = new GameProjCameraMover(cam);
		cam.position = Point3d(0.0, 5.0, 15.0);
		cam_heading = 0.0;
		cam_pitch = 0.0;

		//cam = new GfxIsoCamera(800/16f, 600/16f, -200, 200);
		//m = new GameIsoCameraMover(cam);

		sl = new GfxSimpleLight();
		// Night
		//sl.diffuse = Color4f(0.0/255, 3.0/255, 30.0/255);
		//sl.ambient = Color4f(0.0/255, 3.0/255, 30.0/255);

		// Day
		sl.diffuse = Color4f(200.0/255, 200.0/255, 200.0/255);
		sl.ambient = Color4f(65.0/255, 65.0/255, 65.0/255);
		sl.shadow = true;

		// Test
		//sl.diffuse = Color4f(1.0, 1.0, 1.0);
		//sl.ambient = Color4f(0.0, 0.0, 0.0);

		light_heading = PI/3;
		light_pitch = -PI/6;
		sl.rotation = Quatd(light_heading, light_pitch, 0);
		w.gfx.add(sl);

		w.gfx.fog = new GfxFog();
		w.gfx.fog.start = 150;
		w.gfx.fog.stop = 250;
		w.gfx.fog.color = Color4f(89.0/255, 178.0/255, 220.0/255);

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
		delete sl;
		delete cam;
		delete m;

		auto kb = CtlInput().keyboard;
		kb.up.disconnect(&this.keyUp);
		kb.down.disconnect(&this.keyDown);

		auto m = CtlInput().mouse;
		m.up.disconnect(&this.mouseUp);
		m.down.disconnect(&this.mouseDown);
		m.move.disconnect(&this.mouseMove);
	}

	void keyDown(CtlKeyboard kb, int sym)
	{
		switch(sym) {
		case SDLK_v:
			sl.shadow = !sl.shadow;
			break;
		case SDLK_w:
			m.forward = true;
			break;
		case SDLK_s:
			m.backward = true;
			break;
		case SDLK_a:
			m.left = true;
			break;
		case SDLK_d:
			m.right = true;
			break;
		case SDLK_LSHIFT:
			m.speed = true;
			break;
		case SDLK_SPACE:
			m.up = true;
			break;
		default:
		}
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		switch(sym) {
		case SDLK_w:
			m.forward = false;
			break;
		case SDLK_s:
			m.backward = false;
			break;
		case SDLK_a:
			m.left = false;
			break;
		case SDLK_d:
			m.right = false;
			break;
		case SDLK_LSHIFT:
			m.speed = false;
			break;
		case SDLK_SPACE:
			m.up = false;
			break;
		case SDLK_o:
			Core().screenShot();
			break;
		case SDLK_b:
			w.rm.aa = !w.rm.aa;
			break;
		case SDLK_r:
			w.switchRenderer();
			break;
		case SDLK_v:
			sl.shadow = !sl.shadow;
			break;
		default:
		}
	}

	void mouseMove(CtlMouse mouse, int ixrel, int iyrel)
	{
		if (cam_moveing) {
			double xrel = ixrel;
			double yrel = iyrel;
			cam_heading += xrel / 500.0;
			cam_pitch += yrel / 500.0;
			cam.rotation = Quatd(cam_heading, cam_pitch, 0);
		}

		if (light_moveing) {
			double xrel = ixrel;
			double yrel = iyrel;
			light_heading += xrel / 500.0;
			light_pitch += yrel / 500.0;
			sl.rotation = Quatd(light_heading, light_pitch, 0);
		}
	}

	void mouseDown(CtlMouse m, int button)
	{
		if (button == 1)
			cam_moveing = true;
		if (button == 3)
			light_moveing = true;
	}

	void mouseUp(CtlMouse m, int button)
	{
		if (button == 1)
			cam_moveing = false;
		if (button == 3)
			light_moveing = false;
	}

	void logic()
	{
		m.tick();
	}
}
