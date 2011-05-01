// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sfx.buffer;

import charge.sfx.al;

class Buffer
{
private:
	ALuint buffer;

package:
	ALuint id()
	{
		return buffer;
	}

	this(ALuint id)
	{
		this.buffer = id;
	}

	~this()
	{
		alDeleteBuffers(1, &buffer);
	}

}
