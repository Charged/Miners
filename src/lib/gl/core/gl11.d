// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.core.gl11;

import lib.gl.types;


bool GL_VERSION_1_1;

const GL_PROXY_TEXTURE_1D = 0x8063;
const GL_PROXY_TEXTURE_2D = 0x8064;
const GL_TEXTURE_PRIORITY = 0x8066;
const GL_TEXTURE_RESIDENT = 0x8067;
const GL_TEXTURE_BINDING_1D = 0x8068;
const GL_TEXTURE_BINDING_2D = 0x8069;
const GL_TEXTURE_INTERNAL_FORMAT = 0x1003;
const GL_ALPHA4 = 0x803B;
const GL_ALPHA8 = 0x803C;
const GL_ALPHA12 = 0x803D;
const GL_ALPHA16 = 0x803E;
const GL_LUMINANCE4 = 0x803F;
const GL_LUMINANCE8 = 0x8040;
const GL_LUMINANCE12 = 0x8041;
const GL_LUMINANCE16 = 0x8042;
const GL_LUMINANCE4_ALPHA4 = 0x8043;
const GL_LUMINANCE6_ALPHA2 = 0x8044;
const GL_LUMINANCE8_ALPHA8 = 0x8045;
const GL_LUMINANCE12_ALPHA4 = 0x8046;
const GL_LUMINANCE12_ALPHA12 = 0x8047;
const GL_LUMINANCE16_ALPHA16 = 0x8048;
const GL_INTENSITY = 0x8049;
const GL_INTENSITY4 = 0x804A;
const GL_INTENSITY8 = 0x804B;
const GL_INTENSITY12 = 0x804C;
const GL_INTENSITY16 = 0x804D;
const GL_R3_G3_B2 = 0x2A10;
const GL_RGB4 = 0x804F;
const GL_RGB5 = 0x8050;
const GL_RGB8 = 0x8051;
const GL_RGB10 = 0x8052;
const GL_RGB12 = 0x8053;
const GL_RGB16 = 0x8054;
const GL_RGBA2 = 0x8055;
const GL_RGBA4 = 0x8056;
const GL_RGB5_A1 = 0x8057;
const GL_RGBA8 = 0x8058;
const GL_RGB10_A2 = 0x8059;
const GL_RGBA12 = 0x805A;
const GL_RGBA16 = 0x805B;
const GL_CLIENT_PIXEL_STORE_BIT = 0x00000001;
const GL_CLIENT_VERTEX_ARRAY_BIT = 0x00000002;
const GL_ALL_CLIENT_ATTRIB_BITS = 0xFFFFFFFF;
const GL_CLIENT_ALL_ATTRIB_BITS = 0xFFFFFFFF;

extern(System):

void function(GLsizei,GLuint*) glGenTextures;
void function(GLsizei,GLuint*) glDeleteTextures;
void function(GLenum,GLuint) glBindTexture;
void function(GLsizei,GLuint*,GLclampf*) glPrioritizeTextures;
GLboolean function(GLsizei,GLuint*,GLboolean*) glAreTexturesResident;
GLboolean function(GLuint) glIsTexture;
void function(GLenum,GLint,GLint,GLsizei,GLenum,GLenum,const(GLvoid)*) glTexSubImage1D;
void function(GLenum,GLint,GLint,GLint,GLsizei,GLsizei,GLenum,GLenum,const(GLvoid)*) glTexSubImage2D;
void function(GLenum,GLint,GLenum,GLint,GLint,GLsizei,GLint) glCopyTexImage1D;
void function(GLenum,GLint,GLenum,GLint,GLint,GLsizei,GLsizei,GLint) glCopyTexImage2D;
void function(GLenum,GLint,GLint,GLint,GLint,GLsizei) glCopyTexSubImage1D;
void function(GLenum,GLint,GLint,GLint,GLint,GLint,GLsizei,GLsizei) glCopyTexSubImage2D;
void function(GLint,GLenum,GLsizei,const(GLvoid)*) glVertexPointer;
void function(GLenum,GLsizei,const(GLvoid)*) glNormalPointer;
void function(GLint,GLenum,GLsizei,const(GLvoid)*) glColorPointer;
void function(GLenum,GLsizei,const(GLvoid)*) glIndexPointer;
void function(GLint,GLenum,GLsizei,const(GLvoid)*) glTexCoordPointer;
void function(GLsizei,const(GLvoid)*) glEdgeFlagPointer;
void function(GLenum,GLvoid**) glGetPointerv;
void function(GLint) glArrayElement;
void function(GLenum,GLint,GLsizei) glDrawArrays;
void function(GLenum,GLsizei,GLenum,const(GLvoid)*) glDrawElements;
void function(GLenum,GLsizei,const(GLvoid)*) glInterleavedArrays;
