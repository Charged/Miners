// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Signal.
 */
module charge.util.signal;

import charge.util.vector;


struct Signal(T...)
{
private:
	Vector!(Slot) slots;

public:
	alias void delegate(T) Slot;

	void opCatAssign(Slot slot)
	{
		if (slots.find(slot) >= 0)
			return;

		slots ~= slot;
		Object o = _d_toObject(slot.ptr);
		rt_attachDisposeEvent(o, &unhook);
	}

	alias opCatAssign connect;

	void opSubAssign(Slot slot)
	{
		for(size_t i; i < slots.length;) {
			if (slots[i] == slot) {
				slots.remove(i);
				Object o = _d_toObject(slot.ptr);
				rt_detachDisposeEvent(o, &unhook);
			} else {
				i++;
			}
		}
	}

	alias opSubAssign disconnect;

	void opCall(T t)
	{
		foreach(s; slots)
				s(t);
	}

	alias opCall emit;

	void unhook(Object o)
	{
		for(size_t i; i < slots.length;) {
			auto s = slots[i];
			if (_d_toObject(s.ptr) is o) {
				slots.remove(i);
			} else {
				i++;
			}
		}
	}

	void destruct()
	{
		foreach(slot; slots) {
			Object o = _d_toObject(slot.ptr);
			rt_detachDisposeEvent(o, &unhook);
		}
		slots.removeAll();
	}
}

private:
// From phobos code:
// Special function for internal use only (hah!).
// Use of this is where the slot had better be a delegate
// to an object or an interface that is part of an object.
extern(C) Object _d_toObject(void* p);

alias void delegate(Object) DisposeEvt;
extern(C) void rt_attachDisposeEvent(Object obj, DisposeEvt evt);
extern(C) void rt_detachDisposeEvent(Object obj, DisposeEvt evt);
