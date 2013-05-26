// This file is generated from text files from GLEW.
// See copyright in src/lib/gl/gl.d (BSD/MIT like).
module lib.gl.loader;

import stdx.conv : toUint;
import stdx.string : find, toString;

import lib.loader;
import lib.gl.gl;
import lib.gl.glu;


struct glVersion
{
	static uint major;
	static uint minor;
}

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
	loadGL14(l);
	loadGL15(l);
	loadGL20(l);
	loadGL21(l);

	findExtentions();
	loadGL_EXT_framebuffer_object(l);
	loadGL_NV_depth_buffer_float(l);
	loadGL_ARB_sync(l);
	loadGL_ARB_texture_compression(l);
	loadGL_ARB_vertex_buffer_object(l);
	loadGL_ARB_vertex_array_object(l);
	loadGL_APPLE_vertex_array_object(l);
	loadGL_EXT_geometry_shader4(l);
	loadGL_EXT_texture_array(l);

	loadGL_CHARGE_vertex_array_object();
}

void loadGLU(Loader l)
{
//	loadFunc!(gluBuild1DMipmapLevels)(l);
	loadFunc!(gluBuild1DMipmaps)(l);
//	loadFunc!(gluBuild2DMipmapLevels)(l);
	loadFunc!(gluBuild2DMipmaps)(l);
//	loadFunc!(gluBuild3DMipmapLevels)(l);
//	loadFunc!(gluBuild3DMipmaps)(l);
//	loadFunc!(gluCheckExtension)(l);
	loadFunc!(gluErrorString)(l);
	loadFunc!(gluGetString)(l);
	loadFunc!(gluCylinder)(l);
	loadFunc!(gluDisk)(l);
	loadFunc!(gluPartialDisk)(l);
	loadFunc!(gluSphere)(l);
	loadFunc!(gluBeginCurve)(l);
	loadFunc!(gluBeginPolygon)(l);
	loadFunc!(gluBeginSurface)(l);
	loadFunc!(gluBeginTrim)(l);
	loadFunc!(gluEndCurve)(l);
	loadFunc!(gluEndPolygon)(l);
	loadFunc!(gluEndSurface)(l);
	loadFunc!(gluEndTrim)(l);
	loadFunc!(gluDeleteNurbsRenderer)(l);
	loadFunc!(gluDeleteQuadric)(l);
	loadFunc!(gluDeleteTess)(l);
	loadFunc!(gluGetNurbsProperty)(l);
	loadFunc!(gluGetTessProperty)(l);
	loadFunc!(gluLoadSamplingMatrices)(l);
	loadFunc!(gluNewNurbsRenderer)(l);
	loadFunc!(gluNewQuadric)(l);
	loadFunc!(gluNewTess)(l);
	loadFunc!(gluNextContour)(l);
	loadFunc!(gluNurbsCallback)(l);
//	loadFunc!(gluNurbsCallbackData)(l);
//	loadFunc!(gluNurbsCallbackDataEXT)(l);
	loadFunc!(gluNurbsCurve)(l);
	loadFunc!(gluNurbsProperty)(l);
	loadFunc!(gluNurbsSurface)(l);
	loadFunc!(gluPwlCurve)(l);
	loadFunc!(gluQuadricCallback)(l);
	loadFunc!(gluQuadricDrawStyle)(l);
	loadFunc!(gluQuadricNormals)(l);
	loadFunc!(gluQuadricOrientation)(l);
	loadFunc!(gluQuadricTexture)(l);
	loadFunc!(gluTessBeginContour)(l);
	loadFunc!(gluTessBeginPolygon)(l);
	loadFunc!(gluTessCallback)(l);
	loadFunc!(gluTessEndContour)(l);
	loadFunc!(gluTessEndPolygon)(l);
	loadFunc!(gluTessNormal)(l);
	loadFunc!(gluTessProperty)(l);
	loadFunc!(gluTessVertex)(l);
	loadFunc!(gluLookAt)(l);
	loadFunc!(gluOrtho2D)(l);
	loadFunc!(gluPerspective)(l);
	loadFunc!(gluPickMatrix)(l);
	loadFunc!(gluProject)(l);
	loadFunc!(gluScaleImage)(l);
	loadFunc!(gluUnProject)(l);
//	loadFunc!(gluUnProject4)(l);
}

private:

