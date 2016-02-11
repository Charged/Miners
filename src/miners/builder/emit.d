// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.emit;

import miners.builder.types;
import miners.builder.helpers;


/*
 * Regular quad emitters, takes ambient occlusion terms.
 */


void emitQuadAOXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		   ubyte texture, sideNormal normal)
{
	p.pack(p, x2, y1, z1, texture, aoBR, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
	p.pack(p, x2, y2, z1, texture, aoTR, normal, uvCoord.RIGHT, uvCoord.TOP);
	p.pack(p, x1, y2, z2, texture, aoTL, normal, uvCoord.LEFT, uvCoord.TOP);
	p.pack(p, x1, y1, z2, texture, aoBL, normal, uvCoord.LEFT, uvCoord.BOTTOM);
}

void emitQuadAOXZN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		   ubyte texture, sideNormal normal)
{
	p.pack(p, x1, y1, z2, texture, aoBR, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
	p.pack(p, x1, y2, z2, texture, aoTR, normal, uvCoord.RIGHT, uvCoord.TOP);
	p.pack(p, x2, y2, z1, texture, aoTL, normal, uvCoord.LEFT, uvCoord.TOP);
	p.pack(p, x2, y1, z1, texture, aoBL, normal, uvCoord.LEFT, uvCoord.BOTTOM);
}

void emitQuadAOYP(Packer *p, int x1, int x2, int y, int z1, int z2,
		  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		  ubyte texture, sideNormal normal)
{
	p.pack(p, x1, y, z1, texture, aoTL, normal, uvCoord.LEFT, uvCoord.TOP);
	p.pack(p, x1, y, z2, texture, aoBL, normal, uvCoord.LEFT, uvCoord.BOTTOM);
	p.pack(p, x2, y, z2, texture, aoBR, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
	p.pack(p, x2, y, z1, texture, aoTR, normal, uvCoord.RIGHT, uvCoord.TOP);
}

void emitQuadAOYN(Packer *p, int x1, int x2, int y, int z1, int z2,
		  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		  ubyte texture, sideNormal normal)
{
	p.pack(p, x1, y, z1, texture, aoTL, normal, uvCoord.LEFT, uvCoord.TOP);
	p.pack(p, x2, y, z1, texture, aoTR, normal, uvCoord.RIGHT, uvCoord.TOP);
	p.pack(p, x2, y, z2, texture, aoBR, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
	p.pack(p, x1, y, z2, texture, aoBL, normal, uvCoord.LEFT, uvCoord.BOTTOM);
}


/*
 * Quad emitter that generates manipulated coords.
 */


void emitQuadAOXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		   ubyte texture, sideNormal normal, uvManip manip)
{
	mixin UVManipulator!(manip);

	p.pack(p, x2, y1, z1, texture, aoBR, normal, uBR, vBR);
	p.pack(p, x2, y2, z1, texture, aoTR, normal, uTR, vTR);
	p.pack(p, x1, y2, z2, texture, aoTL, normal, uTL, vTL);
	p.pack(p, x1, y1, z2, texture, aoBL, normal, uBL, vBL);
}

void emitQuadAOXZN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		   ubyte texture, sideNormal normal, uvManip manip)
{
	mixin UVManipulator!(manip);

	p.pack(p, x1, y1, z2, texture, aoBR, normal, uBR, vBR);
	p.pack(p, x1, y2, z2, texture, aoTR, normal, uTR, vTR);
	p.pack(p, x2, y2, z1, texture, aoTL, normal, uTL, vTL);
	p.pack(p, x2, y1, z1, texture, aoBL, normal, uBL, vBL);
}

void emitQuadAOYP(Packer *p, int x1, int x2, int y, int z1, int z2,
		  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		  ubyte texture, sideNormal normal, uvManip manip)
{
	mixin UVManipulator!(manip);

	p.pack(p, x1, y, z1, texture, aoTL, normal, uTL, vTL);
	p.pack(p, x1, y, z2, texture, aoBL, normal, uBL, vBL);
	p.pack(p, x2, y, z2, texture, aoBR, normal, uBR, vBR);
	p.pack(p, x2, y, z1, texture, aoTR, normal, uTR, vTR);
}

void emitQuadAOYN(Packer *p, int x1, int x2, int y, int z1, int z2,
		  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		  ubyte texture, sideNormal normal, uvManip manip)
{
	mixin UVManipulator!(manip);

	p.pack(p, x1, y, z1, texture, aoTL, normal, uTL, vTL);
	p.pack(p, x2, y, z1, texture, aoTR, normal, uTR, vTR);
	p.pack(p, x2, y, z2, texture, aoBR, normal, uBR, vBR);
	p.pack(p, x1, y, z2, texture, aoBL, normal, uBL, vBL);
}


/*
 * Texture coords are mapped to positions, offseted and also manipulated.
 */


void emitQuadMappedUVAOXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal,
		int u_offset, int v_offset, uvManip manip)
{
	ushort[][] uv = genMappedManipUVsXZ(x1, x2, y1, y2, z1, z2, u_offset, v_offset, normal, manip);

	p.pack(p, x2, y1, z1, texture, aoBR, normal, uv[2][0], uv[2][1]);
	p.pack(p, x2, y2, z1, texture, aoTR, normal, uv[3][0], uv[3][1]);
	p.pack(p, x1, y2, z2, texture, aoTL, normal, uv[0][0], uv[0][1]);
	p.pack(p, x1, y1, z2, texture, aoBL, normal, uv[1][0], uv[1][1]);
}

