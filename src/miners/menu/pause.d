// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.pause;

import charge.charge;
import charge.game.gui.layout;
import charge.game.gui.textbased;
import charge.platform.homefolder;

import miners.options;
import miners.interfaces;
import miners.menu.base;


class PauseMenu : public MenuRunnerBase
{
private:
	const string header = `Options`;
	const int minButtonWidth = 32;

	const aaOnText = "Aa: on";
	const aaOffText = "Aa: off";

	const fogOnText = "Fog: on";
	const fogOffText = "Fog: off";

	const shadowOnText = "Shadow: on";
	const shadowOffText = "Shadow: off";

	const fullscreenOnText = "Fullscreen: on";
	const fullscreenOffText = "Fullscreen: off";

	const otherPartText = "Part";
	const otherCloseText = "Close";

	const quitText = "Quit";

	const fullscreenInfoText = `
In order for the fullscreen option to take
effect you need to restart Charged-Miners.`;

	const spacerStr = "                                               ";

	Runner partRunner;

public:
	this(Router r, Options opts, Runner part)
	{
		this.partRunner = part;

		auto mb = new MenuBase(header);
		auto t = new Text(mb, 0, 0, spacerStr);
		auto b1 = new Button(mb, 0,           8, "", minButtonWidth);
		auto b2 = new Button(mb, 0, b1.y + b1.h, "", minButtonWidth);
		auto b3 = new Button(mb, 0, b2.y + b2.h, "", minButtonWidth);
		auto b4 = new Button(mb, 0, b3.y + b3.h, "", minButtonWidth);
		auto b5 = new Button(mb, 0, b4.y + b4.h, "", minButtonWidth);
		auto b6 = new Button(mb, 0, b5.y + b5.h, "", minButtonWidth);
		auto b7 = new Button(mb, 0, b6.y + b6.h + 16, "", minButtonWidth);

		auto lastButton = b7;
		int bY = lastButton.y + lastButton.h + 16;

		string otherText = part !is null ? otherPartText : otherCloseText;

		auto bQuit = new Button(mb, 0, bY, quitText, 8);
		auto bOther = new Button(mb, bY, bY, otherText, 8);

		bQuit.pressed ~= &quit;
		bOther.pressed ~= &other;

		mb.repack();

		auto center = mb.plane.w / 2;

		// Center the children
		foreach(c; mb.getChildren) {
			c.x = center - c.w/2;
		}

		// Place the buttons next to each other.
		bQuit.x = center - 8 - bQuit.w;
		bOther.x = center + 8;

		super(r, opts, mb);

		setAaText(b1); b1.pressed ~= &aa;
		setFogText(b2); b2.pressed ~= &fog;
		setShadowText(b3); b3.pressed ~= &shadow;
		setViewText(b4); b4.pressed ~= &view;
		setFovText(b5); b5.pressed ~= &fov;
		setFullscreenText(b6); b6.pressed ~= &fullscreen;

		b7.setText("Open textures & screenshots");
		b7.pressed ~= &openFolder;
	}

	void quit(Button b) { r.quit(); }

	void other(Button b)
	{
		if (partRunner !is null) {
			r.deleteMe(partRunner);
			r.displayClassicMenu();
		}

		r.deleteMe(this);
	}

	void view(Button b)
	{
		auto d = cast(int)opts.viewDistance() * 2;
		if (d > 2048)
			d = 32;
		opts.viewDistance = d;

		setViewText(b);
	}

	void setViewText(Button b)
	{
		string str;
		switch(cast(int)opts.viewDistance()) {
		case   32: str = "Distance: Tiny"; break;
		case   64: str = "Distance: Short"; break;
		case  128: str = "Distance: Medium"; break;
		case  256: str = "Distance: Far"; break;
		case  512: str = "Distance: Further"; break;
		case 1024: str = "Distance: Furthest"; break;
		case 2048: str = "Distance: Furthestest"; break;
		default:   str = "Distance: Unknown"; break;
		}
		b.setText(str, minButtonWidth);
	}

	void aa(Button b)
	{
		opts.aa.toggle();
		setAaText(b);
	}

	void setAaText(Button b)
	{
		b.setText(opts.aa() ? aaOnText : aaOffText, minButtonWidth);
	}

