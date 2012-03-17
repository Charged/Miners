// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.deferred;

import std.math;
import std.stdio;
static import std.string;

import charge.math.color;
import charge.math.movable;
import charge.math.matrix3x3d;
import charge.math.matrix4x4d;
import charge.sys.logger;
import charge.gfx.gl;
import charge.gfx.light;
import charge.gfx.camera;
import charge.gfx.cull;
import charge.gfx.renderqueue;
import charge.gfx.renderer;
import charge.gfx.target;
import charge.gfx.shader;
import charge.gfx.texture;
import charge.gfx.material;
import charge.gfx.world;
import charge.gfx.zone;


class DeferredRenderer : public Renderer
{
private:
	mixin Logging;

	DeferredTarget deferredTarget;
	DepthTargetArray depthTarget;

	enum matShdr {
		TEX,
		FAKE,
		COLOR,
		OFF,
		NUM = OFF * 2
	}

	static Shader matShader[matShdr.NUM];

	static Shader directionlight_shader;
	static Shader directionlight_iso_shader;
	static Shader directionlight_split_shader;
	static Shader pointlight_shader;
	static Shader spotlight_shader;
	static Shader fog_shader;
	Texture spotlight_texture;

	static bool checked;
	static bool checkStatus;
	static bool initialized;

public:
	static bool check()
	{
		if (checked)
			return checkStatus;

		// We have checked, if we fail that means we failed.
		checked = true;

		try {
			if (!GL_VERSION_2_0)
				throw new Exception("GL_VERSION < 2.0");

			if (!GL_EXT_geometry_shader4)
				throw new Exception("GL_EXT_geometry_shader4 not supported");
			if (!GL_EXT_texture_array)
				throw new Exception("GL_EXT_texture_array not supported");

			auto t = new DeferredTarget(64, 48);
			auto dep1 = new DepthTargetArray(1024, 1024, 2);

			delete t;
			delete dep1;
		} catch (Exception e) {
			l.info("Is not cabable of running deferred renderer!");
			l.bug(e.toString());
			return false;
		}

		l.info("Can run deferred renderer!");

		checkStatus = true;
		return true;
	}

	static bool init()
	{
		if (initialized)
			return true;

		if (!check())
			return false;

		/*
		 * Mesh shaders.
		 */
		matShader[matShdr.TEX] =
			ShaderMaker(material_shader_mesh_vert,
				    material_shader_tex_frag,
				    ["vs_position", "vs_uv", "vs_normal"],
				    ["diffuseTex"]);
		matShader[matShdr.FAKE] =
			ShaderMaker(material_shader_mesh_vert,
				    material_shader_tex_frag,
				    ["vs_position", "vs_uv", "vs_normal"],
				    ["diffuseTex"]);
		matShader[matShdr.COLOR] =
			ShaderMaker(material_shader_mesh_vert,
				    material_shader_tex_frag,
				    ["vs_position", "vs_uv", "vs_normal"],
				    ["diffuseTex"]);

		/*
		 * Skeleton shaders.
		 */
		matShader[matShdr.TEX + matShdr.OFF] =
			ShaderMaker(material_shader_skel_vert,
				    material_shader_tex_frag,
				    ["vs_position", "vs_uv", "vs_normal"],
				    ["diffuseTex"]);
		matShader[matShdr.FAKE + matShdr.OFF] =
			ShaderMaker(material_shader_skel_vert,
				    material_shader_tex_frag,
				    ["vs_position", "vs_uv", "vs_normal"],
				    ["diffuseTex"]);
		matShader[matShdr.COLOR + matShdr.OFF] =
			ShaderMaker(material_shader_skel_vert,
				    material_shader_tex_frag,
				    ["vs_position", "vs_uv", "vs_normal"],
				    ["diffuseTex"]);


		pointlight_shader = ShaderMaker(pointlight_shader_vertex,
		                                pointlight_shader_geom,
		                                pointlight_shader_frag,
		                                GL_POINTS, GL_TRIANGLE_STRIP, 4);

		directionlight_split_shader = ShaderMaker(deferred_base_vert, directionlight_split_shader_frag);
		directionlight_iso_shader = ShaderMaker(deferred_base_vert, directionlight_iso_shader_frag);
		directionlight_shader = ShaderMaker(deferred_base_vert, directionlight_shader_frag);
		spotlight_shader = ShaderMaker(deferred_base_vert, spotlight_shader_frag);
		fog_shader = ShaderMaker(deferred_base_vert, fog_shader_frag);

		glUseProgram(pointlight_shader.id);
		pointlight_shader.sampler("colorTex", 0);
		pointlight_shader.sampler("normalTex", 1);
		pointlight_shader.sampler("depthTex", 2);

		glUseProgram(directionlight_shader.id);
		directionlight_shader.sampler("colorTex", 0);
		directionlight_shader.sampler("normalTex", 1);
		directionlight_shader.sampler("depthTex", 2);

		glUseProgram(directionlight_iso_shader.id);
		directionlight_iso_shader.sampler("colorTex", 0);
		directionlight_iso_shader.sampler("normalTex", 1);
		directionlight_iso_shader.sampler("depthTex", 2);
		directionlight_iso_shader.sampler("shadowTex", 3);

		glUseProgram(directionlight_split_shader.id);
		directionlight_split_shader.sampler("colorTex", 0);
		directionlight_split_shader.sampler("normalTex", 1);
		directionlight_split_shader.sampler("depthTex", 2);
		directionlight_split_shader.sampler("shadowTex", 3);

		glUseProgram(spotlight_shader.id);
		spotlight_shader.sampler("colorTex", 0);
		spotlight_shader.sampler("normalTex", 1);
		spotlight_shader.sampler("depthTex", 2);
		spotlight_shader.sampler("spotTex", 3);

		glUseProgram(fog_shader.id);
		fog_shader.sampler("depthTex", 2);

		glUseProgram(0);

		initialized = true;
		return true;
	}

	this()
	{
		assert(initilized);

		depthTarget = new DepthTargetArray(2048, 2048, 4);

		// If we where to fail to allocate the depthtarget for some reason
		// and throw a error and we allocated the spotlight texture before
		// the depthtarget we would get segfaults in the resource pool.
		// Why do you ask, well thats because the allocated class is not
		// deleted at once but instead left up to the GC, and calling
		// dereference from the GC context is bad.
		spotlight_texture = Texture("res/spotlight.png");
	}

	~this()
	{
		if (spotlight_texture !is null)
			spotlight_texture.dereference();
		delete deferredTarget;
	}

