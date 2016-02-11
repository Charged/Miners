// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.arbvertexbufferobject;

import lib.gl.types;


bool GL_ARB_vertex_buffer_object;

const GL_ARRAY_BUFFER_ARB = 0x8892;
const GL_ELEMENT_ARRAY_BUFFER_ARB = 0x8893;
const GL_ARRAY_BUFFER_BINDING_ARB = 0x8894;
const GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB = 0x8895;
const GL_VERTEX_ARRAY_BUFFER_BINDING_ARB = 0x8896;
const GL_NORMAL_ARRAY_BUFFER_BINDING_ARB = 0x8897;
const GL_COLOR_ARRAY_BUFFER_BINDING_ARB = 0x8898;
const GL_INDEX_ARRAY_BUFFER_BINDING_ARB = 0x8899;
const GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB = 0x889A;
const GL_EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB = 0x889B;
const GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB = 0x889C;
const GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB = 0x889D;
const GL_WEIGHT_ARRAY_BUFFER_BINDING_ARB = 0x889E;
const GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB = 0x889F;
const GL_STREAM_DRAW_ARB = 0x88E0;
const GL_STREAM_READ_ARB = 0x88E1;
const GL_STREAM_COPY_ARB = 0x88E2;
const GL_STATIC_DRAW_ARB = 0x88E4;
const GL_STATIC_READ_ARB = 0x88E5;
const GL_STATIC_COPY_ARB = 0x88E6;
const GL_DYNAMIC_DRAW_ARB = 0x88E8;
const GL_DYNAMIC_READ_ARB = 0x88E9;
const GL_DYNAMIC_COPY_ARB = 0x88EA;
const GL_READ_ONLY_ARB = 0x88B8;
const GL_WRITE_ONLY_ARB = 0x88B9;
const GL_READ_WRITE_ARB = 0x88BA;
const GL_BUFFER_SIZE_ARB = 0x8764;
const GL_BUFFER_USAGE_ARB = 0x8765;
const GL_BUFFER_ACCESS_ARB = 0x88BB;
const GL_BUFFER_MAPPED_ARB = 0x88BC;
const GL_BUFFER_MAP_POINTER_ARB = 0x88BD;

extern(System):

void function(GLenum target, GLuint buffer) glBindBufferARB;
void function(GLsizei n, GLuint *buffers) glDeleteBuffersARB;
void function(GLsizei n, GLuint *buffers) glGenBuffersARB;
GLboolean function(GLuint buffer) glIsBufferARB;
void function(GLenum target, GLsizeiptrARB size, const(void)* data, GLenum usage) glBufferDataARB;
void function(GLenum target, GLintptrARB offset, GLsizeiptrARB size, const(void)* data) glBufferSubDataARB;
void function(GLenum target, GLintptrARB offset, GLsizeiptrARB size, const(void)* data) glGetBufferSubDataARB;
void *function(GLenum target, GLenum access) glMapBufferARB;
GLboolean function(GLenum target) glUnmapBufferARB;
void function(GLenum target, GLenum pname, GLint *params) glGetBufferParameterivARB;
void function(GLenum target, GLenum pname, void **params) glGetBufferPointervARB;
