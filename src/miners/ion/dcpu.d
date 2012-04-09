// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.ion.dcpu;

import std.stdint;


alias void* Dcpu;

extern(C):

Dcpu Dcpu_Create();
void Dcpu_Destroy(Dcpu* me);
uint16_t* Dcpu_GetRam(Dcpu me);
int Dcpu_Execute(Dcpu me, int cycles);

alias void function(Dcpu me, void *data) Dcpu_SysCall;

void Dcpu_SetSysCall(Dcpu me, Dcpu_SysCall sc, int id, void* data);

uint16_t Dcpu_Pop(Dcpu me);
void Dcpu_Push(Dcpu me, uint16_t v);
void Dcpu_DumpState(Dcpu me);

enum Dcpu_Register { DR_A, DR_B, DR_C, DR_X, DR_Y, DR_Z, DR_I, DR_J };

uint16_t Dcpu_GetRegister(Dcpu me, Dcpu_Register reg);

void Dcpu_SetRegister(Dcpu me, Dcpu_Register reg, uint16_t val);
