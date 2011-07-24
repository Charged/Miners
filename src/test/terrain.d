// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module test.terrain;

import std.math;
import std.stdio;
import std.string;
import std.random;

import lib.sdl.sdl;

import charge.charge;

import charge.math.mesh;


version(Windows) {
	uint ntohl(uint i) {
		std.stdio.writefln("WARNING: Programer to lazy to fix ntohl");
		assert(i == 0);
		return i;
	}
} else {
	extern(C) uint ntohl(uint);
}

class Terrain : public GameActor
{
protected:
	GfxRigidModel gfx;
	PhyStatic phy;
	uint seed;
	uint map_width;
	uint map_depth;
	ubyte map_height[];
	ubyte map_type[];
	bool map_random; /** Us random variations */
	int tile_size; /** size of each tile */
	int tile_height; /** height of each tile */
	int tile_steps; /** number of rows and colums per tile */

	static ubyte tile_info_height[6][4] = [
		[0, 1, 1, 1], /*  0-3  downslope in one corner */
		[0, 0, 1, 0], /*  4-7  upslope in one corner */
		[0, 1, 2, 1], /*  8-11 steep slope */
		[0, 0, 1, 1], /* 12-15 flat slope */
		[1, 0, 1, 0], /* 16-19 two high, two low */
		[0, 0, 0, 0], /* 20    flat */
	];

public:
	void hackWater()
	{
		GfxRigidModel gfx;
		Triangle[] tris;
		Vertex[] verts;
		char[] name;
		int i;

		tris.length = 2;
		verts.length = 4;

		for (int x = 0; x < 2; x++) {
			for (int z = 0; z < 2; z++) {
				verts[i].x = x * map_width * tile_size;
				verts[i].y = (tile_height * 4) - (0.2f * tile_height);
				verts[i].z = z * map_depth * tile_size;
				verts[i].u = x * map_width;
				verts[i].v = z * map_depth;
				verts[i].nx = 0;
				verts[i].ny = 1;
				verts[i].nz = 0;
				i++;
			}
		}

		tris[0] = Triangle(0, 1, 2);
		tris[1] = Triangle(3, 1, 2);

		auto rm = RigidMesh(verts, tris, RigidMesh.Types.INDEXED_TRIANGLES);
		name = rm.getName();

		gfx = GfxRigidModel(w.gfx, name);
		gfx.position = Point3d(16 * -64, 0.1, 16 * -64);

		gfx.setMaterial(new GfxSimpleMaterial());
		gfx.getMaterial()["tex"] = "res/water_tile.png";
		rm.dereference();
	}

	this(GameWorld w, uint seed)
	{
		int num_tiles;
		int num_verts;
		int num_tris;
		Triangle[] tris;
		Vertex[] verts;
		char[] name;
		int width, depth;
		int iv, it;
		ubyte map[];

		super(w);

		width = 128;
		depth = 128;
		this.seed = seed;
		this.map_width = width;
		this.map_depth = depth;
		this.tile_size = 16;
		this.tile_height = 8;
		this.tile_steps = 4;
		num_tiles = width * depth;
		map_height.length = num_tiles;
		map_type.length = num_tiles;


		map = loadSimCity2000Level("res/democity.sc2");

		mapFixHeightIssues(width, depth, map);
		mapFromHeightData(width, depth, map);

		calcNumVertTri(num_verts, num_tris);
		//calcNumVertTriSub(num_verts, num_tris);

		verts.length = num_verts;
		tris.length = num_tris;
		for (int z = 0; z < depth; z++) {
			for (int x = 0; x < width; x++) {
				makeTileTriangles(x, z, iv, it, tris);
				makeTileVertices(x, z, iv, verts);
				//makeTileVerticesSub(x, z, iv, verts);
				//makeTileTrianglesSub(x, z, iv, it, tris);
				//iv += num_tile_vertices;
				//it += num_tile_triangles;
			}
		}

		auto rm = RigidMesh(verts, tris, RigidMesh.Types.INDEXED_TRIANGLES);
		name = rm.getName();

		gfx = GfxRigidModel(w.gfx, name);
		phy = new charge.phy.actor.Static(w.phy, new charge.phy.geom.GeomMesh(name));

		gfx.position = Point3d(16 * -64, 0, 16 * -64);
		phy.position = gfx.position;
		phy.rotation = gfx.rotation;

		gfx.setMaterial(new GfxSimpleMaterial());
		gfx.getMaterial().setTexture("tex", "res/dirt_tile.png");
		rm.dereference();


		hackWater();
	} 

