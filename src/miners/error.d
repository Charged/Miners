// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.error;


/**
 * Used for signaling raising errors and turning on the Error menu.
 *
 * The text should be informative as to what actions the user can
 * do to help solve the error, worst case point him to the bugzilla.
 */
class GameException : Exception
{
public:
	Exception next;
	bool panic;

public:
	this(string text, Exception next, bool panic)
	{
		if (text is null)
			text = bugzilla;

		super(text);
		this.next = next;
		this.panic = panic;
	}

private:
	const string bugzilla =
`Charged Miners experienced some kind of problem, this isn't meant to happen.
Sorry about that, please file a bug in the Charge Miners issue tracker and
tell us what happened. Also please privode the Exception printout if shown.

            https://github.com/Wallbraker/Charged-Miners/issues`;
}
