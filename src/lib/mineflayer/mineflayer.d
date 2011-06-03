// File based on header in mineflayer library.
// See copyright at the bottom of this file.
module lib.mineflayer.mineflayer;

import lib.loader;

extern (C):

alias char mineflayer_bool;

enum
{
	mineflayer_ForwardControl,
	mineflayer_BackControl,
	mineflayer_LeftControl,
	mineflayer_RightControl,
	mineflayer_JumpControl,
	mineflayer_CrouchControl,
	mineflayer_DiscardItemControl,
	mineflayer_ControlCount,
}
alias int mineflayer_Control;

enum
{
	mineflayer_BlockBrokenReason,
	mineflayer_AbortedReason,
}
alias int mineflayer_StoppedDiggingReason;

enum
{
	mineflayer_NamedPlayerEntity = 1,
	mineflayer_MobEntity = 3,
	mineflayer_PickupEntity,
}
alias int mineflayer_EntityType;

enum
{
	mineflayer_NoAnimation,
	mineflayer_SwingArmAnimation,
	mineflayer_DamageAnimation,
	mineflayer_CrouchAnimation = 104,
	mineflayer_UncrouchAnimation,
	mineflayer_DeathAnimation = 55061,
}
alias int mineflayer_AnimationType;

enum
{
	mineflayer_DisconnectedStatus,
	mineflayer_ConnectingStatus,
	mineflayer_WaitingForHandshakeResponseStatus,
	mineflayer_WaitingForSessionIdStatus,
	mineflayer_WaitingForNameVerificationStatus,
	mineflayer_WaitingForLoginResponseStatus,
	mineflayer_SuccessStatus,
	mineflayer_SocketErrorStatus,
}
alias int mineflayer_LoginStatus;

enum
{
	mineflayer_InventoryWindow = -1,
	mineflayer_ChestWindow,
	mineflayer_CraftingTableWindow,
	mineflayer_FurnaceWindow,
	mineflayer_DispenserWindow,
}
alias int mineflayer_WindowType;

enum
{
	mineflayer_NoDirection = -1,
	mineflayer_NegativeY,
	mineflayer_PositiveY,
	mineflayer_NegativeZ,
	mineflayer_PositiveZ,
	mineflayer_NegativeX,
	mineflayer_PositiveX,
}
alias int mineflayer_BlockFaceDirection;

enum
{
	mineflayer_NormalDimension,
	minefalyer_NetherDimension = -1,
}
alias int mineflayer_Dimension;

