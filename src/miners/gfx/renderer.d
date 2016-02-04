// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.gfx.renderer;

import miners.gfx.vbo;
import miners.gfx.imports;
import miners.gfx.selector;


class MinecraftForwardRenderer : GfxForwardRenderer
{
private:
	GfxForwardMaterialShader materialShader;
	GfxForwardMaterialShader materialShaderIndexed;

	mixin SysLogging;

	static bool checked;
	static bool checkStatus;

public:
	static bool textureArraySupported;

	static bool check()
	{
		if (checked)
			return checkStatus;

		// We have checked, if we fail that means we failed.
		checked = true;

		if (!GfxForwardRenderer.check())
			return false;

		try {
			if (!GL_VERSION_2_1)
				throw new Exception("GL_VERSION < 2.1");

			if (!GL_ARB_vertex_buffer_object)
				throw new Exception("ARB VBO extension not available");

			if (!GL_CHARGE_vertex_array_object)
				throw new Exception("ARB/APPLE VAO extension not available");

		} catch (Exception e) {
			l.warn("Is not cabable of running minecraft forward renderer!");
			l.warn(e.toString());
			return false;
		}

		try {
			int value;

			if (!GfxTextureArray.check())
				throw new Exception("Texture Arrays not supported");

			glGetIntegerv(GL_MAX_ARRAY_TEXTURE_LAYERS_EXT, &value);
			if (value < 256)
				throw new Exception("GL_EXT_texture_array doesn't support enough layers");

			textureArraySupported = true;
		} catch (Exception e) {
			l.warn("Not using texture arrrays (%s).", e.toString());
		}

		l.info("Can run Miners forward renderer.");

		checkStatus = true;
		return true;
	}

	this()
	{
		assert(initialized);

		if (textureArraySupported) {
			materialShaderIndexed = new GfxForwardMaterialShader(
				Helper.materialVertCompactMeshIndexed, Helper.materialFragForwardIndexed);

			materialShaderIndexed.bind();
			materialShaderIndexed.float4("normals", cast(uint)Helper.normals.length / 4, Helper.normals.ptr);
			materialShaderIndexed.float4("uv_mixs", cast(uint)Helper.uv_mixs.length / 4, Helper.uv_mixs.ptr);
			glUseProgram(0);
		}

		materialShader = new GfxForwardMaterialShader(
			Helper.materialVertCompactMesh, Helper.materialFragForward);

		materialShader.bind();
		materialShader.float4("normals", cast(uint)Helper.normals.length / 4, Helper.normals.ptr);
		glUseProgram(0);
	}

protected:
	override void renderLoop(GfxRenderQueue rq, GfxWorld w)
	{
		Matrix4x4d view;
		GfxRenderable r;
		GfxSimpleMaterial m;

		glGetDoublev(GL_MODELVIEW_MATRIX, view.array.ptr);
		view.transpose();

		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);

		auto shader = textureArraySupported ? materialShaderIndexed : materialShader;

		auto sl = setupSimpleLight(w);

		auto direction = view * sl.rotation.rotateHeading;
		setupSimpleLight(shader, sl, direction);

		if (w.fog !is null) {
			glFogfv(GL_FOG_COLOR, w.fog.color.ptr);
			glFogf(GL_FOG_START, w.fog.start);
			glFogf(GL_FOG_END, w.fog.stop);
		} else {
			// XXX Work around not having a non-fog set of shaders.
			glFogfv(GL_FOG_COLOR, Color4f.Black.ptr);
			glFogf(GL_FOG_START, float.max/4048);
			glFogf(GL_FOG_END, float.max/2024);
		}

		for (r = rq.pop; r !is null; r = rq.pop) {
			m = cast(GfxSimpleMaterial)r.getMaterial();
			if (m is null)
				continue;

			auto cvgmc = cast(ChunkVBOGroupCompactMesh)r;
			if (cvgmc !is null) {
				drawGroup(cvgmc, m);
				continue;
			}

			if (sl !is null)
				render(m, r, sl);
			else
				render(m, r);
		}

