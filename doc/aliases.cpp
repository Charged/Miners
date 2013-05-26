// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright at the bottom of this file (GPLv2 only).

/*
 * These typedefs are here to work around Doxygen not understanding
 * d aliases at all.
 */
typedef charge::net::packet::Packet NetPacket;
typedef charge::net::packet::RealiblePacket RealiblePacket;
typedef charge::net::packet::UnrealiblePacket UnrealiblePacket;
typedef charge::net::packet::PacketInStream NetInStream;
typedef charge::net::packet::PacketOutStream NetOutStream;
typedef charge::net::client::Client NetClient;
typedef charge::net::server::Server NetServer;
typedef charge::net::threaded::ThreadedPacketQueue NetThreadedPacketQueue;
typedef charge::net::threaded::ThreadedTcpConnection NetThreadedTcpConnection;
typedef charge::net::http::HttpConnection NetHttpConnection;
typedef charge::net::http::ThreadedHttpConnection NetThreadedHttpConnection;
typedef charge::net::download::DownloadListener NetDownloadListener;
typedef charge::net::download::DownloadConnection NetDownloadConnection;
typedef charge::net::connection::Connection NetConnection;
typedef charge::net::connection::ConnectionListener NetConnectionListener;

typedef charge::sfx::sfx::sfxLoaded sfxLoaded;
typedef charge::sfx::buffer::Buffer SfxBuffer;
typedef charge::sfx::buffermanager::BufferManager SfxBufferManager;
typedef charge::sfx::listener::Listener SfxListener;
typedef charge::sfx::source::Source SfxSource;

typedef charge::gfx::gfx::gfxLoaded gfxLoaded;
typedef charge::gfx::vbo::VBO GfxVBO;
typedef charge::gfx::vbo::RigidMeshVBO GfxRigidMeshVBO;
typedef charge::gfx::cube::Cube GfxCube;
typedef charge::gfx::draw::Draw GfxDraw;
typedef charge::gfx::font::BitmapFont GfxBitmapFont;
typedef charge::gfx::font::BitmapFont::defaultFont gfxDefaultFont;
typedef charge::gfx::rigidmodel::RigidModel GfxRigidModel;
typedef charge::gfx::skeleton::Bone GfxSkeletonBone;
typedef charge::gfx::skeleton::SimpleSkeleton GfxSimpleSkeleton;
typedef charge::gfx::light::Light GfxLight;
typedef charge::gfx::light::SimpleLight GfxSimpleLight;
typedef charge::gfx::light::PointLight GfxPointLight;
typedef charge::gfx::light::SpotLight GfxSpotLight;
typedef charge::gfx::light::Fog GfxFog;
typedef charge::gfx::texture::Texture GfxTexture;
typedef charge::gfx::texture::ColorTexture GfxColorTexture;
typedef charge::gfx::texture::TextureArray GfxTextureArray;
typedef charge::gfx::texture::TextureTarget GfxTextureTarget;
typedef charge::gfx::texture::DynamicTexture GfxDynamicTexture;
typedef charge::gfx::texture::WrappedTexture GfxWrappedTexture;
typedef charge::gfx::material::Material GfxMaterial;
typedef charge::gfx::material::SimpleMaterial GfxSimpleMaterial;
typedef charge::gfx::material::MaterialManager GfxMaterialManager;
typedef charge::gfx::world::Actor GfxActor;
typedef charge::gfx::world::World GfxWorld;
typedef charge::gfx::camera::Camera GfxCamera;
typedef charge::gfx::camera::ProjCamera GfxProjCamera;
typedef charge::gfx::camera::OrthoCamera GfxOrthoCamera;
typedef charge::gfx::camera::IsoCamera GfxIsoCamera;
typedef charge::gfx::renderer::Renderer GfxRenderer;
typedef charge::gfx::fixed::FixedRenderer GfxFixedRenderer;
typedef charge::gfx::forward::ForwardRenderer GfxForwardRenderer;
typedef charge::gfx::deferred::DeferredRenderer GfxDeferredRenderer;
typedef charge::gfx::target::RenderTarget GfxRenderTarget;
typedef charge::gfx::target::DefaultTarget GfxDefaultTarget;
typedef charge::gfx::target::DoubleTarget GfxDoubleTarget;

typedef charge::phy::phy::phyLoaded phyLoaded;
typedef charge::phy::actor::Actor PhyActor;
typedef charge::phy::actor::Body PhyBody;
typedef charge::phy::actor::Static PhyStatic;
typedef charge::phy::material::Material PhyMaterial;
typedef charge::phy::geom::Geom PhyGeom;
typedef charge::phy::geom::GeomCube PhyGeomCube;
typedef charge::phy::geom::GeomSphere PhyGeomSphere;
typedef charge::phy::geom::GeomMesh PhyGeomMesh;
typedef charge::phy::cube::Cube PhyCube;
typedef charge::phy::sphere::Sphere PhySphere;
typedef charge::phy::car::Car PhyCar;
typedef charge::phy::world::World PhyWorld;

typedef charge::ctl::input::Input CtlInput;
typedef charge::ctl::input::Device CtlDevice;
typedef charge::ctl::input::Mouse CtlMouse;
typedef charge::ctl::input::Keyboard CtlKeyboard;
typedef charge::ctl::input::Joystick CtlJoystick;

typedef charge::sys::logger::Logger SysLogger;
typedef charge::sys::logger::Logging SysLogging;
typedef charge::sys::file::File SysFile;
typedef charge::sys::file::FileManager SysFileManager;
typedef charge::sys::file::ZipFile SysZipFile;
typedef charge::sys::resource::reference sysReference;
typedef charge::sys::resource::Pool SysPool;
typedef charge::sys::resource::Resource SysResource;

typedef charge::game::world::Ticker GameTicker;
typedef charge::game::world::Actor GameActor;
typedef charge::game::world::World GameWorld;
typedef charge::game::app::App GameApp;
typedef charge::game::app::SimpleApp GameSimpleApp;
typedef charge::game::lua::LuaState GameLuaState;
typedef charge::game::scene::app::SceneManagerApp GameSceneManagerApp;
typedef charge::game::scene::menu::MenuScene GameMenuScene;
typedef charge::game::scene::scene::Scene GameScene;
typedef charge::game::scene::scene::SceneManager GameSceneManager;
typedef charge::game::scene::update::UpdateScene GameUpdateScene;
typedef charge::game::scene::startup::Task GameTask;
typedef charge::game::scene::startup::StartupScene GameStartupScene;
typedef charge::game::scene::debugger::DebuggerScene GameDebuggerScene;
typedef charge::game::scene::background::BackgroundScene GameBackgroundScene;
typedef charge::game::movers::Mover GameMover;
typedef charge::game::movers::IsoCameraMover GameIsoCameraMover;
typedef charge::game::movers::ProjCameraMover GameProjCameraMover;
typedef charge::game::update::UpdateDownloader GameUpdateDownloader;
typedef charge::game::actors::car::Car GameCar;
typedef charge::game::actors::playerspawn::PlayerSpawn GamePlayerSpawn;
typedef charge::game::actors::primitive::Primitive GamePrimitive;
typedef charge::game::actors::primitive::Cube GameCube;
typedef charge::game::actors::primitive::Static GameStatic;
typedef charge::game::actors::primitive::StaticCube GameStaticCube;
typedef charge::game::actors::primitive::StaticRigid GameStaticRigid;

typedef charge::core::Core Core;
typedef charge::core::CoreOptions CoreOptions;
typedef charge::core::coreFlag coreFlag;
