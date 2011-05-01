// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.nvdepthbufferfloat;

import lib.loader;
import lib.gl.types;

bool GL_NV_depth_buffer_float;

void loadGL_NV_depth_buffer_float(Loader l) {
	if (!GL_NV_depth_buffer_float)
		return;

	loadFunc!(glDepthRangedNV)(l);
	loadFunc!(glClearDepthdNV)(l);
	loadFunc!(glDepthBoundsdNV)(l);
}

const GL_DEPTH_COMPONENT32F_NV = 0x8DAB;
const GL_DEPTH32F_STENCIL8_NV = 0x8DAC;
const GL_FLOAT_32_UNSIGNED_INT_24_8_REV_NV = 0x8DAD;
const GL_DEPTH_BUFFER_FLOAT_MODE_NV = 0x8DAF;

extern(System):
void (*glDepthRangedNV)(double n, double f);
void (*glClearDepthdNV)(double d);
void (*glDepthBoundsdNV)(double zmin, double zmax);
