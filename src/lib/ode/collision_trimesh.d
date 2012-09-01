// This file is hand mangled of a ODE header file.
// See copyright in src/ode/ode.d (BSD).
module lib.ode.collision_trimesh;

import lib.ode.common;


enum { TRIMESH_FACE_NORMALS };

alias void* dTriMeshDataID;

extern(C) {
	alias int dTriCallback(dGeomID TriMesh, dGeomID RefObject, int TriangleIndex);
	alias void dTriArrayCallback(dGeomID TriMesh, dGeomID RefObject, int* TriIndices, int TriCount);
	alias int dTriRayCallback(dGeomID TriMesh, dGeomID Ray, int TriangleIndex, dReal u, dReal v);
}

version(DynamicODE)
{
extern(C):
dTriMeshDataID function() dGeomTriMeshDataCreate;
void function(dTriMeshDataID g) dGeomTriMeshDataDestroy;
void function(dTriMeshDataID g, int data_id, void* in_data) dGeomTriMeshDataSet;
void* function(dTriMeshDataID g, int data_id) dGeomTriMeshDataGet;
void function( dGeomID g, dMatrix4 last_trans ) dGeomTriMeshSetLastTransform;
dReal* function( dGeomID g ) dGeomTriMeshGetLastTransform;
void function(dTriMeshDataID g, void* Vertices, int VertexStride, int VertexCount, void* Indices, int IndexCount, int TriStride) dGeomTriMeshDataBuildSingle;
void function(dTriMeshDataID g, void* Vertices, int VertexStride, int VertexCount, void* Indices, int IndexCount, int TriStride, void* Normals) dGeomTriMeshDataBuildSingle1;
void function(dTriMeshDataID g, void* Vertices,  int VertexStride, int VertexCount, void* Indices, int IndexCount, int TriStride) dGeomTriMeshDataBuildDouble;
void function(dTriMeshDataID g, void* Vertices,  int VertexStride, int VertexCount, void* Indices, int IndexCount, int TriStride, void* Normals) dGeomTriMeshDataBuildDouble1;
void function(dTriMeshDataID g, dReal* Vertices, int VertexCount, int* Indices, int IndexCount) dGeomTriMeshDataBuildSimple;
void function(dTriMeshDataID g, dReal* Vertices, int VertexCount, int* Indices, int IndexCount, int* Normals) dGeomTriMeshDataBuildSimple1;
void function(dTriMeshDataID g) dGeomTriMeshDataPreprocess;
void function(dTriMeshDataID g, ubyte** buf, int* bufLen) dGeomTriMeshDataGetBuffer;
void function(dTriMeshDataID g, ubyte* buf) dGeomTriMeshDataSetBuffer;
void function(dGeomID g, dTriCallback* Callback) dGeomTriMeshSetCallback;
dTriCallback* function(dGeomID g) dGeomTriMeshGetCallback;
void function(dGeomID g, dTriArrayCallback* ArrayCallback) dGeomTriMeshSetArrayCallback;
dTriArrayCallback* function(dGeomID g) dGeomTriMeshGetArrayCallback;
void function(dGeomID g, dTriRayCallback* Callback) dGeomTriMeshSetRayCallback;
dTriRayCallback* function(dGeomID g) dGeomTriMeshGetRayCallback;
dGeomID function(dSpaceID space, dTriMeshDataID Data, dTriCallback* Callback, dTriArrayCallback* ArrayCallback, dTriRayCallback* RayCallback) dCreateTriMesh;
void function(dGeomID g, dTriMeshDataID Data) dGeomTriMeshSetData;
dTriMeshDataID function(dGeomID g) dGeomTriMeshGetData;
void function(dGeomID g, int geomClass, int enable) dGeomTriMeshEnableTC;
int function(dGeomID g, int geomClass) dGeomTriMeshIsTCEnabled;
void function(dGeomID g) dGeomTriMeshClearTCCache;
dTriMeshDataID function(dGeomID g) dGeomTriMeshGetTriMeshDataID;
void function(dGeomID g, int Index, dVector3* v0, dVector3* v1, dVector3* v2) dGeomTriMeshGetTriangle;
void function(dGeomID g, int Index, dReal u, dReal v, dVector3 Out) dGeomTriMeshGetPoint;
int function(dGeomID g) dGeomTriMeshGetTriangleCount;
void function(dTriMeshDataID g) dGeomTriMeshDataUpdate;
}
else
{
extern(C):
dTriMeshDataID dGeomTriMeshDataCreate();
void dGeomTriMeshDataDestroy(dTriMeshDataID g);
void dGeomTriMeshDataSet(dTriMeshDataID g, int data_id, void* in_data);
void* dGeomTriMeshDataGet(dTriMeshDataID g, int data_id);
void dGeomTriMeshSetLastTransform( dGeomID g, dMatrix4 last_trans );
dReal* dGeomTriMeshGetLastTransform( dGeomID g );
void dGeomTriMeshDataBuildSingle(dTriMeshDataID g, void* Vertices, int VertexStride, int VertexCount, void* Indices, int IndexCount, int TriStride);
void dGeomTriMeshDataBuildSingle1(dTriMeshDataID g, void* Vertices, int VertexStride, int VertexCount, void* Indices, int IndexCount, int TriStride, void* Normals);
void dGeomTriMeshDataBuildDouble(dTriMeshDataID g, void* Vertices,  int VertexStride, int VertexCount, void* Indices, int IndexCount, int TriStride);
void dGeomTriMeshDataBuildDouble1(dTriMeshDataID g, void* Vertices,  int VertexStride, int VertexCount, void* Indices, int IndexCount, int TriStride, void* Normals);
void dGeomTriMeshDataBuildSimple(dTriMeshDataID g, dReal* Vertices, int VertexCount, int* Indices, int IndexCount);
void dGeomTriMeshDataBuildSimple1(dTriMeshDataID g, dReal* Vertices, int VertexCount, int* Indices, int IndexCount, int* Normals);
void dGeomTriMeshDataPreprocess(dTriMeshDataID g);
void dGeomTriMeshDataGetBuffer(dTriMeshDataID g, ubyte** buf, int* bufLen);
void dGeomTriMeshDataSetBuffer(dTriMeshDataID g, ubyte* buf);
void dGeomTriMeshSetCallback(dGeomID g, dTriCallback* Callback);
dTriCallback* dGeomTriMeshGetCallback(dGeomID g);
void dGeomTriMeshSetArrayCallback(dGeomID g, dTriArrayCallback* ArrayCallback);
dTriArrayCallback* dGeomTriMeshGetArrayCallback(dGeomID g);
void dGeomTriMeshSetRayCallback(dGeomID g, dTriRayCallback* Callback);
dTriRayCallback* dGeomTriMeshGetRayCallback(dGeomID g);
dGeomID dCreateTriMesh(dSpaceID space, dTriMeshDataID Data, dTriCallback* Callback, dTriArrayCallback* ArrayCallback, dTriRayCallback* RayCallback);
void dGeomTriMeshSetData(dGeomID g, dTriMeshDataID Data);
dTriMeshDataID dGeomTriMeshGetData(dGeomID g);
void dGeomTriMeshEnableTC(dGeomID g, int geomClass, int enable);
int dGeomTriMeshIsTCEnabled(dGeomID g, int geomClass);
void dGeomTriMeshClearTCCache(dGeomID g);
dTriMeshDataID dGeomTriMeshGetTriMeshDataID(dGeomID g);
void dGeomTriMeshGetTriangle(dGeomID g, int Index, dVector3* v0, dVector3* v1, dVector3* v2);
void dGeomTriMeshGetPoint(dGeomID g, int Index, dReal u, dReal v, dVector3 Out);
int dGeomTriMeshGetTriangleCount(dGeomID g);
void dGeomTriMeshDataUpdate(dTriMeshDataID g);
}
