// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module test.game;

import std.math : pow, fmin, acos, PI;

import charge.charge;

import lib.sdl.sdl;


class Ticker : GameActor, GameTicker
{
protected:
	GfxActor gfx;
	PhyBody phy;

public:
	this(GameWorld w)
	{
		super(w);
		w.addTicker(this);
	}

	~this()
	{
		w.remTicker(this);
		delete gfx;
		delete phy;
	}

	void tick()
	{
		gfx.position = phy.position;
		gfx.rotation = phy.rotation;

		if (phy.position.y < -50) {
			phy.position = Point3d(0.0, 3.0, -6.0);
			phy.rotation = Quatd();
		}
	}

	void force(bool inverse)
	{
		Vector3d vec = Point3d(0.0, 10.0, 0.0) - phy.position;
		vec.normalize();
		vec.scale(9.8);

		if (inverse)
			vec.scale(-1.0);

		phy.addForce(vec);
	}

}

class Cube : Ticker
{
	this(GameWorld w, Point3d pos)
	{
		super(w);

		gfx = GfxRigidModel(w.gfx, "res/cube.bin");
		gfx.position = pos;

		phy = new PhyCube(w.phy, pos);
	}
}

class Sphere : Ticker
{
	this(GameWorld w, Point3d pos)
	{
		super(w);

		gfx = GfxRigidModel(w.gfx, "res/sphere.bin");
		gfx.position = pos;

		phy = new PhySphere(w.phy, pos);
	}
}

class Car : Ticker
{
	this(GameWorld w, Point3d pos)
	{
		super(w);

		gfx = GfxRigidModel(w.gfx, "res/car.bin");
		gfx.position = pos;

		phy = car = new PhyCar(w.phy, pos);

		car.massSetBox(10.0, 2.0, 1.0, 3.0);

		car.collisionBoxAt(Point3d(0, 0.275, 0.075), 2.0, 0.75, 4.75);
		car.collisionBoxAt(Point3d(0, 0.8075, 0.85), 1.3, 0.45, 2.4);

		car.wheel[0].powered = true;
		car.wheel[0].radius = 0.36;
		car.wheel[0].rayLength = 0.76;
		car.wheel[0].rayOffset = Vector3d( 0.82, 0.26, -1.5);
		car.wheel[0].opposit = 1;

		car.wheel[1].powered = true;
		car.wheel[1].radius = 0.36;
		car.wheel[1].rayLength = 0.76;
		car.wheel[1].rayOffset = Vector3d(-0.82, 0.26, -1.5);
		car.wheel[1].opposit = 0;

		car.wheel[2].powered = false;
		car.wheel[2].radius = 0.36;
		car.wheel[2].rayLength = 0.76;
		car.wheel[2].rayOffset = Vector3d( 0.82, 0.26, 1.5);
		car.wheel[2].opposit = 3;

		car.wheel[3].powered = false;
		car.wheel[3].radius = 0.36;
		car.wheel[3].rayLength = 0.76;
		car.wheel[3].rayOffset = Vector3d(-0.82, 0.26, 1.5);
		car.wheel[3].opposit = 2;

		car.carPower = 0;
		car.carDesiredVel = 0;
		car.carBreakingMuFactor = 1.0;
		car.carBreakingMuLimit = 20000;

		car.carSpringMu = 0.01;
		car.carSpringMu2 = 1.5;

		car.carSpringErp = 0.2;
		car.carSpringCfm = 0.03;

		car.carDesiredTurn = 0;
		car.carTurnSpeed = 0;
		car.carTurn = 0;

		car.carSwayFactor = 25.0;
		car.carSwayForceLimit = 20000;

		car.carSlip2Factor = 0.004;
		car.carSlip2Limit = 0.01;

		for (int i; i < 4; i++) {
			wheels[i] = GfxRigidModel(w.gfx, "res/wheel2.bin");
		}
	}

	~this()
	{
		foreach(w; wheels)
			delete w;
	}

	void tick()
	{
		gfx.position = phy.position - (phy.rotation * Vector3d(0.0, 0.2, 0.0));
		gfx.rotation = phy.rotation * Quatd(PI, Vector3d.Up);

		for (int i; i < 4; i++)
			car.setMoveWheel(i, wheels[i]);

		auto v = car.velocity;
		auto l = v.length;
		v.normalize;
		auto a = pow(cast(real)l, cast(uint)2);
		v.scale(-0.01 * a);
		car.addForce(v);

		if (phy.position.y < -50) {
			phy.position = Point3d(0.0, 3.0, -6.0);
			phy.rotation = Quatd();
		}
	}

	GfxCube coll;
	GfxActor wheels[4];
	PhyCar car;
}

class Game : GameSimpleApp
{
private:
	bool moveing;
	double heading;
	double pitch;
	bool force;
	bool inverse;
	bool forward;
	bool backwards;

