// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module test.frustum;

import std.math : tan, PI_4;

import lib.sdl.sdl;

import charge.charge;

import charge.math.mesh;
import charge.math.frustum;
import charge.math.matrix4x4d;

import charge.gfx.gl;
static import charge.gfx.vbo;
alias charge.gfx.vbo.RigidMeshVBO GfxVBO;


class Game : GameSimpleApp
{
private:
	double heading;
	double pitch;
	bool moveing;

	GameWorld w;

	GfxProjCamera cam;
	GfxCamera view_cam;
	GfxDefaultTarget rt;
	GameMover m;
	GfxVBO sphere;

public:
	mixin SysLogging;

	this(string[] args)
	{
		/* This will initalize Core and other important things */
		super();

		GfxRenderer.init();
		
		rt = GfxDefaultTarget();

		w = new GameWorld();
		view_cam = new GfxProjCamera(45.0, cast(double)rt.width / rt.height, 1, 1000);
		m = new GameProjCameraMover(view_cam);
		view_cam.position = Point3d(0.0, 0.0, 5.0);
		heading = 0.0;
		pitch = 0.0;

		cam = new GfxProjCamera(45.0, cast(double)rt.width / rt.height, 1, 500);

		sphere = GfxVBO("res/sphere.bin");
	}

	~this()
	{
	}

protected:
	void input()
	{
		SDL_Event e;

		while(SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) {
				running = false;
			}

			if (e.type == SDL_KEYDOWN) {
				if (e.key.keysym.sym == SDLK_ESCAPE)
					running = false;
				if (e.key.keysym.sym == SDLK_w)
					m.forward = true;
				if (e.key.keysym.sym == SDLK_s)
					m.backward = true;
				if (e.key.keysym.sym == SDLK_a)
					m.left = true;
				if (e.key.keysym.sym == SDLK_d)
					m.right = true;
				if (e.key.keysym.sym == SDLK_LSHIFT)
					m.speed = true;
				if (e.key.keysym.sym == SDLK_SPACE)
					m.up = true;
			}

			if (e.type == SDL_KEYUP) {
				if (e.key.keysym.sym == SDLK_w)
					m.forward = false;
				if (e.key.keysym.sym == SDLK_s)
					m.backward = false;
				if (e.key.keysym.sym == SDLK_a)
					m.left = false;
				if (e.key.keysym.sym == SDLK_d)
					m.right = false;
				if (e.key.keysym.sym == SDLK_LSHIFT)
					m.speed = false;
				if (e.key.keysym.sym == SDLK_SPACE)
					m.up = false;
			}

			if (e.type == SDL_MOUSEMOTION && moveing) {
				double xrel = e.motion.xrel;
				double yrel = e.motion.yrel;
				heading += xrel / 500.0;
				pitch += yrel / 500.0;
				view_cam.rotation = Quatd(heading, pitch, 0);
			}

			if (e.type == SDL_MOUSEBUTTONDOWN && e.button.button == 1)
				moveing = true;

			if (e.type == SDL_MOUSEBUTTONUP && e.button.button == 1)
				moveing = false;
		}

	}

	void logic()
	{
		m.tick();
	}


	void getSphere(double fov, double ratio, double near, double far, out Point3d center, out double radius)
	{
		double near_height = tan(fov / 2.0) * near;
		double near_width = near_height * ratio;
		double far_height = tan(fov / 2.0) * far;
		double far_width = far_height * ratio;

		double a, b, c, d, e, f;
		a = near_width;
		b = near_height;
		c = near;
		d = far_width;
		e = far_height;
		f = far;
		double Z = (d*d + e*e + f*f - a*a - b*b - c*c) / (f - c);
		Z = Z / 2;

		double size = (Point3d(0.0, 0.0, Z) - Point3d(near_width, near_height, near)).length;
		double size2 = (Point3d(0.0, 0.0, Z) - Point3d(far_width, far_height, far)).length;
		//writefln("%s - %s = %s", size, size2, size - size2);

		center = Point3d(0.0, 0.0, Z);
		radius = size;
	}

	void getPoints(double fov, double ratio, double near, double far, Point3d[] p)
	{
		Matrix4x4d mat;
		Matrix4x4d proj;
		Point3d center;
		double radius;
		getSphere(fov, ratio, far, near, center, radius);
		auto rot = Quatd(PI_4, Vector3d(1.0, 0.0, 0.0));
		auto pos = center;
		auto point = pos + rot.rotateHeading();
		auto up = rot.rotateUp();

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-radius, radius, -radius, radius, 4*radius, -radius);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		gluLookAt(pos.x, pos.y, pos.z,
		          point.x, point.y, point.z,
		          up.x, up.y, up.z);

		glMatrixMode(GL_PROJECTION);
		glGetDoublev(GL_MODELVIEW_MATRIX, mat.array.ptr);
		glMultMatrixd(mat.array.ptr);
		glGetDoublev(GL_PROJECTION_MATRIX, mat.array.ptr);
		mat.transpose();
		mat.inverse();
		p[0] = mat * Point3d( 1,  1, -1);
		p[1] = mat * Point3d(-1,  1, -1);
		p[2] = mat * Point3d(-1, -1, -1);
		p[3] = mat * Point3d( 1, -1, -1);
		p[4] = mat * Point3d( 1,  1,  1);
		p[5] = mat * Point3d(-1,  1,  1);
		p[6] = mat * Point3d(-1, -1,  1);
		p[7] = mat * Point3d( 1, -1,  1);
	}

	void render()
	{
		Point3d p[8];

		double near = 1;
		double far = 500;
		double fov = PI_4;
		double ratio = 800/600;

		double near_height = tan(fov / 2.0) * near;
		double near_width = near_height * ratio;
		double far_height = tan(fov / 2.0) * far;
		double far_width = far_height * ratio;


		p[0] = Point3d( near_width,  near_height, near);
		p[1] = Point3d(-near_width,  near_height, near);
		p[2] = Point3d(-near_width, -near_height, near);
		p[3] = Point3d( near_width, -near_height, near);

		p[4] = Point3d( far_width,  far_height, far);
		p[5] = Point3d(-far_width,  far_height, far);
		p[6] = Point3d(-far_width, -far_height, far);
		p[7] = Point3d( far_width, -far_height, far);

		getPoints(fov, ratio, 40, 100, p);

		rt.clear();

		view_cam.transform();

		glBegin(GL_QUADS);
		glColor3d(1.0, 1.0, 1.0);
		glVertex3dv(&p[0].x);
		glVertex3dv(&p[1].x);
		glVertex3dv(&p[2].x);
		glVertex3dv(&p[3].x);

		glColor3d(0.6, 0.6, 0.6);
		glVertex3dv(&p[0].x);
		glVertex3dv(&p[1].x);
		glVertex3dv(&p[5].x);
		glVertex3dv(&p[4].x);

		glColor3d(0.8, 0.8, 0.8);
		glVertex3dv(&p[1].x);
		glVertex3dv(&p[2].x);
		glVertex3dv(&p[6].x);
		glVertex3dv(&p[5].x);
		glEnd();

		glEnable(GL_CULL_FACE);
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE);
		Point3d center;
		double size;

		glPushMatrix();
		getSphere(fov, ratio, 1.0, 40.0, center, size);
		glTranslated(center.x, center.y, center.z);
		glScaled(size*2, size*2, size*2);
		glColor4d(1.0, 0.2, 0.2, 0.5);
		sphere.drawFixed();
		glPopMatrix();

		glPushMatrix();
		getSphere(fov, ratio, 40.0, 100.0, center, size);
		glTranslated(center.x, center.y, center.z);
		glScaled(size*2, size*2, size*2);
		glColor4d(0.2, 1.0, 0.2, 0.5);
		sphere.drawFixed();
		glPopMatrix();

		glPushMatrix();
		getSphere(fov, ratio, 100.0, 500.0, center, size);
		glTranslated(center.x, center.y, center.z);
		glScaled(size*2, size*2, size*2);
		glColor4d(0.2, 0.2, 1.0, 0.5);
		sphere.drawFixed();
		glPopMatrix();

		glDisable(GL_BLEND);
		glDisable(GL_CULL_FACE);

		rt.swap();
	}

	void network()
	{
	}

	void close()
	{
	}

}
