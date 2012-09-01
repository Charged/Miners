// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.console;

import std.string : split, format, find;
import charge.core : Core;
import charge.ctl.keyboard : CtlKeyboard = Keyboard;


/**
 * A helper class that is the text input part of a console.
 */
class Console
{
public:
	alias void delegate(string) TextDg;

	bool typing;
	const typingCursor = 219;
	size_t maxChars;

	char[] typed; /**< Typed text. */
	char[] showing; /**< Text including the cursor. */

	/**
	 * Command prefix, this is subtracted from all input when doing
	 * command processing. If the input doesn't start with the prefix
	 * the input is treated as chat.
	 *
	 * If cmdPrefix is null all input is regarded as commands.
	 */
	string cmdPrefix;

	TextDg message; /**< The console wants to put something on the backlog. */
	TextDg chat; /**< Called when something was chatted. */

private:
	uint backspaceCounter;
	TextDg update;
	char[] typedBuffer;

public:
	this(TextDg update, size_t maxChars)
	{
		assert(maxChars >= 2);
		assert(update !is null);

		this.maxChars = maxChars;
		this.update = update;
		this.typedBuffer.length = maxChars;
	}

	void logic()
	{
		if (backspaceCounter > 0) {
			backspaceCounter++;

			if (backspaceCounter >= 30) {
				backspaceCounter -= 5;
				keyDown(null, 0x08, 0);
			}
		}
	}

	void startTyping()
	{
		typing = true;
		incArrays();
	}

	void stopTyping()
	{
		typed = null;
		showing = null;
		typing = false;
		backspaceCounter = 0;

		doUserInputed();

		update("");
	}

	void keyDown(CtlKeyboard kb, int sym, dchar unicode)
	{
		// Something else on other systems.
		if (isPasteShortcut(kb, sym, unicode)) {

			auto str = Core().getClipboardText();

			foreach(c; str) {
				if (c == '\n' ||
				    c == '\r')
					break;

				keyDown(null, 0, c);
			}

			return;
		}

		// Enter, we are done typing.
		if (sym == 0x0D) {
			if (typed.length > 0)
				process(typed);
			return stopTyping();
		}

		// Backspace, remove one character.
		if (sym == 0x08) {
			if (typed.length == 0)
				return;

			if (backspaceCounter <= 0)
				backspaceCounter = 1;

			doUserInputed();

			return decArrays();
		}

		// I'm sure there is somebody out there that
		// has tab bound to something else then the
		// tab button and whats to use it.
		if (unicode == '\t')
			return tabComplete();

		// Some chars don't display that well,
		// Also ClassicConsole override this to
		// to be even more restrictive.
		if (!validateChar(unicode))
			return;

		// Don't add any more once the buffer is full.
		if (showing.length >= typedBuffer.length)
			return;

		doUserInputed();

		incArrays();
		typed[$-1] = cast(char)unicode;
	}

	void keyUp(CtlKeyboard kb, uint sym)
	{
		if (sym == 0x08)
			backspaceCounter = 0;
	}

protected:
	bool isPasteShortcut(CtlKeyboard kb, int sym, dchar unicode)
	{
		if (kb is null)
			return false;

		version (Windows)
			if (kb.ctrl && sym == 'v')
				return true;

		return false;
	}

	bool validateChar(dchar unicode)
	{
		if (unicode == '\t' ||
		    unicode == '\n' ||
		    unicode > 0x7F ||
		    unicode == 0)
			return false;
		return true;
	}

	abstract void tabComplete();

	void process(in char[] str)
	{
		char[] findStr;

		// If the command prefix ends with a space,
		// only search for the command without the space.
		if (cmdPrefix.length > 0) {
			if (cmdPrefix[$-1] == ' ')
				findStr = cmdPrefix[0 .. $-1];
			else
				findStr = cmdPrefix;

			// Only a command if we find the command prefix first.
			if (find(str, findStr) != 0)
				return doChat(str.dup);

			// Remove the prefix
			str = str[findStr.length .. $];
		}

		auto cmds = split(str);

		// Hit the user over the head.
		if (cmds.length == 0)
			return msgNoCommandGiven();

		doCommand(cmds, str);
	}

	void doUserInputed()
	{

	}

	void doCommand(char[][] cmds, char[] str)
	{
		if (cmds[0] == "help")
			return msgHelp();
		msgNoSuchCommand(cmds[0]);
	}

	final void doMessage(char[] str)
	{
		if (message !is null)
			message(str.dup);
	}

	final void doChat(char[] str)
	{
		if (chat !is null)
			chat(str.dup);
	}

	void msgNoCommandGiven()
	{
		doMessage(format("No command given type %shelp", cmdPrefix));
	}

	void msgNoSuchCommand(char[] cmd)
	{
		doMessage(format(
			"Unknown command \"%s\" type %shelp",
			cmd, cmdPrefix));
	}

	void msgHelp()
	{
		doMessage("Commands:");
		doMessage("   help - show help message");
	}

protected:
	void incArrays()
	{
		showing = typedBuffer[0 .. showing.length + 1];
		showing[$-1] = typingCursor;
		typed = showing[0 .. $-1];

		update(showing);
	}

	void decArrays()
	{
		showing = typedBuffer[0 .. showing.length - 1];
		showing[$-1] = typingCursor;
		typed = showing[0 .. $-1];

		update(showing);
	}
}
