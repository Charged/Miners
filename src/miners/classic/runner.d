// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.runner;


import lib.sdl.keysym;

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
	ClassicMessageLog mlGui;
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

		chatDirty = true;
		chatGui = new ColorContainer(
			Color4f(0, 0, 0, 0.8),
			8 * 64 + 8 * 2,
			9 * ml.backlog + 8 * (2 + 2));
		mlGui = new ClassicMessageLog(chatGui, 8, 8, 20);
		auto spacer = new Text(chatGui, 8, mlGui.y+mlGui.h, chatSep);
		typedText = new Text(chatGui, 8, spacer.y+spacer.h, "");

		chatGui.repaintDg = &handleRepaint;
		console = new ClassicConsole(opts, &typedText.setText);

		if (c !is null) {
			console.chat = &c.sendClientMessage;
			console.message = &ml.archive;
			ml.message = &mlGui.message;
		} else {
			console.chat = &mlGui.message;
			console.message = &mlGui.message;
		}
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

		foreach(p; players) {
			if (p is null)
				continue;
			delete p;
		}	

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

		r.render(w.gfx, cam.current, rt);

		if (opts.hideUi())
			return;

		if (currentBlock != savedBlock) {
			placeText.setText(classicBlocks[currentBlock].name);
			savedBlock = currentBlock;
			placeGui.paint();
		}

		if (chatDirty) {
			chatGui.paint();
			chatDirty = false;
		}

		auto t = placeGui.texture;
		auto x = rt.width - t.width - 8;
		auto y = rt.height - t.height - 8;

		d.target = rt;
		d.start();
		d.blit(t, x, y);
		if (ml !is null || console.typing) {
			t = chatGui.texture;

			d.blit(t, 8, rt.height - t.height - 8);
		}
		d.stop();
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
		if (sym == 27) {
			if (console.typing)
				return console.stopTyping();
			else
				return r.menu.displayMainMenu();
		}

		if (console.typing)
			return console.keyDown(sym, unicode);

		// Start chatting when we press 't'.
		if (sym == 't')
			return console.startTyping();

		switch(sym) {
		case SDLK_w:
			m.forward = true;
			break;
		case SDLK_s:
			m.backward = true;
			break;
		case SDLK_a:
			m.left = true;
			break;
		case SDLK_d:
			m.right = true;
			break;
		case SDLK_LSHIFT:
			m.speed = true;
			break;
		case SDLK_SPACE:
			m.up = true;
			break;
		default:
		}
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		if (console.typing)
			return;

		switch(sym) {
		case SDLK_w:
			m.forward = false;
			break;
		case SDLK_s:
			m.backward = false;
			break;
		case SDLK_a:
			m.left = false;
			break;
		case SDLK_d:
			m.right = false;
			break;
		case SDLK_LSHIFT:
			m.speed = false;
			break;
		case SDLK_SPACE:
			m.up = false;
			break;
		case SDLK_g:
			if (!kb.ctrl)
				break;
			grab = !grab;
			break;
		case SDLK_o:
			Core().screenShot();
			break;
		case SDLK_F2:
			opts.hideUi.toggle;
			break;
		case SDLK_F3:
			opts.showDebug.toggle;
			break;
		default:
		}
	}

	void mouseDown(CtlMouse mouse, int button)
	{
		if (button == 4)
			return decBlock();
		if (button == 5)
			return incBlock();

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

		r.menu.displayError(["Disconencted", rs], false);
		r.deleteMe(this);
	}
}


/**
 * Classic version of the console, used for text input.
 */
class ClassicConsole : public Console
{
protected:
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
	bool validateChar(dchar unicode)
	{
		// Skip invalid characters.
		if (unicode < 0x20 ||
		    unicode > 0x7F ||
		    unicode == '&')
			return false;
		return true;
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
	this(Container c, int x, int y, uint rows)
	{
		super(c, x, y, 64, rows, 1);
	}

protected:
	void drawRow(GfxDraw d, int y, char[] row)
	{
		auto color = &colors[15];
		bool colorSelect;
		int k;

		foreach(c; row) {
			if (colorSelect) {
				colorSelect = false;
				int index = charToIndex(c);
				if (index >= 0) {
					color = &colors[index];
					continue;
				}
			} else if (c == '&') {
				colorSelect = true;
				continue;
			}

			d.blit(glyphs, *color, true,
				c*8, 0, 8, 8,
				k*8, y, 8, 8);
			k++;
		}
	}

	int charToIndex(char c)
	{
		if (c >= 'a' && c <= 'f')
			return c - 'a' + 10;
		if (c >= '0' && c <= '9')
			return c - '0';
		return -1;
	}

	const Color4f colors[16] = [
		Color4f( 32/255f,  32/255f,  32/255f, 1),
		Color4f( 45/255f, 100/255f, 200/255f, 1),
		Color4f( 50/255f, 126/255f,  54/255f, 1),
		Color4f(  0/255f, 170/255f, 170/255f, 1),
		Color4f(188/255f,  75/255f,  45/255f, 1),
		Color4f(172/255f,  56/255f, 172/255f, 1),
		Color4f(200/255f, 175/255f,  45/255f, 1),
		Color4f(180/255f, 180/255f, 200/255f, 1),
		Color4f(100/255f, 100/255f, 100/255f, 1),
		Color4f( 72/255f, 125/255f, 247/255f, 1),
		Color4f( 85/255f, 255/255f,  85/255f, 1),
		Color4f( 85/255f, 255/255f, 255/255f, 1),
		Color4f(255/255f,  85/255f,  85/255f, 1),
		Color4f(255/255f,  85/255f, 255/255f, 1),
		Color4f(255/255f, 255/255f,  85/255f, 1),
		Color4f.White,
	];
}
