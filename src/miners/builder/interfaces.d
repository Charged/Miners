// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.interfaces;

import miners.gfx.vbo;
import miners.builder.workspace;


/**
 * Used to hide the details of how the mesh is being built.
 */
interface MeshBuilder
{
	WorkspaceData* getWorkspace();

	void putWorkspace(WorkspaceData *ws);

	void update(ChunkVBOCompactMesh vbos[], bool indexed,
	            WorkspaceData *data,
	            int xPos, int yPos, int zPos);
}
