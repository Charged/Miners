// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.all;

public
{
	static import charge.gfx.gfx;
	static import charge.gfx.vbo;
	static import charge.gfx.cube;
	static import charge.gfx.draw;
	static import charge.gfx.font;
	static import charge.gfx.rigidmodel;
	static import charge.gfx.skeleton;
	static import charge.gfx.light;
	static import charge.gfx.texture;
	static import charge.gfx.material;
	static import charge.gfx.world;
	static import charge.gfx.camera;
	static import charge.gfx.renderer;
}

alias charge.gfx.gfx.gfxLoaded gfxLoaded;
alias charge.gfx.vbo.VBO GfxVBO;
alias charge.gfx.vbo.RigidMeshVBO GfxRigidMeshVBO;
alias charge.gfx.cube.Cube GfxCube;
alias charge.gfx.draw.Draw GfxDraw;
alias charge.gfx.font.BitmapFont GfxBitmapFont;
alias charge.gfx.font.BitmapFont.defaultFont gfxDefaultFont;
alias charge.gfx.rigidmodel.RigidModel GfxRigidModel;
alias charge.gfx.skeleton.Bone GfxSkeletonBone;
alias charge.gfx.skeleton.SimpleSkeleton GfxSimpleSkeleton;
alias charge.gfx.light.Light GfxLight;
alias charge.gfx.light.SimpleLight GfxSimpleLight;
alias charge.gfx.light.PointLight GfxPointLight;
alias charge.gfx.light.SpotLight GfxSpotLight;
alias charge.gfx.light.Fog GfxFog;
alias charge.gfx.texture.Texture GfxTexture;
alias charge.gfx.texture.ColorTexture GfxColorTexture;
alias charge.gfx.texture.TextureArray GfxTextureArray;
alias charge.gfx.texture.TextureTarget GfxTextureTarget;
alias charge.gfx.texture.DynamicTexture GfxDynamicTexture;
alias charge.gfx.texture.WrappedTexture GfxWrappedTexture;
alias charge.gfx.material.Material GfxMaterial;
alias charge.gfx.material.SimpleMaterial GfxSimpleMaterial;
alias charge.gfx.material.MaterialManager GfxMaterialManager;
alias charge.gfx.world.Actor GfxActor;
alias charge.gfx.world.World GfxWorld;
alias charge.gfx.camera.Camera GfxCamera;
alias charge.gfx.camera.ProjCamera GfxProjCamera;
alias charge.gfx.camera.OrthoCamera GfxOrthoCamera;
alias charge.gfx.camera.IsoCamera GfxIsoCamera;
alias charge.gfx.renderer.Renderer GfxRenderer;
alias charge.gfx.forward.ForwardRenderer GfxForwardRenderer;
alias charge.gfx.deferred.DeferredRenderer GfxDeferredRenderer;
alias charge.gfx.target.RenderTarget GfxRenderTarget;
alias charge.gfx.target.DefaultTarget GfxDefaultTarget;
alias charge.gfx.target.DoubleTarget GfxDoubleTarget;