	void target(RenderTarget rt)
	{
		renderTarget = rt;

		if (deferred && (deferredTarget is null ||
			(deferredTarget.width != rt.width || deferredTarget.height != rt.height))) {
			delete deferredTarget;
			deferredTarget = new DeferredTarget(rt.width, rt.height);
		}
	}

protected:
	void render(Camera c, RenderQueue rq, World w)
	{
		Matrix4x4d view;
		Matrix4x4d proj;
		Matrix4x4d projITS; /* Inverse Transpose Scale */

		// Catch any screen size changes.
		if (deferredTarget is null ||
		    deferredTarget.width != renderTarget.width ||
		    deferredTarget.height != renderTarget.height) {
			delete deferredTarget;
			deferredTarget = new DeferredTarget(renderTarget.width,
							    renderTarget.height);
		}

		//
		// Fill the G-Buffer
		//

		deferredTarget.setTarget();

		glClearDepth(1);
		if (w.fog is null) {
			glClearColor(0, 0, 0, 0);
			glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
		} else {
			glClear(GL_DEPTH_BUFFER_BIT);
		}

		glDisable(GL_BLEND);
		glEnable(GL_DEPTH_TEST);
		glDepthFunc(GL_LESS);

		c.transform();

		renderLoop(rq, w);


		//
		// Do the lighting
		//

		// Matricies
		c.transform();

		extractMatrices(c, view, proj, projITS);

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();

		// Rendertarget
		renderTarget.setTarget();

		// Clear the accumilation buffer
		glClearColor(0, 0, 0, 1);
		glClear(GL_COLOR_BUFFER_BIT);

		// State
		glDisable(GL_DEPTH_TEST);
		gluTexUnitEnableBind(GL_TEXTURE_2D, 0, deferredTarget.color);
		gluTexUnitEnableBind(GL_TEXTURE_2D, 1, deferredTarget.normal);
		gluTexUnitEnableBind(GL_TEXTURE_2D, 2, deferredTarget.depth);

		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE);

		// Setup uniforms for lights
		float vec[2];
		vec[0] = 1.0f / renderTarget.width;
		vec[1] = 1.0f / renderTarget.height;

		glUseProgram(directionlight_split_shader.id);
		directionlight_split_shader.matrix4("projectionMatrixInverse", false, projITS);
		directionlight_split_shader.float2("screen", 1, vec.ptr);
		glUseProgram(directionlight_iso_shader.id);
		directionlight_iso_shader.matrix4("projectionMatrixInverse", false, projITS);
		directionlight_iso_shader.float2("screen", 1, vec.ptr);
		glUseProgram(directionlight_shader.id);
		directionlight_shader.matrix4("projectionMatrixInverse", false, projITS);
		directionlight_shader.float2("screen", 1, vec.ptr);
		glUseProgram(pointlight_shader.id);
		pointlight_shader.matrix4("projectionMatrixInverse", false, projITS);
		pointlight_shader.float1("near_clip", c.near);
		pointlight_shader.float2("screen", 1, vec.ptr);
		glUseProgram(spotlight_shader.id);
		spotlight_shader.matrix4("projectionMatrixInverse", false, projITS);
		spotlight_shader.float2("screen", 1, vec.ptr);
		glUseProgram(fog_shader.id);
		fog_shader.matrix4("projectionMatrixInverse", false, projITS);
		fog_shader.float2("screen", 1, vec.ptr);

		drawLights(c, w, view, proj);

		drawPointLights(c, w, view);

		if (w.fog !is null)
			drawFog(w.fog);

		glUseProgram(0);

		gluTexUnitDisableUnbind(GL_TEXTURE_2D, 2);
		gluTexUnitDisableUnbind(GL_TEXTURE_2D, 1);
		gluTexUnitDisableUnbind(GL_TEXTURE_2D, 0);

