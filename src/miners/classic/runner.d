// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.runner;

import charge.charge;
import charge.math.ints;
import charge.game.gui.text;
import charge.game.gui.textbased;

import miners.types;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.console;
import miners.gfx.selector;
import miners.actors.otherplayer;
import miners.classic.data;
import miners.classic.world;
import miners.classic.message;
import miners.classic.connection;
import miners.classic.interfaces;
import miners.importer.network;
import miners.importer.converter;


/**
 * Classic runner
 */
class ClassicRunner : public ViewerRunner, public ClientListener
{
private:
	mixin SysLogging;

protected:
	ClientConnection c;
	ClassicWorld w;

	OtherPlayer players[ubyte.max+1];

	int sentCounter;
	Point3d saveCamPos;
	double saveCamHeading;
	double saveCamPitch;

	MessageLogger ml;

	GfxDraw d;
	Selector sel;

	ColorContainer placeGui;

	int currentBlock;
	int savedBlock;


	Text placeText;
	ColorContainer chatGui;
	Text chatText;
	Text typedText;
	bool chatDirty;

	const chatSep = "----------------------------------------------------------------";

	ClassicConsole console;

public:
	this(Router r, Options opts)
	{
		if (w is null)
			w = new ClassicWorld(opts);

		super(r, opts, w);

		sel = new Selector(w.gfx);
		sel.show = true;
		sel.setBlock(0, 0, 0);

		savedBlock = -1;
		currentBlock = 1;

		d = new GfxDraw();
		placeGui = new ColorContainer(Color4f(0, 0, 0, 0.8), 8*16+8*2, 8*3);
		placeText = new Text(placeGui, 8, 8, classicBlocks[currentBlock].name);

		chatGui = new ColorContainer(Color4f(0, 0, 0, 0.8), 8*64+8*2, 8*(ml.backlog+2+2));
		chatText = new Text(chatGui, 8, 8, "");
		auto spacer = new Text(chatGui, 8, 8+ml.backlog*8, chatSep);
		typedText = new Text(chatGui, 8, spacer.y+8, "");

		chatGui.repaintDg = &handleRepaint;
		console = new ClassicConsole(&typedText.setText);

		if (c !is null)
			console.doneTyping = &c.sendClientMessage;
	}

	this(Router r, Options opts,
	     char[] filename)
	{
		w = new ClassicWorld(opts, filename);

		this(r, opts);
	}

	this(Router r, Options opts,
	     ClientConnection c, MessageLogger ml,
	     uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		this.c = c;
		this.ml = ml;
		this.w = new ClassicWorld(opts, xSize, ySize, zSize, data);
		this(r, opts);

		c.setListener(this);
	}

	~this()
	{
	}

	void close()
	{
		placeGui.breakApart();
		chatGui.breakApart();
		delete sel;

		if (c is null)
			return;

		c.shutdown();
		c.close();
		c.wait();
		delete c;
		c = null;
	}

	void logic()
	{
		super.logic();

		if (c is null)
			return;

		c.doPackets();

		if (!(sentCounter++ % 5)) {
			auto pos = cam.position;
			if (pos != saveCamPos ||
			    cam_heading != saveCamHeading ||
			    cam_pitch != saveCamPitch) {

				c.sendClientPlayerUpdate(pos.x,
							 pos.y,
							 pos.z,
							 cam_heading,
							 cam_pitch);

				saveCamPos = pos;
				saveCamHeading = cam_heading;
				saveCamPitch = cam_pitch;
			} else {
				sentCounter = 0;
			}
		}
	}

	void render(GfxRenderTarget rt)
	{
		placeSelector();

		super.render(rt);

		if (currentBlock != savedBlock) {
			placeText.setText(classicBlocks[currentBlock].name);
			savedBlock = currentBlock;
			placeGui.paint();
		}

		if (ml !is null && ml.dirty) {
			chatText.setText(ml.getAllMessages());
			ml.dirty = false;
		}

		if (chatDirty) {
			chatGui.paint();
			chatDirty = false;
		}

		auto t = placeGui.getTarget();
		auto x = rt.width - t.width - 8;
		auto y = rt.height - t.height - 8;

		d.target = rt;
		d.start();
		d.blit(t, x, y);
		if (ml !is null || console.typing) {
			t.dereference();
			t = null;
			t = chatGui.getTarget();

			d.blit(t, 8, rt.height - t.height - 8);
		}
		d.stop();

		t.dereference();
	}