enum
{
	mineflayer_NoItem = -1,
	mineflayer_AirItem,
	mineflayer_StoneItem,
	mineflayer_GrassItem,
	mineflayer_DirtItem,
	mineflayer_CobblestoneItem,
	mineflayer_WoodenPlankItem,
	mineflayer_SaplingItem,
	mineflayer_BedrockItem,
	mineflayer_WaterItem,
	mineflayer_StationaryWaterItem,
	mineflayer_LavaItem,
	mineflayer_StationaryLavaItem,
	mineflayer_SandItem,
	mineflayer_GravelItem,
	mineflayer_GoldOreItem,
	mineflayer_IronOreItem,
	mineflayer_CoalOreItem,
	mineflayer_WoodItem,
	mineflayer_LeavesItem,
	mineflayer_SpongeItem,
	mineflayer_GlassItem,
	mineflayer_LapisLazuliOreItem,
	mineflayer_LapisLazuliBlockItem,
	mineflayer_DispenserItem,
	mineflayer_SandstoneItem,
	mineflayer_NoteBlockItem,
	mineflayer_Bed_placedItem,
	mineflayer_WoolItem = 35,
	mineflayer_YellowFlowerItem = 37,
	mineflayer_RedRoseItem,
	mineflayer_BrownMushroomItem,
	mineflayer_RedMushroomItem,
	mineflayer_GoldBlockItem,
	mineflayer_IronBlockItem,
	mineflayer_DoubleSlabItem,
	mineflayer_SlabItem,
	mineflayer_BrickItem,
	mineflayer_TntItem,
	mineflayer_BookshelfItem,
	mineflayer_MossStoneItem,
	mineflayer_ObsidianItem,
	mineflayer_TorchItem,
	mineflayer_FireItem,
	mineflayer_MonsterSpawnerItem,
	mineflayer_WoodenStairsItem,
	mineflayer_ChestItem,
	mineflayer_RedstoneWire_placedItem,
	mineflayer_DiamondOreItem,
	mineflayer_DiamondBlockItem,
	mineflayer_CraftingTableItem,
	mineflayer_CropsItem,
	mineflayer_FarmlandItem,
	mineflayer_FurnaceItem,
	mineflayer_BurningFurnaceItem,
	mineflayer_SignPost_placedItem,
	mineflayer_WoodenDoor_placedItem,
	mineflayer_LadderItem,
	mineflayer_MinecartTracksItem,
	mineflayer_CobblestoneStairsItem,
	mineflayer_WallSign_placedItem,
	mineflayer_LeverItem,
	mineflayer_StonePressurePlateItem,
	mineflayer_IronDoor_placedItem,
	mineflayer_WoodenPressurePlateItem,
	mineflayer_RedstoneOreItem,
	mineflayer_GlowingRedstoneOreItem,
	mineflayer_RedstoneTorchOff_placedItem,
	mineflayer_RedstoneTorchOnItem,
	mineflayer_StoneButtonItem,
	mineflayer_SnowItem,
	mineflayer_IceItem,
	mineflayer_SnowBlockItem,
	mineflayer_CactusItem,
	mineflayer_ClayItem,
	mineflayer_SugarCane_placedItem,
	mineflayer_JukeboxItem,
	mineflayer_FenceItem,
	mineflayer_PumpkinItem,
	mineflayer_NetherrackItem,
	mineflayer_SoulSandItem,
	mineflayer_GlowstoneItem,
	mineflayer_PortalItem,
	mineflayer_JackOLanternItem,
	mineflayer_Cake_placedItem,
	mineflayer_RedstoneRepeaterOff_placedItem,
	mineflayer_RedstoneRepeaterOn_placedItem,
	mineflayer_IronShovelItem = 256,
	mineflayer_IronPickaxeItem,
	mineflayer_IronAxeItem,
	mineflayer_FlintAndSteelItem,
	mineflayer_AppleItem,
	mineflayer_BowItem,
	mineflayer_ArrowItem,
	mineflayer_CoalItem,
	mineflayer_DiamondItem,
	mineflayer_IronIngotItem,
	mineflayer_GoldIngotItem,
	mineflayer_IronSwordItem,
	mineflayer_WoodenSwordItem,
	mineflayer_WoodenShovelItem,
	mineflayer_WoodenPickaxeItem,
	mineflayer_WoodenAxeItem,
	mineflayer_StoneSwordItem,
	mineflayer_StoneShovelItem,
	mineflayer_StonePickaxeItem,
	mineflayer_StoneAxeItem,
	mineflayer_DiamondSwordItem,
	mineflayer_DiamondShovelItem,
	mineflayer_DiamondPickaxeItem,
	mineflayer_DiamondAxeItem,
	mineflayer_StickItem,
	mineflayer_BowlItem,
	mineflayer_MushroomStewItem,
	mineflayer_GoldSwordItem,
	mineflayer_GoldShovelItem,
	mineflayer_GoldPickaxeItem,
	mineflayer_GoldAxeItem,
	mineflayer_StringItem,
	mineflayer_FeatherItem,
	mineflayer_GunpowderItem,
	mineflayer_WoodenHoeItem,
	mineflayer_StoneHoeItem,
	mineflayer_IronHoeItem,
	mineflayer_DiamondHoeItem,
	mineflayer_GoldHoeItem,
	mineflayer_SeedsItem,
	mineflayer_WheatItem,
	mineflayer_BreadItem,
	mineflayer_LeatherHelmetItem,
	mineflayer_LeatherChestplateItem,
	mineflayer_LeatherLeggingsItem,
	mineflayer_LeatherBootsItem,
	mineflayer_ChainmailHelmetItem,
	mineflayer_ChainmailChestplateItem,
	mineflayer_ChainmailLeggingsItem,
	mineflayer_ChainmailBootsItem,
	mineflayer_IronHelmetItem,
	mineflayer_IronChestplateItem,
	mineflayer_IronLeggingsItem,
	mineflayer_IronBootsItem,
	mineflayer_DiamondHelmetItem,
	mineflayer_DiamondChestplateItem,
	mineflayer_DiamondLeggingsItem,
	mineflayer_DiamondBootsItem,
	mineflayer_GoldHelmetItem,
	mineflayer_GoldChestplateItem,
	mineflayer_GoldLeggingsItem,
	mineflayer_GoldBootsItem,
	mineflayer_FlintItem,
	mineflayer_RawPorkchopItem,
	mineflayer_CookedPorkchopItem,
	mineflayer_PaintingItem,
	mineflayer_GoldenAppleItem,
	mineflayer_SignItem,
	mineflayer_WoodenDoorItem,
	mineflayer_BucketItem,
	mineflayer_WaterBucketItem,
	mineflayer_LavaBucketItem,
	mineflayer_MinecartItem,
	mineflayer_SaddleItem,
	mineflayer_IronDoorItem,
	mineflayer_RedstoneItem,
	mineflayer_SnowballItem,
	mineflayer_BoatItem,
	mineflayer_LeatherItem,
	mineflayer_MilkBucketItem,
	mineflayer_ClayBrickItem,
	mineflayer_ClayBallItem,
	mineflayer_SugarCaneItem,
	mineflayer_PaperItem,
	mineflayer_BookItem,
	mineflayer_SlimeballItem,
	mineflayer_StorageMinecartItem,
	mineflayer_PoweredMinecartItem,
	mineflayer_EggItem,
	mineflayer_CompassItem,
	mineflayer_FishingRodItem,
	mineflayer_ClockItem,
	mineflayer_GlowstoneDustItem,
	mineflayer_RawFishItem,
	mineflayer_CookedFishItem,
	mineflayer_InkSacItem,
	mineflayer_BoneItem,
	mineflayer_SugarItem,
	mineflayer_CakeItem,
	mineflayer_BedItem,
	mineflayer_RedstoneRepeaterItem,
	mineflayer_GoldMusicDiscItem = 2256,
	mineflayer_GreenMusicDiscItem,
}
alias int mineflayer_ItemType;