void emitQuadMappedUVAOXZN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal,
		int u_offset, int v_offset, uvManip manip)
{
	ushort[][] uv = genMappedManipUVsXZ(x1, x2, y1, y2, z1, z2, u_offset, v_offset, normal, manip);

	p.pack(p, x1, y1, z2, texture, aoBR, normal, uv[2][0], uv[2][1]);
	p.pack(p, x1, y2, z2, texture, aoTR, normal, uv[3][0], uv[3][1]);
	p.pack(p, x2, y2, z1, texture, aoTL, normal, uv[0][0], uv[0][1]);
	p.pack(p, x2, y1, z1, texture, aoBL, normal, uv[1][0], uv[1][1]);
}

void emitQuadMappedUVAOYP(Packer *p, int x1, int x2, int y, int z1, int z2,
			  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			  ubyte texture, sideNormal normal,
			  int u_offset, int v_offset, uvManip manip)
{
	ushort[][] uv = genMappedManipUVsY(x1, x2, z1, z2, u_offset, v_offset, manip);

	p.pack(p, x1, y, z1, texture, aoTL, normal, uv[0][0], uv[0][1]);
	p.pack(p, x1, y, z2, texture, aoBL, normal, uv[1][0], uv[1][1]);
	p.pack(p, x2, y, z2, texture, aoBR, normal, uv[2][0], uv[2][1]);
	p.pack(p, x2, y, z1, texture, aoTR, normal, uv[3][0], uv[3][1]);
}

void emitQuadMappedUVAOYN(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal,
		int u_offset, int v_offset, uvManip manip)
{
	ushort[][] uv = genMappedManipUVsY(x1, x2, z1, z2, u_offset, v_offset, manip);

	p.pack(p, x1, y, z1, texture, aoTL, normal, uv[0][0], uv[0][1]);
	p.pack(p, x2, y, z1, texture, aoTR, normal, uv[3][0], uv[3][1]);
	p.pack(p, x2, y, z2, texture, aoBR, normal, uv[2][0], uv[2][1]);
	p.pack(p, x1, y, z2, texture, aoBL, normal, uv[1][0], uv[1][1]);
}


/*
 * Texture coords are mapped to positions and offseted.
 */


void emitQuadMappedUVAOXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal,
		int u_offset, int v_offset)
{
	emitQuadMappedUVAOXZP(p, x1, x2, y1, y2, z1, z2, aoBL, aoBR, aoTL, aoTR,
			texture, normal, u_offset, v_offset, uvManip.NONE);
}

void emitQuadMappedUVAOXZN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal,
		int u_offset, int v_offset)
{
	emitQuadMappedUVAOXZN(p, x1, x2, y1, y2, z1, z1, aoBL, aoBR, aoTL, aoTR,
			texture, normal, u_offset, v_offset, uvManip.NONE);
}

void emitQuadMappedUVAOYP(Packer *p, int x1, int x2, int y, int z1, int z2,
			  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			  ubyte texture, sideNormal normal,
			  int u_offset, int v_offset)
{
	emitQuadMappedUVAOYP(p, x1, x2, y, z1, z2, aoBL, aoBR, aoTL, aoTR,
			     texture, normal, u_offset, v_offset, uvManip.NONE);
}

void emitQuadMappedUVAOYN(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal,
		int u_offset, int v_offset)
{
	emitQuadMappedUVAOYN(p, x1, x2, y, z1, z2, aoBL, aoBR, aoTL, aoTR,
			texture, normal, u_offset, v_offset, uvManip.NONE);
}



void emitHalfQuadAOXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal)
{
	mixin UVManipulator!(uvManip.HALF_V);

	p.pack(p, x2, y1, z1, texture, aoBR, normal, uBR, vBR);
	p.pack(p, x2, y2, z1, texture, aoTR, normal, uTR, vTR);
	p.pack(p, x1, y2, z2, texture, aoTL, normal, uTL, vTL);
	p.pack(p, x1, y1, z2, texture, aoBL, normal, uBL, vBL);
}

void emitHalfQuadAOXZM(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal)
{
	mixin UVManipulator!(uvManip.HALF_V);

	p.pack(p, x1, y1, z2, texture, aoBR, normal, uBR, vBR);
	p.pack(p, x1, y2, z2, texture, aoTR, normal, uTR, vTR);
	p.pack(p, x2, y2, z1, texture, aoTL, normal, uTL, vTL);
	p.pack(p, x2, y1, z1, texture, aoBL, normal, uBL, vBL);
}

void emitQuadYP(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte tex, sideNormal normal)
{
	emitQuadAOYP(p, x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal);
}

void emitQuadYP(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte tex, sideNormal normal, uvManip manip)
{
	emitQuadAOYP(p, x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal, manip);
}

void emitQuadMappedUVYP(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte texture, sideNormal normal,
		int u_offset, int v_offset, uvManip manip)
{
	emitQuadMappedUVAOYP(p, x1, x2, y, z1, z2, 0, 0, 0, 0,
			texture, normal, u_offset, v_offset, manip);
}

void emitQuadMappedUVYP(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte texture, sideNormal normal)
{
	emitQuadMappedUVAOYP(p, x1, x2, y, z1, z2, 0, 0, 0, 0,
			texture, normal, 0, 0, uvManip.NONE);
}

void emitQuadYN(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte tex, sideNormal normal)
{
	emitQuadAOYN(p, x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal);
}

void emitQuadYN(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte tex, sideNormal normal, uvManip manip)
{
	emitQuadAOYN(p, x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal, manip);
}

void emitQuadMappedUVYN(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte texture, sideNormal normal,
		int u_offset, int v_offset, uvManip manip)
{
	emitQuadMappedUVAOYN(p, x1, x2, y, z1, z2, 0, 0, 0, 0,
			texture, normal, u_offset, v_offset, manip);
}

void emitQuadMappedUVYN(Packer *p, int x1, int x2, int y, int z1, int z2,
		ubyte texture, sideNormal normal)
{
	emitQuadMappedUVAOYN(p, x1, x2, y, z1, z2, 0, 0, 0, 0,
			texture, normal, 0, 0, uvManip.NONE);
}

void emitQuadXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte tex, sideNormal normal)
{
	emitQuadAOXZP(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal);
}

void emitQuadXZN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte tex, sideNormal normal)
{
	emitQuadAOXZN(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal);
}

void emitQuadXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte tex, sideNormal normal, uvManip manip)
{
	emitQuadAOXZP(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal, manip);
}

void emitQuadXZN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte tex, sideNormal normal, uvManip manip)
{
	emitQuadAOXZN(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal, manip);
}

void emitTiltedQuadXZP(Packer *p, int bx1, int bx2, int tx1, int tx2, int y1, int y2,
		int bz1, int bz2, int tz1, int tz2,
		ubyte tex, sideNormal normal)
{
	p.pack(p, bx2, y1, bz1, tex, 0, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
	p.pack(p, tx2, y2, tz1, tex, 0, normal, uvCoord.RIGHT, uvCoord.TOP);
	p.pack(p, tx1, y2, tz2, tex, 0, normal, uvCoord.LEFT, uvCoord.TOP);
	p.pack(p, bx1, y1, bz2, tex, 0, normal, uvCoord.LEFT, uvCoord.BOTTOM);
}

void emitTiltedQuadXZN(Packer *p, int bx1, int bx2, int tx1, int tx2, int y1, int y2,
		int bz1, int bz2, int tz1, int tz2,
		ubyte tex, sideNormal normal)
{
	p.pack(p, bx1, y1, bz2, tex, 0, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
	p.pack(p, tx1, y2, tz2, tex, 0, normal, uvCoord.RIGHT, uvCoord.TOP);
	p.pack(p, tx2, y2, tz1, tex, 0, normal, uvCoord.LEFT, uvCoord.TOP);
	p.pack(p, bx2, y1, bz1, tex, 0, normal, uvCoord.LEFT, uvCoord.BOTTOM);
}

void emitQuadMappedUVXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte tex, sideNormal normal,
		int u_offset, int v_offset, uvManip manip)
{
	emitQuadMappedUVAOXZP(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0,
			tex, normal, u_offset, v_offset, manip);
}

void emitQuadMappedUVXZN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte tex, sideNormal normal,
		int u_offset, int v_offset, uvManip manip)
{
	emitQuadMappedUVAOXZN(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0,
			tex, normal, u_offset, v_offset, manip);
}