	~this()
	{
		delete gfx;
		delete phy;
	}

private:
	static final int imin(int a, int b) { return a < b ? a : b; }
	static final int imax(int a, int b) { return a > b ? a : b; }
	static final int imin4(int a, int b, int c, int d) { return imin(imin(a, b), imin(c, d)); }
	static final int imax4(int a, int b, int c, int d) { return imax(imax(a, b), imax(c, d)); }

	static final bool isTypeFlat(int type)
	{
		const bool table[6] = [false, false, true, true, false, true];
		return table[type/4];
	}

	/*
	 * Given 4 height corners of a tile return the type.
	 */
	static final ubyte calcType(int lf, int ln, int rf, int rn, int min, int max)
	{
		const ubyte[15] table = [20,  6,  7, 15,  5, 14, 17,  2,  4, 16, 12,  3, 13,  1, 0];
		if (max - min == 2) {
			if (lf - min == 0)
				return 8;
			else if (ln - min == 0)
				return 9;
			else if (rn - min == 0)
				return 10;
			else
				return 11;
		} else {
			return table[(lf - min) << 0 | (ln - min) << 1 | (rf - min) << 2 | (rn - min) << 3];
		}
	}

	static final int getCornerHeight(int type, int x, int z)
	{
		int i = (z << 1 | x) ^ z;
		i += type;
		return tile_info_height[type / 4][i % 4];
	}

	final bool isTileFlat(int tx, int tz)
	{
		return isTypeFlat(getType(tx, tz));
	}

	final ubyte getType(int x, int z)
	{
		return map_type[x + map_width * z];
	}

	final void setType(int x, int z, ubyte v)
	{
		map_type[x + map_width * z] = v;
	}

	final ubyte getHeight(int x, int z)
	{
		return map_height[x + map_width * z];
	}

	final void setHeight(int x, int z, ubyte v)
	{
		map_height[x + map_width * z] = v;
	}


	/*
	 * Mesh data generatores.
	 */


	/*
	 * Calculate number of verties and triangles for
	 * non-subdevided tiles.
	 */
	void calcNumVertTri(out int verts, out int tris)
	{
		
		for (int x; x < map_width; x++) {
			for (int z; z < map_depth; z++) {
				if (isTileFlat(x, z)) {
					verts += 4;
				} else {
					verts += 6;
				}
			}
		}
		tris = map_width * map_depth * 2;
	}

	/*
	 * Generate vertices for a tile at position the given position, with no subdevision.
	 */
	void makeTileVertices(int tx, int tz, ref int iv, ref Vertex[] verts)
	{
		const int index[4] = [0, 3, 1, 2];
		ubyte type = getType(tx, tz);
		int height = getHeight(tx, tz);
		int i;
		Vector3d n;

		void gen(int x, int z)
		{
			auto v = &verts[iv++];
			v.x = (tx + x) * tile_size;
			v.y = (getCornerHeight(type, x, z) + height) * tile_height;
			v.z = (tz + z) * tile_size;

			v.u = x;
			v.v = z;

			v.nx = cast(float)n.x;
			v.ny = cast(float)n.y;
			v.nz = cast(float)n.z;
		}

		void calcNormal(int x, int z)
		{
			int dx = getCornerHeight(type, 1-x, z) - getCornerHeight(type, x, z);
			int dz = getCornerHeight(type, x, 1-z) - getCornerHeight(type, x, z);

			if (x == 0 && z == 0)
				n = Vector3d(0, tile_height * dz, tile_size) *
				    Vector3d(tile_size, tile_height * dx, 0);
			else if (x == 0 && z == 1)
				n = Vector3d(tile_size, tile_height * dx, 0) *
				    Vector3d(0, tile_height * dz, -tile_size);
			else if (x == 1 && z == 0)
				n = Vector3d(-tile_size, tile_height * dx, 0) *
				    Vector3d(0, tile_height * dz, tile_size);
			else
				n = Vector3d(0, tile_height * dz, -tile_size) *
				    Vector3d(-tile_size, tile_height * dx, 0);
			n.normalize();
		}

		if (isTypeFlat(type)) {
			calcNormal(0, 0);
			n.normalize();
			gen(0, 0);
			gen(0, 1);
			gen(1, 0);
			gen(1, 1);
		} else {
			calcNormal(0, type % 2);
			gen(0, 0);
			gen(0, 1);
			gen(1, type % 2);

			calcNormal(1, (type + 1) % 2);
			n.normalize();
			gen(1, 1);
			gen(1, 0);
			gen(0, (type + 1)% 2);
		}
	}

