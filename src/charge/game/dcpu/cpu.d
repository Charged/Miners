// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.dcpu.cpu;

import lib.gl.gl;

import lib.dcpu.dcpu;


/**
 * Info struct for attached hw.
 */
struct DcpuHwInfo
{
	uint id;
	uint manufacturer;
	ushort ver;
	ushort index;
}

/**
 * A attached hardware to a dcpu.
 */
interface DcpuHw
{
	DcpuHwInfo* getHwInfo();
	void interupt();
	void notifyUnregister();
}

final class Dcpu
{
public:
	vm_t* vm;
	DcpuHw[] hws;
	hw_t[] hwStructs;


public:
	this()
	{
		vm = vm_create();
	}

	~this()
	{
		assert(vm is null);
		assert(hws is null);
	}

	void close()
	{
		foreach(hw; hws) {
			hw.notifyUnregister();
		}
		hws = null;

		if (vm !is null) {
			vm_free(vm);
			vm = null;
		}
	}

	bool step(int cycles)
	{
		return vm_run_cycles(vm, cycles);;
	}

	ushort* ram()
	{
		return vm.ram.ptr;
	}

	ushort reg(uint reg)
	{
		if (reg >= REG_NUM)
			throw new Exception("Reg out of bounds");

		// Spill into sp, pc, ia & ex.
		return vm.registers.ptr[reg];
	}

	/**
	 * Safely get a slice of ram, returns default if it failed.
	 */
	ushort[] getSliceSafe(ushort offset, size_t size, ushort[] def)
	{
		if (offset + size > VM_RAM_SIZE)
			return def;

		return vm.ram[offset .. offset + size];
	}

	void addSleep(ushort sleep)
	{
		vm.sleep_cycles += sleep;
	}


	/*
	 *
	 * Attached hardware.
	 *
	 */


	void register(DcpuHw hw)
	{
		auto info = hw.getHwInfo();

		hw_t hwStruct;
		hwStruct.id = info.id;
		hwStruct.ver = info.ver;
		hwStruct.manufacturer = info.manufacturer;
		hwStruct.handler = &handler;
		hwStruct.userdata = cast(void*)hw;

		hws ~= hw;
		hwStructs ~= hwStruct;

		info.index = vm_hw_register(vm, &hwStructs[$-1]);
	}

	private static extern(C) void handler(vm_t* vm, void* ud)
	{
		auto hw = cast(DcpuHw)ud;
		if (hw is null)
			throw new Exception("Oh god");
		hw.interupt();
	}
}
