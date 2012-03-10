// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.gfx.vbo;

import charge.math.box;
import charge.sys.resource;

import miners.gfx.imports;
import miners.defines;


/**
 * ChunkVBO which is just the inbuilt RigidMeshVBO.
 */
class ChunkVBORigidMesh : public charge.gfx.vbo.RigidMeshVBO
{
public:
	static ChunkVBORigidMesh opCall(RigidMeshBuilder mb, int x, int y, int z)
	{
		return ChunkVBORigidMesh(Pool(), mb, x, y, z);
	}

	static ChunkVBORigidMesh opCall(Pool p, RigidMeshBuilder mb, int x, int y, int z)
	{
		return new ChunkVBORigidMesh(p, mb);
	}

protected:
	this(charge.sys.resource.Pool p, RigidMeshBuilder mb)
	{
		super(p, mb);
	}

}


/**
 * A slightly more compact version of ChunkVBORigidMesh.
 */
class ChunkVBOCompactMesh : public GfxVBO
{
protected:
	const void* vertOffset = null;
	const void* uvOffset = cast(void*)(3 * float.sizeof);
	const void* dataOffset = cast(void*)(4 * float.sizeof);

public:
	static struct Vertex
	{
		float[3] position;
		struct {
			ushort u;
			ushort v;
		}
		struct {
			ubyte light;
			ubyte normal;
			ubyte texture;
			ubyte pad;
		}
	}

	static ChunkVBOCompactMesh opCall(Vertex[] verts, int x, int y, int z)
	{
		return new ChunkVBOCompactMesh(charge.sys.resource.Pool(), verts);
	}

	void update(Vertex[] verts)
	{
		super.update(verts.ptr, verts.length * Vertex.sizeof,
		             cast(uint)verts.length, null, 0, 0);
	}

protected:
	this(charge.sys.resource.Pool p, Vertex[] verts)
	{
		super(p, null);

		update(verts);

		assert(vao);

		// Setup the vertex array object.
		glBindVertexArrayCHARGE(vao);

		glEnableVertexAttribArray(0); // pos
		glEnableVertexAttribArray(1); // uv
		glEnableVertexAttribArray(2); // data

		glBindBufferARB(GL_ARRAY_BUFFER_ARB, vboVerts);

		const size = ChunkVBOCompactMesh.Vertex.sizeof;
		glVertexAttribPointer(0, 3, GL_FLOAT, false, size, vertOffset);         // pos
		glVertexAttribPointer(1, 2, GL_SHORT, false, size, uvOffset);           // uv
		glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, false, size, dataOffset); // data

		glBindVertexArrayCHARGE(0);
	}

}


/**
 * Base class for all Chunk VBO Groups, handles general managment.
 */
abstract class ChunkVBOGroup : public GfxActor, public GfxRenderable
{
public:
	mixin SysLogging;

	Entry[] array;
	GfxMaterial m;
	ABox[] resultAABB;
	GfxVBO[] resultVBO;
	int result_num;

	static struct Entry {
		ABox aabb;
		GfxVBO vbo;
	};

	this(GfxWorld w) {
		super(w);
		pos = Point3d();
		rot = Quatd();
		m = GfxMaterialManager.getDefault();
	}

	~this()
	{
		delete m;
		m = null;
		delete array;
		delete resultVBO;
		delete resultAABB;
	}

	GfxMaterial getMaterial()
	{
		return m;
	}

	void setMaterial(GfxMaterial m)
	{
		this.m = m;
	}

	void add(GfxVBO vbo, int x, int y, int z)
	{
		Entry e;
		e.aabb.min = Point3d(x * BuildWidth, y * BuildHeight, z * BuildDepth);
		e.aabb.max = Point3d((x+1) * BuildWidth, (y+1) * BuildHeight, (z+1) * BuildDepth);
		e.vbo = vbo;
		array ~= e;
	}

	void remove(GfxVBO vbo)
	{
		int i;
		foreach(e; array) {
			if (e.vbo is vbo)
				break;
			i++;
		}
		vbo.dereference();
		assert(i < array.length);
		array = array[0 .. i] ~ array[i+1 .. array.length];
	}

	void cullAndPush(GfxCull cull, GfxRenderQueue rq)
	{
		resultVBO.length = array.length;
		resultAABB.length = array.length;
		int i;
		foreach(vbo; array) {
			if (cull.f.check(vbo.aabb)) {
				resultVBO[i] = vbo.vbo;
				resultAABB[i++] = vbo.aabb;
			}
		}

		if (i == 0)
			return;

		result_num = i;
		rq.push(0.0, this);
	}
}


/**
 * Chunk group for RigidMesh VBO's.
 */
class ChunkVBOGroupRigidMesh : public ChunkVBOGroup
{
public:
	this(GfxWorld w)
	{
		super(w);
	}

	void drawFixed()
	{
		gluPushAndTransform(pos, rot);

		ChunkVBORigidMesh.drawArrayFixed(
			cast(ChunkVBORigidMesh[])resultVBO[0 .. result_num]);

		glPopMatrix();
	}

	void drawAttrib(GfxShader s)
	{
		gluPushAndTransform(pos, rot);

		ChunkVBORigidMesh.drawArrayAttrib(
			cast(ChunkVBORigidMesh[])resultVBO[0 .. result_num]);

		glPopMatrix();
	}
}


/**
 * Chunk group for CompactMesh VBO's.
 */
class ChunkVBOGroupCompactMesh : public ChunkVBOGroup
{
public:
	this(GfxWorld w)
	{
		super(w);
	}

	void drawFixed()
	{

	}

	void drawAttrib(GfxShader s)
	{
		const vertexSize = ChunkVBOCompactMesh.Vertex.sizeof;
		const void* vertOffset = null;
		const void* uvOffset = cast(void*)(3 * float.sizeof);
		const void* dataOffset = cast(void*)(4 * float.sizeof);

		gluPushAndTransform(pos, rot);

		auto vbos = cast(ChunkVBOCompactMesh[])resultVBO[0 .. result_num];

		foreach(vbo; vbos) {
			glBindVertexArrayCHARGE(vbo.vao);
			glDrawArrays(GL_QUADS, 0, vbo.numVerts);
		}

		glBindVertexArrayCHARGE(0);

		glPopMatrix();
	}
}
