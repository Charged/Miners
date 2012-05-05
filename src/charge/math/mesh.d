// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.math.mesh;

import std.outofmemory;

import charge.sys.file;
import charge.sys.logger;
import charge.sys.resource;
import charge.util.memory;


struct Vertex
{
	float x, y, z;
	float u, v;
	float nx, ny, nz;
}


struct Triangle
{
	uint i1, i2, i3;
}


struct RigidMeshStruct
{
	ubyte major;
	ubyte minor;
	ushort reserved1;
	uint reserved2;
	uint indexCount;
	uint vertCount;

	union {
		ulong fillerIndexiPtr;
		uint* index;
	}

	union {
		ulong fillerVertPtr;
		Vertex* verts;
	}
}


class RigidMesh : public Resource
{
public:
	const char[] uri = "mesh://";
	enum Types {
		INDEXED_TRIANGLES,
		QUADS,
	};

private:
	mixin Logging;
	Vertex *v;
	size_t num_verts;
	Triangle *t;
	size_t num_tris;
	Types tp;

public:
	static RigidMesh opCall(char[] name)
	{
		auto p = Pool();
		auto r = p.resource(uri, name);
		auto t = cast(RigidMesh)r;
		if (r !is null) {
			assert(t !is null);
			return t;
		}
		return load(p, name);
	}

	static RigidMesh opCall(Vertex verts[], Triangle tris[], Types type)
	{
		return new RigidMesh(Pool(), null, verts, tris, type);
	}

	~this()
	{
		cFree(v);
		cFree(t);
	}

	Vertex[] verts()
	{
		return v[0 .. num_verts];
	}

	Triangle[] tris()
	{
		return t[0 .. num_tris];
	}

	Types type()
	{
		return tp;
	}

protected:
	this(Pool p, char[] name, Vertex verts[], Triangle tris[], Types type)
	{
		super(p, uri, name);
		this.tp = type;
		this.num_verts = verts.length;
		this.num_tris = tris.length;
		this.v = cast(Vertex*)cMalloc(num_verts * Vertex.sizeof);
		if (tris !is null)
			this.t = cast(Triangle*)cMalloc(num_tris * Triangle.sizeof);

		if (v is null || (t is null && tris.length != 0)) {
			cFree(v);
			cFree(t);
			throw new std.outofmemory.OutOfMemoryException();
		}

		v[0 .. num_verts] = verts[0 .. $];

		if (tris !is null)
			t[0 .. num_tris] = tris[0 .. $];
		else
			assert(t is null);
	}

	static RigidMesh load(Pool p, char[] filename)
	{
		File file;
		void[] f;
		RigidMeshStruct *mod;
		Vertex verts[];
		Triangle tris[];

		file = FileManager(filename);
		if (file is null) {
			l.warn("file %s not found", filename);
			return null;
		}

		f = file.peekMem();
		scope(exit) delete file;

		/* Sanity checks */
		if (f.length < RigidMeshStruct.sizeof) {
			l.warn("file %s to small aborting", filename);
			goto err;
		}

		mod = cast(RigidMeshStruct*)f.ptr;

		if (mod.indexCount == 0 || mod.vertCount == 0) {
			l.warn("index or vertex count is zero in file ", filename);
			goto err;
		}

		size_t dataLength = RigidMeshStruct.sizeof + mod.indexCount * uint.sizeof +
			mod.vertCount * Vertex.sizeof;

		if (f.length != dataLength) {
			l.warn("file %s has wrong size", filename);
			goto err;
		}

		if (mod.indexCount % 3 != 0) {
			l.warn("index count in %s is not dividable by 3", filename);
			goto err;
		}

		// Indices storted right after the RigidMeshStruct
		auto tris_ptr = cast(Triangle*)(&mod[1]);
		tris = tris_ptr[0 .. mod.indexCount / 3];

		// Vertices storted after the indicies
		auto vert_ptr = cast(Vertex*)&tris_ptr[tris.length];
		verts = vert_ptr[0 .. mod.vertCount];

		/// TODO test all the indecies.
		l.info("Loaded ", filename);

		return new RigidMesh(p, filename, verts, tris, Types.INDEXED_TRIANGLES);

	err:
		return null;
	}
private:
	
}

class RigidMeshBuilder
{
	Vertex *verts;
	Triangle *tris;
	uint iv;
	uint it;
	RigidMesh.Types type;

	this(uint max_verts, uint max_tris, RigidMesh.Types type)
	{
		verts = cast(Vertex*)cMalloc(max_verts * Vertex.sizeof);
		tris = cast(Triangle*)cMalloc(max_verts * Triangle.sizeof);
		iv = 0;
		it = 0;
		this.type = type;
	}

	~this()
	{
		cFree(verts);
		cFree(tris);
	}

	final void vert(float x, float y, float z, float u, float v, float nx, float ny, float nz)
	{
		verts[iv].x = x;
		verts[iv].y = y;
		verts[iv].z = z;
		verts[iv].u = u;
		verts[iv].v = v;
		verts[iv].nx = nx;
		verts[iv].ny = ny;
		verts[iv].nz = nz;
		iv++;
	}

	final void tri(int i1, int i2, int i3)
	{
		tris[it++] = Triangle(i1, i2, i3);
	}

	final void triQuad4(bool flip)
	{
		uint iv = this.iv - 4;
		tri(iv+flip, iv+!flip, iv+3);
		tri(iv+3, iv+1+flip, iv+1+!flip);
	}

	final RigidMesh build()
	{
		return RigidMesh(verts[0 .. iv], tris[0 .. it], type);
	}
}
