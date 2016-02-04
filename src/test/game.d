// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module test.game;

import std.math : pow, fmin, acos, PI;

import charge.charge;

import lib.sdl.sdl;


class BaseActor : GamePrimitive
{
public:
	this(GameWorld w, Point3d pos, Quatd rot, GfxActor gfx, PhyBody phy)
	{
		super(w, pos, rot, gfx, phy);
	}

	~this()
	{
		assert(gfx is null);
		assert(phy is null);
	}

	override void tick()
	{
		super.tick();
		if (phy.position.y < -50) {
			position = Point3d(0.0, 3.0, -6.0);
			rotation = Quatd();
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

class Cube : BaseActor
{
	this(GameWorld w, Point3d pos)
	{
		super(w, pos, Quatd(), GfxRigidModel(w.gfx, "res/cube.bin"), new PhyCube(w.phy));
	}
}

class Sphere : BaseActor
{
	this(GameWorld w, Point3d pos)
	{
		super(w, pos, Quatd(), GfxRigidModel(w.gfx, "res/sphere.bin"), new PhySphere(w.phy, pos));
	}
}

class Car : GameCar
{
	this(GameWorld w, Point3d pos)
	{
		super(w);
		position = pos;

		car.carBreakingMuFactor = 1.0;
		car.carBreakingMuLimit = 20000;

		car.carSpringMu = 0.01;
		car.carSpringMu2 = 1.5;
		car.carSpringErp = 0.2;
		car.carSpringCfm = 0.03;

		car.carSwayFactor = 25.0;
		car.carSwayForceLimit = 20000;

		car.carSlip2Factor = 0.004;
		car.carSlip2Limit = 0.01;
	}

	override void tick()
	{
		super.tick();
		if (position.y < -50) {
			position = Point3d(0.0, 3.0, -6.0);
			rotation = Quatd();
		}
	}
}

class Game : GameSimpleApp
{
private:
	bool moveing;
	double heading;
	double pitch;
	bool force;
	bool inverse;

	SysPool pool;
	SysZipFile basePackage;

	Car car;

	GameWorld w;

	BaseActor[] removable;

	GfxSimpleLight sl;
	GfxSpotLight spl;
	GfxProjCamera cam;
	GfxRenderer r;

public:
	mixin SysLogging;

	this(string[] args)
	{
		/* This will initalize Core and other important things */
		super();

		if (!phyLoaded)
			throw new Exception("Physics was not loaded missing ODE library?");

		basePackage = SysZipFile("base.chz");
		if (basePackage is null)
			throw new Exception("Could not find base.chz file");
		pool = new SysPool(SysPool(), [basePackage]);

		w = new GameWorld(pool);
		sl = new GfxSimpleLight(w.gfx);
		GfxDefaultTarget rt = GfxDefaultTarget();
		cam = new GfxProjCamera(45.0, cast(double)rt.width / rt.height, 1, 150);
		r = GfxRenderer.create();

		cam.position = Point3d(0.0, 5.0, 15.0);
		sl.rotation = Quatd(PI/3, -PI/4, 0.0);
		sl.shadow = true;

		auto pl = new GfxPointLight(w.gfx);
		pl.position = Point3d(0.0, 0.0, 0.0);
		pl.size = 20;
		spl = new GfxSpotLight(w.gfx);
		spl.position = Point3d(0.0, 5.0, 15.0);
		spl.far = 150;

		new GameStaticCube(w, Point3d(0.0, -5.0, 0.0), Quatd(), 200.0, 10.0, 200.0);

		new GameStaticRigid(w, Point3d(0.0, 0.0, -15.0), Quatd(), "res/bath.bin", "res/bath.bin");
		heading = 0.0;
		pitch = 0.0;
		l.info("Press 's' 'c' 'f' 'g' for fun");

		car = new Car(w, Point3d(0.0, 3.0, -6.0));
		new Car(w, Point3d(0.0, 3.0, 10.0));

		keyboard.up ~= &this.keyUp;
		keyboard.down ~= &this.keyDown;

		mouse.up ~= &this.mouseUp;
		mouse.down ~= &this.mouseDown;
		mouse.move ~= &this.mouseMove;
	}

	~this()
	{
	}

	override void close()
	{
		keyboard.up.disconnect(&this.keyUp);
		keyboard.down.disconnect(&this.keyDown);

		mouse.up.disconnect(&this.mouseUp);
		mouse.down.disconnect(&this.mouseDown);
		mouse.move.disconnect(&this.mouseMove);

		breakApartAndNull(sl);
		breakApartAndNull(spl);
		breakApartAndNull(cam);
		breakApartAndNull(w);
		delete r;
		super.close();
		pool.clean();
	}

protected:
	void addRemovable(BaseActor t)
	{
		removable ~= t;
	}

	override void logic()
	{
		w.tick();

		if (force || inverse) {
			foreach(a; w.actors) {
				auto ticker = cast(BaseActor)a;
				if (ticker !is null)
					ticker.force(inverse);
			}
		}

		spl.position = car.position;
		spl.rotation = car.rotation;
		auto v = car.rotation.rotateHeading;
		v.y = 0;
		v.normalize();
		v.scale(-10.0);
		v.y = 3.0;
		v = (car.position + v) - cam.position;
		double scale = v.lengthSqrd * 0.002 + v.length * 0.04;
		scale = fmin(v.length, scale);
		v.normalize();
		v.scale(scale);
		cam.position = cam.position + v;

		auto v2 = car.position - cam.position;
		v2.y = 0;
		v2.normalize();
		auto angle = acos(Vector3d.Heading.dot(v2));

		/* since we actualy don't do a cross to get the axis */
		if (v2.x > 0)
			angle = -angle;

		cam.rotation = Quatd(angle, Vector3d.Up);
	}

	override void render()
	{
		GfxDefaultTarget rt = GfxDefaultTarget();
		rt.clear();
		r.target = rt;
		r.render(cam, w.gfx);
		rt.swap();
	}

	override void network()
	{
	}

	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		switch(sym) {
		case SDLK_r:
			car.position = Point3d(0.0, 3.0, -6.0);
			car.rotation = Quatd();
			break;
		case SDLK_f:
			force = true;
			break;
		case SDLK_g:
			inverse = true;
			break;
		case SDLK_UP:
			car.move(GameCar.Forward, true);
			break;
		case SDLK_DOWN:
			car.move(GameCar.Backward, true);
			break;
		case SDLK_RIGHT:
			car.move(GameCar.Right, true);
			break;
		case SDLK_LEFT:
			car.move(GameCar.Left, true);
			break;
		default:
		}
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		switch(sym) {
		case SDLK_UP:
			car.move(GameCar.Forward, false);
			break;
		case SDLK_DOWN:
			car.move(GameCar.Backward, false);
			break;
		case SDLK_RIGHT:
			car.move(GameCar.Right, false);
			break;
		case SDLK_LEFT:
			car.move(GameCar.Left, false);
			break;
		case SDLK_f:
			force = false;
			break;
		case SDLK_g:
			inverse = false;
			break;
		case SDLK_ESCAPE:
			running = false;
			break;
		case SDLK_s:
			addRemovable(new Sphere(w, Point3d(0, 1, 0)));
			break;
		case SDLK_c:
			addRemovable(new Cube(w, Point3d(0, 1, 0)));
			break;
		case SDLK_p:
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
			break;
		case SDLK_o:
			foreach(r; removable)
				r.breakApart();
			removable.length = 0;
			break;
		default:
		}
	}

	void mouseDown(CtlMouse mouse, int button)
	{
		if (button == 1)
			moveing = true;
	}

	void mouseUp(CtlMouse, int button)
	{
		if (button == 1)
			moveing = false;
	}

	void mouseMove(CtlMouse mouse, int ixrel, int iyrel)
	{
		if (!moveing)
			return;

		double xrel = ixrel;
		double yrel = iyrel;
		heading += xrel / 1000.0;
		pitch += yrel / 1000.0;
		cam.rotation = Quatd(heading, pitch, 0);
	}
}
