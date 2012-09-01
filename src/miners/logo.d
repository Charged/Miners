// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.logo;

import std.math;

import charge.math.color;
import charge.gfx.gl;
import charge.game.gui.component;
import charge.game.gui.container;

static import charge.gfx.draw;
private alias charge.gfx.draw.Draw GfxDraw;


class Logo : Component
{
private:
	const black = Color4f(Color4b(0x00_00_00_ff));
	const grey = Color4f(Color4b(0x20_20_20_ff));
	const frameHighlight = Color4f(Color4b(0xfa_f3_cc_ff));
	const frameSolid = Color4f(Color4b(0xe1_d3_78_ff));
	const frameDark = Color4f(Color4b(0xb7_9d_54_ff));
	const blockHighlight = Color4f(Color4b(0xf0_00_ff_ff));
	const blockSolid = Color4f(Color4b(0xb8_02_c3_ff));
	const blockDark = Color4f(Color4b(0x7a_00_82_ff));

	const double r1 = 52.0;
	const double r2 = 64.0;
	const int scale = 4;

public:
	int teeth;
	uint rotate;

public:
	this(Container c, int x, int y)
	{
		this.teeth = 12;
		this.rotate = 0;

		super(c, x, y, cast(uint)(scale * r2) * 2, cast(uint)(scale * r2) * 2);
	}

	void paint(GfxDraw d)
	{
		glTranslated(scale * r2, scale * r2, 0);
		glScaled(scale, scale, 1);

		glPushMatrix();

		glRotated(rotate * 0.5, 0, 0, 1);

		double gd = (2.0 * PI / teeth) / 4;

		void drawGear(double r1, double r2, double adj) {
			glBegin(GL_TRIANGLE_FAN);
			glVertex2d(0, 0);

			double angle = (gd / 2 * 3);

			angle += adj / 2;

			for(int i; i < teeth; i++) {
				angle += gd - adj;
				glVertex2d(r1 * cos(angle), r1 * sin(angle));
				angle += gd;
				glVertex2d(r2 * cos(angle), r2 * sin(angle));
				angle += gd + adj;
				glVertex2d(r2 * cos(angle), r2 * sin(angle));
				angle += gd;
				glVertex2d(r1 * cos(angle), r1 * sin(angle));
			}

			angle += gd - adj;
			glVertex2d(r1 * cos(angle), r1 * sin(angle));

			glEnd();
		}

		glColor4fv(grey.ptr);
		drawGear(r1, r2, 0.03);

		glColor4fv(black.ptr);
		drawGear(r1-4, r2-4, -0.03);

		glPopMatrix();

		const int fs = 44; // frameSize
		const int fsh = fs / 2; // frameSizeHalfe
		const int fw = 6; // frameWidth
		const int fwh = fw / 2; // frameWidthHalf
		const int bs = 24; // blockSize
		const int bsh = bs / 2; // blockSizeHalf

		void drawBackBottom() {
			glVertex2i(  0,            0 );
			glVertex2i( fs,          fsh );
			glVertex2i( fs - 2 * fw, fsh );
			glVertex2i(  0,      2 * fwh );

			glVertex2i(  0,            0 );
			glVertex2i(-fs,          fsh );
			glVertex2i(-fs + 2 * fw, fsh );
			glVertex2i(  0,      2 * fwh );
		}

		void drawBackLeft() {
			glVertex2i(  0, -fs );
			glVertex2i(  0,   0 );
			glVertex2i(-fw, fwh );
			glVertex2i(-fw, -fs + fwh );

			glVertex2i(-fs, fsh - fw );
			glVertex2i(-fs, fsh );
			glVertex2i(  0,   0 );
			glVertex2i(  0, -fw );
		}

		void drawBackRight() {
			glVertex2i( 0,      -fs );
			glVertex2i( 0,        0 );
			glVertex2i( 0 + fw, fwh );
			glVertex2i( 0 + fw, -fs + fwh );

			glVertex2i( fs, fsh - fw );
			glVertex2i( fs, fsh );
			glVertex2i(  0,   0 );
			glVertex2i(  0, -fw );
		}

		void drawTop() {
			int w1 = -fs;
			int w2 = -fs + 2 * fw;
			int w3 =   0;
			int w4 =  fs - 2 * fw;
			int w5 =  fs;


			int h1 =  -fs;
			int h2 =  -fs + 2 * fwh;
			int h3 = -fsh;
			int h4 =    0 - 2 * fwh;
			int h5 =    0;

			glVertex2i( w3, h1 );
			glVertex2i( w5, h3 );
			glVertex2i( w4, h3 );
			glVertex2i( w3, h2 );

			glVertex2i( w3, h1 );
			glVertex2i( w1, h3 );
			glVertex2i( w2, h3 );
			glVertex2i( w3, h2 );

			glVertex2i( w3, h5 );
			glVertex2i( w5, h3 );
			glVertex2i( w4, h3 );
			glVertex2i( w3, h4 );

			glVertex2i( w3, h5 );
			glVertex2i( w1, h3 );
			glVertex2i( w2, h3 );
			glVertex2i( w3, h4 );
		}

		void drawRight() {
			glVertex2i( fs,      -fsh );
			glVertex2i( fs,       fsh );
			glVertex2i( fs - fw,  fsh + fwh );
			glVertex2i( fs - fw, -fsh + fwh );

			glVertex2i(  0,  0 );
			glVertex2i(  0, fs );
			glVertex2i( fw, fs - fwh );
			glVertex2i( fw,  0 - fwh );

			glVertex2i(  0,    0 );
			glVertex2i(  0,   fw );
			glVertex2i( fs, -fsh + fw );
			glVertex2i( fs, -fsh );

			glVertex2i(  0, fs - fw );
			glVertex2i(  0, fs );
			glVertex2i( fs, fsh );
			glVertex2i( fs, fsh - fw);
		}

		void drawLeft() {
			glVertex2i(-fs,      -fsh );
			glVertex2i(-fs,       fsh );
			glVertex2i(-fs + fw,  fsh + fwh );
			glVertex2i(-fs + fw, -fsh + fwh );

			glVertex2i(  0,  0 );
			glVertex2i(  0, fs );
			glVertex2i(-fw, fs - fwh );
			glVertex2i(-fw,  0 - fwh );

			glVertex2i(  0,    0 );
			glVertex2i(  0,   fw );
			glVertex2i(-fs, -fsh + fw );
			glVertex2i(-fs, -fsh );

			glVertex2i(  0,  fs - fw );
			glVertex2i(  0,  fs );
			glVertex2i(-fs, fsh );
			glVertex2i(-fs, fsh - fw);
		}

		glBegin(GL_QUADS);


		glEnd();

		glBegin(GL_QUADS);

		// Background frame
		glColor4fv(frameHighlight.ptr);
		drawBackBottom();
		glColor4fv(frameSolid.ptr);
		drawBackLeft();
		glColor4fv(frameDark.ptr);
		drawBackRight();

		// Middle block
		glColor4fv(blockHighlight.ptr);
		glVertex2i( 0, 0 );
		glVertex2i( bs, -bsh );
		glVertex2i( 0, -bs );
		glVertex2i( -bs, -bsh );
		glColor4fv(blockSolid.ptr);
		glVertex2i( 0, 0 );
		glVertex2i( bs, -bsh );
		glVertex2i( bs, bsh );
		glVertex2i( 0, bs );
		glColor4fv(blockDark.ptr);
		glVertex2i( 0 , 0 );
		glVertex2i( -bs, -bsh );
		glVertex2i( -bs, bsh );
		glVertex2i( 0, bs );

		// Foreground frame
		glColor4fv(frameHighlight.ptr);
		drawTop();
		glColor4fv(frameSolid.ptr);
		drawRight();
		glColor4fv(frameDark.ptr);
		drawLeft();

		glEnd();
	}

