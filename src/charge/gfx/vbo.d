// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.vbo;

import charge.util.vector;

import charge.math.mesh;

import charge.gfx.gl;

import charge.sys.logger;
import charge.sys.resource;

class VBO : public Resource
{
public:
	const char[] uri = "vbo://";

	GLuint vboVerts;
	GLuint vboIndices;
	GLuint numVerts;
	GLuint numIndices;

	GLuint vao;

	size_t verteciesSize;
	size_t indicesSize;

protected:
	static int used_mem;

private:
	mixin Logging;


public:
	~this()
	{
		// Delete the VAO first
		if (vao)
			glDeleteVertexArraysCHARGE(1, &vao);

		glDeleteBuffersARB(1, &vboVerts);
		if (vboIndices)
			glDeleteBuffersARB(1, &vboIndices);

		used_mem -= indicesSize;
		used_mem -= verteciesSize;
	}

	static int used() { return used_mem; }

protected:
	this(Pool p, char[] filename, bool dynamic,
	     void *verts, size_t verticesSize, GLuint numVerts,
	     void *indices, size_t indicesSize, GLuint numIndices) {
		super(p, uri, filename, dynamic);

		this.verteciesSize = verticesSize;
		this.indicesSize = indicesSize;
		this.numVerts = numVerts;
		this.numIndices = numIndices;

		glGenBuffersARB(1, &vboVerts);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, vboVerts);
		glBufferDataARB(GL_ARRAY_BUFFER_ARB, verteciesSize,
		                verts, GL_STATIC_DRAW_ARB);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);

		if (indicesSize) {
			assert(numIndices);
			glGenBuffersARB(1, &vboIndices);
			glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, vboIndices);
			glBufferDataARB(GL_ELEMENT_ARRAY_BUFFER_ARB, indicesSize,
			                indices, GL_STATIC_DRAW_ARB);
			glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
		}

		used_mem += indicesSize;
		used_mem += verteciesSize;

		if (GL_CHARGE_vertex_array_object)
			glGenVertexArraysCHARGE(1, &vao);
	}

}

class RigidMeshVBO : public VBO
{
protected:
	const void *vertOffset = null;
	const void *normalOffset = cast(void*)(float.sizeof * 5);
	const void *texOffset = cast(void*)(float.sizeof * 3);

	GLint primType;
	bool indexed;

private:
	mixin Logging;

public:
	this(Pool p, char[] filename, RigidMesh model)
	{
		numVerts = cast(GLuint)model.verts.length;
		numIndices = cast(GLuint)model.tris.length;

		this(p, filename, false, model.type,
		     model.verts.ptr, cast(uint)model.verts.length,
		     model.tris.ptr, cast(uint)model.tris.length);
	}

	this(Pool p, char[] prefix, RigidMeshBuilder builder)
	{
		this(p, prefix, true, builder.type,
		     builder.verts, builder.iv,
		     builder.tris, builder.it);
	}

protected:
	this(Pool p, char[] filename, bool dynamic, RigidMesh.Types type,
	     Vertex *verts, uint numVerts, Triangle *tris, uint numTriangles)
	{
		if (filename is null) {
			assert(dynamic);
			filename = "charge/gfx/vbo";
		}

		switch (type) {
		case RigidMesh.Types.INDEXED_TRIANGLES:
			primType = GL_TRIANGLES;
			indexed = true;
			break;
		case RigidMesh.Types.QUADS:
			assert(numIndices == 0);
			primType = GL_QUADS;
			indexed = false;
			break;
		default:
			assert(false);
		}

		this.numVerts = numVerts;
		this.numIndices = numTriangles * 3;

		verteciesSize = Vertex.sizeof * numVerts;
		indicesSize = Triangle.sizeof * numTriangles;

		if (!indexed) {
			indicesSize = 0; numIndices = 0;
		} else {
			assert(indicesSize > 0);
		}

		super(p, filename, dynamic,
		      verts, verteciesSize, numVerts,
		      tris, indicesSize, numIndices);

		if (!vao)
			return;

		// Setup the vertex array object.
		glBindVertexArrayCHARGE(vao);

		glEnableVertexAttribArray(0); // pos
		glEnableVertexAttribArray(1); // uv
		glEnableVertexAttribArray(2); // normal

		glBindBufferARB(GL_ARRAY_BUFFER_ARB, vboVerts);

		const size = Vertex.sizeof;
		glVertexAttribPointer(0, 3, GL_FLOAT, false, size, vertOffset);   // pos
		glVertexAttribPointer(1, 2, GL_FLOAT, false, size, texOffset);    // uv
		glVertexAttribPointer(2, 3, GL_FLOAT, false, size, normalOffset); // normal

		if (indexed)
			glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, vboIndices);

