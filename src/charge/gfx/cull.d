// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.cull;

import charge.math.movable;
import charge.math.matrix4x4d;
import charge.math.frustum;
import charge.gfx.camera;
import charge.gfx.gl;


class Cull
{
	Point3d center;
	Frustum f;

	this(Camera c)
	{
		center = c.position;
		c.transform;

		extractFromCurrentMatrices();
	}

	this(Point3d center)
	{
		this.center = center;
		extractFromCurrentMatrices();
	}

	void extractFromCurrentMatrices()
	{
		Matrix4x4d mat;

		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		glGetDoublev(GL_MODELVIEW_MATRIX, mat.array.ptr);
		glMultMatrixd(mat.array.ptr);
		glGetDoublev(GL_PROJECTION_MATRIX, mat.array.ptr);
		glPopMatrix();

		f.setGLMatrix(mat);
	}

}
