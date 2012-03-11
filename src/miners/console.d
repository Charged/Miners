// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.console;


/**
 *
 */
class Console
{
public:
	alias void delegate(char[]) TextDg;

	bool typing;
	const typingCursor = 219;

	char[] typed; /**< Typed text. */
	char[] showing; /**< Text including the cursor. */

	TextDg doneTyping; /**< Called when we are done with the typing */

private:
	TextDg update;
	size_t maxChars;
	char[] typedBuffer;

public:
	this(TextDg update, size_t maxChars)
	{
		this.update = update;
		this.typedBuffer.length = maxChars;
	}

	void startTyping()
	{
		typing = true;
		incArrays();
	}

	void keyDown(int sym, dchar unicode)
	{
		// Enter, we are done typing.
		if (sym == 0x0D) {
			if (typed.length > 1 && doneTyping !is null)
				doneTyping(typed);

			typed = null;
			showing = null;
			typing = false;

			update("");
			return;
		}

		// Backspace, remove one character.
		if (sym == 0x08) {
			if (typed.length == 0)
				return;

			return decArrays();
		}

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

	bool validateChar(dchar unicode)
	{
		if (unicode == '\t' ||
		    unicode == '\n' ||
		    unicode > 0x7F ||
		    unicode == 0)
			return false;
		return true;
	}

private:
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


