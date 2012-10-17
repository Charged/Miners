// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Material.
 */
module charge.phy.material;

import charge.phy.actor;


class Material
{
public:
	float mu2;

	void delegate(Actor b1, Actor b2) collision;

	/* Returns the default material */
	static Material opCall() {
		return def;
	}

private:
	static this()
	{
		def = new Material();
	}

	static Material def;
}