		glDisable(GL_BLEND);
	}

	void extractMatrices(Camera c,
	                     ref Matrix4x4d view,
	                     ref Matrix4x4d proj,
	                     ref Matrix4x4d projITS)
	{
		c.transform();

		glGetDoublev(GL_MODELVIEW_MATRIX, view.array.ptr);
		view.transpose();
		glGetDoublev(GL_PROJECTION_MATRIX, proj.array.ptr);
		proj.transpose();

		glGetDoublev(GL_PROJECTION_MATRIX, projITS.array.ptr);
		projITS.inverse();

		/*
		 * Reload matrix again and adjust for range.
		 *
		 * Inputs are in range [0..1] but we want [-1..1]
		 */
		glMatrixMode(GL_PROJECTION);
		glLoadMatrixd(projITS.array.ptr);
		glScaled(2.0, 2.0, 2.0);
		glTranslated(-0.5, -0.5, -0.5);
		glGetDoublev(GL_PROJECTION_MATRIX, projITS.array.ptr);
	}

	void drawLights(Camera c, World w, ref Matrix4x4d view, ref Matrix4x4d proj)
	{
		foreach(l; w.lights) {
			auto dl = cast(SimpleLight)l;
			auto sl = cast(SpotLight)l;

			if (dl !is null) {
				drawDirectionLight(dl, c, w, view, proj);
			} else if (sl !is null) {
				drawSpotLight(sl, view, proj);
			} else {
				continue;
			}
		}
	}


	/*
	 * Common shadow caster code
	 */


	/**
	 * Render all shadow casting actors as shadow casters into
	 * the currently set render target.
	 */
	void renderShadowLoop(Point3d pos, Camera cam, World w)
	{
		auto cull = new Cull(pos);
		auto rq = new RenderQueue();

		foreach(a; w.actors)
		{
			a.cullAndPush(cull, rq);
		}

		for (auto r = rq.pop; r !is null; r = rq.pop) {
			auto sm = cast(SimpleMaterial)r.getMaterial();
			if (sm is null)
				continue;

			renderShadow(r, sm);
		}
	}

	/**
	 * Render a Renderable as a shadow caster.
	 */
	void renderShadow(Renderable r, SimpleMaterial sm)
	{
		Shader s;
		int off = sm.skel * matShdr.OFF;

		if (sm.fake) {
			s =  matShader[matShdr.FAKE + off];
			glUseProgram(s.id);
			glBindTexture(GL_TEXTURE_2D, sm.texSafe.id);
		} else {
			s =  matShader[matShdr.COLOR + off];
			glUseProgram(s.id);
		}

		r.drawAttrib(s);
	}

	/**
	 * Takes the currently set modelview and projection matrix in the GL
	 * state along with a scene view matrix as argument and calculates
	 * a matrix view that goes from global scene to current projection
	 * matrix. The matrix can be used with shadow mapping.
	 */
	void getSceneViewToProjMatrix(ref Matrix4x4d global_to_scene_view,
	                              ref Matrix4x4d out_mat)
	{
		Matrix4x4d mat = global_to_scene_view;
		mat.inverse(); // render view to global
		mat.transpose();

		glMatrixMode(GL_MODELVIEW); // global to depth view
		glMultMatrixd(mat.array.ptr); // render view to depth view
		glGetDoublev(GL_MODELVIEW_MATRIX, mat.array.ptr);

		glMatrixMode(GL_PROJECTION); // depth view to depth proj
		glMultMatrixd(mat.array.ptr); // render view to depth proj

		// XXX get these to work
		//glTranslated(-2.0, -2.0, -2.0); // scaled and offseted to [0..1]
		//glScaled(0.5, 0.5, 0.5);

		glGetDoublev(GL_PROJECTION_MATRIX, out_mat.array.ptr);
	}


	/*
	 * Directional lights
	 */


	static void getDirSplitSphere(double fov, double ratio, double near, double far,
	                              out Point3d center, out double radius)
	{
		double near_height = tan(fov / 2.0) * near;
		double near_width = near_height * ratio;
		double far_height = tan(fov / 2.0) * far;
		double far_width = far_height * ratio;

		double a, b, c, d, e, f;
		a = near_width;
		b = near_height;
		c = near;
		d = far_width;
		e = far_height;
		f = far;
		double Z = (d*d + e*e + f*f - a*a - b*b - c*c) / (f - c);
		Z = Z / 2;

		double size = (Point3d(0, 0, Z) - Point3d(near_width, near_height, near)).length;

		// Forward is negative Z axis
		center = Point3d(0.0, 0.0, -Z);
		radius = size;
	}

	static void getDirSplitDistance(int splits, double near, double far,
	                                float near_array[], float far_array[])
	{
		double lambda = 0.75;
		double ratio = far / near;
		near_array[0] = near;

		for(int i=1; i<splits; i++)
		{
			float si = i / cast(float)splits;

			near_array[i] = lambda * (near * pow(ratio, si)) +
			                (1 - lambda) * (near + (far - near) * si);
			far_array[i-1] = near_array[i] * 1.005f;
		}
		far_array[splits-1] = far;
	}

	void setDirSplitMatrices(SimpleLight dl, ProjCamera c,
                                 double far, double near)
	{
		Point3d center;
		double radius;
		getDirSplitSphere(c.fov, c.ratio, near, far, center, radius);
		auto rot = dl.rotation;
		auto pos = (c.rotation * cast(Vector3d)center) + c.position;
		auto point = pos + rot.rotateHeading();
		auto up = rot.rotateUp();
		Matrix4x4d mat;

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-radius, radius, -radius, radius, -6*radius, radius);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		gluLookAt(pos.x, pos.y, pos.z,
		          point.x, point.y, point.z,
		          up.x, up.y, up.z);

		// Fixes the jittering
		// XXX Could be done in a faster way
		glGetDoublev(GL_MODELVIEW_MATRIX, mat.array.ptr);
		mat.transpose();
		auto p = mat * Point3d(0.0, 0.0, 0.0);
		double tx = p.x % ((radius*2) / depthTarget.width);
		double ty = p.y % ((radius*2) / depthTarget.height);

		glLoadIdentity();
		glTranslated(-tx, -ty, 0);
		gluLookAt(pos.x, pos.y, pos.z,
		          point.x, point.y, point.z,
		          up.x, up.y, up.z);
	}

	void drawDirSplitShadow(SimpleLight dl, ProjCamera c, World w,
	                        ref Matrix4x4d view, ref Matrix4x4d proj)
	{
		ProjCamera cam = c;
		const int num_splits = 4;
		float nears[num_splits];
		float fars[num_splits];
		Matrix4x4d mat[num_splits];

		gluPushMatricesAttrib(GL_VIEWPORT_BIT);

		getDirSplitDistance(4, cam.near, cam.far, nears, fars);

		glUseProgram(0);
		glDisable(GL_BLEND);
		glEnable(GL_DEPTH_TEST);

		glDisable(GL_CULL_FACE);
		glCullFace(GL_FRONT);

		gluTexUnitDisable(GL_TEXTURE_2D, 2);
		gluTexUnitDisable(GL_TEXTURE_2D, 1);
		gluTexUnitDisable(GL_TEXTURE_2D, 0);

		glPolygonOffset(1.0f, 4096.0f);
		glEnable(GL_POLYGON_OFFSET_FILL);

		for (int i; i < num_splits; i++) {
			depthTarget.setTarget(i);
			glViewport(0, 0, depthTarget.width, depthTarget.height);
			glClear(GL_DEPTH_BUFFER_BIT);
			setDirSplitMatrices(dl, cam, nears[i], fars[i]);
			// XXX better position.
			renderShadowLoop(dl.position, cam, w);
			getSceneViewToProjMatrix(view, mat[i]);
		}

		glBindTexture(GL_TEXTURE_2D, deferredTarget.color);
		glDisable(GL_POLYGON_OFFSET_FILL);

		gluTexUnitEnable(GL_TEXTURE_2D, 0);
		gluTexUnitEnable(GL_TEXTURE_2D, 1);
		gluTexUnitEnable(GL_TEXTURE_2D, 2);

		glCullFace(GL_BACK);
		glDisable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE);

		gluPopMatricesAttrib();

		renderTarget.setTarget();

		glActiveTexture(GL_TEXTURE3);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, depthTarget.depthArray);
		glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT,
		                GL_TEXTURE_COMPARE_MODE,
		                GL_COMPARE_R_TO_TEXTURE);
		gluGetError("bind");

		glUseProgram(directionlight_split_shader.id);
		auto direction = view * dl.rotation.rotateHeading;
		directionlight_split_shader.float3("lightDirection", direction);
		directionlight_split_shader.float4("lightDiffuse", dl.diffuse);
		directionlight_split_shader.float4("lightAmbient", dl.ambient);
		directionlight_split_shader.float4("slices", 1, fars.ptr);
		for (int i; i < num_splits; i++) {
			glActiveTexture(GL_TEXTURE0 + cast(GLenum)(i));
			glMatrixMode(GL_TEXTURE);
			glLoadMatrixd(mat[i].array.ptr);
		}
		gluGetError("set value");

		glBegin(GL_QUADS);
		glColor3f(  1.0f,  1.0f,  1.0f);
		glVertex3f(-1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f,  1.0f,  0.0f);
		glVertex3f(-1.0f,  1.0f,  0.0f);
		glEnd();

		for (int i; i < num_splits; i++) {
			glActiveTexture(GL_TEXTURE0 + cast(GLenum)(i));
			glMatrixMode(GL_TEXTURE);
			glLoadIdentity();
		}

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE);
		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
		gluGetError("leave");
	}


	void setDirIsoMatricies(SimpleLight dl, IsoCamera c,
	                        ref Matrix4x4d view, ref Matrix4x4d proj)
	{
		Quatd rot = dl.rotation;
		Matrix4x4d mat;
		Matrix3x3d rotMat = rot;
		Matrix3x3d rotMatInv = rot;
		rotMatInv.inverse();

		glMatrixMode(GL_PROJECTION);
		mat = proj; // scene view to scene proj
		mat.transpose();
		glLoadMatrixd(mat.array.ptr); // scene view to global

		mat = view; // global to scene view
		mat.transpose();
		glMultMatrixd(mat.array.ptr); // scene proj to global

		glGetDoublev(GL_PROJECTION_MATRIX, mat.array.ptr);
		mat.transpose();
		mat.inverse();

		Point3d p[8];
		// Get the global coords of the scene ModelViewProj matrix.
		p[0] = mat / Point3d(-1, -1, -1);
		p[1] = mat / Point3d(-1, -1,  1);
		p[2] = mat / Point3d(-1,  1, -1);
		p[3] = mat / Point3d(-1,  1,  1);
		p[4] = mat / Point3d( 1, -1, -1);
		p[5] = mat / Point3d( 1, -1,  1);
		p[6] = mat / Point3d( 1,  1, -1);
		p[7] = mat / Point3d( 1,  1,  1);

		// Rotate points into light space
		for (int i; i < 8; i++)
			p[i] = rotMat * p[i];

		// Find the min & max coords in light space.
		Point3d min, max;
		min = p[0];
		max = p[0];
		for (int i = 1; i < 8; i++) {
			if (min.x > p[i].x)
				min.x = p[i].x;
			if (min.y > p[i].y)
				min.y = p[i].y;
			if (min.z > p[i].z)
				min.z = p[i].z;
			if (max.x < p[i].x)
				max.x = p[i].x;
			if (max.y < p[i].y)
				max.y = p[i].y;
			if (max.z < p[i].z)
				max.z = p[i].z;
		}

		double width = max.x - min.x;
		double height = max.y - min.y;
		double depth = max.z - min.z;
		Point3d pos = Point3d(min.x + width / 2, min.y + height / 2, max.z);
		pos = rotMatInv * pos;

		// Start setting the actual matricies
		Point3d point = pos + rot.rotateHeading();
		Point3d up = rot.rotateUp();

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-width / 2, width / 2, -height / 2, height / 2, -depth, 0);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		gluLookAt(pos.x, pos.y, pos.z,
		          point.x, point.y, point.z,
		          up.x, up.y, up.z);

		// Fixes the jittering
		// XXX Could be done in a faster way
		glGetDoublev(GL_MODELVIEW_MATRIX, mat.array.ptr);
		mat.transpose();
		auto tweekP = mat * Point3d(0.0, 0.0, 0.0);
		double tx = tweekP.x % (width / depthTarget.width);
		double ty = tweekP.y % (height / depthTarget.height);

		glLoadIdentity();
		glTranslated(-tx, -ty, 0);
		gluLookAt(pos.x, pos.y, pos.z,
		          point.x, point.y, point.z,
		          up.x, up.y, up.z);
	}

	void drawDirIsoShadow(SimpleLight dl, IsoCamera c, World w,
	                      ref Matrix4x4d view, ref Matrix4x4d proj)
	{
		IsoCamera cam = c;
		Matrix4x4d mat;

		gluPushMatricesAttrib(GL_VIEWPORT_BIT);

		glUseProgram(0);
		glDisable(GL_BLEND);
		glEnable(GL_DEPTH_TEST);

		glDisable(GL_CULL_FACE);
		glCullFace(GL_FRONT);

		gluTexUnitDisable(GL_TEXTURE_2D, 2);
		gluTexUnitDisable(GL_TEXTURE_2D, 1);
		gluTexUnitDisable(GL_TEXTURE_2D, 0);

		glPolygonOffset(1.3f, 4096.0f);
		glEnable(GL_POLYGON_OFFSET_FILL);

		{
			depthTarget.setTarget(0);
			glViewport(0, 0, depthTarget.width, depthTarget.height);
			glClear(GL_DEPTH_BUFFER_BIT);
			setDirIsoMatricies(dl, cam, view, proj);
			renderShadowLoop(dl.position, cam, w);
			getSceneViewToProjMatrix(view, mat);
		}

		glBindTexture(GL_TEXTURE_2D, deferredTarget.color);
		glDisable(GL_POLYGON_OFFSET_FILL);

		gluTexUnitEnable(GL_TEXTURE_2D, 0);
		gluTexUnitEnable(GL_TEXTURE_2D, 1);
		gluTexUnitEnable(GL_TEXTURE_2D, 2);

		glCullFace(GL_BACK);
		glDisable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE);

		gluPopMatricesAttrib();

		renderTarget.setTarget();

		glActiveTexture(GL_TEXTURE3);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, depthTarget.depthArray);
		glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT,
		                GL_TEXTURE_COMPARE_MODE,
		                GL_COMPARE_R_TO_TEXTURE);
		gluGetError("bind");

		// Setup shader state
		glUseProgram(directionlight_iso_shader.id);
		auto direction = view * dl.rotation.rotateHeading;
		directionlight_iso_shader.float3("lightDirection", direction);
		directionlight_iso_shader.float4("lightDiffuse", dl.diffuse);
		directionlight_iso_shader.float4("lightAmbient", dl.ambient);
		{
			glActiveTexture(GL_TEXTURE0);
			glMatrixMode(GL_TEXTURE);
			glLoadMatrixd(mat.array.ptr);
		}
		gluGetError("set value");

		glBegin(GL_QUADS);
		glColor3f(  1.0f,  1.0f,  1.0f);
		glVertex3f(-1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f,  1.0f,  0.0f);
		glVertex3f(-1.0f,  1.0f,  0.0f);
		glEnd();

		// Reset texture matrix state
		{
			glActiveTexture(GL_TEXTURE0);
			glMatrixMode(GL_TEXTURE);
			glLoadIdentity();
		}

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE);
		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
		gluGetError("leave");
	}

	void drawDirNoShadow(SimpleLight dl, ref Matrix4x4d view, ref Matrix4x4d proj)
	{
		auto direction = view * dl.rotation.rotateHeading;

		glUseProgram(directionlight_shader.id);
		directionlight_shader.float3("lightDirection", direction);
		directionlight_shader.float4("lightDiffuse", dl.diffuse);
		directionlight_shader.float4("lightAmbient", dl.ambient);

		glBegin(GL_QUADS);
		glColor3f(  1.0f,  1.0f,  1.0f);
		glVertex3f(-1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f,  1.0f,  0.0f);
		glVertex3f(-1.0f,  1.0f,  0.0f);
		glEnd();
	}

	void drawDirectionLight(SimpleLight dl, Camera c, World w,
	                        ref Matrix4x4d view, ref Matrix4x4d proj)
	{
		if (!dl.shadow)
			return drawDirNoShadow(dl, view, proj);

		ProjCamera pcam = cast(ProjCamera)c;
 		if (pcam !is null)
			return drawDirSplitShadow(dl, pcam, w, view, proj);

		IsoCamera icam = cast(IsoCamera)c;
		if (icam !is null)
			return drawDirIsoShadow(dl, icam, w, view, proj);

		return drawDirNoShadow(dl, view, proj);
	}


	/*
	 * Point lights
	 */


	void drawPointLights(Camera c, World w, ref Matrix4x4d view)
	{
		glGetError();

		c.transform();

		glUseProgram(pointlight_shader.id);

		glBegin(GL_POINTS);
		foreach(l; w.lights) {
			auto pl = cast(PointLight)l;

			if (pl is null)
				continue;

			Point3d p = pl.position;
			glColor4fv(pl.diffuse.ptr);
			glVertex4d(p.x, p.y, p.z, pl.size);
		}
		glEnd();
	}


	/*
	 * Spot light
	 */


	void getSpotLightMatrix(SpotLight l, ref Matrix4x4d view, ref Matrix4x4d texture)
	{
		float shadowNear = 1.0;
		float shadowFar = l.length;
		auto point = l.position + l.rotation.rotateHeading();
		auto up = l.rotation.rotateUp();
		GLfloat d = shadowNear * std.math.tan(PI/180*10.0);
		Matrix4x4d viewInverse = view;
		Matrix4x4d lightProjection;
		Matrix4x4d lightModelView;
		viewInverse.transpose;
		viewInverse.inverse;
		//texture = viewInverse;

		static const GLfloat biasMatrix[16] = [
			0.5, 0.0, 0.0, 0.0,
			0.0, 0.5, 0.0, 0.0,
			0.0, 0.0, 0.5, 0.0,
			0.5, 0.5, 0.5, 1.0,
		];

		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		glLoadIdentity();
		glFrustum(-d, d, -d, d, shadowNear, shadowFar);
		glGetDoublev(GL_PROJECTION_MATRIX, lightProjection.array.ptr);
		glPopMatrix();

		glMatrixMode(GL_MODELVIEW);
		glPushMatrix();
		glLoadIdentity();
		gluLookAt(
				l.position.x, l.position.y, l.position.z,
				point.x, point.y, point.z,
				up.x, up.y, up.z
			);
		glGetDoublev(GL_MODELVIEW_MATRIX, lightModelView.array.ptr);
		glPopMatrix();

		glMatrixMode(GL_TEXTURE);

		glLoadMatrixf(biasMatrix.ptr);
		glTranslatef(0.0, 0.0, 0.0);
		glMultMatrixd(lightProjection.array.ptr);
		glMultMatrixd(lightModelView.array.ptr);
		glMultMatrixd(viewInverse.array.ptr);
		glGetDoublev(GL_TEXTURE_MATRIX, texture.array.ptr);
		glMatrixMode(GL_MODELVIEW);
	}

	void drawSpotLight(SpotLight sl, ref Matrix4x4d view, ref Matrix4x4d proj)
	{
		auto position = view * sl.position;
		auto rotation = view * sl.rotation.rotateHeading;
		Matrix4x4d texture;
		getSpotLightMatrix(sl, view, texture);


		glUseProgram(spotlight_shader.id);
		spotlight_shader.matrix4("textureMatrix", false, texture);
		spotlight_shader.float4("lightDiffuse", sl.diffuse);
		spotlight_shader.float3("lightPosition", view * sl.position);
		spotlight_shader.float3("lightDirection", view * sl.rotation.rotateHeading);
		spotlight_shader.float1("lightLength", sl.length);

		gluTexUnitEnableBind(GL_TEXTURE_2D, 3, spotlight_texture);

		glBegin(GL_QUADS);
		glColor3f(  1.0f,  1.0f,  1.0f);
		glVertex3f(-1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f,  1.0f,  0.0f);
		glVertex3f(-1.0f,  1.0f,  0.0f);
		glEnd();

		gluTexUnitDisableUnbind(GL_TEXTURE_2D, 3);
	}


	/*
	 * Deferred target rendering
	 */


	void renderLoop(RenderQueue rq, World w)
	{
		SimpleMaterial sm;
		Renderable r;

		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);
		glActiveTexture(GL_TEXTURE0);
		glEnable(GL_TEXTURE_2D);

		for (r = rq.pop; r !is null; r = rq.pop) {
			sm = cast(SimpleMaterial)r.getMaterial();
			if (sm is null)
				continue;

			render(r, sm);
		}

		glActiveTexture(GL_TEXTURE0);
		glDisable(GL_TEXTURE_2D);
		glUseProgram(0);
		glDisable(GL_CULL_FACE);
	}

	void render(Renderable r, SimpleMaterial sm)
	{
		Texture t;
		Shader s;
		int off = sm.skel * matShdr.OFF;


		if (sm.fake)
			s =  matShader[matShdr.FAKE + off];
		else
			s =  matShader[matShdr.TEX + off];

		glBindTexture(GL_TEXTURE_2D, sm.texSafe.id);
		glUseProgram(s.id);

		r.drawAttrib(s);
	}


	void drawFog(Fog fog)
	{
		glUseProgram(fog_shader.id);
		fog_shader.float4("color", 1, fog.color.ptr);
		fog_shader.float1("start", fog.start);
		fog_shader.float1("stop", fog.stop);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glBegin(GL_QUADS);
		glColor3f(  1.0f,  1.0f,  1.0f);
		glVertex3f(-1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f, -1.0f,  0.0f);
		glVertex3f( 1.0f,  1.0f,  0.0f);
		glVertex3f(-1.0f,  1.0f,  0.0f);
		glEnd();
	}


	/*
	 *
	 * Debug code
	 *
	 */


	void debugTextureFullscreen(uint id)
	{
		gluTexUnitDisableUnbind(GL_TEXTURE_2D, 2);
		gluTexUnitDisableUnbind(GL_TEXTURE_2D, 1);
		gluTexUnitDisableUnbind(GL_TEXTURE_2D, 0);

		glDisable(GL_BLEND);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluOrtho2D(0, 1, 0, 1);

		gluTexUnitEnableBind(GL_TEXTURE_2D, 0, deferredTarget.normal);

		glColor4fv(Color4f.White.ptr);
		glBegin(GL_QUADS);
		glTexCoord2f(0, 0);
		glVertex2f  (0, 0);
		glTexCoord2f(1, 0);
		glVertex2f  (1, 0);
		glTexCoord2f(1, 1);
		glVertex2f  (1, 1);
		glTexCoord2f(0, 1);
		glVertex2f  (0, 1);
		glEnd();
	}


	/*
	 * Shaders
	 */


	const char[] material_shader_mesh_vert = "
