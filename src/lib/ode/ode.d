// Hand written file.
// See copyright at the bottom of this file.
module lib.ode.ode;

import lib.loader;

public:
import lib.ode.common;
import lib.ode.mass;
import lib.ode.contact;
import lib.ode.objects;
import lib.ode.collision;
import lib.ode.collision_trimesh;
import lib.ode.space;
import lib.ode.init;

version(DynamicODE)
{
void loadODE(Loader l)
{
	loadODE_Objects(l);
	loadODE_Mass(l);
	loadODE_Collision(l);
	loadODE_CollisionTrimesh(l);
	loadODE_Space(l);
	loadODE_Common(l);
	loadODE_Init(l);
}
}

char[] licenseText = `
Open Dynamics Engine
Copyright (c) 2001-2007, Russell L. Smith. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

Neither the names of ODE's copyright owner nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
`;

import license;

static this()
{
	licenseArray ~= licenseText;
}
