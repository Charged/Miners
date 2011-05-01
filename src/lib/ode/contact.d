// This file is hand mangled of a ODE header file.
// See copyright in src/ode/ode.d (BSD).
module lib.ode.contact;

import lib.ode.common;

const dContactMu2       = 0x001;
const dContactFDir1     = 0x002;
const dContactBounce    = 0x004;
const dContactSoftERP   = 0x008;
const dContactSoftCFM   = 0x010;
const dContactMotion1   = 0x020;
const dContactMotion2   = 0x040;
const dContactMotionN   = 0x080;
const dContactSlip1     = 0x100;
const dContactSlip2     = 0x200;
const dContactApprox0   = 0x0000;
const dContactApprox1_1 = 0x1000;
const dContactApprox1_2 = 0x2000;
const dContactApprox1   = 0x3000;

struct dSurfaceParameters
{
	int mode;
	dReal mu;

	dReal mu2;
	dReal bounce;
	dReal bounce_vel;
	dReal soft_erp;
	dReal soft_cfm;
	dReal motion1, motion2, motionN;
	dReal slip1, slip2;
}

struct dContactGeom
{
	dVector3 pos;
	dVector3 normal;
	dReal depth;
	dGeomID g1, g2;
	int side1, side2;
}

struct dContact
{
	dSurfaceParameters surface;
	dContactGeom geom;
	dVector3 fdir1;
}
