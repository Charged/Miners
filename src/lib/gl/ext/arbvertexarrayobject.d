// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.arbvertexarrayobject;

import lib.loader;
import lib.gl.types;

bool GL_ARB_vertex_array_object;

void loadGL_ARB_vertex_array_object(Loader l) {
	if (!GL_ARB_vertex_array_object)
		return;

	loadFunc!(glBindVertexArray)(l);
	loadFunc!(glDeleteVertexArrays)(l);
	loadFunc!(glGenVertexArrays)(l);
	loadFunc!(glIsVertexArray)(l);
}

const GL_VERTEX_ARRAY_BINDING = 0x85B5;

extern(System):

void (*glBindVertexArray)(GLuint array);
void (*glDeleteVertexArrays)(GLsizei n, GLuint *arrays);
void (*glGenVertexArrays)(GLsizei n, GLuint *arrays);
GLboolean (*glIsVertexArray)(GLuint array);
