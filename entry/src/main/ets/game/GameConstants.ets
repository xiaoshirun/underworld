export const TILE_SIZE: number = 32;
export const CHUNK_SIZE: number = 32;
export const PLAYER_SIZE: number = 14;
export const PLAYER_SPEED: number = 3.0;
export const DASH_SPEED: number = 12.0;
export const DASH_DURATION: number = 150;
export const DASH_COOLDOWN: number = 1000;
export const ATTACK_DURATION: number = 250;
export const ATTACK_COOLDOWN: number = 400;
export const ATTACK_RANGE: number = 28;
export const ATTACK_WIDTH: number = 22;
export const PLAYER_MAX_HP: number = 10;
export const INVINCIBLE_DURATION: number = 800;
export const SLIME_SIZE: number = 20;
export const SLIME_SPEED: number = 1.2;
export const PURPLE_SLIME_SPEED: number = 2.0;
export const PURPLE_SLIME_DETECT: number = 180;
export const RED_SLIME_SPEED: number = 3.5;
export const RED_SLIME_DETECT: number = 150;
export const BLUE_SLIME_SPEED: number = 2.5;
export const SLIME_HP: number = 3;
export const SLIME_DAMAGE: number = 1;
export const SLIME_KNOCKBACK: number = 8;
export const MONSTER_HP_SCALE_PER_LEVEL: number = 0.15;
export const MONSTER_SIZE_PER_4_LEVELS: number = 4;
export const HUMANOID_BEAST_HP: number = 8;
export const ENGULF_DAMAGE_INTERVAL: number = 500;
export const ENGULF_ESCAPE_ATTACKS: number = 3;
export const DEVOUR_RANGE: number = 35;
export const DEVOUR_ANIM_DURATION: number = 500;
export const DEVOUR_COOLDOWN: number = 800;
export const DEVOUR_HP_THRESHOLD: number = 0.3;
export const DEVOUR_XP_BASE: number = 5;
export const DRILL_BREAK_HITS: number = 3;
export const XP_ORB_SIZE: number = 6;
export const XP_COLLECT_RANGE: number = 40;
export const XP_MAGNET_RANGE: number = 80;
export const MATERIAL_MAGNET_RANGE: number = 60;
export const MATERIAL_COLLECT_RANGE: number = 25;
export const MATERIAL_FLY_SPEED: number = 0.15;
export const LEVEL_UP_XP: number = 10;
export const CHUNK_LOAD_RADIUS: number = 2;
export const JOYSTICK_RADIUS: number = 55;
export const MINIMAP_SIZE: number = 130;
export const FRAME_INTERVAL: number = 16;
export const MINIMAP_UPDATE_INTERVAL: number = 15;
export const MAX_PARTICLES: number = 200;
export const MAX_DYN_TILE_CACHE: number = 100;
export const NOISE_SCALE: number = 0.08;
export const CAVE_THRESHOLD: number = 0.45;
export const BIOME_SCALE: number = 0.015;

// Trap timing constants (ms)
export const TRAP_TELEGRAPH_TIME: number = 800;
export const TRAP_ACTIVE_TIME: number = 600;
export const TRAP_COOLDOWN_TIME: number = 2000;
export const TRAP_TRIGGER_RADIUS: number = 40;
export const TRAP_DAMAGE: number = 2;
export const TRAP_SIZE: number = 24;

// Mechanism constants
export const MECH_INTERACT_RANGE: number = 30;