		glUseProgram(0);
		glDisable(GL_CULL_FACE);
	}

	void drawGroup(ChunkVBOGroupCompactMesh cvgcm, GfxSimpleMaterial m)
	{
		GfxShader s;

		if (cvgcm.result_num < 1)
			return;

		if (textureArraySupported) {
			s = materialShaderIndexed;
			s.bind();
			glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, m.texSafe.id);
		} else {
			s = materialShader;
			s.bind();
			glBindTexture(GL_TEXTURE_2D, m.texSafe.id);
		}

		if (m.stipple) {
			glPolygonStipple(cast(GLubyte*)Helper.stipplePattern.ptr);
			glEnable(GL_POLYGON_STIPPLE);
			glDisable(GL_CULL_FACE);
			cvgcm.drawAttrib(s);
			glEnable(GL_CULL_FACE);
			glDisable(GL_POLYGON_STIPPLE);
		} else {
			cvgcm.drawAttrib(s);
		}

		glUseProgram(0);
	}
}

class MinecraftDeferredRenderer : GfxDeferredRenderer
{
private:
	mixin SysLogging;
	static bool initialized;
	static GfxShader materialShader;

	static bool checked;
	static bool checkStatus;

public:
	static bool check()
	{
		if (checked)
			return checkStatus;

		// We have checked, if we fail that means we failed.
		checked = true;

		if (!GfxDeferredRenderer.check())
			return false;

		int value;

		try {
			if (!GL_VERSION_2_1)
				throw new Exception("GL_VERSION < 2.1");

			if (!GL_ARB_vertex_buffer_object)
				throw new Exception("ARB VBO extension not available");

			if (!GL_CHARGE_vertex_array_object)
				throw new Exception("ARB/APPLE VAO extension not available");

			// XXX Should test for GL_EXT_gpu_shader4 as well
			if (!GL_EXT_geometry_shader4)
				throw new Exception("GL_EXT_geometry_shader4 not supported");

			if (!GL_EXT_texture_array)
				throw new Exception("GL_EXT_texture_array not supported");

			glGetIntegerv(GL_MAX_ARRAY_TEXTURE_LAYERS_EXT, &value);
			if (value < 256)
				throw new Exception("GL_EXT_texture_array doesn't support enough layers");

		} catch (Exception e) {
			l.warn("Is not cabable of running the deferred miners renderer!");
			l.warn(e.toString());
			return false;
		}

		l.info("Can run deferred miners renderer.");

		checkStatus = true;
		return true;
	}

	static bool init()
	{
		if (initialized)
			return true;

		if (!GfxDeferredRenderer.init())
			return false;

		if (!check())
			return false;

		materialShader = new GfxDeferredMaterialShader(
			Helper.materialVertCompactMeshIndexed,
			Helper.materialFragDeferred);

		materialShader.bind();
		materialShader.float4("normals", cast(uint)Helper.normals.length / 4, Helper.normals.ptr);
		materialShader.float4("uv_mixs", cast(uint)Helper.uv_mixs.length / 4, Helper.uv_mixs.ptr);
		glUseProgram(0);

		initialized = true;

		return true;
	}

	this()
	{
		assert(initialized);
	}

protected:
	void renderGroup(ChunkVBOGroupCompactMesh cvgcm, GfxSimpleMaterial m, bool shadow)
	{
		materialShader.bind();
		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, m.texSafe.id);

		if (m.stipple && !shadow) {
			glPolygonStipple(cast(GLubyte*)Helper.stipplePattern.ptr);
			glEnable(GL_POLYGON_STIPPLE);
			glDisable(GL_CULL_FACE);
			cvgcm.drawAttrib(materialShader);
			glEnable(GL_CULL_FACE);
			glDisable(GL_POLYGON_STIPPLE);
		} else {
			cvgcm.drawAttrib(materialShader);
		}

