// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for common OpenGL imports and helpers.
 */
module charge.gfx.gl;

import std.stdio : writef, writefln;

public {
	import lib.gl.gl;
	import lib.gl.glu;
}

import charge.math.movable;
import charge.math.matrix3x3d;
import charge.math.matrix4x4d;

import charge.gfx.texture;


void gluPushAndTransform(Point3d p, Quatd q)
{
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();

	Matrix3x3d rot;
	Matrix4x4d glRot;

	rot = q;

	for( int x = 0; x < 3; x++ )
		for( int y = 0; y < 3; y++ )
			glRot.m[x][y] = rot.m[y][x];

	glRot.m[3][0] = p.x;
	glRot.m[3][1] = p.y;
	glRot.m[3][2] = p.z;
	glRot.m[3][3] = 1.0;
	glRot.m[2][3] = 0.0;
	glRot.m[1][3] = 0.0;
	glRot.m[0][3] = 0.0;

	glMultMatrixd(glRot.m.ptr.ptr);
}

void gluGetError(string text = null)
{
	auto err = glGetError();
	if (err == GL_NO_ERROR)
		return;

	writef("glError: ");
	if (text)
		writef("(%s) ", text);

	switch (err) {
	case GL_INVALID_ENUM:
		writefln("GL_INVALID_ENUM");
		break;
	case GL_INVALID_VALUE:
		writefln("GL_INVALID_ENUM");
		break;
	case GL_INVALID_OPERATION:
		writefln("GL_INVALID_OPERATION");
		break;
	case GL_STACK_OVERFLOW:
		writefln("GL_STACK_OVERFLOW");
		break;
	case GL_STACK_UNDERFLOW:
		writefln("GL_STACK_UNDERFLOW");
		break;
	case GL_OUT_OF_MEMORY:
		writefln("GL_OUT_OF_MEMORY");
		break;
	case GL_INVALID_FRAMEBUFFER_OPERATION_EXT:
		writefln("GL_INVALID_FRAMEBUFFER_OPERATION");
		break;
	default:
		writefln("GL_UNKNOWN_ERROR");
	}
}

string gluCheckFramebufferStatus()
{
	auto status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);

	switch (status) {
	case GL_FRAMEBUFFER_COMPLETE_EXT:
		return null;
	case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT:
		return "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT";
	case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT:
		return "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT";
	case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT:
		return "GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT";
	case GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT:
		return "GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT";
	case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT:
		return "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT";
	case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT:
		return "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT";
	case GL_FRAMEBUFFER_UNSUPPORTED_EXT:
		return "GL_FRAMEBUFFER_UNSUPPORTED_EXT";
	default:
		return "GL_FRAMEBUFFER_UNKNOWN";
	}
}

void gluTexUnitDisable(GLenum target, uint unit)
{
	glActiveTexture(GL_TEXTURE0 + unit);
	glDisable(target);
}

void gluTexUnitDisableUnbind(GLenum target, uint unit)
{
	gluTexUnitDisable(target, unit);
	glBindTexture(target, 0);
}

void gluTexUnitEnable(GLenum target, uint unit)
{
	glActiveTexture(GL_TEXTURE0 + unit);
	glEnable(target);
}

void gluTexUnitEnableBind(GLenum target, uint unit, GLuint id)
{
	gluTexUnitEnable(target, unit);
	glBindTexture(target, id);
}

void gluTexUnitEnableBind(GLenum target, uint unit, Texture tex)
{
	gluTexUnitEnableBind(target, unit, tex.id);
}

void gluPushMatricesAttrib(GLenum attrib)
{
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glPushAttrib(attrib);
}

void gluPopMatricesAttrib()
{
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	glPopAttrib();
}

void gluFrameBufferBind(GLuint fbo, GLenum buffers[], GLuint width, GLuint height)
{
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
	glDrawBuffers(cast(GLuint)buffers.length, buffers.ptr);
	glViewport(0, 0, width, height);
}
