// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.core.gl14;

import lib.gl.types;


bool GL_VERSION_1_4;

const GL_GENERATE_MIPMAP = 0x8191;
const GL_GENERATE_MIPMAP_HINT = 0x8192;
const GL_DEPTH_COMPONENT16 = 0x81A5;
const GL_DEPTH_COMPONENT24 = 0x81A6;
const GL_DEPTH_COMPONENT32 = 0x81A7;
const GL_TEXTURE_DEPTH_SIZE = 0x884A;
const GL_DEPTH_TEXTURE_MODE = 0x884B;
const GL_TEXTURE_COMPARE_MODE = 0x884C;
const GL_TEXTURE_COMPARE_FUNC = 0x884D;
const GL_COMPARE_R_TO_TEXTURE = 0x884E;
const GL_FOG_COORDINATE_SOURCE = 0x8450;
const GL_FOG_COORDINATE = 0x8451;
const GL_FRAGMENT_DEPTH = 0x8452;
const GL_CURRENT_FOG_COORDINATE = 0x8453;
const GL_FOG_COORDINATE_ARRAY_TYPE = 0x8454;
const GL_FOG_COORDINATE_ARRAY_STRIDE = 0x8455;
const GL_FOG_COORDINATE_ARRAY_POINTER = 0x8456;
const GL_FOG_COORDINATE_ARRAY = 0x8457;
const GL_POINT_SIZE_MIN = 0x8126;
const GL_POINT_SIZE_MAX = 0x8127;
const GL_POINT_FADE_THRESHOLD_SIZE = 0x8128;
const GL_POINT_DISTANCE_ATTENUATION = 0x8129;
const GL_COLOR_SUM = 0x8458;
const GL_CURRENT_SECONDARY_COLOR = 0x8459;
const GL_SECONDARY_COLOR_ARRAY_SIZE = 0x845A;
const GL_SECONDARY_COLOR_ARRAY_TYPE = 0x845B;
const GL_SECONDARY_COLOR_ARRAY_STRIDE = 0x845C;
const GL_SECONDARY_COLOR_ARRAY_POINTER = 0x845D;
const GL_SECONDARY_COLOR_ARRAY = 0x845E;
const GL_BLEND_DST_RGB = 0x80C8;
const GL_BLEND_SRC_RGB = 0x80C9;
const GL_BLEND_DST_ALPHA = 0x80CA;
const GL_BLEND_SRC_ALPHA = 0x80CB;
const GL_INCR_WRAP = 0x8507;
const GL_DECR_WRAP = 0x8508;
const GL_TEXTURE_FILTER_CONTROL = 0x8500;
const GL_TEXTURE_LOD_BIAS = 0x8501;
const GL_MAX_TEXTURE_LOD_BIAS = 0x84FD;
const GL_MIRRORED_REPEAT = 0x8370;

extern(System):

void function(GLenum mode) glBlendEquation;
void function(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha) glBlendColor;
void function(GLfloat coord) glFogCoordf;
void function(GLfloat *coord) glFogCoordfv;
void function(GLdouble coord) glFogCoordd;
void function(GLdouble *coord) glFogCoorddv;
void function(GLenum type, GLsizei stride, GLvoid *pointer) glFogCoordPointer;
void function(GLenum mode, GLint *first, GLsizei *count, GLsizei primcount) glMultiDrawArrays;
void function(GLenum mode, GLsizei *count, GLenum type, GLvoid **indices, GLsizei primcount) glMultiDrawElements;
void function(GLenum pname, GLint param) glPointParameteri;
void function(GLenum pname, GLint *params) glPointParameteriv;
void function(GLenum pname, GLfloat param) glPointParameterf;
void function(GLenum pname, GLfloat *params) glPointParameterfv;
void function(GLbyte red, GLbyte green, GLbyte blue) glSecondaryColor3b;
void function(GLbyte *v) glSecondaryColor3bv;
void function(GLdouble red, GLdouble green, GLdouble blue) glSecondaryColor3d;
void function(GLdouble *v) glSecondaryColor3dv;
void function(GLfloat red, GLfloat green, GLfloat blue) glSecondaryColor3f;
void function(GLfloat *v) glSecondaryColor3fv;
void function(GLint red, GLint green, GLint blue) glSecondaryColor3i;
void function(GLint *v) glSecondaryColor3iv;
void function(GLshort red, GLshort green, GLshort blue) glSecondaryColor3s;
void function(GLshort *v) glSecondaryColor3sv;
void function(GLubyte red, GLubyte green, GLubyte blue) glSecondaryColor3ub;
void function(GLubyte *v) glSecondaryColor3ubv;
void function(GLuint red, GLuint green, GLuint blue) glSecondaryColor3ui;
void function(GLuint *v) glSecondaryColor3uiv;
void function(GLushort red, GLushort green, GLushort blue) glSecondaryColor3us;
void function(GLushort *v) glSecondaryColor3usv;
void function(GLint size, GLenum type, GLsizei stride, GLvoid *pointer) glSecondaryColorPointer;
void function(GLenum sfactorRGB, GLenum dfactorRGB, GLenum sfactorAlpha, GLenum dfactorAlpha) glBlendFuncSeparate;
void function(GLdouble x, GLdouble y) glWindowPos2d;
void function(GLfloat x, GLfloat y) glWindowPos2f;
void function(GLint x, GLint y) glWindowPos2i;
void function(GLshort x, GLshort y) glWindowPos2s;
void function(GLdouble *p) glWindowPos2dv;
void function(GLfloat *p) glWindowPos2fv;
void function(GLint *p) glWindowPos2iv;
void function(GLshort *p) glWindowPos2sv;
void function(GLdouble x, GLdouble y, GLdouble z) glWindowPos3d;
void function(GLfloat x, GLfloat y, GLfloat z) glWindowPos3f;
void function(GLint x, GLint y, GLint z) glWindowPos3i;
void function(GLshort x, GLshort y, GLshort z) glWindowPos3s;
void function(GLdouble *p) glWindowPos3dv;
void function(GLfloat *p) glWindowPos3fv;
void function(GLint *p) glWindowPos3iv;
void function(GLshort *p) glWindowPos3sv;