		glUseProgram(0);
	}

	override void renderShadowLoop(Point3d pos, GfxWorld w)
	{
		auto cull = new GfxCull(pos);
		auto rq = new GfxRenderQueue();

		foreach(a; w.actors)
		{
			a.cullAndPush(cull, rq);
		}

		for (auto r = rq.pop; r !is null; r = rq.pop) {
			auto m = cast(GfxSimpleMaterial)r.getMaterial();

			auto cvgmc = cast(ChunkVBOGroupCompactMesh)r;
			if (cvgmc !is null) {
				renderGroup(cvgmc, m, true);
				continue;
			}

			// XXX Fix me!
			auto sel = cast(Selector)r;
			if (sel !is null)
				continue;

			renderShadow(r, m);
		}
	}

	override void renderLoop(GfxRenderQueue rq, GfxWorld w)
	{
		GfxSimpleMaterial m;
		GfxRenderable r;

		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);
		glActiveTexture(GL_TEXTURE0);

		for (r = rq.pop; r !is null; r = rq.pop) {
			m = cast(GfxSimpleMaterial)r.getMaterial();
			if (m is null)
				continue;

			auto cvgmc = cast(ChunkVBOGroupCompactMesh)r;
			if (cvgmc !is null) {
				renderGroup(cvgmc, m, false);
				continue;
			}

			render(r, m);
		}

		glActiveTexture(GL_TEXTURE0);
		glUseProgram(0);
		glDisable(GL_CULL_FACE);
	}

protected:

}

private class Helper
{
public:
	const static float[] normals = [
		-1.0,  0.0,  0.0, 0.0, // XN
		 1.0,  0.0,  0.0, 0.0, // XP
		 0.0, -1.0,  0.0, 0.0, // YN - Down
		 0.0,  1.0,  0.0, 0.0, // YP - Up
		 0.0,  0.0, -1.0, 0.0, // ZN
		 0.0,  0.0,  1.0, 0.0, // ZP

		-1.0,  0.0, -1.0, 0.0, // XNZN
		-1.0,  0.0,  1.0, 0.0, // XNZP
		 1.0,  0.0, -1.0, 0.0, // XPZN
		 1.0,  0.0,  1.0, 0.0, // XPZP
	];
	const static float[] uv_mixs = [
		 0.0,  1.0,  0.0, -1.0, // XN
		 0.0, -1.0,  0.0, -1.0, // XP
		 1.0,  0.0,  1.0,  0.0, // YN - Down
		 1.0,  0.0,  1.0,  0.0, // YP - Up
		-1.0,  0.0,  0.0, -1.0, // ZN
		 1.0,  0.0,  0.0, -1.0, // ZP

		 0.0,  1.0,  0.0, -1.0, // XNZN
		 0.0, -1.0,  0.0, -1.0, // XMZP
		-1.0,  0.0,  0.0, -1.0, // XPZN
		 1.0,  0.0,  0.0, -1.0, // XPZP
	];

	static uint[32] stipplePattern;

	static this()
	{
		foreach(int i, ref p; stipplePattern)
			p = 0x55_55_55_55 << (i % 2);
	}

	/*
	 * Material Fragment shaders.
	 *
	 * Used both for forward and deferred. They both have the following
	 * varyings from the vertex shader:
	 *
	 * light - ambient occlusion term.
	 * normal - normal in camera space.
	 * uv(i) - texture coordenate, i is sufixed for texture array versions.
	 */

