// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.phy.geom;

import charge.phy.ode;
import charge.math.mesh;
import charge.sys.logger;
import charge.sys.resource;

class Geom
{
package:
	dGeomID geom;
}

class GeomCube : Geom
{
	this(float x, float y, float z)
	{
		geom = dCreateBox(null, x, y, z);
		dGeomSetData(geom, null);
	}
}

class GeomSphere : Geom
{
	this(float radius)
	{
		geom = dCreateSphere(null, radius);
		dGeomSetData(geom, null);
	}
}

class GeomMeshData : Resource
{
public:
	const string uri = "geom://";

private:
	mixin Logging;
	RigidMesh rigidMesh;
	dTriMeshDataID mesh;

public:
	static GeomMeshData opCall(string filename)
	{
		return GeomMeshData(Pool(), filename);
	}

	static GeomMeshData opCall(Pool p, string filename)
	{
		auto r = p.resource(uri, filename);
		auto d = cast(GeomMeshData)r;
		if (r !is null) {
			assert(d !is null);
			return d;
		}

		auto m = RigidMesh(filename);
		if (m is null) {
			l.warn("failed to load %s", filename);
			return null;
		}
		auto ret = new GeomMeshData(p, filename, m);
		Resource.reference(&m, null);
		return ret;
	}

	~this()
	{
		Resource.reference(&rigidMesh, null);
		dGeomTriMeshDataDestroy(mesh);
	}

protected:
	this(Pool p, string filename, RigidMesh mesh)
	{
		super(p, uri, filename);

		Resource.reference(&rigidMesh, mesh);

		this.mesh = dGeomTriMeshDataCreate();
		dGeomTriMeshDataBuildSingle(
			this.mesh,
			cast(float*)&mesh.verts[0], Vertex.sizeof, cast(int)mesh.verts.length,
			cast(int*)&mesh.tris[0], cast(int)mesh.tris.length * 3, Triangle.sizeof);
	}
}

class GeomMesh : Geom
{
private:
	GeomMeshData data;
	dTriMeshDataID mesh_data;

public:
	this(string filename)
	{
		data = GeomMeshData(filename);

		if (data is null)
			throw new Exception("Model not found!");

		geom = dCreateTriMesh(null, data.mesh, null, null, null);
		dGeomSetData(geom, null);
	}

	~this()
	{
		dGeomDestroy(geom);
		Resource.reference(&data, null);
	}
}