enum
{
	mineflayer_CreeperMob = 50,
	mineflayer_SkeletonMob,
	mineflayer_SpiderMob,
	mineflayer_GiantZombieMob,
	mineflayer_ZombieMob,
	mineflayer_SlimeMob,
	mineflayer_GhastMob,
	mineflayer_ZombiePigmanMob,
	mineflayer_PigMob = 90,
	mineflayer_SheepMob,
	mineflayer_CowMob,
	mineflayer_ChickenMob,
}
alias int mineflayer_MobType;

struct mineflayer_Utf8
{
	int byte_count;
	ubyte *utf8_bytes;

	static mineflayer_Utf8 opCall(string str)
	{
		mineflayer_Utf8 ret;
		ret.byte_count = cast(int)str.length;
		ret.utf8_bytes = cast(ubyte*)str.ptr;
		return ret;
	}
}

struct mineflayer_Double3D
{
	double x;
	double y;
	double z;
}

struct mineflayer_Int3D
{
	int x;
	int y;
	int z;
}

struct mineflayer_EntityPosition
{
	mineflayer_Double3D pos;
	mineflayer_Double3D vel;
	double height;
	float yaw;
	float pitch;
	char on_ground;
}

struct mineflayer_Block
{
	int type;      // [0, 255]
	int metadata;  // [0, 15]
	int light;     // [0, 15]
	int sky_light; // [0, 15]
}

struct mineflayer_Item
{
	mineflayer_ItemType type;
	int count;                // [0, 255]
	int metadata;             // [0, 65535]
}

enum
{
	mineflayer_NoMaterial,
	mineflayer_StoneMaterial,
	mineflayer_DirtMaterial,
	mineflayer_WoodMaterial,
	mineflayer_CropsMaterial,
	mineflayer_WaterMaterial,
	mineflayer_LavaMaterial,
	mineflayer_SandMaterial,
	mineflayer_LeavesMaterial,
	mineflayer_SpongeMaterial,
	mineflayer_GlassMaterial,
	mineflayer_WoolMaterial,
	mineflayer_IronMaterial,
	mineflayer_TntMaterial,
	mineflayer_RedstoneMaterial,
	mineflayer_FireMaterial,
	mineflayer_SnowMaterial,
	mineflayer_IceMaterial,
	mineflayer_SnowBlockMaterial,
	mineflayer_CactusMaterial,
	mineflayer_ClayMaterial,
	mineflayer_PumpkinMaterial,
	mineflayer_PortalMaterial,
	mineflayer_CakeMaterial,
	mineflayer_DiamondMaterial,
	mineflayer_GoldMaterial,
}
alias int mineflayer_Material;

