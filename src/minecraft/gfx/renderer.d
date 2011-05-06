// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.gfx.renderer;

import minecraft.gfx.vbo;
import minecraft.gfx.imports;


class MinecraftForwardRenderer : public GfxFixedRenderer
{
private:
	GfxTexture tex;
	GfxTextureArray ta;
	GfxShader material_shader;
	GfxShader material_shader_indexed;

	mixin SysLogging;

public:
	static bool textureArraySupported;

	static bool check()
	{
		try {
			if (!GL_VERSION_2_0)
				throw new Exception("GL_VERSION < 2.0");
		} catch (Exception e) {
			l.warn("Is not cabable of running minecraft forward renderer!");
			l.warn(e.toString());
			l.warn(std.string.toString(glGetString(GL_RENDERER)));
			return false;
		}

		try {
			int value;

			if (!GL_EXT_texture_array)
				throw new Exception("GL_EXT_texture_array not supported");

			glGetIntegerv(GL_MAX_ARRAY_TEXTURE_LAYERS_EXT, &value);
			if (value < 256)
				throw new Exception("GL_EXT_texture_array doesn't support enough layers");

			textureArraySupported = true;
		} catch (Exception e) {
			l.warn("Not using texture arrrays (%s).", e.toString());
		}
		

		return true;
	}

	this(GfxTexture tex, GfxTextureArray ta)
	{
		this.ta = ta;
		this.tex = tex;

		if (textureArraySupported) {
			material_shader_indexed = GfxShaderMaker(Helper.materialVertCompactMeshIndexed,
								 Helper.materialFragForwardIndexed,
								 ["vs_position", "vs_data"],
								 ["diffuseTex"]);

			glUseProgram(material_shader_indexed.id);
			material_shader_indexed.float4("normals", 6, Helper.normals.ptr);
			material_shader_indexed.float4("uv_mixs", 6, Helper.uv_mixs.ptr);
			glUseProgram(0);
		}

		material_shader = GfxShaderMaker(Helper.materialVertCompactMesh,
						 Helper.materialFragForward,
						 ["vs_position", "vs_data"],
						 ["diffuseTex"]);

		glUseProgram(material_shader.id);
		material_shader.float4("normals", 6, Helper.normals.ptr);
		glUseProgram(0);
	}

	void setTerrainTexture(GfxTexture tex, GfxTextureArray ta)
	{
		this.ta = ta;
		this.tex = tex;
	}

protected:
	void renderLoop(GfxRenderQueue rq, GfxWorld w)
	{
		Matrix4x4d view;
		GfxRenderable r;
		GfxSimpleMaterial m;

		glGetDoublev(GL_MODELVIEW_MATRIX, view.array.ptr);
		view.transpose();

		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);

		auto shader = textureArraySupported ? material_shader_indexed : material_shader;

		foreach(l; w.lights) {
			auto sl = cast(GfxSimpleLight)l;
			if (sl is null)
				continue;

			auto direction = view * sl.rotation.rotateHeading;
		
			glUseProgram(shader.id);
			shader.float3("lightDir", direction);
			shader.float4("lightDiffuse", sl.diffuse);
			shader.float4("lightAmbient", sl.ambient);
			glUseProgram(0);
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

			continue;
		}

		glDisable(GL_CULL_FACE);
	}

	void drawGroup(ChunkVBOGroupCompactMesh cvgcm, GfxSimpleMaterial m)
	{
		if (cvgcm.result_num < 1)
			return;

		if (textureArraySupported) {
			glUseProgram(material_shader_indexed.id);
			glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, ta.id);
		} else {
			glUseProgram(material_shader.id);
			glBindTexture(GL_TEXTURE_2D, tex.id);
		}

		cvgcm.drawAttrib();

		glUseProgram(0);
	}
}

class MinecraftDeferredRenderer : public GfxDeferredRenderer
{
private:
	mixin SysLogging;
	static bool initialized;
	static GfxShader material_shader;
	static GfxShader material_shader_array;

	GfxTextureArray ta;

public:
	this(GfxTextureArray ta)
	{
		this.ta = ta;

		if (!initialized)
			throw new Exception("Not initialized or failed to init MinecraftRenderer");
		super();
	}

