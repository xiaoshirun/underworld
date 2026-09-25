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
export const SLIME_SIZE: number = 12;
export const SLIME_SPEED: number = 1.2;
export const PURPLE_SLIME_SPEED: number = 2.0;
export const PURPLE_SLIME_DETECT: number = 180;
export const RED_SLIME_SPEED: number = 3.5;
export const RED_SLIME_DETECT: number = 150;
export const BLUE_SLIME_SPEED: number = 2.5;
export const SLIME_HP: number = 3;
export const SLIME_DAMAGE: number = 1;
export const SLIME_KNOCKBACK: number = 8;
export const ENGULF_DAMAGE_INTERVAL: number = 500;
export const ENGULF_ESCAPE_ATTACKS: number = 3;
export const DRILL_BREAK_HITS: number = 3;
export const XP_ORB_SIZE: number = 6;
export const XP_COLLECT_RANGE: number = 40;
export const XP_MAGNET_RANGE: number = 80;
export const LEVEL_UP_XP: number = 10;
export const CHUNK_LOAD_RADIUS: number = 3;
export const JOYSTICK_RADIUS: number = 55;
export const MINIMAP_SIZE: number = 130;
export const FRAME_INTERVAL: number = 16;
export const MINIMAP_UPDATE_INTERVAL: number = 5;
export const NOISE_SCALE: number = 0.08;
export const CAVE_THRESHOLD: number = 0.45;
export const BIOME_SCALE: number = 0.015;

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
  GHOST_SLIME = 5
}

export enum BiomeType {
  NORMAL = 0,
  CRYSTAL = 1,
  MUSHROOM = 2,
  WATER = 3,
  LAVA = 4
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

export interface GameSettings {
  soundEnabled: boolean;
  effectsEnabled: boolean;
}