varying vec2 uv;
varying vec3 normal;

attribute vec4 vs_position;
attribute vec2 vs_uv;
attribute vec3 vs_normal;

void main()
{
	uv = vs_uv;
	normal = gl_NormalMatrix * vs_normal;
	gl_Position = gl_ModelViewProjectionMatrix * vs_position;
}
";

	const char[] material_shader_skel_vert = "
varying vec3 normal;
varying vec2 uv;

uniform vec4 bones[128];

attribute vec4 vs_position;
attribute vec2 vs_uv;
attribute vec4 vs_normal; // And bone

vec3 qrot(vec4 rot, vec3 pos)
{
	return pos + 2.0 * cross(rot.xyz, cross(rot.xyz, pos) + rot.w*pos);
}

vec3 applyBone(vec4 rot, vec3 trans, vec3 pos)
{
	return qrot(rot, pos) + trans;
}

void main()
{
	// UV is super simple
	uv = vs_uv;

	// Look up the bone that we need to fetch
	int index = int(floor(vs_normal.w) * 2.0);
	vec4 quat = bones[index];
	vec3 trans = bones[index+1].xyz;

	// Rotate the normal
	normal = gl_NormalMatrix * qrot(quat, vs_normal.xyz);

	// Rotate and transform the position
	vec4 pos = vs_position;
	pos.xyz = applyBone(quat, trans, pos.xyz);
	gl_Position = gl_ModelViewProjectionMatrix * pos;
}
";

	const char[] material_shader_tex_frag = "