	void setTerrainTexture(GfxTextureArray ta)
	{
		this.ta = ta;
	}

	static bool check()
	{
		int value;

		try {
			if (!GL_VERSION_2_0)
				throw new Exception("GL_VERSION < 2.0");

			// XXX Should test for GL_EXT_gpu_shader4 as well
			if (!GL_EXT_geometry_shader4)
				throw new Exception("GL_EXT_geometry_shader4 not supported");

			if (!GL_EXT_texture_array)
				throw new Exception("GL_EXT_texture_array not supported");

			glGetIntegerv(GL_MAX_ARRAY_TEXTURE_LAYERS_EXT, &value);
			if (value < 256)
				throw new Exception("GL_EXT_texture_array doesn't support enough layers");

		} catch (Exception e) {
			l.warn("Is not cabable of running the deferred minecraft renderer!");
			l.warn(e.toString());
			l.warn(std.string.toString(glGetString(GL_RENDERER)));
			return false;
		}

		return true;
	}

	static bool init()
	{
		if (!check())
			return false;

		material_shader_array  = GfxShaderMaker(Helper.materialVertArrayIndexed,
							Helper.materialFragDeferred,
							["vs_data"],
							["diffuseTex"]);

		glUseProgram(material_shader_array.id);
		material_shader_array.float4("normals", 6, Helper.normals.ptr);
		material_shader_array.float4("uv_mixs", 6, Helper.uv_mixs.ptr);
		glUseProgram(0);

		material_shader = GfxShaderMaker(Helper.materialVertCompactMeshIndexed,
						 Helper.materialFragDeferred,
						 ["vs_position", "vs_data"],
						 ["diffuseTex"]);

		glUseProgram(material_shader.id);
		material_shader.float4("normals", 6, Helper.normals.ptr);
		material_shader.float4("uv_mixs", 6, Helper.uv_mixs.ptr);
		glUseProgram(0);

		initialized = true;

		return true;
	}

protected:
	void drawGroup(ChunkVBOGroupArray cvga, GfxSimpleMaterial m)
	{
		glUseProgram(material_shader_array.id);

		glDisable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, ta.id);
		cvga.drawShader(material_shader_array);

		glUseProgram(0);
	}

	void drawGroup(ChunkVBOGroupCompactMesh cvgcm, GfxSimpleMaterial m)
	{
		glUseProgram(material_shader.id);
		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, ta.id);

		cvgcm.drawAttrib();

		glUseProgram(0);
	}

	void renderDirectionLightShadow(GfxSimpleLight dl,
					GfxProjCamera cam,
					GfxWorld w,
					double near, double far,
	                                ref Matrix4x4d out_mat)
	{
		setMatrices(dl, cam, near, far);

		auto cull = new GfxCull(dl.position);
		auto rq = new GfxRenderQueue();

		foreach(a; w.actors)
		{
			a.cullAndPush(cull, rq);
		}

		for (auto r = rq.pop; r !is null; r = rq.pop) {
			auto m = cast(GfxSimpleMaterial)r.getMaterial();

			auto cvgmc = cast(ChunkVBOGroupCompactMesh)r;
			if (cvgmc !is null) {
				drawGroup(cvgmc, m);
				continue;
			}

			auto cvga = cast(ChunkVBOGroupArray)r;
			if (cvga !is null) {
				drawGroup(cvga, m);
				continue;
			}
		}
	}

	void renderLoop(GfxRenderQueue rq, GfxWorld w)
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
				drawGroup(cvgmc, m);
				continue;
			}

			auto cvg = cast(ChunkVBOGroupArray)r;
			if (cvg !is null) {
				drawGroup(cvg, m);
				continue;
			}
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
	const static float normals[] = [
		 0.0,  1.0,  0.0, 0.0, // Up
		 0.0, -1.0,  0.0, 0.0, // Down
		 1.0,  0.0,  0.0, 0.0,
		-1.0,  0.0,  0.0, 0.0,
		 0.0,  0.0,  1.0, 0.0,
		 0.0,  0.0, -1.0, 0.0,
	];
	const static float uv_mixs[] = [
		 1.0,  0.0,  1.0,  0.0, // Up
		 1.0,  0.0,  1.0,  0.0, // Down
		 0.0, -1.0,  0.0, -1.0,
		 0.0,  1.0,  0.0, -1.0,
		 1.0,  0.0,  0.0, -1.0,
		-1.0,  0.0,  0.0, -1.0,
	];

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

	const char[] materialFragForward = "