	enum string materialFragForward = "
#version 120

uniform sampler2D diffuseTex;

uniform vec3 lightDirection;
uniform vec4 lightDiffuse;
uniform vec4 lightAmbient;

varying float light;
varying vec3 normal;
varying vec2 uv;

void main()
{
	vec4 color = texture2D(diffuseTex, uv);
	if (color.a < 0.5)
		discard;

	vec3 n = normalize(normal);
	if (!gl_FrontFacing)
		n = -n;

	float nDotL = max(dot(n, -lightDirection), 0.0);
	float l = nDotL * light;

	// Lightning
	color.rgb = color.rgb * l * lightDiffuse.rgb + color.rgb * lightAmbient.rgb * light;

	// Fog
	float depth = gl_FragCoord.z / gl_FragCoord.w;
	float fogFactor = smoothstep(gl_Fog.end, gl_Fog.start, depth);
	color.rgb = mix(gl_Fog.color.rgb, color.rgb, fogFactor);

	gl_FragColor = vec4(color.rgb, 1);
}
";

	enum string materialFragForwardIndexed = "
#version 120
#extension GL_EXT_texture_array : require

uniform sampler2DArray diffuseTex;

uniform vec3 lightDirection;
uniform vec4 lightDiffuse;
uniform vec4 lightAmbient;

varying float light;
varying vec3 normal;
varying vec3 uvi;

void main()
{
	vec4 color = texture2DArray(diffuseTex, uvi);
	if (color.a < 0.5)
		discard;

	vec3 n = normalize(normal);
	if (!gl_FrontFacing)
		n = -n;

	float nDotL = max(dot(n, -lightDirection), 0.0);
	float l = nDotL * light;

	// Lighting
	color.rgb = color.rgb * l * lightDiffuse.rgb + color.rgb * lightAmbient.rgb * light;

	// Fog
	float depth = gl_FragCoord.z / gl_FragCoord.w;
	float fogFactor = smoothstep(gl_Fog.end, gl_Fog.start, depth);
	color.rgb = mix(gl_Fog.color.rgb, color.rgb, fogFactor);

	gl_FragColor = vec4(color.rgb, 1);
}
";

	enum string materialFragDeferred = "
#version 120
#extension GL_EXT_texture_array : require

uniform sampler2DArray diffuseTex;

varying float light;
varying vec3 normal;
varying vec3 uvi;

void main()
{
	vec4 color = texture2DArray(diffuseTex, uvi);
	if (color.a < 0.5)
		discard;

	vec3 n = normalize(normal);
	if (!gl_FrontFacing)
		n = -n;

	gl_FragData[0] = vec4(color.rgb * light, 1.0);
	gl_FragData[1] = vec4(n * 0.5 + 0.5, 0.0);
}
";

	/*
	 * Material vertex shaders.
	 *
	 * Both can be used with either renderer.
	 */

	enum string materialVertCompactMesh = "
#version 120

uniform vec4 normals[10];
uniform vec4 uv_mixs[10];

varying vec3 normal;
varying float light;
varying vec2 uv;

attribute vec4 vs_position;
attribute vec2 vs_uv;
attribute vec4 vs_data;

void main()
{
	vec3 vs_normal = normals[int(vs_data.y)].xyz;
	light = 1.0 - vs_data.x * 0.4;

	uv = vs_uv.xy / 256.0;

	// Okay for now, but this should not be done.
	normal = gl_NormalMatrix * vs_normal;
	gl_Position = gl_ModelViewProjectionMatrix * vs_position;
}
";

	enum string materialVertCompactMeshIndexed = "
#version 120

varying vec3 normal;
varying float light;
varying vec3 uvi;

attribute vec4 vs_position;
attribute vec2 vs_uv;
attribute vec4 vs_data;

uniform vec4 normals[10];
uniform vec4 uv_mixs[10];

void main()
{
	vec3 vs_normal = normals[int(vs_data.y)].xyz;

	uvi.xy = vs_uv / 256.0;
	uvi.z = vs_data.z;
	light = 1.0 - vs_data.x * 0.4;

	// Okay for now, but this should not be done.
	normal = gl_NormalMatrix * vs_normal;
	gl_Position = gl_ModelViewProjectionMatrix * vs_position;
}
";
}