uniform sampler2D diffuseTex;

varying vec2 uv;
varying vec3 normal;

void main()
{
	gl_FragData[0] = vec4(texture2D(diffuseTex, uv).xyz, 0);
	gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5 , 0.0);
}
";

	const char[] material_shader_fake_frag = "
uniform sampler2D diffuseTex;

varying vec2 uv;
varying vec3 normal;

void main()
{
	vec4 color = texture2D(diffuseTex, uv);
	if (color.a < 0.5)
		discard;

	gl_FragData[0] = vec4(color.xyz, 0);
	gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5 , 0.0);
}
";

	const char[] material_shader_color_frag = "
uniform vec4 color;

varying vec3 normal;

void main()
{
	gl_FragData[0] = vec4(color.xyz, 0);
	gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5 , 0.0);
}
";

	const char[] deferred_base_vert = "
void main()
{
	/* Both matrixes are identity so just copy the position */
	gl_Position = gl_Vertex;
}
";

	const char[] spotlight_shader_frag = "
uniform vec2 screen;
uniform sampler2D colorTex;
uniform sampler2D normalTex;
uniform sampler2D depthTex;
uniform sampler2D spotTex;
uniform mat4 projectionMatrixInverse;
uniform mat4 textureMatrix;
uniform vec3 lightPosition;
uniform vec4 lightDiffuse;
uniform float lightLength;

