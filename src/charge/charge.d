// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright at the bottom of this file (GPLv2 only).

/**
 * Source file that includes all of charge into one namespace.
 *
 * Also prefixing classes due to name collision.
 */
module charge.charge;


/*!
@mainpage
@section start Where to start looking
If you want to look up math related things look at the
@link Math Math group @endlink.
@n@n
For Charged Miners classic a good as place as any is the
@link miners.classic.scene.ClassicScene ClassicScene @endlink
@link src/miners/classic/scene.d [code] @endlink which holds most of the
gameplay logic for Charged Miners and links to the other parts of it.
*/

/*!
@defgroup Math Math related structs, classes and functions.

Charge uses a OpenGL based convetions for axis, so Y+ is up, X+ is right and
Z- is forward. For rotations the convention is to use Quatd to represent them,
which might be harder to understand in the beginning but has advantages over
other methods.
*/

/*!
@defgroup Resource The charge resource system.

All resources in charge are reference counted.
*/

public
{
	import charge.util.memory : cMemoryArray;
	import charge.util.properties : Properties;
	import charge.util.vector : Vector, VectorData;

	import charge.math.mesh : RigidMesh, RigidMeshBuilder;
	import charge.math.picture : Picture;
	import charge.math.color : Color4b, Color3f, Color4f;
	import charge.math.vector3d : Vector3d;
	import charge.math.point3d : Point3d;
	import charge.math.quatd : Quatd;
	import charge.math.movable : Movable, breakApartAndNull;
	import charge.math.matrix3x3d : Matrix3x3d;
	import charge.math.matrix4x4d : Matrix4x4d;

	import charge.core : Core, CoreOptions, coreFlag;

	import charge.net.all;
	import charge.gfx.all;
	import charge.sfx.all;
	import charge.phy.all;
	import charge.ctl.all;
	import charge.sys.all;
	import charge.game.all;
}

string licenseText = r"
Copyright © 2011, Jakob Bornecrantz.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation version 2 (GPLv2)
of the License only.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
";

import license;

static this() {
	licenseArray ~= licenseText;
}
