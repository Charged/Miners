// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.gfx.vbo;

import charge.math.box;
import minecraft.gfx.imports;


/**
 * ChunkVBO which is just the inbuilt RigidMeshVBO.
 */
class ChunkVBORigidMesh : public charge.gfx.vbo.RigidMeshVBO
{
public:
	static ChunkVBORigidMesh opCall(RigidMeshBuilder mb, int x, int z)
	{
		return new ChunkVBORigidMesh(charge.sys.resource.Pool(), mb, x, z);
	}

protected:
	this(charge.sys.resource.Pool p, RigidMeshBuilder mb, int x, int z)
	{
		auto name = std.string.format("mc/vbo/chunk.%s.%s.rigid", x, z);
		super(p, name, mb);
	}

}


/**
 * A slightly more compact version of ChunkVBORigidMesh.
 */
class ChunkVBOCompactMesh : public GfxVBO
{
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

	static ChunkVBOCompactMesh opCall(Vertex[] verts, int x, int z)
	{
		return new ChunkVBOCompactMesh(charge.sys.resource.Pool(), verts, x, z);
	}

protected:
	this(charge.sys.resource.Pool p, Vertex[] verts, int x, int z)
	{
		auto str = std.string.format("mc/vbo/chunk.%s.%s.compact-mesh", x, z);
		super(p, str, true, verts.ptr,
		      verts.length * Vertex.sizeof,
		      cast(uint)verts.length,
		      null, 0, 0);
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

	void add(GfxVBO vbo, int x, int z)
	{
		Entry e;
		e.aabb.min = Point3d(x * 16, -0, z * 16);
		e.aabb.max = Point3d((x+1) * 16, 128, (z+1) * 16);
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

		glEnableVertexAttribArray(0); // pos
		glEnableVertexAttribArray(1); // uv
		glEnableVertexAttribArray(2); // data

		foreach (vbo; vbos) {
			glBindBufferARB(GL_ARRAY_BUFFER_ARB, vbo.vboVerts);

			/* Shame that we need to set up this binding on each draw */
			glVertexAttribPointer(0, 3, GL_FLOAT, false, vertexSize, vertOffset);  // pos
			glVertexAttribPointer(1, 2, GL_SHORT, false, vertexSize, uvOffset); // uv
			glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, false, vertexSize, dataOffset); // data
			glDrawArrays(GL_QUADS, 0, vbo.numVerts);
		}

		glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);

		glDisableVertexAttribArray(0); // pos
		glDisableVertexAttribArray(1); // uv
		glDisableVertexAttribArray(2); // data

		glPopMatrix();
	}
}
