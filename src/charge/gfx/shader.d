// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.shader;


import charge.math.color;
import charge.math.point3d;
import charge.math.vector3d;
import charge.math.matrix4x4d;
import charge.sys.logger;
import charge.gfx.gl;

class Shader
{
private:
	uint glId;
	
public:
	this(uint id)
	{
		this.glId = id;
	}

	~this()
	{
		glDeleteProgram(id);
	}

	uint id()
	{
		return glId;
	}

	void int4(char *name, int count, int *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform4iv(loc, count, value);
	}

	void int3(char *name, int count, int *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform3iv(loc, count, value);
	}

	void int2(char *name, int count, int *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform2iv(loc, count, value);
	}

	void int1(char *name, int count, int *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform1iv(loc, count, value);
	}

	void float4(char *name, int count, float *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform4fv(loc, count, value);
	}

	void float4(char *name, float *value)
	{
		float4(name, 1, value);
	}

	void float4(char *name, Color4f value)
	{
		float4(name, 1, value.ptr);
	}

	void float4(char *name, float value[4])
	{
		float4(name, value.ptr);
	}

	void float3(char *name, int count, float *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform3fv(loc, count, value);
	}

	void float3(char *name, float *value)
	{
		float3(name, 1, value);
	}

	void float3(char *name, float array[3])
	{
		float3(name, array.ptr);
	}

	void float3(char *name, Point3d value)
	{
		float array[3];
		array[0] = value.x;
		array[1] = value.y;
		array[2] = value.z;
		float3(name, array.ptr);
	}

	void float3(char *name, Vector3d value)
	{
		float array[3];
		array[0] = value.x;
		array[1] = value.y;
		array[2] = value.z;
		float3(name, array.ptr);
	}

	void float2(char *name, int count, float *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform2fv(loc, count, value);
	}

	void float2(char *name, float *value)
	{
		float2(name, 1, value);
	}

	void float2(char *name, float value[2])
	{
		float2(name, value.ptr);
	}

	void float1(char *name, int count, float *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform1fv(loc, count, value);
	}

	void float1(char *name, float value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform1f(loc, value);
	}

	void matrix4(char *name, int count, bool transpose, float *value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniformMatrix4fv(loc, count, transpose, value);
	}

	void matrix4(char *name, bool transpose, ref Matrix4x4d matrix)
	{
		float array[16];
		foreach(uint i, a; matrix.array)
			array[i] = cast(float)a;

		matrix4(name, 1, transpose, array.ptr);
	}

	void sampler(char *name, int value)
	{
		int loc = glGetUniformLocation(glId, name);
		glUniform1i(loc, value);
	}

}

class ShaderMaker
{
private:
	mixin Logging;

public:
	static Shader opCall(char[] vertex, char[] fragment)
	{
		return new Shader(makeShader(vertex, fragment));
	}

	static Shader opCall(char[] vertex, char[] fragment,
			     char[][] bind_attributes,
			     char[][] bind_textures)
	{
		return new Shader(makeShader(vertex, fragment, bind_attributes, bind_textures));
	}

	static Shader opCall(char[] vertex, char[] geom, char[] fragment,
	                     GLenum in_type, GLenum out_type, uint num_out)
	{
		return new Shader(makeShader(vertex, geom, fragment, in_type, out_type, num_out));
	}