	void placeSelector()
	{
		auto pos = cam.position;
		auto vec = cam.rotation.rotateHeading();

		sel.show = false;

		bool step(int x, int y, int z) {
			auto b = w.t[x, y, z];

			if (b.type == 0)
				return true;

			sel.show = true;
			sel.setBlock(x, y, z);

			return false;
		}

		stepDirection(pos, vec, 6, &step);
	}

	/**
	 * Called from chat gui when it wants be repainted.
	 */
	void handleRepaint()
	{
		chatDirty = true;
	}


	/*
	 *
	 * Input functions.
	 *
	 */


	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		if (console.typing)
			return console.keyDown(sym, unicode);

		// Start chatting when we press 't'.
		if (sym == 't')
			return console.startTyping();

		super.keyDown(kb, sym, unicode, str);
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		if (!console.typing)
			return super.keyUp(kb, sym);
	}

	void mouseDown(CtlMouse mouse, int button)
	{
		super.mouseDown(mouse, button);

		if (button == 4)
			return decBlock();
		if (button == 5)
			return incBlock();

		if ((button < 0 && button > 3) || !grabbed)
			return;

		int xLast, yLast, zLast;
		int numBlocks;

		bool stepPlace(int x, int y, int z) {
			auto b = w.t[x, y, z];

			numBlocks++;

			if (b.type == 0) {
				xLast = x;
				yLast = y;
				zLast = z;
				return true;
			}

			// Lets not replace the block the camera happens to be in.
			if (numBlocks <= 2)
				return false;

			convertClassicToBeta(cast(ubyte)currentBlock, b.type, b.meta);

			w.t[xLast, yLast, zLast] = b;
			w.t.markVolumeDirty(xLast, yLast, zLast, 1, 1, 1);
			w.t.resetBuild();

			if (c !is null)
				c.sendClientSetBlock(cast(short)xLast,
						     cast(short)yLast,
						     cast(short)zLast,
						     1, cast(ubyte)currentBlock);

			// We should only place one block.
			return false;
		}

		bool stepRemove(int x, int y, int z) {
			auto b = w.t[x, y, z];

			if (b.type == 0)
				return true;

			w.t[x, y, z] = Block();
			w.t.markVolumeDirty(x, y, z, 1, 1, 1);
			w.t.resetBuild();

			if (c !is null)
				c.sendClientSetBlock(cast(short)x,
						     cast(short)y,
						     cast(short)z,
						     0, cast(ubyte)currentBlock);

			// We should only remove one block.
			return false;
		}

		bool stepCopy(int x, int y, int z) {
			auto b = w.t[x, y, z];

			if (b.type == 0)
				return true;

			// See which block that match
			foreach(int i, info; classicBlocks) {
				if (b.type != info.type ||
				    b.meta != info.meta)
					continue;

				if (!info.placable)
					return false;

				currentBlock = i;

				return false;
			}

			return false;
		}

		auto pos = cam.position;
		auto vec = cam.rotation.rotateHeading();

		if (button == 3)
			stepDirection(pos, vec, 6, &stepPlace);
		else if (button == 1)
			stepDirection(pos, vec, 6, &stepRemove);
		else if (button == 2)
			stepDirection(pos, vec, 6, &stepCopy);

	}

	void incBlock()
	{
		currentBlock++;
		if (currentBlock >= classicBlocks.length)
			currentBlock = 0;
		if (!classicBlocks[currentBlock].placable)
			incBlock();
	}

	void decBlock()
	{
		currentBlock--;
		if (currentBlock < 0)
			currentBlock = classicBlocks.length-1;
		if (!classicBlocks[currentBlock].placable)
			decBlock();
	}


	/*
	 *
	 * Network functions.
	 *
	 */


	void ping()
	{
	}

	void indentification(ubyte ver, char[] name, char[] motd, ubyte type)
	{
		name = removeColorTags(name);
		motd = removeColorTags(motd);

		l.info("Connected:\n\t%s\n\t%s", name, motd);
	}

	void levelInitialize()
	{
		l.info("levelInitialize: Starting to load level");
	}

	void levelLoadUpdate(ubyte percent)
	{
	}

	void levelFinalize(uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		l.info("levelFinalize (%sx%sx%s) %s bytes", xSize, ySize, zSize, data.length);

		w.newLevelFromClassic(xSize, ySize, zSize, data);
	}

	void setBlock(short x, short y, short z, ubyte type)
	{
		Block block;

		convertClassicToBeta(type, block.type, block.meta);
		w.t[x, y, z] = block;
		w.t.markVolumeDirty(x, y, z, 1, 1, 1);
		w.t.resetBuild();
	}

	void playerSpawn(byte id, char[] name,
			 double x, double y, double z,
			 double heading, double pitch)
	{
		name = removeColorTags(name);

		auto index = cast(ubyte)id;

		// Skip this player.
		if (index == 255) {
			cam.position = Point3d(x, y, z);
			cam_heading = heading;
			cam_pitch = pitch;
			return;
		}

		// Should not happen, but we arn't trusting the servers.
		if (players[index] !is null)
			delete players[index];

		double offset = 52.0 / 32.0;
		auto pos = Point3d(x, y - offset, z);
		auto p = new OtherPlayer(w, index, pos, heading, pitch);
		players[index] = p;
	}

	/**
	 * AKA Teleport.
	 */
	void playerMoveTo(byte id, double x, double y, double z,
			  double heading, double pitch)
	{
		auto index = cast(ubyte)id;

		// Skip this player.
		if (index == 255) {
			cam.position = Point3d(x, y, z);
			cam_heading = heading;
			cam_pitch = pitch;
			return;
		}

		auto p = players[index];
		// Stray packets.
		if (p is null)
			return;

		// XXX Don't render the player model at all.
		//if (y == -1024)
		//	return;

		double offset = 52.0 / 32.0;
		auto pos = Point3d(x, y - offset, z);
		p.update(pos, heading, pitch);
	}

	void playerMove(byte id, double x, double y, double z,
			double heading, double pitch)
	{
		auto p = players[cast(ubyte)id];

		// Stray packets.
		if (p is null)
			return;

		auto pos = p.position + Vector3d(x, y, z);
		p.update(pos, heading, pitch);
	}

	void playerMove(byte id, double x, double y, double z)
	{
		auto p = players[cast(ubyte)id];

		// Stray packets.
		if (p is null)
			return;

		auto pos = p.position + Vector3d(x, y, z);
		p.update(pos, p.heading, p.pitch);
	}

	void playerMove(byte id, double heading, double pitch)
	{
		auto p = players[cast(ubyte)id];

		// Stray packets.
		if (p is null)
			return;

		auto pos = p.position;
		p.update(pos, heading, pitch);
	}

	void playerDespawn(byte id)
	{
		auto index = cast(ubyte)id;

		// Skip player.
		if (index == 255)
			return;

		delete players[index];
	}

	void playerType(ubyte type)
	{
		l.info("player type changed %s.", type);
	}

	void disconnect(char[] reason)
	{
		auto rs = removeColorTags(reason);

		l.info("Disconnected: \"%s\"", rs);

		r.displayError(["Disconencted", rs], false);
		r.deleteMe(this);
	}
}


/**
 * Classic version of the console, used for text input.
 */
class ClassicConsole : public Console
{

	this(TextDg update)
	{
		super(update, 64);
	}

	bool validateChar(dchar unicode)
	{
		// Skip invalid characters.
		if (unicode < 0x20 ||
		    unicode > 0x7F ||
		    unicode == '&')
			return false;
		return true;
	}
}
