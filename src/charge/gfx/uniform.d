// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for shader uniforms.
 *
 * @todo add back ref.
 */
module charge.gfx.uniform;

import lib.gl.gl;

import charge.math.color;
import charge.math.quatd;
import charge.math.point3d;
import charge.math.vector3d;
import charge.math.matrix4x4d;


struct UniformFloat
{
	GLint loc;

	void init(string name, GLint id)
	{
		loc = glGetUniformLocation(id, name.ptr);
	}

	final void opAssign(float value)
	{
		glUniform1f(loc, value);
	}
}

struct UniformFloat2
{
	GLint loc;

	void init(string name, GLint id)
	{
		loc = glGetUniformLocation(id, name.ptr);
	}

	final void opAssign(float *value)
	{
		glUniform2fv(loc, 1, value);
	}
}

struct UniformFloat3
{
	GLint loc;

	void init(string name, GLint id)
	{
		loc = glGetUniformLocation(id, name.ptr);
	}

	final void opAssign(float *value)
	{
		glUniform3fv(loc, 1, value);
	}
}

struct UniformFloat4
{
	GLint loc;

	void init(string name, GLint id)
	{
		loc = glGetUniformLocation(id, name.ptr);
	}

	final void opAssign(float *value)
	{
		glUniform4fv(loc, 1, value);
	}
}

struct UniformColor4f
{
	GLint loc;

	void init(string name, GLint id)
	{
		loc = glGetUniformLocation(id, name.ptr);
	}

	final void opAssign(Color4f value)
	{
		glUniform4fv(loc, 1, value.ptr);
	}
}

struct UniformVector3d
{
	GLint loc;

	void init(string name, GLint id)
	{
		loc = glGetUniformLocation(id, name.ptr);
	}

	final void opAssign(float* value)
	{
		glUniform3fv(loc, 1, value);
	}

	final void opAssign(Vector3d value)
	{
		float[3] array;
		array[0] = value.x;
		array[1] = value.y;
		array[2] = value.z;
		glUniform3fv(loc, 1, array.ptr);
	}

	final void opAssign(Quatd value)
	{
		opAssign(value.rotateHeading);
	}
}

struct UniformPoint3d
{
	GLint loc;

	void init(string name, GLint id)
	{
		loc = glGetUniformLocation(id, name.ptr);
	}

	final void opAssign(float* value)
	{
		glUniform3fv(loc, 1, value);
	}

	final void opAssign(Point3d value)
	{
		float[3] array;
		array[0] = value.x;
		array[1] = value.y;
		array[2] = value.z;
		glUniform3fv(loc, 1, array.ptr);
	}
}

struct UniformMatrix4x4d
{
	GLint loc;

	void init(string name, GLint id)
	{
		loc = glGetUniformLocation(id, name.ptr);
	}

	void opAssign(Matrix4x4d value)
	{
		float[16] array;
		foreach(uint i, a; value.array)
			array[i] = cast(float)a;

		glUniformMatrix4fv(loc, 1, true, array.ptr);
	}

	void transposed(Matrix4x4d value)
	{
		float[16] array;
		foreach(uint i, a; value.array)
			array[i] = cast(float)a;

		glUniformMatrix4fv(loc, 1, false, array.ptr);
	}
}
