// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.nvdepthbufferfloat;

import lib.gl.types;


bool GL_NV_depth_buffer_float;

const GL_DEPTH_COMPONENT32F_NV = 0x8DAB;
const GL_DEPTH32F_STENCIL8_NV = 0x8DAC;
const GL_FLOAT_32_UNSIGNED_INT_24_8_REV_NV = 0x8DAD;
const GL_DEPTH_BUFFER_FLOAT_MODE_NV = 0x8DAF;

extern(System):

void function(double n, double f) glDepthRangedNV;
void function(double d) glClearDepthdNV;
void function(double zmin, double zmax) glDepthBoundsdNV;
