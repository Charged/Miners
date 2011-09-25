// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.forward;

import std.math;

import charge.math.color;
import charge.math.point3d;
import charge.math.vector3d;
import charge.math.matrix4x4d;
import charge.sys.logger;
import charge.gfx.gl;
import charge.gfx.light;
import charge.gfx.camera;
import charge.gfx.cull;
import charge.gfx.renderer;
import charge.gfx.renderqueue;
import charge.gfx.target;
import charge.gfx.shader;
import charge.gfx.texture;
import charge.gfx.material;
import charge.gfx.world;

/**
 * A bog standard forward renderer using shaders.
 */
class ForwardRenderer : public Renderer
{
protected:
	static Shader materialShaderMeshTex;
	static Shader materialShaderSkelTex;

private:
	mixin Logging;

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

			if (!GL_ARB_vertex_buffer_object)
				throw new Exception("ARB VBO extension not available");

			if (!GL_CHARGE_vertex_array_object)
				throw new Exception("ARB/APPLE VAO extension not available");

		} catch (Exception e) {
			l.info("Is not cabable of running forward renderer!");
			l.bug(e.toString());
			return false;
		}

		l.info("Can run forward renderer.");

		checkStatus = true;
		return true;
	}

	static bool init()
	{
		if (initialized)
			return true;

		if (!check())
			return false;

		materialShaderMeshTex =
			ShaderMaker(materialVertMesh,
				    materialFragTex,
				    ["vs_position", "vs_uv", "vs_normal"],
				    ["diffuseTex"]);

		materialShaderSkelTex =
			ShaderMaker(materialVertSkel,
				    materialFragTex,
				    ["vs_position", "vs_uv", "vs_normal"],
				    ["diffuseTex"]);

		initialized = true;
		return true;
	}

	this()
	{
		assert(initialized);
	}

protected:
	void render(Camera c, RenderQueue rq, World w)
	{
		renderTarget.setTarget();

		if (w.fog !is null) {
			auto fc = &w.fog.color;
			glClearColor(fc.r, fc.g, fc.b, 1.0);
		} else {
			glClearColor(   0,    0,    0, 1.0);
		}

		glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		c.transform();

		renderLoop(rq, w);

		glDisable(GL_DEPTH_TEST);
	}

	void renderLoop(RenderQueue rq, World w)
	{
		Renderable r;

		if (w.fog !is null) {
			glFogfv(GL_FOG_COLOR, w.fog.color.ptr);
			glFogf(GL_FOG_START, w.fog.start);
			glFogf(GL_FOG_END, w.fog.stop);
		}
		// TODO: no fog

		glAlphaFunc(GL_GEQUAL, 0.5f);

		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);

		// Render only the first SimpleLight
		auto sl = setupSimpleLight(w);

		for (r = rq.pop; r !is null; r = rq.pop) {
			auto sm = cast(SimpleMaterial)r.getMaterial();
			if (sm is null)
				continue;

			if (sm.fake)
				glEnable(GL_ALPHA_TEST);
			else
				glDisable(GL_ALPHA_TEST);

			if (sl !is null)
				render(sm, r, sl);
			else
				render(sm, r);
		}

		glUseProgram(0);
		glDisable(GL_CULL_FACE);
		glDisable(GL_ALPHA_TEST);
	}

	/**
	 * Setup the first SimpleLight found
	 */
	SimpleLight setupSimpleLight(World w)
	{
		SimpleLight sl;
		Matrix4x4d view;

		glGetDoublev(GL_MODELVIEW_MATRIX, view.array.ptr);
		view.transpose();

		foreach(l; w.lights) {
			sl = cast(SimpleLight)l;
			if (sl !is null)
				break;
		}

		if (sl is null)
			return null;

		auto direction = view * sl.rotation.rotateHeading;

		setupSimpleLight(materialShaderMeshTex, sl, direction);
		setupSimpleLight(materialShaderSkelTex, sl, direction);

		return sl;
	}

	/**
	 * Set the variables for a simple light to a shader.
	 *
	 * Also given the transformed direction vector.
	 */
	void setupSimpleLight(Shader s, SimpleLight sl, Vector3d dir)
	{
		glUseProgram(s.id);
		s.float3("lightDir", dir);
		s.float4("lightDiffuse", sl.diffuse);
		s.float4("lightAmbient", sl.ambient);
		glUseProgram(0);
	}

	void render(SimpleMaterial sm, Renderable r)
	{
		// TODO:
	}

	void render(SimpleMaterial sm, Renderable r, SimpleLight sl)
	{
		Shader s;

		if (sm.skel)
			s = materialShaderSkelTex;
		else
			s = materialShaderMeshTex;

		auto t = sm.texSafe;
		assert(t !is null);

		glBindTexture(GL_TEXTURE_2D, t.id);
		glUseProgram(s.id);

		r.drawAttrib(s);
	}

	/*
	 * Material Fragment shaders.
	 *
	 * They have the following varyings from the vertex shader:
	 *
	 * normal - normal in camera space.
	 * uv     - texture coordenate.
	 */

	const char[] materialFragTex = "
uniform sampler2D diffuseTex;

uniform vec3 lightDir;
uniform vec4 lightDiffuse;
uniform vec4 lightAmbient;

varying vec3 normal;
varying vec2 uv;

void main()
{
	vec4 color = texture2D(diffuseTex, uv);

	float nDotL = max(dot(normalize(normal), -lightDir), 0.0);

	// Lightning
	color.rgb = color.rgb * nDotL * lightDiffuse.rgb + color.rgb * lightAmbient.rgb;

	// Fog
	float depth = gl_FragCoord.z / gl_FragCoord.w;
	float fogFactor = smoothstep(gl_Fog.end, gl_Fog.start, depth);
	color.rgb = mix(gl_Fog.color.rgb, color.rgb, fogFactor);

	gl_FragColor = color;
}
";

	const char[] materialFragBlack = "
varying vec3 normal;
varying vec2 uv;

void main()
{
	vec4 color = vec4(0, 0, 0, 1);

	// Fog
	float depth = gl_FragCoord.z / gl_FragCoord.w;
	float fogFactor = smoothstep(gl_Fog.end, gl_Fog.start, depth);
	color.rgb = mix(gl_Fog.color.rgb, color.rgb, fogFactor);

	gl_FragColor = color;
}
";


	/*
	 * Material vertex shader.
	 */

	const char[] materialVertMesh = "
varying vec3 normal;
varying vec2 uv;

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

	const char[] materialVertSkel = "
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
}
