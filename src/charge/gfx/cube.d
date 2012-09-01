// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.cube;

import charge.math.movable;

import charge.gfx.gl;
import charge.gfx.world;
import charge.gfx.shader;
import charge.gfx.material;
import charge.gfx.renderqueue;
import charge.gfx.cull;


private {

struct Vertex
{
	float pos[3];
	float normal[3];
	float uv[2];
	float tanget[3];
	float binomial[3];
}

static Vertex vert[24] = [
	{ // X-
		[-0.5f, -0.5f, -0.5f], // Pos
		[-1.0f,  0.0f,  0.0f], // Normal
		[ 0.0f,  1.0f],        // UV
		[ 0.0f,  0.0f,  1.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[-0.5f, -0.5f,  0.5f], // Pos
		[-1.0f,  0.0f,  0.0f], // Normal
		[ 1.0f,  1.0f],        // UV
		[ 0.0f,  0.0f,  1.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[-0.5f,  0.5f,  0.5f], // Pos
		[-1.0f,  0.0f,  0.0f], // Normal
		[ 1.0f,  0.0f],        // UV
		[ 0.0f,  0.0f,  1.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[-0.5f,  0.5f, -0.5f], // Pos
		[-1.0f,  0.0f,  0.0f], // Normal
		[ 0.0f,  0.0f],        // UV
		[ 0.0f,  0.0f,  1.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, { // X+
		[ 0.5f, -0.5f, -0.5f], // Pos
		[ 1.0f,  0.0f,  0.0f], // Normal
		[ 1.0f,  1.0f],        // UV
		[ 0.0f,  0.0f, -1.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[ 0.5f,  0.5f, -0.5f], // Pos
		[ 1.0f,  0.0f,  0.0f], // Normal
		[ 1.0f,  0.0f],        // UV
		[ 0.0f,  0.0f, -1.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[ 0.5f,  0.5f,  0.5f], // Pos
		[ 1.0f,  0.0f,  0.0f], // Normal
		[ 0.0f,  0.0f],        // UV
		[ 0.0f,  0.0f, -1.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[ 0.5f, -0.5f,  0.5f], // Pos
		[ 1.0f,  0.0f,  0.0f], // Normal
		[ 0.0f,  1.0f],        // UV
		[ 0.0f,  0.0f, -1.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, { // Y- Bottom
		[-0.5f, -0.5f, -0.5f], // Pos
		[ 0.0f, -1.0f,  0.0f], // Normal
		[ 1.0f,  0.0f],        // UV
		[ 1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  0.0f,  1.0f]  // Binomial
	}, {
		[ 0.5f, -0.5f, -0.5f], // Pos
		[ 0.0f, -1.0f,  0.0f], // Normal
		[ 0.0f,  0.0f],        // UV
		[ 1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  0.0f,  1.0f]  // Binomial
	}, {
		[ 0.5f, -0.5f,  0.5f], // Pos
		[ 0.0f, -1.0f,  0.0f], // Normal
		[ 0.0f,  1.0f],        // UV
		[ 1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  0.0f,  1.0f]  // Binomial
	}, {
		[-0.5f, -0.5f,  0.5f], // Pos
		[ 0.0f, -1.0f,  0.0f], // Normal
		[ 1.0f,  1.0f],        // UV
		[ 1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  0.0f,  1.0f]  // Binomial
	}, { // Y+ Top
		[-0.5f,  0.5f, -0.5f], // Pos
		[ 0.0f,  1.0f,  0.0f], // Normal
		[ 0.0f,  0.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  0.0f,  1.0f]  // Binomial
	}, {
		[-0.5f,  0.5f,  0.5f], // Pos
		[ 0.0f,  1.0f,  0.0f], // Normal
		[ 0.0f,  1.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  0.0f,  1.0f]  // Binomial
	}, {
		[ 0.5f,  0.5f,  0.5f], // Pos
		[ 0.0f,  1.0f,  0.0f], // Normal
		[ 1.0f,  1.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  0.0f,  1.0f]  // Binomial
	}, {
		[ 0.5f,  0.5f, -0.5f], // Pos
		[ 0.0f,  1.0f,  0.0f], // Normal
		[ 1.0f,  0.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  0.0f,  1.0f]  // Binomial
	}, { // Z- Front
		[-0.5f, -0.5f, -0.5f], // Pos
		[ 0.0f,  0.0f, -1.0f], // Normal
		[ 1.0f,  1.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[-0.5f,  0.5f, -0.5f], // Pos
		[ 0.0f,  0.0f, -1.0f], // Normal
		[ 1.0f,  0.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[ 0.5f,  0.5f, -0.5f], // Pos
		[ 0.0f,  0.0f, -1.0f], // Normal
		[ 0.0f,  0.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[ 0.5f, -0.5f, -0.5f], // Pos
		[ 0.0f,  0.0f, -1.0f], // Normal
		[ 0.0f,  1.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, { // Z- Back
		[-0.5f, -0.5f,  0.5f], // Pos
		[ 0.0f,  0.0f,  1.0f], // Normal
		[ 0.0f,  1.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[ 0.5f, -0.5f,  0.5f], // Pos
		[ 0.0f,  0.0f,  1.0f], // Normal
		[ 1.0f,  1.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[ 0.5f,  0.5f,  0.5f], // Pos
		[ 0.0f,  0.0f,  1.0f], // Normal
		[ 1.0f,  0.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}, {
		[-0.5f,  0.5f,  0.5f], // Pos
		[ 0.0f,  0.0f,  1.0f], // Normal
		[ 0.0f,  0.0f],        // UV
		[-1.0f,  0.0f,  0.0f], // Tanget
		[ 0.0f,  1.0f,  0.0f]  // Binomial
	}
];
}

class Cube : Actor, Renderable
{
public:
	this(World w) {
		super(w);
		pos = Point3d();
		rot = Quatd();
		m = MaterialManager.getDefault();

		x = y = z = 1;
	}

	~this()
	{
		delete m;
	}

	void setSize(double sx, double sy, double sz)
	{
		x = sx;
		y = sy;
		z = sz;
	}

	void cullAndPush(Cull cull, RenderQueue rq)
	{
		auto v = cull.center - position;
		rq.push(v.lengthSqrd, this);
	}

	Material getMaterial()
	{
		return m;
	}

	void drawFixed()
	{
		gluPushAndTransform(pos, rot);
		glScaled(x, y, z);

		glEnable(GL_NORMALIZE);
		glEnableClientState(GL_VERTEX_ARRAY);
		glVertexPointer(3, GL_FLOAT, Vertex.sizeof, &vert[0].pos[0]);

		glEnableClientState(GL_NORMAL_ARRAY);
		glNormalPointer(GL_FLOAT, Vertex.sizeof, &vert[0].normal[0]);

		glClientActiveTexture(GL_TEXTURE0);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer(2, GL_FLOAT, Vertex.sizeof, &vert[0].uv[0]);

		glClientActiveTexture(GL_TEXTURE1);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer(3, GL_FLOAT, Vertex.sizeof, &vert[0].tanget[0]);

		glClientActiveTexture(GL_TEXTURE2);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer(3, GL_FLOAT, Vertex.sizeof, &vert[0].binomial[0]);

		glDrawArrays(GL_QUADS, 0, 24);

		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_NORMAL_ARRAY);
		glClientActiveTexture(GL_TEXTURE2);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glClientActiveTexture(GL_TEXTURE1);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glClientActiveTexture(GL_TEXTURE0);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisable(GL_NORMALIZE);

		glPopMatrix();
	}

	void drawAttrib(Shader s)
	{
		gluPushAndTransform(pos, rot);
		glScaled(x, y, z);

		glEnableVertexAttribArray(0); // pos
		glEnableVertexAttribArray(1); // uv
		glEnableVertexAttribArray(2); // normal
		glEnableVertexAttribArray(3); // tanget
		glEnableVertexAttribArray(4); // binomial

		glVertexAttribPointer(0, 3, GL_FLOAT, false, Vertex.sizeof, &vert[0].pos[0]);      // pos
		glVertexAttribPointer(1, 2, GL_FLOAT, false, Vertex.sizeof, &vert[0].uv[0]);       // uv
		glVertexAttribPointer(2, 3, GL_FLOAT, false, Vertex.sizeof, &vert[0].normal[0]);   // normal
		glVertexAttribPointer(3, 3, GL_FLOAT, false, Vertex.sizeof, &vert[0].tanget[0]);   // tanget
		glVertexAttribPointer(4, 3, GL_FLOAT, false, Vertex.sizeof, &vert[0].binomial[0]); // binomial
		glDrawArrays(GL_QUADS, 0, 24);

		glDisableVertexAttribArray(0); // pos
		glDisableVertexAttribArray(1); // uv
		glDisableVertexAttribArray(2); // normal
		glDisableVertexAttribArray(3); // tanget
		glDisableVertexAttribArray(4); // binomial

		glPopMatrix();
	}

private:
	Material m;
	double x, y, z;
}