struct mineflayer_ItemData
{
	mineflayer_ItemType id;
	mineflayer_Utf8 name;
	int stack_height;
	char placeable;
	char item_activatable;
	char physical;
	char diggable;
	char block_activatable;
	char safe;
	float hardness;
	mineflayer_Material material;
}

struct mineflayer_Entity
{
	mineflayer_EntityType type;
	int entity_id;
	mineflayer_EntityPosition position;
	union {
		struct {
			mineflayer_Utf8 username;
			mineflayer_ItemType held_item;
		};
		mineflayer_MobType mob_type;
		mineflayer_Item item;
	}
}

struct mineflayer_Url
{
	mineflayer_Utf8 username;
	mineflayer_Utf8 password;
	mineflayer_Utf8 hostname;
	int port;
}

alias void *mineflayer_GamePtr;

struct mineflayer_Callbacks
{
	void function(void *context, mineflayer_Utf8 username, mineflayer_Utf8 message) chatReceived;
	void function(void *context, double seconds) timeUpdated;
	void function(void *context, mineflayer_Utf8 message) nonSpokenChatReceived;
	void function(void *context, mineflayer_Entity *mineflayer_entity) entitySpawned;
	void function(void *context, mineflayer_Entity *mineflayer_entity) entityDespawned;
	void function(void *context, mineflayer_Entity *mineflayer_entity) entityMoved;
	void function(void *context, mineflayer_Entity *mineflayer_entity, mineflayer_AnimationType animation_type) animation;
	void function(void *context, mineflayer_Int3D start, mineflayer_Int3D size) chunkUpdated;
	void function(void *context, mineflayer_Int3D coord) unloadChunk;
	void function(void *context, mineflayer_Int3D location, mineflayer_Utf8 text) signUpdated;
	void function(void *context) playerPositionUpdated;
	void function(void *context) playerHealthUpdated;
	void function(void *context) playerDied;
	void function(void *context, int world) playerSpawned;
	void function(void *context, mineflayer_StoppedDiggingReason reason) stoppedDigging;
	void function(void *context, mineflayer_LoginStatus status) loginStatusUpdated;
	void function(void *context, mineflayer_WindowType window_type) windowOpened;
	void function(void *context) inventoryUpdated;
	void function(void *context) equippedItemChanged;
}