	static int makeShader(char[] vertex, char[] geom, char[] fragment,
	                      GLenum in_type, GLenum out_type, uint num_out)
	{
		if (!GL_EXT_geometry_shader4)
			throw new Exception("Geometry shaders not supported");

		// Create the handels
		uint geomShader = glCreateShader(GL_GEOMETRY_SHADER_EXT);
		uint vertexShader = glCreateShader(GL_VERTEX_SHADER);
		uint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
		uint programShader = glCreateProgram();

		// Attach the shaders to a program handel.
		glAttachShader(programShader, geomShader);
		glAttachShader(programShader, vertexShader);
		glAttachShader(programShader, fragmentShader);

		glProgramParameteriEXT(programShader, GL_GEOMETRY_INPUT_TYPE_EXT, in_type);
		glProgramParameteriEXT(programShader, GL_GEOMETRY_OUTPUT_TYPE_EXT, out_type);
		glProgramParameteriEXT(programShader, GL_GEOMETRY_VERTICES_OUT_EXT, num_out);

		// Load and compile the Geometry Shader
		compileShader(geomShader, geom, "geometry");

		// Load and compile the Vertex Shader
		compileShader(vertexShader, vertex, "vertex");

		// Load and compile the Fragment Shader
		compileShader(fragmentShader, fragment, "fragment");

		// Linking the Shader Program
		glLinkProgram(programShader);

		// Print any debug message
		printDebug(programShader, true, "program (vert/geom/frag)");

		// The shader objects are not needed any more,
		// the programShader is the complete shader to be used.
		glDeleteShader(vertexShader);
		glDeleteShader(fragmentShader);

		return programShader;
	}

	static int makeShader(char[] vertex, char[] fragment)

	{
		// Compile the shaders
		auto programShader = createAndCompileShader(vertex, fragment);

		// Linking the Shader Program
		glLinkProgram(programShader);

		// Print any debug message
		printDebug(programShader, true, "program (vert/frag)");

		return programShader;

	}

	static int makeShader(char[] vertex, char[] fragment,
			      char[][] bind_attributes,
			      char[][] bind_textures)
	{
		int status;

		// Compile the shaders
		auto shader = createAndCompileShader(vertex, fragment);

		foreach(uint i, name; bind_attributes) {
			if (name is null)
				continue;

			glBindAttribLocation(shader, i, name.ptr);
		}

		// Linking the Shader Program
		glLinkProgram(shader);

		// Print any debug message
		printDebug(shader, true, "program (vert/frag)");

		glGetProgramiv(shader, GL_LINK_STATUS, &status);

		if (status != 0) {
			glUseProgram(shader);
			foreach(uint i, name; bind_textures) {
				if (name is null)
					continue;

				int loc = glGetUniformLocation(shader, name.ptr);
				glUniform1i(loc, i);
			}
			glUseProgram(0);
		}

		return shader;

	}

private:
	static uint createAndCompileShader(char[] vertex, char[] fragment)
	{
		// Create the handels
		uint vertexShader = glCreateShader(GL_VERTEX_SHADER);
		uint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
		uint programShader = glCreateProgram();

		// Attach the shaders to a program handel.
		glAttachShader(programShader, vertexShader);
		glAttachShader(programShader, fragmentShader);

		// Load and compile the Vertex Shader
		compileShader(vertexShader, vertex, "vertex");

		// Load and compile the Fragment Shader
		compileShader(fragmentShader, fragment, "fragment");

		// The shader objects are not needed any more,
		// the programShader is the complete shader to be used.
		glDeleteShader(vertexShader);
		glDeleteShader(fragmentShader);

		return programShader;
	}

	static void compileShader(int shader, char[] source, char[] type)
	{
		char* ptr;
		int length;

		ptr = source.ptr;
		length = cast(int)source.length;
		glShaderSource(shader, 1, &ptr, &length);
		glCompileShader(shader);

		// Print any debug message
		printDebug(shader, false, type);
	}

	private static void printDebug(int shader, bool program, char[] type)
	{
		// Instead of pointers, realy bothersome.
		int status;
		int length;

		// Get information about the log on this object.
		if (program) {
			glGetProgramiv(shader, GL_LINK_STATUS, &status);
			glGetProgramiv(shader, GL_INFO_LOG_LENGTH, &length);
		} else {
			glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
			glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
		}

		if (status == 0) {
			char[] buffer = new char[++length];

			if (program)
				glGetProgramInfoLog(shader, length, &length, buffer.ptr);
			else
				glGetShaderInfoLog(shader, length, &length, buffer.ptr);

			buffer.length = length;

			if (length != 0)
				l.warn("%s status: %s\n%s", type, status, buffer);
			else
				l.warn("%s status: %s", type, status);
		} else {
			//l.trace("status: %s", status);
		}
	}

}