	/*
	 * Generate a tringles for a tile at the given position, with no subdevision.
	 */
	void makeTileTriangles(int tx, int tz, int iv, ref int it, ref Triangle[] tris)
	{
		ubyte type = getType(tx, tz);
		int lf = iv; /* left far */
		int rf = iv + 2;
		int ln = iv + 1;
		int rn = iv + 3;

		if (isTypeFlat(type)) {
			if (type % 2) {
				tris[it++] = Triangle(lf, rn, rf);
				tris[it++] = Triangle(ln, rn, lf);
			} else {
				tris[it++] = Triangle(lf, ln, rf);
				tris[it++] = Triangle(ln, rn, rf);
			}
		} else {
			tris[it++] = Triangle(iv+0, iv+1, iv+2);
			tris[it++] = Triangle(iv+3, iv+4, iv+5);
		}
	}


	/*
	 * Mesh generators subdevision versions.
	 */


	/*
	 * Calculate number of verties and triangles for
	 * non-subdevided tiles.
	 */
	void calcNumVertTriSub(out int verts, out int tris)
	{
		int num_tiles = map_width * map_depth;
		int num_tile_vertices = (tile_steps + 1) * (tile_steps + 1);
		int num_tile_triangles = tile_steps * tile_steps * 2;
		int num_verts = num_tile_vertices * num_tiles;
		int num_tris = num_tile_triangles * num_tiles;
	}

	/*
	 * Generate vertices for a tile.
	 */
	void makeTileVerticesSub(int tx, int tz, int iv, ref Vertex[] verts)
	{
		ubyte type = getType(tx, tz);
		int height = getHeight(tx, tz);
		int steps = tile_steps;
		int h, hz;
		int lf_h = tile_info_height[type / 4][(0 + type) % 4];
		int rf_h = tile_info_height[type / 4][(1 + type) % 4];
		int ln_h = tile_info_height[type / 4][(3 + type) % 4];
		int rn_h = tile_info_height[type / 4][(2 + type) % 4];
		int dz = ln_h - lf_h;
		int dx = rf_h - lf_h;
		int dx2 = rn_h - ln_h;

		tx *= steps;
		tz *= steps;
		hz = (height + lf_h) * steps;

		for (int z; z <= steps; z++) {
			h = hz;
			for (int x; x <= steps; x++) {
				genTileVertexSub(tx + x, h, tz + z, x, z, verts[iv++]);

				if (type % 2) {
					if (x < z)
						h += dx2;
					else
						h += dx;
				} else {
					if ((steps - z) <= x)
						h += dx2;
					else
						h += dx;
				}
			}
			hz += dz;
		}
	}

	/*
	 * Generate triangles for a tile.
	 */
	void makeTileTrianglesSub(int tx, int tz, int iv, int it, ref Triangle[] tris)
	{
		ubyte type = getType(tx, tz);

		writefln("(%s %s) %s", tx, tz, it);
		for (int z; z < tile_steps; z++) {
			for (int x; x < tile_steps; x++) {
				int lf = z * (tile_steps + 1) + x + iv;
				int rf = lf + 1;
				int ln = (z + 1) * (tile_steps + 1) + x + iv;
				int rn = ln + 1;
				if (type % 2) {
					tris[it++] = Triangle(lf, rn, rf);
					tris[it++] = Triangle(ln, rn, lf);
				} else {
					tris[it++] = Triangle(lf, ln, rf);
					tris[it++] = Triangle(ln, rn, rf);
				}
			}
		}
	}

