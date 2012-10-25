// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.gfx.selector;

import charge.math.mesh;
import charge.sys.resource;
import miners.gfx.imports;


/**
 * Base class for all Chunk VBO Groups, handles general managment.
 */
class Selector : GfxActor, GfxRenderable
{
public:
	bool show;

protected:
	alias charge.gfx.vbo.RigidMeshVBO GfxRigidMeshVBO;

	GfxMaterial m;
	GfxRigidMeshVBO vbo;

private:
	mixin SysLogging;

public:
	this(GfxWorld w)
	{
		super(w);
		m = GfxMaterialManager.getDefault(w.pool);
		m["color"] = Color3f(0, 0, 0);
		vbo = GfxRigidMeshVBO(RigidMesh.Types.QUADS, vert, null);
	}

	~this()
	{
		assert(m is null);
	}

	void breakApart()
	{
		breakApartAndNull(m);
		super.breakApart();
	}

	void setBlock(int x, int y, int z)
	{
		pos = Point3d(x, y, z);
	}

	void setPosition(ref Point3d pos) {}
	void setRotation(ref Quatd rot) {}


	/*
	 *
 	 * GfxActor methods.
	 *
	 */


	GfxMaterial getMaterial()
	{
		return m;
	}

	void setMaterial(GfxMaterial m)
	{
		this.m = m;
	}

	void cullAndPush(GfxCull cull, GfxRenderQueue rq)
	{
		if (show)
			rq.push(-double.max, this);
	}


	/*
	 *
	 * GfxRenderable
	 *
	 */


	void drawFixed()
	{
		gluPushAndTransform(pos, rot);

		glLineWidth(4);
		glDepthFunc(GL_LEQUAL);
		glPolygonMode(GL_FRONT, GL_LINE);

		vbo.drawFixed();

		glPolygonMode(GL_FRONT, GL_FILL);
		glDepthFunc(GL_LESS);
		glLineWidth(1);

		glPopMatrix();
	}

	void drawAttrib(GfxShader s)
	{
		gluPushAndTransform(pos, rot);

		glLineWidth(4);
		glDepthFunc(GL_LEQUAL);
		glPolygonMode(GL_FRONT, GL_LINE);

		vbo.drawAttrib();

		glPolygonMode(GL_FRONT, GL_FILL);
		glDepthFunc(GL_LESS);
		glLineWidth(1);

		glPopMatrix();
	}
}

private static Vertex vert[24] = [
	{ // X-
		-0.001f, -0.001f, -0.001f, // Pos
		 0.0f,    1.0f,            // UV
		-1.0f,    0.0f,    0.0f,   // Normal
	}, {
		-0.001f, -0.001f,  1.001f, // Pos
		 1.0f,    1.0f,            // UV
		-1.0f,    0.0f,    0.0f,   // Normal
	}, {
		-0.001f,  1.001f,  1.001f, // Pos
		 1.0f,    0.0f,            // UV
		-1.0f,    0.0f,    0.0f,   // Normal
	}, {
		-0.001f,  1.001f, -0.001f, // Pos
		 0.0f,    0.0f,            // UV
		-1.0f,    0.0f,    0.0f,   // Normal
	}, { // X+
		 1.001f, -0.001f, -0.001f, // Pos
		 1.0f,    1.0f,            // UV
		 1.0f,    0.0f,    0.0f,   // Normal
	}, {
		 1.001f,  1.001f, -0.001f, // Pos
		 1.0f,    0.0f,            // UV
		 1.0f,    0.0f,    0.0f,   // Normal
	}, {
		 1.001f,  1.001f,  1.001f, // Pos
		 0.0f,    0.0f,            // UV
		 1.0f,    0.0f,    0.0f,   // Normal
	}, {
		 1.001f, -0.001f,  1.001f, // Pos
		 0.0f,    1.0f,            // UV
		 1.0f,    0.0f,    0.0f,   // Normal
	}, { // Y- Bottom
		-0.001f, -0.001f, -0.001f, // Pos
		 1.0f,    0.0f,            // UV
		 0.0f, -  1.0f,    0.0f,   // Normal
	}, {
		 1.001f, -0.001f, -0.001f, // Pos
		 0.0f,    0.0f,            // UV
		 0.0f, -  1.0f,    0.0f,   // Normal
	}, {
		 1.001f, -0.001f,  1.001f, // Pos
		 0.0f,    1.0f,            // UV
		 0.0f, -  1.0f,    0.0f,   // Normal
	}, {
		-0.001f, -0.001f,  1.001f, // Pos
		 1.0f,    1.0f,            // UV
		 0.0f, -  1.0f,    0.0f,   // Normal
	}, { // Y+ Top
		-0.001f,  1.001f, -0.001f, // Pos
		 0.0f,    0.0f,            // UV
		 0.0f,    1.0f,    0.0f,   // Normal
	}, {
		-0.001f,  1.001f,  1.001f, // Pos
		 0.0f,    1.0f,            // UV
		 0.0f,    1.0f,    0.0f,   // Normal
	}, {
		 1.001f,  1.001f,  1.001f, // Pos
		 1.0f,    1.0f,            // UV
		 0.0f,    1.0f,    0.0f,   // Normal
	}, {
		 1.001f,  1.001f, -0.001f, // Pos
		 1.0f,    0.0f,            // UV
		 0.0f,    1.0f,    0.0f,   // Normal
	}, { // Z- Front
		-0.001f, -0.001f, -0.001f, // Pos
		 1.0f,    1.0f,            // UV
		 0.0f,    0.0f, -  1.0f,   // Normal
	}, {
		-0.001f,  1.001f, -0.001f, // Pos
		 1.0f,    0.0f,            // UV
		 0.0f,    0.0f, -  1.0f,   // Normal
	}, {
		 1.001f,  1.001f, -0.001f, // Pos
		 0.0f,    0.0f,            // UV
		 0.0f,    0.0f, -  1.0f,   // Normal
	}, {
		 1.001f, -0.001f, -0.001f, // Pos
		 0.0f,    1.0f,            // UV
		 0.0f,    0.0f, -  1.0f,   // Normal
	}, { // Z- Back
		-0.001f, -0.001f,  1.001f, // Pos
		 0.0f,    1.0f,            // UV
		 0.0f,    0.0f,    1.0f,   // Normal
	}, {
		 1.001f, -0.001f,  1.001f, // Pos
		 1.0f,    1.0f,            // UV
		 0.0f,    0.0f,    1.0f,   // Normal
	}, {
		 1.001f,  1.001f,  1.001f, // Pos
		 1.0f,    0.0f,            // UV
		 0.0f,    0.0f,    1.0f,   // Normal
	}, {
		-0.001f,  1.001f,  1.001f, // Pos
		 0.0f,    0.0f,            // UV
		 0.0f,    0.0f,    1.0f,   // Normal
	}
];
