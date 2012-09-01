// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.tracker;

import lib.sdl.sdl;


final class TimeTracker
{
public:
	string name;

private:
	long then;
	long accumilated;

	static TimeTracker[16] stack;
	static size_t top;

	static TimeTracker[] keepers;
	static long lastCalc;

public:
	this(string name)
	{
		this.name = name;
		keepers ~= this;
	}

	static this()
	{
		auto tk = new TimeTracker("N/A");
		stack[top] = tk;
	}

	void start()
	{
		auto now = SDL_GetTicks();
		stack[top].account(now);
		then = now;

		stack[++top] = this;
	}

	void stop()
	{
		auto now = SDL_GetTicks();
		account(now);

		assert(stack[top] is this);
		stack[top--] = null;
		stack[top].then = now;
	}

	static void calcAll(void delegate(string name, double amount) dg)
	{
		auto now = SDL_GetTicks();
		long elapsed = now - lastCalc;
		lastCalc = now;

		// Make sure everything up till now is accounted for.
		stack[top].account(now);

		foreach(tk; keepers) {
			auto ret = tk.calc(elapsed);
			dg(tk.name, ret);
		}
	}

private:
	void account(long now)
	{
		accumilated += now - then;
		then = now;
	}

	double calc(long elapsed)
	{
		double ret = accumilated / cast(real)elapsed * 100.0;
		accumilated = 0;
		return ret;
	}
}