	SysZipFile basePackage;

	Car car;

	GameWorld w;

	Ticker removable[];

	GfxSimpleLight sl;
	GfxSpotLight spl;
	GfxProjCamera cam;
	GfxRenderer r;
	GfxRigidModel model;

public:
	mixin SysLogging;

	this(string[] args)
	{
		/* This will initalize Core and other important things */
		super();

		basePackage = SysZipFile("base.chz");

		running = true;

		GfxRenderer.init();

		w = new GameWorld();
		sl = new GfxSimpleLight(w.gfx);
		GfxDefaultTarget rt = GfxDefaultTarget();
		cam = new GfxProjCamera(45.0, cast(double)rt.width / rt.height, 1, 150);
		r = GfxRenderer.create();

		cam.position = Point3d(0.0, 5.0, 15.0);
		sl.rotation = Quatd(PI/3, -PI/4, 0.0);//Quatd(PI, Vector3d.Up) * sl.rotation;
		sl.shadow = true;

		auto pl = new GfxPointLight(w.gfx);
		pl.position = Point3d(0.0, 0.0, 0.0);
		pl.size = 20;
		spl = new GfxSpotLight(w.gfx);
		spl.position = Point3d(0.0, 5.0, 15.0);
		spl.far = 150;

		w.phy.setStepLength(10);


		new GameStaticCube(w, Point3d(0.0, -5.0, 0.0), Quatd(), 200.0, 10.0, 200.0);

		new GameStaticRigid(w, Point3d(0.0, 0.0, -15.0), Quatd(), "res/bath.bin", "res/bath.bin");
		heading = 0.0;
		pitch = 0.0;
		l.info("Press 's' 'c' 'f' 'g' for fun");

		car = new Car(w, Point3d(0.0, 3.0, -6.0));
		new Car(w, Point3d(0.0, 3.0, 10.0));
	}

	~this()
	{
		delete basePackage;
		delete w;
	}

protected:
	void addRemovable(Ticker t)
	{
		removable ~= t;
	}

