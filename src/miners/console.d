// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.console;

import std.string : split, format, find;


/**
 * A helper class that is the text input part of a console.
 */
class Console
{
public:
	alias void delegate(char[]) TextDg;

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
	char[] cmdPrefix;

	TextDg message; /**< The console wants to put something on the backlog. */
	TextDg chat; /**< Called when something was chatted. */

private:
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

		update("");
	}

	void keyDown(int sym, dchar unicode)
	{
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

		incArrays();
		typed[$-1] = cast(char)unicode;
	}

protected:
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

	void process(char[] str)
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

	void doCommand(char[][] cmds, char[] str)
	{
		if (cmds[0] == "help")
			return msgHelp();
		msgNoSuchCommand(cmds[0]);
	}

	final void doMessage(char[] str)
	{
		if (message !is null)
			message(str);
	}

	final void doChat(char[] str)
	{
		if (chat !is null)
			chat(str);
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
