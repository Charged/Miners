// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.gfx.vbo;

import charge.math.movable;
import charge.math.frustum;
import charge.sys.resource;

import miners.gfx.imports;
import miners.defines;


/**
 * ChunkVBO which is just the inbuilt RigidMeshVBO.
 */
class ChunkVBORigidMesh : charge.gfx.vbo.RigidMeshVBO
{
public:
	static ChunkVBORigidMesh opCall(RigidMeshBuilder mb, int x, int y, int z)
	{
		return new ChunkVBORigidMesh(mb);
	}

protected:
	this(RigidMeshBuilder builder)
	{
		super(null, null, builder.type,
		      builder.verts, builder.iv,
		      builder.tris, builder.it);
	}

}


/**
 * A slightly more compact version of ChunkVBORigidMesh.
 */
class ChunkVBOCompactMesh : GfxVBO
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
		return new ChunkVBOCompactMesh(verts);
	}

	void update(Vertex[] verts)
	{
		super.update(verts.ptr, verts.length * Vertex.sizeof,
		             cast(uint)verts.length, null, 0, 0);
	}

protected:
	this(Vertex[] verts)
	{
		super(null, null);

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

		glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
	}

}


/**
 * Base class for all Chunk VBO Groups, handles general managment.
 */
abstract class ChunkVBOGroup : GfxActor, GfxRenderable
{
public:
	mixin SysLogging;

	Entry[] array;
	GfxMaterial m;
	GfxVBO[] resultVbo;
	GfxVBO[] resultWaterVbo;
	int result_num;

	static struct Entry {
		ABox aabb;
		GfxVBO vbo;
	};

	this(GfxWorld w)
	{
		super(w);
		pos = Point3d();
		rot = Quatd();
		m = GfxMaterialManager.getDefault(w.pool);
	}

	~this()
	{
		assert(m is null);
		assert(array is null);
		assert(resultVbo is null);
	}

	override void breakApart()
	{
		breakApartAndNull(m);
		super.breakApart();
		delete array;
		delete resultVbo;
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
		e.aabb.min = Vector3f(x * BuildWidth, y * BuildHeight, z * BuildDepth);
		e.aabb.max = Vector3f((x+1) * BuildWidth, (y+1) * BuildHeight, (z+1) * BuildDepth);
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
		sysReference(&vbo, null);
		assert(i < array.length);
		array = array[0 .. i] ~ array[i+1 .. array.length];
	}

	override void cullAndPush(GfxCull cull, GfxRenderQueue rq)
	{
		resultVbo.length = array.length;
		int i;
		foreach(vbo; array) {
			if (cull.f.check(vbo.aabb)) {
				resultVbo[i++] = vbo.vbo;
			}
		}

		if (i == 0)
			return;

		result_num = i;
		rq.push(0.0, this);
	}

	abstract void drawAttrib(GfxShader s);
}


/**
 * Chunk group for RigidMesh VBO's.
 */
class ChunkVBOGroupRigidMesh : ChunkVBOGroup
{
public:
	this(GfxWorld w)
	{
		super(w);
	}

	override void drawAttrib(GfxShader s)
	{
		gluPushAndTransform(pos, rot);

		charge.gfx.vbo.RigidMeshVBO.drawArrayAttrib(
			cast(charge.gfx.vbo.RigidMeshVBO[])resultVbo[0 .. result_num]);

		glPopMatrix();
	}
}


/**
 * Chunk group for CompactMesh VBO's.
 */
class ChunkVBOGroupCompactMesh : ChunkVBOGroup
{
public:
	this(GfxWorld w)
	{
		super(w);
	}

	override void drawAttrib(GfxShader s)
	{
		const vertexSize = ChunkVBOCompactMesh.Vertex.sizeof;
		const void* vertOffset = null;
		const void* uvOffset = cast(void*)(3 * float.sizeof);
		const void* dataOffset = cast(void*)(4 * float.sizeof);

		gluPushAndTransform(pos, rot);

		auto vbos = cast(ChunkVBOCompactMesh[])resultVbo[0 .. result_num];

		foreach(vbo; vbos) {
			glBindVertexArrayCHARGE(vbo.vao);
			glDrawArrays(GL_QUADS, 0, vbo.numVerts);
		}

		glBindVertexArrayCHARGE(0);

		glPopMatrix();
	}
}
