// This file is hand mangled of a ODE header file.
// See copyright in src/ode/ode.d (BSD).
module lib.ode.mass;

import lib.ode.common;


struct dMass
{
	dReal mass;
	dVector4 c;
	dMatrix3 I;

	static dMass opCall()
	{
		dMass ret;
		dMassSetZero(&ret);
		return ret;
	}

	void setZero()
	{ dMassSetZero(&this); }
	void setParameters(dReal themass, dReal cgx, dReal cgy, dReal cgz, dReal I11, dReal I22, dReal I33, dReal I12, dReal I13, dReal I23)
	{ dMassSetParameters(&this,themass,cgx,cgy,cgz,I11,I22,I33,I12,I13,I23); }
	void setSphere(dReal density, dReal radius)
	{ dMassSetSphere(&this,density,radius); }
	void setCapsule(dReal density, int direction, dReal a, dReal b)
	{ dMassSetCapsule(&this,density,direction,a,b); }
	void setCappedCylinder(dReal density, int direction, dReal a, dReal b)
	{ setCapsule(density, direction, a, b); }
	void setBox(dReal density, dReal lx, dReal ly, dReal lz)
	{ dMassSetBox(&this,density,lx,ly,lz); }
	void adjust(dReal newmass)
	{ dMassAdjust(&this,newmass); }
	void translate(dReal x, dReal y, dReal z)
	{ dMassTranslate(&this,x,y,z); }
	void rotate(dMatrix3 R)
	{ dMassRotate(&this,R); }
	void add(dMass *b)
	{ dMassAdd(&this,b); }
}



version(DynamicODE)
{
extern(C):
int function(dMass *m) dMassCheck;
void function(dMass *) dMassSetZero;
void function(dMass *, dReal themass, dReal cgx, dReal cgy, dReal cgz, dReal I11, dReal I22, dReal I33, dReal I12, dReal I13, dReal I23) dMassSetParameters;
void function(dMass *, dReal density, dReal radius) dMassSetSphere;
void function(dMass *, dReal total_mass, dReal radius) dMassSetSphereTotal;
void function(dMass *, dReal density, int direction, dReal radius, dReal length) dMassSetCapsule;
void function(dMass *, dReal total_mass, int direction, dReal radius, dReal length) dMassSetCapsuleTotal;
void function(dMass *, dReal density, int direction, dReal radius, dReal length) dMassSetCylinder;
void function(dMass *, dReal total_mass, int direction, dReal radius, dReal length) dMassSetCylinderTotal;
void function(dMass *, dReal density, dReal lx, dReal ly, dReal lz) dMassSetBox;
void function(dMass *, dReal total_mass, dReal lx, dReal ly, dReal lz) dMassSetBoxTotal;
void function(dMass *, dReal density, dGeomID g) dMassSetTrimesh;
//void function(dMass *m, dReal total_mass, dGeomID g) dMassSetTrimeshTotal;
void function(dMass *, dReal newmass) dMassAdjust;
void function(dMass *, dReal x, dReal y, dReal z) dMassTranslate;
void function(dMass *a, dMatrix3 R) dMassRotate;
void function(dMass *a, dMass *b) dMassAdd;
}
else
{
extern(C):
int dMassCheck(dMass *m);
void dMassSetZero(dMass *);
void dMassSetParameters(dMass *, dReal themass, dReal cgx, dReal cgy, dReal cgz, dReal I11, dReal I22, dReal I33, dReal I12, dReal I13, dReal I23);
void dMassSetSphere(dMass *, dReal density, dReal radius);
void dMassSetSphereTotal(dMass *, dReal total_mass, dReal radius);
void dMassSetCapsule(dMass *, dReal density, int direction, dReal radius, dReal length);
void dMassSetCapsuleTotal(dMass *, dReal total_mass, int direction, dReal radius, dReal length);
void dMassSetCylinder(dMass *, dReal density, int direction, dReal radius, dReal length);
void dMassSetCylinderTotal(dMass *, dReal total_mass, int direction, dReal radius, dReal length);
void dMassSetBox(dMass *, dReal density, dReal lx, dReal ly, dReal lz);
void dMassSetBoxTotal(dMass *, dReal total_mass, dReal lx, dReal ly, dReal lz);
void dMassSetTrimesh(dMass *, dReal density, dGeomID g);
//void dMassSetTrimeshTotal(dMass *m, dReal total_mass, dGeomID g);
void dMassAdjust(dMass *, dReal newmass);
void dMassTranslate(dMass *, dReal x, dReal y, dReal z);
void dMassRotate(dMass *a, dMatrix3 R);
void dMassAdd(dMass *a, dMass *b);
}
