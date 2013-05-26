// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.packers;

import charge.util.memory;

import miners.gfx.vbo;
import miners.builder.types;
import miners.builder.helpers;


/**
 * CompactPacker handled both indexed and non-indexed.
 */
struct PackerCompact
{
public:
	Packer base;
	int iv;
	int xOff;
	int yOff;
	int zOff;

public:
	alias ChunkVBOCompactMesh.Vertex Vertex;


	static void packI(Packer *_p, int x, int y, int z,
			  ubyte texture, ubyte light, sideNormal normal,
			  ushort u, ushort v)
	{
		int uI = u << 4;
		int vI = v << 4;

		auto p = cast(PackerCompact*)_p;
		Vertex *vert = p.newVert();

		mixin PositionCalculator!();

		vert.position[0] = xF;
		vert.position[1] = yF;
		vert.position[2] = zF;
		vert.u = cast(ushort)uI;
		vert.v = cast(ushort)vI;
		vert.light = light;
		vert.normal = normal;
		vert.texture = texture;
		vert.pad = 0;
	}

	static void packN(Packer *_p, int x, int y, int z,
			  ubyte texture, ubyte light, sideNormal normal,
			  ushort u, ushort v)
	{
		int uI = (texture & 0x0f) * 16;
		int vI = (texture & 0xf0);
		uI += u;
		vI += v;

		auto p = cast(PackerCompact*)_p;
		Vertex *vert = p.newVert();

		mixin PositionCalculator!();

		vert.position[0] = xF;
		vert.position[1] = yF;
		vert.position[2] = zF;
		vert.u = cast(ushort)uI;
		vert.v = cast(ushort)vI;
		vert.light = light;
		vert.normal = normal;
		vert.texture = texture;
		vert.pad = 0;
	}

	void ctor(int xOff, int yOff, int zOff, bool indexed)
	{
		this.base.pack = indexed ? &packI : &packN;

		this.iv = 0;
		this.xOff = xOff << VERTEX_SIZE_BIT_SHIFT;
		this.yOff = yOff << VERTEX_SIZE_BIT_SHIFT;
		this.zOff = zOff << VERTEX_SIZE_BIT_SHIFT;
	}

	Vertex* newVert()
	{
		return &(cast(Vertex*)&(&this)[1])[iv++];
	}

	Vertex[] getVerts()
	{
		auto v = cast(Vertex*)&(&this)[1];
		return v[0 .. iv];
	}


	/*
	 * Memory
	 */


	static PackerCompact* cAlloc(size_t numVerts)
	{
		size_t size;
		size = PackerCompact.sizeof +Vertex.sizeof * numVerts;
		auto ptr = cMalloc(size);

		return cast(PackerCompact*)ptr;
	}

	void cFree()
	{
		auto ptr = cast(void*)&this;
		.cFree(ptr);
	}
}