struct testFunc(alias T)
{
	static void opCall(string str) {
		try {
			T = find(str, T.stringof) >= 0;
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
	GL_VERSION_1_4 = glVersion.major == 1 && glVersion.minor >= 4 || glVersion.major > 1;
	GL_VERSION_1_5 = glVersion.major == 1 && glVersion.minor >= 5 || glVersion.major > 1;
	GL_VERSION_2_0 = glVersion.major == 2 && glVersion.minor >= 0 || glVersion.major > 2;
	GL_VERSION_2_1 = glVersion.major == 2 && glVersion.minor >= 1 || glVersion.major > 2;
}

void findExtentions()
{
	string e = toString(glGetString(GL_EXTENSIONS));

	testFunc!(GL_EXT_framebuffer_object)(e);
	testFunc!(GL_ARB_texture_compression)(e);
	testFunc!(GL_ARB_sync)(e);
	testFunc!(GL_NV_depth_buffer_float)(e);
	testFunc!(GL_ARB_vertex_buffer_object)(e);
	testFunc!(GL_ARB_vertex_array_object)(e);
	testFunc!(GL_APPLE_vertex_array_object)(e);
	testFunc!(GL_EXT_geometry_shader4)(e);
	testFunc!(GL_EXT_texture_array)(e);
	testFunc!(GL_EXT_texture_compression_s3tc)(e);
}

void loadGL10(Loader l)
{
	loadFunc!(glClearIndex)(l);
	loadFunc!(glClearColor)(l);
	loadFunc!(glClear)(l);
	loadFunc!(glIndexMask)(l);
	loadFunc!(glColorMask)(l);
	loadFunc!(glAlphaFunc)(l);
	loadFunc!(glBlendFunc)(l);
	loadFunc!(glLogicOp)(l);
	loadFunc!(glCullFace)(l);
	loadFunc!(glFrontFace)(l);
	loadFunc!(glPointSize)(l);
	loadFunc!(glLineWidth)(l);
	loadFunc!(glLineStipple)(l);
	loadFunc!(glPolygonMode)(l);
	loadFunc!(glPolygonOffset)(l);
	loadFunc!(glPolygonStipple)(l);
	loadFunc!(glGetPolygonStipple)(l);
	loadFunc!(glEdgeFlag)(l);
	loadFunc!(glEdgeFlagv)(l);
	loadFunc!(glScissor)(l);
	loadFunc!(glClipPlane)(l);
	loadFunc!(glGetClipPlane)(l);
	loadFunc!(glDrawBuffer)(l);
	loadFunc!(glReadBuffer)(l);
	loadFunc!(glEnable)(l);
	loadFunc!(glDisable)(l);
	loadFunc!(glIsEnabled)(l);
	loadFunc!(glEnableClientState)(l);
	loadFunc!(glDisableClientState)(l);
	loadFunc!(glGetBooleanv)(l);
	loadFunc!(glGetDoublev)(l);
	loadFunc!(glGetFloatv)(l);
	loadFunc!(glGetIntegerv)(l);
	loadFunc!(glPushAttrib)(l);
	loadFunc!(glPopAttrib)(l);
	loadFunc!(glPushClientAttrib)(l);
	loadFunc!(glPopClientAttrib)(l);
	loadFunc!(glRenderMode)(l);
	loadFunc!(glGetError)(l);
	loadFunc!(glGetString)(l);
	loadFunc!(glFinish)(l);
	loadFunc!(glFlush)(l);
	loadFunc!(glHint)(l);
	loadFunc!(glClearDepth)(l);
	loadFunc!(glDepthFunc)(l);
	loadFunc!(glDepthMask)(l);
	loadFunc!(glDepthRange)(l);
	loadFunc!(glClearAccum)(l);
	loadFunc!(glAccum)(l);
	loadFunc!(glMatrixMode)(l);
	loadFunc!(glOrtho)(l);
	loadFunc!(glFrustum)(l);
	loadFunc!(glViewport)(l);
	loadFunc!(glPushMatrix)(l);
	loadFunc!(glPopMatrix)(l);
	loadFunc!(glLoadIdentity)(l);
	loadFunc!(glLoadMatrixd)(l);
	loadFunc!(glLoadMatrixf)(l);
	loadFunc!(glMultMatrixd)(l);
	loadFunc!(glMultMatrixf)(l);
	loadFunc!(glRotated)(l);
	loadFunc!(glRotatef)(l);
	loadFunc!(glScaled)(l);
	loadFunc!(glScalef)(l);
	loadFunc!(glTranslated)(l);
	loadFunc!(glTranslatef)(l);
	loadFunc!(glIsList)(l);
	loadFunc!(glDeleteLists)(l);
	loadFunc!(glGenLists)(l);
	loadFunc!(glNewList)(l);
	loadFunc!(glEndList)(l);
	loadFunc!(glCallList)(l);
	loadFunc!(glCallLists)(l);
	loadFunc!(glListBase)(l);
	loadFunc!(glBegin)(l);
	loadFunc!(glEnd)(l);
	loadFunc!(glVertex2d)(l);
	loadFunc!(glVertex2f)(l);
	loadFunc!(glVertex2i)(l);
	loadFunc!(glVertex2s)(l);
	loadFunc!(glVertex3d)(l);
	loadFunc!(glVertex3f)(l);
	loadFunc!(glVertex3i)(l);
	loadFunc!(glVertex3s)(l);
	loadFunc!(glVertex4d)(l);
	loadFunc!(glVertex4f)(l);
	loadFunc!(glVertex4i)(l);
	loadFunc!(glVertex4s)(l);
	loadFunc!(glVertex2dv)(l);
	loadFunc!(glVertex2fv)(l);
	loadFunc!(glVertex2iv)(l);
	loadFunc!(glVertex2sv)(l);
	loadFunc!(glVertex3dv)(l);
	loadFunc!(glVertex3fv)(l);
	loadFunc!(glVertex3iv)(l);
	loadFunc!(glVertex3sv)(l);
	loadFunc!(glVertex4dv)(l);
	loadFunc!(glVertex4fv)(l);
	loadFunc!(glVertex4iv)(l);
	loadFunc!(glVertex4sv)(l);
	loadFunc!(glNormal3b)(l);
	loadFunc!(glNormal3d)(l);
	loadFunc!(glNormal3f)(l);
	loadFunc!(glNormal3i)(l);
	loadFunc!(glNormal3s)(l);
	loadFunc!(glNormal3bv)(l);
	loadFunc!(glNormal3dv)(l);
	loadFunc!(glNormal3fv)(l);
	loadFunc!(glNormal3iv)(l);
	loadFunc!(glNormal3sv)(l);
	loadFunc!(glIndexd)(l);
	loadFunc!(glIndexf)(l);
	loadFunc!(glIndexi)(l);
	loadFunc!(glIndexs)(l);
	loadFunc!(glIndexub)(l);
	loadFunc!(glIndexdv)(l);
	loadFunc!(glIndexfv)(l);
	loadFunc!(glIndexiv)(l);
	loadFunc!(glIndexsv)(l);
	loadFunc!(glIndexubv)(l);
	loadFunc!(glColor3b)(l);
	loadFunc!(glColor3d)(l);
	loadFunc!(glColor3f)(l);
	loadFunc!(glColor3i)(l);
	loadFunc!(glColor3s)(l);
	loadFunc!(glColor3ub)(l);
	loadFunc!(glColor3ui)(l);
	loadFunc!(glColor3us)(l);
	loadFunc!(glColor4b)(l);
	loadFunc!(glColor4d)(l);
	loadFunc!(glColor4f)(l);
	loadFunc!(glColor4i)(l);
	loadFunc!(glColor4s)(l);
	loadFunc!(glColor4ub)(l);
	loadFunc!(glColor4ui)(l);
	loadFunc!(glColor4us)(l);
	loadFunc!(glColor3bv)(l);
	loadFunc!(glColor3dv)(l);
	loadFunc!(glColor3fv)(l);
	loadFunc!(glColor3iv)(l);
	loadFunc!(glColor3sv)(l);
	loadFunc!(glColor3ubv)(l);
	loadFunc!(glColor3uiv)(l);
	loadFunc!(glColor3usv)(l);
	loadFunc!(glColor4bv)(l);
	loadFunc!(glColor4dv)(l);
	loadFunc!(glColor4fv)(l);
	loadFunc!(glColor4iv)(l);
	loadFunc!(glColor4sv)(l);
	loadFunc!(glColor4ubv)(l);
	loadFunc!(glColor4uiv)(l);
	loadFunc!(glColor4usv)(l);
	loadFunc!(glTexCoord1d)(l);
	loadFunc!(glTexCoord1f)(l);
	loadFunc!(glTexCoord1i)(l);
	loadFunc!(glTexCoord1s)(l);
	loadFunc!(glTexCoord2d)(l);
	loadFunc!(glTexCoord2f)(l);
	loadFunc!(glTexCoord2i)(l);
	loadFunc!(glTexCoord2s)(l);
	loadFunc!(glTexCoord3d)(l);
	loadFunc!(glTexCoord3f)(l);
	loadFunc!(glTexCoord3i)(l);
	loadFunc!(glTexCoord3s)(l);
	loadFunc!(glTexCoord4d)(l);
	loadFunc!(glTexCoord4f)(l);
	loadFunc!(glTexCoord4i)(l);
	loadFunc!(glTexCoord4s)(l);
	loadFunc!(glTexCoord1dv)(l);
	loadFunc!(glTexCoord1fv)(l);
	loadFunc!(glTexCoord1iv)(l);
	loadFunc!(glTexCoord1sv)(l);
	loadFunc!(glTexCoord2dv)(l);
	loadFunc!(glTexCoord2fv)(l);
	loadFunc!(glTexCoord2iv)(l);
	loadFunc!(glTexCoord2sv)(l);
	loadFunc!(glTexCoord3dv)(l);
	loadFunc!(glTexCoord3fv)(l);
	loadFunc!(glTexCoord3iv)(l);
	loadFunc!(glTexCoord3sv)(l);
	loadFunc!(glTexCoord4dv)(l);
	loadFunc!(glTexCoord4fv)(l);
	loadFunc!(glTexCoord4iv)(l);
	loadFunc!(glTexCoord4sv)(l);
	loadFunc!(glRasterPos2d)(l);
	loadFunc!(glRasterPos2f)(l);
	loadFunc!(glRasterPos2i)(l);
	loadFunc!(glRasterPos2s)(l);
	loadFunc!(glRasterPos3d)(l);
	loadFunc!(glRasterPos3f)(l);
	loadFunc!(glRasterPos3i)(l);
	loadFunc!(glRasterPos3s)(l);
	loadFunc!(glRasterPos4d)(l);
	loadFunc!(glRasterPos4f)(l);
	loadFunc!(glRasterPos4i)(l);
	loadFunc!(glRasterPos4s)(l);
	loadFunc!(glRasterPos2dv)(l);
	loadFunc!(glRasterPos2fv)(l);
	loadFunc!(glRasterPos2iv)(l);
	loadFunc!(glRasterPos2sv)(l);
	loadFunc!(glRasterPos3dv)(l);
	loadFunc!(glRasterPos3fv)(l);
	loadFunc!(glRasterPos3iv)(l);
	loadFunc!(glRasterPos3sv)(l);
	loadFunc!(glRasterPos4dv)(l);
	loadFunc!(glRasterPos4fv)(l);
	loadFunc!(glRasterPos4iv)(l);
	loadFunc!(glRasterPos4sv)(l);
	loadFunc!(glRectd)(l);
	loadFunc!(glRectf)(l);
	loadFunc!(glRecti)(l);
	loadFunc!(glRects)(l);
	loadFunc!(glRectdv)(l);
	loadFunc!(glRectfv)(l);
	loadFunc!(glRectiv)(l);
	loadFunc!(glRectsv)(l);
	loadFunc!(glShadeModel)(l);
	loadFunc!(glLightf)(l);
	loadFunc!(glLighti)(l);
	loadFunc!(glLightfv)(l);
	loadFunc!(glLightiv)(l);
	loadFunc!(glGetLightfv)(l);
	loadFunc!(glGetLightiv)(l);
	loadFunc!(glLightModelf)(l);
	loadFunc!(glLightModeli)(l);
	loadFunc!(glLightModelfv)(l);
	loadFunc!(glLightModeliv)(l);
	loadFunc!(glMaterialf)(l);
	loadFunc!(glMateriali)(l);
	loadFunc!(glMaterialfv)(l);
	loadFunc!(glMaterialiv)(l);
	loadFunc!(glGetMaterialfv)(l);
	loadFunc!(glGetMaterialiv)(l);
	loadFunc!(glColorMaterial)(l);
	loadFunc!(glPixelZoom)(l);
	loadFunc!(glPixelStoref)(l);
	loadFunc!(glPixelStorei)(l);
	loadFunc!(glPixelTransferf)(l);
	loadFunc!(glPixelTransferi)(l);
	loadFunc!(glPixelMapfv)(l);
	loadFunc!(glPixelMapuiv)(l);
	loadFunc!(glPixelMapusv)(l);
	loadFunc!(glGetPixelMapfv)(l);
	loadFunc!(glGetPixelMapuiv)(l);
	loadFunc!(glGetPixelMapusv)(l);
	loadFunc!(glBitmap)(l);
	loadFunc!(glReadPixels)(l);
	loadFunc!(glDrawPixels)(l);
	loadFunc!(glCopyPixels)(l);
	loadFunc!(glStencilFunc)(l);
	loadFunc!(glStencilMask)(l);
	loadFunc!(glStencilOp)(l);
	loadFunc!(glClearStencil)(l);
	loadFunc!(glTexGend)(l);
	loadFunc!(glTexGenf)(l);
	loadFunc!(glTexGeni)(l);
	loadFunc!(glTexGendv)(l);
	loadFunc!(glTexGenfv)(l);
	loadFunc!(glTexGeniv)(l);
	loadFunc!(glTexEnvf)(l);
	loadFunc!(glTexEnvi)(l);
	loadFunc!(glTexEnvfv)(l);
	loadFunc!(glTexEnviv)(l);
	loadFunc!(glGetTexEnvfv)(l);
	loadFunc!(glGetTexEnviv)(l);
	loadFunc!(glTexParameterf)(l);
	loadFunc!(glTexParameteri)(l);
	loadFunc!(glTexParameterfv)(l);
	loadFunc!(glTexParameteriv)(l);
	loadFunc!(glGetTexParameterfv)(l);
	loadFunc!(glGetTexParameteriv)(l);
	loadFunc!(glGetTexLevelParameterfv)(l);
	loadFunc!(glGetTexLevelParameteriv)(l);
	loadFunc!(glTexImage1D)(l);
	loadFunc!(glTexImage2D)(l);
	loadFunc!(glGetTexImage)(l);
	loadFunc!(glMap1d)(l);
	loadFunc!(glMap1f)(l);
	loadFunc!(glMap2d)(l);
	loadFunc!(glMap2f)(l);
	loadFunc!(glGetMapdv)(l);
	loadFunc!(glGetMapfv)(l);
	loadFunc!(glEvalCoord1d)(l);
	loadFunc!(glEvalCoord1f)(l);
	loadFunc!(glEvalCoord1dv)(l);
	loadFunc!(glEvalCoord1fv)(l);
	loadFunc!(glEvalCoord2d)(l);
	loadFunc!(glEvalCoord2f)(l);
	loadFunc!(glEvalCoord2dv)(l);
	loadFunc!(glEvalCoord2fv)(l);
	loadFunc!(glMapGrid1d)(l);
	loadFunc!(glMapGrid1f)(l);
	loadFunc!(glMapGrid2d)(l);
	loadFunc!(glMapGrid2f)(l);
	loadFunc!(glEvalPoint1)(l);
	loadFunc!(glEvalPoint2)(l);
	loadFunc!(glEvalMesh1)(l);
	loadFunc!(glEvalMesh2)(l);
	loadFunc!(glFogf)(l);
	loadFunc!(glFogi)(l);
	loadFunc!(glFogfv)(l);
	loadFunc!(glFogiv)(l);
	loadFunc!(glFeedbackBuffer)(l);
	loadFunc!(glPassThrough)(l);
	loadFunc!(glSelectBuffer)(l);
	loadFunc!(glInitNames)(l);
	loadFunc!(glLoadName)(l);
	loadFunc!(glPushName)(l);
	loadFunc!(glPopName)(l);
}

void loadGL11(Loader l)
{
	loadFunc!(glGenTextures)(l);
	loadFunc!(glDeleteTextures)(l);
	loadFunc!(glBindTexture)(l);
	loadFunc!(glPrioritizeTextures)(l);
	loadFunc!(glAreTexturesResident)(l);
	loadFunc!(glIsTexture)(l);
	loadFunc!(glTexSubImage1D)(l);
	loadFunc!(glTexSubImage2D)(l);
	loadFunc!(glCopyTexImage1D)(l);
	loadFunc!(glCopyTexImage2D)(l);
	loadFunc!(glCopyTexSubImage1D)(l);
	loadFunc!(glCopyTexSubImage2D)(l);
	loadFunc!(glVertexPointer)(l);
	loadFunc!(glNormalPointer)(l);
	loadFunc!(glColorPointer)(l);
	loadFunc!(glIndexPointer)(l);
	loadFunc!(glTexCoordPointer)(l);
	loadFunc!(glEdgeFlagPointer)(l);
	loadFunc!(glGetPointerv)(l);
	loadFunc!(glArrayElement)(l);
	loadFunc!(glDrawArrays)(l);
	loadFunc!(glDrawElements)(l);
	loadFunc!(glInterleavedArrays)(l);
}

void loadGL12(Loader l)
{
	if (!GL_VERSION_1_2)
		return;

	loadFunc!(glDrawRangeElements)(l);
	loadFunc!(glTexImage3D)(l);
	loadFunc!(glTexSubImage3D)(l);
	loadFunc!(glCopyTexSubImage3D)(l);
}

void loadGL13(Loader l)
{
	if (!GL_VERSION_1_3)
		return;

	loadFunc!(glActiveTexture)(l);
	loadFunc!(glClientActiveTexture)(l);
	loadFunc!(glCompressedTexImage1D)(l);
	loadFunc!(glCompressedTexImage2D)(l);
	loadFunc!(glCompressedTexImage3D)(l);
	loadFunc!(glCompressedTexSubImage1D)(l);
	loadFunc!(glCompressedTexSubImage2D)(l);
	loadFunc!(glCompressedTexSubImage3D)(l);
	loadFunc!(glGetCompressedTexImage)(l);
	loadFunc!(glLoadTransposeMatrixd)(l);
	loadFunc!(glLoadTransposeMatrixf)(l);
	loadFunc!(glMultTransposeMatrixd)(l);
	loadFunc!(glMultTransposeMatrixf)(l);
	loadFunc!(glMultiTexCoord1d)(l);
	loadFunc!(glMultiTexCoord1dv)(l);
	loadFunc!(glMultiTexCoord1f)(l);
	loadFunc!(glMultiTexCoord1fv)(l);
	loadFunc!(glMultiTexCoord1i)(l);
	loadFunc!(glMultiTexCoord1iv)(l);
	loadFunc!(glMultiTexCoord1s)(l);
	loadFunc!(glMultiTexCoord1sv)(l);
	loadFunc!(glMultiTexCoord2d)(l);
	loadFunc!(glMultiTexCoord2dv)(l);
	loadFunc!(glMultiTexCoord2f)(l);
	loadFunc!(glMultiTexCoord2fv)(l);
	loadFunc!(glMultiTexCoord2i)(l);
	loadFunc!(glMultiTexCoord2iv)(l);
	loadFunc!(glMultiTexCoord2s)(l);
	loadFunc!(glMultiTexCoord2sv)(l);
	loadFunc!(glMultiTexCoord3d)(l);
	loadFunc!(glMultiTexCoord3dv)(l);
	loadFunc!(glMultiTexCoord3f)(l);
	loadFunc!(glMultiTexCoord3fv)(l);
	loadFunc!(glMultiTexCoord3i)(l);
	loadFunc!(glMultiTexCoord3iv)(l);
	loadFunc!(glMultiTexCoord3s)(l);
	loadFunc!(glMultiTexCoord3sv)(l);
	loadFunc!(glMultiTexCoord4d)(l);
	loadFunc!(glMultiTexCoord4dv)(l);
	loadFunc!(glMultiTexCoord4f)(l);
	loadFunc!(glMultiTexCoord4fv)(l);
	loadFunc!(glMultiTexCoord4i)(l);
	loadFunc!(glMultiTexCoord4iv)(l);
	loadFunc!(glMultiTexCoord4s)(l);
	loadFunc!(glMultiTexCoord4sv)(l);
	loadFunc!(glSampleCoverage)(l);
}

void loadGL14(Loader l)
{
	if (!GL_VERSION_1_4)
		return;

	loadFunc!(glBlendEquation)(l);
	loadFunc!(glBlendColor)(l);
	loadFunc!(glFogCoordf)(l);
	loadFunc!(glFogCoordfv)(l);
	loadFunc!(glFogCoordd)(l);
	loadFunc!(glFogCoorddv)(l);
	loadFunc!(glFogCoordPointer)(l);
	loadFunc!(glMultiDrawArrays)(l);
	loadFunc!(glMultiDrawElements)(l);
	loadFunc!(glPointParameteri)(l);
	loadFunc!(glPointParameteriv)(l);
	loadFunc!(glPointParameterf)(l);
	loadFunc!(glPointParameterfv)(l);
	loadFunc!(glSecondaryColor3b)(l);
	loadFunc!(glSecondaryColor3bv)(l);
	loadFunc!(glSecondaryColor3d)(l);
	loadFunc!(glSecondaryColor3dv)(l);
	loadFunc!(glSecondaryColor3f)(l);
	loadFunc!(glSecondaryColor3fv)(l);
	loadFunc!(glSecondaryColor3i)(l);
	loadFunc!(glSecondaryColor3iv)(l);
	loadFunc!(glSecondaryColor3s)(l);
	loadFunc!(glSecondaryColor3sv)(l);
	loadFunc!(glSecondaryColor3ub)(l);
	loadFunc!(glSecondaryColor3ubv)(l);
	loadFunc!(glSecondaryColor3ui)(l);
	loadFunc!(glSecondaryColor3uiv)(l);
	loadFunc!(glSecondaryColor3us)(l);
	loadFunc!(glSecondaryColor3usv)(l);
	loadFunc!(glSecondaryColorPointer)(l);
	loadFunc!(glBlendFuncSeparate)(l);
	loadFunc!(glWindowPos2d)(l);
	loadFunc!(glWindowPos2f)(l);
	loadFunc!(glWindowPos2i)(l);
	loadFunc!(glWindowPos2s)(l);
	loadFunc!(glWindowPos2dv)(l);
	loadFunc!(glWindowPos2fv)(l);
	loadFunc!(glWindowPos2iv)(l);
	loadFunc!(glWindowPos2sv)(l);
	loadFunc!(glWindowPos3d)(l);
	loadFunc!(glWindowPos3f)(l);
	loadFunc!(glWindowPos3i)(l);
	loadFunc!(glWindowPos3s)(l);
	loadFunc!(glWindowPos3dv)(l);
	loadFunc!(glWindowPos3fv)(l);
	loadFunc!(glWindowPos3iv)(l);
	loadFunc!(glWindowPos3sv)(l);
}

void loadGL15(Loader l)
{
	if (!GL_VERSION_1_5)
		return;

	loadFunc!(glGenQueries)(l);
	loadFunc!(glDeleteQueries)(l);
	loadFunc!(glIsQuery)(l);
	loadFunc!(glBeginQuery)(l);
	loadFunc!(glEndQuery)(l);
	loadFunc!(glGetQueryiv)(l);
	loadFunc!(glGetQueryObjectiv)(l);
	loadFunc!(glGetQueryObjectuiv)(l);
	loadFunc!(glBindBuffer)(l);
	loadFunc!(glDeleteBuffers)(l);
	loadFunc!(glGenBuffers)(l);
	loadFunc!(glIsBuffer)(l);
	loadFunc!(glBufferData)(l);
	loadFunc!(glBufferSubData)(l);
	loadFunc!(glGetBufferSubData)(l);
	loadFunc!(glMapBuffer)(l);
	loadFunc!(glUnmapBuffer)(l);
	loadFunc!(glGetBufferParameteriv)(l);
	loadFunc!(glGetBufferPointerv)(l);
}

void loadGL20(Loader l)
{
	if (!GL_VERSION_2_0)
		return;

	loadFunc!(glBlendEquationSeparate)(l);
	loadFunc!(glDrawBuffers)(l);
	loadFunc!(glStencilOpSeparate)(l);
	loadFunc!(glStencilFuncSeparate)(l);
	loadFunc!(glStencilMaskSeparate)(l);
	loadFunc!(glAttachShader)(l);
	loadFunc!(glBindAttribLocation)(l);
	loadFunc!(glCompileShader)(l);
	loadFunc!(glCreateProgram)(l);
	loadFunc!(glCreateShader)(l);
	loadFunc!(glDeleteProgram)(l);
	loadFunc!(glDeleteShader)(l);
	loadFunc!(glDetachShader)(l);
	loadFunc!(glDisableVertexAttribArray)(l);
	loadFunc!(glEnableVertexAttribArray)(l);
	loadFunc!(glGetActiveAttrib)(l);
	loadFunc!(glGetActiveUniform)(l);
	loadFunc!(glGetAttachedShaders)(l);
	loadFunc!(glGetAttribLocation)(l);
	loadFunc!(glGetProgramiv)(l);
	loadFunc!(glGetProgramInfoLog)(l);
	loadFunc!(glGetShaderiv)(l);
	loadFunc!(glGetShaderInfoLog)(l);
	loadFunc!(glShaderSource)(l);
	loadFunc!(glGetUniformLocation)(l);
	loadFunc!(glGetUniformfv)(l);
	loadFunc!(glGetUniformiv)(l);
	loadFunc!(glGetVertexAttribdv)(l);
	loadFunc!(glGetVertexAttribfv)(l);
	loadFunc!(glGetVertexAttribiv)(l);
	loadFunc!(glGetVertexAttribPointerv)(l);
	loadFunc!(glIsProgram)(l);
	loadFunc!(glIsShader)(l);
	loadFunc!(glLinkProgram)(l);
	loadFunc!(glGetShaderSource)(l);
	loadFunc!(glUseProgram)(l);
	loadFunc!(glUniform1f)(l);
	loadFunc!(glUniform1fv)(l);
	loadFunc!(glUniform1i)(l);
	loadFunc!(glUniform1iv)(l);
	loadFunc!(glUniform2f)(l);
	loadFunc!(glUniform2fv)(l);
	loadFunc!(glUniform2i)(l);
	loadFunc!(glUniform2iv)(l);
	loadFunc!(glUniform3f)(l);
	loadFunc!(glUniform3fv)(l);
	loadFunc!(glUniform3i)(l);
	loadFunc!(glUniform3iv)(l);
	loadFunc!(glUniform4f)(l);
	loadFunc!(glUniform4fv)(l);
	loadFunc!(glUniform4i)(l);
	loadFunc!(glUniform4iv)(l);
	loadFunc!(glUniformMatrix2fv)(l);
	loadFunc!(glUniformMatrix3fv)(l);
	loadFunc!(glUniformMatrix4fv)(l);
	loadFunc!(glValidateProgram)(l);
	loadFunc!(glVertexAttrib1d)(l);
	loadFunc!(glVertexAttrib1dv)(l);
	loadFunc!(glVertexAttrib1f)(l);
	loadFunc!(glVertexAttrib1fv)(l);
	loadFunc!(glVertexAttrib1s)(l);
	loadFunc!(glVertexAttrib1sv)(l);
	loadFunc!(glVertexAttrib2d)(l);
	loadFunc!(glVertexAttrib2dv)(l);
	loadFunc!(glVertexAttrib2f)(l);
	loadFunc!(glVertexAttrib2fv)(l);
	loadFunc!(glVertexAttrib2s)(l);
	loadFunc!(glVertexAttrib2sv)(l);
	loadFunc!(glVertexAttrib3d)(l);
	loadFunc!(glVertexAttrib3dv)(l);
	loadFunc!(glVertexAttrib3f)(l);
	loadFunc!(glVertexAttrib3fv)(l);
	loadFunc!(glVertexAttrib3s)(l);
	loadFunc!(glVertexAttrib3sv)(l);
	loadFunc!(glVertexAttrib4Nbv)(l);
	loadFunc!(glVertexAttrib4Niv)(l);
	loadFunc!(glVertexAttrib4Nsv)(l);
	loadFunc!(glVertexAttrib4Nub)(l);
	loadFunc!(glVertexAttrib4Nubv)(l);
	loadFunc!(glVertexAttrib4Nuiv)(l);
	loadFunc!(glVertexAttrib4Nusv)(l);
	loadFunc!(glVertexAttrib4bv)(l);
	loadFunc!(glVertexAttrib4d)(l);
	loadFunc!(glVertexAttrib4dv)(l);
	loadFunc!(glVertexAttrib4f)(l);
	loadFunc!(glVertexAttrib4fv)(l);
	loadFunc!(glVertexAttrib4iv)(l);
	loadFunc!(glVertexAttrib4s)(l);
	loadFunc!(glVertexAttrib4sv)(l);
	loadFunc!(glVertexAttrib4ubv)(l);
	loadFunc!(glVertexAttrib4uiv)(l);
	loadFunc!(glVertexAttrib4usv)(l);
	loadFunc!(glVertexAttribPointer)(l);
}

void loadGL21(Loader l)
{
	if (!GL_VERSION_2_1)
		return;

	loadFunc!(glUniformMatrix2x3fv)(l);
	loadFunc!(glUniformMatrix3x2fv)(l);
	loadFunc!(glUniformMatrix2x4fv)(l);
	loadFunc!(glUniformMatrix4x2fv)(l);
	loadFunc!(glUniformMatrix3x4fv)(l);
	loadFunc!(glUniformMatrix4x3fv)(l);
}

void loadGL_APPLE_vertex_array_object(Loader l)
{
	if (!GL_APPLE_vertex_array_object)
		return;

	loadFunc!(glBindVertexArrayAPPLE)(l);
	loadFunc!(glDeleteVertexArraysAPPLE)(l);
	loadFunc!(glGenVertexArraysAPPLE)(l);
	loadFunc!(glIsVertexArrayAPPLE)(l);
}

void loadGL_ARB_sync(Loader l)
{
	if (!GL_ARB_sync)
		return;

	loadFunc!(glFenceSync)(l);
	loadFunc!(glIsSync)(l);
	loadFunc!(glDeleteSync)(l);
	loadFunc!(glClientWaitSync)(l);
	loadFunc!(glWaitSync)(l);
	loadFunc!(glGetInteger64v)(l);
	loadFunc!(glGetSynciv)(l);
}

void loadGL_ARB_texture_compression(Loader l)
{
	if (!GL_ARB_texture_compression)
		return;

	loadFunc!(glCompressedTexImage1DARB)(l);
	loadFunc!(glCompressedTexImage2DARB)(l);
	loadFunc!(glCompressedTexImage3DARB)(l);
	loadFunc!(glCompressedTexSubImage1DARB)(l);
	loadFunc!(glCompressedTexSubImage2DARB)(l);
	loadFunc!(glCompressedTexSubImage3DARB)(l);
	loadFunc!(glGetCompressedTexImageARB)(l);
}

void loadGL_ARB_vertex_array_object(Loader l)
{
	if (!GL_ARB_vertex_array_object)
		return;

	loadFunc!(glBindVertexArray)(l);
	loadFunc!(glDeleteVertexArrays)(l);
	loadFunc!(glGenVertexArrays)(l);
	loadFunc!(glIsVertexArray)(l);
}

void loadGL_ARB_vertex_buffer_object(Loader l)
{
	loadFunc!(glBindBufferARB)(l);
	loadFunc!(glDeleteBuffersARB)(l);
	loadFunc!(glGenBuffersARB)(l);
	loadFunc!(glIsBufferARB)(l);
	loadFunc!(glBufferDataARB)(l);
	loadFunc!(glBufferSubDataARB)(l);
	loadFunc!(glGetBufferSubDataARB)(l);
	loadFunc!(glMapBufferARB)(l);
	loadFunc!(glUnmapBufferARB)(l);
	loadFunc!(glGetBufferParameterivARB)(l);
	loadFunc!(glGetBufferPointervARB)(l);
}

void loadGL_CHARGE_vertex_array_object()
{
	if (GL_ARB_vertex_array_object) {
		GL_CHARGE_vertex_array_object = true;
		glBindVertexArrayCHARGE = glBindVertexArray;
		glDeleteVertexArraysCHARGE = glDeleteVertexArrays;
		glGenVertexArraysCHARGE = glGenVertexArrays;
		glIsVertexArrayCHARGE = glIsVertexArray;
	} else if (GL_APPLE_vertex_array_object) {
		GL_CHARGE_vertex_array_object = true;
		glBindVertexArrayCHARGE = glBindVertexArrayAPPLE;
		glDeleteVertexArraysCHARGE = glDeleteVertexArraysAPPLE;
		glGenVertexArraysCHARGE = glGenVertexArraysAPPLE;
		glIsVertexArrayCHARGE = glIsVertexArrayAPPLE;
	}
}

void loadGL_EXT_framebuffer_object(Loader l)
{
	if (!GL_EXT_framebuffer_object)
		return;

	loadFunc!(glBindFramebufferEXT)(l);
	loadFunc!(glBindRenderbufferEXT)(l);
	loadFunc!(glCheckFramebufferStatusEXT)(l);
	loadFunc!(glDeleteFramebuffersEXT)(l);
	loadFunc!(glDeleteRenderbuffersEXT)(l);
	loadFunc!(glFramebufferRenderbufferEXT)(l);
	loadFunc!(glFramebufferTexture1DEXT)(l);
	loadFunc!(glFramebufferTexture2DEXT)(l);
	loadFunc!(glFramebufferTexture3DEXT)(l);
	loadFunc!(glGenFramebuffersEXT)(l);
	loadFunc!(glGenRenderbuffersEXT)(l);
	loadFunc!(glGenerateMipmapEXT)(l);
	loadFunc!(glGetFramebufferAttachmentParameterivEXT)(l);
	loadFunc!(glGetRenderbufferParameterivEXT)(l);
	loadFunc!(glIsFramebufferEXT)(l);
	loadFunc!(glIsRenderbufferEXT)(l);
	loadFunc!(glRenderbufferStorageEXT)(l);
}

void loadGL_EXT_geometry_shader4(Loader l)
{
	if (!GL_EXT_geometry_shader4)
		return;

	loadFunc!(glProgramParameteriEXT)(l);
	loadFunc!(glFramebufferTextureEXT)(l);
	loadFunc!(glFramebufferTextureLayerEXT)(l);
	loadFunc!(glFramebufferTextureFaceEXT)(l);
}

void loadGL_EXT_texture_array(Loader l)
{
	if (!GL_EXT_texture_array)
		return;

	// Collides with GL_EXT_geometry_shader4
	if (!GL_EXT_geometry_shader4)
		loadFunc!(glFramebufferTextureLayerEXT)(l);
}

void loadGL_NV_depth_buffer_float(Loader l)
{
	if (!GL_NV_depth_buffer_float)
		return;

	loadFunc!(glDepthRangedNV)(l);
	loadFunc!(glClearDepthdNV)(l);
	loadFunc!(glDepthBoundsdNV)(l);
}