export const COLOR_BG: string = '#08080f';
export const COLOR_WALL: string = '#1a1a2e';
export const COLOR_WALL_EDGE: string = '#252540';
export const COLOR_FLOOR: string = '#12121f';
export const COLOR_FLOOR_VAR: string = '#16162a';
export const COLOR_WATER: string = '#1a3a5c';
export const COLOR_WATER_LIGHT: string = '#2a5a8c';
export const COLOR_LAVA: string = '#8b2500';
export const COLOR_LAVA_LIGHT: string = '#cd3700';
export const COLOR_CRYSTAL: string = '#00ced1';
export const COLOR_CRYSTAL_GLOW: string = '#008b8b';
export const COLOR_MUSHROOM_CAP: string = '#cd3278';
export const COLOR_MUSHROOM_STEM: string = '#deb887';
export const COLOR_MUSHROOM_GLOW: string = '#ff69b4';
export const COLOR_GLOW_STONE: string = '#ffd700';
export const COLOR_GLOW: string = '#ffaa00';
export const COLOR_PLANT: string = '#2d8a4e';
export const COLOR_PLANT_LIGHT: string = '#4ade80';
export const COLOR_FERN: string = '#228b22';
export const COLOR_VINE: string = '#006400';
export const COLOR_FLOWER_PINK: string = '#ff69b4';
export const COLOR_FLOWER_YELLOW: string = '#ffd700';
export const COLOR_CACTUS: string = '#2e8b57';
export const COLOR_PLAYER_SKIN: string = '#f5c8a0';
export const COLOR_PLAYER_HAIR: string = '#6b3a1a';
export const COLOR_PLAYER_BODY: string = '#3b82f6';
export const COLOR_PLAYER_BODY_DARK: string = '#2563eb';
export const COLOR_DRILL_BASE: string = '#9ca3af';
export const COLOR_DRILL_TIP: string = '#fbbf24';
export const COLOR_SLIME_GRAY: string = '#6b8e7b';
export const COLOR_SLIME_GRAY_LIGHT: string = '#8fb8a0';
export const COLOR_SLIME_PURPLE: string = '#8b5cf6';
export const COLOR_SLIME_PURPLE_LIGHT: string = '#a78bfa';
export const COLOR_SLIME_RED: string = '#dc2626';
export const COLOR_SLIME_RED_LIGHT: string = '#f87171';
export const COLOR_SLIME_BLUE: string = '#2563eb';
export const COLOR_SLIME_BLUE_LIGHT: string = '#60a5fa';
export const COLOR_SLIME_YELLOW: string = '#eab308';
export const COLOR_SLIME_YELLOW_LIGHT: string = '#fde047';
export const COLOR_SLIME_GHOST: string = '#94a3b8';
export const COLOR_SLIME_GHOST_LIGHT: string = '#cbd5e1';
export const COLOR_SLIME_EYE: string = '#ffffff';
export const COLOR_SLIME_PUPIL: string = '#1a1a2e';
export const COLOR_XP_ORB: string = '#22d3ee';
export const COLOR_XP_GLOW: string = '#06b6d4';
export const COLOR_HP_FULL: string = '#ef4444';
export const COLOR_HP_EMPTY: string = '#374151';
export const COLOR_MINIMAP_BG: string = '#0a0a15';
export const COLOR_MINIMAP_PLAYER: string = '#22d3ee';
export const COLOR_MINIMAP_ENEMY: string = '#f43f5e';
export const COLOR_JOY_BASE: string = '#334155';
export const COLOR_JOY_KNOB: string = '#94a3b8';
export const COLOR_BTN_JUMP: string = '#22c55e';
export const COLOR_BTN_ATTACK: string = '#ef4444';
export const COLOR_BTN_DASH: string = '#3b82f6';
export const COLOR_ATTACK_FLASH: string = '#fbbf24';
export const COLOR_DAMAGE_PARTICLE: string = '#ff6b6b';
export const COLOR_DRILL_PARTICLE: string = '#a8a29e';

export enum TileType {
  VOID = 0,
  WALL = 1,
  FLOOR = 2,
  GLOW_STONE = 3,
  PLANT = 4,
  WATER = 5,
  CRYSTAL = 6,
  MUSHROOM = 7,
  LAVA = 8,
  BROKEN_WALL = 9
}

export enum EnemyType {
  GRAY_SLIME = 0,
  PURPLE_SLIME = 1,
  RED_SLIME = 2,
  BLUE_SLIME = 3,
  YELLOW_SLIME = 4,
  GHOST_SLIME = 5,
  HUMANOID_BEAST = 6
}

export enum BiomeType {
  NORMAL = 0,
  CRYSTAL = 1,
  MUSHROOM = 2,
  WATER = 3,
  LAVA = 4,
  SHADOW = 5
}

export enum GenderType {
  MALE = 0,
  FEMALE = 1
}

export enum WeaponForm {
  BLADE = 0,
  WHIP = 1,
  HAMMER = 2,
  STAFF = 3,
  DUAL_BLADES = 4,
  GREAT_AXE = 5
}

export enum EvolutionBranch {
  CRYSTAL = 0,
  FLAME = 1,
  SHADOW = 2,
  TOXIN = 3,
  TIDE = 4
}

export enum EvolutionLevel {
  BASE = 0,
  LEVEL_1 = 1,
  LEVEL_2 = 2,
  LEVEL_3 = 3
}

