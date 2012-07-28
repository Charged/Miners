// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.core.gl21;

import lib.gl.types;


bool GL_VERSION_2_1;

const GL_CURRENT_RASTER_SECONDARY_COLOR = 0x845F;
const GL_PIXEL_PACK_BUFFER = 0x88EB;
const GL_PIXEL_UNPACK_BUFFER = 0x88EC;
const GL_PIXEL_PACK_BUFFER_BINDING = 0x88ED;
const GL_PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;
const GL_FLOAT_MAT2x3 = 0x8B65;
const GL_FLOAT_MAT2x4 = 0x8B66;
const GL_FLOAT_MAT3x2 = 0x8B67;
const GL_FLOAT_MAT3x4 = 0x8B68;
const GL_FLOAT_MAT4x2 = 0x8B69;
const GL_FLOAT_MAT4x3 = 0x8B6A;
const GL_SRGB = 0x8C40;
const GL_SRGB8 = 0x8C41;
const GL_SRGB_ALPHA = 0x8C42;
const GL_SRGB8_ALPHA8 = 0x8C43;
const GL_SLUMINANCE_ALPHA = 0x8C44;
const GL_SLUMINANCE8_ALPHA8 = 0x8C45;
const GL_SLUMINANCE = 0x8C46;
const GL_SLUMINANCE8 = 0x8C47;
const GL_COMPRESSED_SRGB = 0x8C48;
const GL_COMPRESSED_SRGB_ALPHA = 0x8C49;
const GL_COMPRESSED_SLUMINANCE = 0x8C4A;
const GL_COMPRESSED_SLUMINANCE_ALPHA = 0x8C4B;

extern(System):

void (*glUniformMatrix2x3fv)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
void (*glUniformMatrix3x2fv)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
void (*glUniformMatrix2x4fv)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
void (*glUniformMatrix4x2fv)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
void (*glUniformMatrix3x4fv)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
void (*glUniformMatrix4x3fv)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
