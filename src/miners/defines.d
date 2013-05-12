// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.defines;


/**
 * The dimensions of the Mesh/VBOs, only the GFX part. Not chunks as they
 * are stored in the map format.
 */
const int BuildWidth = 16;
const int BuildHeight = 16;
const int BuildDepth = 16;

/**
 * The number of meshes that are built.
 */
const int BuildMeshes = 2;


/**
 * Whered borrowed textures go.
 */
const string borrowedPath = "borrowed/";

/**
 * Where the borrowed modern terrain.png is saved.
 */
const string borrowedModernTerrainTexture = borrowedPath ~ "terrain.png";

/**
 * Where the borrowed classic terrain.png is saved.
 */
const string borrowedClassicTerrainTexture = borrowedPath ~ "terrain.classic.png";

/**
 * Where the downloaded default classic terrain.png is saved.
 */
const string defaultClassicTerrainTexture = "terrain.default.png";