export enum MaterialType {
  CRYSTAL_ORE = 0,
  MUSHROOM_ORE = 1,
  FLAME_ORE = 2,
  ABYSS_ORE = 3,
  VOID_ORE = 4,
  CORE_NORMAL = 5,
  CORE_RARE = 6,
  FORM_CORE = 7
}

export enum ChestType {
  NORMAL = 0,
  ELITE = 1,
  BOSS = 2
}

export enum TransformForm {
  NONE = -1,
  SLIME = 0,
  GHOST = 1,
  ARMOR = 2,
  IRON_MAN = 3
}

export enum BossType {
  CRYSTAL_GUARDIAN = 0,
  MUSHROOM_KING = 1,
  LAVA_BEAST = 2,
  ABYSS_SIREN = 3,
  VOID_RIFT = 4
}

export enum BossPhase {
  PHASE_1 = 0,
  PHASE_2 = 1
}

export enum BossRole {
  PASSAGE_GUARDIAN = 0,
  OPTIONAL_CHALLENGE = 1
}

export enum TrapType {
  GROUND_SPIKES = 0,
  FALLING_ROCKS = 1,
  POISON_SPORES = 2,
  LAVA_GEYSER = 3,
  VOID_CRACK = 4,
  WATER_VORTEX = 5
}

export enum MechanismType {
  PRESSURE_PLATE = 0,
  LEVER = 1,
  PUSH_BLOCK = 2,
  CRYSTAL_REFLECTOR = 3,
  BREAKABLE_WALL = 4,
  TELEPORT_RUNE = 5
}

export enum TrapState {
  IDLE = 0,
  TELEGRAPH = 1,
  ACTIVE = 2,
  COOLDOWN = 3
}

export interface PlayerState {
  x: number;
  y: number;
  vx: number;
  vy: number;
  hp: number;
  facing: number;
  isAttacking: boolean;
  attackTimer: number;
  isDashing: boolean;
  dashTimer: number;
  dashCooldown: number;
  dashDirX: number;
  dashDirY: number;
  isJumping: boolean;
  jumpTimer: number;
  jumpHeight: number;
  invincibleTimer: number;
  animFrame: number;
  xp: number;
  level: number;
  isEngulfed: boolean;
  engulfSlimeIndex: number;
  engulfEscapeCount: number;
  engulfDamageTimer: number;
  isDrilling: boolean;
  drillTargetX: number;
  drillTargetY: number;
  drillHitCount: number;
  gender: GenderType;
  currentWeaponForm: WeaponForm;
  unlockedForms: number[];
  evolutionBranch: EvolutionBranch;
  evolutionLevel: EvolutionLevel;
  isUsingTool: boolean;
  toolCooldown: number;
  inventory: Inventory;
  isTransformed: boolean;
  transformForm: TransformForm;
  transformEnergy: number;
  transformMaxEnergy: number;
  transformCooldown: number;
  unlockedTransforms: number[];
  savedWeaponForm: WeaponForm;
  transformAnimTimer: number;
  transformFormAttackCooldown: number;
  isDevouring: boolean;
  devourTimer: number;
  devourCooldown: number;
  isDead: boolean;
}

export interface SlimeState {
  x: number;
  y: number;
  vx: number;
  vy: number;
  hp: number;
  maxHp: number;
  enemyType: EnemyType;
  active: boolean;
  bouncePhase: number;
  hitFlash: number;
  moveTimer: number;
  targetX: number;
  targetY: number;
  isEngulfing: boolean;
  engulfedPlayer: boolean;
  size: number;
  chargeTimer: number;
  isCharging: boolean;
  splitCount: number;
}

export interface XpOrb {
  x: number;
  y: number;
  value: number;
  bobPhase: number;
  active: boolean;
}

export interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  color: string;
  size: number;
}

export interface ChunkData {
  tiles: number[][];
  enemies: SlimeState[];
  generated: boolean;
  bosses: BossState[];
  chests: ChestState[];
  traps: TrapInstance[];
  mechanisms: MechanismInstance[];
  secretRooms: SecretRoom[];
  isBossRoom: boolean;
}

export interface WorldData {
  tiles: number[][];
  width: number;
  height: number;
}

export interface InputState {
  joyActive: boolean;
  joyDx: number;
  joyDy: number;
  jumpPressed: boolean;
  attackPressed: boolean;
  dashPressed: boolean;
  attackHeld: boolean;
  toolPressed: boolean;
}