	/*
	 * Generate a single vertex for a tile.
	 */
	void genTileVertexSub(int x, int y, int z, int u, int v, ref Vertex vert)
	{
		rand_seed(x + seed, z);
		float rv = map_random ? (rand() % 16 / 64f) : 0;
		vert.x = x * (tile_size / tile_steps);
		vert.y = y * (tile_height / tile_steps) + rv;
		vert.z = z * (tile_size / tile_steps);

		vert.u = u / cast(float)tile_steps;
		vert.v = v / cast(float)tile_steps;

		vert.nx = 0;
		vert.ny = 1;
		vert.nz = 0;
	}


	/*
	 * Level loaders.
	 */


	/*
	 * Turns a height map of ubytes into map_type and map_height information.
	 *
	 * One constraint no neighbouring tiles may differ more then one in height.
	 */
	void mapFromHeightData(int width, int depth, ubyte map[])
	{
		/* Lookup height data, while makeing sure we do not go out of bounds. */
		int inH(int x, int z)
		{
			if (x < 0)
				x = 0;
			else if (x >= width)
				x = width - 1;
			if (z < 0)
				z = 0;
			else if (z >= depth)
				z = depth - 1;

			return map[z + map_width * x];
		}

		/*
		 * Calculate the height for a given corner of a tile.
		 *
		 * The magical plus one at the end gives us steep slopes.
		 */
		int calcPoint(int x, int z) {
			/* int h = inH(x+1, z+1) + inH(x+1, z) + inH(x, z+1) + inH(x, z) + 1;
			return h / 4;
			*/
			return imax4(inH(x-1, z-1), inH(x-1, z), inH(x, z-1), inH(x, z));
		}

		/* for each tile calculate type and height */
		for (int x; x < depth; x++) {
			for (int z; z < width; z++) {
				int lf = calcPoint(x    , z    );
				int ln = calcPoint(x    , z + 1);
				int rf = calcPoint(x + 1, z    );
				int rn = calcPoint(x + 1, z + 1);

				int min = imin(imin(lf, ln), imin(rf, rn));
				int max = imax(imax(lf, ln), imax(rf, rn));

				setHeight(x, z, cast(ubyte)min);
				setType(x, z, calcType(lf, ln, rf, rn, min, max));
			}
		}
	}

	/*
	 * Fixes any height issues with a map.
	 */
	void mapFixHeightIssues(int width, int depth, ubyte map[])
	{
		/* Lookup height data, while makeing sure we do not go out of bounds. */
		int inH(int x, int z)
		{
			if (x < 0)
				x = 0;
			else if (x >= width)
				x = width - 1;
			if (z < 0)
				z = 0;
			else if (z >= depth)
				z = depth - 1;

			return map[z + width * x];
		}

		/* Set height data. */
		void outH(int x, int z, int h)
		{
			map[z + width * x] = cast(ubyte)h;
		}

		void fix(int x, int z)
		{
			if (x < 0 || x >= width)
				return;
			if (z < 0 || z >= depth)
				return;

			int h = inH(x, z);

			int u = inH(x    , z - 1);
			int d = inH(x    , z + 1);
			int l = inH(x - 1, z    );
			int r = inH(x + 1, z    );

			h++;
			int max = imax4(u, d, l, r);
			if (h >= max)
				return;

			outH(x, z, max - 1);

			fix(x  , z-1);
			fix(x  , z+1);
			fix(x-1, z  );
			fix(x+1, z  );
		}

		/* for each tile calculate type and height */
		for (int x; x < depth; x++) {
			for (int z; z < width; z++) {
				fix(x, z);
			}
		}
	}