void main()
{
	vec2 coord = gl_FragCoord.xy * screen;
	vec4 color = texture2D(colorTex, coord);
	vec4 normal = texture2D(normalTex, coord);
	float depth = texture2D(depthTex, coord).r;

	vec4 position = projectionMatrixInverse * vec4(coord, depth, 1.0);
	position.xyz /= position.w;
	// normal is a vec4 only normalize xyz
	normal.xyz = normalize((normal.xyz - 0.5) * 2.0);

	vec4 spotTexCoord = vec4(position.xyz, 1.0);
	spotTexCoord = textureMatrix * spotTexCoord;
	spotTexCoord.xyz /= spotTexCoord.w;

	if (spotTexCoord.x > 1.0 || spotTexCoord.x < 0.0)
		discard;
	if (spotTexCoord.y > 1.0 || spotTexCoord.y < 0.0)
		discard;
	if (spotTexCoord.z > 1.0 || spotTexCoord.z < 0.0)
		discard;

	vec4 lightDiffuse = texture2D(spotTex, spotTexCoord.xy);
	vec3 lightDirection = normalize(lightPosition - position.xyz);
	float nDotL = max(dot(normal.xyz, lightDirection.xyz), 0.0);
	float minusDistance = -distance(lightPosition.xyz, position.xyz);
	float factor = smoothstep(-lightLength, 0.0, minusDistance);

	gl_FragData[0] = color * lightDiffuse * nDotL * factor;
	gl_FragData[0].a = 1.0;
}
";

	const char[] pointlight_shader_frag = "
uniform vec2 screen;
uniform sampler2D colorTex;
uniform sampler2D normalTex;
uniform sampler2D depthTex;
uniform mat4 projectionMatrixInverse;

varying vec3 lightPosition;
varying vec3 lightDiffuse;
varying float lightSize;

void main()
{
	vec2 coord = gl_FragCoord.xy * screen;
	float depth = texture2D(depthTex, coord).r;

	// Discard if the light is behind the current pixel.
	if (gl_FragCoord.z > depth)
		discard;

	vec4 position = projectionMatrixInverse * vec4(coord, depth, 1.0);
	position.xyz /= position.w;

	// We wont contribute any light to pixels outside the light radius.
	float minusDistance = -distance(lightPosition.xyz, position.xyz);
	if (minusDistance < -lightSize)
		discard;

	vec4 color = texture2D(colorTex, coord);
	vec4 normal = texture2D(normalTex, coord);
	// normal is a vec4 only normalize xyz
	normal.xyz = normalize((normal.xyz - 0.5) * 2.0);

	vec3 lightDirection = normalize(lightPosition - position.xyz);
	float nDotL = max(dot(normal.xyz, lightDirection.xyz), 0.0);
	float factor = smoothstep(-lightSize, 0.0, minusDistance);

	gl_FragData[0] = color * vec4(lightDiffuse, 1.0) * nDotL * factor;
	gl_FragData[0].a = 1.0;
}
";

	const char[] pointlight_shader_geom = "
uniform float near_clip;

varying in vec3 position[1];
varying in vec3 diffuse[1];
varying in float size[1];

varying out vec3 lightPosition;
varying out vec3 lightDiffuse;
varying out float lightSize;

vec4 transform(vec3 vector)
{
	vec4 result;
	result = gl_ProjectionMatrix * vec4(vector, 1.0);
	result /= result.w;
	return result;
}

void emit(vec4 pos)
{
	gl_Position = pos;
	lightPosition = position[0];
	lightDiffuse = diffuse[0];
	lightSize = size[0];
	EmitVertex();
}

void main() {
	vec3 pmin, pmax;
	pmin = vec3(-1.0, -1.0, -1.0) * size[0] + position[0];
	pmax = vec3( 1.0,  1.0,  1.0) * size[0] + position[0];

	// Discared if furthest point is behind near clip plane.
	if (pmin.z > -near_clip)
		return;

	// Clip nearest point to near clip plane
	if (pmax.z > -near_clip)
		pmax.z = -near_clip;

	vec4 p1, p2, p3, p4;
	p1 = transform(vec3(pmin.xyz));
	p2 = transform(vec3(pmin.xy, pmax.z));
	p3 = transform(vec3(pmax.xy, pmin.z));
	p4 = transform(vec3(pmax.xyz));
	vec2 minp = min(p1.xy, p2.xy);
	vec2 maxp = max(p3.xy, p4.xy);

	emit(vec4(minp.x, minp.y, p4.z, p4.w));
	emit(vec4(maxp.x, minp.y, p4.z, p4.w));
	emit(vec4(minp.x, maxp.y, p4.z, p4.w));
	emit(vec4(maxp.x, maxp.y, p4.z, p4.w));
	EndPrimitive();
}
";

	const char[] pointlight_shader_vertex = "
