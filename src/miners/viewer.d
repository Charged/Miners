// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.viewer;

import std.math : PI, PI_2;

import lib.sdl.keysym;

import charge.charge;

import miners.world;
import miners.runner;
import miners.options;
import miners.interfaces;
import miners.actors.camera;
import miners.actors.sunlight;
import miners.actors.otherplayer;


/**
 * Inbuilt ViewerRunner
 */
class ViewerRunner : GameRunnerBase
{
public:
	/* Light related */
	SunLight sl;
	double light_heading;
	double light_pitch;
	bool light_moveing;


	/* Camera related */
	Camera cam;
	GameMover m;
	double cam_heading;
	double cam_pitch;
	bool cam_moveing;

private:
	mixin SysLogging;

public:
	this(Router r, Options opts, World w)
	{
		super(r, opts, w);

		GfxDefaultTarget rt = GfxDefaultTarget();

		centerer = cam = new Camera(w);
		cam.position = w.spawn + Vector3d(0.5, 1.5, 0.5);

		m = new GameProjCameraMover(cam);
		cam_heading = 0.0;
		cam_pitch = 0.0;

		centerMap();

		sl = new SunLight(w);

		// Night
		//sl.gfx.diffuse = Color4f(0.0/255, 3.0/255, 30.0/255);
		//sl.gfx.ambient = Color4f(0.0/255, 3.0/255, 30.0/255);

		// Day
		sl.gfx.diffuse = Color4f(200.0/255, 200.0/255, 200.0/255);
		sl.gfx.ambient = Color4f(65.0/255, 65.0/255, 65.0/255);

		// Test
		//sl.gfx.diffuse = Color4f(1.0, 1.0, 1.0);
		//sl.gfx.ambient = Color4f(0.0, 0.0, 0.0);

		light_heading = PI/3;
		light_pitch = -PI/6;
		sl.rotation = Quatd(light_heading, light_pitch, 0);
	}

	~this()
	{
		assert(cam is null);
		assert(sl is null);
		assert(m is null);
		assert(w is null);
	}

	void close()
	{
		delete cam;
		delete sl;
		delete m;
		delete w;

		super.close();
	}

	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		switch(sym) {
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
		case SDLK_ESCAPE:
			r.displayPauseMenu();
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
		case SDLK_g:
			if (!kb.ctrl)
				break;
			grab = !grab;
			break;
		case SDLK_o:
			Core().screenShot();
			break;
		case SDLK_b:
			opts.aa.toggle;
			break;
		case SDLK_y:
			opts.fog.toggle;
			break;
		case SDLK_r:
			opts.changeRenderer();
			break;
		case SDLK_v:
			opts.shadow.toggle;
			break;
		case SDLK_F2:
			opts.hideUi.toggle;
			break;
		case SDLK_F3:
			opts.showDebug.toggle;
			break;
		default:
		}
	}

	void mouseMove(CtlMouse mouse, int ixrel, int iyrel)
	{
		if (cam_moveing || (grabbed && !light_moveing)) {
			double xrel = ixrel;
			double yrel = iyrel;

			if (grabbed) {
				cam_heading += xrel / -500.0;
				cam_pitch += yrel / -500.0;
			} else {
				cam_heading += xrel / 500.0;
				cam_pitch += yrel / 500.0;
			}

			if (cam_pitch < -PI_2) cam_pitch = -PI_2;
			if (cam_pitch >  PI_2) cam_pitch =  PI_2;

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
		super.logic();
	}

	void render(GfxRenderTarget rt)
	{
		cam.resize(rt.width, rt.height);
		r.render(w.gfx, cam.current, rt);
	}

}