	/*
	 * Load a SimCity2000 level, only loads height data.
	 *
	 * Return a height map to be used with mapFromHeightData.
	 */
	ubyte[] loadSimCity2000Level(char[] name)
	{
		struct file_header {
			char[4] form;
			int size;
			char[4] scdh;
		};

		struct segment_header {
			char[4] seg_type;
			int seg_size;
		};

		auto m = std.file.read(name);
		file_header *fh;
		segment_header *f;
		void *ptr = m.ptr;
		short *sptr;
		ubyte map[];

		if (ptr is null)
			return null;

		fh = cast(file_header*)ptr;
		if (m.length != ntohl(fh.size) + 8)
			return null;

		/* point to the segments after the file header */
		ptr += 12;

		/* search for the ALTM altitude segment */
		while (ptr < m.ptr + m.length) {
			f = cast(segment_header*)(ptr);
			if (f.seg_type == "ALTM")
				break;

			/* jump to next segment */
			ptr += ntohl(f.seg_size) + 8;
		}

		/* could not find the segment bail */
		if (ptr >= m.ptr + m.length)
			return null;

		/* setup a pointer pointing to the data after the header */
		sptr = cast(short *)(ptr + 8);

		/* allocate data */
		map.length = 128 * 128;

		/* loop over the data reading the height data */
		for (int i, z; z < 128; z++) {
			for (int x; x < 128; x++, i++) {
				map[i] = cast(ubyte)((sptr[i] & 0x0f00) >> 8);
			}
		}

		return map;
	}
}

class Game : public GameSimpleApp
{
private:
	bool moveing;
	double heading;
	double pitch;
	bool force;
	bool inverse;
	bool forward;
	bool backwards;
	bool projective;

	Car car;

	GameWorld w;

	Ticker removable[];

	Terrain terrain;

	GfxSimpleLight sl;
	GfxSpotLight spl;
	GfxProjCamera projcam;
	GfxIsoCamera isocam;
	GfxRenderer r;
	GfxRigidModel model;

public:
	mixin SysLogging;

	this(char[][] args)
	{
		/* This will initalize Core and other important things */
		super();

		running = true;

		GfxRenderer.init();

		w = new GameWorld();
		sl = new GfxSimpleLight();
		projcam = new GfxProjCamera();
		isocam = new GfxIsoCamera(400, 300, -500, 500);
		terrain = new Terrain(w, 0);
		r = GfxRenderer.create();

		projcam.position = Point3d(0.0, 5.0, 15.0);
		sl.rotation = Quatd(PI / 4, Vector3d.Up) * Quatd(-PI / 4, Vector3d.Left);

		w.gfx.add(sl);
		auto pl = new GfxPointLight();
		pl.position = Point3d(0.0, 0.0, 0.0);
		pl.size = 20;
		w.gfx.add(pl);
		spl = new GfxSpotLight();
		spl.position = Point3d(0.0, 5.0, 15.0);
		spl.length = 150;
		w.gfx.add(spl);

		w.phy.setStepLength(10);


		new GameStaticCube(w, Point3d(0.0, -5.0, 0.0), Quatd(), 200.0, 10.0, 200.0);

		//new GameStaticRigid(w, Point3d(0.0, 0.0, -15.0), Quatd(), "res/bath.bin", "res/bath.bin");
		heading = 0.0;
		pitch = 0.0;
		l.info("Press 's' 'c' 'f' 'g' for fun");

		car = new Car(w, Point3d(0.0, 3.0, -6.0));
		new Car(w, Point3d(0.0, 3.0, 10.0));
	}

	~this()
	{
		delete w;
	}

protected:
	void addRemovable(Ticker t)
	{
		removable ~= t;
	}

