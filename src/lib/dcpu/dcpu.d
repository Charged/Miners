// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module lib.dcpu.dcpu;

alias void* Dcpu;

extern(C):

Dcpu Dcpu_Create();
void Dcpu_Destroy(Dcpu* me);
ushort* Dcpu_GetRam(Dcpu me);
int Dcpu_Execute(Dcpu me, int cycles);

alias void function(Dcpu me, void *data) Dcpu_SysCall;

void Dcpu_SetSysCall(Dcpu me, Dcpu_SysCall sc, int id, void* data);

ushort Dcpu_Pop(Dcpu me);
void Dcpu_Push(Dcpu me, ushort v);
void Dcpu_DumpState(Dcpu me);

enum Dcpu_Register { DR_A, DR_B, DR_C, DR_X, DR_Y, DR_Z, DR_I, DR_J };

ushort Dcpu_GetRegister(Dcpu me, Dcpu_Register reg);

void Dcpu_SetRegister(Dcpu me, Dcpu_Register reg, ushort val);
