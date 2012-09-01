// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.core.gl15;

import lib.gl.types;


bool GL_VERSION_1_5;

const GL_BUFFER_SIZE = 0x8764;
const GL_BUFFER_USAGE = 0x8765;
const GL_QUERY_COUNTER_BITS = 0x8864;
const GL_CURRENT_QUERY = 0x8865;
const GL_QUERY_RESULT = 0x8866;
const GL_QUERY_RESULT_AVAILABLE = 0x8867;
const GL_ARRAY_BUFFER = 0x8892;
const GL_ELEMENT_ARRAY_BUFFER = 0x8893;
const GL_ARRAY_BUFFER_BINDING = 0x8894;
const GL_ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;
const GL_VERTEX_ARRAY_BUFFER_BINDING = 0x8896;
const GL_NORMAL_ARRAY_BUFFER_BINDING = 0x8897;
const GL_COLOR_ARRAY_BUFFER_BINDING = 0x8898;
const GL_INDEX_ARRAY_BUFFER_BINDING = 0x8899;
const GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING = 0x889A;
const GL_EDGE_FLAG_ARRAY_BUFFER_BINDING = 0x889B;
const GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING = 0x889C;
const GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING = 0x889D;
const GL_WEIGHT_ARRAY_BUFFER_BINDING = 0x889E;
const GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;
const GL_READ_ONLY = 0x88B8;
const GL_WRITE_ONLY = 0x88B9;
const GL_READ_WRITE = 0x88BA;
const GL_BUFFER_ACCESS = 0x88BB;
const GL_BUFFER_MAPPED = 0x88BC;
const GL_BUFFER_MAP_POINTER = 0x88BD;
const GL_STREAM_DRAW = 0x88E0;
const GL_STREAM_READ = 0x88E1;
const GL_STREAM_COPY = 0x88E2;
const GL_STATIC_DRAW = 0x88E4;
const GL_STATIC_READ = 0x88E5;
const GL_STATIC_COPY = 0x88E6;
const GL_DYNAMIC_DRAW = 0x88E8;
const GL_DYNAMIC_READ = 0x88E9;
const GL_DYNAMIC_COPY = 0x88EA;
const GL_SAMPLES_PASSED = 0x8914;

extern(System):

void function(GLsizei n, GLuint* ids) glGenQueries;
void function(GLsizei n, GLuint* ids) glDeleteQueries;
GLboolean function(GLuint id) glIsQuery;
void function(GLenum target, GLuint id) glBeginQuery;
void function(GLenum target) glEndQuery;
void function(GLenum target, GLenum pname, GLint* params) glGetQueryiv;
void function(GLuint id, GLenum pname, GLint* params) glGetQueryObjectiv;
void function(GLuint id, GLenum pname, GLuint* params) glGetQueryObjectuiv;
void function(GLenum target, GLuint buffer) glBindBuffer;
void function(GLsizei n, GLuint* buffers) glDeleteBuffers;
void function(GLsizei n, GLuint* buffers) glGenBuffers;
GLboolean function(GLuint buffer) glIsBuffer;
void function(GLenum target, GLsizeiptr size, GLvoid* data, GLenum usage) glBufferData;
void function(GLenum target, GLintptr offset, GLsizeiptr size, GLvoid* data) glBufferSubData;
void function(GLenum target, GLintptr offset, GLsizeiptr size, GLvoid* data) glGetBufferSubData;
GLvoid* function(GLenum target, GLenum access) glMapBuffer;
GLboolean function(GLenum target) glUnmapBuffer;
void function(GLenum target, GLenum pname, GLint* params) glGetBufferParameteriv;
void function(GLenum target, GLenum pname, GLvoid** params) glGetBufferPointerv;
