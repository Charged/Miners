// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.extframebufferobject;

import lib.gl.types;


bool GL_EXT_framebuffer_object;

const GL_INVALID_FRAMEBUFFER_OPERATION_EXT = 0x0506;
const GL_MAX_RENDERBUFFER_SIZE_EXT = 0x84E8;
const GL_FRAMEBUFFER_BINDING_EXT = 0x8CA6;
const GL_RENDERBUFFER_BINDING_EXT = 0x8CA7;
const GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE_EXT = 0x8CD0;
const GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_EXT = 0x8CD1;
const GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL_EXT = 0x8CD2;
const GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE_EXT = 0x8CD3;
const GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_3D_ZOFFSET_EXT = 0x8CD4;
const GL_FRAMEBUFFER_COMPLETE_EXT = 0x8CD5;
const GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT = 0x8CD6;
const GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT = 0x8CD7;
const GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT = 0x8CD9;
const GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT = 0x8CDA;
const GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT = 0x8CDB;
const GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT = 0x8CDC;
const GL_FRAMEBUFFER_UNSUPPORTED_EXT = 0x8CDD;
const GL_MAX_COLOR_ATTACHMENTS_EXT = 0x8CDF;
const GL_COLOR_ATTACHMENT0_EXT = 0x8CE0;
const GL_COLOR_ATTACHMENT1_EXT = 0x8CE1;
const GL_COLOR_ATTACHMENT2_EXT = 0x8CE2;
const GL_COLOR_ATTACHMENT3_EXT = 0x8CE3;
const GL_COLOR_ATTACHMENT4_EXT = 0x8CE4;
const GL_COLOR_ATTACHMENT5_EXT = 0x8CE5;
const GL_COLOR_ATTACHMENT6_EXT = 0x8CE6;
const GL_COLOR_ATTACHMENT7_EXT = 0x8CE7;
const GL_COLOR_ATTACHMENT8_EXT = 0x8CE8;
const GL_COLOR_ATTACHMENT9_EXT = 0x8CE9;
const GL_COLOR_ATTACHMENT10_EXT = 0x8CEA;
const GL_COLOR_ATTACHMENT11_EXT = 0x8CEB;
const GL_COLOR_ATTACHMENT12_EXT = 0x8CEC;
const GL_COLOR_ATTACHMENT13_EXT = 0x8CED;
const GL_COLOR_ATTACHMENT14_EXT = 0x8CEE;
const GL_COLOR_ATTACHMENT15_EXT = 0x8CEF;
const GL_DEPTH_ATTACHMENT_EXT = 0x8D00;
const GL_STENCIL_ATTACHMENT_EXT = 0x8D20;
const GL_FRAMEBUFFER_EXT = 0x8D40;
const GL_RENDERBUFFER_EXT = 0x8D41;
const GL_RENDERBUFFER_WIDTH_EXT = 0x8D42;
const GL_RENDERBUFFER_HEIGHT_EXT = 0x8D43;
const GL_RENDERBUFFER_INTERNAL_FORMAT_EXT = 0x8D44;
const GL_STENCIL_INDEX1_EXT = 0x8D46;
const GL_STENCIL_INDEX4_EXT = 0x8D47;
const GL_STENCIL_INDEX8_EXT = 0x8D48;
const GL_STENCIL_INDEX16_EXT = 0x8D49;
const GL_RENDERBUFFER_RED_SIZE_EXT = 0x8D50;
const GL_RENDERBUFFER_GREEN_SIZE_EXT = 0x8D51;
const GL_RENDERBUFFER_BLUE_SIZE_EXT = 0x8D52;
const GL_RENDERBUFFER_ALPHA_SIZE_EXT = 0x8D53;
const GL_RENDERBUFFER_DEPTH_SIZE_EXT = 0x8D54;
const GL_RENDERBUFFER_STENCIL_SIZE_EXT = 0x8D55;

extern(System):

void function(GLenum target, GLuint framebuffer) glBindFramebufferEXT;
void function(GLenum target, GLuint renderbuffer) glBindRenderbufferEXT;
GLenum function(GLenum target) glCheckFramebufferStatusEXT;
void function(GLsizei n, GLuint* framebuffers) glDeleteFramebuffersEXT;
void function(GLsizei n, GLuint* renderbuffers) glDeleteRenderbuffersEXT;
void function(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer) glFramebufferRenderbufferEXT;
void function(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level) glFramebufferTexture1DEXT;
void function(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level) glFramebufferTexture2DEXT;
void function(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset) glFramebufferTexture3DEXT;
void function(GLsizei n, GLuint* framebuffers) glGenFramebuffersEXT;
void function(GLsizei n, GLuint* renderbuffers) glGenRenderbuffersEXT;
void function(GLenum target) glGenerateMipmapEXT;
void function(GLenum target, GLenum attachment, GLenum pname, GLint* params) glGetFramebufferAttachmentParameterivEXT;
void function(GLenum target, GLenum pname, GLint* params) glGetRenderbufferParameterivEXT;
GLboolean function(GLuint framebuffer) glIsFramebufferEXT;
GLboolean function(GLuint renderbuffer) glIsRenderbufferEXT;
void function(GLenum target, GLenum initernalformat, GLsizei width, GLsizei height) glRenderbufferStorageEXT;