	void input()
	{
		SDL_Event e;

		while(SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT) {
				running = false;
			}

			if (e.type == SDL_KEYDOWN) {
				if (e.key.keysym.sym == SDLK_r) {
					car.car.position = Point3d(0.0, 3.0 + 8 * 7, 16.0);
					car.car.rotation = Quatd();
				}
				if (e.key.keysym.sym == SDLK_f)
					force = true;
				if (e.key.keysym.sym == SDLK_g)
					inverse = true;
				if (e.key.keysym.sym == SDLK_UP)
					forward = true;
				if (e.key.keysym.sym == SDLK_DOWN)
					backwards = true;



				if (e.key.keysym.sym == SDLK_RIGHT) {
					double s = -PI * 0.20;
					car.car.setTurning(s, 0.01);
				}
				if (e.key.keysym.sym == SDLK_LEFT) {
					double s = PI * 0.20;
					car.car.setTurning(s, 0.01);
				}

			}

			if (e.type == SDL_KEYUP) {

				if (e.key.keysym.sym == SDLK_UP)
					forward = false;
				if (e.key.keysym.sym == SDLK_DOWN)
					backwards = false;
				if (e.key.keysym.sym == SDLK_RIGHT) {
					car.car.setTurning(0, 0.15);
				}
				if (e.key.keysym.sym == SDLK_LEFT) {
					car.car.setTurning(0, 0.15);
				}
				if (e.key.keysym.sym == SDLK_f)
					force = false;
				if (e.key.keysym.sym == SDLK_v)
					projective = !projective;
				if (e.key.keysym.sym == SDLK_g)
					inverse = false;
				if (e.key.keysym.sym == SDLK_ESCAPE)
					running = false;
				if (e.key.keysym.sym == SDLK_s)
					addRemovable(new Sphere(w, Point3d(0, 1, 0)));
				if (e.key.keysym.sym == SDLK_c)
					addRemovable(new Cube(w, Point3d(0, 1, 0)));
				if (e.key.keysym.sym == SDLK_p) {
					addRemovable(new Cube(w, Point3d( 4, 1, 0)));
					addRemovable(new Cube(w, Point3d( 3, 1, 0)));
					addRemovable(new Cube(w, Point3d( 2, 1, 0)));
					addRemovable(new Cube(w, Point3d( 1, 1, 0)));
					addRemovable(new Cube(w, Point3d( 0, 1, 0)));
					addRemovable(new Cube(w, Point3d(-1, 1, 0)));
					addRemovable(new Cube(w, Point3d(-2, 1, 0)));
					addRemovable(new Cube(w, Point3d(-3, 1, 0)));
					addRemovable(new Cube(w, Point3d(-4, 1, 0)));

					addRemovable(new Cube(w, Point3d( 3.5, 2, 0)));
					addRemovable(new Cube(w, Point3d( 2.5, 2, 0)));
					addRemovable(new Cube(w, Point3d( 1.5, 2, 0)));
					addRemovable(new Cube(w, Point3d( 0.5, 2, 0)));
					addRemovable(new Cube(w, Point3d(-0.5, 2, 0)));
					addRemovable(new Cube(w, Point3d(-1.5, 2, 0)));
					addRemovable(new Cube(w, Point3d(-2.5, 2, 0)));
					addRemovable(new Cube(w, Point3d(-3.5, 2, 0)));

					addRemovable(new Cube(w, Point3d( 3, 3, 0)));
					addRemovable(new Cube(w, Point3d( 2, 3, 0)));
					addRemovable(new Cube(w, Point3d( 1, 3, 0)));
					addRemovable(new Cube(w, Point3d( 0, 3, 0)));
					addRemovable(new Cube(w, Point3d(-1, 3, 0)));
					addRemovable(new Cube(w, Point3d(-2, 3, 0)));
					addRemovable(new Cube(w, Point3d(-3, 3, 0)));

					addRemovable(new Cube(w, Point3d( 2.5, 4, 0)));
					addRemovable(new Cube(w, Point3d( 1.5, 4, 0)));
					addRemovable(new Cube(w, Point3d( 0.5, 4, 0)));
					addRemovable(new Cube(w, Point3d(-0.5, 4, 0)));
					addRemovable(new Cube(w, Point3d(-1.5, 4, 0)));
					addRemovable(new Cube(w, Point3d(-2.5, 4, 0)));

					addRemovable(new Cube(w, Point3d( 2, 5, 0)));
					addRemovable(new Cube(w, Point3d( 1, 5, 0)));
					addRemovable(new Cube(w, Point3d( 0, 5, 0)));
					addRemovable(new Cube(w, Point3d(-1, 5, 0)));
					addRemovable(new Cube(w, Point3d(-2, 5, 0)));

					addRemovable(new Cube(w, Point3d( 1.5, 6, 0)));
					addRemovable(new Cube(w, Point3d( 0.5, 6, 0)));
					addRemovable(new Cube(w, Point3d(-0.5, 6, 0)));
					addRemovable(new Cube(w, Point3d(-1.5, 6, 0)));

					addRemovable(new Cube(w, Point3d( 1, 7, 0)));
					addRemovable(new Cube(w, Point3d( 0, 7, 0)));
					addRemovable(new Cube(w, Point3d(-1, 7, 0)));

					addRemovable(new Cube(w, Point3d( 0.5, 8, 0)));
					addRemovable(new Cube(w, Point3d(-0.5, 8, 0)));

					addRemovable(new Cube(w, Point3d( 0, 9, 0)));
				}
				if (e.key.keysym.sym == SDLK_o) {
					foreach(r; removable)
						delete r;
					removable.length = 0;
				}
			}

/*
			if (e.type == SDL_MOUSEMOTION && moveing) {
				double xrel = e.motion.xrel;
				double yrel = e.motion.yrel;
				heading += xrel / 1000.0;
				pitch += yrel / 1000.0;
				projcam.rotation = Quatd(heading, 0, pitch);
			}
*/

			if (e.type == SDL_MOUSEBUTTONDOWN && e.button.button == 1)
				moveing = true;

			if (e.type == SDL_MOUSEBUTTONUP && e.button.button == 1)
				moveing = false;
		}

	}

	void logic()
	{
		w.tick();

		if (force || inverse)
			foreach(a; w.actors) {
				auto ticker = cast(Ticker)a;
				if (ticker !is null)
					ticker.force(inverse);
			}

		if (forward && !backwards)
			car.car.setAllWheelPower(100.0, 40.0);
		else if (!forward && backwards)
			car.car.setAllWheelPower(-10.0, 40.0);
		else
			car.car.setAllWheelPower(0.0, 0.0);

		spl.position = car.car.position;
		spl.rotation = car.car.rotation;
		auto v = car.car.rotation.rotateHeading;
		v.y = 0;
		v.normalize();
		v.scale(-10.0);
		v.y = 3.0;
		v = (car.car.position + v) - projcam.position;
		double scale = v.lengthSqrd * 0.002 + v.length * 0.04;
		scale = fmin(v.length, scale);
		v.normalize();
		v.scale(scale);
		projcam.position = projcam.position + v;

		auto v2 = car.car.position - projcam.position;
		v2.y = 0;
		v2.normalize();
		auto angle = acos(Vector3d.Heading.dot(v2));

		/* since we actualy don't do a cross to get the axis */
		if (v2.x > 0)
			angle = -angle;

		projcam.rotation = Quatd(angle, Vector3d.Up);

		//isocam.rotation = Quatd(0.785398163, -0.615472907, 0);
		//Vector3d gah = cam.rotation * Vector3d.Heading;
		//gah.scale(-500);
		//cam.position = car.car.position + gah;
		isocam.position = car.car.position;
	}

	void render()
	{
		auto cam = projective ? projcam : isocam;

		GfxDefaultTarget rt = GfxDefaultTarget();
		rt.clear();
		r.target = rt;
		r.render(cam, w.gfx);
		rt.swap();
	}

	void network()
	{
	}

	void close()
	{
	}

}