	void fov(Button b)
	{
		int fov = opts.fov();
		if (fov < 70)
			fov = 70;
		else if (fov < 120)
			fov = 120;
		else
			fov = 45;

		opts.fov = fov;
		setFovText(b);
	}

	void setFovText(Button b)
	{
		string str;
		switch(opts.fov()) {
		case  45: str = "Fov: Charged"; break;
		case  70: str = "Fov: Minecraft"; break;
		case 120: str = "Fov: Quake Pro"; break;
		default:  str = "Fov: Custom"; break;
		}
		b.setText(str, minButtonWidth);
	}

	void fog(Button b)
	{
		opts.fog.toggle();
		setFogText(b);
	}

	void setFogText(Button b)
	{
		b.setText(opts.fog() ? fogOnText : fogOffText, minButtonWidth);
	}

	void shadow(Button b)
	{
		opts.shadow.toggle();
		setShadowText(b);
	}

	void setShadowText(Button b)
	{
		b.setText(opts.shadow() ? shadowOnText : shadowOffText, minButtonWidth);
	}

	void fullscreen(Button b)
	{
		auto p = Core().properties;
		auto res = p.getBool("fullscreen", Core.defaultFullscreen);

		res = !res;
		p.add("fullscreen", res);

		r.displayInfo("Info", [fullscreenInfoText], "Ok", &r.displayPauseMenu);
		r.deleteMe(this);
	}

	void setFullscreenText(Button b)
	{
		auto p = Core().properties;
		auto r = p.getBool("fullscreen", Core.defaultFullscreen);
		b.setText(r ? fullscreenOnText : fullscreenOffText, minButtonWidth);
	}

	void openFolder(Button b)
	{
		version(Windows) {
			try {
				windowsOpenFolder();
			} catch (Exception e) {
				r.displayError(e, false);
				r.deleteMe(this);
			}
		} else {
			r.displayInfo("Sorry", [
				"Can't open the settings folder on this platform",
				chargeConfigFolder], "Ok", &r.displayPauseMenu);
			r.deleteMe(this);
		}
	}
}

version(Windows)
{
	void windowsOpenFolder()
	{
		bool bRet;
		uint uRet;
		STARTUPINFO si;
		PROCESS_INFORMATION pi;

		si.cb = cast(uint)si.sizeof;

		auto cmd = "explorer.exe \"" ~ chargeConfigFolder ~ "\"\0";

		bRet = CreateProcessA(
			null,
			cmd.ptr,
			null,
			null,
			false,
			0,
			null,
			null,
			&si,
			&pi);

		if (!bRet)
			throw new Exception("Failed to show folder");

		scope(exit) {
			CloseHandle(pi.hProcess);
			CloseHandle(pi.hThread);
		}
	}

	struct STARTUPINFO {
		uint  cb;
		void* lpReserved;
		void* lpDesktop;
		void* lpTitle;
		uint  dwX;
		uint  dwY;
		uint  dwXSize;
		uint  dwYSize;
		uint  dwXCountChars;
		uint  dwYCountChars;
		uint  dwFillAttribute;
		uint  dwFlags;
		short wShowWindow;
		short cbReserved2;
		void* lpReserved2;
		void* hStdInput;
		void* hStdOutput;
		void* hStdError;
	}

	struct PROCESS_INFORMATION {
		void* hProcess;
		void* hThread;
		uint dwProcessId;
		uint dwThreadId;
	}

	extern(System) bool CreateProcessA(
		char* lpApplicationName,
		char* lpCommandLine,
		void* lpProcessAttributes,
		void* lpThreadAttributes,
		bool bInheritHandles,
		uint dwCreationFlags,
		void* lpEnvironment,
		void* lpCurrentDirectory,
		STARTUPINFO* lpStartupInfo,
		PROCESS_INFORMATION* lpProcessInformation
	);

	extern(System) uint WaitForSingleObject(
		void* hHandle,
		uint dwMilliseconds,
	);

	extern(System) bool GetExitCodeProcess(
		void* hHandle,
		uint* lpDword
	);

	extern(System) bool CloseHandle(
		void* hHandle
	);
}
