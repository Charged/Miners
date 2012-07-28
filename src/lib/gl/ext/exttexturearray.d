// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.ext.exttexturearray;

import lib.gl.types;

import lib.gl.ext.extgeometryshader4;


bool GL_EXT_texture_array;

const GL_TEXTURE_1D_ARRAY_EXT = 0x8C18;
const GL_TEXTURE_2D_ARRAY_EXT = 0x8C1A;
const GL_PROXY_TEXTURE_2D_ARRAY_EXT = 0x8C1B;
const GL_PROXY_TEXTURE_1D_ARRAY_EXT = 0x8C19;
const GL_TEXTURE_BINDING_1D_ARRAY_EXT = 0x8C1C;
const GL_TEXTURE_BINDING_2D_ARRAY_EXT = 0x8C1D;
const GL_MAX_ARRAY_TEXTURE_LAYERS_EXT = 0x88FF;
const GL_COMPARE_REF_DEPTH_TO_TEXTURE_EXT = 0x884E;
const GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER_EXT = 0x8CD4;
const GL_SAMPLER_1D_ARRAY_EXT = 0x8DC0;
const GL_SAMPLER_2D_ARRAY_EXT = 0x8DC1;
const GL_SAMPLER_1D_ARRAY_SHADOW_EXT = 0x8DC3;
const GL_SAMPLER_2D_ARRAY_SHADOW_EXT = 0x8DC4;

extern (System):

// Collides with GL_EXT_geometry_shader4
// void (*glFramebufferTextureLayerEXT)(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
