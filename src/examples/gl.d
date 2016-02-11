// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module examples.gl;

import charge.charge;
import charge.gfx.gl;


class Game : GameApp
{
protected:
	float value;

public:
	this(string[] args)
	{
		value = 0;
		super();
	}

	override void logic()
	{
		value += 0.01;
		if (value > 360)
			value -= 360;
	}

	override void render()
	{
		auto rt = GfxDefaultTarget();

		glClearColor(1, 0, 0, 1);
		glClear(GL_COLOR_BUFFER_BIT);

		glPushMatrix();
		glRotatef(value, 0, 0, 1);

		glBegin(GL_TRIANGLES);
		glColor3f(1, 1, 1);
		glVertex3f(-1,-1, 0);
		glVertex3f(-1, 1, 0);
		glVertex3f( 1, 1, 0);
		glEnd();

		glPopMatrix();

		rt.swap();
	}
}