class Ticker : public GameActor, public GameTicker
{
protected:
	GfxActor gfx;
	PhyBody phy;

public:
	this(GameWorld w)
	{
		super(w);
		w.addTicker(this);
	}

	~this()
	{
		w.remTicker(this);
		delete gfx;
		delete phy;
	}

	void tick()
	{
		gfx.position = phy.position;
		gfx.rotation = phy.rotation;

		if (phy.position.y < -50) {
			phy.position = Point3d(0.0, 3.0, -6.0);
			phy.rotation = Quatd();
		}
	}

	void force(bool inverse)
	{
		Vector3d vec = Point3d(0.0, 10.0, 0.0) - phy.position;
		vec.normalize();
		vec.scale(9.8);

		if (inverse)
			vec.scale(-1.0);

		phy.addForce(vec);
	}

}

class Cube : public Ticker
{
	this(GameWorld w, Point3d pos)
	{
		super(w);

		gfx = GfxRigidModel(w.gfx, "res/cube.bin");
		gfx.position = pos;

		phy = new PhyCube(w.phy, pos);
	}
}

class Sphere : public Ticker
{
	this(GameWorld w, Point3d pos)
	{
		super(w);

		gfx = GfxRigidModel(w.gfx, "res/sphere.bin");
		gfx.position = pos;

		phy = new PhySphere(w.phy, pos);
	}
}

