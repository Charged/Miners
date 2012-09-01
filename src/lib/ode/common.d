// This file is hand mangled of a ODE header file.
// See copyright in src/ode/ode.d (BSD).
module lib.ode.common;


alias float dReal;

alias dReal dVector3[4];
alias dReal dVector4[4];
alias dReal dMatrix3[4*3];
alias dReal dMatrix4[4*4];
alias dReal dMatrix6[8*6];
alias dVector4 dQuaternion;

alias void* dWorldID;
alias void* dSpaceID;
alias void* dBodyID;
alias void* dGeomID;
alias void* dJointID;
alias void* dJointGroupID;

enum {
	d_ERR_UNKNOWN = 0,
	d_ERR_IASSERT,
	d_ERR_UASSERT,
	d_ERR_LCP
}

enum {
	dJointTypeNone = 0,
	dJointTypeBall,
	dJointTypeHinge,
	dJointTypeSlider,
	dJointTypeContact,
	dJointTypeUniversal,
	dJointTypeHinge2,
	dJointTypeFixed,
	dJointTypeNull,
	dJointTypeAMotor,
	dJointTypeLMotor,
	dJointTypePlane2D,
	dJointTypePR
}

struct dLimot
{
	int mode;
	dReal lostop, histop;
	dReal vel, fmax;
	dReal fudge_factor;
	dReal bounce, soft;
	dReal suspension_erp, suspension_cfm;
};

const dLimotLoStop      = 0x0001;
const dLimotHiStop      = 0x0002;
const dLimotVel         = 0x0004;
const dLimotFMax        = 0x0008;
const dLimotFudgeFactor = 0x0010;
const dLimotBounce      = 0x0020;
const dLimotSoft        = 0x0040;

enum {
	dParamLoStop = 0,
	dParamHiStop,
	dParamVel,
	dParamFMax,
	dParamFudgeFactor,
	dParamBounce,
	dParamCFM,
	dParamStopERP,
	dParamStopCFM,
	dParamSuspensionERP,
	dParamSuspensionCFM,

	dParamLoStop2 = 0x100,
	dParamHiStop2,
	dParamVel2,
	dParamFMax2,
	dParamFudgeFactor2,
	dParamBounce2,
	dParamCFM2,
	dParamStopERP2,
	dParamStopCFM2,
	dParamSuspensionERP2,
	dParamSuspensionCFM2,

	dParamLoStop3 = 0x200,
	dParamHiStop3,
	dParamVel3,
	dParamFMax3,
	dParamFudgeFactor3,
	dParamBounce3,
	dParamCFM3,
	dParamStopERP3,
	dParamStopCFM3,
	dParamSuspensionERP3,
	dParamSuspensionCFM3,

	dParamGroup=0x100
}

const dAMotorUser  = 0;
const dAMotorEuler = 1;

struct dJointFeedback
{
	dVector3 f1;
	dVector3 t1;
	dVector3 f2;
	dVector3 t2;
}

version(DynamicODE)
{
extern (C):
void function(dGeomID) dGeomMoved;
dGeomID function(dGeomID) dGeomGetBodyNext;
}
else
{
extern (C):
void dGeomMoved(dGeomID);
dGeomID dGeomGetBodyNext(dGeomID);
}
