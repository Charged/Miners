// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.debugger;

import std.string : sformat;

static import std.gc;
static import gcstats;
static import lib.sdl.sdl;

import charge.charge;
import charge.sys.tracker : TimeTracker;
import charge.sys.memory : MemHeader;

import miners.interfaces;

static import miners.terrain.chunk;


/**
 * A debug display overlay.
 */
class DebugRunner : public Runner
{
protected:
	Router router;

	GfxDraw d;
	GfxDynamicTexture debugText;

	uint num_frames;

	ulong start;
	const ulong stepLength = 1000;

public:
	this(Router r)
	{
		super(Type.Overlay);

		this.router = r;

		d = new GfxDraw();

		debugText = new GfxDynamicTexture("mc/debugText");
	}

	~this()
	{
		assert(debugText is null);
	}

	void close()
	{
		sysReference(&debugText, null);
	}

	void render(GfxRenderTarget rt)
	{
		num_frames++;
		updateText();

		d.target = rt;
		d.start();
		int x = rt.width - debugText.width - 8 - 8 - 8;
		int y = 8;
		d.fill(Color4f(0, 0, 0, .8), true, x, y,
		       debugText.width+16, debugText.height+16);
		d.blit(debugText, x+8, y+8);

		d.stop();
	}

	void updateText()
	{
		auto elapsed = lib.sdl.sdl.SDL_GetTicks() - start;

		if (elapsed < stepLength)
			return;

		const float MB = 1024*1024;

		gcstats.GCStats stats;
		std.gc.getStats(stats);

		char[1024] tmp;
		char[] info = sformat(tmp,
			"Charge%7.1fFPS\n"
			"\n"
			"Memory:\n"
			"     C%7.1fMB\n"
			"     D%7.1fMB\n"
			"   Lua%7.1fMB\n"
			"   VBO%7.1fMB\n"
			" Chunk%7.1fMB\n"
			"\n"
			"GC:\n"
			"  used%7.1fMB\n"
			"  pool%7.1fMB\n"
			"  free%7.1fMB\n"
			" pages% 7s\n"
			"  free% 7s\n"
			"\n"
			"Time:",
			cast(float)num_frames / (cast(float)elapsed / 1000.0),
			MemHeader.getMemory() / MB,
			stats.usedsize / MB,
			lib.lua.state.State.getMemory() / MB,
			charge.gfx.vbo.VBO.used / MB,
			miners.terrain.chunk.Chunk.used_mem / MB,
			stats.usedsize / MB,
			stats.poolsize / MB,
			stats.freelistsize / MB,
			stats.pageblocks,
			stats.freeblocks);

		size_t pos = info.length;
		void callback(string name, double value) {
			auto ret = sformat(tmp[pos .. $], "\n% 6s %6.1f%%", name, value);
			pos += ret.length;
		}
		TimeTracker.calcAll(&callback);

		info = tmp[0 .. pos];

		assert(tmp.ptr == info.ptr);

		gfxDefaultFont.render(debugText, info);

		num_frames = 0;
		start = start + elapsed;
	}

	void logic() {}
	void assumeControl() {}
	void dropControl() {}
	void resize(uint w, uint h) {}
}
