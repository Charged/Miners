// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.console;

import stdx.string : find;
import std.string : format;
import miners.console : Console;
import miners.options : Options;
import miners.importer.network : removeColorTags;


/**
 * Classic version of the console, used for text input.
 */
class ClassicConsole : Console
{
public:
	string delegate(string, string) tabCompletePlayer;
	string lastTabComplete;
	string tabCompleteText; //< what the user actually typed in

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
	override void tabComplete()
	{
		if (tabCompletePlayer is null)
			return;

		string search;
		string tabbing;

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

			search = tabbing.idup;
			tabCompleteText = search;
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

			incArrays(c);
		}
	}

	override bool validateChar(dchar unicode)
	{
		// Skip invalid characters.
		if (unicode < 0x20 ||
		    unicode > 0x7F ||
		    unicode == '&')
			return false;
		return true;
	}

	override void doUserInputed()
	{
		tabCompleteText = null;
		lastTabComplete = null;
	}

	override void doCommand(string[] cmds, string str)
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

			doChat(str[cast(size_t)i .. $]);
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

	override void msgHelp()
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

	override void msgNoCommandGiven()
	{
		doMessage(format(
			"&eNo command given type &a%shelp", cmdPrefix));
	}

	override void msgNoSuchCommand(string cmd)
	{
		doMessage(format(
			"&eUnknown command \"&c%s&e\" type &a%shelp",
			cmd, cmdPrefix));
	}
}
