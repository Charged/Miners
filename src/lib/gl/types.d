// This file is hand written but based on files from Khorons.
// See the copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.types;

// GL
alias uint      GLenum;
alias ubyte     GLboolean;
alias uint      GLbitfield;
alias void      GLvoid;
alias byte      GLbyte;
alias short     GLshort;
alias int       GLint;
alias ubyte     GLubyte;
alias ushort    GLushort;
alias uint      GLuint;
alias int       GLsizei;
alias float     GLfloat;
alias float     GLclampf;
alias double    GLdouble;
alias double    GLclampd;
alias char      GLchar;
alias ptrdiff_t GLintptr;
alias ptrdiff_t GLsizeiptr;

// GL_ARB_shader_objects
alias void*     GLhandleARB;
alias char      GLcharARB;

// GL_ARB_vertex_buffer_object
alias size_t    GLsizeiptrARB;
alias int*      GLintptrARB;

// GL_NV_half_float
alias ushort    GLhalf;

// GL_EXT_timer_query
alias long      GLint64EXT;
alias ulong     GLuint64EXT;
