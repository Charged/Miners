// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.runner;

import std.string : format, find;
import std.math : PI, PI_2;

import lib.sdl.keysym;
import lib.gl.gl;

import charge.charge;
import charge.math.ints;
import charge.game.gui.text;
import charge.game.gui.textbased;

import miners.types;
import miners.runner;
import miners.options;
import miners.console;
import miners.interfaces;
import miners.gfx.selector;
import miners.actors.camera;
import miners.actors.sunlight;
import miners.classic.data;
import miners.classic.text;
import miners.classic.world;
import miners.classic.message;
import miners.classic.console;
import miners.classic.connection;
import miners.classic.interfaces;
import miners.classic.messagelog;
import miners.classic.otherplayer;
import miners.classic.playerphysics;
import miners.importer.network;


/**
 * Classic runner
 */
class ClassicRunner : GameRunnerBase, ClientListener
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

	// Mostly control admin-crate delete-ing.
	bool isAdmin;

	int chatBacklog;
	const int chatBorder = 4;
	const int chatBacklogSmall = 7;
	const int chatOffsetFromBottom = 32 + 8 + 8;

	Text spacer;
	TextureContainer chatGui;
	ClassicMessageLog mlGui;
	Text typedText;
	bool chatDirty;

	bool showPlayerList;

	TextureContainer chatGuiSmall;
	ClassicMessageLog mlGuiSmall;

	int mouseButtonCounter1;
	int mouseButtonCounter3;

	TextureContainer chatGuiCurrent;

	const chatSep = "----------------------------------------------------------------";

	ClassicConsole console;



	/* Light related */
	SunLight sl;
	double lightHeading;
	double lightPitch;
	bool lightMoveing;

	/* Camera related */
	Camera cam;
	double camHeading;
	double camPitch;
	bool camMoveing;

	/* Moves the camera */
	PlayerPhysics pp;


