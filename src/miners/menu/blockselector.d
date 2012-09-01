// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.blockselector;

import std.stdio;

import charge.charge;
import charge.game.gui.textbased;

import miners.options;
import miners.interfaces;
import miners.menu.base;
import miners.classic.data;

alias void delegate(ubyte) SelectedDg;

class ClassicBlockMenu : MenuRunnerBase
{
private:
	const string header = `Select Block`;
	SelectedDg selected;

public:
	this(Router r, Options opts, SelectedDg selected)
	{
		assert(selected !is null);

		this.selected = selected;
		this.r = r;

		auto mb = new MenuBase(header);
		auto cg = new ClassicGrid(mb, opts, 0, 0, &mySelected);
		mb.repack();

		super(r, opts, mb);
	}

	void close()
	{
		selected = null;
		super.close();
	}

private:
	void mySelected(ubyte block)
	{
		selected(block);
		r.deleteMe(this);
	}
}


private class ClassicGrid : Component
{
private:
	const colums = 8;
	const blockSize = 32;
	const tileEdge = 8;
	const tileSize = blockSize + tileEdge * 2;

	Options opts;
	ubyte[] blockIds;
	SelectedDg selected;


public:
	this(Container parent, Options opts, int x, int y, SelectedDg selected)
	{
		assert(selected !is null);

		int count;
		foreach (b; classicBlocks)
			count += b.placable;

		w = tileSize * colums;
		h = ((count / colums) + (count % colums == 0 ? 0 : 1)) * tileSize;

		super(parent, x, y, w, h);
		this.opts = opts;
		this.selected = selected;

		blockIds.length = count;

		count = 0;
		foreach (int i, b; classicBlocks) {
			if (!b.placable)
				continue;
			blockIds[count++] = cast(ubyte)i;
		}
	}


	void repack()
	{

	}


	void breakApart()
	{
		super.breakApart();
		selected = null;
	}


	void releaseResources()
	{

	}


	void paint(GfxDraw d)
	{
		int x;
		int y;

		foreach (int i, b; blockIds) {
			auto tex = opts.classicSides[b];

			d.blit(tex, Color4f.White, true,
			       0, 0, tex.width, tex.height,
			       x + tileEdge, y + tileEdge, blockSize, blockSize);

			if (i % 8 == 7) {
				y += tileSize;
				x = 0;
			} else {
				x += tileSize;
			}
		}
	}

	void mouseUp(Mouse m, int x, int y, uint button)
	{
		if (button != 1)
			return;

		x /= tileSize;
		y /= tileSize;

		int num = x + y * colums;

		if (num >= blockIds.length)
			return;

		selected(blockIds[num]);
	}
}
