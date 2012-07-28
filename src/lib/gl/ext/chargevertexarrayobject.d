// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.chargevertexarrayobject;

/*
 * To work different VAO extensions being available.
 *
 * Mostly this is Apple fault.
 */

import lib.gl.types;

import lib.gl.ext.arbvertexarrayobject;
import lib.gl.ext.applevertexarrayobject;


bool GL_CHARGE_vertex_array_object;

const GL_VERTEX_ARRAY_BINDING_CHARGE = 0x85B5;

extern (System):

void (*glBindVertexArrayCHARGE)(GLuint array);
void (*glDeleteVertexArraysCHARGE)(GLsizei n, GLuint *arrays);
void (*glGenVertexArraysCHARGE)(GLsizei n, GLuint *arrays);
GLboolean (*glIsVertexArrayCHARGE)(GLuint array);
