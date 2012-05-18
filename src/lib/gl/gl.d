// This file is partially generated from text files from GLEW.
// See copyright at the bottom of this file (BSD/MIT like).
module lib.gl.gl;

import std.conv;
import std.stdio;
import std.string;

import lib.loader;

public:
import lib.gl.types;
import lib.gl.core.gl10;
import lib.gl.core.gl11;
import lib.gl.core.gl12;
import lib.gl.core.gl13;
import lib.gl.core.gl14;
import lib.gl.core.gl15;
import lib.gl.core.gl20;
import lib.gl.core.gl21;
import lib.gl.ext.extframebufferobject;
import lib.gl.ext.nvdepthbufferfloat;
import lib.gl.ext.arbtexturecompression;
import lib.gl.ext.arbvertexbufferobject;
import lib.gl.ext.arbvertexarrayobject;
import lib.gl.ext.applevertexarrayobject;
import lib.gl.ext.chargevertexarrayobject;
import lib.gl.ext.extgeometryshader4;
import lib.gl.ext.exttexturearray;
import lib.gl.ext.exttexturecompressions3tc;
import lib.gl.glu;

struct glVersion {
	static uint major;
	static uint minor;
};

void loadGL(Loader l)
{
	loadFunc!(glGetString)(l);

	if (glGetString is null)
		return;

	findCore();
	loadGL10(l);
	loadGL11(l);
	loadGL12(l);
	loadGL13(l);
	loadGL15(l);
	loadGL20(l);
	loadGL21(l);

	findExtentions();
	loadGL_EXT_framebuffer_object(l);
	loadGL_NV_depth_buffer_float(l);
	loadGL_ARB_texture_compression(l);
	loadGL_ARB_vertex_buffer_object(l);
	loadGL_ARB_vertex_array_object(l);
	loadGL_APPLE_vertex_array_object(l);
	loadGL_EXT_geometry_shader4(l);
	loadGL_EXT_texture_array(l);

	loadGL_CHARGE_vertex_array_object();
}

private:

struct testFunc(alias T)
{
	static void opCall(char[] string) {
		try {
			T = find(string, T.stringof) >= 0;
		} catch (Exception e) {}
	}
}

void findCore()
{
	glVersion.major = 0;
	glVersion.minor = 0;

	auto ver = toString(glGetString(GL_VERSION)); 
	glVersion.major = toUint(ver[0 .. 1]);
	glVersion.minor = toUint(ver[2 .. 3]);

	GL_VERSION_1_0 = glVersion.major == 1 && glVersion.minor >= 0 || glVersion.major > 1;
	GL_VERSION_1_1 = glVersion.major == 1 && glVersion.minor >= 1 || glVersion.major > 1;
	GL_VERSION_1_2 = glVersion.major == 1 && glVersion.minor >= 2 || glVersion.major > 1;
	GL_VERSION_1_3 = glVersion.major == 1 && glVersion.minor >= 3 || glVersion.major > 1;
	GL_VERSION_1_5 = glVersion.major == 1 && glVersion.minor >= 5 || glVersion.major > 1;
	GL_VERSION_2_0 = glVersion.major == 2 && glVersion.minor >= 0 || glVersion.major > 2;
	GL_VERSION_2_1 = glVersion.major == 2 && glVersion.minor >= 1 || glVersion.major > 2;
}

void findExtentions()
{
	char[] e = toString(glGetString(GL_EXTENSIONS));

	testFunc!(GL_EXT_framebuffer_object)(e);
	testFunc!(GL_ARB_texture_compression)(e);
	testFunc!(GL_NV_depth_buffer_float)(e);
	testFunc!(GL_ARB_vertex_buffer_object)(e);
	testFunc!(GL_ARB_vertex_array_object)(e);
	testFunc!(GL_APPLE_vertex_array_object)(e);
	testFunc!(GL_EXT_geometry_shader4)(e);
	testFunc!(GL_EXT_texture_array)(e);
	testFunc!(GL_EXT_texture_compression_s3tc)(e);
}


char[] licenseText = `
The OpenGL Extension Wrangler Library
Copyright (C) 2002-2008, Milan Ikits <milan ikits@ieee org>
Copyright (C) 2002-2008, Marcelo E. Magallon <mmagallo@debian org>
Copyright (C) 2002, Lev Povalahev
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* The name of the author may be used to endorse or promote products
  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.


Mesa 3-D graphics library
Version:  7.0

Copyright (C) 1999-2007  Brian Paul   All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
BRIAN PAUL BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Copyright (c) 2007 The Khronos Group Inc.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and/or associated documentation files (the
"Materials"), to deal in the Materials without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Materials, and to
permit persons to whom the Materials are furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Materials.

THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
`;

import license;

static this()
{
	licenseArray ~= licenseText;
}
