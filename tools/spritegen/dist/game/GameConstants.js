"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MECH_INTERACT_RANGE = exports.TRAP_SIZE = exports.TRAP_DAMAGE = exports.TRAP_TRIGGER_RADIUS = exports.TRAP_COOLDOWN_TIME = exports.TRAP_ACTIVE_TIME = exports.TRAP_TELEGRAPH_TIME = exports.BIOME_SCALE = exports.CAVE_THRESHOLD = exports.NOISE_SCALE = exports.MINIMAP_UPDATE_INTERVAL = exports.FRAME_INTERVAL = exports.MINIMAP_SIZE = exports.JOYSTICK_RADIUS = exports.CHUNK_LOAD_RADIUS = exports.LEVEL_UP_XP = exports.XP_MAGNET_RANGE = exports.XP_COLLECT_RANGE = exports.XP_ORB_SIZE = exports.DRILL_BREAK_HITS = exports.DEVOUR_XP_BASE = exports.DEVOUR_HP_THRESHOLD = exports.DEVOUR_COOLDOWN = exports.DEVOUR_ANIM_DURATION = exports.DEVOUR_RANGE = exports.ENGULF_ESCAPE_ATTACKS = exports.ENGULF_DAMAGE_INTERVAL = exports.SLIME_KNOCKBACK = exports.SLIME_DAMAGE = exports.SLIME_HP = exports.BLUE_SLIME_SPEED = exports.RED_SLIME_DETECT = exports.RED_SLIME_SPEED = exports.PURPLE_SLIME_DETECT = exports.PURPLE_SLIME_SPEED = exports.SLIME_SPEED = exports.SLIME_SIZE = exports.INVINCIBLE_DURATION = exports.PLAYER_MAX_HP = exports.ATTACK_WIDTH = exports.ATTACK_RANGE = exports.ATTACK_COOLDOWN = exports.ATTACK_DURATION = exports.DASH_COOLDOWN = exports.DASH_DURATION = exports.DASH_SPEED = exports.PLAYER_SPEED = exports.PLAYER_SIZE = exports.CHUNK_SIZE = exports.TILE_SIZE = void 0;
exports.COLOR_MINIMAP_ENEMY = exports.COLOR_MINIMAP_PLAYER = exports.COLOR_MINIMAP_BG = exports.COLOR_HP_EMPTY = exports.COLOR_HP_FULL = exports.COLOR_XP_GLOW = exports.COLOR_XP_ORB = exports.COLOR_SLIME_PUPIL = exports.COLOR_SLIME_EYE = exports.COLOR_SLIME_GHOST_LIGHT = exports.COLOR_SLIME_GHOST = exports.COLOR_SLIME_YELLOW_LIGHT = exports.COLOR_SLIME_YELLOW = exports.COLOR_SLIME_BLUE_LIGHT = exports.COLOR_SLIME_BLUE = exports.COLOR_SLIME_RED_LIGHT = exports.COLOR_SLIME_RED = exports.COLOR_SLIME_PURPLE_LIGHT = exports.COLOR_SLIME_PURPLE = exports.COLOR_SLIME_GRAY_LIGHT = exports.COLOR_SLIME_GRAY = exports.COLOR_DRILL_TIP = exports.COLOR_DRILL_BASE = exports.COLOR_PLAYER_BODY_DARK = exports.COLOR_PLAYER_BODY = exports.COLOR_PLAYER_HAIR = exports.COLOR_PLAYER_SKIN = exports.COLOR_CACTUS = exports.COLOR_FLOWER_YELLOW = exports.COLOR_FLOWER_PINK = exports.COLOR_VINE = exports.COLOR_FERN = exports.COLOR_PLANT_LIGHT = exports.COLOR_PLANT = exports.COLOR_GLOW = exports.COLOR_GLOW_STONE = exports.COLOR_MUSHROOM_GLOW = exports.COLOR_MUSHROOM_STEM = exports.COLOR_MUSHROOM_CAP = exports.COLOR_CRYSTAL_GLOW = exports.COLOR_CRYSTAL = exports.COLOR_LAVA_LIGHT = exports.COLOR_LAVA = exports.COLOR_WATER_LIGHT = exports.COLOR_WATER = exports.COLOR_FLOOR_VAR = exports.COLOR_FLOOR = exports.COLOR_WALL_EDGE = exports.COLOR_WALL = exports.COLOR_BG = void 0;
exports.SPIKE_COOLDOWN_TIME = exports.SPIKE_ACTIVE_TIME = exports.SPIKE_TELEGRAPH_TIME = exports.VOID_PULL_DPS = exports.LAVA_GEYSER_DAMAGE = exports.POISON_DPS = exports.ROCK_DAMAGE = exports.SPIKE_DAMAGE = exports.TRIGGER_DETECT_RANGE = exports.ELITE_GUARDIAN_COUNT = exports.ELITE_CHEST_CHANCE = exports.NORMAL_CHEST_CHANCE = exports.CHEST_INTERACT_RANGE = exports.CHEST_SIZE = exports.BOSS_RESPAWN_TIME = exports.OPTIONAL_CHALLENGE_AGGRO = exports.PASSAGE_GUARDIAN_AGGRO = exports.BOSS_PHASE2_THRESHOLD = exports.BOSS_ATTACK_INTERVAL = exports.BOSS_ROOM_SIZE = exports.BOSS_SIZE = exports.BOSS_HP = exports.FORM_UNLOCK_COST = exports.EVOLUTION_COST_ORE = exports.EVOLUTION_COST_RARE = exports.EVOLUTION_COST_NORMAL = exports.TrapState = exports.MechanismType = exports.TrapType = exports.BossRole = exports.BossPhase = exports.BossType = exports.TransformForm = exports.ChestType = exports.MaterialType = exports.EvolutionLevel = exports.EvolutionBranch = exports.WeaponForm = exports.GenderType = exports.BiomeType = exports.EnemyType = exports.TileType = exports.COLOR_DRILL_PARTICLE = exports.COLOR_DAMAGE_PARTICLE = exports.COLOR_ATTACK_FLASH = exports.COLOR_BTN_DASH = exports.COLOR_BTN_ATTACK = exports.COLOR_BTN_JUMP = exports.COLOR_JOY_KNOB = exports.COLOR_JOY_BASE = void 0;
exports.COLOR_EVO_PANEL_BG = exports.COLOR_TOOL_BTN = exports.COLOR_BOSS_HP_BG = exports.COLOR_BOSS_HP_BAR = exports.COLOR_EVO_TIDE = exports.COLOR_EVO_TOXIN = exports.COLOR_EVO_SHADOW = exports.COLOR_EVO_FLAME = exports.COLOR_EVO_CRYSTAL = exports.COLOR_TELEPORT_EXIT = exports.COLOR_TELEPORT_ENTRY = exports.COLOR_TELEPORT_RUNE = exports.COLOR_BREAKABLE_WALL = exports.COLOR_BEAM = exports.COLOR_REFLECTOR = exports.COLOR_PUSH_BLOCK = exports.COLOR_LEVER_HANDLE = exports.COLOR_LEVER = exports.COLOR_PLATE_ACTIVE = exports.COLOR_PRESSURE_PLATE = exports.COLOR_VORTEX = exports.COLOR_VOID_PULL = exports.COLOR_VOID_CRACK = exports.COLOR_LAVA_GEYSER = exports.COLOR_POISON_CLOUD = exports.COLOR_ROCK = exports.COLOR_SPIKE_TIP = exports.COLOR_SPIKE = exports.COLOR_SHADOW_PARTICLE = exports.COLOR_SHADOW_WALL = exports.COLOR_SHADOW_FLOOR = exports.COLOR_CHEST_GLOW = exports.COLOR_CHEST_BOSS = exports.COLOR_CHEST_ELITE = exports.COLOR_CHEST_NORMAL = exports.COLOR_BOSS_VOID = exports.COLOR_BOSS_ABYSS = exports.COLOR_BOSS_LAVA = exports.COLOR_BOSS_MUSHROOM = exports.COLOR_BOSS_CRYSTAL = exports.WEAPON_FORM_STATS = exports.LEVER_LINK_RANGE = exports.TELEPORT_COOLDOWN = exports.PRESSURE_PLATE_RANGE = exports.PUSH_BLOCK_SPEED = exports.LAVA_GEYSER_ACTIVE = exports.LAVA_GEYSER_WARNING = exports.POISON_EMIT_INTERVAL = exports.POISON_CLOUD_DURATION = exports.ROCK_FALL_WARNING = void 0;
exports.COLOR_PLAYER_FEMALE_HAIR = exports.COLOR_PLAYER_FEMALE_BODY_DARK = exports.COLOR_PLAYER_FEMALE_BODY = exports.COLOR_TRANSFORM_FLASH = exports.COLOR_TRANSFORM_BTN_READY = exports.COLOR_TRANSFORM_BTN_LOCKED = exports.COLOR_TRANSFORM_ENERGY_BG = exports.COLOR_TRANSFORM_IRON_GOLD = exports.COLOR_TRANSFORM_IRON_RED = exports.COLOR_TRANSFORM_ARMOR_ACCENT = exports.COLOR_TRANSFORM_ARMOR = exports.COLOR_TRANSFORM_GHOST_DARK = exports.COLOR_TRANSFORM_GHOST = exports.COLOR_TRANSFORM_SLIME_DARK = exports.COLOR_TRANSFORM_SLIME = exports.TRANSFORM_ENERGY_XP_ORB = exports.TRANSFORM_ENERGY_KILL_BOSS = exports.TRANSFORM_ENERGY_KILL_ELITE = exports.TRANSFORM_ENERGY_KILL_SLIME = exports.TRANSFORM_DAMAGE_REDUCTION = exports.TRANSFORM_ATTACK_COOLDOWNS = exports.TRANSFORM_ATTACK_COSTS = exports.TRANSFORM_SPEEDS = exports.TRANSFORM_DRAIN_RATES = exports.TRANSFORM_REVERT_ANIM = exports.TRANSFORM_ACTIVATE_ANIM = exports.TRANSFORM_PASSIVE_REGEN = exports.TRANSFORM_COOLDOWN = exports.TRANSFORM_MAX_ENERGY = exports.COLOR_TRAP_WARNING = exports.COLOR_EVO_PANEL_BORDER = void 0;
exports.getBossColor = getBossColor;
exports.TILE_SIZE = 32;
exports.CHUNK_SIZE = 32;
exports.PLAYER_SIZE = 14;
exports.PLAYER_SPEED = 3.0;
exports.DASH_SPEED = 12.0;
exports.DASH_DURATION = 150;
exports.DASH_COOLDOWN = 1000;
exports.ATTACK_DURATION = 250;
exports.ATTACK_COOLDOWN = 400;
exports.ATTACK_RANGE = 28;
exports.ATTACK_WIDTH = 22;
exports.PLAYER_MAX_HP = 10;
exports.INVINCIBLE_DURATION = 800;
exports.SLIME_SIZE = 12;
exports.SLIME_SPEED = 1.2;
exports.PURPLE_SLIME_SPEED = 2.0;
exports.PURPLE_SLIME_DETECT = 180;
exports.RED_SLIME_SPEED = 3.5;
exports.RED_SLIME_DETECT = 150;
exports.BLUE_SLIME_SPEED = 2.5;
exports.SLIME_HP = 3;
exports.SLIME_DAMAGE = 1;
exports.SLIME_KNOCKBACK = 8;
exports.ENGULF_DAMAGE_INTERVAL = 500;
exports.ENGULF_ESCAPE_ATTACKS = 3;
exports.DEVOUR_RANGE = 35;
exports.DEVOUR_ANIM_DURATION = 500;
exports.DEVOUR_COOLDOWN = 800;
exports.DEVOUR_HP_THRESHOLD = 0.3;
exports.DEVOUR_XP_BASE = 5;
exports.DRILL_BREAK_HITS = 3;
exports.XP_ORB_SIZE = 6;
exports.XP_COLLECT_RANGE = 40;
exports.XP_MAGNET_RANGE = 80;
exports.LEVEL_UP_XP = 10;
exports.CHUNK_LOAD_RADIUS = 3;
exports.JOYSTICK_RADIUS = 55;
exports.MINIMAP_SIZE = 130;
exports.FRAME_INTERVAL = 16;
exports.MINIMAP_UPDATE_INTERVAL = 5;
exports.NOISE_SCALE = 0.08;
exports.CAVE_THRESHOLD = 0.45;
exports.BIOME_SCALE = 0.015;
// Trap timing constants (ms)
exports.TRAP_TELEGRAPH_TIME = 800;
exports.TRAP_ACTIVE_TIME = 600;
exports.TRAP_COOLDOWN_TIME = 2000;
exports.TRAP_TRIGGER_RADIUS = 40;
exports.TRAP_DAMAGE = 2;
exports.TRAP_SIZE = 24;
// Mechanism constants
exports.MECH_INTERACT_RANGE = 30;
exports.COLOR_BG = '#08080f';
exports.COLOR_WALL = '#1a1a2e';
exports.COLOR_WALL_EDGE = '#252540';
exports.COLOR_FLOOR = '#12121f';
exports.COLOR_FLOOR_VAR = '#16162a';
exports.COLOR_WATER = '#1a3a5c';
exports.COLOR_WATER_LIGHT = '#2a5a8c';
exports.COLOR_LAVA = '#8b2500';
exports.COLOR_LAVA_LIGHT = '#cd3700';
exports.COLOR_CRYSTAL = '#00ced1';
exports.COLOR_CRYSTAL_GLOW = '#008b8b';
exports.COLOR_MUSHROOM_CAP = '#cd3278';
exports.COLOR_MUSHROOM_STEM = '#deb887';
exports.COLOR_MUSHROOM_GLOW = '#ff69b4';
exports.COLOR_GLOW_STONE = '#ffd700';
exports.COLOR_GLOW = '#ffaa00';
exports.COLOR_PLANT = '#2d8a4e';
exports.COLOR_PLANT_LIGHT = '#4ade80';
exports.COLOR_FERN = '#228b22';
exports.COLOR_VINE = '#006400';
exports.COLOR_FLOWER_PINK = '#ff69b4';
exports.COLOR_FLOWER_YELLOW = '#ffd700';
exports.COLOR_CACTUS = '#2e8b57';
exports.COLOR_PLAYER_SKIN = '#f5c8a0';
exports.COLOR_PLAYER_HAIR = '#6b3a1a';
exports.COLOR_PLAYER_BODY = '#3b82f6';
exports.COLOR_PLAYER_BODY_DARK = '#2563eb';
exports.COLOR_DRILL_BASE = '#9ca3af';
exports.COLOR_DRILL_TIP = '#fbbf24';
exports.COLOR_SLIME_GRAY = '#6b8e7b';
exports.COLOR_SLIME_GRAY_LIGHT = '#8fb8a0';
exports.COLOR_SLIME_PURPLE = '#8b5cf6';
exports.COLOR_SLIME_PURPLE_LIGHT = '#a78bfa';
exports.COLOR_SLIME_RED = '#dc2626';
exports.COLOR_SLIME_RED_LIGHT = '#f87171';
exports.COLOR_SLIME_BLUE = '#2563eb';
exports.COLOR_SLIME_BLUE_LIGHT = '#60a5fa';
exports.COLOR_SLIME_YELLOW = '#eab308';
exports.COLOR_SLIME_YELLOW_LIGHT = '#fde047';
exports.COLOR_SLIME_GHOST = '#94a3b8';
exports.COLOR_SLIME_GHOST_LIGHT = '#cbd5e1';
exports.COLOR_SLIME_EYE = '#ffffff';
exports.COLOR_SLIME_PUPIL = '#1a1a2e';
exports.COLOR_XP_ORB = '#22d3ee';
exports.COLOR_XP_GLOW = '#06b6d4';
exports.COLOR_HP_FULL = '#ef4444';
exports.COLOR_HP_EMPTY = '#374151';
exports.COLOR_MINIMAP_BG = '#0a0a15';
exports.COLOR_MINIMAP_PLAYER = '#22d3ee';
exports.COLOR_MINIMAP_ENEMY = '#f43f5e';
exports.COLOR_JOY_BASE = '#334155';
exports.COLOR_JOY_KNOB = '#94a3b8';
exports.COLOR_BTN_JUMP = '#22c55e';
exports.COLOR_BTN_ATTACK = '#ef4444';
exports.COLOR_BTN_DASH = '#3b82f6';
exports.COLOR_ATTACK_FLASH = '#fbbf24';
exports.COLOR_DAMAGE_PARTICLE = '#ff6b6b';
exports.COLOR_DRILL_PARTICLE = '#a8a29e';
var TileType;
(function (TileType) {
    TileType[TileType["VOID"] = 0] = "VOID";
    TileType[TileType["WALL"] = 1] = "WALL";
    TileType[TileType["FLOOR"] = 2] = "FLOOR";
    TileType[TileType["GLOW_STONE"] = 3] = "GLOW_STONE";
    TileType[TileType["PLANT"] = 4] = "PLANT";
    TileType[TileType["WATER"] = 5] = "WATER";
    TileType[TileType["CRYSTAL"] = 6] = "CRYSTAL";
    TileType[TileType["MUSHROOM"] = 7] = "MUSHROOM";
    TileType[TileType["LAVA"] = 8] = "LAVA";
    TileType[TileType["BROKEN_WALL"] = 9] = "BROKEN_WALL";
})(TileType || (exports.TileType = TileType = {}));
var EnemyType;
(function (EnemyType) {
    EnemyType[EnemyType["GRAY_SLIME"] = 0] = "GRAY_SLIME";
    EnemyType[EnemyType["PURPLE_SLIME"] = 1] = "PURPLE_SLIME";
    EnemyType[EnemyType["RED_SLIME"] = 2] = "RED_SLIME";
    EnemyType[EnemyType["BLUE_SLIME"] = 3] = "BLUE_SLIME";
    EnemyType[EnemyType["YELLOW_SLIME"] = 4] = "YELLOW_SLIME";
    EnemyType[EnemyType["GHOST_SLIME"] = 5] = "GHOST_SLIME";
})(EnemyType || (exports.EnemyType = EnemyType = {}));
var BiomeType;
(function (BiomeType) {
    BiomeType[BiomeType["NORMAL"] = 0] = "NORMAL";
    BiomeType[BiomeType["CRYSTAL"] = 1] = "CRYSTAL";
    BiomeType[BiomeType["MUSHROOM"] = 2] = "MUSHROOM";
    BiomeType[BiomeType["WATER"] = 3] = "WATER";
    BiomeType[BiomeType["LAVA"] = 4] = "LAVA";
    BiomeType[BiomeType["SHADOW"] = 5] = "SHADOW";
})(BiomeType || (exports.BiomeType = BiomeType = {}));
var GenderType;
(function (GenderType) {
    GenderType[GenderType["MALE"] = 0] = "MALE";
    GenderType[GenderType["FEMALE"] = 1] = "FEMALE";
})(GenderType || (exports.GenderType = GenderType = {}));
var WeaponForm;
(function (WeaponForm) {
    WeaponForm[WeaponForm["BLADE"] = 0] = "BLADE";
    WeaponForm[WeaponForm["WHIP"] = 1] = "WHIP";
    WeaponForm[WeaponForm["HAMMER"] = 2] = "HAMMER";
    WeaponForm[WeaponForm["STAFF"] = 3] = "STAFF";
    WeaponForm[WeaponForm["DUAL_BLADES"] = 4] = "DUAL_BLADES";
    WeaponForm[WeaponForm["GREAT_AXE"] = 5] = "GREAT_AXE";
})(WeaponForm || (exports.WeaponForm = WeaponForm = {}));
var EvolutionBranch;
(function (EvolutionBranch) {
    EvolutionBranch[EvolutionBranch["CRYSTAL"] = 0] = "CRYSTAL";
    EvolutionBranch[EvolutionBranch["FLAME"] = 1] = "FLAME";
    EvolutionBranch[EvolutionBranch["SHADOW"] = 2] = "SHADOW";
    EvolutionBranch[EvolutionBranch["TOXIN"] = 3] = "TOXIN";
    EvolutionBranch[EvolutionBranch["TIDE"] = 4] = "TIDE";
})(EvolutionBranch || (exports.EvolutionBranch = EvolutionBranch = {}));
var EvolutionLevel;
(function (EvolutionLevel) {
    EvolutionLevel[EvolutionLevel["BASE"] = 0] = "BASE";
    EvolutionLevel[EvolutionLevel["LEVEL_1"] = 1] = "LEVEL_1";
    EvolutionLevel[EvolutionLevel["LEVEL_2"] = 2] = "LEVEL_2";
    EvolutionLevel[EvolutionLevel["LEVEL_3"] = 3] = "LEVEL_3";
})(EvolutionLevel || (exports.EvolutionLevel = EvolutionLevel = {}));
var MaterialType;
(function (MaterialType) {
    MaterialType[MaterialType["CRYSTAL_ORE"] = 0] = "CRYSTAL_ORE";
    MaterialType[MaterialType["MUSHROOM_ORE"] = 1] = "MUSHROOM_ORE";
    MaterialType[MaterialType["FLAME_ORE"] = 2] = "FLAME_ORE";
    MaterialType[MaterialType["ABYSS_ORE"] = 3] = "ABYSS_ORE";
    MaterialType[MaterialType["VOID_ORE"] = 4] = "VOID_ORE";
    MaterialType[MaterialType["CORE_NORMAL"] = 5] = "CORE_NORMAL";
    MaterialType[MaterialType["CORE_RARE"] = 6] = "CORE_RARE";
    MaterialType[MaterialType["FORM_CORE"] = 7] = "FORM_CORE";
})(MaterialType || (exports.MaterialType = MaterialType = {}));
var ChestType;
(function (ChestType) {
    ChestType[ChestType["NORMAL"] = 0] = "NORMAL";
    ChestType[ChestType["ELITE"] = 1] = "ELITE";
    ChestType[ChestType["BOSS"] = 2] = "BOSS";
})(ChestType || (exports.ChestType = ChestType = {}));
var TransformForm;
(function (TransformForm) {
    TransformForm[TransformForm["NONE"] = -1] = "NONE";
    TransformForm[TransformForm["SLIME"] = 0] = "SLIME";
    TransformForm[TransformForm["GHOST"] = 1] = "GHOST";
    TransformForm[TransformForm["ARMOR"] = 2] = "ARMOR";
    TransformForm[TransformForm["IRON_MAN"] = 3] = "IRON_MAN";
})(TransformForm || (exports.TransformForm = TransformForm = {}));
var BossType;
(function (BossType) {
    BossType[BossType["CRYSTAL_GUARDIAN"] = 0] = "CRYSTAL_GUARDIAN";
    BossType[BossType["MUSHROOM_KING"] = 1] = "MUSHROOM_KING";
    BossType[BossType["LAVA_BEAST"] = 2] = "LAVA_BEAST";
    BossType[BossType["ABYSS_SIREN"] = 3] = "ABYSS_SIREN";
    BossType[BossType["VOID_RIFT"] = 4] = "VOID_RIFT";
})(BossType || (exports.BossType = BossType = {}));
var BossPhase;
(function (BossPhase) {
    BossPhase[BossPhase["PHASE_1"] = 0] = "PHASE_1";
    BossPhase[BossPhase["PHASE_2"] = 1] = "PHASE_2";
})(BossPhase || (exports.BossPhase = BossPhase = {}));
var BossRole;
(function (BossRole) {
    BossRole[BossRole["PASSAGE_GUARDIAN"] = 0] = "PASSAGE_GUARDIAN";
    BossRole[BossRole["OPTIONAL_CHALLENGE"] = 1] = "OPTIONAL_CHALLENGE";
})(BossRole || (exports.BossRole = BossRole = {}));
var TrapType;
(function (TrapType) {
    TrapType[TrapType["GROUND_SPIKES"] = 0] = "GROUND_SPIKES";
    TrapType[TrapType["FALLING_ROCKS"] = 1] = "FALLING_ROCKS";
    TrapType[TrapType["POISON_SPORES"] = 2] = "POISON_SPORES";
    TrapType[TrapType["LAVA_GEYSER"] = 3] = "LAVA_GEYSER";
    TrapType[TrapType["VOID_CRACK"] = 4] = "VOID_CRACK";
    TrapType[TrapType["WATER_VORTEX"] = 5] = "WATER_VORTEX";
})(TrapType || (exports.TrapType = TrapType = {}));
var MechanismType;
(function (MechanismType) {
    MechanismType[MechanismType["PRESSURE_PLATE"] = 0] = "PRESSURE_PLATE";
    MechanismType[MechanismType["LEVER"] = 1] = "LEVER";
    MechanismType[MechanismType["PUSH_BLOCK"] = 2] = "PUSH_BLOCK";
    MechanismType[MechanismType["CRYSTAL_REFLECTOR"] = 3] = "CRYSTAL_REFLECTOR";
    MechanismType[MechanismType["BREAKABLE_WALL"] = 4] = "BREAKABLE_WALL";
    MechanismType[MechanismType["TELEPORT_RUNE"] = 5] = "TELEPORT_RUNE";
})(MechanismType || (exports.MechanismType = MechanismType = {}));
var TrapState;
(function (TrapState) {
    TrapState[TrapState["IDLE"] = 0] = "IDLE";
    TrapState[TrapState["TELEGRAPH"] = 1] = "TELEGRAPH";
    TrapState[TrapState["ACTIVE"] = 2] = "ACTIVE";
    TrapState[TrapState["COOLDOWN"] = 3] = "COOLDOWN";
})(TrapState || (exports.TrapState = TrapState = {}));
// ==================== Expansion Constants ====================
// Evolution costs per level (index = EvolutionLevel)
exports.EVOLUTION_COST_NORMAL = [0, 3, 0, 0];
exports.EVOLUTION_COST_RARE = [0, 0, 1, 2];
exports.EVOLUTION_COST_ORE = [0, 2, 4, 6];
exports.FORM_UNLOCK_COST = 1;
// Boss config
exports.BOSS_HP = 50;
exports.BOSS_SIZE = 40;
exports.BOSS_ROOM_SIZE = 15;
exports.BOSS_ATTACK_INTERVAL = 3000;
exports.BOSS_PHASE2_THRESHOLD = 0.5;
exports.PASSAGE_GUARDIAN_AGGRO = 9999;
exports.OPTIONAL_CHALLENGE_AGGRO = 120;
exports.BOSS_RESPAWN_TIME = 60000;
// Chest config
exports.CHEST_SIZE = 10;
exports.CHEST_INTERACT_RANGE = 30;
exports.NORMAL_CHEST_CHANCE = 0.08;
exports.ELITE_CHEST_CHANCE = 0.03;
exports.ELITE_GUARDIAN_COUNT = 3;
// Trap config
exports.TRIGGER_DETECT_RANGE = 48;
exports.SPIKE_DAMAGE = 1;
exports.ROCK_DAMAGE = 2;
exports.POISON_DPS = 1;
exports.LAVA_GEYSER_DAMAGE = 2;
exports.VOID_PULL_DPS = 1;
exports.SPIKE_TELEGRAPH_TIME = 500;
exports.SPIKE_ACTIVE_TIME = 1500;
exports.SPIKE_COOLDOWN_TIME = 2000;
exports.ROCK_FALL_WARNING = 300;
exports.POISON_CLOUD_DURATION = 3000;
exports.POISON_EMIT_INTERVAL = 4000;
exports.LAVA_GEYSER_WARNING = 800;
exports.LAVA_GEYSER_ACTIVE = 1500;
// Mechanism config
exports.PUSH_BLOCK_SPEED = 2.0;
exports.PRESSURE_PLATE_RANGE = 16;
exports.TELEPORT_COOLDOWN = 2000;
exports.LEVER_LINK_RANGE = 320;
// Weapon form attack params: [range, width, duration, cooldown]
exports.WEAPON_FORM_STATS = [
    [28, 22, 250, 400], // BLADE
    [40, 12, 300, 350], // WHIP
    [20, 35, 350, 600], // HAMMER
    [50, 10, 200, 450], // STAFF
    [22, 18, 180, 250], // DUAL_BLADES
    [30, 40, 400, 700], // GREAT_AXE
];
// ==================== Expansion Color Constants ====================
// Boss colors
exports.COLOR_BOSS_CRYSTAL = '#00ced1';
exports.COLOR_BOSS_MUSHROOM = '#cd3278';
exports.COLOR_BOSS_LAVA = '#ff4500';
exports.COLOR_BOSS_ABYSS = '#4169e1';
exports.COLOR_BOSS_VOID = '#6b21a8';
/** Boss 类型 → 主题色映射（BossSpriteGenerator 与 GameEngine 共用） */
function getBossColor(bossType) {
    if (bossType === BossType.CRYSTAL_GUARDIAN)
        return exports.COLOR_BOSS_CRYSTAL;
    if (bossType === BossType.MUSHROOM_KING)
        return exports.COLOR_BOSS_MUSHROOM;
    if (bossType === BossType.LAVA_BEAST)
        return exports.COLOR_BOSS_LAVA;
    if (bossType === BossType.ABYSS_SIREN)
        return exports.COLOR_BOSS_ABYSS;
    return exports.COLOR_BOSS_VOID;
}
// Chest colors
exports.COLOR_CHEST_NORMAL = '#8b6914';
exports.COLOR_CHEST_ELITE = '#708090';
exports.COLOR_CHEST_BOSS = '#ffd700';
exports.COLOR_CHEST_GLOW = '#fbbf24';
// Shadow biome colors
exports.COLOR_SHADOW_FLOOR = '#0d0d1a';
exports.COLOR_SHADOW_WALL = '#1a0a2e';
exports.COLOR_SHADOW_PARTICLE = '#7c3aed';
// Trap colors
exports.COLOR_SPIKE = '#9ca3af';
exports.COLOR_SPIKE_TIP = '#d1d5db';
exports.COLOR_ROCK = '#78716c';
exports.COLOR_POISON_CLOUD = '#4ade80';
exports.COLOR_LAVA_GEYSER = '#ff6b00';
exports.COLOR_VOID_CRACK = '#7c3aed';
exports.COLOR_VOID_PULL = '#a855f7';
exports.COLOR_VORTEX = '#38bdf8';
// Mechanism colors
exports.COLOR_PRESSURE_PLATE = '#a8a29e';
exports.COLOR_PLATE_ACTIVE = '#fbbf24';
exports.COLOR_LEVER = '#78716c';
exports.COLOR_LEVER_HANDLE = '#22d3ee';
exports.COLOR_PUSH_BLOCK = '#a3a3a3';
exports.COLOR_REFLECTOR = '#67e8f9';
exports.COLOR_BEAM = '#fbbf24';
exports.COLOR_BREAKABLE_WALL = '#2a2a45';
exports.COLOR_TELEPORT_RUNE = '#8b5cf6';
exports.COLOR_TELEPORT_ENTRY = '#3b82f6';
exports.COLOR_TELEPORT_EXIT = '#22c55e';
// Weapon evolution glow colors
exports.COLOR_EVO_CRYSTAL = '#67e8f9';
exports.COLOR_EVO_FLAME = '#f97316';
exports.COLOR_EVO_SHADOW = '#a855f7';
exports.COLOR_EVO_TOXIN = '#4ade80';
exports.COLOR_EVO_TIDE = '#38bdf8';
// UI colors
exports.COLOR_BOSS_HP_BAR = '#dc2626';
exports.COLOR_BOSS_HP_BG = '#1f2937';
exports.COLOR_TOOL_BTN = '#f59e0b';
exports.COLOR_EVO_PANEL_BG = '#0f172a';
exports.COLOR_EVO_PANEL_BORDER = '#334155';
exports.COLOR_TRAP_WARNING = '#fbbf24';
// Transform system constants
exports.TRANSFORM_MAX_ENERGY = 100;
exports.TRANSFORM_COOLDOWN = 10000;
exports.TRANSFORM_PASSIVE_REGEN = 1.0;
exports.TRANSFORM_ACTIVATE_ANIM = 800;
exports.TRANSFORM_REVERT_ANIM = 500;
// Energy drain per second by form (index = TransformForm value)
exports.TRANSFORM_DRAIN_RATES = [2.0, 3.0, 2.5, 3.5];
// Form movement speeds
exports.TRANSFORM_SPEEDS = [3.5, 2.8, 2.5, 4.0];
// Form attack energy costs
exports.TRANSFORM_ATTACK_COSTS = [3, 5, 8, 2];
// Form attack cooldowns (ms)
exports.TRANSFORM_ATTACK_COOLDOWNS = [600, 800, 1000, 350];
// Form damage reduction (percentage)
exports.TRANSFORM_DAMAGE_REDUCTION = [0.3, 0.0, 0.5, 0.0];
// Energy recovery from kills
exports.TRANSFORM_ENERGY_KILL_SLIME = 5;
exports.TRANSFORM_ENERGY_KILL_ELITE = 10;
exports.TRANSFORM_ENERGY_KILL_BOSS = 50;
exports.TRANSFORM_ENERGY_XP_ORB = 1;
// Transform form colors
exports.COLOR_TRANSFORM_SLIME = '#4ade80';
exports.COLOR_TRANSFORM_SLIME_DARK = '#22c55e';
exports.COLOR_TRANSFORM_GHOST = '#a78bfa';
exports.COLOR_TRANSFORM_GHOST_DARK = '#7c3aed';
exports.COLOR_TRANSFORM_ARMOR = '#94a3b8';
exports.COLOR_TRANSFORM_ARMOR_ACCENT = '#ef4444';
exports.COLOR_TRANSFORM_IRON_RED = '#dc2626';
exports.COLOR_TRANSFORM_IRON_GOLD = '#fbbf24';
exports.COLOR_TRANSFORM_ENERGY_BG = '#1f2937';
exports.COLOR_TRANSFORM_BTN_LOCKED = '#4b5563';
exports.COLOR_TRANSFORM_BTN_READY = '#22d3ee';
exports.COLOR_TRANSFORM_FLASH = '#ffffff';
// Female character colors
exports.COLOR_PLAYER_FEMALE_BODY = '#8b5cf6';
exports.COLOR_PLAYER_FEMALE_BODY_DARK = '#7c3aed';
exports.COLOR_PLAYER_FEMALE_HAIR = '#4a1a6b';
