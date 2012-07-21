// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module lib.dcpu.dcpu;

import std.stdint;


extern(C):

enum {
	REG_A = 0x00,
	REG_B = 0x01,
	REG_C = 0x02,
	REG_X = 0x03,
	REG_Y = 0x04,
	REG_Z = 0x05,
	REG_I = 0x06,
	REG_J = 0x07,
}

struct vm_t
{
	uint16_t registers[8];    ///< The 8 virtual machine registers: A, B, C, X, Y, Z, I, J.
	uint16_t pc;              ///< The virtual machine's current instruction position.
	uint16_t sp;              ///< The virtual machine's current stack position.
	uint16_t ia;              ///< The current interrupt handler location.
	uint16_t ex;              ///< The overflow or excess data register.
	uint16_t ram[0x10000];    ///< The virtual machine's main RAM segment.
	uint16_t dummy;           ///< A dummy position that is used internally to silently redirect assignments.
	uint16_t irq[256];        ///< The interrupt queue.
	uint16_t irq_count;       ///< The number of interrupts currently in the queue.
	uint16_t sleep_cycles;    ///< An internal counter used to measure how many additional cycles the VM should sleep for.
	uint8_t queue_interrupts; ///< Whether the interrupt queue is enabled.
	uint8_t halted;           ///< Whether the virtual machine is currently halted.
	uint8_t skip;             ///< Whether the virtual machine will skip the next instruction.
	uint8_t debug_;           ///< Whether the virtual machine will output each instruction to standard output.
	void* dump;               ///< An open file descriptor where instruction execution information should be sent, or NULL.
}

typedef void function(vm_t* vm, void* ud) hw_interrupt;

/* dcpu.h */

vm_t* vm_create();
void vm_flash(vm_t* vm, uint16_t memory[0x10000]);
void vm_execute(vm_t* vm, char* execution_dump);
void vm_free(vm_t* vm);

/* dcpubase.h */

void vm_halt(vm_t* vm, char* message, ...);
void vm_interrupt(vm_t* vm, uint16_t msgid);
uint16_t vm_consume_word(vm_t* vm);
uint16_t vm_resolve_value(vm_t* vm, uint16_t val, uint8_t pos);
void vm_cycle(vm_t* vm);

extern(D):

bool vm_run_cycles(vm_t* vm, int cycles)
{
	for (int i; i < cycles; i++) {
		vm_cycle(vm);

		if (vm.halted)
			return false;
	}

	return true;
}