	void releaseResources()
	{

	}

	void repack()
	{

	}
}

class Cogwheel : Component
{
private:
	uint teeth;
	uint boxRadius;
	uint outerRadius;
	uint innerRadius;

public:
	this(Container c, int x, int y, uint boxRadius, uint outerRadius, uint innerRadius, uint teeth)
	{
		super(c, x, y, boxRadius * 2, boxRadius * 2);

		this.teeth = teeth;
		this.boxRadius = boxRadius;
		this.outerRadius = outerRadius;
		this.innerRadius = innerRadius;
	}

	void paint(GfxDraw d)
	{
		d.fill(Logo.grey, false, 0, 0, w, h);

		d.translate(boxRadius, boxRadius);

		double gd = (2.0 * PI / teeth) / 4;

		void drawGear(double r1, double r2, double adj) {
			glBegin(GL_TRIANGLE_FAN);
			glVertex2d(0, 0);

			double angle = (gd / 2 * 3);

			angle += adj / 2;

			for(int i; i < teeth; i++) {
				angle += gd - adj;
				glVertex2d(r1 * cos(angle), r1 * sin(angle));
				angle += gd;
				glVertex2d(r2 * cos(angle), r2 * sin(angle));
				angle += gd + adj;
				glVertex2d(r2 * cos(angle), r2 * sin(angle));
				angle += gd;
				glVertex2d(r1 * cos(angle), r1 * sin(angle));
			}

			angle += gd - adj;
			glVertex2d(r1 * cos(angle), r1 * sin(angle));

			glEnd();
		}

		glColor4fv(Logo.black.ptr);
		drawGear(outerRadius, innerRadius, 0);
	}

	void releaseResources()
	{

	}

	void repack()
	{

	}
}
