// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.shader;

import std.c.stdlib : alloca;

import charge.math.color;
import charge.math.point3d;
import charge.math.vector3d;
import charge.math.matrix4x4d;
import charge.sys.logger;
import charge.gfx.gl;
import charge.gfx.uniform;


class Shader
{
protected:
	GLint glId;

public:
	this(GLuint id)
	{
		this.glId = id;
	}

	~this()
	{
		glDeleteProgram(id);
	}

final:
	uint id()
	{
		return glId;
	}

	void bind()
	{
		glUseProgram(glId);
	}

	void unbind()
	{
		glUseProgram(0);
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

	static GLuint makeShader(char[] vertex, char[] geom, char[] fragment,
	                         GLenum in_type, GLenum out_type, uint num_out)
	{
		int programShader = createAndCompileShader(vertex, geom, fragment);

		glProgramParameteriEXT(programShader, GL_GEOMETRY_INPUT_TYPE_EXT, in_type);
		glProgramParameteriEXT(programShader, GL_GEOMETRY_OUTPUT_TYPE_EXT, out_type);
		glProgramParameteriEXT(programShader, GL_GEOMETRY_VERTICES_OUT_EXT, num_out);

		// Linking the Shader Program
		glLinkProgram(programShader);

		// Print any debug message
		printDebug(programShader, true, "program (vert/geom/frag)");

		return programShader;
	}

	static GLuint makeShader(char[] vertex, char[] fragment)
	{
		// Compile the shaders
		auto programShader = createAndCompileShader(vertex, fragment);

		// Linking the Shader Program
		glLinkProgram(programShader);

		// Print any debug message
		printDebug(programShader, true, "program (vert/frag)");

		return programShader;

	}

	static GLuint makeShader(char[] vertex, char[] fragment,
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
	static GLuint createAndCompileShader(char[] vertex, char[] fragment)
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

	static GLuint createAndCompileShader(char[] vertex, char[] geometry, char[] fragment)
	{
		// Create the handels
		GLuint geomShader = glCreateShader(GL_GEOMETRY_SHADER_EXT);
		GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
		GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
		GLuint programShader = glCreateProgram();

		// Attach the shaders to a program handel.
		glAttachShader(programShader, geomShader);
		glAttachShader(programShader, vertexShader);
		glAttachShader(programShader, fragmentShader);

		// Load and compile the Geometry Shader
		compileShader(geomShader, geometry, "geometry");

		// Load and compile the Vertex Shader
		compileShader(vertexShader, vertex, "vertex");

		// Load and compile the Fragment Shader
		compileShader(fragmentShader, fragment, "fragment");

		// The shader objects are not needed any more,
		// the programShader is the complete shader to be used.
		glDeleteShader(geomShader);
		glDeleteShader(vertexShader);
		glDeleteShader(fragmentShader);

		return programShader;
	}

	static void compileShader(GLuint shader, char[] source, char[] type)
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

	private static bool printDebug(GLuint shader, bool program, char[] type)
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

		char[] buffer;
		if (length > 1) {
			// Yes length+1 and just length.
			buffer = (cast(char*)alloca(length+1))[0 .. length];
			if (program)
				glGetProgramInfoLog(shader, length, &length, buffer.ptr);
			else
				glGetShaderInfoLog(shader, length, &length, buffer.ptr);
			assert(buffer.length == length);
		}

		switch (status) {
		case GL_TRUE:
			// Only print warnings from the linking stage.
			if (length != 0 && program)
				l.warn("%s status: ok!\n%s", type, buffer);
			else
				l.trace("%s status: ok!", type);

			return true;

		case GL_FALSE:
			if (length != 0)
				l.error("%s status: bad!\n%s", type, buffer);
			else
				l.error("%s status: bad!", type);

			return false;

		default:
			if (length != 0)
				l.error("%s status: %s\n%s", type, status, buffer);
			else
				l.error("%s status: %s", type, status);

			return false;
		}
	}

}