public:
	this(Router r, Options opts)
	{
		this.opts = opts;

		if (w is null)
			w = new ClassicWorld(opts);

		super(r, opts, w);

		// Camera defaults
		camHeading = 0.0;
		camPitch = 0.0;

		centerer = cam = new Camera(w);
		cam.position = w.spawn + Vector3d(0.5, 1.5, 0.5);

		centerMap();

		// Light defaults
		lightHeading = PI/3;
		lightPitch = -PI/6;

		sl = new SunLight(w);
		sl.gfx.diffuse = Color4f(200.0/255, 200.0/255, 200.0/255);
		sl.gfx.ambient = Color4f(65.0/255, 65.0/255, 65.0/255);
		sl.rotation = Quatd(lightHeading, lightPitch, 0);

		// Show which block is selected.
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

		auto bf = opts.classicFont();
		uint temp = chatBorder * 2 + bf.height * 2 + chatOffsetFromBottom;
		chatBacklog = (height - temp) / (bf.height + 1);

		chatDirty = true;
		mlGui = new ClassicMessageLog(null, opts, chatBorder, chatBorder, chatBacklog);
		spacer = new ClassicText(null, opts, chatBorder, mlGui.y+mlGui.h, chatSep);
		typedText = new ClassicText(null, opts, chatBorder, spacer.y+spacer.h, "");

		chatGui = new TextureContainer(
			mlGui.w + chatBorder * 2,
			mlGui.h + spacer.h + typedText.h + chatBorder * 2,
			Color4f(0, 0, 0, 0.2));
		chatGui.add(mlGui);
		chatGui.add(spacer);
		chatGui.add(typedText);
		chatGui.repaintDg = &handleRepaint;


		mlGuiSmall = new ClassicMessageLog(null, opts, chatBorder, chatBorder, chatBacklogSmall);
		chatGuiSmall = new TextureContainer(
			mlGuiSmall.w + chatBorder * 2,
			mlGuiSmall.h + chatBorder * 2,
			Color4f(0, 0, 0, 0));
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

	this(Router r, Options opts, string filename)
	{
		w = new ClassicWorld(opts, filename);

		this(r, opts);
	}

	this(Router r, Options opts,
	     Connection cc, uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		this.c = cast(ClientConnection)cc;
		this.ml = cast(MessageLogger)cc.getMessageListener();
		this.isAdmin = this.c.isAdmin;

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


	/*
	 *
	 * Runner functions.
	 *
	 */


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

		delete cam;
		delete sl;
		delete w;

		super.close();

		if (c is null)
			return;

		c.close();
		c = null;
	}

	void logic()
	{
		// Yay
		cam.position = pp.movePlayer(cam.position, camHeading);

		// From BaseRunner class.
		w.tick();
		centerMap();

		// Handle console repeat.
		if (console.typing)
			console.logic();

		// Handle remove repeat.
		if (mouseButtonCounter1 > 0) {
			mouseButtonCounter1++;
			if (mouseButtonCounter1 > 35) {
				doRemoveBlock();
				mouseButtonCounter1 = 20;
			}
		}

		// Handle placement repeat.
		if (mouseButtonCounter3 > 0) {
			mouseButtonCounter3++;
			if (mouseButtonCounter3 > 35) {
				doPlaceBlock();
				mouseButtonCounter3 = 20;
			}
		}

		if (c is null)
			return;

		c.doPackets();

		// Might have gotten a levelInitialize packet.
		if (c is null)
			return;

		if (!(sentCounter++ % 5)) {
			auto pos = cam.position;
			if (pos != saveCamPos ||
			    camHeading != saveCamHeading ||
			    camPitch != saveCamPitch) {

				c.sendClientPlayerUpdate(pos.x,
							 pos.y,
							 pos.z,
							 camHeading,
							 camPitch);

				saveCamPos = pos;
				saveCamHeading = camHeading,
				saveCamPitch = camPitch;
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

		if (showPlayerList)
			drawPlayerList();

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

	void resize(uint w, uint h)
	{
		cam.resize(w, h);
	}

	void dropControl()
	{
		stopMoving();
		super.dropControl();
	}

	bool grab(bool val)
	{
		if (val) {
			camMoveing = false;
			lightMoveing = false;
		}

		return super.grab(val);
	}

	bool grab()
	{
		return super.grab();
	}


	/*
	 *
	 * Helper functions.
	 *
	 */


	void stopMoving()
	{
		mouseButtonCounter1 = 0;
		mouseButtonCounter3 = 0;

		showPlayerList = false;

		pp.forward = false;
		pp.backward = false;
		pp.left = false;
		pp.right = false;
		pp.up = false;
		pp.down = false;
		pp.jump = false;
		pp.crouch = false;
		pp.run = false;
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

	void drawPlayerList()
	{
		auto f = opts.classicFont();

		int x = 8;
		int y = 8;
		int w = f.width * 64 + chatBorder * 2;
		int h = chatBorder * 2;
		foreach(p; players) {
			if (p is null)
				continue;
			h += f.height;
		}

		d.fill(Color4f(0, 0, 0, 0.2), true, x, y, w, h);

		x = 8 + chatBorder;
		y = 8 + chatBorder;
		foreach(p; players) {
			if (p is null)
				continue;
			f.draw(d, x, y, p.name);
			y += f.height;
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
			if (p is null || p.isHidden)
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
			uint height = t.height + borderSize * 2;

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
			auto info = &classicBlocks[b.type];

			if (!info.selectable)
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
		int i;
		foreach(b; slots) {
			if (b == block)
				break;
			i++;
		}

		// Swap places if the same
		if (i < slots.length)
			slots[i] = slots[currentSlot];

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
			if (console.typing) {
				grab = true;
				return console.stopTyping();
			} else if (c !is null && opts.playSessionCookie !is null) {
				return r.displayClassicPauseMenu(this);
			} else {
				return r.displayClassicPauseMenu(null);
			}
		}

		if (console.typing) {
			console.keyDown(kb, sym, unicode);
			if (!console.typing)
				grab = true;
			return;
		}

		if (unicode == '/') {
			// Start entering a command when we press '/'
			grab = false;
			console.startTyping();
			console.keyDown(kb, sym, unicode);
			stopMoving();
			return;
		}

		switch(sym) {
		case SDLK_g:
			if (kb.ctrl) {
				grab = !grab;
				break;
			}
			// Fallthrough
		default:
			keyBinding(kb, sym, true);
		}
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		if (console.typing) {
			console.keyUp(kb, sym);
			if (!console.typing)
				grab = true;
			return;
		}

		switch(sym) {
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
			pp.forward = keyDown;

		} else if (sym == opts.keyBackward) {
			pp.backward = keyDown;

		} else if (sym == opts.keyLeft) {
			pp.left = keyDown;

		} else if (sym == opts.keyRight) {
			pp.right = keyDown;

		} else if (sym == opts.keyCameraUp) {
			pp.up = keyDown;

		} else if (sym == opts.keyCameraDown) {
			pp.down = keyDown;

		} else if (sym == opts.keyJump) {
			pp.jump = keyDown;

		} else if (sym == opts.keyCrouch) {
			pp.crouch = keyDown;

		} else if (sym == opts.keyRun) {
			pp.run = keyDown;

		} else if (sym == opts.keyFlightMode) {
			// XXX Fix

		} else if (sym == opts.keyChat) {
			if (keyDown) {
				grab = false;
				console.startTyping();
				stopMoving();
			}
		} else if (sym == opts.keySelector) {
			if (keyDown)
				r.displayClassicBlockSelector(&selectedBlock);

		} else if (sym == opts.keyScreenshot) {
			if (keyDown)
				Core().screenShot();

		} else if (sym == opts.keyPlayerList) {
			showPlayerList = keyDown;

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
				camMoveing = true;
			if (button == 3)
				lightMoveing = true;
			return;
		}


		// XXX Custamizable buttons.
		if (button == 1) {
			mouseButtonCounter1 = 1;
			mouseButtonCounter3 = 0;
			doRemoveBlock();
		} else if (button == 2) {
			doCopyBlock();
		} else if (button == 3) {
			mouseButtonCounter1 = 0;
			mouseButtonCounter3 = 1;
			doPlaceBlock();
		}
	}

	void mouseUp(CtlMouse, int button)
	{
		// XXX Custamizable buttons.
		if (button == 1) {
			camMoveing = false;
			mouseButtonCounter1 = 0;
		} else if (button == 3) {
			lightMoveing = false;
			mouseButtonCounter3 = 0;
		}
	}

	void mouseMove(CtlMouse mouse, int ixrel, int iyrel)
	{
		if (camMoveing || (grabbed && !lightMoveing)) {
			double xrel = ixrel;
			double yrel = iyrel;

			if (grabbed) {
				camHeading += xrel / -500.0;
				camPitch += yrel / -500.0;
			} else {
				camHeading += xrel / 500.0;
				camPitch += yrel / 500.0;
			}

			if (camPitch < -PI_2) camPitch = -PI_2;
			if (camPitch >  PI_2) camPitch =  PI_2;

			cam.rotation = Quatd(camHeading, camPitch, 0);
		}

		if (lightMoveing) {
			double xrel = ixrel;
			double yrel = iyrel;
			lightHeading += xrel / 500.0;
			lightPitch += yrel / 500.0;
			sl.rotation = Quatd(lightHeading, lightPitch, 0);
		}
	}


	/*
	 *
	 * Block functions.
	 *
	 */


	/**
	 * Place a block of the type that is currently selected in the slot bar.
	 */
	void doPlaceBlock()
	{
		auto pos = cam.position;
		auto vec = cam.rotation.rotateHeading();

		// Checkfor Admin-crate.
		if (!isAdmin && slots[currentSlot] == 7)
			return;

		int xLast, yLast, zLast;
		int numBlocks;

		bool stepPlace(int x, int y, int z) {
			auto b = w.t[x, y, z];
			auto info = &classicBlocks[b.type];

			numBlocks++;

			if (!info.selectable) {
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

		stepDirection(pos, vec, 6, &stepPlace);
	}

	/**
	 * Removes the current looked at block.
	 */
	void doRemoveBlock()
	{
		auto pos = cam.position;
		auto vec = cam.rotation.rotateHeading();

		int xLast, yLast, zLast;
		int numBlocks;

		bool stepRemove(int x, int y, int z) {
			auto b = w.t[x, y, z];
			auto info = &classicBlocks[b.type];

			if (!info.selectable)
				return true;

			// Checkfor Admin-crate.
			if (!isAdmin && b.type == 7)
				return false;

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

		stepDirection(pos, vec, 6, &stepRemove);
	}

	/**
	 * Copies the block being looked at and updates the slot bar.
	 */
	void doCopyBlock()
	{
		auto pos = cam.position;
		auto vec = cam.rotation.rotateHeading();

		int xLast, yLast, zLast;
		int numBlocks;

		bool stepCopy(int x, int y, int z) {
			auto b = w.t[x, y, z];
			auto info = &classicBlocks[b.type];

			if (!info.selectable)
				return true;

			if (b.type >= classicBlocks.length)
				return false;

			if (!info.placable)
				return false;

			int i;
			foreach(block; slots) {
				if (block == b.type)
					break;
				i++;
			}

			if (i < slots.length)
				currentSlot = i;
			else
				slots[currentSlot] = b.type;

			return false;
		}

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

	void indentification(ubyte ver, string name, string motd, ubyte type)
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

	void playerSpawn(byte id, string name,
			 double x, double y, double z,
			 double heading, double pitch)
	{
		auto index = cast(ubyte)id;

		// Skip this player.
		if (index == 255) {
			cam.position = Point3d(x, y, z);
			cam.rotation = Quatd(heading, pitch, 0);
			camHeading = heading;
			camPitch = pitch;
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
			camHeading = heading;
			camPitch = pitch;
			return;
		}

		auto p = players[index];
		// Stray packets.
		if (p is null)
			return;

		// XXX Don't render the player model at all.
		if (y == -1024)
			p.isHidden = true;
		else
			p.isHidden = false;

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
		if (c !is null)
			isAdmin = c.isAdmin;
	}

	void disconnect(string reason)
	{
		auto rs = removeColorTags(reason);

		l.info("Disconnected: \"%s\"", rs);

		r.displayError(["Disconencted", rs], false);
		r.deleteMe(this);
	}
}