class Car : public Ticker
{
	~this()
	{
		delete wheels[0];
		delete wheels[1];
		delete wheels[2];
		delete wheels[3];
	}

	this(GameWorld w, Point3d pos)
	{
		super(w);

		gfx = GfxRigidModel(w.gfx, "res/car.bin");
		gfx.position = pos;

		phy = car = new PhyCar(w.phy, pos);

		car.massSetBox(10.0, 2.0, 1.0, 3.0);

		car.collisionBoxAt(Point3d(0, 0.275, 0.075), 2.0, 0.75, 4.75);
		car.collisionBoxAt(Point3d(0, 0.8075, 0.85), 1.3, 0.45, 2.4);

		car.wheel[0].powered = true;
		car.wheel[0].radius = 0.36;
		car.wheel[0].rayLength = 0.76;
		car.wheel[0].rayOffset = Vector3d( 0.82, 0.26, -1.5);
		car.wheel[0].opposit = 1;

		car.wheel[1].powered = true;
		car.wheel[1].radius = 0.36;
		car.wheel[1].rayLength = 0.76;
		car.wheel[1].rayOffset = Vector3d(-0.82, 0.26, -1.5);
		car.wheel[1].opposit = 0;

		car.wheel[2].powered = false;
		car.wheel[2].radius = 0.36;
		car.wheel[2].rayLength = 0.76;
		car.wheel[2].rayOffset = Vector3d( 0.82, 0.26, 1.5);
		car.wheel[2].opposit = 3;

		car.wheel[3].powered = false;
		car.wheel[3].radius = 0.36;
		car.wheel[3].rayLength = 0.76;
		car.wheel[3].rayOffset = Vector3d(-0.82, 0.26, 1.5);
		car.wheel[3].opposit = 2;

		car.carPower = 0;
		car.carDesiredVel = 0;
		car.carBreakingMuFactor = 1.0;
		car.carBreakingMuLimit = 20000;

		car.carSpringMu = 0.01;
		car.carSpringMu2 = 1.5;

		car.carSpringErp = 0.2;
		car.carSpringCfm = 0.03;

		car.carDesiredTurn = 0;
		car.carTurnSpeed = 0;
		car.carTurn = 0;

		car.carSwayFactor = 25.0;
		car.carSwayForceLimit = 20000;

		car.carSlip2Factor = 0.004;
		car.carSlip2Limit = 0.01;

		for (int i; i < 4; i++) {
			wheels[i] = GfxRigidModel(w.gfx, "res/wheel2.bin");
		}
	}

	void tick()
	{
		gfx.position = phy.position - (phy.rotation * Vector3d(0.0, 0.2, 0.0));
		gfx.rotation = phy.rotation * Quatd(PI, Vector3d.Up);

		for (int i; i < 4; i++)
			car.setMoveWheel(i, wheels[i]);

		auto v = car.velocity;
		auto l = v.length;
		v.normalize;
		auto a = pow(cast(real)l, cast(uint)2);
		v.scale(-0.01 * a);
		car.addForce(v);

		if (phy.position.y < -50) {
			phy.position = Point3d(0.0, 3.0, -6.0);
			phy.rotation = Quatd();
		}
	}

	GfxCube coll;
	GfxActor wheels[4];
	PhyCar car;
}