void emitQuadMappedUVXZP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte tex, sideNormal normal)
{
	emitQuadMappedUVAOXZP(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0,
			tex, normal, 0, 0, uvManip.NONE);
}

void emitQuadMappedUVXZN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte tex, sideNormal normal)
{
	emitQuadMappedUVAOXZN(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0,
			tex, normal, 0, 0, uvManip.NONE);
}

void emitDiagonalQuads(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2, ubyte tex)
{
	emitQuadAOXZN(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, sideNormal.XNZN);
	emitQuadAOXZP(p, x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, sideNormal.XPZP);

	// We flip the z values to get the other two set of coords.
	emitQuadAOXZP(p, x1, x2, y1, y2, z2, z1, 0, 0, 0, 0, tex, sideNormal.XNZP);
	emitQuadAOXZN(p, x1, x2, y1, y2, z2, z1, 0, 0, 0, 0, tex, sideNormal.XPZN);
}

/*
   +--+
   |  |
   |  +--+
   | /   |
   |/    |
   o-----+
 */
void emitStairQuadsLP(Packer *p, int x1, int x3, int y1, int y3, int z1, int z3,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal)
{
	ubyte aoTC = cast(ubyte)((aoTL + aoTR)/2);
	ubyte aoMR = cast(ubyte)((aoBR + aoTR)/2);
	ubyte aoMC = cast(ubyte)((aoBL + aoTR)/2);

	int x2 = (x1 + x3)/2, y2 = (y1 + y3)/2, z2 = (z1 + z3)/2;

	p.pack(p, x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
	p.pack(p, x2, y3, z2, texture, aoTC, normal, uvCoord.CENTER, uvCoord.TOP);
	p.pack(p, x1, y3, z3, texture, aoTL, normal, uvCoord.LEFT,   uvCoord.TOP);
	p.pack(p, x1, y1, z3, texture, aoBL, normal, uvCoord.LEFT,   uvCoord.BOTTOM);

	p.pack(p, x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
	p.pack(p, x1, y1, z3, texture, aoBL, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
	p.pack(p, x3, y1, z1, texture, aoBR, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
	p.pack(p, x3, y2, z1, texture, aoMR, normal, uvCoord.RIGHT,  uvCoord.MIDDLE);
}

void emitStairQuadsLN(Packer *p, int x1, int x3, int y1, int y3, int z1, int z3,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal)
{
	ubyte aoTC = cast(ubyte)((aoTL + aoTR)/2);
	ubyte aoML = cast(ubyte)((aoBL + aoTL)/2);
	ubyte aoMC = cast(ubyte)((aoBL + aoTR)/2);

	int x2 = (x1 + x3)/2, y2 = (y1 + y3)/2, z2 = (z1 + z3)/2;

	p.pack(p, x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
	p.pack(p, x1, y1, z3, texture, aoBR, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
	p.pack(p, x1, y3, z3, texture, aoTR, normal, uvCoord.LEFT,   uvCoord.TOP);
	p.pack(p, x2, y3, z2, texture, aoTC, normal, uvCoord.CENTER, uvCoord.TOP);

	p.pack(p, x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
	p.pack(p, x3, y2, z1, texture, aoML, normal, uvCoord.RIGHT,  uvCoord.MIDDLE);
	p.pack(p, x3, y1, z1, texture, aoBL, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
	p.pack(p, x1, y1, z3, texture, aoBR, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
}

/*
   +--+
   |  |
   +--+  |
   |   \ |
   |    \|
   o-----+
 */
void emitStairQuadsRP(Packer *p, int x1, int x3, int y1, int y3, int z1, int z3,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal)
{
	ubyte aoTC = cast(ubyte)((aoTL + aoTR)/2);
	ubyte aoML = cast(ubyte)((aoBL + aoTL)/2);
	ubyte aoMC = cast(ubyte)((aoBL + aoTR)/2);

	int x2 = (x1 + x3)/2, y2 = (y1 + y3)/2, z2 = (z1 + z3)/2;

	p.pack(p, x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
	p.pack(p, x1, y2, z3, texture, aoML, normal, uvCoord.LEFT,   uvCoord.MIDDLE);
	p.pack(p, x1, y1, z3, texture, aoBL, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
	p.pack(p, x3, y1, z1, texture, aoBR, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);

	p.pack(p, x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
	p.pack(p, x3, y1, z1, texture, aoBR, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
	p.pack(p, x3, y3, z1, texture, aoTR, normal, uvCoord.RIGHT,  uvCoord.TOP);
	p.pack(p, x2, y3, z2, texture, aoTC, normal, uvCoord.CENTER, uvCoord.TOP);
}

void emitStairQuadsRN(Packer *p, int x1, int x3, int y1, int y3, int z1, int z3,
		ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
		ubyte texture, sideNormal normal)
{
	ubyte aoTC = cast(ubyte)((aoTL + aoTR)/2);
	ubyte aoMR = cast(ubyte)((aoBR + aoTR)/2);
	ubyte aoMC = cast(ubyte)((aoBL + aoTR)/2);

	int x2 = (x1 + x3)/2, y2 = (y1 + y3)/2, z2 = (z1 + z3)/2;

	p.pack(p, x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
	p.pack(p, x3, y1, z1, texture, aoBL, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
	p.pack(p, x1, y1, z3, texture, aoBR, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
	p.pack(p, x1, y2, z3, texture, aoMR, normal, uvCoord.LEFT,   uvCoord.MIDDLE);

	p.pack(p, x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
	p.pack(p, x2, y3, z2, texture, aoTC, normal, uvCoord.CENTER, uvCoord.TOP);
	p.pack(p, x3, y3, z1, texture, aoTL, normal, uvCoord.RIGHT,  uvCoord.TOP);
	p.pack(p, x3, y1, z1, texture, aoBL, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
}

void emitAscendingRailQuadYP(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte texture, sideNormal direction)
{
	// swap Y values if it ascends in the opposite direction
	if (direction == sideNormal.XN || direction == sideNormal.ZN) {
		int tmp = y1; y1 = y2; y2 = tmp;
	}

	if (direction == sideNormal.XP || direction == sideNormal.XN) {
		p.pack(p, x1, y1, z2, texture, 0, sideNormal.YP, uvCoord.LEFT, uvCoord.TOP);
		p.pack(p, x2, y2, z2, texture, 0, sideNormal.YP, uvCoord.LEFT, uvCoord.BOTTOM);
		p.pack(p, x2, y2, z1, texture, 0, sideNormal.YP, uvCoord.RIGHT, uvCoord.BOTTOM);
		p.pack(p, x1, y1, z1, texture, 0, sideNormal.YP, uvCoord.RIGHT, uvCoord.TOP);
	} else if (direction == sideNormal.ZP || direction == sideNormal.ZN) {
		p.pack(p, x2, y2, z2, texture, 0, sideNormal.YP, uvCoord.LEFT, uvCoord.TOP);
		p.pack(p, x2, y1, z1, texture, 0, sideNormal.YP, uvCoord.LEFT, uvCoord.BOTTOM);
		p.pack(p, x1, y1, z1, texture, 0, sideNormal.YP, uvCoord.RIGHT, uvCoord.BOTTOM);
		p.pack(p, x1, y2, z2, texture, 0, sideNormal.YP, uvCoord.RIGHT, uvCoord.TOP);
	}
}

void emitAscendingRailQuadYN(Packer *p, int x1, int x2, int y1, int y2, int z1, int z2,
		ubyte texture, sideNormal direction)
{
	// swap Y values if it ascends in the opposite direction
	if (direction == sideNormal.XN || direction == sideNormal.ZN) {
		int tmp = y1; y1 = y2; y2 = tmp;
	}

	if (direction == sideNormal.XP || direction == sideNormal.XN) {
		p.pack(p, x1, y1, z2, texture, 0, sideNormal.YN, uvCoord.LEFT, uvCoord.TOP);
		p.pack(p, x1, y1, z1, texture, 0, sideNormal.YN, uvCoord.RIGHT, uvCoord.TOP);
		p.pack(p, x2, y2, z1, texture, 0, sideNormal.YN, uvCoord.RIGHT, uvCoord.BOTTOM);
		p.pack(p, x2, y2, z2, texture, 0, sideNormal.YN, uvCoord.LEFT, uvCoord.BOTTOM);
	} else if (direction == sideNormal.ZP || direction == sideNormal.ZN) {
		p.pack(p, x2, y2, z2, texture, 0, sideNormal.YN, uvCoord.LEFT, uvCoord.TOP);
		p.pack(p, x1, y2, z2, texture, 0, sideNormal.YN, uvCoord.RIGHT, uvCoord.TOP);
		p.pack(p, x1, y1, z1, texture, 0, sideNormal.YN, uvCoord.RIGHT, uvCoord.BOTTOM);
		p.pack(p, x2, y1, z1, texture, 0, sideNormal.YN, uvCoord.LEFT, uvCoord.BOTTOM);
	}
}
