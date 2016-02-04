// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Geom (s).
 */
module charge.phy.geom;

import charge.phy.ode;
import charge.math.mesh;
import charge.sys.logger;
import charge.sys.resource : Pool, Resource, reference;


class Geom
{
package:
	dGeomID geom;

public:
	~this()
	{
		assert(geom is null);
	}

	void breakApart()
	{
		if (geom !is null) {
			dGeomDestroy(geom);
			geom = null;
		}
	}
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

/**
 * Backing data for @link charge.phy.geom.GeomMesh GeomMesh @endlink.
 *
 * @ingroup Resource
 */
class GeomMeshData : Resource
{
public:
	enum string uri = "geom://";

private:
	mixin Logging;
	RigidMesh rigidMesh;
	dTriMeshDataID mesh;

public:
	static GeomMeshData opCall(Pool p, string filename)
	{
		auto r = p.resource(uri, filename);
		auto d = cast(GeomMeshData)r;
		if (r !is null) {
			assert(d !is null);
			return d;
		}

		auto m = RigidMesh(p, filename);
		if (m is null) {
			l.warn("failed to load %s", filename);
			return null;
		}
		auto ret = new GeomMeshData(p, filename, m);
		reference(&m, null);
		return ret;
	}

	~this()
	{
		reference(&rigidMesh, null);
		dGeomTriMeshDataDestroy(mesh);
	}

protected:
	this(Pool p, string filename, RigidMesh mesh)
	{
		super(p, uri, filename);

		reference(&rigidMesh, mesh);

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
	this(Pool p, string filename)
	{
		data = GeomMeshData(p, filename);

		if (data is null)
			throw new Exception("Model not found!");

		geom = dCreateTriMesh(null, data.mesh, null, null, null);
		dGeomSetData(geom, null);
	}

	~this()
	{
		assert(data is null);
	}

	override void breakApart()
	{
		reference(&data, null);
		super.breakApart();
	}
}
