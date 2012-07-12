// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.interfaces;

import charge.gfx.vbo : GfxVBO = VBO;
import miners.builder.workspace;


/**
 * Used to hide the details of how the mesh is being built.
 */
interface MeshBuilder
{
	WorkspaceData* getWorkspace();

	void putWorkspace(WorkspaceData *ws);

	void updateCompactMesh(GfxVBO vbos[], bool indexed,
	                       WorkspaceData *data,
	                       int xPos, int yPos, int zPos);
}