export interface AmbientParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  alpha: number;
  color: string;
  life: number;
  maxLife: number;
}

export interface DynTileCacheEntry {
  bmp: ImageBitmap;
  gen: number;
}

export interface GameSettings {
  soundEnabled: boolean;
  effectsEnabled: boolean;
}

// ==================== Expansion Interfaces ====================

export interface BossState {
  x: number;
  y: number;
  vx: number;
  vy: number;
  hp: number;
  maxHp: number;
  bossType: BossType;
  bossRole: BossRole;
  phase: BossPhase;
  active: boolean;
  defeated: boolean;
  attackTimer: number;
  specialTimer: number;
  hitFlash: number;
  size: number;
  aggroRadius: number;
  extraData: number[];
}

export interface ChestState {
  x: number;
  y: number;
  chestType: ChestType;
  opened: boolean;
  active: boolean;
  guardianDefeated: boolean;
  guardianCount: number;
  openAnim: number;
}

export interface BossRoom {
  chunkX: number;
  chunkY: number;
  bossType: BossType;
  entered: boolean;
  defeated: boolean;
  chestSpawned: boolean;
}

export interface FormEvolutionData {
  branch: EvolutionBranch;
  level: EvolutionLevel;
  oreCount: number;
  coreNormalCount: number;
  coreRareCount: number;
}

export interface WeaponState {
  currentForm: WeaponForm;
  unlockedForms: WeaponForm[];
  evolutionData: FormEvolutionData[];
}

export interface Inventory {
  crystalOre: number;
  mushroomOre: number;
  flameOre: number;
  abyssOre: number;
  voidOre: number;
  coreNormal: number;
  coreRare: number;
  formCore: number;
  hpPotions: number;
  gold: number;
  transformCoreSlime: number;
  transformCoreArmor: number;
  transformCoreIronMan: number;
  transformCoreGhost: number;
}

export interface TransformCoreDrop {
  dropIndex: number;
  form: TransformForm;
}

export interface TransformUnlockNotify {
  active: boolean;
  form: TransformForm;
}

export interface MaterialDrop {
  x: number;
  y: number;
  type: MaterialType;
  count: number;
  bobPhase: number;
  active: boolean;
  flyProgress: number;
}

export interface FloatingText {
  x: number;
  y: number;
  text: string;
  color: string;
  life: number;
  maxLife: number;
}

export interface TrapInstance {
  x: number;
  y: number;
  trapType: TrapType;
  state: TrapState;
  timer: number;
  triggerRadius: number;
  damage: number;
  size: number;
  extraData: number[];
}

export interface MechanismInstance {
  x: number;
  y: number;
  mechanismType: MechanismType;
  active: boolean;
  linkedIndex: number;
  rotation: number;
  pushable: boolean;
  posX: number;
  posY: number;
}

export interface SecretRoom {
  chunkX: number;
  chunkY: number;
  wallTileX: number;
  wallTileY: number;
  revealed: boolean;
  chestType: ChestType;
}

// ==================== Expansion Constants ====================

// Evolution costs per level (index = EvolutionLevel)
export const EVOLUTION_COST_NORMAL: number[] = [0, 3, 0, 0];
export const EVOLUTION_COST_RARE: number[] = [0, 0, 1, 2];
export const EVOLUTION_COST_ORE: number[] = [0, 2, 4, 6];
export const FORM_UNLOCK_COST: number = 1;

// Boss config
export const BOSS_HP: number = 50;
export const BOSS_SIZE: number = 40;
export const BOSS_ROOM_SIZE: number = 15;
export const BOSS_ATTACK_INTERVAL: number = 3000;
export const BOSS_PHASE2_THRESHOLD: number = 0.5;
export const PASSAGE_GUARDIAN_AGGRO: number = 9999;
export const OPTIONAL_CHALLENGE_AGGRO: number = 120;
export const BOSS_RESPAWN_TIME: number = 60000;

// Chest config
export const CHEST_SIZE: number = 10;
export const CHEST_INTERACT_RANGE: number = 30;
export const NORMAL_CHEST_CHANCE: number = 0.08;
export const ELITE_CHEST_CHANCE: number = 0.03;
export const ELITE_GUARDIAN_COUNT: number = 3;

