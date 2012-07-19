// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.runner;

import std.string : format, find;

import lib.sdl.keysym;
import lib.gl.gl;

import charge.charge;
import charge.math.ints;
import charge.game.gui.text;
import charge.game.gui.textbased;
import charge.game.gui.messagelog;

import miners.types;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.console;
import miners.interfaces;
import miners.gfx.selector;
import miners.classic.data;
import miners.classic.world;
import miners.classic.message;
import miners.classic.connection;
import miners.classic.interfaces;
import miners.classic.otherplayer;
import miners.classic.playerphysics;
import miners.importer.network;


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

	int currentSlot;
	ubyte[9] slots;

	int chatBacklog;
	const int chatBorder = 4;
	const int chatBacklogSmall = 7;
	const int chatOffsetFromBottom = 32 + 8 + 8;

	Text spacer;
	ColorContainer chatGui;
	ClassicMessageLog mlGui;
	Text typedText;
	bool chatDirty;

	ColorContainer chatGuiSmall;
	ClassicMessageLog mlGuiSmall;


	ColorContainer chatGuiCurrent;

	const chatSep = "----------------------------------------------------------------";

	ClassicConsole console;

	PlayerPhysics pp;

public:
	this(Router r, Options opts)
	{
		if (w is null)
			w = new ClassicWorld(opts);

		super(r, opts, w);

		sel = new Selector(w.gfx);
		sel.show = true;
		sel.setBlock(0, 0, 0);

		currentSlot = 0;
		slots[0] = 1;
		slots[1] = 4;
		slots[2] = 45;
		slots[3] = 3;
		slots[4] = 5;
		slots[5] = 17;
		slots[6] = 18;
		slots[7] = 20;
		slots[8] = 44;

		d = new GfxDraw();

		uint width, height; bool fullscreen;
		Core().size(width, height, fullscreen);

		uint temp = chatBorder * 2 + gfxDefaultFont.height * 2 + chatOffsetFromBottom;
		chatBacklog = (height - temp) / (gfxDefaultFont.height + 1);

		chatDirty = true;
		mlGui = new ClassicMessageLog(null, opts, chatBorder, chatBorder, chatBacklog);
		spacer = new Text(null, chatBorder, mlGui.y+mlGui.h, chatSep);
		typedText = new Text(null, chatBorder, spacer.y+spacer.h, "", true);

		chatGui = new ColorContainer(
			Color4f(0, 0, 0, 0.2),
			mlGui.w + chatBorder * 2,
			mlGui.h + spacer.h + typedText.h + chatBorder * 2);
		chatGui.add(mlGui);
		chatGui.add(spacer);
		chatGui.add(typedText);
		chatGui.repaintDg = &handleRepaint;


		mlGuiSmall = new ClassicMessageLog(null, opts, chatBorder, chatBorder, chatBacklogSmall);
		chatGuiSmall = new ColorContainer(
			Color4f(0, 0, 0, 0.0),
			mlGuiSmall.w + chatBorder * 2,
			mlGuiSmall.h + chatBorder * 2);
		chatGuiSmall.add(mlGuiSmall);
		chatGuiSmall.repaintDg = &handleRepaint;

		console = new ClassicConsole(opts, &typedText.setText);

		if (c !is null) {
			console.chat = &c.sendClientMessage;
			console.message = &ml.archive;
			console.tabCompletePlayer = &ml.tabCompletePlayer;
		} else {
			players[0] = new OtherPlayer(w, 0, "&4Hero&9brine", w.spawn, 0, 0);

			ml = new MessageLogger();
			console.chat = &ml.archive;
			console.message = &ml.archive;
		}

		pp = new PlayerPhysics(&ppGetBlock);
	}

	this(Router r, Options opts,
	     char[] filename)
	{
		w = new ClassicWorld(opts, filename);

		this(r, opts);
	}

	this(Router r, Options opts,
	     Connection cc, uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		this.c = cast(ClientConnection)cc;
		this.ml = cast(MessageLogger)cc.getMessageListener();

		assert(this.c !is null);
		assert(this.ml !is null);

		this.c.setListener(this);

		this.w = new ClassicWorld(opts, xSize, ySize, zSize, data);
		this(r, opts);
	}

	~this()
	{
		assert(sel is null);
	}

	void close()
	{
		chatGui.breakApart();
		chatGuiSmall.breakApart();
		delete sel;

		foreach(p; players) {
			if (p is null)
				continue;
			delete p;
		}	

		if (ml !is null)
			ml.message = null;

		super.close();

		if (c is null)
			return;

		c.close();
		c = null;
	}

	void logic()
	{
		if (false) {
			m.tick();
		} else {
			cam.position = pp.movePlayer(cam.position, cam_heading);
		}

		// From BaseRunner class.
		w.tick();
		centerMap();

		// Handle console repeat.
		if (console.typing)
			console.logic();

		if (c is null)
			return;

		c.doPackets();

		// Might have gotten a levelInitialize packet.
		if (c is null)
			return;

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

		cam.resize(rt.width, rt.height);
		r.render(w.gfx, cam.current, rt);

		if (opts.hideUi())
			return;

		auto tmpChatGui = console.typing ? chatGui : chatGuiSmall;
		auto tmpMlGui = console.typing ? mlGui : mlGuiSmall;
		if (chatGuiCurrent !is tmpChatGui) {
			chatGuiCurrent = tmpChatGui;
			ml.message = &tmpMlGui.message;
			ml.pushAll();
		}

		if (chatDirty) {
			tmpChatGui.paintTexture();
			chatDirty = false;
		}

		// Start drawing the gui.
		d.target = rt;
		d.start();
		scope (exit)
			d.stop();

		auto cam = cast(GfxProjCamera)cam.current;
		if (cam !is null)
			drawPlayerNames(cam, rt);

		drawSlotBar(d, rt);

		// If a menu is shown don't draw chat or crosshair
		if (!inControl)
			return;

		GfxTexture t;
		int x;
		int y;

		uint offset = chatOffsetFromBottom +
			(console.typing ? 0 : spacer.h + typedText.h);
		t = tmpChatGui.texture;
		d.blit(t, 8, rt.height - t.height - offset);

		// Crosshair
		if (!console.typing) {
			auto w = rt.width / 2 - 5;
			auto h = rt.height / 2 - 5;

			glLogicOp(GL_INVERT);
			glEnable(GL_COLOR_LOGIC_OP);
			glBegin(GL_QUADS);
			glColor3f(1, 1, 1);
			glVertex2d(   w,  h+4);
			glVertex2d(   w,  h+6);
			glVertex2d(w+10,  h+6);
			glVertex2d(w+10,  h+4);
			glVertex2d( w+4,    h);
			glVertex2d( w+6,    h);
			glVertex2d( w+6, h+10);
			glVertex2d( w+4, h+10);
			glEnd();
			glDisable(GL_COLOR_LOGIC_OP);
			glLogicOp(GL_COPY);
		}
	}

	void drawSlotBar(GfxDraw d, GfxRenderTarget rt)
	{
		int blockSize = 32;
		int slotEdge = 4;
		int slotSize = blockSize + slotEdge * 2;
		int width = cast(int)slots.length * slotSize;
		int startX = rt.width / 2 - width / 2;
		int startY = rt.height - slotSize;
		int pos = startX;

		d.fill(Color4f(0, 0, 0, 0.8), true, startX, startY, width, slotSize);
		foreach (int i, slot; slots) {
			auto tex = opts.classicSides[slot];

			// Shouldn't happen.
			if (tex is null)
				continue;

			if (i == currentSlot) {
				d.fill(Color4f.White, false, pos, startY, slotSize, slotEdge);
				d.fill(Color4f.White, false, pos, startY + slotSize - slotEdge, slotSize, slotEdge);
				d.fill(Color4f.White, false, pos, startY, slotEdge, slotSize);
				d.fill(Color4f.White, false, pos + slotSize - slotEdge, startY, slotEdge, slotSize);
			}

			d.blit(tex, Color4f.White, true,
			       0, 0, tex.width, tex.height,
			       pos + slotEdge, startY + slotEdge, blockSize, blockSize);

			pos += slotSize;
		}
	}

	void drawPlayerNames(GfxProjCamera cam, GfxRenderTarget rt)
	{
		Matrix4x4d mat;
		cam.getMatrixFromGlobalToScreen(rt.width, rt.height, mat);

		struct Elm
		{
			int index;
			float dist;

			int opCmp(ref Elm l)
			{
				return typeid(float).compare(&dist, &l.dist);
			}
		}

		Elm[players.length] store;
		Elm[] list;
		int[players.length] xList;
		int[players.length] yList;

		// We need to sort the players according
		// to distance from camera.
		foreach(int i, p; players) {
			if (p is null)
				continue;

			auto pos = p.position;
			pos.y += 1.85;
			pos = mat / pos;

			if (pos.x < 0 || pos.x > rt.width ||
			    pos.y < 0 || pos.y > rt.height - 8 ||
			    pos.z < 0 || pos.z > 1)
				continue;

			store[list.length] = Elm(i, pos.z);
			list = store[0 .. list.length + 1];

			xList[i] = cast(int)pos.x;
			yList[i] = rt.height - cast(int)pos.y;
		}

		list.sort;

		foreach_reverse(ref e; list) {
			auto p = players[e.index];
			int x = xList[e.index];
			int y = yList[e.index];

			const int arrowSize = 4;
			const int borderSize = 2;

			auto t = p.text;
			uint width = t.width + borderSize * 2;
			uint height = gfxDefaultFont.height + borderSize * 2;

			int tX = x - width / 2;
			int tY = y - height - arrowSize;

			y = imax(height + arrowSize, y);

			tX = imin(imax(0, tX), rt.width - width);
			tY = imax(0, tY);

			d.fill(Color4f(0, 0, 0, 0.2), true, tX, tY, width, height);

			glBegin(GL_TRIANGLES);
			glVertex2d(x + .5, y);
			glVertex2d(x + arrowSize + 1, y - arrowSize);
			glVertex2d(x - arrowSize,     y - arrowSize);
			glEnd();

			d.blit(p.text, tX + borderSize, tY + borderSize);
		}
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
	 * The block selected menu has selected a block type.
	 */
	void selectedBlock(ubyte block)
	{
		slots[currentSlot] = block;
	}


	/**
	 * Called from chat gui when it wants be repainted.
	 */
	void handleRepaint()
	{
		chatDirty = true;
	}


	/**
	 * Callback for the PlayerPhysics to get a block.
	 */
	ubyte ppGetBlock(int x, int y, int z)
	{
		auto b = w.t[x, y, z];
		return b.type;
	}


	/*
	 *
	 * Input functions.
	 *
	 */


	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		if (sym == 27) {
			if (console.typing)
				return console.stopTyping();
			else
				return r.displayPauseMenu();
		}

		if (console.typing)
			return console.keyDown(sym, unicode);

		if (unicode == '/') {
			// Start entering a command when we press '/'
			console.startTyping();
			console.keyDown(sym, unicode);
			return;
		}

		keyBinding(kb, sym, true);
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		if (console.typing)
			return console.keyUp(sym);;

		switch(sym) {
		case SDLK_g:
			if (kb.ctrl)
				grab = !grab;
			else
				keyBinding(kb, sym, false);
			break;
		case SDLK_F2:
			opts.hideUi.toggle;
			break;
		case SDLK_F3:
			opts.showDebug.toggle;
			break;
		default:
			keyBinding(kb, sym, false);
		}
	}

	/**
	 * Handle both up and key down via the keyBindings work.
	 */
	void keyBinding(CtlKeyboard kb, int sym, bool keyDown)
	{
		if (sym == opts.keyForward) {
			m.forward = keyDown;
			pp.forward = keyDown;

		} else if (sym == opts.keyBackward) {
			m.backward = keyDown;
			pp.backward = keyDown;

		} else if (sym == opts.keyLeft) {
			m.left = keyDown;
			pp.left = keyDown;

		} else if (sym == opts.keyRight) {
			m.right = keyDown;
			pp.right = keyDown;

		} else if (sym == opts.keyCameraUp) {
			m.up = keyDown;
			pp.up = keyDown;

		} else if (sym == opts.keyCameraDown) {
			pp.down = keyDown;

		} else if (sym == opts.keyJump) {
			pp.jump = keyDown;

		} else if (sym == opts.keyCrouch) {
			pp.crouch = keyDown;

		} else if (sym == opts.keyRun) {
			m.speed = keyDown;
			pp.run = keyDown;

		} else if (sym == opts.keyFlightMode) {
			// XXX Fix

		} else if (sym == opts.keyChat) {
			if (keyDown)
				console.startTyping();

		} else if (sym == opts.keySelector) {
			if (keyDown)
				r.displayClassicBlockSelector(&selectedBlock);

		} else if (sym == opts.keyScreenshot) {
			if (keyDown)
				Core().screenShot();

		} else if (sym == opts.keySlot0) {
			currentSlot = 0;
		} else if (sym == opts.keySlot1) {
			currentSlot = 1;
		} else if (sym == opts.keySlot2) {
			currentSlot = 2;
		} else if (sym == opts.keySlot3) {
			currentSlot = 3;
		} else if (sym == opts.keySlot4) {
			currentSlot = 4;
		} else if (sym == opts.keySlot5) {
			currentSlot = 5;
		} else if (sym == opts.keySlot6) {
			currentSlot = 6;
		} else if (sym == opts.keySlot7) {
			currentSlot = 7;
		} else if (sym == opts.keySlot8) {
			currentSlot = 8;
		}
	}

	void mouseDown(CtlMouse mouse, int button)
	{
		if (button == 4) {
			currentSlot--;
			if (currentSlot < 0)
				currentSlot = slots.length - 1;
			return;
		}
		if (button == 5) {
			currentSlot++;
			if (currentSlot >= slots.length)
				currentSlot = 0;
			return;
		}

		if ((button < 0 && button > 3) || !grabbed) {
			if (button == 1)
				cam_moveing = true;
			if (button == 3)
				light_moveing = true;
			return;
		}

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

			auto cur = slots[currentSlot];
			w.t[xLast, yLast, zLast] = Block(cur, 0);
			w.t.markVolumeDirty(xLast, yLast, zLast, 1, 1, 1);
			w.t.resetBuild();

			if (c !is null)
				c.sendClientSetBlock(cast(short)xLast,
						     cast(short)yLast,
						     cast(short)zLast,
						     1, cur);

			// We should only place one block.
			return false;
		}

		bool stepRemove(int x, int y, int z) {
			auto b = w.t[x, y, z];

			if (b.type == 0)
				return true;

			auto cur = slots[currentSlot];
			w.t[x, y, z] = Block();
			w.t.markVolumeDirty(x, y, z, 1, 1, 1);
			w.t.resetBuild();

			if (c !is null)
				c.sendClientSetBlock(cast(short)x,
						     cast(short)y,
						     cast(short)z,
						     0, cur);

			// We should only remove one block.
			return false;
		}

		bool stepCopy(int x, int y, int z) {
			auto b = w.t[x, y, z];

			if (b.type == 0)
				return true;

			if (b.type >= classicBlocks.length)
				return false;

			auto info = classicBlocks[b.type];

			if (!info.placable)
				return false;

			slots[currentSlot] = b.type;

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

		auto tmp = c;
		c = null;
		ml.message = null;
		ml = null;

		r.deleteMe(this);

		r.classicWorldChange(tmp);
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
		w.t[x, y, z] = Block(type, 0);
		w.t.markVolumeDirty(x, y, z, 1, 1, 1);
		w.t.resetBuild();
	}

	void playerSpawn(byte id, char[] name,
			 double x, double y, double z,
			 double heading, double pitch)
	{
		auto index = cast(ubyte)id;

		// Skip this player.
		if (index == 255) {
			cam.position = Point3d(x, y, z);
			cam.rotation = Quatd(heading, pitch, 0);
			cam_heading = heading;
			cam_pitch = pitch;
			return;
		}

		// Should not happen, but we arn't trusting the servers.
		if (players[index] !is null)
			delete players[index];

		double offset = 52.0 / 32.0;
		auto pos = Point3d(x, y - offset, z);
		auto p = new OtherPlayer(w, index, name, pos, heading, pitch);
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
			cam.rotation = Quatd(heading, pitch, 0);
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
		players[index] = null;
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
public:
	char[] delegate(char[], char[]) tabCompletePlayer;
	char[] lastTabComplete;
	char[] tabCompleteText; //< what the user actually typed in

protected:
	MessageLogger ml;
	Options opts;
	const cmdPrefixStr = "/client ";

public:
	this(Options opts, TextDg update)
	{
		this.opts = opts;
		this.opts.useCmdPrefix ~= &usePrefix;
		usePrefix(this.opts.useCmdPrefix());

		super(update, 64);
	}

	void usePrefix(bool useIt = true)
	{
		cmdPrefix = useIt ? cmdPrefixStr : null;
	}

protected:
	void tabComplete()
	{
		if (tabCompletePlayer is null)
			return;

		char[] search;
		char[] tabbing;

		// If we completed last, remove what we added
		if (lastTabComplete !is null) {

			// Search on the tab complete text
			search = tabCompleteText;

			int i = cast(int)typed.length;
			// Find the first none whitespace
			foreach_reverse(c; typed) {
				if (c != ' ')
					break;
				i--;
			}

			// Find the first whitespace
			foreach_reverse(c; typed[0 .. i]) {
				if (c == ' ')
					break;
				i--;
			}

			// Make it remove what we added last time
			if (i != typed.length)
				tabbing = typed[i .. $];

		} else if (typed.length != 0) {

			int i = cast(int)typed.length;
			foreach_reverse(c; typed) {
				if (c == ' ')
					break;
				i--;
			}

			// Ends with space
			if (i != typed.length)
				tabbing = typed[i .. $];

			search = tabbing;
			tabCompleteText = tabbing.dup;
		}

		auto t = tabCompletePlayer(search, lastTabComplete);

		// Nothing found return.
		if (t is null)
			return;

		// tabCompletePlayer returns with color encoding.
		t = removeColorTags(t);

		// Save the last result
		lastTabComplete = t;

		// We do it this way so that all the arrays are
		// correctly matched, or we are apt to get it wrong.
		for(int k; k < tabbing.length; k++)
			decArrays();

		if (typed.length == 0)
			t = t ~ ": ";

		// See comment above.
		foreach(c; t) {
			// Don't add any more once the buffer is full.
			if (showing.length >= maxChars)
				return;

			incArrays();
			typed[$-1] = c;
		}
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

	void doUserInputed()
	{
		tabCompleteText = null;
		lastTabComplete = null;
	}

	void doCommand(char[][] cmds, char[] str)
	{
		switch(cmds[0]) {
		case "help":
			msgHelp();
			break;
		case "aa":
			opts.aa.toggle();
			doMessage(format("AA toggled (%s).", opts.aa()));
			break;
		case "say":
			auto i = find(str, "say") + 4;
			assert(i >= 4);

			if (i >= str.length)
				break;

			doChat(str[cast(size_t)i .. $].dup);
			break;
		case "fps":
			opts.showDebug.toggle();
			doMessage(format("FPS toggled (%s).", opts.showDebug()));
			break;
		case "fog":
			opts.fog.toggle();
			doMessage(format("Fog toggled (%s).", opts.fog()));
			break;
		case "hide":
			opts.hideUi.toggle();
			doMessage(format("UI toggled (%s).", opts.hideUi()));
			break;
		case "prefix":
			opts.useCmdPrefix.toggle();
			doMessage(format("Prefix toggled (%s).", opts.useCmdPrefix()));
			break;
		case "shadow":
			opts.shadow.toggle();
			doMessage(format("Shadows toggled (%s).", opts.shadow()));
			break;
		case "view":
			auto d = opts.viewDistance() * 2;
			if (d > 1024)
				d = 32;
			opts.viewDistance = d;
			doMessage(format("View distance changed (%s).", d));
			break;
		default:
			msgNoSuchCommand(cmds[0]);
		}
	}

	void msgHelp()
	{
		doMessage("&eCommands:");
		doMessage("&a  aa&e     - toggle anti-aliasing");
		doMessage("&a  say&e    - chat the following text");
		doMessage("&a  fog&e    - toggle fog rendering");
		doMessage("&a  fps&e    - toggle fps counter and debug info (&cF3&e)");
		doMessage("&a  hide&e   - toggle UI hide                    (&cF2&e)");
		doMessage("&a  view&e   - change view distance");
		doMessage("&a  prefix&e - toogle the command prefix &a" ~ cmdPrefixStr);
		doMessage("&a  shadow&e - toggle shadows");
	}

	void msgNoCommandGiven()
	{
		doMessage(format(
			"&eNo command given type &a%shelp", cmdPrefix));
	}

	void msgNoSuchCommand(char[] cmd)
	{
		doMessage(format(
			"&eUnknown command \"&c%s&e\" type &a%shelp",
			cmd, cmdPrefix));
	}
}

class ClassicMessageLog : public MessageLog
{
public:
	Options opts;


public:
	this(Container c, Options opts, int x, int y, uint rows)
	{
		this.opts = opts;
		super(c, x, y, 64, rows, 0, 1);
	}

	void makeResources()
	{
		sysReference(&bf, opts.classicFont());
	}


protected:
	void drawRow(GfxDraw d, int y, char[] row)
	{
		bf.draw(d, 0, y, row);
	}
}
