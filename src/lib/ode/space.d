// This file is hand mangled of a ODE header file.
// See copyright in src/ode/ode.d (BSD).
module lib.ode.space;

import lib.ode.common;
import lib.ode.contact;


extern (C) {
	alias void function (void *data, dGeomID o1, dGeomID o2) dNearCallback;
}

version(DynamicODE)
{
extern(C):
dSpaceID function(dSpaceID space) dSimpleSpaceCreate;
dSpaceID function(dSpaceID space) dHashSpaceCreate;
dSpaceID function(dSpaceID space, ref dVector3 Center, ref dVector3 Extents, int Depth) dQuadTreeSpaceCreate;
void function(dSpaceID) dSpaceDestroy;
void function(dSpaceID space, int minlevel, int maxlevel) dHashSpaceSetLevels;
void function(dSpaceID space, int *minlevel, int *maxlevel) dHashSpaceGetLevels;
void function(dSpaceID space, int mode) dSpaceSetCleanup;
int function(dSpaceID space) dSpaceGetCleanup;
void function(dSpaceID, dGeomID) dSpaceAdd;
void function(dSpaceID, dGeomID) dSpaceRemove;
int function(dSpaceID, dGeomID) dSpaceQuery;
void function(dSpaceID) dSpaceClean;
int function(dSpaceID) dSpaceGetNumGeoms;
dGeomID function(dSpaceID, int i) dSpaceGetGeom;
}
else
{
extern(C):
dSpaceID dSimpleSpaceCreate(dSpaceID space);
dSpaceID dHashSpaceCreate(dSpaceID space);
dSpaceID dQuadTreeSpaceCreate(dSpaceID space, ref dVector3 Center, ref dVector3 Extents, int Depth);
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
