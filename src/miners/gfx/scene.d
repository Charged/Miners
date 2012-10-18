// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.gfx.scene;

import charge.charge;
import charge.math.mesh;

import miners.options;
import miners.gfx.imports;


class BackgroundScene
{
public:
	Options opts;
	GfxTexture texture;


protected:
	GfxWorld world;
	GfxTextureTarget target;
	GfxRenderer renderer;


	this(Options opts)
	{
		this.opts = opts;
		this.world = new GfxWorld();
		this.renderer = new GfxForwardRenderer();
	}

	~this()
	{
		assert(world is null);
		assert(target is null);
		assert(texture is null);
		assert(renderer is null);
	}

	void close()
	{
		releaseResources();

		delete world;
		delete renderer;
	}

	void releaseResources()
	{
		target = null;
		renderer.target = null;
		sysReference(&texture, null);
	}

	void makeResources(uint w, uint h)
	{
		if (target is null ||
		    target.width != w ||
		    target.height != h) {

			target = null;
			renderer.target = null;
			sysReference(&texture, null);

			texture = target = GfxTextureTarget(null, w, h);
		}
	}
}

class ClassicBackgroundScene : BackgroundScene
{
public:
	GfxProjCamera camera;
	GfxSimpleLight light;
	GfxFog fog;


public:
	this(Options opts)
	{
		super(opts);
		this.camera = new GfxProjCamera();
		this.fog = new GfxFog();
		this.light = new GfxSimpleLight(world);

		fog.color = Color4f(Color4b(0xaacbffff));
		fog.start = 128;
		fog.stop = 1024;
		world.fog = fog;

		Triangle[2] tris;
		Vertex[4] verts;
		int i;

		for (int x = 0; x < 2; x++) {
			for (int z = 0; z < 2; z++) {
				verts[i].x = x * 4000 - 2000;
				verts[i].y = 0;
				verts[i].z = z * 4000 - 2000;
				verts[i].u = x * 4000;
				verts[i].v = z * 4000;
				verts[i].nx = 0;
				verts[i].ny = 1;
				verts[i].nz = 0;
				i++;
			}
		}

		tris[0] = Triangle(0, 1, 2);
		tris[1] = Triangle(3, 2, 1);

		GfxMaterial m;

		auto water = getModel(verts, tris);
		m = water.getMaterial();
		m["tex"] = opts.classicSides[8];


		// Use the old verts but modify them a bit for the sky.
		foreach(ref vert; verts)
			vert.y = 128;

		tris[0] = Triangle(0, 2, 1);
		tris[1] = Triangle(3, 1, 2);

		auto sky = getModel(verts, tris);
		m = sky.getMaterial();
		m["color"] = Color4f(Color4b(0x80b1ffff));
	}

	void close()
	{
		light = null;
		camera = null;
		fog = null;

		super.close();
	}

	void render(GfxProjCamera origCam, GfxSimpleLight origSl,
	            uint w, uint h)
	{
		makeResources(w, h);

		// Copy from parent scene.
		light.rotation = origSl.rotation;

		camera.rotation = origCam.rotation;
		camera.fov = origCam.fov;
		camera.ratio = origCam.ratio;

		// Fixed.
		light.diffuse = Color4f(.1, .1, .1, 1);
		light.ambient = Color4f(.9, .9, .9, 1);

		camera.position = Point3d(0, 2, 0);
		camera.far = 1024;
		camera.near = 1;

		renderer.target = target;
		renderer.render(camera, world);
	}


private:
	GfxRigidModel getModel(Vertex[] verts, Triangle[] tris)
	{
		auto vbo = GfxRigidMeshVBO(
			RigidMesh.Types.INDEXED_TRIANGLES, verts, tris);
		return GfxRigidModel(world, vbo);
	}
}
