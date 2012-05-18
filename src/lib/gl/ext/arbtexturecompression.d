module lib.gl.arbtexturecompression;

import lib.loader;
import lib.gl.types;

bool GL_ARB_texture_compression;

void loadGL_ARB_texture_compression(Loader l) {
	if (!GL_ARB_texture_compression)
		return;

	loadFunc!(glCompressedTexImage1DARB)(l);
	loadFunc!(glCompressedTexImage2DARB)(l);
	loadFunc!(glCompressedTexImage3DARB)(l);
	loadFunc!(glCompressedTexSubImage1DARB)(l);
	loadFunc!(glCompressedTexSubImage2DARB)(l);
	loadFunc!(glCompressedTexSubImage3DARB)(l);
	loadFunc!(glGetCompressedTexImageARB)(l);
}

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
void (*glCompressedTexImage1DARB)(GLenum target, GLint level, GLenum initernalformat, GLsizei width, GLint border, GLsizei imageSize, void* data);
void (*glCompressedTexImage2DARB)(GLenum target, GLint level, GLenum initernalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, void* data);
void (*glCompressedTexImage3DARB)(GLenum target, GLint level, GLenum initernalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, void* data);
void (*glCompressedTexSubImage1DARB)(GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, void* data);
void (*glCompressedTexSubImage2DARB)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, void* data);
void (*glCompressedTexSubImage3DARB)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, void* data);
void (*glGetCompressedTexImageARB)(GLenum target, GLint lod, void* img);

