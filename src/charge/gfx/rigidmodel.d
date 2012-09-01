// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.rigidmodel;

import charge.math.movable;
import charge.math.mesh;

import charge.gfx.cull;
import charge.gfx.world;
import charge.gfx.shader;
import charge.gfx.renderqueue;
import charge.gfx.material;
import charge.gfx.gl;
import charge.gfx.vbo;

import charge.sys.logger;

class RigidModel : public Actor, public Renderable
{
private:
	mixin Logging;

	double x, y, z;
	RigidMeshVBO vbo;
	Material m;

public:
	static RigidModel opCall(World w, string name)
	{
		auto vbo = RigidMeshVBO(name);
		if (vbo is null) {
			l.warn("failed to load %s", name);
			return null;
		}
		return new RigidModel(w, vbo);
	}

	static RigidModel opCall(World w, RigidMeshVBO vbo)
	{
		// Take on reference because the constructor doesn't.
		RigidMeshVBO tmp;
		vbo.reference(&tmp, vbo);

		return new RigidModel(w, vbo);
	}

	void setSize(double sx, double sy, double sz)
	{
		x = sx;
		y = sy;
		z = sz;
	}

	Material getMaterial()
	{
		return m;
	}

	void setMaterial(Material m)
	{
		this.m = m;
	}

protected:
	this(World w, RigidMeshVBO vbo) {
		super(w);
		pos = Point3d();
		rot = Quatd();
		m = MaterialManager.getDefault();
		x = y = z = 1;
		this.vbo = vbo;
	}

	~this()
	{
		delete m;
		vbo.reference(&vbo, null);
	}

	void cullAndPush(Cull cull, RenderQueue rq)
	{
		auto v = cull.center - position;
		rq.push(v.lengthSqrd, this);
	}

	void drawFixed()
	{
		gluPushAndTransform(pos, rot);
		glScaled(x, y, z);

		vbo.drawFixed();

		glPopMatrix();
	}

	void drawAttrib(Shader s)
	{
		gluPushAndTransform(pos, rot);
		glScaled(x, y, z);

		vbo.drawAttrib();

		glPopMatrix();
	}
}
