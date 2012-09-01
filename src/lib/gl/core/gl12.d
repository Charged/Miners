// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.core.gl12;

import lib.gl.types;


bool GL_VERSION_1_2;

const GL_UNSIGNED_BYTE_3_3_2 = 0x8032;
const GL_UNSIGNED_SHORT_4_4_4_4 = 0x8033;
const GL_UNSIGNED_SHORT_5_5_5_1 = 0x8034;
const GL_UNSIGNED_INT_8_8_8_8 = 0x8035;
const GL_UNSIGNED_INT_10_10_10_2 = 0x8036;
const GL_RESCALE_NORMAL = 0x803A;
const GL_UNSIGNED_BYTE_2_3_3_REV = 0x8362;
const GL_UNSIGNED_SHORT_5_6_5 = 0x8363;
const GL_UNSIGNED_SHORT_5_6_5_REV = 0x8364;
const GL_UNSIGNED_SHORT_4_4_4_4_REV = 0x8365;
const GL_UNSIGNED_SHORT_1_5_5_5_REV = 0x8366;
const GL_UNSIGNED_INT_8_8_8_8_REV = 0x8367;
const GL_UNSIGNED_INT_2_10_10_10_REV = 0x8368;
const GL_BGR = 0x80E0;
const GL_BGRA = 0x80E1;
const GL_MAX_ELEMENTS_VERTICES = 0x80E8;
const GL_MAX_ELEMENTS_INDICES = 0x80E9;
const GL_CLAMP_TO_EDGE = 0x812F;
const GL_TEXTURE_MIN_LOD = 0x813A;
const GL_TEXTURE_MAX_LOD = 0x813B;
const GL_TEXTURE_BASE_LEVEL = 0x813C;
const GL_TEXTURE_MAX_LEVEL = 0x813D;
const GL_LIGHT_MODEL_COLOR_CONTROL = 0x81F8;
const GL_SINGLE_COLOR = 0x81F9;
const GL_SEPARATE_SPECULAR_COLOR = 0x81FA;
const GL_SMOOTH_POINT_SIZE_RANGE = 0x0B12;
const GL_SMOOTH_POINT_SIZE_GRANULARITY = 0x0B13;
const GL_SMOOTH_LINE_WIDTH_RANGE = 0x0B22;
const GL_SMOOTH_LINE_WIDTH_GRANULARITY = 0x0B23;
const GL_ALIASED_POINT_SIZE_RANGE = 0x846D;
const GL_ALIASED_LINE_WIDTH_RANGE = 0x846E;
const GL_PACK_SKIP_IMAGES = 0x806B;
const GL_PACK_IMAGE_HEIGHT = 0x806C;
const GL_UNPACK_SKIP_IMAGES = 0x806D;
const GL_UNPACK_IMAGE_HEIGHT = 0x806E;
const GL_TEXTURE_3D = 0x806F;
const GL_PROXY_TEXTURE_3D = 0x8070;
const GL_TEXTURE_DEPTH = 0x8071;
const GL_TEXTURE_WRAP_R = 0x8072;
const GL_MAX_3D_TEXTURE_SIZE = 0x8073;
const GL_TEXTURE_BINDING_3D = 0x806A;

extern(System):

void function(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, GLvoid *indices) glDrawRangeElements;
void function(GLenum target, GLint level, GLint initernalFormat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, GLvoid *pixels) glTexImage3D;
void function(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, GLvoid *pixels) glTexSubImage3D;
void function(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height) glCopyTexSubImage3D;
