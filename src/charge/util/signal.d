// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.util.signal;

import charge.util.vector;

/*
 * This signal implementation isn't very portable using D1 phobos specific
 * hidden functionality. All this to support autoremove on delete.
 */

extern (C) Object _d_toObject(void* p);

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
		o.notifyRegister(&unhook);
	}

	alias opCatAssign connect;

	void opSubAssign(Slot slot)
	{
		for(size_t i; i < slots.length;) {
			if (slots[i] == slot) {
				slots.remove(i);
				Object o = _d_toObject(slot.ptr);
				o.notifyUnRegister(&unhook);
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
			o.notifyUnRegister(&unhook);
		}
		slots.removeAll();
	}
}
