// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module lib.dcpu.dcpu;

import std.stdint : uint8_t, uint16_t, uint32_t;


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

	REG_PC = 0x08,
	REG_SP = 0x09,
	REG_IA = 0x0A,
	REG_EX = 0x0B,

	REG_NUM = 0x0C
}

enum {
	VM_NUM_IRQS = 256,
	VM_RAM_SIZE = 0x10000,
	VM_HOOK_MAX = 50,
	VM_HW_MAX = 32,
}

struct vm_t
{
	uint16_t registers[8];      ///< The 8 virtual machine registers: A, B, C, X, Y, Z, I, J.
	uint16_t pc;                ///< The virtual machine's current instruction position.
	uint16_t sp;                ///< The virtual machine's current stack position.
	uint16_t ia;                ///< The current interrupt handler location.
	uint16_t ex;                ///< The overflow or excess data register.
	uint16_t ram[VM_RAM_SIZE];  ///< The virtual machine's main RAM segment.
	uint16_t dummy;             ///< A dummy position that is used internally to silently redirect assignments.
	uint16_t irq[VM_NUM_IRQS];  ///< The interrupt queue.
	uint16_t irq_count;         ///< The number of interrupts currently in the queue.
	uint16_t sleep_cycles;      ///< An internal counter used to measure how many additional cycles the VM should sleep for.
	uint8_t queue_interrupts;   ///< Whether the interrupt queue is enabled.
	uint8_t halted;             ///< Whether the virtual machine is currently halted.
	uint8_t exit;               ///< Whether the virtual machine is quitting.
	uint8_t skip;               ///< Whether the virtual machine will skip the next instruction.
	uint8_t debug_;             ///< Whether the virtual machine will output each instruction to standard output.

	bool can_fire;              ///< Will the DCPU catch fire on an invalid operation?
	bool on_fire;               ///< Is the DCPU on fire?
	int fire_cycles;
	int fire_cycles_target;
	int radiation_factor;

	bool radiation;
	int radiation_cycles;
	int radiation_cycles_target;

	vm_hook hook_list[VM_HOOK_MAX];
	uint16_t hook_mode[VM_HOOK_MAX];
	void* hook_userdata[VM_HOOK_MAX];

	hw_t* hw_list[VM_HW_MAX];

	void* dump;                 ///< An open file descriptor where instruction execution information should be sent, or NULL.

	void* host;       ///< The hardware emulation host.
}

struct hw_t
{
	uint32_t id;           /// The hardware identifier.
	uint16_t ver;          /// The hardware version.
	uint32_t manufacturer; /// The hardware manufacturer.
	hw_interrupt handler;  /// The function which handles interrupts sent to this hardware component.
	hw_free_handler free_handler; ///< The function which handles free'ing any data this hardware component uses.
	void* userdata;        /// Userdata associated with the hardware.
}

alias void function(vm_t* vm, void* ud) hw_interrupt;
alias void function(void* ud) hw_free_handler;
alias void function(vm_t* vm, void* ud) vm_hook;


/* dcpu.h */

vm_t* vm_create();
void vm_init(vm_t* vm);
void vm_flash(vm_t* vm, uint16_t memory[0x10000]);
void vm_free(vm_t* vm);

/* dcpubase.h */

void vm_halt(vm_t* vm, char* message, ...);
void vm_interrupt(vm_t* vm, uint16_t msgid);
uint16_t vm_consume_word(vm_t* vm);
uint16_t vm_resolve_value(vm_t* vm, uint16_t val, uint8_t pos);
void vm_cycle(vm_t* vm);

/* hw.h */

uint16_t vm_hw_register(vm_t* vm, hw_t* device);
void vm_hw_unregister(vm_t* vm, uint16_t id);
uint16_t vm_hw_count(vm_t* vm);
hw_t vm_hw_get_device(vm_t* vm, uint16_t index);
void vm_hw_interrupt(vm_t* vm, uint16_t index);


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