varying float size;
varying vec3 position;
varying vec3 diffuse;

void main() {
	position = (gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0)).xyz;
	size = gl_Vertex.w;
	diffuse = gl_Color.rgb;
	gl_Position = ftransform();
}
";

	const char[] directionlight_shader_frag = "
uniform vec2 screen;
uniform sampler2D colorTex;
uniform sampler2D normalTex;
uniform sampler2D depthTex;
uniform mat4 projectionMatrixInverse;
uniform vec3 lightDirection;
uniform vec4 lightDiffuse;
uniform vec4 lightAmbient;

void main()
{
	vec2 coord = gl_FragCoord.xy * screen;
	vec4 color = texture2D(colorTex, coord);
	vec4 normal = texture2D(normalTex, coord);
	float depth = texture2D(depthTex, coord).r;

	vec4 position = projectionMatrixInverse * vec4(coord, depth, 1.0);
	position.xyz /= position.w;
	// normal is a vec4 only normalize xyz
	normal.xyz = normalize((normal.xyz - 0.5) * 2.0);

	float nDotL = max(dot(normal.xyz, -lightDirection), 0.0);

	gl_FragData[0] = color * lightDiffuse * nDotL + color * lightAmbient;
	gl_FragData[0].a = 1.0;
}
";

	const char[] directionlight_split_shader_frag = "
#version 120
#extension GL_EXT_texture_array : enable
#extension GL_EXT_gpu_shader4 : enable

uniform vec2 screen;
uniform sampler2D colorTex;
uniform sampler2D normalTex;
uniform sampler2D depthTex;
uniform sampler2DArrayShadow shadowTex;
uniform mat4 projectionMatrixInverse;
uniform vec3 lightDirection;
uniform vec4 lightDiffuse;
uniform vec4 lightAmbient;
uniform vec4 slices;

float getCoffGuass(vec4 depthCoords)
{
	float ret = shadow2DArray(shadowTex, depthCoords).x * 0.25;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( -1, -1)).x * 0.0625;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( -1, 0)).x * 0.125;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( -1, 1)).x * 0.0625;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 0, -1)).x * 0.125;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 0, 1)).x * 0.125;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 1, -1)).x * 0.0625;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 1, 0)).x * 0.125;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 1, 1)).x * 0.0625;
	return ret;
}

float getCoffSimple(vec4 depthCoords)
{
	return shadow2DArray(shadowTex, depthCoords).r;
}

float shadowCoff(vec4 position)
{
	int index = 3;
	if (-position.z < slices.x)
		index = 0;
	else if (-position.z < slices.y)
		index = 1;
	else if (-position.z < slices.z)
		index = 2;

	// XXX The scale at the end should go away
	vec4 depthCoords = (gl_TextureMatrix[index] * vec4(position.xyz, 1.0)) * .5 + .5;
	depthCoords.w = depthCoords.z;
	depthCoords.z = index;

	// Make pixels realy far away less detailed
	if (index < 3)
		return getCoffGuass(depthCoords);
	else
		return getCoffSimple(depthCoords);
}

void main()
{
	vec2 coord = gl_FragCoord.xy * screen;
	vec4 color = texture2D(colorTex, coord);
	vec4 normal = texture2D(normalTex, coord);
	float depth = texture2D(depthTex, coord).r;

	vec4 position = projectionMatrixInverse * vec4(coord, depth, 1.0);
	position.xyz /= position.w;
	// normal is a vec4 only normalize xyz
	normal.xyz = normalize((normal.xyz - 0.5) * 2.0);

	float nDotL = max(dot(normal.xyz, -lightDirection), 0.0);
	float coff = shadowCoff(position);

	gl_FragData[0] = color * lightDiffuse * nDotL * coff + color * lightAmbient;
}
";

	const char[] directionlight_iso_shader_frag = "
#version 120
#extension GL_EXT_texture_array : enable
#extension GL_EXT_gpu_shader4 : enable

uniform vec2 screen;
uniform sampler2D colorTex;
uniform sampler2D normalTex;
uniform sampler2D depthTex;
uniform sampler2DArrayShadow shadowTex;
uniform mat4 projectionMatrixInverse;
uniform vec3 lightDirection;
uniform vec4 lightDiffuse;
uniform vec4 lightAmbient;

float getCoffGuass(vec4 depthCoords)
{
	float ret = shadow2DArray(shadowTex, depthCoords).x * 0.25;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( -1, -1)).x * 0.0625;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( -1, 0)).x * 0.125;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( -1, 1)).x * 0.0625;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 0, -1)).x * 0.125;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 0, 1)).x * 0.125;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 1, -1)).x * 0.0625;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 1, 0)).x * 0.125;
	ret += shadow2DArrayOffset(shadowTex, depthCoords, ivec2( 1, 1)).x * 0.0625;
	return ret;
}

float shadowCoff(vec4 position)
{
	int index = 0;

	// XXX The scale at the end should go away
	vec4 depthCoords = (gl_TextureMatrix[index] * vec4(position.xyz, 1.0)) * .5 + .5;
	depthCoords.w = depthCoords.z;
	depthCoords.z = index;

	return getCoffGuass(depthCoords);
}

void main()
{
	vec2 coord = gl_FragCoord.xy * screen;
	vec4 color = texture2D(colorTex, coord);
	vec4 normal = texture2D(normalTex, coord);
	float depth = texture2D(depthTex, coord).r;

	vec4 position = projectionMatrixInverse * vec4(coord, depth, 1.0);
	position.xyz /= position.w;
	// normal is a vec4 only normalize xyz
	normal.xyz = normalize((normal.xyz - 0.5) * 2.0);

	float nDotL = max(dot(normal.xyz, -lightDirection), 0.0);
	float coff = shadowCoff(position);

	gl_FragData[0] = color * lightDiffuse * nDotL * coff + color * lightAmbient;
}
";

	const char[] fog_shader_frag = "
uniform vec2 screen;
uniform sampler2D depthTex;
uniform mat4 projectionMatrixInverse;
uniform vec4 color;
uniform float start;
uniform float stop;

void main()
{
	vec2 coord = gl_FragCoord.xy * screen;
	float depth = texture2D(depthTex, coord).r;
	vec4 position = projectionMatrixInverse * vec4(coord, depth, 1.0);
	position.xyz /= position.w;
	float dist = distance(vec3(0.0, 0.0, 0.0), position.xyz);

	gl_FragData[0] = color;
	gl_FragData[0].a = smoothstep(start, stop, dist);
}
";

}

