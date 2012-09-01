// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.arbsync;

import lib.gl.types;


bool GL_ARB_sync;

const GL_MAX_SERVER_WAIT_TIMEOUT    = 0x9111;
const GL_OBJECT_TYPE                = 0x9112;
const GL_SYNC_CONDITION             = 0x9113;
const GL_SYNC_STATUS                = 0x9114;
const GL_SYNC_FLAGS                 = 0x9115;
const GL_SYNC_FENCE                 = 0x9116;
const GL_SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
const GL_UNSIGNALED                 = 0x9118;
const GL_SIGNALED                   = 0x9119;
const GL_ALREADY_SIGNALED           = 0x911A;
const GL_TIMEOUT_EXPIRED            = 0x911B;
const GL_CONDITION_SATISFIED        = 0x911C;
const GL_WAIT_FAILED                = 0x911D;
const GL_SYNC_FLUSH_COMMANDS_BIT    = 0x00000001;
const GLuint64 GL_TIMEOUT_IGNORED   = 0xFFFFFFFFFFFFFFFF;

extern(System):

GLsync function(GLenum condition, GLbitfield flags) glFenceSync;
GLboolean function(GLsync sync) glIsSync;
void function(GLsync sync) glDeleteSync;
GLenum function(GLsync sync, GLbitfield flags, GLuint64 timeout) glClientWaitSync;
void function(GLsync sync, GLbitfield flags, GLuint64 timeout) glWaitSync;
void function(GLenum pname, GLint64 *params) glGetInteger64v;
void function(GLsync sync, GLenum pname, GLsizei bufSize, GLsizei *length, GLint *values) glGetSynciv;
