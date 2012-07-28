// This file is hand mangled of a ODE header file.
// See copyright in src/ode/ode.d (BSD).
module lib.ode.space;

import lib.ode.common;
import lib.ode.contact;


extern (C) {
	typedef void function (void *data, dGeomID o1, dGeomID o2) dNearCallback;
}

version(DynamicODE)
{
extern(C):
dSpaceID (*dSimpleSpaceCreate)(dSpaceID space);
dSpaceID (*dHashSpaceCreate)(dSpaceID space);
dSpaceID (*dQuadTreeSpaceCreate)(dSpaceID space, dVector3 Center, dVector3 Extents, int Depth);
void (*dSpaceDestroy)(dSpaceID);
void (*dHashSpaceSetLevels)(dSpaceID space, int minlevel, int maxlevel);
void (*dHashSpaceGetLevels)(dSpaceID space, int *minlevel, int *maxlevel);
void (*dSpaceSetCleanup)(dSpaceID space, int mode);
int (*dSpaceGetCleanup)(dSpaceID space);
void (*dSpaceAdd)(dSpaceID, dGeomID);
void (*dSpaceRemove)(dSpaceID, dGeomID);
int (*dSpaceQuery)(dSpaceID, dGeomID);
void (*dSpaceClean)(dSpaceID);
int (*dSpaceGetNumGeoms)(dSpaceID);
dGeomID (*dSpaceGetGeom)(dSpaceID, int i);
}
else
{
extern(C):
dSpaceID dSimpleSpaceCreate(dSpaceID space);
dSpaceID dHashSpaceCreate(dSpaceID space);
dSpaceID dQuadTreeSpaceCreate(dSpaceID space, dVector3 Center, dVector3 Extents, int Depth);
void dSpaceDestroy(dSpaceID);
void dHashSpaceSetLevels(dSpaceID space, int minlevel, int maxlevel);
void dHashSpaceGetLevels(dSpaceID space, int *minlevel, int *maxlevel);
void dSpaceSetCleanup(dSpaceID space, int mode);
int dSpaceGetCleanup(dSpaceID space);
void dSpaceAdd(dSpaceID, dGeomID);
void dSpaceRemove(dSpaceID, dGeomID);
int dSpaceQuery(dSpaceID, dGeomID);
void dSpaceClean(dSpaceID);
int dSpaceGetNumGeoms(dSpaceID);
dGeomID dSpaceGetGeom(dSpaceID, int i);
}