private class DeferredTarget : public RenderTarget
{
private:
	mixin Logging;

	uint w;
	uint h;
	uint colorTex;
	uint normalTex;
	uint depthTex;
	uint fbo;

public:
	this(uint w, uint h)
	{
		this.w = w;
		this.h = h;
		uint depthFormat, colorFormat, normalFormat;

		if (!GL_NV_depth_buffer_float) {
			colorFormat = GL_RGBA8;
			normalFormat = GL_RGB10_A2;
			depthFormat = GL_DEPTH_COMPONENT32;
		} else {
			colorFormat = GL_RGBA8;
			normalFormat = GL_RGB10_A2;
			depthFormat = GL_DEPTH_COMPONENT32F_NV;
		}

		if (!GL_EXT_framebuffer_object)
			throw new Exception("GL_EXT_framebuffer_object not supported");

		glGenTextures(1, &colorTex);
		glGenTextures(1, &normalTex);
		glGenTextures(1, &depthTex);
		glGenFramebuffersEXT(1, &fbo);

		scope(failure) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &colorTex);
			glDeleteTextures(1, &normalTex);
			glDeleteTextures(1, &depthTex);
			fbo = colorTex = normalTex = depthTex = 0;
		}

		glBindTexture(GL_TEXTURE_2D, colorTex);
		glTexImage2D(GL_TEXTURE_2D, 0, colorFormat, w, h, 0, GL_RGBA, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		glBindTexture(GL_TEXTURE_2D, normalTex);
		glTexImage2D(GL_TEXTURE_2D, 0, normalFormat, w, h, 0, GL_RGBA, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		glBindTexture(GL_TEXTURE_2D, depthTex);
		glTexImage2D(GL_TEXTURE_2D, 0, depthFormat, w, h, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		glBindTexture(GL_TEXTURE_2D, 0);

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, colorTex, 0);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT1_EXT, GL_TEXTURE_2D, normalTex, 0);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_2D, depthTex, 0);

		GLenum status = cast(GLenum)glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);

		if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
			throw new Exception("DeferredTarget framebuffer not complete " ~ std.string.toString(status));

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
		l.bug("Created new deferred render target (%sx%s)", w, h);
	}

	~this()
	{
		if (fbo || colorTex || normalTex || depthTex) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &colorTex);
			glDeleteTextures(1, &normalTex);
			glDeleteTextures(1, &depthTex);
		}
	}

	void setTarget()
	{
		static GLenum buffers[2] = [
			GL_COLOR_ATTACHMENT0_EXT,
			GL_COLOR_ATTACHMENT1_EXT,
		];
		gluFrameBufferBind(fbo, buffers, width, height);

	}

	int color()
	{
		return colorTex;
	}

	int normal()
	{
		return normalTex;
	}

	int depth()
	{
		return depthTex;
	}

	uint width()
	{
		return w;
	}

	uint height()
	{
		return h;
	}

}

private class DepthTarget : public RenderTarget
{
private:
	mixin Logging;

	uint w;
	uint h;
	uint depthTex;
	uint fbo;

public:
	this(uint w, uint h)
	{
		this.w = w;
		this.h = h;
		uint depthFormat;

		if (!GL_NV_depth_buffer_float) {
			depthFormat = GL_DEPTH_COMPONENT32;
		} else {
			depthFormat = GL_DEPTH_COMPONENT32F_NV;
		}

		if (!GL_EXT_framebuffer_object)
			throw new Exception("GL_EXT_framebuffer_object not supported");

		glGenTextures(1, &depthTex);
		glGenFramebuffersEXT(1, &fbo);

		scope(failure) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &depthTex);
			fbo = depthTex = 0;
		}

		glBindTexture(GL_TEXTURE_2D, depthTex);
		glTexImage2D(GL_TEXTURE_2D, 0, depthFormat, w, h, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		glBindTexture(GL_TEXTURE_2D, 0);

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_2D, depthTex, 0);

		GLenum status = cast(GLenum)glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);

		if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
			throw new Exception("DepthTarget framebuffer not complete " ~ std.string.toString(status));

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
		l.bug("Created new depth target (%sx%s)", w, h);
	}

	~this()
	{
		if (fbo || depthTex) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &depthTex);
		}
	}

	void setTarget()
	{
		static GLenum buffers[1] = [
			GL_NONE,
		];
		gluFrameBufferBind(fbo, buffers, width, height);
	}

	int depth()
	{
		return depthTex;
	}

	uint width()
	{
		return w;
	}

	uint height()
	{
		return h;
	}

}

private class DepthTargetArray : public RenderTarget
{
private:
	mixin Logging;

	uint w;
	uint h;
	uint num;
	uint depthTex;
	uint fbo;

public:
	this(uint w, uint h, int num)
	{
		this.w = w;
		this.h = h;
		this.num = num;
		uint depthFormat;

		if (1) {
			depthFormat = GL_DEPTH_COMPONENT24;
		} else if (!GL_NV_depth_buffer_float) {
			depthFormat = GL_DEPTH_COMPONENT32;
		} else {
			depthFormat = GL_DEPTH_COMPONENT32F_NV;
		}

		if (!GL_EXT_framebuffer_object)
			throw new Exception("GL_EXT_framebuffer_object not supported");
		if (!GL_EXT_texture_array)
			throw new Exception("GL_EXT_texture_array not supported");

		glGenTextures(1, &depthTex);
		glGenFramebuffersEXT(1, &fbo);

		scope(failure) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &depthTex);
			fbo = depthTex = 0;
		}

		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, depthTex);
		glTexImage3D(GL_TEXTURE_2D_ARRAY_EXT, 0, depthFormat,
		             w, h, num, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		//glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		//glTexParameteri(GL_TEXTURE_2D_ARRAY_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, 0);

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
		glDrawBuffer(GL_NONE);

		// Just bind the first in the array to check completness
		glFramebufferTextureLayerEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
		                             depthTex, 0, 0);

		GLenum status = cast(GLenum)glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);

		if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
			throw new Exception("DepthTargetArray framebuffer not complete " ~ std.string.toString(status));

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
		l.bug("Created new depth target array (%sx%s)x%s", w, h, num);
	}

	~this()
	{
		if (fbo || depthTex) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &depthTex);
		}
	}

	void setTarget()
	{
		setTarget(0);
		assert("Don't call setTarget on DepthTargetArray".ptr == null);
	}

	void setTarget(int layer)
	{
		static GLenum buffers[1] = [
			GL_NONE,
		];
		gluFrameBufferBind(fbo, buffers, width, height);
		glFramebufferTextureLayerEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
		                             depthTex, 0, layer);
	}

	int depthArray()
	{
		return depthTex;
	}

	uint width()
	{
		return w;
	}

	uint height()
	{
		return h;
	}

}
