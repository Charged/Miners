// This file is hand mangled of a ODE header file.
// See copyright in src/ode/ode.d (BSD).
module lib.ode.init;


const dInitFlagManualThreadCleanup = 0x00000001;
const dAllocateFlagBasicData = 0;
const dAllocateFlagCollisionData = 0x00000001;
const dAllocateMaskAll = ~0U;

version(DynamicODE)
{
extern(C):
void (*dInitODE)();
void (*dInitODE2)(uint initFlags);
int (*dAllocateODEDataForThread)(uint uiAllocateFlags);
}
else
{
extern(C):
void dInitODE();
void dInitODE2(uint initFlags);
int dAllocateODEDataForThread(uint uiAllocateFlags);
}