	void input()
	{
		SDL_Event e;

		while(SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) {
				running = false;
			}

			if (e.type == SDL_KEYDOWN) {
				if (e.key.keysym.sym == SDLK_r) {
					car.car.position = Point3d(0.0, 3.0, -6.0);
					car.car.rotation = Quatd();
				}
				if (e.key.keysym.sym == SDLK_f)
					force = true;
				if (e.key.keysym.sym == SDLK_g)
					inverse = true;
				if (e.key.keysym.sym == SDLK_UP)
					forward = true;
				if (e.key.keysym.sym == SDLK_DOWN)
					backwards = true;



				if (e.key.keysym.sym == SDLK_RIGHT) {
					double s = -PI * 0.20;
					car.car.setTurning(s, 0.01);
				}
				if (e.key.keysym.sym == SDLK_LEFT) {
					double s = PI * 0.20;
					car.car.setTurning(s, 0.01);
				}

			}

			if (e.type == SDL_KEYUP) {

				if (e.key.keysym.sym == SDLK_UP)
					forward = false;
				if (e.key.keysym.sym == SDLK_DOWN)
					backwards = false;
				if (e.key.keysym.sym == SDLK_RIGHT) {
					car.car.setTurning(0, 0.15);
				}
				if (e.key.keysym.sym == SDLK_LEFT) {
					car.car.setTurning(0, 0.15);
				}
				if (e.key.keysym.sym == SDLK_f)
					force = false;
				if (e.key.keysym.sym == SDLK_g)
					inverse = false;
				if (e.key.keysym.sym == SDLK_ESCAPE)
					running = false;
				if (e.key.keysym.sym == SDLK_s)
					addRemovable(new Sphere(w, Point3d(0, 1, 0)));
				if (e.key.keysym.sym == SDLK_c)
					addRemovable(new Cube(w, Point3d(0, 1, 0)));
				if (e.key.keysym.sym == SDLK_p) {
					addRemovable(new Cube(w, Point3d( 4, 1, 0)));
					addRemovable(new Cube(w, Point3d( 3, 1, 0)));
					addRemovable(new Cube(w, Point3d( 2, 1, 0)));
					addRemovable(new Cube(w, Point3d( 1, 1, 0)));
					addRemovable(new Cube(w, Point3d( 0, 1, 0)));
					addRemovable(new Cube(w, Point3d(-1, 1, 0)));
					addRemovable(new Cube(w, Point3d(-2, 1, 0)));
					addRemovable(new Cube(w, Point3d(-3, 1, 0)));
					addRemovable(new Cube(w, Point3d(-4, 1, 0)));

					addRemovable(new Cube(w, Point3d( 3.5, 2, 0)));
					addRemovable(new Cube(w, Point3d( 2.5, 2, 0)));
					addRemovable(new Cube(w, Point3d( 1.5, 2, 0)));
					addRemovable(new Cube(w, Point3d( 0.5, 2, 0)));
					addRemovable(new Cube(w, Point3d(-0.5, 2, 0)));
					addRemovable(new Cube(w, Point3d(-1.5, 2, 0)));
					addRemovable(new Cube(w, Point3d(-2.5, 2, 0)));
					addRemovable(new Cube(w, Point3d(-3.5, 2, 0)));

					addRemovable(new Cube(w, Point3d( 3, 3, 0)));
					addRemovable(new Cube(w, Point3d( 2, 3, 0)));
					addRemovable(new Cube(w, Point3d( 1, 3, 0)));
					addRemovable(new Cube(w, Point3d( 0, 3, 0)));
					addRemovable(new Cube(w, Point3d(-1, 3, 0)));
					addRemovable(new Cube(w, Point3d(-2, 3, 0)));
					addRemovable(new Cube(w, Point3d(-3, 3, 0)));

					addRemovable(new Cube(w, Point3d( 2.5, 4, 0)));
					addRemovable(new Cube(w, Point3d( 1.5, 4, 0)));
					addRemovable(new Cube(w, Point3d( 0.5, 4, 0)));
					addRemovable(new Cube(w, Point3d(-0.5, 4, 0)));
					addRemovable(new Cube(w, Point3d(-1.5, 4, 0)));
					addRemovable(new Cube(w, Point3d(-2.5, 4, 0)));

					addRemovable(new Cube(w, Point3d( 2, 5, 0)));
					addRemovable(new Cube(w, Point3d( 1, 5, 0)));
					addRemovable(new Cube(w, Point3d( 0, 5, 0)));
					addRemovable(new Cube(w, Point3d(-1, 5, 0)));
					addRemovable(new Cube(w, Point3d(-2, 5, 0)));

					addRemovable(new Cube(w, Point3d( 1.5, 6, 0)));
					addRemovable(new Cube(w, Point3d( 0.5, 6, 0)));
					addRemovable(new Cube(w, Point3d(-0.5, 6, 0)));
					addRemovable(new Cube(w, Point3d(-1.5, 6, 0)));

					addRemovable(new Cube(w, Point3d( 1, 7, 0)));
					addRemovable(new Cube(w, Point3d( 0, 7, 0)));
					addRemovable(new Cube(w, Point3d(-1, 7, 0)));

					addRemovable(new Cube(w, Point3d( 0.5, 8, 0)));
					addRemovable(new Cube(w, Point3d(-0.5, 8, 0)));

					addRemovable(new Cube(w, Point3d( 0, 9, 0)));
				}
				if (e.key.keysym.sym == SDLK_o) {
					foreach(r; removable)
						delete r;
					removable.length = 0;
				}
			}

			if (e.type == SDL_MOUSEMOTION && moveing) {
				double xrel = e.motion.xrel;
				double yrel = e.motion.yrel;
				heading += xrel / 1000.0;
				pitch += yrel / 1000.0;
				cam.rotation = Quatd(heading, 0, pitch);
			}

			if (e.type == SDL_MOUSEBUTTONDOWN && e.button.button == 1)
				moveing = true;

			if (e.type == SDL_MOUSEBUTTONUP && e.button.button == 1)
				moveing = false;
		}

	}

	void logic()
	{
		w.tick();

		if (force || inverse)
			foreach(a; w.actors) {
				auto ticker = cast(Ticker)a;
				if (ticker !is null)
					ticker.force(inverse);
			}

		if (forward && !backwards)
			car.car.setAllWheelPower(100.0, 40.0);
		else if (!forward && backwards)
			car.car.setAllWheelPower(-10.0, 40.0);
		else
			car.car.setAllWheelPower(0.0, 0.0);

		spl.position = car.car.position;
		spl.rotation = car.car.rotation;
		auto v = car.car.rotation.rotateHeading;
		v.y = 0;
		v.normalize();
		v.scale(-10.0);
		v.y = 3.0;
		v = (car.car.position + v) - cam.position;
		double scale = v.lengthSqrd * 0.002 + v.length * 0.04;
		scale = fmin(v.length, scale);
		v.normalize();
		v.scale(scale);
		cam.position = cam.position + v;

		auto v2 = car.car.position - cam.position;
		v2.y = 0;
		v2.normalize();
		auto angle = acos(Vector3d.Heading.dot(v2));

		/* since we actualy don't do a cross to get the axis */
		if (v2.x > 0)
			angle = -angle;

		cam.rotation = Quatd(angle, Vector3d.Up);
	}

	void render()
	{
		GfxDefaultTarget rt = GfxDefaultTarget();
		rt.clear();
		r.target = rt;
		r.render(cam, w.gfx);
		rt.swap();
	}

	void network()
	{
	}

	void close()
	{
	}

}
