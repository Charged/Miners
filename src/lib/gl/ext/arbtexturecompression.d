// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.arbtexturecompression;

import lib.gl.types;


bool GL_ARB_texture_compression;

const GL_COMPRESSED_ALPHA_ARB = 0x84E9;
const GL_COMPRESSED_LUMINANCE_ARB = 0x84EA;
const GL_COMPRESSED_LUMINANCE_ALPHA_ARB = 0x84EB;
const GL_COMPRESSED_INTENSITY_ARB = 0x84EC;
const GL_COMPRESSED_RGB_ARB = 0x84ED;
const GL_COMPRESSED_RGBA_ARB = 0x84EE;
const GL_TEXTURE_COMPRESSION_HINT_ARB = 0x84EF;
const GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB = 0x86A0;
const GL_TEXTURE_COMPRESSED_ARB = 0x86A1;
const GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB = 0x86A2;
const GL_COMPRESSED_TEXTURE_FORMATS_ARB = 0x86A3;

extern(System):

void function(GLenum target, GLint level, GLenum initernalformat, GLsizei width, GLint border, GLsizei imageSize, void* data) glCompressedTexImage1DARB;
void function(GLenum target, GLint level, GLenum initernalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, void* data) glCompressedTexImage2DARB;
void function(GLenum target, GLint level, GLenum initernalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, void* data) glCompressedTexImage3DARB;
void function(GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, void* data) glCompressedTexSubImage1DARB;
void function(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, void* data) glCompressedTexSubImage2DARB;
void function(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, void* data) glCompressedTexSubImage3DARB;
void function(GLenum target, GLint lod, void* img) glGetCompressedTexImageARB;
