// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for VBO (s).
 */
module charge.gfx.vbo;

import charge.util.vector;

import charge.math.mesh;

import charge.gfx.gl;

import charge.sys.logger;
import charge.sys.resource;


/**
 * Base class for VBO meshes.
 *
 * @ingroup Resource
 */
class VBO : Resource
{
protected:
	const string uri = "vbo://";

	GLuint vboVerts;
	GLuint vboIndices;
	GLuint numVerts;
	GLuint numIndices;

	GLuint vao;

	size_t verteciesSize;
	size_t indicesSize;

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

		used_mem -= verteciesSize;
		used_mem -= indicesSize;
	}

	static int used() { return used_mem; }

protected:
	this(Pool p, string name)
	{
		super(p, uri, name);

		glGenBuffersARB(1, &vboVerts);
		if (GL_CHARGE_vertex_array_object)
			glGenVertexArraysCHARGE(1, &vao);
	}

	void update(void *verts, size_t verticesSize, GLuint numVerts,
	            void *indices, size_t indicesSize, GLuint numIndices)
	{
		used_mem -= this.verteciesSize;
		used_mem -= this.indicesSize;

		this.verteciesSize = verticesSize;
		this.indicesSize = indicesSize;
		this.numVerts = numVerts;
		this.numIndices = numIndices;

		glBindBufferARB(GL_ARRAY_BUFFER_ARB, vboVerts);
		glBufferDataARB(GL_ARRAY_BUFFER_ARB, verteciesSize,
		                verts, GL_STATIC_DRAW_ARB);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);

		if (indicesSize) {
			assert(numIndices);
			if (vboIndices == 0)
				glGenBuffersARB(1, &vboIndices);
			glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, vboIndices);
			glBufferDataARB(GL_ELEMENT_ARRAY_BUFFER_ARB, indicesSize,
			                indices, GL_STATIC_DRAW_ARB);
			glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
		} else {
			if (vboIndices)
				glDeleteBuffersARB(1, &vboIndices);
			vboIndices = 0;
		}

		used_mem += verteciesSize;
		used_mem += indicesSize;
	}

}

/**
 * Resource part backing @link charge.gfx.rigidmodel.RigidModel RigidModel @endlink.
 *
 * @ingroup Resource
 */
class RigidMeshVBO : VBO
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
	static RigidMeshVBO opCall(Pool p, string filename)
	in {
		assert(p !is null);
		assert(filename !is null);
	}
	body {
		auto r = p.resource(uri, filename);
		auto t = cast(RigidMeshVBO)r;
		if (r !is null) {
			assert(t !is null);
			return t;
		}

		auto m = RigidMesh(p, filename);
		if (m is null) {
			l.warn("failed to load %s", filename);
			return null;
		}
		auto ret = new RigidMeshVBO(p, filename, m);
		reference(&m, null);
		return ret;
	}

	static RigidMeshVBO opCall(RigidMeshBuilder builder)
	{
		return new RigidMeshVBO(
			null, null, builder.type,
			builder.verts, builder.iv,
			builder.tris, builder.it);
	}

	static RigidMeshVBO opCall(RigidMesh.Types type,
	                           Vertex[] verts, Triangle[] tris)
	{
		return new RigidMeshVBO(null, null, type,
		                        verts.ptr, cast(uint)verts.length,
		                        tris.ptr, cast(uint)tris.length);
	}

	void update(RigidMeshBuilder builder)
	{
		update(builder.type,
		       builder.verts, builder.iv,
		       builder.tris, builder.it);
	}

	void update(RigidMesh.Types type, Vertex *verts, uint numVerts,
	            Triangle *tris, uint numTriangles)
	{
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

		super.update(verts, verteciesSize, numVerts,
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

		glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
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

protected:
	this(Pool p, string name, RigidMesh model)
	{
		numVerts = cast(GLuint)model.verts.length;
		numIndices = cast(GLuint)model.tris.length;

		this(p, name, model.type,
		     model.verts.ptr, cast(uint)model.verts.length,
		     model.tris.ptr, cast(uint)model.tris.length);
	}

	this(Pool p, string name, RigidMesh.Types type,
	     Vertex *verts, uint numVerts, Triangle *tris, uint numTriangles)
	{
		super(p, name);

		update(type, verts, numVerts, tris, numTriangles);
	}
}