typedef mineflayer_GamePtr function(mineflayer_Url url, char auto_physics_loop) PFN_createGame;
typedef mineflayer_GamePtr function(mineflayer_Url url, mineflayer_Callbacks callbacks, void *context) PFN_createGamePullCallbacks;
typedef void function(mineflayer_GamePtr game, mineflayer_Callbacks callbacks, void *context) PFN_setCallbacks;
typedef void function(mineflayer_GamePtr game) PFN_doCallbacks;
typedef void function(mineflayer_GamePtr game) PFN_destroyGame;
typedef void function(mineflayer_Entity *mineflayer_entity) PFN_destroyEntity;
typedef void function(mineflayer_Utf8 utf8) PFN_destroyUtf8;
typedef void function(int *item_id_list) PFN_destroyItemIdList;
typedef void function(mineflayer_GamePtr game) PFN_start;
typedef void function(mineflayer_GamePtr game, float delta_seconds) PFN_doPhysics;
typedef int function() PFN_runEventLoop;
typedef void function(mineflayer_GamePtr game, mineflayer_Control control, char activated) PFN_setControlActivated;
typedef void function(mineflayer_GamePtr game, float delta_yaw, float delta_pitch) PFN_updatePlayerLook;
typedef void function(mineflayer_GamePtr game, float yaw, float pitch, char force) PFN_setPlayerLook;
typedef void function(mineflayer_GamePtr game, int entity_id) PFN_attackEntity;
typedef void function(mineflayer_GamePtr game) PFN_respawn;
typedef int function(mineflayer_GamePtr game) PFN_playerEntityId;
typedef mineflayer_EntityPosition function(mineflayer_GamePtr game) PFN_playerPosition;
typedef mineflayer_Entity *function(mineflayer_GamePtr game, int entity_id) PFN_entity;
typedef mineflayer_Block function(mineflayer_GamePtr game, mineflayer_Int3D absolute_location) PFN_blockAt;
typedef char function(mineflayer_GamePtr game, mineflayer_Int3D absolute_location) PFN_isBlockLoaded;
typedef mineflayer_Utf8 function(mineflayer_GamePtr game, mineflayer_Int3D absolute_location) PFN_signTextAt;
typedef int function(mineflayer_GamePtr game) PFN_playerHealth;
typedef void function(mineflayer_GamePtr game, mineflayer_Int3D block) PFN_startDigging;
typedef void function(mineflayer_GamePtr game) PFN_stopDigging;
typedef char function(mineflayer_GamePtr game, mineflayer_Int3D block, mineflayer_BlockFaceDirection face) PFN_placeBlock;
typedef char function(mineflayer_GamePtr game) PFN_activateItem;
typedef char function(mineflayer_GamePtr game, mineflayer_Int3D block, mineflayer_BlockFaceDirection face) PFN_canPlaceBlock;
typedef void function(mineflayer_GamePtr game, mineflayer_Int3D block) PFN_activateBlock;
typedef void function(mineflayer_GamePtr game, mineflayer_Utf8 message) PFN_sendChat;
typedef double function(mineflayer_GamePtr game) PFN_timeOfDay;
typedef int function(mineflayer_GamePtr game) PFN_selectedEquipSlot;
typedef void function(mineflayer_GamePtr game, int slot_id) PFN_selectEquipSlot;
typedef char function(mineflayer_GamePtr game, int slot_id, char right_click) PFN_clickInventorySlot;
typedef char function(mineflayer_GamePtr game, int slot_id, char right_click) PFN_clickUniqueSlot;
typedef char function(mineflayer_GamePtr game, char right_click) PFN_clickOutsideWindow;
typedef void function(mineflayer_GamePtr game) PFN_openInventoryWindow;
typedef void function(mineflayer_GamePtr game) PFN_closeWindow;
typedef mineflayer_Item function(mineflayer_GamePtr game, int slot_id) PFN_inventoryItem;
typedef mineflayer_Item function(mineflayer_GamePtr game, int slot_id) PFN_uniqueWindowItem;
typedef void function(mineflayer_GamePtr game, float value) PFN_setInputAcceleration;
typedef void function(mineflayer_GamePtr game, float value) PFN_setGravity;
typedef float function() PFN_getStandardGravity;
typedef void function(mineflayer_GamePtr game, float value) PFN_setMaxGroundSpeed;
typedef void function(mineflayer_GamePtr game, mineflayer_Double3D pt) PFN_setPlayerPosition;
typedef void function(char value) PFN_setJesusModeEnabled;
typedef mineflayer_ItemData *function(mineflayer_ItemType item_id) PFN_itemData;
typedef int *function() PFN_itemIdList;
typedef mineflayer_Dimension function(mineflayer_GamePtr game) PFN_currentDimension;

extern(D):

PFN_createGame mineflayer_createGame;
PFN_createGamePullCallbacks mineflayer_createGamePullCallbacks;
PFN_setCallbacks mineflayer_setCallbacks;
PFN_doCallbacks mineflayer_doCallbacks;
PFN_destroyGame mineflayer_destroyGame;
PFN_destroyEntity mineflayer_destroyEntity;
PFN_destroyUtf8 mineflayer_destroyUtf8;
PFN_destroyItemIdList mineflayer_destroyItemIdList;
PFN_start mineflayer_start;
PFN_doPhysics mineflayer_doPhysics;
PFN_runEventLoop mineflayer_runEventLoop;
PFN_setControlActivated mineflayer_setControlActivated;
PFN_updatePlayerLook mineflayer_updatePlayerLook;
PFN_setPlayerLook mineflayer_setPlayerLook;
PFN_attackEntity mineflayer_attackEntity;
PFN_respawn mineflayer_respawn;
PFN_playerEntityId mineflayer_playerEntityId;
PFN_playerPosition mineflayer_playerPosition;
PFN_entity mineflayer_entity;
PFN_blockAt mineflayer_blockAt;
PFN_isBlockLoaded mineflayer_isBlockLoaded;
PFN_signTextAt mineflayer_signTextAt;
PFN_playerHealth mineflayer_playerHealth;
PFN_startDigging mineflayer_startDigging;
PFN_stopDigging mineflayer_stopDigging;
PFN_placeBlock mineflayer_placeBlock;
PFN_activateItem mineflayer_activateItem;
PFN_canPlaceBlock mineflayer_canPlaceBlock;
PFN_activateBlock mineflayer_activateBlock;
PFN_sendChat mineflayer_sendChat;
PFN_timeOfDay mineflayer_timeOfDay;
PFN_selectedEquipSlot mineflayer_selectedEquipSlot;
PFN_selectEquipSlot mineflayer_selectEquipSlot;
PFN_clickInventorySlot mineflayer_clickInventorySlot;
PFN_clickUniqueSlot mineflayer_clickUniqueSlot;
PFN_clickOutsideWindow mineflayer_clickOutsideWindow;
PFN_openInventoryWindow mineflayer_openInventoryWindow;
PFN_closeWindow mineflayer_closeWindow;
PFN_inventoryItem mineflayer_inventoryItem;
PFN_uniqueWindowItem mineflayer_uniqueWindowItem;
PFN_setInputAcceleration mineflayer_setInputAcceleration;
PFN_setGravity mineflayer_setGravity;
PFN_getStandardGravity mineflayer_getStandardGravity;
PFN_setMaxGroundSpeed mineflayer_setMaxGroundSpeed;
PFN_setPlayerPosition mineflayer_setPlayerPosition;
PFN_setJesusModeEnabled mineflayer_setJesusModeEnabled;
PFN_itemData mineflayer_itemData;
PFN_itemIdList mineflayer_itemIdList;
PFN_currentDimension mineflayer_currentDimension;