uniform sampler2D diffuseTex;

uniform vec3 lightDir;
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

	float nDotL = max(dot(normalize(normal), -lightDir), 0.0);
	float l = nDotL * light;

	gl_FragColor = vec4(color.rgb * l * lightDiffuse.rgb + color.rgb * lightAmbient.rgb * light, 1);
}
";

	const char[] materialFragForwardIndexed = "
#extension GL_EXT_texture_array : require

uniform sampler2DArray diffuseTex;

uniform vec3 lightDir;
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

	float nDotL = max(dot(normalize(normal), -lightDir), 0.0);
	float l = nDotL * light;

	gl_FragColor = vec4(color.rgb * l * lightDiffuse.rgb + color.rgb * lightAmbient.rgb * light, 1);
}
";

	const char[] materialFragDeferred = "
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

	gl_FragData[0] = vec4(color.rgb * light, 1.0);
	gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5 , 0.0);
}
";

	/*
	 * Material vertex shaders.
	 *
	 * Both can be used with either renderer.
	 */

	const char[] materialVertCompactMesh = "
uniform vec4 normals[6];
uniform vec4 uv_mixs[6];

varying vec3 normal;
varying float light;
varying vec2 uv;

attribute vec4 vs_position;
attribute vec4 vs_data;

void main()
{
	int g = int(vs_data.z);
	vec3 vs_normal = normals[int(vs_data.z)].xyz;
	light = 1.0 - vs_data.w * 0.4;

	uv = vs_data.xy / 16.0;

	// Okay for now, but this should not be done.
	normal = gl_NormalMatrix * vs_normal;
	gl_Position = gl_ModelViewProjectionMatrix * vs_position;
}
";

	const char[] materialVertCompactMeshIndexed = "
varying vec3 normal;
varying float light;
varying vec3 uvi;

attribute vec4 vs_position;
attribute vec4 vs_data;

uniform vec4 normals[6];
uniform vec4 uv_mixs[6];

void main()
{
	vec3 vs_normal = normals[int(vs_data.z)].xyz;
	vec4 mixs = uv_mixs[int(vs_data.z)];

	uvi.x = dot(vs_position.xz, mixs.xy);
	uvi.y = dot(vs_position.zy, mixs.zw);
	uvi.z = vs_data.x;
	light = 1.0 - vs_data.w * 0.4;

	// Okay for now, but this should not be done.
	normal = gl_NormalMatrix * vs_normal;
	gl_Position = gl_ModelViewProjectionMatrix * vs_position;
}
";

	const char[] materialVertArrayIndexed = "
#extension GL_EXT_gpu_shader4 : require

uniform vec4 normals[6];
uniform vec4 uv_mixs[6];

uniform vec2 offset;

varying float light;
varying vec3 normal;
varying vec3 uvi;

attribute vec4 vs_data;

void main()
{
	ivec2 bits = ivec2(vs_data.xy);
	ivec3 posInt;
	int lightInt;
	vec4 pos;
	float texture;

	posInt.x = (bits.x & 0x1f);
	int normalIndex = (bits.x >> 5) & 0x07;
	texture = float((bits.x >> 8) & 0xff);
	lightInt = (bits.y >> 12 & 0x0f);
	posInt.y = ((bits.y >> 5) & 0x7f);
	posInt.z = (bits.y & 0x1f);
	pos.xyz = vec3(posInt);

	vec4 mixs = uv_mixs[normalIndex];

	uvi.x = dot(pos.xz, mixs.xy);
	uvi.y = dot(pos.zy, mixs.zw);
	uvi.z = texture;

	pos.xyz += vec3(offset.x, -64, offset.y);
	pos.w = 1.0;

	light = 1.0 - float(lightInt) * 0.3;
	normal = gl_NormalMatrix * normals[normalIndex].xyz;
	gl_Position = gl_ModelViewProjectionMatrix * pos;
}
";

}
