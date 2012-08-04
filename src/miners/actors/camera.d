// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.actors.camera;

import std.math;

import charge.charge;

import miners.world;
import miners.actors.sunlight;


class Camera : public GameActor
{
protected:
	GfxCamera c;
	GfxProjCamera pcam;
	GfxIsoCamera icam;

	/*
	 * Screen height and width.
	 */
	uint width;
	uint height;

	/**
	 * Pixels per block, the number of pixels to one block across the
	 * width of a block in iso view. Since we are using a two to one iso
	 * projection the number of pixels high a block is half this number.
	 */
	uint ppb;

	/**
	 * Center the iso camera position height at this level.
	 */
	double isoCenterHeight;

	/**
	 * The width of a square across the screen, in game units.
	 *
	 * Using the Pythagorean theorem yeilds:
	 *
	 * 1² + 1² = w²
	 *     √2
	 */
	const isoWidthLength = 1.4142135623730950488016887242096980785696718753769480731766;

	/**
	 * The height of a square across the screen, in game units.
	 *
	 * The the width is √2 as given above. Since the view is angled with the
	 * angle tan⁻¹( ½ ) this gives us the height on the screen as:
	 *
	 * √2 sin( tan⁻¹( ½ ) )
	 */
	const isoHeightLength = 0.6324555320336758663997787088865437067439110278650433653715;

	/**
	 * When moving the iso camera to the height of 64 we need to multiply the
	 * difference between the current height and 64 with a constant. To get
	 * the length that the point must travel along the view of the iso camera.
	 */
	const isoHeightDiff = 0.4472135954999579392818347337462552470881236719223051448541;

public:
	this(World w)
	{
		super(w);

		this.ppb = 32;
		this.isoCenterHeight = 64.0;

		pcam = new GfxProjCamera();
		icam = new GfxIsoCamera(800, 600, -200, 200, GfxIsoCamera.TwoToOne);

		// Set defaults
		proj = true;
		near = 0.1;
		fov = w.opts.fov();
		far = w.opts.viewDistance();

		w.opts.fov ~= &fov;
		w.opts.viewDistance ~= &far;

		resize(800, 600);
	}

	~this()
	{
		auto w = cast(World)w;
		w.opts.fov -= &fov;
		w.opts.viewDistance -= &far;

		delete icam;
		delete pcam;
	}

	void resize(uint width, uint height)
	{
		double w = width / ppb * isoWidthLength;
		double h = height / (ppb / 2) * isoHeightLength;

		double ratio = cast(double)width / cast(double)height;

		icam.width = w;
		icam.height = h;

		pcam.ratio = ratio;
	}

	void setPosition(ref Point3d pos)
	{
		pcam.position = pos;

		auto ipos = pos;
		auto rot = icam.rotation;

		// Tweek the position
		Matrix3x3d mat = rot;
		Matrix3x3d matInv = rot;
		matInv.inverse();

		ipos = matInv * ipos;
		ipos.x -= (ipos.x % (isoWidthLength/(ppb)));
		ipos.y -= (ipos.y % (isoHeightLength/(ppb/2)));
		ipos = mat * ipos;

		icam.position = ipos;
	}

	final void pixelsPerBlock(uint ppb)
	{
		assert(ppb != 0);

		this.ppb = ppb;
		resize(width, height);
	}

	final void isoHeight(double value)
	{
		isoCenterHeight = value / 2;
	}

	final GfxCamera current() { return c; }
	final bool iso() { return c is icam; }
	final bool proj() { return c is pcam; }
	final void iso(bool value) { c = value ? icam : pcam; }
	final void proj(bool value) { iso = !value; }

	final void fov(int value) { pcam.fov = value; }
	final void far(double value) { pcam.far = value; }
	final void near(double value) { pcam.near = value; }
	final int fov() { return cast(int)pcam.fov; }
	final double far() { return pcam.far; }
	final double near() { return pcam.near; }

	void getPosition(out Point3d pos) { pcam.getPosition(pos); }
	void setRotation(ref Quatd rot) { pcam.setRotation(rot); }
	void getRotation(out Quatd rot) { pcam.getRotation(rot); }
}