// Trap config
export const TRIGGER_DETECT_RANGE: number = 48;
export const SPIKE_DAMAGE: number = 1;
export const ROCK_DAMAGE: number = 2;
export const POISON_DPS: number = 1;
export const LAVA_GEYSER_DAMAGE: number = 2;
export const VOID_PULL_DPS: number = 1;
export const WATER_VORTEX_DAMAGE: number = 1;
export const SPIKE_TELEGRAPH_TIME: number = 500;
export const SPIKE_ACTIVE_TIME: number = 1500;
export const SPIKE_COOLDOWN_TIME: number = 2000;
export const ROCK_FALL_WARNING: number = 300;
export const POISON_CLOUD_DURATION: number = 3000;
export const POISON_EMIT_INTERVAL: number = 4000;
export const LAVA_GEYSER_WARNING: number = 800;
export const LAVA_GEYSER_ACTIVE: number = 1500;

// Mechanism config
export const PUSH_BLOCK_SPEED: number = 2.0;
export const PRESSURE_PLATE_RANGE: number = 16;
export const TELEPORT_COOLDOWN: number = 2000;
export const LEVER_LINK_RANGE: number = 320;

// Weapon form attack params: [range, width, duration, cooldown]
export const WEAPON_FORM_STATS: number[][] = [
  [28, 22, 250, 400],   // BLADE
  [40, 12, 300, 350],   // WHIP
  [20, 35, 350, 600],   // HAMMER
  [50, 10, 200, 450],   // STAFF
  [22, 18, 180, 250],   // DUAL_BLADES
  [30, 40, 400, 700],   // GREAT_AXE
];

// Weapon base damage: HAMMER > GREAT_AXE > BLADE > WHIP = DUAL_BLADES > STAFF
export const WEAPON_FORM_DAMAGE: number[] = [
  3,  // BLADE
  2,  // WHIP
  5,  // HAMMER
  1,  // STAFF
  2,  // DUAL_BLADES
  4,  // GREAT_AXE
];

// Damage bonus per evolution level
export const EVOLUTION_DAMAGE_BONUS: number = 1;

// ==================== Expansion Color Constants ====================

// Boss colors
export const COLOR_BOSS_CRYSTAL: string = '#00ced1';
export const COLOR_BOSS_MUSHROOM: string = '#cd3278';
export const COLOR_BOSS_LAVA: string = '#ff4500';
export const COLOR_BOSS_ABYSS: string = '#4169e1';
export const COLOR_BOSS_VOID: string = '#6b21a8';

/** Boss 类型 → 主题色映射（BossSpriteGenerator 与 GameEngine 共用） */
export function getBossColor(bossType: BossType): string {
  if (bossType === BossType.CRYSTAL_GUARDIAN) return COLOR_BOSS_CRYSTAL;
  if (bossType === BossType.MUSHROOM_KING) return COLOR_BOSS_MUSHROOM;
  if (bossType === BossType.LAVA_BEAST) return COLOR_BOSS_LAVA;
  if (bossType === BossType.ABYSS_SIREN) return COLOR_BOSS_ABYSS;
  return COLOR_BOSS_VOID;
}

// Chest colors
export const COLOR_CHEST_NORMAL: string = '#8b6914';
export const COLOR_CHEST_ELITE: string = '#708090';
export const COLOR_CHEST_BOSS: string = '#ffd700';
export const COLOR_CHEST_GLOW: string = '#fbbf24';

// Shadow biome colors
export const COLOR_SHADOW_FLOOR: string = '#0d0d1a';
export const COLOR_SHADOW_WALL: string = '#1a0a2e';
export const COLOR_SHADOW_PARTICLE: string = '#7c3aed';

// Trap colors
export const COLOR_SPIKE: string = '#9ca3af';
export const COLOR_SPIKE_TIP: string = '#d1d5db';
export const COLOR_ROCK: string = '#78716c';
export const COLOR_POISON_CLOUD: string = '#4ade80';
export const COLOR_LAVA_GEYSER: string = '#ff6b00';
export const COLOR_VOID_CRACK: string = '#7c3aed';
export const COLOR_VOID_PULL: string = '#a855f7';
export const COLOR_VORTEX: string = '#38bdf8';

// Mechanism colors
export const COLOR_PRESSURE_PLATE: string = '#a8a29e';
export const COLOR_PLATE_ACTIVE: string = '#fbbf24';
export const COLOR_LEVER: string = '#78716c';
export const COLOR_LEVER_HANDLE: string = '#22d3ee';
export const COLOR_PUSH_BLOCK: string = '#a3a3a3';
export const COLOR_REFLECTOR: string = '#67e8f9';
export const COLOR_BEAM: string = '#fbbf24';
export const COLOR_BREAKABLE_WALL: string = '#2a2a45';
export const COLOR_TELEPORT_RUNE: string = '#8b5cf6';
export const COLOR_TELEPORT_ENTRY: string = '#3b82f6';
export const COLOR_TELEPORT_EXIT: string = '#22c55e';

