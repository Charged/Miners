// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.skeleton;

import charge.util.memory;
import charge.util.vector;

import charge.math.quatd;
import charge.math.point3d;
import charge.math.vector3d;

import charge.sys.logger;
import charge.sys.resource;

import charge.gfx.gl;
import charge.gfx.cull;
import charge.gfx.world;
import charge.gfx.shader;
import charge.gfx.material;
import charge.gfx.renderqueue;

static import charge.gfx.vbo;


/**
 * Part of a skeleton. 
 *
 * Each bone is rotated and moved by its parent absolute location.
 *
 * this.absPos = Parent.absRot + Parent.absRot * this.offset;
 * this.absRot = Parent.absPos * this.rot;
 *
 * The root bone is the model itself and are handled by the
 * graphics pipeline, so any references to it are free.
 */
struct Bone
{
	Quatd rot;
	Vector3d offset;
	uint parent;
	uint __pad;
}

/**
 * Very very simple skeleton.
 */
class SimpleSkeleton : Actor, Renderable
{
public:
	cMemoryArray!(Bone) bones;

	static struct Vertex
	{
		float pos[3];
		float uv[2];
		float normal[3];
		float bone;
	}

protected:
	Material m;
	VBO vbo;

public:
	this(World w, VBO vbo, Bone bones[])
	{
		super(w);

		reference(&this.vbo, vbo);

		this.bones.allocCopy(bones);
		this.m = MaterialManager.getDefault();
		(cast(SimpleMaterial)this.m).skel = true;
	}

	~this()
	{
		delete m;
		reference(&vbo, null);
		bones.free();
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
	}

	void drawAttrib(Shader s)
	{
		gluPushAndTransform(pos, rot);

		float stuff[4*64*2];
		for (int i, k; k < bones.length; i+=8, k++) {
			auto q = bones.ptr[k].rot;
			auto t = bones.ptr[k].offset;

			stuff[i+0] = q.x; stuff[i+1] = q.y; stuff[i+2] = q.z; stuff[i+3] = q.w;
			stuff[i+4] = t.x; stuff[i+5] = t.y; stuff[i+6] = t.z; stuff[i+7] =   0;
		}
		s.float4("bones", cast(uint)bones.length*2, stuff.ptr);

		vbo.draw();

		glPopMatrix();
	}

	/**
	 * SimpleSkeleton mesh vbo.
	 *
	 * @ingroup Resource
	 */
	static class VBO : charge.gfx.vbo.VBO
	{
	protected:
		const void* positionOffset = null;
		const void* uvOffset = cast(void*)(float.sizeof * 3);
		const void* normalOffset = cast(void*)(float.sizeof * (3 + 2));

	public:
		static VBO opCall(Vertex verts[])
		{
			return new VBO(Pool(), verts);
		}

		this(Pool p, Vertex verts[])
		{
			super(p, null);

			update(verts.ptr, verts.length * Vertex.sizeof,
			       cast(uint)verts.length, null, 0, 0);

			if (!vao)
				return;

			glBindVertexArrayCHARGE(vao);

			glEnableVertexAttribArray(0); // pos
			glEnableVertexAttribArray(1); // uv
			glEnableVertexAttribArray(2); // normal + bone

			glBindBufferARB(GL_ARRAY_BUFFER_ARB, vboVerts);

			const size = Vertex.sizeof;
			glVertexAttribPointer(0, 3, GL_FLOAT, false, size, positionOffset); // pos
			glVertexAttribPointer(1, 2, GL_FLOAT, false, size, uvOffset);       // uv
			glVertexAttribPointer(2, 4, GL_FLOAT, false, size, normalOffset);   // normal + bone

			glBindVertexArrayCHARGE(0);

			glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
		}

		final void draw()
		{
			glBindVertexArrayCHARGE(vao);

			glDrawArrays(GL_QUADS, 0, numVerts);

			glBindVertexArrayCHARGE(0);
		}
	}
}