void loadMineflayer(Loader l)
{
	loadFunc!(mineflayer_createGame)(l);
	loadFunc!(mineflayer_createGamePullCallbacks)(l);
	loadFunc!(mineflayer_setCallbacks)(l);
	loadFunc!(mineflayer_doCallbacks)(l);
	loadFunc!(mineflayer_destroyGame)(l);
	loadFunc!(mineflayer_destroyEntity)(l);
	loadFunc!(mineflayer_destroyUtf8)(l);
	loadFunc!(mineflayer_destroyItemIdList)(l);
	loadFunc!(mineflayer_start)(l);
	loadFunc!(mineflayer_doPhysics)(l);
	loadFunc!(mineflayer_runEventLoop)(l);
	loadFunc!(mineflayer_setControlActivated)(l);
	loadFunc!(mineflayer_updatePlayerLook)(l);
	loadFunc!(mineflayer_setPlayerLook)(l);
	loadFunc!(mineflayer_attackEntity)(l);
	loadFunc!(mineflayer_respawn)(l);
	loadFunc!(mineflayer_playerEntityId)(l);
	loadFunc!(mineflayer_playerPosition)(l);
	loadFunc!(mineflayer_entity)(l);
	loadFunc!(mineflayer_blockAt)(l);
	loadFunc!(mineflayer_isBlockLoaded)(l);
	loadFunc!(mineflayer_signTextAt)(l);
	loadFunc!(mineflayer_playerHealth)(l);
	loadFunc!(mineflayer_startDigging)(l);
	loadFunc!(mineflayer_stopDigging)(l);
	loadFunc!(mineflayer_placeBlock)(l);
	loadFunc!(mineflayer_activateItem)(l);
	loadFunc!(mineflayer_canPlaceBlock)(l);
	loadFunc!(mineflayer_activateBlock)(l);
	loadFunc!(mineflayer_sendChat)(l);
	loadFunc!(mineflayer_timeOfDay)(l);
	loadFunc!(mineflayer_selectedEquipSlot)(l);
	loadFunc!(mineflayer_selectEquipSlot)(l);
	loadFunc!(mineflayer_clickInventorySlot)(l);
	loadFunc!(mineflayer_clickUniqueSlot)(l);
	loadFunc!(mineflayer_clickOutsideWindow)(l);
	loadFunc!(mineflayer_openInventoryWindow)(l);
	loadFunc!(mineflayer_closeWindow)(l);
	loadFunc!(mineflayer_inventoryItem)(l);
	loadFunc!(mineflayer_uniqueWindowItem)(l);
	loadFunc!(mineflayer_setInputAcceleration)(l);
	loadFunc!(mineflayer_setGravity)(l);
	loadFunc!(mineflayer_getStandardGravity)(l);
	loadFunc!(mineflayer_setMaxGroundSpeed)(l);
	loadFunc!(mineflayer_setPlayerPosition)(l);
	loadFunc!(mineflayer_setJesusModeEnabled)(l);
	loadFunc!(mineflayer_itemData)(l);
	loadFunc!(mineflayer_itemIdList)(l);
	loadFunc!(mineflayer_currentDimension)(l);
}

char[] licenseText = `
The MIT License

Copyright (c) 2011 superjoe30@gmail.com, thejoshwolfe@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
`;

import license;

static this()
{
	licenseArray ~= licenseText;
}