// Weapon evolution glow colors
export const COLOR_EVO_CRYSTAL: string = '#67e8f9';
export const COLOR_EVO_FLAME: string = '#f97316';
export const COLOR_EVO_SHADOW: string = '#a855f7';
export const COLOR_EVO_TOXIN: string = '#4ade80';
export const COLOR_EVO_TIDE: string = '#38bdf8';

// UI colors
export const COLOR_BOSS_HP_BAR: string = '#dc2626';
export const COLOR_BOSS_HP_BG: string = '#1f2937';
export const COLOR_TOOL_BTN: string = '#f59e0b';
export const COLOR_EVO_PANEL_BG: string = '#0f172a';
export const COLOR_EVO_PANEL_BORDER: string = '#334155';
export const COLOR_TRAP_WARNING: string = '#fbbf24';

// Transform system constants
export const TRANSFORM_MAX_ENERGY: number = 100;
export const TRANSFORM_COOLDOWN: number = 10000;
export const TRANSFORM_PASSIVE_REGEN: number = 1.0;
export const TRANSFORM_ACTIVATE_ANIM: number = 800;
export const TRANSFORM_REVERT_ANIM: number = 500;

// Energy drain per second by form (index = TransformForm value)
export const TRANSFORM_DRAIN_RATES: number[] = [2.0, 3.0, 2.5, 3.5];

// Form movement speeds
export const TRANSFORM_SPEEDS: number[] = [3.5, 2.8, 2.5, 4.0];

// Form attack energy costs
export const TRANSFORM_ATTACK_COSTS: number[] = [3, 5, 8, 2];

// Form attack cooldowns (ms)
export const TRANSFORM_ATTACK_COOLDOWNS: number[] = [600, 800, 1000, 350];

// Form damage reduction (percentage)
export const TRANSFORM_DAMAGE_REDUCTION: number[] = [0.3, 0.0, 0.5, 0.0];

// Energy recovery from kills
export const TRANSFORM_ENERGY_KILL_SLIME: number = 5;
export const TRANSFORM_ENERGY_KILL_ELITE: number = 10;
export const TRANSFORM_ENERGY_KILL_BOSS: number = 50;
export const TRANSFORM_ENERGY_XP_ORB: number = 1;

// Transform form colors
export const COLOR_TRANSFORM_SLIME: string = '#4ade80';
export const COLOR_TRANSFORM_SLIME_DARK: string = '#22c55e';
export const COLOR_TRANSFORM_GHOST: string = '#a78bfa';
export const COLOR_TRANSFORM_GHOST_DARK: string = '#7c3aed';
export const COLOR_TRANSFORM_ARMOR: string = '#94a3b8';
export const COLOR_TRANSFORM_ARMOR_ACCENT: string = '#ef4444';
export const COLOR_TRANSFORM_IRON_RED: string = '#dc2626';
export const COLOR_TRANSFORM_IRON_GOLD: string = '#fbbf24';
export const COLOR_TRANSFORM_ENERGY_BG: string = '#1f2937';
export const COLOR_TRANSFORM_BTN_LOCKED: string = '#4b5563';
export const COLOR_TRANSFORM_BTN_READY: string = '#22d3ee';
export const COLOR_TRANSFORM_FLASH: string = '#ffffff';

// Female character colors
export const COLOR_PLAYER_FEMALE_BODY: string = '#8b5cf6';
export const COLOR_PLAYER_FEMALE_BODY_DARK: string = '#7c3aed';
export const COLOR_PLAYER_FEMALE_HAIR: string = '#4a1a6b';

export interface SaveData {
  playerX: number;
  playerY: number;
  hp: number;
  xp: number;
  level: number;
  inventory: Inventory;
  currentWeaponForm: WeaponForm;
  unlockedForms: number[];
  evolutionBranch: EvolutionBranch;
  evolutionLevel: EvolutionLevel;
  isTransformed: boolean;
  transformForm: TransformForm;
  transformEnergy: number;
  unlockedTransforms: number[];
  activeSkills: number[];
  passiveSkills: number[];
  timestamp: number;
}
