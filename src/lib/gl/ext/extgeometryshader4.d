// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.extgeometryshader4;

import lib.gl.types;


bool GL_EXT_geometry_shader4;

const GL_GEOMETRY_SHADER_EXT = 0x8DD9;
const GL_MAX_GEOMETRY_VARYING_COMPONENTS_EXT = 0x8DDD;
const GL_MAX_VERTEX_VARYING_COMPONENTS_EXT = 0x8DDE;
const GL_MAX_VARYING_COMPONENTS_EXT = 0x8B4B;
const GL_MAX_GEOMETRY_UNIFORM_COMPONENTS_EXT = 0x8DDF;
const GL_MAX_GEOMETRY_OUTPUT_VERTICES_EXT = 0x8DE0;
const GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_EXT = 0x8DE1;
const GL_GEOMETRY_VERTICES_OUT_EXT = 0x8DDA;
const GL_GEOMETRY_INPUT_TYPE_EXT = 0x8DDB;
const GL_GEOMETRY_OUTPUT_TYPE_EXT = 0x8DDC;
const GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_EXT = 0x8C29;
const GL_LINES_ADJACENCY_EXT = 0xA;
const GL_LINE_STRIP_ADJACENCY_EXT = 0xB;
const GL_TRIANGLES_ADJACENCY_EXT = 0xC;
const GL_TRIANGLE_STRIP_ADJACENCY_EXT = 0xD;
const GL_FRAMEBUFFER_ATTACHMENT_LAYERED_EXT = 0x8DA7;
const GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_EXT = 0x8DA8;
const GL_FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_EXT = 0x8DA9;
const GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER_EXT = 0x8CD4;
const GL_PROGRAM_POINT_SIZE_EXT = 0x8642;

extern (System):

void function(GLuint program, GLenum pname, GLint value) glProgramParameteriEXT;
void function(GLenum target, GLenum attachment, GLuint texture, GLint level) glFramebufferTextureEXT;
void function(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer) glFramebufferTextureLayerEXT;
void function(GLenum target, GLenum attachment, GLuint texture, GLint level, GLenum face) glFramebufferTextureFaceEXT;