		// Restore default
		glBindVertexArrayCHARGE(0);
	}

public:
	static RigidMeshVBO opCall(char[] filename)
	{
		return RigidMeshVBO(Pool(), filename);
	}

	static RigidMeshVBO opCall(Pool p, char[] filename)
	{
		auto r = p.resource(uri, filename);
		auto t = cast(RigidMeshVBO)r;
		if (r !is null) {
			assert(t !is null);
			return t;
		}

		auto m = RigidMesh(filename);
		if (m is null) {
			l.warn("failed to load %s", filename);
			return null;
		}
		auto ret = new RigidMeshVBO(p, filename, m);
		m.dereference;
		return ret;
	}

	static RigidMeshVBO opCall(char[] prefix, RigidMeshBuilder builder)
	{
		return RigidMeshVBO(Pool(), prefix, builder);
	}

	static RigidMeshVBO opCall(Pool p, char[] prefix, RigidMeshBuilder builder)
	{
		return new RigidMeshVBO(p, prefix, builder);
	}

	/**
	 * Draws the vbo using fixed vertex inputs.
	 */
	final void drawFixed()
	{
		setup();
		doDraw();
		cleanup();
	}

	/**
	 * Draws a array of vbos using fixed vertex inputs.
	 */
	static void drawArrayFixed(RigidMeshVBO[] vbos)
	{
		if (!vbos.length)
			return;

		setup();
		
		foreach(vbo; vbos) {
			vbo.doDraw();
		}

		cleanup();
	}

	/**
	 * Draws a the vbo using VertexAttribArrays as inputs.
	 *
	 * Where the attribute index to name mapping follows the order
	 * in which they are located in the vertex. To illustrate:
	 *
	 * 0 - position
	 * 1 - uv
	 * 2 - normal
	 */
	final void drawAttrib()
	{
		RigidMeshVBO[1] a;
		a[0] = this;
		drawArrayAttrib(a);
	}

	/**
	 * Draws a array of vbos using VertexAttribArrays as inputs.
	 *
	 * Where the attribute index to name mapping follows the order
	 * in which they are located in the vertex. To illustrate:
	 *
	 * 0 - position
	 * 1 - uv
	 * 2 - normal
	 */
	static void drawArrayAttrib(RigidMeshVBO[] vbos)
	{
		const vertexSize = Vertex.sizeof;

		foreach (vbo; vbos) {
			glBindVertexArrayCHARGE(vbo.vao);

			if (vbo.indexed) {
				glDrawElements(vbo.primType, vbo.numIndices, GL_UNSIGNED_INT, null);
			} else {
				glDrawArrays(vbo.primType, 0, vbo.numVerts);
			}
		}

		glBindVertexArrayCHARGE(0);
	}

private:
	final static void setup()
	{
		glEnable(GL_NORMALIZE);
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_NORMAL_ARRAY);
		glClientActiveTexture(GL_TEXTURE0);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	}

	final void doDraw()
	{
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, vboVerts);
		glVertexPointer(3, GL_FLOAT, Vertex.sizeof, vertOffset);
		glNormalPointer(GL_FLOAT, Vertex.sizeof, normalOffset);
		glTexCoordPointer(2, GL_FLOAT, Vertex.sizeof, texOffset);
		if (indexed) {
			glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, vboIndices);
			glDrawElements(primType, numIndices, GL_UNSIGNED_INT, null);
		} else {
			glDrawArrays(primType, 0, numVerts);
		}
	}

	final static void cleanup()
	{
		glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);

		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_NORMAL_ARRAY);
		glClientActiveTexture(GL_TEXTURE2);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glClientActiveTexture(GL_TEXTURE1);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glClientActiveTexture(GL_TEXTURE0);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisable(GL_NORMALIZE);
	}

}
