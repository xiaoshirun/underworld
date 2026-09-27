import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE, PLAYER_SPEED,
  DASH_SPEED, DASH_DURATION, DASH_COOLDOWN, ATTACK_DURATION, ATTACK_COOLDOWN,
  ATTACK_RANGE, ATTACK_WIDTH, PLAYER_MAX_HP, INVINCIBLE_DURATION,
  SLIME_SIZE, SLIME_SPEED, PURPLE_SLIME_SPEED, PURPLE_SLIME_DETECT,
  RED_SLIME_SPEED, RED_SLIME_DETECT, BLUE_SLIME_SPEED,
  SLIME_DAMAGE, SLIME_KNOCKBACK,
  ENGULF_DAMAGE_INTERVAL, ENGULF_ESCAPE_ATTACKS, DRILL_BREAK_HITS,
  XP_ORB_SIZE, XP_COLLECT_RANGE, XP_MAGNET_RANGE, LEVEL_UP_XP,
  CHUNK_LOAD_RADIUS,
  MINIMAP_SIZE, FRAME_INTERVAL, MINIMAP_UPDATE_INTERVAL,
  TileType, EnemyType, BiomeType, PlayerState, SlimeState, XpOrb, Particle,
  ChunkData, InputState, GameSettings, AmbientParticle,
  GenderType, WeaponForm, EvolutionBranch, EvolutionLevel,
  BossState, ChestState, ChestType, BossRoom, MaterialDrop, TrapInstance, MechanismInstance,
  Inventory, TrapType, TrapState,
  TransformCoreDrop, TransformUnlockNotify,
  MechanismType, SecretRoom,
  BossType, BossRole, BossPhase, MaterialType,
  BOSS_HP, BOSS_SIZE, BOSS_ATTACK_INTERVAL, BOSS_PHASE2_THRESHOLD,
  BOSS_RESPAWN_TIME, BOSS_ROOM_SIZE,
  PASSAGE_GUARDIAN_AGGRO, OPTIONAL_CHALLENGE_AGGRO,
  WEAPON_FORM_STATS,
  TRAP_TELEGRAPH_TIME, TRAP_ACTIVE_TIME, TRAP_COOLDOWN_TIME, TRAP_TRIGGER_RADIUS, TRAP_DAMAGE, TRAP_SIZE,
  MECH_INTERACT_RANGE, PUSH_BLOCK_SPEED, TELEPORT_COOLDOWN, PRESSURE_PLATE_RANGE,
  CHEST_SIZE, CHEST_INTERACT_RANGE,
  EVOLUTION_COST_ORE, EVOLUTION_COST_NORMAL, EVOLUTION_COST_RARE, FORM_UNLOCK_COST,
  COLOR_BG, COLOR_WALL, COLOR_WALL_EDGE, COLOR_FLOOR, COLOR_FLOOR_VAR,
  COLOR_WATER, COLOR_WATER_LIGHT, COLOR_LAVA, COLOR_LAVA_LIGHT,
  COLOR_CRYSTAL, COLOR_CRYSTAL_GLOW,
  COLOR_MUSHROOM_CAP, COLOR_MUSHROOM_STEM, COLOR_MUSHROOM_GLOW,
  COLOR_GLOW_STONE, COLOR_GLOW, COLOR_PLANT, COLOR_PLANT_LIGHT,
  COLOR_PLAYER_SKIN, COLOR_PLAYER_HAIR, COLOR_PLAYER_BODY, COLOR_PLAYER_BODY_DARK,
  COLOR_PLAYER_FEMALE_BODY, COLOR_PLAYER_FEMALE_BODY_DARK, COLOR_PLAYER_FEMALE_HAIR,
  COLOR_DRILL_BASE, COLOR_DRILL_TIP,
  COLOR_SLIME_GRAY, COLOR_SLIME_GRAY_LIGHT, COLOR_SLIME_PURPLE, COLOR_SLIME_PURPLE_LIGHT,
  COLOR_SLIME_RED, COLOR_SLIME_RED_LIGHT, COLOR_SLIME_BLUE, COLOR_SLIME_BLUE_LIGHT,
  COLOR_SLIME_YELLOW, COLOR_SLIME_YELLOW_LIGHT, COLOR_SLIME_GHOST, COLOR_SLIME_GHOST_LIGHT,
  COLOR_SLIME_EYE, COLOR_SLIME_PUPIL,
  COLOR_XP_ORB, COLOR_XP_GLOW,
  COLOR_MINIMAP_BG, COLOR_MINIMAP_PLAYER, COLOR_MINIMAP_ENEMY,
  COLOR_ATTACK_FLASH, COLOR_DAMAGE_PARTICLE, COLOR_DRILL_PARTICLE,
  COLOR_SPIKE, COLOR_SPIKE_TIP, COLOR_ROCK, COLOR_POISON_CLOUD,
  COLOR_LAVA_GEYSER, COLOR_VOID_CRACK, COLOR_VOID_PULL, COLOR_VORTEX,
  COLOR_TRAP_WARNING,
  COLOR_PRESSURE_PLATE, COLOR_PLATE_ACTIVE, COLOR_LEVER, COLOR_LEVER_HANDLE,
  COLOR_PUSH_BLOCK, COLOR_REFLECTOR, COLOR_BEAM, COLOR_BREAKABLE_WALL,
  COLOR_TELEPORT_RUNE, COLOR_TELEPORT_ENTRY, COLOR_TELEPORT_EXIT,
  COLOR_BOSS_CRYSTAL, COLOR_BOSS_MUSHROOM, COLOR_BOSS_LAVA, COLOR_BOSS_ABYSS, COLOR_BOSS_VOID,
  COLOR_BOSS_HP_BAR, COLOR_BOSS_HP_BG,
  COLOR_CHEST_NORMAL, COLOR_CHEST_ELITE, COLOR_CHEST_BOSS, COLOR_CHEST_GLOW,
  COLOR_SHADOW_FLOOR, COLOR_SHADOW_WALL, COLOR_SHADOW_PARTICLE,
  TransformForm, TRANSFORM_MAX_ENERGY, TRANSFORM_COOLDOWN, TRANSFORM_PASSIVE_REGEN,
  TRANSFORM_DRAIN_RATES, TRANSFORM_SPEEDS, TRANSFORM_ATTACK_COSTS, TRANSFORM_ATTACK_COOLDOWNS,
  TRANSFORM_DAMAGE_REDUCTION, TRANSFORM_ENERGY_KILL_SLIME,
  TRANSFORM_ENERGY_KILL_BOSS, TRANSFORM_ENERGY_XP_ORB, TRANSFORM_ACTIVATE_ANIM, TRANSFORM_REVERT_ANIM,
  COLOR_TRANSFORM_SLIME, COLOR_TRANSFORM_SLIME_DARK, COLOR_TRANSFORM_GHOST, COLOR_TRANSFORM_GHOST_DARK,
  COLOR_TRANSFORM_ARMOR, COLOR_TRANSFORM_ARMOR_ACCENT, COLOR_TRANSFORM_IRON_RED, COLOR_TRANSFORM_IRON_GOLD,
  COLOR_TRANSFORM_FLASH,
  GameState, SaveData, SAVE_VERSION, AUTO_SAVE_INTERVAL,
} from './GameConstants';
import { WorldGenerator } from './WorldGenerator';
import { AudioManager } from './AudioManager';
import { ParticleManager, ParticleEmitter, EmitterConfig, EmitterMode, ParticleShape,
  createExplosionConfig, createSparkConfig, createDustConfig, createTrailConfig,
  createBloodConfig, createMagicConfig, createSmokeConfig } from './ParticleSystem';
import { PhysicsEngine, PhysicsBody, createBody, vec2Distance, vec2Normalize, vec2 } from './PhysicsEngine';
import { TileBatchRenderer, SpriteBatch, GlowBatchRenderer } from './SpriteBatch';
import { GameContext, ChunkCacheEntry } from './GameContext';
import { PlayerMovementSystem, MovementBridge } from './systems/PlayerMovementSystem';
import { PlayerCombatSystem } from './systems/PlayerCombatSystem';
import { TransformSystem, TransformBridge } from './systems/TransformSystem';

const CACHE_CANVAS_SIZE: number = CHUNK_SIZE * TILE_SIZE + 32;
const CACHE_PADDING: number = 16;

export class GameEngine extends GameContext implements MovementBridge, TransformBridge {
  private movementSystem: PlayerMovementSystem | null = null;
  private combatSystem: PlayerCombatSystem | null = null;
  private transformSystem: TransformSystem | null = null;

  init(ctx: CanvasRenderingContext2D, minimapCtx: CanvasRenderingContext2D, screenW: number, screenH: number,
    cacheCtxs?: CanvasRenderingContext2D[], appContext?: Object): void {
    this.ctx = ctx;
    this.minimapCtx = minimapCtx;
    this.screenW = screenW;
    this.screenH = screenH;
    if (appContext) {
      this.context = appContext;
    }

    if (cacheCtxs) {
      this.cacheCtxs = cacheCtxs;
      this.cacheEntryPool = new Array(cacheCtxs.length).fill(null);
      this.freePoolIndices = [];
      for (let i: number = 0; i < cacheCtxs.length; i++) {
        this.freePoolIndices.push(i);
      }
    }

    this.audio.init();

    this.loadChunksAround(0, 0);

    const startX: number = CHUNK_SIZE * TILE_SIZE / 2;
    const startY: number = CHUNK_SIZE * TILE_SIZE / 2;
    this.player = {
      x: startX, y: startY, vx: 0, vy: 0, hp: PLAYER_MAX_HP,
      facing: 0, isAttacking: false, attackTimer: 0,
      isDashing: false, dashTimer: 0, dashCooldown: 0, dashDirX: 0, dashDirY: 0,
      isJumping: false, jumpTimer: 0, jumpHeight: 0, invincibleTimer: 0, animFrame: 0,
      xp: 0, level: 1,
      isEngulfed: false, engulfSlimeIndex: -1, engulfEscapeCount: 0, engulfDamageTimer: 0,
      isDrilling: false, drillTargetX: 0, drillTargetY: 0, drillHitCount: 0,
      gender: this.playerGender,
      currentWeaponForm: WeaponForm.BLADE,
      unlockedForms: [WeaponForm.BLADE, WeaponForm.WHIP, WeaponForm.HAMMER, WeaponForm.STAFF, WeaponForm.DUAL_BLADES, WeaponForm.GREAT_AXE],
      evolutionBranch: EvolutionBranch.CRYSTAL,
      evolutionLevel: EvolutionLevel.BASE,
      isUsingTool: false,
      toolCooldown: 0,
      inventory: {
        crystalOre: 0, mushroomOre: 0, flameOre: 0, abyssOre: 0, voidOre: 0,
        coreNormal: 0, coreRare: 0, formCore: 0,
        hpPotions: 3, gold: 0,
        transformCoreSlime: 0, transformCoreArmor: 0,
        transformCoreIronMan: 0, transformCoreGhost: 0
      },
      isTransformed: false,
      transformForm: TransformForm.NONE,
      transformEnergy: TRANSFORM_MAX_ENERGY,
      transformMaxEnergy: TRANSFORM_MAX_ENERGY,
      transformCooldown: 0,
      unlockedTransforms: [],
      savedWeaponForm: WeaponForm.BLADE,
      transformAnimTimer: 0,
      transformFormAttackCooldown: 0
    };

    this.cameraX = startX - screenW / 2;
    this.cameraY = startY - screenH / 2;

    // Clear spawn area so player isn't stuck in walls
    const spawnRadius: number = 3;
    const spawnTX: number = Math.floor(startX / TILE_SIZE);
    const spawnTY: number = Math.floor(startY / TILE_SIZE);
    for (let dy: number = -spawnRadius; dy <= spawnRadius; dy++) {
      for (let dx: number = -spawnRadius; dx <= spawnRadius; dx++) {
        const tx: number = spawnTX + dx;
        const ty: number = spawnTY + dy;
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);
        if (tile === TileType.WALL) {
          this.setTile(tx * TILE_SIZE + TILE_SIZE / 2, ty * TILE_SIZE + TILE_SIZE / 2, TileType.FLOOR);
        }
      }
    }

    this.initAmbientParticles();
    this.movementSystem = new PlayerMovementSystem(this, this);
    this.combatSystem = new PlayerCombatSystem(this);
    this.transformSystem = new TransformSystem(this, this);
    this.startLoop();
  }

  private startLoop(): void {
    this.gameLoopId = setInterval(() => {
      this.update(FRAME_INTERVAL);
      this.render();
      this.frameCount++;
    }, FRAME_INTERVAL);
  }

  destroy(): void {
    if (this.gameLoopId !== -1) {
      clearInterval(this.gameLoopId);
      this.gameLoopId = -1;
    }
    this.audio.destroy();
  }

  setInputJoy(active: boolean, dx: number, dy: number): void {
    this.input.joyActive = active;
    this.input.joyDx = dx;
    this.input.joyDy = dy;
  }

  setInputJump(pressed: boolean): void {
    this.input.jumpPressed = pressed;
  }

  setInputAttack(pressed: boolean): void {
    this.input.attackPressed = pressed;
  }

  setInputDash(pressed: boolean): void {
    this.input.dashPressed = pressed;
  }

  getPlayerHp(): number {
    return this.player === null ? 0 : this.player.hp;
  }

  getPlayerXp(): number {
    return this.player === null ? 0 : this.player.xp;
  }

  getPlayerLevel(): number {
    return this.player === null ? 1 : this.player.level;
  }

  getInventory(): Inventory {
    if (this.player === null) {
      return {
        crystalOre: 0, mushroomOre: 0, flameOre: 0, abyssOre: 0, voidOre: 0,
        coreNormal: 0, coreRare: 0, formCore: 0, hpPotions: 0, gold: 0,
        transformCoreSlime: 0, transformCoreArmor: 0, transformCoreIronMan: 0, transformCoreGhost: 0
      };
    }
    return this.player.inventory;
  }

  getLevelUpXp(): number {
    return LEVEL_UP_XP;
  }

  getSettings(): GameSettings {
    return this.settings;
  }

  setSettings(s: GameSettings): void {
    this.settings = s;
    this.audio.setSettings(s);
  }

  setGender(g: GenderType): void {
    this.playerGender = g;
    if (this.player !== null) {
      this.player.gender = g;
    }
  }

  setInputTool(pressed: boolean): void {
    this.input.toolPressed = pressed;
  }

  switchWeaponForm(form: WeaponForm): void {
    if (this.player === null) return;
    const forms: WeaponForm[] = this.player.unlockedForms;
    let found: boolean = false;
    for (let i: number = 0; i < forms.length; i++) {
      if (forms[i] === form) { found = true; break; }
    }
    if (!found) return;
    this.player.currentWeaponForm = form;
  }

  cycleWeaponForm(): void {
    if (this.player === null) return;
    const forms: WeaponForm[] = this.player.unlockedForms;
    if (forms.length <= 1) return;
    let idx: number = 0;
    for (let i: number = 0; i < forms.length; i++) {
      if (forms[i] === this.player.currentWeaponForm) { idx = i; break; }
    }
    const nextIdx: number = (idx + 1) % forms.length;
    this.player.currentWeaponForm = forms[nextIdx];
  }

  getCurrentWeaponForm(): WeaponForm {
    if (this.player === null) return WeaponForm.BLADE;
    return this.player.currentWeaponForm;
  }

  getWeaponFormName(form: WeaponForm): string {
    const names: string[] = ['刃', '鞭', '锤', '杖', '双刃', '巨斧'];
    return names[form];
  }

  private buildChunkCache(cx: number, cy: number): void {
    if (this.cacheCtxs.length === 0 || this.freePoolIndices.length === 0) return;
    const key: string = this.chunkKey(cx, cy);
    if (this.activeChunkCaches.has(key)) return;

    const poolIndex: number = this.freePoolIndices.pop()!;
    const cacheCtx: CanvasRenderingContext2D = this.cacheCtxs[poolIndex];

    cacheCtx.clearRect(0, 0, CACHE_CANVAS_SIZE, CACHE_CANVAS_SIZE);

    const chunkWorldX: number = cx * this.chunkPixelSize;
    const chunkWorldY: number = cy * this.chunkPixelSize;
    const cacheOffX: number = CACHE_PADDING - chunkWorldX;
    const cacheOffY: number = CACHE_PADDING - chunkWorldY;

    const camWorldX: number = this.cameraX + this.screenW / 2;
    const camWorldY: number = this.cameraY + this.screenH / 2;
    const viewBiome: BiomeType = this.worldGen.getBiome(camWorldX, camWorldY);
    const isShadow: boolean = viewBiome === BiomeType.SHADOW;
    const floorColor: string = isShadow ? COLOR_SHADOW_FLOOR : COLOR_FLOOR;
    const floorVarColor: string = isShadow ? '#0a0a16' : COLOR_FLOOR_VAR;
    const wallColor: string = isShadow ? COLOR_SHADOW_WALL : COLOR_WALL;

    const startTX: number = cx * CHUNK_SIZE;
    const startTY: number = cy * CHUNK_SIZE;
    const endTX: number = startTX + CHUNK_SIZE;
    const endTY: number = startTY + CHUNK_SIZE;

    for (let ty: number = startTY; ty < endTY; ty++) {
      for (let tx: number = startTX; tx < endTX; tx++) {
        const screenX: number = tx * TILE_SIZE + cacheOffX;
        const screenY: number = ty * TILE_SIZE + cacheOffY;
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);

        if (tile === TileType.WALL) {
          this.renderStaticWall(cacheCtx, screenX, screenY, tx, ty, wallColor, isShadow);
        } else if (tile === TileType.FLOOR) {
          this.renderStaticFloor(cacheCtx, screenX, screenY, tx, ty, floorColor, floorVarColor, isShadow);
        } else if (tile === TileType.BROKEN_WALL) {
          this.renderStaticBrokenWall(cacheCtx, screenX, screenY);
        } else if (tile === TileType.PLANT) {
          this.renderStaticPlant(cacheCtx, screenX, screenY, floorColor);
        }
      }
    }

    const entry: ChunkCacheEntry = { key: key, poolIndex: poolIndex, isShadow: isShadow };
    this.cacheEntryPool[poolIndex] = entry;
    this.activeChunkCaches.set(key, entry);
  }

  private renderStaticWall(c: CanvasRenderingContext2D, screenX: number, screenY: number,
    tx: number, ty: number, wallColor: string, isShadow: boolean): void {
    c.fillStyle = wallColor;
    c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);

    const brickH: number = 8;
    const brickW: number = 16;
    const row: number = ty % 2;
    c.fillStyle = isShadow ? '#2d1050' : COLOR_WALL_EDGE;
    c.fillRect(screenX, screenY, TILE_SIZE, 1);
    c.fillRect(screenX, screenY + brickH, TILE_SIZE, 1);
    c.fillRect(screenX, screenY + brickH * 2, TILE_SIZE, 1);
    c.fillRect(screenX, screenY + brickH * 3, TILE_SIZE, 1);
    const vOff: number = row === 0 ? 0 : brickW / 2;
    c.fillRect(screenX + vOff, screenY, 1, brickH);
    c.fillRect(screenX + vOff + brickW, screenY, 1, brickH);
    c.fillRect(screenX + vOff + brickW / 2, screenY + brickH, 1, brickH);
    c.fillRect(screenX + vOff + brickW * 1.5, screenY + brickH, 1, brickH);
    c.fillRect(screenX + vOff, screenY + brickH * 2, 1, brickH);
    c.fillRect(screenX + vOff + brickW, screenY + brickH * 2, 1, brickH);
    c.fillRect(screenX + vOff + brickW / 2, screenY + brickH * 3, 1, brickH);

    const hash: number = ((tx * 31 + ty * 17) % 7);
    if (hash === 0) {
      c.fillStyle = '#1f1f35';
      c.fillRect(screenX + 4, screenY + 3, 3, 2);
    } else if (hash === 1) {
      c.fillStyle = '#1f1f35';
      c.fillRect(screenX + 20, screenY + 18, 4, 2);
    } else if (hash === 3) {
      c.fillStyle = '#22223a';
      c.fillRect(screenX + 10, screenY + 12, 2, 3);
    }

    const oreHash: number = ((tx * 73 + ty * 137) % 47);
    if (oreHash < 3) {
      c.fillStyle = '#8b4513';
      c.fillRect(screenX + 6, screenY + 8, 4, 3);
      c.fillRect(screenX + 9, screenY + 10, 3, 4);
      c.fillStyle = '#cd7f32';
      c.fillRect(screenX + 7, screenY + 9, 2, 2);
      c.fillRect(screenX + 10, screenY + 11, 2, 2);
    } else if (oreHash === 3) {
      c.fillStyle = '#4a5568';
      c.fillRect(screenX + 18, screenY + 4, 5, 3);
      c.fillRect(screenX + 20, screenY + 6, 3, 4);
      c.fillStyle = '#718096';
      c.fillRect(screenX + 19, screenY + 5, 3, 2);
    } else if (oreHash === 4) {
      c.fillStyle = '#a0aec0';
      c.fillRect(screenX + 4, screenY + 20, 3, 3);
      c.fillRect(screenX + 6, screenY + 22, 4, 2);
      c.fillStyle = '#e2e8f0';
      c.fillRect(screenX + 5, screenY + 21, 2, 2);
    } else if (oreHash === 5) {
      c.fillStyle = '#b7791f';
      c.fillRect(screenX + 14, screenY + 14, 4, 3);
      c.fillRect(screenX + 16, screenY + 16, 3, 4);
      c.fillStyle = '#ecc94b';
      c.fillRect(screenX + 15, screenY + 15, 2, 2);
    }

    const belowTile: number = this.getTile(tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
    if (belowTile === TileType.FLOOR || belowTile === TileType.BROKEN_WALL) {
      c.fillStyle = isShadow ? '#4a1a6a' : '#2d6b3a';
      c.fillRect(screenX, screenY + TILE_SIZE - 3, TILE_SIZE, 3);
      c.fillStyle = isShadow ? '#6b2a9a' : '#3d8a4e';
      c.fillRect(screenX + 2, screenY + TILE_SIZE - 5, 2, 3);
      c.fillRect(screenX + 8, screenY + TILE_SIZE - 4, 1, 2);
      c.fillRect(screenX + 14, screenY + TILE_SIZE - 6, 2, 4);
      c.fillRect(screenX + 22, screenY + TILE_SIZE - 4, 1, 2);
      c.fillRect(screenX + 28, screenY + TILE_SIZE - 5, 2, 3);
    }

    const belowWall: number = this.getTile(tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
    if (belowWall !== TileType.WALL && belowWall !== TileType.FLOOR) {
      const vineHash: number = ((tx * 41 + ty * 67) % 11);
      if (vineHash < 3) {
        const vineLen: number = 6 + (vineHash * 4);
        c.fillStyle = isShadow ? '#3a1a5a' : '#1a4a2a';
        c.fillRect(screenX + 4 + vineHash * 3, screenY + TILE_SIZE, 1, vineLen);
        c.fillRect(screenX + 5 + vineHash * 3, screenY + TILE_SIZE + vineLen - 2, 1, 3);
        c.fillStyle = isShadow ? '#5a2a8a' : '#2d6b3a';
        c.fillRect(screenX + 3 + vineHash * 3, screenY + TILE_SIZE + vineLen, 3, 2);
      } else if (vineHash < 5) {
        c.fillStyle = isShadow ? '#3a1a5a' : '#1a4a2a';
        c.fillRect(screenX + 8, screenY + TILE_SIZE, 1, 4);
        c.fillRect(screenX + 18, screenY + TILE_SIZE, 1, 6);
        c.fillRect(screenX + 26, screenY + TILE_SIZE, 1, 3);
      }
    }
  }

  private renderStaticFloor(c: CanvasRenderingContext2D, screenX: number, screenY: number,
    tx: number, ty: number, floorColor: string, floorVarColor: string, isShadow: boolean): void {
    const variant: number = ((tx * 7 + ty * 13) % 5);
    c.fillStyle = variant === 0 ? floorColor : variant === 1 ? floorVarColor : variant === 2 ? '#14142a' : variant === 3 ? '#10101e' : floorColor;
    c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);

    const hash: number = ((tx * 23 + ty * 11) % 8);
    if (hash === 0) {
      c.fillStyle = '#1e1e38';
      c.fillRect(screenX + 4, screenY + 8, 4, 3);
      c.fillRect(screenX + 18, screenY + 20, 3, 2);
    } else if (hash === 1) {
      c.fillStyle = '#0e0e1a';
      c.fillRect(screenX + 12, screenY + 4, 2, 2);
      c.fillRect(screenX + 24, screenY + 16, 3, 2);
      c.fillRect(screenX + 6, screenY + 24, 2, 2);
    } else if (hash === 2) {
      c.fillStyle = '#1a1a30';
      c.fillRect(screenX + 8, screenY + 14, 5, 3);
    } else if (hash === 4) {
      c.fillStyle = '#0c0c18';
      c.fillRect(screenX + 20, screenY + 6, 2, 3);
      c.fillRect(screenX + 2, screenY + 22, 3, 2);
    }

    c.fillStyle = '#0a0a14';
    c.globalAlpha = 0.12;
    c.fillRect(screenX, screenY + TILE_SIZE - 1, TILE_SIZE, 1);
    c.fillRect(screenX + TILE_SIZE - 1, screenY, 1, TILE_SIZE);
    c.globalAlpha = 1.0;

    const aboveTile: number = this.getTile(tx * TILE_SIZE, (ty - 1) * TILE_SIZE);
    if (aboveTile === TileType.WALL) {
      c.fillStyle = isShadow ? '#1a0a2e' : '#1a1a28';
      c.fillRect(screenX, screenY, TILE_SIZE, 3);
    }

    if (aboveTile !== TileType.WALL && aboveTile !== TileType.FLOOR) {
      const stHash: number = ((tx * 53 + ty * 97) % 13);
      if (stHash < 2) {
        c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
        c.fillRect(screenX + 12, screenY, 8, 2);
        c.fillRect(screenX + 14, screenY + 2, 4, 4);
        c.fillRect(screenX + 15, screenY + 6, 2, 4);
        c.fillStyle = isShadow ? '#3a2a5a' : '#3a3a50';
        c.fillRect(screenX + 13, screenY, 2, 3);
      } else if (stHash < 5) {
        c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
        c.fillRect(screenX + 6 + stHash * 4, screenY, 3, 2);
        c.fillRect(screenX + 7 + stHash * 4, screenY + 2, 1, 3 + stHash);
      }
    }

    const belowFloor: number = this.getTile(tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
    if (belowFloor !== TileType.FLOOR && belowFloor !== TileType.WALL) {
      const smHash: number = ((tx * 37 + ty * 79) % 17);
      if (smHash < 2) {
        c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
        c.fillRect(screenX + 10, screenY + TILE_SIZE - 2, 12, 2);
        c.fillRect(screenX + 12, screenY + TILE_SIZE - 6, 8, 4);
        c.fillRect(screenX + 14, screenY + TILE_SIZE - 9, 4, 3);
        c.fillStyle = isShadow ? '#3a2a5a' : '#3a3a50';
        c.fillRect(screenX + 15, screenY + TILE_SIZE - 8, 2, 2);
      } else if (smHash < 5) {
        c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
        c.fillRect(screenX + 4 + smHash * 5, screenY + TILE_SIZE - 2, 3, 2);
        c.fillRect(screenX + 5 + smHash * 5, screenY + TILE_SIZE - 4 - smHash, 1, 2 + smHash);
      }
    }
  }

  private renderStaticBrokenWall(c: CanvasRenderingContext2D, screenX: number, screenY: number): void {
    c.fillStyle = '#2a2a3e';
    c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
    c.fillStyle = '#3a3a50';
    c.fillRect(screenX + 2, screenY + 2, 8, 6);
    c.fillRect(screenX + 16, screenY + 10, 10, 7);
    c.fillRect(screenX + 6, screenY + 20, 7, 8);
    c.fillStyle = '#4a4a60';
    c.fillRect(screenX + 4, screenY + 4, 4, 3);
    c.fillRect(screenX + 18, screenY + 12, 5, 3);
    c.fillStyle = '#1a1a2e';
    c.fillRect(screenX + 12, screenY + 2, 1, 8);
    c.fillRect(screenX + 14, screenY + 6, 1, 6);
    c.fillRect(screenX + 26, screenY + 18, 1, 10);
  }

  private renderStaticPlant(c: CanvasRenderingContext2D, screenX: number, screenY: number, floorColor: string): void {
    c.fillStyle = floorColor;
    c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
    c.fillStyle = COLOR_PLANT;
    c.fillRect(screenX + 14, screenY + 16, 4, 12);
    c.fillStyle = COLOR_PLANT_LIGHT;
    c.beginPath();
    c.arc(screenX + 16, screenY + 14, 6, 0, Math.PI * 2);
    c.fill();
    c.fillStyle = COLOR_PLANT;
    c.beginPath();
    c.arc(screenX + 12, screenY + 18, 4, 0, Math.PI * 2);
    c.fill();
  }

  private update(dt: number): void {
    if (this.player === null) return;
    if (this.state !== GameState.PLAYING) return;
    const p: PlayerState = this.player;

    const ptx: number = Math.floor(p.x / TILE_SIZE);
    const pty: number = Math.floor(p.y / TILE_SIZE);
    this.loadChunksAround(ptx, pty);

    this.movementSystem!.update(dt);
    // === Transform System Update ===
    this.updateTransformSystem(p, dt);
    this.updateEnemies(dt);
    this.updateBosses(dt);
    this.checkBossRoomEntry(p);
    this.collectMaterialDrops(p);
    this.checkChestInteraction();
    this.updateChestAnims(dt);
    this.updateTraps(dt);
    this.updateMechanisms(dt);
    this.updateXpOrbs(dt);
    this.updateParticles(dt);
    this.particleMgr.update(dt);
    this.updateAmbientParticles(dt);
    this.updateCamera(p);
    this.updateShake(dt);
    if (this.damageFlashTimer > 0) {
      this.damageFlashTimer -= dt;
      if (this.damageFlashTimer < 0) this.damageFlashTimer = 0;
    }

    // Death detection
    if (p.hp <= 0 && this.state === GameState.PLAYING) {
      this.handlePlayerDeath();
    }

    // Auto-save interval
    if (this.frameCount > 0 && this.frameCount % AUTO_SAVE_INTERVAL === 0) {
      this.autoSave();
    }
  }

  // === Transform System ===

  private updateTransformSystem(p: PlayerState, dt: number): void {
    this.transformSystem!.update(p, dt);
  }

  // Public getters for UI
  getIsTransformed(): boolean {
    return this.player !== null && this.player.isTransformed;
  }

  getTransformEnergy(): number {
    return this.player !== null ? this.player.transformEnergy : 0;
  }

  getTransformMaxEnergy(): number {
    return this.player !== null ? this.player.transformMaxEnergy : TRANSFORM_MAX_ENERGY;
  }

  getTransformForm(): TransformForm {
    return this.player !== null ? this.player.transformForm : TransformForm.NONE;
  }

  getTransformCooldown(): number {
    return this.player !== null ? this.player.transformCooldown : 0;
  }

  getUnlockedTransforms(): number[] {
    return this.player !== null ? this.player.unlockedTransforms : [];
  }

  getTransformUnlockNotify(): TransformUnlockNotify {
    return { active: this.transformUnlockNotifyTimer > 0, form: this.transformUnlockNotifyForm } as TransformUnlockNotify;
  }

  private performAttack(p: PlayerState): void {
    this.combatSystem!.performAttack(p);
  }

  private updateEnemies(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;

      s.bouncePhase += 0.05;
      if (s.hitFlash > 0) s.hitFlash -= dt;
      s.vx *= 0.9;
      s.vy *= 0.9;

      if (s.isEngulfing) continue;

      const dx: number = p.x - s.x;
      const dy: number = p.y - s.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (s.enemyType) {
        case EnemyType.GRAY_SLIME: {
          s.moveTimer -= dt;
          if (s.moveTimer <= 0) {
            s.moveTimer = 2000 + Math.random() * 3000;
            const angle: number = Math.random() * Math.PI * 2;
            s.targetX = Math.cos(angle) * SLIME_SPEED;
            s.targetY = Math.sin(angle) * SLIME_SPEED;
          }
          s.vx += s.targetX * 0.02;
          s.vy += s.targetY * 0.02;
          break;
        }
        case EnemyType.PURPLE_SLIME: {
          if (dist < PURPLE_SLIME_DETECT && dist > 1) {
            s.vx += (dx / dist) * PURPLE_SLIME_SPEED * 0.1;
            s.vy += (dy / dist) * PURPLE_SLIME_SPEED * 0.1;
            if (dist < s.size + PLAYER_SIZE && p.invincibleTimer <= 0 && !p.isEngulfed) {
              if (Math.random() < 0.01) {
                s.isEngulfing = true;
                s.engulfedPlayer = true;
                p.isEngulfed = true;
                p.engulfSlimeIndex = i;
                p.engulfEscapeCount = 0;
                p.engulfDamageTimer = ENGULF_DAMAGE_INTERVAL;
                this.audio.playEngulf();
              }
            }
          }
          break;
        }
        case EnemyType.RED_SLIME: {
          if (dist < RED_SLIME_DETECT && dist > 1) {
            if (!s.isCharging) {
              s.chargeTimer -= dt;
              if (s.chargeTimer <= 0) {
                s.isCharging = true;
                s.chargeTimer = 500;
                s.vx = (dx / dist) * RED_SLIME_SPEED * 2;
                s.vy = (dy / dist) * RED_SLIME_SPEED * 2;
              } else {
                s.vx += (dx / dist) * RED_SLIME_SPEED * 0.03;
                s.vy += (dy / dist) * RED_SLIME_SPEED * 0.03;
              }
            } else {
              s.chargeTimer -= dt;
              if (s.chargeTimer <= 0) {
                s.isCharging = false;
                s.chargeTimer = 1500;
              }
            }
          }
          break;
        }
        case EnemyType.BLUE_SLIME: {
          if (dist < PURPLE_SLIME_DETECT && dist > 1) {
            s.vx += (dx / dist) * BLUE_SLIME_SPEED * 0.05;
            s.vy += (dy / dist) * BLUE_SLIME_SPEED * 0.05;
          }
          s.moveTimer -= dt;
          if (s.moveTimer <= 0) {
            s.moveTimer = 1500 + Math.random() * 2000;
            const angle: number = Math.random() * Math.PI * 2;
            s.targetX = Math.cos(angle) * BLUE_SLIME_SPEED * 0.5;
            s.targetY = Math.sin(angle) * BLUE_SLIME_SPEED * 0.5;
          }
          s.vx += s.targetX * 0.01;
          s.vy += s.targetY * 0.01;
          break;
        }
        case EnemyType.YELLOW_SLIME: {
          s.moveTimer -= dt;
          if (s.moveTimer <= 0) {
            s.moveTimer = 3000 + Math.random() * 2000;
            const angle: number = Math.random() * Math.PI * 2;
            s.targetX = Math.cos(angle) * SLIME_SPEED * 0.5;
            s.targetY = Math.sin(angle) * SLIME_SPEED * 0.5;
          }
          s.vx += s.targetX * 0.01;
          s.vy += s.targetY * 0.01;
          break;
        }
        case EnemyType.GHOST_SLIME: {
          if (dist < PURPLE_SLIME_DETECT * 1.5 && dist > 1) {
            const speed: number = PURPLE_SLIME_SPEED * 0.8;
            s.vx += (dx / dist) * speed * 0.08;
            s.vy += (dy / dist) * speed * 0.08;
          }
          break;
        }
      }

      let maxSpeed: number = SLIME_SPEED;
      switch (s.enemyType) {
        case EnemyType.PURPLE_SLIME: maxSpeed = PURPLE_SLIME_SPEED; break;
        case EnemyType.RED_SLIME: maxSpeed = s.isCharging ? RED_SLIME_SPEED * 2 : RED_SLIME_SPEED; break;
        case EnemyType.BLUE_SLIME: maxSpeed = BLUE_SLIME_SPEED; break;
        case EnemyType.GHOST_SLIME: maxSpeed = PURPLE_SLIME_SPEED * 0.8; break;
        default: maxSpeed = SLIME_SPEED; break;
      }
      const speed: number = Math.sqrt(s.vx * s.vx + s.vy * s.vy);
      if (speed > maxSpeed) {
        s.vx = (s.vx / speed) * maxSpeed;
        s.vy = (s.vy / speed) * maxSpeed;
      }

      const newX: number = s.x + s.vx;
      const newY: number = s.y + s.vy;
      if (s.enemyType === EnemyType.GHOST_SLIME) {
        s.x = newX;
        s.y = newY;
      } else {
        if (!this.checkEnemyCollision(newX, s.y)) { s.x = newX; } else { s.vx = -s.vx; }
        if (!this.checkEnemyCollision(s.x, newY)) { s.y = newY; } else { s.vy = -s.vy; }
      }

      if (p.invincibleTimer <= 0 && !p.isEngulfed && !s.isEngulfing) {
        const cdx: number = p.x - s.x;
        const cdy: number = p.y - s.y;
        const cdist: number = Math.sqrt(cdx * cdx + cdy * cdy);
        if (cdist < PLAYER_SIZE / 2 + s.size / 2) {
          let incomingDamage: number = SLIME_DAMAGE;
          if (p.isTransformed) {
            const reduction: number = TRANSFORM_DAMAGE_REDUCTION[p.transformForm as number];
            incomingDamage = Math.max(1, Math.floor(incomingDamage * (1 - reduction)));
          }
          p.hp -= incomingDamage;
          if (p.hp < 0) p.hp = 0;
          this.damageFlashTimer = 200;
          p.invincibleTimer = (p.isTransformed && p.transformForm === TransformForm.GHOST) ? 1500 : INVINCIBLE_DURATION;
          const knockAngle: number = Math.atan2(cdy, cdx);
          const knockBack: number = (p.isTransformed && p.transformForm === TransformForm.ARMOR) ? 2.5 : 5;
          p.x -= Math.cos(knockAngle) * knockBack;
          p.y -= Math.sin(knockAngle) * knockBack;
          this.shakeTimer = 150;
          this.audio.playPlayerDamage();
          if (this.settings.effectsEnabled) {
            this.particleMgr.blood(p.x, p.y, -Math.cos(knockAngle), -Math.sin(knockAngle));
          }
        }
      }
    }
  }

  private checkEnemyCollision(x: number, y: number): boolean {
    const halfSize: number = SLIME_SIZE / 2;
    const cornersX: number[] = [x - halfSize, x + halfSize];
    const cornersY: number[] = [y - halfSize, y + halfSize];
    for (let i: number = 0; i < 2; i++) {
      for (let j: number = 0; j < 2; j++) {
        const tile: number = this.getTile(cornersX[i], cornersY[j]);
        if (!this.isWalkable(tile)) return true;
      }
    }
    return false;
  }

  private updateXpOrbs(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = 0; i < this.xpOrbs.length; i++) {
      const orb: XpOrb = this.xpOrbs[i];
      if (!orb.active) continue;

      orb.bobPhase += 0.08;

      const dx: number = p.x - orb.x;
      const dy: number = p.y - orb.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < XP_MAGNET_RANGE && dist > 1) {
        const pullSpeed: number = 3.0 * (1.0 - dist / XP_MAGNET_RANGE);
        orb.x += (dx / dist) * pullSpeed;
        orb.y += (dy / dist) * pullSpeed;
      }

      if (dist < XP_COLLECT_RANGE) {
        orb.active = false;
        p.xp += orb.value;
        // Transform energy recovery from XP orb
        if (p.isTransformed) {
          p.transformEnergy += TRANSFORM_ENERGY_XP_ORB;
          if (p.transformEnergy > p.transformMaxEnergy) {
            p.transformEnergy = p.transformMaxEnergy;
          }
        }
        this.audio.playXpCollect();
        if (p.xp >= LEVEL_UP_XP) {
          p.xp -= LEVEL_UP_XP;
          p.level++;
          if (p.hp < PLAYER_MAX_HP) p.hp++;
          this.audio.playLevelUp();
          if (this.settings.effectsEnabled) {
            this.particleMgr.magic(p.x, p.y, COLOR_XP_ORB);
          }
        }
      }
    }

    if (this.xpOrbs.length > 200) {
      const active: XpOrb[] = [];
      for (let i: number = 0; i < this.xpOrbs.length; i++) {
        if (this.xpOrbs[i].active) active.push(this.xpOrbs[i]);
      }
      this.xpOrbs = active;
    }
  }

  private updateTraps(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = 0; i < this.traps.length; i++) {
      const trap: TrapInstance = this.traps[i];
      const dx: number = p.x - trap.x;
      const dy: number = p.y - trap.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (trap.state) {
        case TrapState.IDLE:
          if (dist < trap.triggerRadius) {
            trap.state = TrapState.TELEGRAPH;
            trap.timer = TRAP_TELEGRAPH_TIME;
          }
          break;

        case TrapState.TELEGRAPH:
          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.ACTIVE;
            trap.timer = TRAP_ACTIVE_TIME;
            this.audio.playPlayerDamage();
          }
          break;

        case TrapState.ACTIVE:
          trap.timer -= dt;
          if (trap.trapType === TrapType.VOID_CRACK && dist < trap.triggerRadius * 1.5) {
            const pullStrength: number = 0.8 * (1.0 - dist / (trap.triggerRadius * 1.5));
            p.vx -= (dx / dist) * pullStrength;
            p.vy -= (dy / dist) * pullStrength;
          }
          if (dist < trap.size) {
            if (p.invincibleTimer <= 0) {
              // Iron Man hovers — immune to ground traps and terrain
              if (p.isTransformed && p.transformForm === TransformForm.IRON_MAN) {
                // Skip trap damage for Iron Man
              } else {
              p.hp -= trap.damage;
              p.invincibleTimer = INVINCIBLE_DURATION;
              this.shakeTimer = 150;
              this.damageFlashTimer = 200;
              if (this.settings.effectsEnabled) {
                this.particleMgr.sparks(p.x, p.y, COLOR_DAMAGE_PARTICLE, 6);
              }
              if (trap.trapType === TrapType.WATER_VORTEX) {
                p.x += (Math.random() - 0.5) * 120;
                p.y += (Math.random() - 0.5) * 120;
              }
              } // end else (non-Iron-Man)
            }
          }
          if (trap.timer <= 0) {
            trap.state = TrapState.COOLDOWN;
            trap.timer = TRAP_COOLDOWN_TIME;
          }
          break;

        case TrapState.COOLDOWN:
          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.IDLE;
          }
          break;
      }
    }
  }

  private updateMechanisms(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    if (this.teleportCooldown > 0) this.teleportCooldown -= dt;

    for (let i: number = 0; i < this.mechanisms.length; i++) {
      const mech: MechanismInstance = this.mechanisms[i];
      const dx: number = p.x - mech.x;
      const dy: number = p.y - mech.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (mech.mechanismType) {
        case MechanismType.PRESSURE_PLATE:
          const wasActive: boolean = mech.active;
          mech.active = dist < PRESSURE_PLATE_RANGE;
          if (mech.active !== wasActive) {
            this.checkMechanismLinks(mech);
          }
          break;

        case MechanismType.PUSH_BLOCK:
          if (mech.pushable && dist < PLAYER_SIZE + 12) {
            const pushDirX: number = p.vx;
            const pushDirY: number = p.vy;
            const pushLen: number = Math.sqrt(pushDirX * pushDirX + pushDirY * pushDirY);
            if (pushLen > 0.5) {
              const newX: number = mech.posX + (pushDirX / pushLen) * PUSH_BLOCK_SPEED;
              const newY: number = mech.posY + (pushDirY / pushLen) * PUSH_BLOCK_SPEED;
              const tileAtNew: number = this.getTile(newX, newY);
              if (tileAtNew === TileType.FLOOR || tileAtNew === TileType.BROKEN_WALL) {
                mech.posX = newX;
                mech.posY = newY;
                mech.x = newX;
                mech.y = newY;
                if (this.settings.effectsEnabled && this.frameCount % 3 === 0) {
                  this.spawnParticle(mech.x, mech.y + 8, (Math.random() - 0.5) * 0.5, -0.3, 300, COLOR_DRILL_PARTICLE, 2);
                }
              }
            }
          }
          break;

        case MechanismType.TELEPORT_RUNE:
          if (dist < MECH_INTERACT_RANGE && this.teleportCooldown <= 0) {
            const pairIndex: number = mech.linkedIndex;
            if (pairIndex >= 0 && pairIndex < this.mechanisms.length) {
              const paired: MechanismInstance = this.mechanisms[pairIndex];
              if (paired.mechanismType === MechanismType.TELEPORT_RUNE) {
                p.x = paired.x;
                p.y = paired.y;
                this.teleportCooldown = TELEPORT_COOLDOWN;
                this.audio.playDash();
                if (this.settings.effectsEnabled) {
                  for (let k: number = 0; k < 10; k++) {
                    const angle: number = Math.random() * Math.PI * 2;
                    const speed: number = 1.5 + Math.random() * 2;
                    this.spawnParticle(paired.x, paired.y,
                      Math.cos(angle) * speed, Math.sin(angle) * speed, 500, COLOR_TELEPORT_RUNE, 3);
                  }
                }
              }
            }
          }
          break;

        case MechanismType.LEVER:
          if (dist < MECH_INTERACT_RANGE && this.input.toolPressed) {
            this.input.toolPressed = false;
            mech.active = !mech.active;
            mech.rotation = mech.active ? 45 : -45;
            this.audio.playDrillHit();
            this.checkMechanismLinks(mech);
          }
          break;

        case MechanismType.CRYSTAL_REFLECTOR:
          if (dist < MECH_INTERACT_RANGE && this.input.toolPressed) {
            this.input.toolPressed = false;
            mech.rotation = (mech.rotation + 60) % 360;
            this.audio.playDrillHit();
          }
          break;
      }
    }

    this.movementSystem!.checkBreakableWalls(p);
  }

  private checkMechanismLinks(mech: MechanismInstance): void {
    for (let i: number = 0; i < this.mechanisms.length; i++) {
      const other: MechanismInstance = this.mechanisms[i];
      if (other.linkedIndex >= 0 && other !== mech) {
        const linkedMech: MechanismInstance = this.mechanisms[other.linkedIndex];
        if (linkedMech === mech) {
          other.active = mech.active;
        }
      }
    }
  }

  // ==================== Boss System ====================

  private getEntranceDir(cx: number, cy: number): number {
    let h: number = (cx * 13 + 7000) * 374761393 + (cy * 13 + 8000) * 668265263;
    h = ((h ^ (h >> 13)) * 1274126177) | 0;
    return ((h ^ (h >> 16)) >>> 0) % 4;
  }

  private getBossRoomEntranceTiles(chunkX: number, chunkY: number): number[][] {
    const center: number = Math.floor(CHUNK_SIZE / 2);
    const roomRadius: number = Math.floor(BOSS_ROOM_SIZE / 2);
    const dir: number = this.getEntranceDir(chunkX, chunkY);
    const tiles: number[][] = [];

    if (dir === 0) {
      tiles.push([chunkX * CHUNK_SIZE + center - 1, chunkY * CHUNK_SIZE + center - roomRadius]);
      tiles.push([chunkX * CHUNK_SIZE + center, chunkY * CHUNK_SIZE + center - roomRadius]);
      tiles.push([chunkX * CHUNK_SIZE + center + 1, chunkY * CHUNK_SIZE + center - roomRadius]);
    } else if (dir === 1) {
      tiles.push([chunkX * CHUNK_SIZE + center - 1, chunkY * CHUNK_SIZE + center + roomRadius]);
      tiles.push([chunkX * CHUNK_SIZE + center, chunkY * CHUNK_SIZE + center + roomRadius]);
      tiles.push([chunkX * CHUNK_SIZE + center + 1, chunkY * CHUNK_SIZE + center + roomRadius]);
    } else if (dir === 2) {
      tiles.push([chunkX * CHUNK_SIZE + center - roomRadius, chunkY * CHUNK_SIZE + center - 1]);
      tiles.push([chunkX * CHUNK_SIZE + center - roomRadius, chunkY * CHUNK_SIZE + center]);
      tiles.push([chunkX * CHUNK_SIZE + center - roomRadius, chunkY * CHUNK_SIZE + center + 1]);
    } else {
      tiles.push([chunkX * CHUNK_SIZE + center + roomRadius, chunkY * CHUNK_SIZE + center - 1]);
      tiles.push([chunkX * CHUNK_SIZE + center + roomRadius, chunkY * CHUNK_SIZE + center]);
      tiles.push([chunkX * CHUNK_SIZE + center + roomRadius, chunkY * CHUNK_SIZE + center + 1]);
    }
    return tiles;
  }

  private checkBossRoomEntry(p: PlayerState): void {
    const pcx: number = Math.floor(p.x / (CHUNK_SIZE * TILE_SIZE));
    const pcy: number = Math.floor(p.y / (CHUNK_SIZE * TILE_SIZE));

    for (let i: number = 0; i < this.bossRooms.length; i++) {
      const room: BossRoom = this.bossRooms[i];
      if (room.entered || room.defeated) continue;
      if (room.chunkX !== pcx || room.chunkY !== pcy) continue;

      // Check if this chunk is actually a boss room
      const key: string = this.chunkKey(room.chunkX, room.chunkY);
      const chunk: ChunkData | undefined = this.chunks.get(key);
      if (chunk === undefined || !chunk.isBossRoom) continue;

      // Player entered the boss room - seal and spawn
      room.entered = true;
      this.bossRoomLocked = true;

      // Seal entrance tiles
      const entranceTiles: number[][] = this.getBossRoomEntranceTiles(room.chunkX, room.chunkY);
      for (let j: number = 0; j < entranceTiles.length; j++) {
        this.setTile(
          entranceTiles[j][0] * TILE_SIZE + TILE_SIZE / 2,
          entranceTiles[j][1] * TILE_SIZE + TILE_SIZE / 2,
          TileType.WALL
        );
      }

      // Activate the boss
      for (let j: number = 0; j < this.bosses.length; j++) {
        const boss: BossState = this.bosses[j];
        if (!boss.active && !boss.defeated && boss.bossType === room.bossType) {
          boss.active = true;
          this.activeBoss = boss;
        }
      }

      this.audio.playWallBreak();
      this.shakeTimer = 300;
      break;
    }
  }

  private updateBosses(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = this.bosses.length - 1; i >= 0; i--) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;

      const dx: number = p.x - boss.x;
      const dy: number = p.y - boss.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      // Movement AI
      if (boss.bossRole === BossRole.PASSAGE_GUARDIAN) {
        // Always chase player in sealed room
        if (dist > 1) {
          const speed: number = 1.5;
          boss.vx = (dx / dist) * speed;
          boss.vy = (dy / dist) * speed;
        }
      } else {
        // Optional Challenge - only chase within aggro radius
        if (dist < boss.aggroRadius) {
          if (dist > 1) {
            const speed: number = 1.8;
            boss.vx = (dx / dist) * speed;
            boss.vy = (dy / dist) * speed;
          }
        } else {
          // Wander randomly
          boss.attackTimer -= dt;
          if (boss.attackTimer <= 0) {
            const angle: number = Math.random() * Math.PI * 2;
            boss.vx = Math.cos(angle) * 0.5;
            boss.vy = Math.sin(angle) * 0.5;
            boss.attackTimer = 2000 + Math.random() * 3000;
          }
        }
      }

      boss.x += boss.vx;
      boss.y += boss.vy;

      // Attack timer
      boss.attackTimer -= dt;
      if (boss.attackTimer <= 0 && dist < boss.size + PLAYER_SIZE + 20) {
        // Melee attack
        boss.attackTimer = BOSS_ATTACK_INTERVAL;
        if (p.invincibleTimer <= 0) {
          p.hp -= 2;
          p.invincibleTimer = INVINCIBLE_DURATION;
          this.audio.playPlayerDamage();
          this.damageFlashTimer = 200;
          this.shakeTimer = 200;
          // Knockback
          if (dist > 1) {
            p.vx = -(dx / dist) * 6;
            p.vy = -(dy / dist) * 6;
          }
          if (this.settings.effectsEnabled) {
            this.particleMgr.blood(p.x, p.y, -(dx / dist), -(dy / dist));
          }
        }
      }

      // Phase transition
      if (boss.phase === BossPhase.PHASE_1 && boss.hp <= boss.maxHp * BOSS_PHASE2_THRESHOLD) {
        boss.phase = BossPhase.PHASE_2;
        boss.hitFlash = 500;
        this.shakeTimer = 400;
        if (this.settings.effectsEnabled) {
          this.particleMgr.explosion(boss.x, boss.y, this.getBossColor(boss.bossType), 20);
          this.particleMgr.sparks(boss.x, boss.y, '#ffffff', 12);
        }
      }

      // Boss death
      if (boss.hp <= 0) {
        boss.defeated = true;
        // Transform energy recovery on boss kill
        if (this.player !== null && this.player.isTransformed) {
          this.player.transformEnergy += TRANSFORM_ENERGY_KILL_BOSS;
          if (this.player.transformEnergy > this.player.transformMaxEnergy) {
            this.player.transformEnergy = this.player.transformMaxEnergy;
          }
        }
        boss.active = false;

        // Handle boss room
        if (boss.bossRole === BossRole.PASSAGE_GUARDIAN) {
          this.bossRoomLocked = false;
          this.activeBoss = null;
          // Open entrance
          for (let j: number = 0; j < this.bossRooms.length; j++) {
            const room: BossRoom = this.bossRooms[j];
            if (room.chunkX === Math.floor(boss.x / (CHUNK_SIZE * TILE_SIZE)) &&
                room.chunkY === Math.floor(boss.y / (CHUNK_SIZE * TILE_SIZE))) {
              room.defeated = true;
              const entranceTiles: number[][] = this.getBossRoomEntranceTiles(room.chunkX, room.chunkY);
              for (let e: number = 0; e < entranceTiles.length; e++) {
                this.setTile(
                  entranceTiles[e][0] * TILE_SIZE + TILE_SIZE / 2,
                  entranceTiles[e][1] * TILE_SIZE + TILE_SIZE / 2,
                  TileType.FLOOR
                );
              }
              break;
            }
          }
        } else {
          // Optional Challenge - mark defeated for respawn timer
          const bcx: number = Math.floor(boss.x / (CHUNK_SIZE * TILE_SIZE));
          const bcy: number = Math.floor(boss.y / (CHUNK_SIZE * TILE_SIZE));
          this.worldGen.markOptionalBossDefeated(bcx, bcy);
          if (this.activeBoss === boss) this.activeBoss = null;
        }

        // Death particles
        if (this.settings.effectsEnabled) {
          this.particleMgr.explosion(boss.x, boss.y, this.getBossColor(boss.bossType), 30);
          this.particleMgr.sparks(boss.x, boss.y, '#ffffff', 15);
          this.particleMgr.smoke(boss.x, boss.y);
        }

        // Drop materials
        this.spawnBossDrops(boss);

        // Spawn boss chest at boss position
        this.chests.push({
          x: boss.x, y: boss.y,
          chestType: ChestType.BOSS,
          opened: false, active: true,
          guardianDefeated: true, guardianCount: 0,
          openAnim: 0
        });

        this.shakeTimer = 500;
        this.audio.playEnemyDeath();
        this.autoSave();
      }

      // Hit flash decay
      if (boss.hitFlash > 0) {
        boss.hitFlash -= dt;
      }
    }
  }

  private spawnBossDrops(boss: BossState): void {
    // Drop 2-3 boss-specific ore materials
    const dropCount: number = 2 + Math.floor(Math.random() * 2);
    for (let i: number = 0; i < dropCount; i++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 20 + Math.random() * 30;
      const dropX: number = boss.x + Math.cos(angle) * dist;
      const dropY: number = boss.y + Math.sin(angle) * dist;

      let matType: MaterialType = MaterialType.CORE_NORMAL;
      if (boss.bossType === BossType.CRYSTAL_GUARDIAN) matType = MaterialType.CRYSTAL_ORE;
      else if (boss.bossType === BossType.MUSHROOM_KING) matType = MaterialType.MUSHROOM_ORE;
      else if (boss.bossType === BossType.LAVA_BEAST) matType = MaterialType.FLAME_ORE;
      else if (boss.bossType === BossType.ABYSS_SIREN) matType = MaterialType.ABYSS_ORE;
      else if (boss.bossType === BossType.VOID_RIFT) matType = MaterialType.VOID_ORE;

      this.materialDrops.push({
        x: dropX, y: dropY,
        type: matType, count: 1,
        bobPhase: Math.random() * Math.PI * 2,
        active: true
      });
    }

    // Always drop a rare core
    this.materialDrops.push({
      x: boss.x + (Math.random() - 0.5) * 40,
      y: boss.y + (Math.random() - 0.5) * 40,
      type: MaterialType.CORE_RARE, count: 1,
      bobPhase: Math.random() * Math.PI * 2,
      active: true
    });

    // Drop transform core (first defeat only — check if player already has it)
    const transformDrop: TransformForm = this.transformSystem!.getCoreForBoss(boss.bossType);
    if (transformDrop !== TransformForm.NONE) {
      const alreadyHas: boolean = this.player !== null &&
        this.player.unlockedTransforms.indexOf(transformDrop) !== -1;
      if (!alreadyHas) {
        this.materialDrops.push({
          x: boss.x + (Math.random() - 0.5) * 30,
          y: boss.y + (Math.random() - 0.5) * 30,
          type: MaterialType.FORM_CORE, count: 1,
          bobPhase: Math.random() * Math.PI * 2,
          active: true
        });
        // Mark which transform core via extraData — use a separate tracking mechanism
        // Store transform form in a parallel array indexed by drop
        this.transformCoreDrops.push({ dropIndex: this.materialDrops.length - 1, form: transformDrop } as TransformCoreDrop);
      }
    }
  }

  private collectMaterialDrops(p: PlayerState): void {
    const collectRange: number = 30;
    for (let i: number = this.materialDrops.length - 1; i >= 0; i--) {
      const drop: MaterialDrop = this.materialDrops[i];
      if (!drop.active) continue;

      const dx: number = p.x - drop.x;
      const dy: number = p.y - drop.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < collectRange) {
        drop.active = false;
        // Add to inventory
        if (drop.type === MaterialType.CRYSTAL_ORE) p.inventory.crystalOre += drop.count;
        else if (drop.type === MaterialType.MUSHROOM_ORE) p.inventory.mushroomOre += drop.count;
        else if (drop.type === MaterialType.FLAME_ORE) p.inventory.flameOre += drop.count;
        else if (drop.type === MaterialType.ABYSS_ORE) p.inventory.abyssOre += drop.count;
        else if (drop.type === MaterialType.VOID_ORE) p.inventory.voidOre += drop.count;
        else if (drop.type === MaterialType.CORE_NORMAL) p.inventory.coreNormal += drop.count;
        else if (drop.type === MaterialType.CORE_RARE) p.inventory.coreRare += drop.count;
        else if (drop.type === MaterialType.FORM_CORE) p.inventory.formCore += drop.count;

        // Check if this is a transform core drop
        for (let t: number = 0; t < this.transformCoreDrops.length; t++) {
          if (this.transformCoreDrops[t].dropIndex === i) {
            const form: TransformForm = this.transformCoreDrops[t].form;
            if (p.unlockedTransforms.indexOf(form) === -1) {
              p.unlockedTransforms.push(form);
              this.transformUnlockNotifyTimer = 3000;
              this.transformUnlockNotifyForm = form;
            }
            this.transformCoreDrops.splice(t, 1);
            break;
          }
        }

        this.audio.playXpCollect();
        if (this.settings.effectsEnabled) {
          this.particleMgr.sparks(drop.x, drop.y, '#ffd700', 6);
        }
      }
    }

    // Clean up inactive drops
    if (this.materialDrops.length > 50) {
      const active: MaterialDrop[] = [];
      for (let i: number = 0; i < this.materialDrops.length; i++) {
        if (this.materialDrops[i].active) active.push(this.materialDrops[i]);
      }
      this.materialDrops = active;
    }
  }

  private updateCamera(p: PlayerState): void {
    const targetX: number = p.x - this.screenW / 2;
    const targetY: number = p.y - this.screenH / 2;
    this.cameraX += (targetX - this.cameraX) * 0.1;
    this.cameraY += (targetY - this.cameraY) * 0.1;
  }

  private updateShake(dt: number): void {
    if (this.shakeTimer > 0) {
      this.shakeTimer -= dt;
      const intensity: number = 3 * (this.shakeTimer / 150);
      this.shakeX = (Math.random() - 0.5) * intensity * 2;
      this.shakeY = (Math.random() - 0.5) * intensity * 2;
    } else {
      this.shakeX = 0;
      this.shakeY = 0;
    }
  }

  private render(): void {
    if (this.ctx === null || this.player === null) return;
    const c: CanvasRenderingContext2D = this.ctx;
    const p: PlayerState = this.player;

    c.clearRect(0, 0, this.screenW, this.screenH);
    c.fillStyle = COLOR_BG;
    c.fillRect(0, 0, this.screenW, this.screenH);

    const offX: number = -this.cameraX + this.shakeX;
    const offY: number = -this.cameraY + this.shakeY;

    this.renderBackground(c, offX, offY);
    this.renderWorld(c, offX, offY);
    this.renderLighting(c, offX, offY, p);
    this.renderXpOrbs(c, offX, offY);
    this.renderTraps(c, offX, offY);
    this.renderMechanisms(c, offX, offY);
    this.renderChests(c, offX, offY);
    this.renderEnemies(c, offX, offY);
    this.renderBosses(c, offX, offY);
    this.renderMaterialDrops(c, offX, offY);
    this.renderPlayer(c, offX, offY, p);
    this.renderParticles(c, offX, offY);
    this.particleMgr.render(c, offX, offY);
    this.renderAmbientParticles(c);
    this.renderVignette(c, p);
    this.renderBossHPBar(c);

    if (this.frameCount % MINIMAP_UPDATE_INTERVAL === 0) {
      this.renderMinimap();
    }
  }

  private renderBackground(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    const w: number = this.screenW;
    const h: number = this.screenH;
    const depth: number = Math.min(1.0, Math.max(0, this.cameraY / (TILE_SIZE * 30)));

    const camWorldX: number = this.cameraX + this.screenW / 2;
    const camWorldY: number = this.cameraY + this.screenH / 2;
    const viewBiome: BiomeType = this.worldGen.getBiome(camWorldX, camWorldY);

    let topC: string;
    let midC: string;
    let botC: string;
    let farSilhouetteC: string;
    let midSilhouetteC: string;

    switch (viewBiome) {
      case BiomeType.CRYSTAL:
        topC = '#0a1025'; midC = '#060d1a'; botC = '#030812';
        farSilhouetteC = '#0c1530'; midSilhouetteC = '#081020';
        break;
      case BiomeType.MUSHROOM:
        topC = '#150a1e'; midC = '#100718'; botC = '#0a0410';
        farSilhouetteC = '#1a0e28'; midSilhouetteC = '#120a1c';
        break;
      case BiomeType.WATER:
        topC = '#061520'; midC = '#041018'; botC = '#020a10';
        farSilhouetteC = '#081a28'; midSilhouetteC = '#051220';
        break;
      case BiomeType.LAVA:
        topC = '#1a0a05'; midC = '#120703'; botC = '#0a0402';
        farSilhouetteC = '#200e08'; midSilhouetteC = '#180a05';
        break;
      case BiomeType.SHADOW:
        topC = '#0d0520'; midC = '#080315'; botC = '#04020a';
        farSilhouetteC = '#0d0520'; midSilhouetteC = '#0a0318';
        break;
      default:
        if (depth < 0.3) {
          topC = '#0c0c1e'; midC = '#080814'; botC = '#050510';
        } else if (depth < 0.7) {
          topC = '#0a0818'; midC = '#06050f'; botC = '#03030a';
        } else {
          topC = '#0d0520'; midC = '#080315'; botC = '#04020a';
        }
        farSilhouetteC = depth > 0.5 ? '#0d0520' : '#0e0e1c';
        midSilhouetteC = depth > 0.5 ? '#0a0318' : '#0a0a16';
        break;
    }

    const grad: CanvasGradient = c.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, topC);
    grad.addColorStop(0.5, midC);
    grad.addColorStop(1, botC);
    c.fillStyle = grad;
    c.fillRect(0, 0, w, h);

    // Layer 2: Far cave silhouettes (0.1x parallax)
    const farOffX: number = this.cameraX * 0.1;
    const farOffY: number = this.cameraY * 0.1;
    c.fillStyle = farSilhouetteC;
    c.globalAlpha = 0.6;
    const farStep: number = 80;
    const farStart: number = Math.floor(farOffX / farStep) * farStep;
    for (let fx: number = farStart - farStep; fx < farStart + w + farStep * 2; fx += farStep) {
      const sx: number = fx - farOffX;
      const hash: number = Math.abs(Math.floor(fx / farStep) * 2654435761) % 100;
      const stalH: number = 30 + (hash % 50);
      const stalW: number = 25 + (hash % 35);
      const ceilY: number = -(farOffY * 0.3) + (hash % 20);
      c.beginPath();
      c.moveTo(sx, ceilY);
      c.lineTo(sx + stalW / 2, ceilY + stalH);
      c.lineTo(sx + stalW, ceilY);
      c.fill();
      const floorY: number = h - (farOffY * 0.2) - (hash % 15);
      const stgH: number = 20 + (hash % 35);
      c.beginPath();
      c.moveTo(sx + 10, floorY);
      c.lineTo(sx + 10 + stalW / 2 - 5, floorY - stgH);
      c.lineTo(sx + 10 + stalW - 10, floorY);
      c.fill();
    }
    c.globalAlpha = 1.0;

    // Layer 3: Mid cave formations (0.3x parallax)
    const midOffX: number = this.cameraX * 0.3;
    const midOffY: number = this.cameraY * 0.3;
    c.fillStyle = midSilhouetteC;
    c.globalAlpha = 0.4;
    const midStep: number = 50;
    const midStart: number = Math.floor(midOffX / midStep) * midStep;
    for (let mx: number = midStart - midStep; mx < midStart + w + midStep * 2; mx += midStep) {
      const sx: number = mx - midOffX;
      const hash: number = Math.abs(Math.floor(mx / midStep) * 48271) % 100;
      if (hash < 40) {
        const mStalH: number = 15 + (hash % 25);
        const ceilY: number = -(midOffY * 0.4) + (hash % 30);
        c.beginPath();
        c.moveTo(sx, ceilY);
        c.lineTo(sx + 8, ceilY + mStalH);
        c.lineTo(sx + 16, ceilY);
        c.fill();
      }
      if (hash > 60) {
        const mStgH: number = 10 + (hash % 20);
        const floorY: number = h - (midOffY * 0.3) - (hash % 20);
        c.beginPath();
        c.moveTo(sx + 5, floorY);
        c.lineTo(sx + 12, floorY - mStgH);
        c.lineTo(sx + 19, floorY);
        c.fill();
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderWorld(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    const startTX: number = Math.floor(this.cameraX / TILE_SIZE) - 1;
    const startTY: number = Math.floor(this.cameraY / TILE_SIZE) - 1;
    const endTX: number = Math.ceil((this.cameraX + this.screenW) / TILE_SIZE) + 1;
    const endTY: number = Math.ceil((this.cameraY + this.screenH) / TILE_SIZE) + 1;

    const camWorldX: number = this.cameraX + this.screenW / 2;
    const camWorldY: number = this.cameraY + this.screenH / 2;
    const viewBiome: BiomeType = this.worldGen.getBiome(camWorldX, camWorldY);
    const isShadow: boolean = viewBiome === BiomeType.SHADOW;

    if (isShadow !== this.lastCacheIsShadow) {
      this.lastCacheIsShadow = isShadow;
      this.invalidateAllChunkCaches();
    }

    const floorColor: string = isShadow ? COLOR_SHADOW_FLOOR : COLOR_FLOOR;
    const floorVarColor: string = isShadow ? '#0a0a16' : COLOR_FLOOR_VAR;
    const wallColor: string = isShadow ? COLOR_SHADOW_WALL : COLOR_WALL;

    if (this.cacheCtxs.length > 0) {
      const startCX: number = Math.floor(startTX / CHUNK_SIZE) - 1;
      const startCY: number = Math.floor(startTY / CHUNK_SIZE) - 1;
      const endCX: number = Math.floor(endTX / CHUNK_SIZE) + 1;
      const endCY: number = Math.floor(endTY / CHUNK_SIZE) + 1;

      for (let cy: number = startCY; cy <= endCY; cy++) {
        for (let cx: number = startCX; cx <= endCX; cx++) {
          const key: string = this.chunkKey(cx, cy);
          if (!this.activeChunkCaches.has(key)) {
            if (this.freePoolIndices.length === 0) {
              let oldestKey: string = '';
              let oldestPool: number = Number.MAX_SAFE_INTEGER;
              this.activeChunkCaches.forEach((entry: ChunkCacheEntry, k: string) => {
                if (entry.poolIndex < oldestPool) {
                  oldestPool = entry.poolIndex;
                  oldestKey = k;
                }
              });
              if (oldestKey !== '') {
                this.invalidateChunkCache(oldestKey);
              }
            }
            this.buildChunkCache(cx, cy);
          }

          const entry: ChunkCacheEntry | undefined = this.activeChunkCaches.get(key);
          if (entry !== undefined) {
            const cacheCtx: CanvasRenderingContext2D = this.cacheCtxs[entry.poolIndex];
            const destX: number = cx * this.chunkPixelSize + offX - CACHE_PADDING;
            const destY: number = cy * this.chunkPixelSize + offY - CACHE_PADDING;
            c.drawImage(cacheCtx, 0, 0, CACHE_CANVAS_SIZE, CACHE_CANVAS_SIZE,
              destX, destY, CACHE_CANVAS_SIZE, CACHE_CANVAS_SIZE);
          }
        }
      }
    }

    for (let ty: number = startTY; ty <= endTY; ty++) {
      for (let tx: number = startTX; tx <= endTX; tx++) {
        const screenX: number = tx * TILE_SIZE + offX;
        const screenY: number = ty * TILE_SIZE + offY;
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);

        if (this.cacheCtxs.length === 0 && tile === TileType.WALL) {
          this.renderStaticWall(c, screenX, screenY, tx, ty, wallColor, isShadow);
        } else if (this.cacheCtxs.length === 0 && tile === TileType.FLOOR) {
          this.renderStaticFloor(c, screenX, screenY, tx, ty, floorColor, floorVarColor, isShadow);
        } else if (this.cacheCtxs.length === 0 && tile === TileType.BROKEN_WALL) {
          this.renderStaticBrokenWall(c, screenX, screenY);
        } else if (this.cacheCtxs.length === 0 && tile === TileType.PLANT) {
          this.renderStaticPlant(c, screenX, screenY, floorColor);
        } else if (tile === TileType.GLOW_STONE) {
          c.fillStyle = isShadow ? COLOR_SHADOW_FLOOR : COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const glowR: number = 20 + Math.sin(this.frameCount * 0.05 + tx) * 4;
          c.globalAlpha = 0.15;
          c.fillStyle = isShadow ? '#7c3aed' : COLOR_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, glowR, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = isShadow ? '#8b5cf6' : COLOR_GLOW_STONE;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, 5, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = isShadow ? '#c4b5fd' : '#fff8dc';
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2 - 1, screenY + TILE_SIZE / 2 - 1, 2, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.WATER) {
          const waveOff: number = Math.sin(this.frameCount * 0.03 + tx * 0.5) * 2;
          const waveOff2: number = Math.sin(this.frameCount * 0.05 + tx * 0.8) * 1.5;

          // Water base with transparency
          c.globalAlpha = 0.75;
          c.fillStyle = COLOR_WATER;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.globalAlpha = 1.0;

          // Deeper water gradient overlay
          c.fillStyle = '#0a1a3a';
          c.globalAlpha = 0.25;
          c.fillRect(screenX, screenY + TILE_SIZE - 8, TILE_SIZE, 8);
          c.globalAlpha = 1.0;

          // Surface tension line (top edge highlight)
          const aboveWater: number = this.getTile(tx * TILE_SIZE, (ty - 1) * TILE_SIZE);
          if (aboveWater !== TileType.WATER) {
            c.fillStyle = COLOR_WATER_LIGHT;
            c.globalAlpha = 0.6;
            c.fillRect(screenX, screenY, TILE_SIZE, 2);
            c.globalAlpha = 0.3;
            c.fillRect(screenX, screenY + 2, TILE_SIZE, 1);
            c.globalAlpha = 1.0;
          }

          // Caustic light patterns
          c.fillStyle = COLOR_WATER_LIGHT;
          c.globalAlpha = 0.3;
          c.fillRect(screenX + 4, screenY + 8 + waveOff, 24, 3);
          c.fillRect(screenX + 8, screenY + 20 - waveOff, 16, 2);
          // Secondary caustics
          c.globalAlpha = 0.15;
          c.fillRect(screenX + 2 + waveOff2, screenY + 14, 10, 2);
          c.fillRect(screenX + 18 - waveOff2, screenY + 26, 8, 2);
          c.globalAlpha = 1.0;

          // Bubble particles (deterministic, animated)
          const bubbleHash: number = ((tx * 61 + ty * 113) % 23);
          if (bubbleHash < 3) {
            const bubbleY: number = (this.frameCount * 0.3 + bubbleHash * 11) % TILE_SIZE;
            const bubbleX: number = 6 + bubbleHash * 9;
            c.fillStyle = '#ffffff';
            c.globalAlpha = 0.25;
            c.fillRect(screenX + bubbleX, screenY + TILE_SIZE - bubbleY, 2, 2);
            c.globalAlpha = 0.12;
            c.fillRect(screenX + bubbleX + 5, screenY + TILE_SIZE - bubbleY + 4, 1, 1);
            c.globalAlpha = 1.0;
          }
        } else if (tile === TileType.CRYSTAL) {
          c.fillStyle = COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const glow: number = 12 + Math.sin(this.frameCount * 0.04 + tx + ty) * 4;
          c.globalAlpha = 0.2;
          c.fillStyle = COLOR_CRYSTAL_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, glow, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = COLOR_CRYSTAL;
          c.beginPath();
          c.moveTo(screenX + TILE_SIZE / 2, screenY + 6);
          c.lineTo(screenX + TILE_SIZE / 2 + 6, screenY + TILE_SIZE / 2);
          c.lineTo(screenX + TILE_SIZE / 2, screenY + TILE_SIZE - 6);
          c.lineTo(screenX + TILE_SIZE / 2 - 6, screenY + TILE_SIZE / 2);
          c.closePath();
          c.fill();
          c.fillStyle = '#e0ffff';
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2 - 1, screenY + TILE_SIZE / 2 - 2, 2, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.MUSHROOM) {
          c.fillStyle = COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.globalAlpha = 0.15;
          c.fillStyle = COLOR_MUSHROOM_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, 14, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = COLOR_MUSHROOM_STEM;
          c.fillRect(screenX + 13, screenY + 16, 6, 12);
          c.fillStyle = COLOR_MUSHROOM_CAP;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + 14, 9, Math.PI, 0);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(screenX + 13, screenY + 11, 2, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(screenX + 19, screenY + 9, 1.5, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.LAVA) {
          const lavaOff: number = Math.sin(this.frameCount * 0.05 + tx * 0.7) * 3;
          const lavaOff2: number = Math.sin(this.frameCount * 0.08 + tx * 1.2) * 2;

          // Lava base
          c.fillStyle = COLOR_LAVA;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);

          // Bright molten core
          c.fillStyle = '#cd4a00';
          c.globalAlpha = 0.4;
          c.fillRect(screenX + 6, screenY + 10 + lavaOff2, 18, 6);
          c.globalAlpha = 1.0;

          // Surface bright glow
          c.fillStyle = COLOR_LAVA_LIGHT;
          c.globalAlpha = 0.6;
          c.fillRect(screenX + 4, screenY + 6 + lavaOff, 20, 4);
          c.fillRect(screenX + 10, screenY + 18 - lavaOff, 14, 3);
          c.globalAlpha = 1.0;

          // Dark crust patches (cooling lava)
          const crustHash: number = ((tx * 43 + ty * 89) % 11);
          if (crustHash < 3) {
            c.fillStyle = '#3a0a00';
            c.globalAlpha = 0.5;
            c.fillRect(screenX + 2 + crustHash * 8, screenY + 4 + crustHash * 3, 6, 3);
            c.fillRect(screenX + 14 - crustHash * 2, screenY + 22 - crustHash * 4, 5, 2);
            c.globalAlpha = 1.0;
          }

          // Lava surface glow (top edge if open above)
          const aboveLava: number = this.getTile(tx * TILE_SIZE, (ty - 1) * TILE_SIZE);
          if (aboveLava !== TileType.LAVA) {
            c.fillStyle = '#ff6600';
            c.globalAlpha = 0.5 + Math.sin(this.frameCount * 0.06 + tx) * 0.15;
            c.fillRect(screenX, screenY, TILE_SIZE, 2);
            c.fillStyle = '#ffaa00';
            c.globalAlpha = 0.25;
            c.fillRect(screenX, screenY + 2, TILE_SIZE, 1);
            c.globalAlpha = 1.0;
          }

          // Ember sparks
          const emberHash: number = ((tx * 71 + ty * 127) % 19);
          if (emberHash < 2) {
            const emberY: number = (this.frameCount * 0.5 + emberHash * 7) % TILE_SIZE;
            c.fillStyle = '#ffcc00';
            c.globalAlpha = 0.4;
            c.fillRect(screenX + 8 + emberHash * 10, screenY + TILE_SIZE - emberY, 1, 1);
            c.globalAlpha = 1.0;
          }
        }
      }
    }
  }

  private renderPlayer(c: CanvasRenderingContext2D, offX: number, offY: number, p: PlayerState): void {
    const screenX: number = p.x + offX;
    const screenY: number = p.y + offY - p.jumpHeight;
    const half: number = PLAYER_SIZE / 2;

    if (p.isEngulfed) {
      c.globalAlpha = 0.5 + Math.sin(this.frameCount * 0.2) * 0.3;
      const engulfBodyColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY : COLOR_PLAYER_BODY;
      c.fillStyle = engulfBodyColor;
      c.beginPath();
      c.arc(screenX, screenY, half * 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      return;
    }

    if (p.invincibleTimer > 0 && Math.floor(this.frameCount / 3) % 2 === 0) {
      return;
    }

    // Transform rendering override
    if (p.isTransformed) {
      const bobY: number = p.isJumping ? -p.jumpHeight : Math.sin(this.frameCount * 0.08) * 1.5;
      if (p.transformForm === TransformForm.SLIME) {
        this.renderSlimeForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.GHOST) {
        this.renderGhostForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.ARMOR) {
        this.renderArmorForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.IRON_MAN) {
        this.renderIronManForm(c, screenX, screenY, p, bobY);
      }
      // Transform animation overlay
      if (p.transformAnimTimer > 0) {
        this.renderTransformAnim(c, screenX, screenY, p);
      }
      return;
    }

    if (p.isJumping) {
      c.globalAlpha = 0.3;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, p.y + offY + half, half * 0.8, half * 0.3, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    const bobY: number = Math.sin(p.animFrame) * 1.5;
    const walkPhase: number = Math.sin(p.animFrame * 2);
    const isMoving: boolean = Math.abs(p.vx) > 0.1 || Math.abs(p.vy) > 0.1;
    const facingRight: boolean = Math.cos(p.facing) >= 0;

    const bodyColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY : COLOR_PLAYER_BODY;
    const bodyDarkColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY_DARK : COLOR_PLAYER_BODY_DARK;
    const hairColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_HAIR : COLOR_PLAYER_HAIR;

    // === Terraria-style character rendering with detailed textures ===
    // Shadow under feet
    if (!p.isJumping) {
      c.globalAlpha = 0.25;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, screenY + 13 + bobY, 7, 2.5, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Legs with walking animation and detail
    const legSwing: number = isMoving ? walkPhase * 3 : 0;
    // Left leg
    c.fillStyle = '#4a3728';
    c.fillRect(screenX - 4, screenY + 5 + bobY, 3, 7);
    // Leg seam detail
    c.fillStyle = '#3d2b1a';
    c.fillRect(screenX - 3, screenY + 6 + bobY, 1, 5);
    // Right leg
    c.fillStyle = '#4a3728';
    c.fillRect(screenX + 1, screenY + 5 + bobY, 3, 7);
    c.fillStyle = '#3d2b1a';
    c.fillRect(screenX + 2, screenY + 6 + bobY, 1, 5);
    // Boots with leather texture
    c.fillStyle = '#3d2b1a';
    c.fillRect(screenX - 5, screenY + 10 + bobY + (isMoving ? legSwing : 0), 4, 3);
    c.fillRect(screenX + 1, screenY + 10 + bobY + (isMoving ? -legSwing : 0), 4, 3);
    // Boot highlights
    c.fillStyle = '#5a4530';
    c.fillRect(screenX - 5, screenY + 10 + bobY + (isMoving ? legSwing : 0), 4, 1);
    c.fillRect(screenX + 1, screenY + 10 + bobY + (isMoving ? -legSwing : 0), 4, 1);
    // Boot soles
    c.fillStyle = '#2a1a0a';
    c.fillRect(screenX - 5, screenY + 12 + bobY + (isMoving ? legSwing : 0), 4, 1);
    c.fillRect(screenX + 1, screenY + 12 + bobY + (isMoving ? -legSwing : 0), 4, 1);

    // Body / torso with fabric texture
    c.fillStyle = bodyColor;
    c.fillRect(screenX - 5, screenY - 3 + bobY, 10, 9);
    // Body shading (bottom gradient)
    c.fillStyle = bodyDarkColor;
    c.fillRect(screenX - 5, screenY + 3 + bobY, 10, 3);
    // Fabric fold lines
    c.fillStyle = bodyDarkColor;
    c.globalAlpha = 0.4;
    c.fillRect(screenX - 3, screenY - 1 + bobY, 1, 5);
    c.fillRect(screenX + 2, screenY + 0 + bobY, 1, 4);
    c.globalAlpha = 1.0;
    // Chest highlight
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.1;
    c.fillRect(screenX - 2, screenY - 2 + bobY, 4, 2);
    c.globalAlpha = 1.0;
    // Belt with metal texture
    c.fillStyle = '#8b6914';
    c.fillRect(screenX - 5, screenY + 4 + bobY, 10, 2);
    // Belt stitching
    c.fillStyle = '#6b4f0e';
    c.fillRect(screenX - 5, screenY + 4 + bobY, 10, 1);
    // Belt buckle with shine
    c.fillStyle = '#ffd700';
    c.fillRect(screenX - 1, screenY + 4 + bobY, 2, 2);
    c.fillStyle = '#fff8dc';
    c.fillRect(screenX - 1, screenY + 4 + bobY, 1, 1);

    // Arms with sleeve detail
    const armSwing: number = isMoving ? walkPhase * 2 : 0;
    // Left arm
    c.fillStyle = bodyColor;
    c.fillRect(screenX - 7, screenY - 2 + bobY + (isMoving ? -armSwing : 0), 3, 7);
    // Sleeve cuff
    c.fillStyle = bodyDarkColor;
    c.fillRect(screenX - 7, screenY - 2 + bobY + (isMoving ? -armSwing : 0), 3, 1);
    // Right arm
    c.fillStyle = bodyColor;
    c.fillRect(screenX + 4, screenY - 2 + bobY + (isMoving ? armSwing : 0), 3, 7);
    c.fillStyle = bodyDarkColor;
    c.fillRect(screenX + 4, screenY - 2 + bobY + (isMoving ? armSwing : 0), 3, 1);
    // Hands (skin with detail)
    c.fillStyle = COLOR_PLAYER_SKIN;
    c.fillRect(screenX - 7, screenY + 4 + bobY + (isMoving ? -armSwing : 0), 3, 2);
    c.fillRect(screenX + 4, screenY + 4 + bobY + (isMoving ? armSwing : 0), 3, 2);
    // Hand shading
    c.fillStyle = '#e0b090';
    c.fillRect(screenX - 7, screenY + 5 + bobY + (isMoving ? -armSwing : 0), 3, 1);
    c.fillRect(screenX + 4, screenY + 5 + bobY + (isMoving ? armSwing : 0), 3, 1);

    // Head with facial detail
    c.fillStyle = COLOR_PLAYER_SKIN;
    c.fillRect(screenX - 4, screenY - 10 + bobY, 8, 7);
    // Cheek shading
    c.fillStyle = '#e8c0a0';
    c.globalAlpha = 0.5;
    c.fillRect(screenX - 3, screenY - 5 + bobY, 2, 1);
    c.fillRect(screenX + 1, screenY - 5 + bobY, 2, 1);
    c.globalAlpha = 1.0;
    // Chin/jaw shading
    c.fillStyle = '#e0b090';
    c.fillRect(screenX - 3, screenY - 4 + bobY, 6, 1);
    // Nose
    c.fillStyle = '#d4a882';
    c.fillRect(screenX, screenY - 6 + bobY, 1, 2);

    // Hair with detailed strands and highlights
    c.fillStyle = hairColor;
    // Top of hair (main mass)
    c.fillRect(screenX - 5, screenY - 12 + bobY, 10, 4);
    // Hair volume on sides
    c.fillRect(screenX - 6, screenY - 10 + bobY, 2, 5);
    c.fillRect(screenX + 4, screenY - 10 + bobY, 2, 5);
    // Hair highlight strands
    const hairHighlight: string = p.gender === GenderType.FEMALE ? '#7a3a9a' : '#9a5a3a';
    c.fillStyle = hairHighlight;
    c.fillRect(screenX - 4, screenY - 11 + bobY, 2, 1);
    c.fillRect(screenX + 1, screenY - 12 + bobY, 3, 1);
    c.fillRect(screenX - 2, screenY - 10 + bobY, 1, 2);
    // Hair shadow strands
    c.fillStyle = p.gender === GenderType.FEMALE ? '#3a1050' : '#4a2a10';
    c.fillRect(screenX - 3, screenY - 9 + bobY, 1, 3);
    c.fillRect(screenX + 3, screenY - 10 + bobY, 1, 2);
    c.fillRect(screenX, screenY - 11 + bobY, 1, 1);
    // Female long hair with flow detail
    if (p.gender === GenderType.FEMALE) {
      c.fillStyle = hairColor;
      c.fillRect(screenX - 7, screenY - 8 + bobY, 2, 10);
      c.fillRect(screenX + 5, screenY - 8 + bobY, 2, 10);
      // Hair flow highlights
      c.fillStyle = '#7a3a9a';
      c.fillRect(screenX - 7, screenY - 6 + bobY, 1, 3);
      c.fillRect(screenX + 6, screenY - 7 + bobY, 1, 4);
      // Hair flow shadows
      c.fillStyle = '#3a1050';
      c.fillRect(screenX - 6, screenY - 4 + bobY, 1, 5);
      c.fillRect(screenX + 5, screenY - 3 + bobY, 1, 4);
      // Hair tips
      c.fillStyle = hairColor;
      c.fillRect(screenX - 7, screenY + 1 + bobY, 1, 2);
      c.fillRect(screenX + 6, screenY + 1 + bobY, 1, 2);
    }

    // Eyes with more detail
    const eyeOffX: number = facingRight ? 0 : -1;
    // Eye whites
    c.fillStyle = '#ffffff';
    c.fillRect(screenX - 2 + eyeOffX, screenY - 8 + bobY, 3, 3);
    c.fillRect(screenX + 1 + eyeOffX, screenY - 8 + bobY, 3, 3);
    // Iris color
    c.fillStyle = '#4a90d9';
    c.fillRect(screenX - 1 + eyeOffX, screenY - 7 + bobY, 2, 2);
    c.fillRect(screenX + 2 + eyeOffX, screenY - 7 + bobY, 2, 2);
    // Pupils
    c.fillStyle = '#1a1a2e';
    c.fillRect(screenX - 1 + eyeOffX, screenY - 7 + bobY, 1, 1);
    c.fillRect(screenX + 2 + eyeOffX, screenY - 7 + bobY, 1, 1);
    // Eye shine (double highlight)
    c.fillStyle = '#ffffff';
    c.fillRect(screenX - 1 + eyeOffX, screenY - 8 + bobY, 1, 1);
    c.fillRect(screenX + 2 + eyeOffX, screenY - 8 + bobY, 1, 1);
    c.globalAlpha = 0.6;
    c.fillRect(screenX + eyeOffX, screenY - 6 + bobY, 1, 1);
    c.fillRect(screenX + 3 + eyeOffX, screenY - 6 + bobY, 1, 1);
    c.globalAlpha = 1.0;
    // Eyebrows
    c.fillStyle = hairColor;
    c.fillRect(screenX - 2 + eyeOffX, screenY - 9 + bobY, 3, 1);
    c.fillRect(screenX + 1 + eyeOffX, screenY - 9 + bobY, 3, 1);

    // Mouth with detail
    c.fillStyle = '#c0846a';
    c.fillRect(screenX, screenY - 4 + bobY, 2, 1);
    c.fillStyle = '#a06850';
    c.fillRect(screenX, screenY - 4 + bobY, 2, 1);

    this.renderDrill(c, screenX, screenY, p, bobY);
    this.renderWeaponOnPlayer(c, screenX, screenY, p, bobY);
    this.renderEvolutionEffects(c, screenX, screenY, p, bobY);
  }

  private renderDrill(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const drillLen: number = p.isDrilling ? 14 : 8;
    const drillOffX: number = Math.cos(p.facing) * (8 + (p.isDrilling ? 6 : 0));
    const drillOffY: number = Math.sin(p.facing) * (8 + (p.isDrilling ? 6 : 0));
    const baseX: number = sx + drillOffX;
    const baseY: number = sy + drillOffY + bobY;
    const fAng: number = p.facing;
    const perpX: number = -Math.sin(fAng);
    const perpY: number = Math.cos(fAng);

    // Drill body (cylindrical housing)
    c.fillStyle = '#6b7280';
    c.fillRect(baseX - 3, baseY - 3, 6, 6);
    // Housing highlight
    c.fillStyle = '#9ca3af';
    c.fillRect(baseX - 3, baseY - 3, 6, 2);
    // Housing shadow
    c.fillStyle = '#4b5563';
    c.fillRect(baseX - 3, baseY + 1, 6, 2);
    // Rivets on housing
    c.fillStyle = '#374151';
    c.fillRect(baseX - 2, baseY - 2, 1, 1);
    c.fillRect(baseX + 1, baseY - 2, 1, 1);
    c.fillRect(baseX - 2, baseY + 1, 1, 1);
    c.fillRect(baseX + 1, baseY + 1, 1, 1);

    // Drill bit with spiral grooves
    const tipX: number = baseX + Math.cos(fAng) * drillLen;
    const tipY: number = baseY + Math.sin(fAng) * drillLen;
    // Main drill shaft
    c.strokeStyle = COLOR_DRILL_TIP;
    c.lineWidth = 3;
    c.beginPath();
    c.moveTo(baseX, baseY);
    c.lineTo(tipX, tipY);
    c.stroke();
    // Drill bit highlight edge
    c.strokeStyle = '#fde68a';
    c.lineWidth = 1;
    c.beginPath();
    c.moveTo(baseX + perpX, baseY + perpY);
    c.lineTo(tipX + perpX, tipY + perpY);
    c.stroke();
    // Spiral groove lines
    c.strokeStyle = '#b45309';
    c.lineWidth = 1;
    const spiralSegs: number = p.isDrilling ? 5 : 3;
    for (let i: number = 1; i <= spiralSegs; i++) {
      const t: number = i / (spiralSegs + 1);
      const gx: number = baseX + Math.cos(fAng) * drillLen * t;
      const gy: number = baseY + Math.sin(fAng) * drillLen * t;
      const groovePhase: number = t * Math.PI * 2 + (p.isDrilling ? this.frameCount * 0.3 : 0);
      const grooveOff: number = Math.sin(groovePhase) * 1.5;
      c.beginPath();
      c.moveTo(gx + perpX * grooveOff, gy + perpY * grooveOff);
      c.lineTo(gx - perpX * grooveOff, gy - perpY * grooveOff);
      c.stroke();
    }

    // Drilling effect — sparks and heat glow
    if (p.isDrilling) {
      // Heat glow at tip
      c.fillStyle = '#ff6b00';
      c.globalAlpha = 0.5 + Math.random() * 0.3;
      c.beginPath();
      c.arc(tipX, tipY, 4 + Math.random() * 2, 0, Math.PI * 2);
      c.fill();
      // Bright core
      c.fillStyle = '#ffaa00';
      c.globalAlpha = 0.8;
      c.beginPath();
      c.arc(tipX, tipY, 2, 0, Math.PI * 2);
      c.fill();
      // Spark particles
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.9;
      for (let i: number = 0; i < 3; i++) {
        const sparkAng: number = fAng + (Math.random() - 0.5) * 1.5;
        const sparkDist: number = 3 + Math.random() * 5;
        const sparkX: number = tipX + Math.cos(sparkAng) * sparkDist;
        const sparkY: number = tipY + Math.sin(sparkAng) * sparkDist;
        c.fillRect(sparkX, sparkY, 1, 1);
      }
      c.globalAlpha = 1.0;
    }

    if (p.isAttacking) {
      this.renderWeaponAttackEffect(c, sx, sy, p, bobY);
    }
  }

  private renderWeaponAttackEffect(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const form: WeaponForm = p.currentWeaponForm;
    const formStats: number[] = WEAPON_FORM_STATS[form];
    const range: number = formStats[0];
    const width: number = formStats[1];
    const offX: number = Math.cos(p.facing) * range * 0.7;
    const offY: number = Math.sin(p.facing) * range * 0.7;
    const cx: number = sx + offX;
    const cy: number = sy + offY + bobY;
    const perpX: number = -Math.sin(p.facing);
    const perpY: number = Math.cos(p.facing);

    if (form === WeaponForm.BLADE) {
      // Wide sweeping slash arc with trail
      const arcStart: number = p.facing - 1.0;
      const arcEnd: number = p.facing + 1.0;
      // Outer glow
      c.globalAlpha = 0.25;
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 8;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.85, arcStart, arcEnd);
      c.stroke();
      // Main slash
      c.globalAlpha = 0.7;
      c.strokeStyle = '#93c5fd';
      c.lineWidth = 4;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.85, arcStart, arcEnd);
      c.stroke();
      // Inner bright edge
      c.globalAlpha = 0.9;
      c.strokeStyle = '#dbeafe';
      c.lineWidth = 1.5;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.7, arcStart, arcEnd);
      c.stroke();
      // Slash tip sparks
      const sparkAng: number = p.facing + 0.8;
      const sparkX: number = sx + Math.cos(sparkAng) * range * 0.85;
      const sparkY: number = sy + bobY + Math.sin(sparkAng) * range * 0.85;
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.8;
      c.beginPath();
      c.arc(sparkX, sparkY, 2, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.WHIP) {
      // Long cracking whip with shockwave at tip
      const whipLen: number = range * 1.1;
      c.globalAlpha = 0.8;
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(sx + Math.cos(p.facing) * 8, sy + bobY + Math.sin(p.facing) * 8);
      const cp1x: number = sx + Math.cos(p.facing) * whipLen * 0.5 + perpX * 15;
      const cp1y: number = sy + bobY + Math.sin(p.facing) * whipLen * 0.5 + perpY * 15;
      const endX: number = sx + Math.cos(p.facing) * whipLen;
      const endY: number = sy + bobY + Math.sin(p.facing) * whipLen;
      c.quadraticCurveTo(cp1x, cp1y, endX, endY);
      c.stroke();
      // Crack effect at tip — starburst
      c.globalAlpha = 0.6;
      c.fillStyle = '#e879f9';
      c.beginPath();
      c.arc(endX, endY, 5, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.3;
      c.fillStyle = '#f0abfc';
      c.beginPath();
      c.arc(endX, endY, 9, 0, Math.PI * 2);
      c.fill();
      // Shockwave lines
      c.globalAlpha = 0.5;
      c.strokeStyle = '#d8b4fe';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const a: number = p.facing + (i - 1.5) * 0.5;
        c.beginPath();
        c.moveTo(endX, endY);
        c.lineTo(endX + Math.cos(a) * 8, endY + Math.sin(a) * 8);
        c.stroke();
      }
    } else if (form === WeaponForm.HAMMER) {
      // Ground pound shockwave — expanding rings
      c.globalAlpha = 0.5;
      c.fillStyle = '#f97316';
      c.beginPath();
      c.arc(cx, cy, width * 0.6, 0, Math.PI * 2);
      c.fill();
      // Outer ring
      c.globalAlpha = 0.7;
      c.strokeStyle = '#fdba74';
      c.lineWidth = 3;
      c.beginPath();
      c.arc(cx, cy, width * 0.8, 0, Math.PI * 2);
      c.stroke();
      // Shockwave ring
      c.globalAlpha = 0.3;
      c.strokeStyle = '#fed7aa';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(cx, cy, width * 1.2, 0, Math.PI * 2);
      c.stroke();
      // Impact lines
      c.globalAlpha = 0.6;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      for (let i: number = 0; i < 6; i++) {
        const a: number = (Math.PI * 2 / 6) * i;
        c.beginPath();
        c.moveTo(cx + Math.cos(a) * width * 0.3, cy + Math.sin(a) * width * 0.3);
        c.lineTo(cx + Math.cos(a) * width * 1.0, cy + Math.sin(a) * width * 1.0);
        c.stroke();
      }
    } else if (form === WeaponForm.STAFF) {
      // Magic bolt projectile with trailing glow
      const boltX: number = sx + Math.cos(p.facing) * range;
      const boltY: number = sy + bobY + Math.sin(p.facing) * range;
      // Trail
      c.globalAlpha = 0.3;
      c.strokeStyle = '#38bdf8';
      c.lineWidth = 4;
      c.beginPath();
      c.moveTo(sx + Math.cos(p.facing) * 10, sy + bobY + Math.sin(p.facing) * 10);
      c.lineTo(boltX, boltY);
      c.stroke();
      // Outer glow
      c.globalAlpha = 0.35;
      c.fillStyle = '#0ea5e9';
      c.beginPath();
      c.arc(boltX, boltY, 12, 0, Math.PI * 2);
      c.fill();
      // Core bolt
      c.globalAlpha = 0.85;
      c.fillStyle = '#7dd3fc';
      c.beginPath();
      c.arc(boltX, boltY, 6, 0, Math.PI * 2);
      c.fill();
      // Bright center
      c.globalAlpha = 0.9;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(boltX, boltY, 2.5, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.DUAL_BLADES) {
      // Rapid cross-slashing arcs
      for (let side: number = -1; side <= 1; side += 2) {
        const arcCx: number = sx + perpX * 8 * side;
        const arcCy: number = sy + bobY + perpY * 8 * side;
        // Outer glow
        c.globalAlpha = 0.25;
        c.strokeStyle = '#fb923c';
        c.lineWidth = 6;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.7, p.facing - 0.8, p.facing + 0.8);
        c.stroke();
        // Main arc
        c.globalAlpha = 0.75;
        c.strokeStyle = '#fdba74';
        c.lineWidth = 3;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.7, p.facing - 0.8, p.facing + 0.8);
        c.stroke();
        // Inner bright
        c.globalAlpha = 0.9;
        c.strokeStyle = '#fff7ed';
        c.lineWidth = 1;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.55, p.facing - 0.6, p.facing + 0.6);
        c.stroke();
      }
    } else if (form === WeaponForm.GREAT_AXE) {
      // Devastating 360 shockwave
      // Inner fill
      c.globalAlpha = 0.35;
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.7, 0, Math.PI * 2);
      c.fill();
      // Main ring
      c.globalAlpha = 0.7;
      c.strokeStyle = '#fca5a5';
      c.lineWidth = 4;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.9, 0, Math.PI * 2);
      c.stroke();
      // Outer shockwave
      c.globalAlpha = 0.3;
      c.strokeStyle = '#fecaca';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 1.2, 0, Math.PI * 2);
      c.stroke();
      // Radial impact lines
      c.globalAlpha = 0.5;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 2;
      for (let i: number = 0; i < 8; i++) {
        const a: number = (Math.PI * 2 / 8) * i;
        c.beginPath();
        c.moveTo(sx + Math.cos(a) * range * 0.4, sy + bobY + Math.sin(a) * range * 0.4);
        c.lineTo(sx + Math.cos(a) * range * 1.1, sy + bobY + Math.sin(a) * range * 1.1);
        c.stroke();
      }
    }

    c.globalAlpha = 1.0;
  }

  private renderWeaponOnPlayer(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const form: WeaponForm = p.currentWeaponForm;
    const handX: number = sx + 5;
    const handY: number = sy + 2 + bobY;
    const fAng: number = p.facing;
    const cosF: number = Math.cos(fAng);
    const sinF: number = Math.sin(fAng);
    const perpX: number = -sinF;
    const perpY: number = cosF;

    if (!p.isAttacking) {
      // Liquid metal ball — idle weapon state
      const formColors: string[][] = [
        ['#60a5fa', '#2563eb'], // BLADE
        ['#a78bfa', '#7c3aed'], // WHIP
        ['#9ca3af', '#4b5563'], // HAMMER
        ['#7dd3fc', '#0284c7'], // STAFF
        ['#fb923c', '#c2410c'], // DUAL_BLADES
        ['#ef4444', '#991b1b'], // GREAT_AXE
      ];
      const colors: string[] = formColors[form];
      const ballX: number = handX + cosF * 3;
      const ballY: number = handY + sinF * 3;
      const t: number = this.frameCount * 0.06;
      const pulse: number = Math.sin(t) * 0.8;
      const baseR: number = 3.5;
      // Outer glow (form color tint)
      c.globalAlpha = 0.15 + Math.sin(t * 0.7) * 0.05;
      c.fillStyle = colors[0];
      c.beginPath();
      c.arc(ballX, ballY, baseR + 2 + pulse, 0, Math.PI * 2);
      c.fill();
      // Chrome sphere body
      c.globalAlpha = 0.85;
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(ballX, ballY, baseR + pulse * 0.3, 0, Math.PI * 2);
      c.fill();
      // Dark underside (depth)
      c.fillStyle = '#6b7280';
      c.globalAlpha = 0.5;
      c.beginPath();
      c.arc(ballX + cosF * 0.8, ballY + sinF * 0.8 + 1, baseR * 0.7, 0, Math.PI * 2);
      c.fill();
      // Form color swirl on surface
      c.globalAlpha = 0.35;
      c.fillStyle = colors[0];
      const swirlX: number = ballX + Math.cos(t * 1.3) * 1.2;
      const swirlY: number = ballY + Math.sin(t * 1.3) * 1.2;
      c.beginPath();
      c.arc(swirlX, swirlY, 1.8, 0, Math.PI * 2);
      c.fill();
      // Secondary swirl
      c.globalAlpha = 0.2;
      c.fillStyle = colors[1];
      const swirl2X: number = ballX + Math.cos(t * 0.9 + 2.5) * 1.5;
      const swirl2Y: number = ballY + Math.sin(t * 0.9 + 2.5) * 1.5;
      c.beginPath();
      c.arc(swirl2X, swirl2Y, 1.2, 0, Math.PI * 2);
      c.fill();
      // Chrome highlight (specular)
      c.globalAlpha = 0.9;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(ballX - 1.2, ballY - 1.2, 1.2, 0, Math.PI * 2);
      c.fill();
      // Secondary highlight
      c.globalAlpha = 0.4;
      c.fillStyle = '#f9fafb';
      c.beginPath();
      c.arc(ballX + 0.8, ballY + 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      // Surface ripple (liquid metal effect)
      c.globalAlpha = 0.25;
      c.strokeStyle = '#e5e7eb';
      c.lineWidth = 0.5;
      const rippleR: number = baseR * 0.6 + Math.sin(t * 2) * 0.5;
      c.beginPath();
      c.arc(ballX + Math.cos(t) * 0.5, ballY + Math.sin(t) * 0.5, rippleR, 0, Math.PI * 1.5);
      c.stroke();
      c.globalAlpha = 1.0;
      return;
    }

    if (form === WeaponForm.BLADE) {
      // Longsword — detailed blue steel blade with ornate crossguard
      const len: number = 16;
      const tipX: number = handX + cosF * len;
      const tipY: number = handY + sinF * len;
      const baseX: number = handX + cosF * 3;
      const baseY: number = handY + sinF * 3;
      // Blade shadow (darker underside)
      c.strokeStyle = '#3b82f6';
      c.lineWidth = 3.5;
      c.beginPath();
      c.moveTo(baseX - perpX * 0.5, baseY - perpY * 0.5);
      c.lineTo(tipX, tipY);
      c.stroke();
      // Blade body (main steel)
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(baseX, baseY);
      c.lineTo(tipX, tipY);
      c.stroke();
      // Blade highlight (edge catch light)
      c.strokeStyle = '#bfdbfe';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(baseX + perpX * 1, baseY + perpY * 1);
      c.lineTo(tipX, tipY);
      c.stroke();
      // Fuller (central groove)
      c.strokeStyle = '#2563eb';
      c.lineWidth = 0.8;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(baseX + cosF * 2, baseY + sinF * 2);
      c.lineTo(handX + cosF * (len - 3), handY + sinF * (len - 3));
      c.stroke();
      c.globalAlpha = 1.0;
      // Crossguard — ornate gold with curved ends
      const guardCx: number = handX + cosF * 3;
      const guardCy: number = handY + sinF * 3;
      c.strokeStyle = '#b45309';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(guardCx + perpX * 3.5, guardCy + perpY * 3.5);
      c.lineTo(guardCx - perpX * 3.5, guardCy - perpY * 3.5);
      c.stroke();
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(guardCx + perpX * 3, guardCy + perpY * 3);
      c.lineTo(guardCx - perpX * 3, guardCy - perpY * 3);
      c.stroke();
      // Guard end caps (small dots)
      c.fillStyle = '#fcd34d';
      c.beginPath();
      c.arc(guardCx + perpX * 3.5, guardCy + perpY * 3.5, 1, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(guardCx - perpX * 3.5, guardCy - perpY * 3.5, 1, 0, Math.PI * 2);
      c.fill();
      // Grip wrap detail
      c.strokeStyle = '#78350f';
      c.lineWidth = 0.8;
      for (let i: number = 0; i < 3; i++) {
        const t: number = 0.3 + i * 0.25;
        const gx: number = handX + cosF * 3 * t;
        const gy: number = handY + sinF * 3 * t;
        c.beginPath();
        c.moveTo(gx + perpX * 1.2, gy + perpY * 1.2);
        c.lineTo(gx - perpX * 1.2, gy - perpY * 1.2);
        c.stroke();
      }
      // Pommel
      const pomX: number = handX - cosF * 1;
      const pomY: number = handY - sinF * 1;
      c.fillStyle = '#fbbf24';
      c.beginPath();
      c.arc(pomX, pomY, 1.5, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#fcd34d';
      c.beginPath();
      c.arc(pomX - 0.5, pomY - 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      // Tip glint
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.8;
      c.beginPath();
      c.arc(tipX, tipY, 1.5, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.WHIP) {
      // Chain whip — detailed purple segmented curve with barbed tip
      const len: number = 18;
      const segs: number = 6;
      // Chain shadow
      c.strokeStyle = '#6d28d9';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      let prevX: number = handX;
      let prevY: number = handY;
      for (let i: number = 1; i <= segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + this.frameCount * 0.15) * 3 * t;
        const segX: number = handX + cosF * len * t + perpX * wave;
        const segY: number = handY + sinF * len * t + perpY * wave;
        c.lineTo(segX, segY);
        prevX = segX;
        prevY = segY;
      }
      c.stroke();
      // Chain body
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 1.8;
      c.beginPath();
      c.moveTo(handX, handY);
      for (let i: number = 1; i <= segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + this.frameCount * 0.15) * 3 * t;
        const segX: number = handX + cosF * len * t + perpX * wave;
        const segY: number = handY + sinF * len * t + perpY * wave;
        c.lineTo(segX, segY);
      }
      c.stroke();
      // Chain link highlights (small dots at each segment joint)
      c.fillStyle = '#c4b5fd';
      for (let i: number = 1; i < segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + this.frameCount * 0.15) * 3 * t;
        const jx: number = handX + cosF * len * t + perpX * wave;
        const jy: number = handY + sinF * len * t + perpY * wave;
        c.beginPath();
        c.arc(jx, jy, 0.8, 0, Math.PI * 2);
        c.fill();
      }
      // Handle wrap
      c.strokeStyle = '#581c87';
      c.lineWidth = 1;
      for (let i: number = 0; i < 2; i++) {
        const t: number = 0.05 + i * 0.08;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.5, wy + perpY * 1.5);
        c.lineTo(wx - perpX * 1.5, wy - perpY * 1.5);
        c.stroke();
      }
      // Barbed tip — detailed arrowhead
      c.fillStyle = '#c026d3';
      c.beginPath();
      c.moveTo(prevX + cosF * 4, prevY + sinF * 4);
      c.lineTo(prevX + perpX * 2.5, prevY + perpY * 2.5);
      c.lineTo(prevX - perpX * 2.5, prevY - perpY * 2.5);
      c.closePath();
      c.fill();
      // Tip highlight
      c.strokeStyle = '#e879f9';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(prevX + cosF * 3.5, prevY + sinF * 3.5);
      c.lineTo(prevX + perpX * 1.5, prevY + perpY * 1.5);
      c.stroke();
      // Barb spikes
      c.fillStyle = '#d946ef';
      c.beginPath();
      c.moveTo(prevX + perpX * 2.5, prevY + perpY * 2.5);
      c.lineTo(prevX + perpX * 4 + cosF * 1, prevY + perpY * 4 + sinF * 1);
      c.lineTo(prevX + perpX * 1.5, prevY + perpY * 1.5);
      c.closePath();
      c.fill();
      c.beginPath();
      c.moveTo(prevX - perpX * 2.5, prevY - perpY * 2.5);
      c.lineTo(prevX - perpX * 4 + cosF * 1, prevY - perpY * 4 + sinF * 1);
      c.lineTo(prevX - perpX * 1.5, prevY - perpY * 1.5);
      c.closePath();
      c.fill();
    } else if (form === WeaponForm.HAMMER) {
      // War hammer — thick handle with leather wrap + massive detailed head
      const len: number = 10;
      const headX: number = handX + cosF * len;
      const headY: number = handY + sinF * len;
      // Handle shadow
      c.strokeStyle = '#713f12';
      c.lineWidth = 3.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(headX, headY);
      c.stroke();
      // Handle body
      c.strokeStyle = '#8b6914';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(headX, headY);
      c.stroke();
      // Handle highlight
      c.strokeStyle = '#a38524';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + perpX * 0.8, handY + perpY * 0.8);
      c.lineTo(headX + perpX * 0.8, headY + perpY * 0.8);
      c.stroke();
      // Leather grip wrap
      c.strokeStyle = '#451a03';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const t: number = 0.15 + i * 0.18;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.8, wy + perpY * 1.8);
        c.lineTo(wx - perpX * 1.8, wy - perpY * 1.8);
        c.stroke();
      }
      // Hammer head — large detailed block
      c.save();
      c.translate(headX, headY);
      c.rotate(fAng);
      // Head shadow/base
      c.fillStyle = '#374151';
      c.fillRect(-3, -6, 12, 12);
      // Head body (dark iron)
      c.fillStyle = '#6b7280';
      c.fillRect(-2, -5, 10, 10);
      // Head top highlight (lighter iron)
      c.fillStyle = '#9ca3af';
      c.fillRect(-2, -5, 10, 3);
      // Head bottom shadow
      c.fillStyle = '#4b5563';
      c.fillRect(-2, 2, 10, 3);
      // Forging marks (horizontal lines)
      c.strokeStyle = '#374151';
      c.lineWidth = 0.5;
      c.globalAlpha = 0.4;
      for (let i: number = 0; i < 3; i++) {
        const fy: number = -3 + i * 3;
        c.beginPath();
        c.moveTo(-1, fy);
        c.lineTo(7, fy);
        c.stroke();
      }
      c.globalAlpha = 1.0;
      // Rivets on hammer face
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(6, -3, 1, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(6, 3, 1, 0, Math.PI * 2);
      c.fill();
      // Rivet highlights
      c.fillStyle = '#f3f4f6';
      c.beginPath();
      c.arc(5.5, -3.5, 0.4, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(5.5, 2.5, 0.4, 0, Math.PI * 2);
      c.fill();
      // Edge bevel
      c.strokeStyle = '#9ca3af';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(8, -5);
      c.lineTo(8, 5);
      c.stroke();
      c.restore();
    } else if (form === WeaponForm.STAFF) {
      // Magic staff — long ornate rod with glowing crystal orb
      const len: number = 18;
      const orbX: number = handX + cosF * len;
      const orbY: number = handY + sinF * len;
      // Rod shadow
      c.strokeStyle = '#4c1d95';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(orbX, orbY);
      c.stroke();
      // Rod body
      c.strokeStyle = '#7c3aed';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(orbX, orbY);
      c.stroke();
      // Rod highlight
      c.strokeStyle = '#8b5cf6';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX + perpX * 0.8, handY + perpY * 0.8);
      c.lineTo(orbX + perpX * 0.8, orbY + perpY * 0.8);
      c.stroke();
      // Ornate band wraps (golden rings along staff)
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      for (let i: number = 1; i <= 4; i++) {
        const t: number = i * 0.2;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.8, wy + perpY * 1.8);
        c.lineTo(wx - perpX * 1.8, wy - perpY * 1.8);
        c.stroke();
      }
      // Rune marks between bands (small glowing dots)
      c.fillStyle = '#a78bfa';
      c.globalAlpha = 0.6;
      for (let i: number = 0; i < 3; i++) {
        const t: number = 0.15 + i * 0.25;
        const rx: number = handX + cosF * len * t + perpX * 0.5;
        const ry: number = handY + sinF * len * t + perpY * 0.5;
        c.beginPath();
        c.arc(rx, ry, 0.6, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 1.0;
      // Crystal setting (metal prongs holding orb)
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.2;
      for (let i: number = 0; i < 3; i++) {
        const ang: number = fAng + (i - 1) * 1.2;
        c.beginPath();
        c.moveTo(orbX - cosF * 2, orbY - sinF * 2);
        c.lineTo(orbX + Math.cos(ang) * 3, orbY + Math.sin(ang) * 3);
        c.stroke();
      }
      // Orb glow (outer)
      const pulse: number = Math.sin(this.frameCount * 0.1) * 1.5;
      c.globalAlpha = 0.3;
      c.fillStyle = '#38bdf8';
      c.beginPath();
      c.arc(orbX, orbY, 5 + pulse, 0, Math.PI * 2);
      c.fill();
      // Orb mid glow
      c.globalAlpha = 0.5;
      c.fillStyle = '#0ea5e9';
      c.beginPath();
      c.arc(orbX, orbY, 4, 0, Math.PI * 2);
      c.fill();
      // Orb core
      c.globalAlpha = 0.9;
      c.fillStyle = '#7dd3fc';
      c.beginPath();
      c.arc(orbX, orbY, 3, 0, Math.PI * 2);
      c.fill();
      // Orb inner swirl (animated)
      c.strokeStyle = '#bae6fd';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      const swirlAng: number = this.frameCount * 0.08;
      c.beginPath();
      c.arc(orbX + Math.cos(swirlAng) * 1, orbY + Math.sin(swirlAng) * 1, 1.5, 0, Math.PI * 1.2);
      c.stroke();
      // Orb highlight
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.85;
      c.beginPath();
      c.arc(orbX - 1, orbY - 1, 1.2, 0, Math.PI * 2);
      c.fill();
      // Secondary highlight
      c.globalAlpha = 0.4;
      c.beginPath();
      c.arc(orbX + 1, orbY + 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.DUAL_BLADES) {
      // Twin daggers — detailed short curved blades with ornate hilts
      const len: number = 11;
      // Right blade
      const rTipX: number = handX + cosF * len + perpX * 1.5;
      const rTipY: number = handY + sinF * len + perpY * 1.5;
      // Blade shadow
      c.strokeStyle = '#c2410c';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      // Blade body
      c.strokeStyle = '#fb923c';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      // Blade edge highlight
      c.strokeStyle = '#fdba74';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + cosF * 2 + perpX * 0.5, handY + sinF * 2 + perpY * 0.5);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      // Fuller groove
      c.strokeStyle = '#9a3412';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(handX + cosF * 2, handY + sinF * 2);
      c.lineTo(handX + cosF * (len - 2) + perpX * 1.5, handY + sinF * (len - 2) + perpY * 1.5);
      c.stroke();
      c.globalAlpha = 1.0;
      // Right hilt guard
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX + perpX * 2.5, handY + perpY * 2.5);
      c.lineTo(handX - perpX * 1.5, handY - perpY * 1.5);
      c.stroke();
      // Right grip wrap
      c.strokeStyle = '#7c2d12';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX - cosF * 1 + perpX, handY - sinF * 1 + perpY);
      c.lineTo(handX - cosF * 1 - perpX, handY - sinF * 1 - perpY);
      c.stroke();
      // Right tip glint
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.7;
      c.beginPath();
      c.arc(rTipX, rTipY, 1, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      // Left blade
      const handX2: number = sx - 5;
      const lTipX: number = handX2 + cosF * len - perpX * 1.5;
      const lTipY: number = handY + sinF * len - perpY * 1.5;
      // Blade shadow
      c.strokeStyle = '#c2410c';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX2, handY);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      // Blade body
      c.strokeStyle = '#fb923c';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX2, handY);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      // Blade edge highlight
      c.strokeStyle = '#fdba74';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX2 + cosF * 2 - perpX * 0.5, handY + sinF * 2 - perpY * 0.5);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      // Fuller groove
      c.strokeStyle = '#9a3412';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(handX2 + cosF * 2, handY + sinF * 2);
      c.lineTo(handX2 + cosF * (len - 2) - perpX * 1.5, handY + sinF * (len - 2) - perpY * 1.5);
      c.stroke();
      c.globalAlpha = 1.0;
      // Left hilt guard
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX2 - perpX * 2.5, handY - perpY * 2.5);
      c.lineTo(handX2 + perpX * 1.5, handY + perpY * 1.5);
      c.stroke();
      // Left grip wrap
      c.strokeStyle = '#7c2d12';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX2 - cosF * 1 + perpX, handY - sinF * 1 + perpY);
      c.lineTo(handX2 - cosF * 1 - perpX, handY - sinF * 1 - perpY);
      c.stroke();
      // Left tip glint
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.7;
      c.beginPath();
      c.arc(lTipX, lTipY, 1, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.GREAT_AXE) {
      // Great axe — thick handle with wrappings + massive detailed crescent blade
      const len: number = 12;
      const axX: number = handX + cosF * len;
      const axY: number = handY + sinF * len;
      // Handle shadow
      c.strokeStyle = '#451a03';
      c.lineWidth = 4;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(axX, axY);
      c.stroke();
      // Handle body
      c.strokeStyle = '#78350f';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(axX, axY);
      c.stroke();
      // Handle highlight
      c.strokeStyle = '#92400e';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + perpX * 1, handY + perpY * 1);
      c.lineTo(axX + perpX * 1, axY + perpY * 1);
      c.stroke();
      // Handle leather bindings
      c.strokeStyle = '#1c0a00';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const t: number = 0.15 + i * 0.18;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 2, wy + perpY * 2);
        c.lineTo(wx - perpX * 2, wy - perpY * 2);
        c.stroke();
      }
      // Metal collar at axe head junction
      c.strokeStyle = '#6b7280';
      c.lineWidth = 2;
      const colX: number = handX + cosF * (len - 2);
      const colY: number = handY + sinF * (len - 2);
      c.beginPath();
      c.moveTo(colX + perpX * 2.5, colY + perpY * 2.5);
      c.lineTo(colX - perpX * 2.5, colY - perpY * 2.5);
      c.stroke();
      c.strokeStyle = '#9ca3af';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(colX + perpX * 2, colY + perpY * 2);
      c.lineTo(colX - perpX * 2, colY - perpY * 2);
      c.stroke();
      // Axe blade — large crescent with detailed textures
      c.save();
      c.translate(axX, axY);
      c.rotate(fAng);
      // Blade shadow
      c.fillStyle = '#991b1b';
      c.beginPath();
      c.moveTo(-1, -8);
      c.quadraticCurveTo(9, -6, 11, 0);
      c.quadraticCurveTo(9, 6, -1, 8);
      c.lineTo(-1, -8);
      c.closePath();
      c.fill();
      // Blade body (dark crimson)
      c.fillStyle = '#dc2626';
      c.beginPath();
      c.moveTo(0, -7);
      c.quadraticCurveTo(8, -5, 10, 0);
      c.quadraticCurveTo(8, 5, 0, 7);
      c.lineTo(0, -7);
      c.closePath();
      c.fill();
      // Blade inner highlight
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.moveTo(1, -5);
      c.quadraticCurveTo(6, -3, 8, 0);
      c.quadraticCurveTo(6, 1, 1, 2);
      c.lineTo(1, -5);
      c.closePath();
      c.fill();
      // Forging pattern (etched lines)
      c.strokeStyle = '#b91c1c';
      c.lineWidth = 0.5;
      c.globalAlpha = 0.5;
      for (let i: number = 0; i < 3; i++) {
        const fy: number = -4 + i * 3;
        c.beginPath();
        c.moveTo(2, fy);
        c.quadraticCurveTo(5, fy + 0.5, 7, fy);
        c.stroke();
      }
      c.globalAlpha = 1.0;
      // Blade edge highlight (sharp cutting edge)
      c.strokeStyle = '#fca5a5';
      c.lineWidth = 1.2;
      c.beginPath();
      c.moveTo(1, -6);
      c.quadraticCurveTo(7, -4, 9, 0);
      c.stroke();
      // Secondary edge highlight
      c.strokeStyle = '#fecaca';
      c.lineWidth = 0.6;
      c.beginPath();
      c.moveTo(2, -5);
      c.quadraticCurveTo(6, -3, 8, 0);
      c.stroke();
      // Spine (back edge, thicker)
      c.strokeStyle = '#7f1d1d';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(0, -7);
      c.lineTo(0, 7);
      c.stroke();
      // Rivet on blade
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(2, 0, 1, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#f3f4f6';
      c.beginPath();
      c.arc(1.5, -0.5, 0.4, 0, Math.PI * 2);
      c.fill();
      c.restore();
    }
  }

  private renderEvolutionEffects(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const level: number = p.evolutionLevel;
    if (level === EvolutionLevel.BASE) return;

    const branchColor: string = this.getBranchColor(p.evolutionBranch);
    const t: number = this.frameCount * 0.05;

    if (level >= EvolutionLevel.LEVEL_1) {
      c.globalAlpha = 0.15 + Math.sin(t) * 0.05;
      c.fillStyle = branchColor;
      c.beginPath();
      c.arc(sx, sy + bobY, 12, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    if (level >= EvolutionLevel.LEVEL_2) {
      const isMoving: boolean = Math.abs(p.vx) > 0.1 || Math.abs(p.vy) > 0.1;
      if (isMoving) {
        c.globalAlpha = 0.4;
        c.fillStyle = branchColor;
        for (let i: number = 0; i < 2; i++) {
          const px: number = sx + (Math.random() - 0.5) * 8;
          const py: number = sy + bobY + 6 + Math.random() * 4;
          c.beginPath();
          c.arc(px, py, 1 + Math.random(), 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
      }
    }

    if (level >= EvolutionLevel.LEVEL_3) {
      c.globalAlpha = 0.2 + Math.sin(t * 1.5) * 0.08;
      c.strokeStyle = branchColor;
      c.lineWidth = 1.5;
      c.beginPath();
      c.arc(sx, sy + bobY, 16 + Math.sin(t * 0.8) * 2, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 1.0;

      for (let i: number = 0; i < 3; i++) {
        const angle: number = t * 2 + (i * Math.PI * 2 / 3);
        const orbR: number = 14;
        const ox: number = sx + Math.cos(angle) * orbR;
        const oy: number = sy + bobY + Math.sin(angle) * orbR;
        c.globalAlpha = 0.6;
        c.fillStyle = branchColor;
        c.beginPath();
        c.arc(ox, oy, 1.5, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 1.0;
    }
  }

  private renderEnemies(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;

      const screenX: number = s.x + offX;
      const screenY: number = s.y + offY;

      if (screenX < -50 || screenX > this.screenW + 50 || screenY < -50 || screenY > this.screenH + 50) {
        continue;
      }

      const sc: number = s.size / 48;
      const bp: number = s.bouncePhase;
      const flash: boolean = s.hitFlash > 0;
      const cx: number = screenX;
      const cy: number = screenY;

      if (s.enemyType === EnemyType.GRAY_SLIME) {
        const bounce: number = Math.sin(bp) * 3 * sc;
        const squash: number = 1 + Math.sin(bp) * 0.12;
        c.save();
        c.translate(cx, cy + bounce);
        c.scale(squash, 1 / squash);
        c.globalAlpha = 0.2;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 14 * sc, 13 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.fill();
        } else {
          c.strokeStyle = '#1a1a2e';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_GRAY;
          c.beginPath();
          c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = COLOR_SLIME_GRAY_LIGHT;
          c.beginPath();
          c.ellipse(-3 * sc, -4 * sc, 6 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.45;
          c.beginPath();
          c.ellipse(-5 * sc, -6 * sc, 2.5 * sc, 1.8 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 0.2;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(4 * sc, 3 * sc, 2 * sc, 1.5 * sc, 0.3, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-4 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_PUPIL;
          c.beginPath();
          c.arc(-3.5 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-4 * sc, -1.2 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4 * sc, -1.2 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = COLOR_SLIME_PUPIL;
          c.lineWidth = 1 * sc;
          c.beginPath();
          c.arc(0, 3.5 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.PURPLE_SLIME) {
        const bounce: number = Math.sin(bp * 1.3) * 1.5 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        if (!flash) {
          c.globalAlpha = 0.12 + Math.sin(this.frameCount * 0.05) * 0.05;
          c.fillStyle = COLOR_SLIME_PURPLE;
          c.beginPath();
          c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 0.25;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 14 * sc, 13 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        for (let t: number = 0; t < 4; t++) {
          const angle: number = (t / 4) * Math.PI * 2 + this.frameCount * 0.03;
          const tx: number = Math.cos(angle) * 16 * sc;
          const ty: number = Math.sin(angle) * 10 * sc + 4 * sc;
          if (flash) {
            c.globalAlpha = 0.9;
            c.fillStyle = '#ffffff';
          } else {
            c.globalAlpha = 0.9;
            c.fillStyle = COLOR_SLIME_PURPLE;
          }
          c.beginPath();
          c.ellipse(tx, ty, 3 * sc, 2 * sc, angle, 0, Math.PI * 2);
          c.fill();
        }
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
        } else {
          c.strokeStyle = '#1a0533';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(0, 0, 16 * sc, 14 * sc, 0, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_PURPLE;
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = COLOR_SLIME_PURPLE_LIGHT;
          c.beginPath();
          c.ellipse(-3 * sc, -4 * sc, 7 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
          const dripPhase: number = (this.frameCount * 0.03) % 1;
          for (let d: number = 0; d < 3; d++) {
            const dx: number = (-6 + d * 6) * sc;
            const dy: number = 10 * sc + dripPhase * 8 * sc;
            const dAlpha: number = 0.6 * (1 - dripPhase);
            c.globalAlpha = dAlpha;
            c.fillStyle = COLOR_SLIME_PURPLE;
            c.beginPath();
            c.ellipse(dx, dy, 1.5 * sc, (2 + dripPhase * 3) * sc, 0, 0, Math.PI * 2);
            c.fill();
          }
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-4 * sc, -2 * sc, 3.2 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -2 * sc, 3.2 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#ff0040';
          c.beginPath();
          c.arc(-3.5 * sc, -1.5 * sc, 1.8 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1.5 * sc, 1.8 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1a1a2e';
          c.beginPath();
          c.arc(-3.5 * sc, -1.5 * sc, 0.9 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1.5 * sc, 0.9 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-4.2 * sc, -2.2 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.8 * sc, -2.2 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#4c1d95';
          c.lineWidth = 1.5 * sc;
          c.beginPath();
          c.moveTo(-8 * sc, -6 * sc);
          c.lineTo(-2 * sc, -4.5 * sc);
          c.stroke();
          c.beginPath();
          c.moveTo(8 * sc, -6 * sc);
          c.lineTo(2 * sc, -4.5 * sc);
          c.stroke();
          if (s.isEngulfing) {
            c.fillStyle = '#2d1060';
            c.beginPath();
            c.ellipse(0, 5 * sc, 6 * sc, 5 * sc, 0, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = '#1a0533';
            c.beginPath();
            c.ellipse(0, 6 * sc, 3 * sc, 2.5 * sc, 0, 0, Math.PI * 2);
            c.fill();
          } else {
            c.fillStyle = '#2d1060';
            c.beginPath();
            c.ellipse(0, 5 * sc, 5 * sc, 3 * sc, 0, 0, Math.PI * 2);
            c.fill();
          }
        }
        c.restore();
      } else if (s.enemyType === EnemyType.RED_SLIME) {
        const charge: number = s.isCharging ? Math.abs(Math.sin(this.frameCount * 0.08)) : Math.abs(Math.sin(this.frameCount * 0.04)) * 0.3;
        c.save();
        c.translate(cx, cy);
        if (!flash) {
          c.globalAlpha = 0.1 + charge * 0.1;
          c.fillStyle = '#ff4444';
          c.beginPath();
          c.ellipse(0, 0, (18 + charge * 2) * sc, (16 + charge * 2) * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 0.25;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 13 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          for (let fi: number = 0; fi < 7; fi++) {
            const angle: number = -Math.PI * 0.8 + (fi / 6) * Math.PI * 0.6;
            const flicker: number = Math.sin(this.frameCount * 0.12 + fi * 1.5) * 3;
            const len: number = (6 + flicker + charge * 3) * sc;
            const sx: number = Math.cos(angle) * 12 * sc;
            const sy: number = Math.sin(angle) * 10 * sc;
            const ex: number = sx + Math.cos(angle) * len;
            const ey: number = sy + Math.sin(angle) * len;
            c.fillStyle = fi % 2 === 0 ? '#ff6600' : '#ffaa00';
            c.globalAlpha = 0.7;
            c.beginPath();
            c.moveTo(sx - 2 * sc, sy);
            c.lineTo(ex, ey);
            c.lineTo(sx + 2 * sc, sy);
            c.closePath();
            c.fill();
          }
          c.strokeStyle = '#7f1d1d';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(1 * sc, 0, 15 * sc, 12 * sc, 0.1, 0, Math.PI * 2);
          c.stroke();
        }
        c.globalAlpha = 1.0;
        if (flash) {
          c.fillStyle = '#ffffff';
        } else {
          c.fillStyle = COLOR_SLIME_RED;
        }
        c.beginPath();
        c.ellipse(1 * sc, 0, 14 * sc, 11 * sc, 0.1, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_RED_LIGHT;
          c.beginPath();
          c.ellipse(-2 * sc, -3.5 * sc, 6 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-3.5 * sc, -1.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -1.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#ffcc00';
          c.beginPath();
          c.arc(-3 * sc, -1 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1a1a2e';
          c.beginPath();
          c.arc(-3 * sc, -1 * sc, 0.7 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1 * sc, 0.7 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-3.5 * sc, -1.8 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4 * sc, -1.8 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#7f1d1d';
          c.lineWidth = 1.5 * sc;
          c.beginPath();
          c.moveTo(-7 * sc, -5 * sc);
          c.lineTo(-2 * sc, -3.5 * sc);
          c.stroke();
          c.beginPath();
          c.moveTo(7 * sc, -5 * sc);
          c.lineTo(2 * sc, -3.5 * sc);
          c.stroke();
          c.strokeStyle = '#7f1d1d';
          c.lineWidth = 1.2 * sc;
          c.beginPath();
          c.moveTo(-4 * sc, 4 * sc);
          c.lineTo(-2 * sc, 2.5 * sc);
          c.lineTo(0, 4 * sc);
          c.lineTo(2 * sc, 2.5 * sc);
          c.lineTo(4 * sc, 4 * sc);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.BLUE_SLIME) {
        const bounce: number = Math.sin(bp * 0.8) * 1.5 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        if (!flash) {
          for (let d: number = 0; d < 6; d++) {
            const angle: number = (d / 6) * Math.PI * 2 + this.frameCount * 0.02;
            const dist: number = (16 + Math.sin(this.frameCount * 0.03 + d * 2) * 3) * sc;
            const dx: number = Math.cos(angle) * dist;
            const dy: number = Math.sin(angle) * dist * 0.7 - 2.5 * sc;
            c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
            c.globalAlpha = 0.4 + Math.sin(this.frameCount * 0.04 + d) * 0.2;
            c.beginPath();
            c.moveTo(dx, dy - 2 * sc);
            c.lineTo(dx + 1 * sc, dy - 0.5 * sc);
            c.lineTo(dx + 2 * sc, dy);
            c.lineTo(dx + 1 * sc, dy + 0.5 * sc);
            c.lineTo(dx, dy + 2 * sc);
            c.lineTo(dx - 1 * sc, dy + 0.5 * sc);
            c.lineTo(dx - 2 * sc, dy);
            c.lineTo(dx - 1 * sc, dy - 0.5 * sc);
            c.closePath();
            c.fill();
          }
        }
        c.globalAlpha = 0.2;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 13 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.fill();
        } else {
          c.strokeStyle = '#0c2d5e';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.7;
          c.fillStyle = COLOR_SLIME_BLUE;
          c.beginPath();
          c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 0.3;
          c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
          const rippleOff: number = Math.sin(this.frameCount * 0.04) * 1.5 * sc;
          c.beginPath();
          c.ellipse(0, rippleOff, 10 * sc, 7 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.15;
          c.beginPath();
          c.ellipse(-4 * sc, -5 * sc, 4 * sc, 3 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#93c5fd';
          c.lineWidth = 0.8 * sc;
          c.globalAlpha = 0.4;
          for (let w: number = 0; w < 3; w++) {
            const wy: number = (-3 + w * 4) * sc;
            const woff: number = Math.sin(this.frameCount * 0.05 + w) * 2 * sc;
            c.beginPath();
            c.moveTo(-8 * sc, wy + woff);
            c.quadraticCurveTo(0, wy - woff - 1.5 * sc, 8 * sc, wy + woff);
            c.stroke();
          }
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-3.5 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(3.5 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#1e40af';
          c.beginPath();
          c.arc(-3 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-3.5 * sc, -1.2 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.5 * sc, -1.2 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#1e3a5f';
          c.lineWidth = 1 * sc;
          c.beginPath();
          c.arc(0, 3 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.YELLOW_SLIME) {
        const bounce: number = Math.abs(Math.sin(bp * 1.1)) * 4 * sc;
        c.save();
        c.translate(cx, cy - bounce);
        if (!flash) {
          c.globalAlpha = 0.08 + Math.sin(this.frameCount * 0.04) * 0.03;
          c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
          c.beginPath();
          c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
          c.fill();
          for (let sp: number = 0; sp < 8; sp++) {
            const angle: number = (sp / 8) * Math.PI * 2 + this.frameCount * 0.04;
            const dist: number = (14 + Math.sin(this.frameCount * 0.06 + sp * 3) * 4) * sc;
            const sx: number = Math.cos(angle) * dist;
            const sy: number = Math.sin(angle) * dist * 0.6;
            const sparkSize: number = (1 + Math.sin(this.frameCount * 0.1 + sp * 2) * 0.6) * sc;
            c.fillStyle = sp % 2 === 0 ? COLOR_SLIME_YELLOW_LIGHT : '#ffffff';
            c.globalAlpha = 0.6 + Math.sin(this.frameCount * 0.08 + sp) * 0.3;
            c.beginPath();
            c.moveTo(sx, sy - sparkSize * 2);
            c.lineTo(sx + sparkSize * 0.4, sy - sparkSize * 0.4);
            c.lineTo(sx + sparkSize * 2, sy);
            c.lineTo(sx + sparkSize * 0.4, sy + sparkSize * 0.4);
            c.lineTo(sx, sy + sparkSize * 2);
            c.lineTo(sx - sparkSize * 0.4, sy + sparkSize * 0.4);
            c.lineTo(sx - sparkSize * 2, sy);
            c.lineTo(sx - sparkSize * 0.4, sy - sparkSize * 0.4);
            c.closePath();
            c.fill();
          }
          if (Math.random() < 0.3) {
            const boltAngle: number = Math.random() * Math.PI * 2;
            const boltDist: number = 10 * sc;
            const bx: number = Math.cos(boltAngle) * boltDist;
            const by: number = Math.sin(boltAngle) * boltDist * 0.6;
            c.strokeStyle = '#fef08a';
            c.lineWidth = 1 * sc;
            c.globalAlpha = 0.7;
            c.beginPath();
            c.moveTo(bx, by);
            c.lineTo(bx + 3 * sc, by - 2 * sc);
            c.lineTo(bx + 1 * sc, by - 1 * sc);
            c.lineTo(bx + 4 * sc, by - 4 * sc);
            c.stroke();
          }
        }
        c.globalAlpha = 0.15;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, (13 + bounce / sc) * sc, 11 * sc, 2.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(0, 0, 13 * sc, 11 * sc, 0, 0, Math.PI * 2);
          c.fill();
        } else {
          c.strokeStyle = '#78350f';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(0, 0, 13 * sc, 11 * sc, 0, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_YELLOW;
          c.beginPath();
          c.ellipse(0, 0, 12 * sc, 10 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
          c.beginPath();
          c.ellipse(-2.5 * sc, -3.5 * sc, 5.5 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.5;
          c.beginPath();
          c.ellipse(-4 * sc, -5.5 * sc, 2.5 * sc, 1.8 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-3 * sc, -0.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(3 * sc, -0.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#92400e';
          c.beginPath();
          c.arc(-2.5 * sc, 0, 1.3 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.5 * sc, 0, 1.3 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-3 * sc, -0.8 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3 * sc, -0.8 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#92400e';
          c.lineWidth = 1 * sc;
          c.beginPath();
          c.arc(0, 3 * sc, 3.5 * sc, 0.1, Math.PI - 0.1);
          c.stroke();
          c.fillStyle = '#f59e0b';
          c.globalAlpha = 0.3;
          c.beginPath();
          c.ellipse(-6 * sc, 2 * sc, 2 * sc, 1.2 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.ellipse(6 * sc, 2 * sc, 2 * sc, 1.2 * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.GHOST_SLIME) {
        const float: number = Math.sin(bp * 0.5) * 4 * sc;
        const phase: number = Math.sin(this.frameCount * 0.05) * 0.15;
        c.save();
        c.translate(cx, cy + float);
        if (!flash) {
          c.globalAlpha = 0.06 + Math.sin(this.frameCount * 0.04) * 0.03;
          c.fillStyle = COLOR_SLIME_GHOST;
          c.beginPath();
          c.ellipse(0, 0, 22 * sc, 20 * sc, 0, 0, Math.PI * 2);
          c.fill();
          for (let w: number = 0; w < 5; w++) {
            const wAngle: number = (w / 5) * Math.PI * 2 + this.frameCount * 0.02;
            const wDist: number = (10 + Math.sin(this.frameCount * 0.03 + w * 2) * 5) * sc;
            const wx: number = Math.cos(wAngle) * wDist;
            const wy: number = Math.sin(wAngle) * wDist * 0.5 + 5 * sc;
            c.fillStyle = COLOR_SLIME_GHOST_LIGHT;
            c.globalAlpha = 0.15 + Math.sin(this.frameCount * 0.05 + w) * 0.1;
            c.beginPath();
            c.ellipse(wx, wy, 2.5 * sc, 1.5 * sc, wAngle, 0, Math.PI * 2);
            c.fill();
          }
          for (let trail: number = 0; trail < 3; trail++) {
            const ty: number = 8 * sc + trail * 4 * sc;
            const tx: number = Math.sin(this.frameCount * 0.04 + trail * 2) * 3 * sc;
            c.fillStyle = COLOR_SLIME_GHOST;
            c.globalAlpha = 0.1 * (1 - trail * 0.3);
            c.beginPath();
            c.ellipse(tx, ty, (4 - trail) * sc, (2 - trail * 0.5) * sc, 0, 0, Math.PI * 2);
            c.fill();
          }
        }
        const bodyAlpha: number = flash ? 0.9 : (0.45 + phase);
        c.globalAlpha = bodyAlpha;
        if (flash) {
          c.fillStyle = '#ffffff';
        } else {
          c.strokeStyle = '#334155';
          c.lineWidth = 1.5 * sc;
          c.globalAlpha = bodyAlpha * 0.6;
          c.beginPath();
          c.moveTo(-12 * sc, 4 * sc);
          c.quadraticCurveTo(-13 * sc, -10 * sc, 0, -12 * sc);
          c.quadraticCurveTo(13 * sc, -10 * sc, 12 * sc, 4 * sc);
          const wv1: number = Math.sin(this.frameCount * 0.06) * 1.5 * sc;
          const wv2: number = Math.sin(this.frameCount * 0.06 + 1) * 1.5 * sc;
          const wv3: number = Math.sin(this.frameCount * 0.06 + 2) * 1.5 * sc;
          c.quadraticCurveTo(10 * sc, 10 * sc + wv1, 6 * sc, 8 * sc);
          c.quadraticCurveTo(3 * sc, 12 * sc + wv2, 0, 9 * sc);
          c.quadraticCurveTo(-3 * sc, 12 * sc + wv3, -6 * sc, 8 * sc);
          c.quadraticCurveTo(-10 * sc, 10 * sc + wv1, -12 * sc, 4 * sc);
          c.closePath();
          c.stroke();
          c.globalAlpha = bodyAlpha;
          c.fillStyle = COLOR_SLIME_GHOST;
          c.beginPath();
          c.moveTo(-12 * sc, 4 * sc);
          c.quadraticCurveTo(-13 * sc, -10 * sc, 0, -12 * sc);
          c.quadraticCurveTo(13 * sc, -10 * sc, 12 * sc, 4 * sc);
          c.quadraticCurveTo(10 * sc, 10 * sc + wv1, 6 * sc, 8 * sc);
          c.quadraticCurveTo(3 * sc, 12 * sc + wv2, 0, 9 * sc);
          c.quadraticCurveTo(-3 * sc, 12 * sc + wv3, -6 * sc, 8 * sc);
          c.quadraticCurveTo(-10 * sc, 10 * sc + wv1, -12 * sc, 4 * sc);
          c.closePath();
          c.fill();
          c.fillStyle = COLOR_SLIME_GHOST_LIGHT;
          c.globalAlpha = 0.25;
          c.beginPath();
          c.ellipse(0, -2 * sc, 7 * sc, 6 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.1;
          c.beginPath();
          c.ellipse(-3 * sc, -6 * sc, 4 * sc, 2.5 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = flash ? 0.9 : 0.85;
        c.fillStyle = flash ? '#ffffff' : '#e2e8f0';
        c.beginPath();
        c.ellipse(-4 * sc, -3 * sc, 2.8 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -3 * sc, 2.8 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.9;
          c.beginPath();
          c.ellipse(-4 * sc, -2.5 * sc, 1.5 * sc, 2 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.ellipse(4 * sc, -2.5 * sc, 1.5 * sc, 2 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#94a3b8';
          c.globalAlpha = 0.6;
          c.beginPath();
          c.arc(-4.5 * sc, -3.5 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.5 * sc, -3.5 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.6;
          c.beginPath();
          c.ellipse(0, 3 * sc, 3 * sc, (2.5 + Math.sin(this.frameCount * 0.04)) * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.restore();
      }

      c.globalAlpha = 1.0;
      if (s.isCharging && s.enemyType !== EnemyType.RED_SLIME) {
        const halfSize: number = s.size / 2;
        c.globalAlpha = 0.4;
        c.fillStyle = COLOR_SLIME_RED;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + 6, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      if (s.hp < s.maxHp) {
        const barW: number = s.size;
        const barH: number = 3;
        const barY: number = screenY - s.size / 2 - 6;
        c.fillStyle = '#374151';
        c.fillRect(screenX - barW / 2, barY, barW, barH);
        c.fillStyle = '#ef4444';
        c.fillRect(screenX - barW / 2, barY, barW * (s.hp / s.maxHp), barH);
      }
    }
  }

  private renderXpOrbs(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.xpOrbs.length; i++) {
      const orb: XpOrb = this.xpOrbs[i];
      if (!orb.active) continue;

      const screenX: number = orb.x + offX;
      const screenY: number = orb.y + offY;

      if (screenX < -20 || screenX > this.screenW + 20 || screenY < -20 || screenY > this.screenH + 20) {
        continue;
      }

      const bob: number = Math.sin(orb.bobPhase) * 2;

      c.globalAlpha = 0.2;
      c.fillStyle = COLOR_XP_GLOW;
      c.beginPath();
      c.arc(screenX, screenY + bob, XP_ORB_SIZE + 4, 0, Math.PI * 2);
      c.fill();

      c.globalAlpha = 0.9;
      c.fillStyle = COLOR_XP_ORB;
      c.beginPath();
      c.arc(screenX, screenY + bob, XP_ORB_SIZE, 0, Math.PI * 2);
      c.fill();

      c.globalAlpha = 1.0;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(screenX - 1, screenY - 1 + bob, 2, 0, Math.PI * 2);
      c.fill();
    }
    c.globalAlpha = 1.0;
  }

  private renderTraps(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.traps.length; i++) {
      const trap: TrapInstance = this.traps[i];
      const screenX: number = trap.x + offX;
      const screenY: number = trap.y + offY;

      if (screenX < -40 || screenX > this.screenW + 40 || screenY < -40 || screenY > this.screenH + 40) {
        continue;
      }

      if (trap.state === TrapState.IDLE) continue;

      const isActive: boolean = trap.state === TrapState.ACTIVE;
      const isTelegraph: boolean = trap.state === TrapState.TELEGRAPH;

      if (isTelegraph) {
        const pulse: number = 0.3 + 0.3 * Math.sin(this.frameCount * 0.3);
        c.globalAlpha = pulse;
        c.fillStyle = COLOR_TRAP_WARNING;
        c.beginPath();
        c.arc(screenX, screenY, trap.triggerRadius, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      switch (trap.trapType) {
        case TrapType.GROUND_SPIKES:
          if (isActive) {
            c.fillStyle = '#4b5563';
            c.fillRect(screenX - 13, screenY + 4, 26, 4);
            c.fillStyle = COLOR_SPIKE;
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              c.beginPath();
              c.moveTo(spX - 3, spY);
              c.lineTo(spX - 1, spY - 10);
              c.lineTo(spX, spY - 16);
              c.lineTo(spX + 1, spY - 10);
              c.lineTo(spX + 3, spY);
              c.closePath();
              c.fill();
            }
            c.fillStyle = COLOR_SPIKE_TIP;
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              c.beginPath();
              c.moveTo(spX - 0.5, spY - 12);
              c.lineTo(spX, spY - 16);
              c.lineTo(spX + 0.5, spY - 12);
              c.closePath();
              c.fill();
            }
            c.fillStyle = '#9ca3af';
            c.globalAlpha = 0.4;
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              c.fillRect(spX - 1, spY - 8, 1, 6);
            }
            c.globalAlpha = 1.0;
          } else {
            c.fillStyle = '#374151';
            c.globalAlpha = 0.4;
            c.fillRect(screenX - 13, screenY + 5, 26, 3);
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              c.fillRect(spX - 1, screenY + 4, 2, 3);
            }
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.FALLING_ROCKS:
          if (isActive) {
            for (let r: number = 0; r < 4; r++) {
              const rx: number = screenX - 9 + r * 6;
              const ry: number = screenY - 6 + Math.sin(r * 1.5) * 4;
              const rSize: number = 4 + Math.sin(r * 2.3) * 1.5;
              c.fillStyle = COLOR_ROCK;
              c.beginPath();
              c.moveTo(rx, ry - rSize);
              c.lineTo(rx + rSize * 0.8, ry - rSize * 0.3);
              c.lineTo(rx + rSize, ry + rSize * 0.5);
              c.lineTo(rx + rSize * 0.3, ry + rSize);
              c.lineTo(rx - rSize * 0.5, ry + rSize * 0.7);
              c.lineTo(rx - rSize, ry);
              c.closePath();
              c.fill();
              c.fillStyle = '#9ca3af';
              c.globalAlpha = 0.3;
              c.fillRect(rx - 1, ry - rSize * 0.5, 2, rSize * 0.5);
              c.globalAlpha = 1.0;
            }
          } else if (isTelegraph) {
            c.fillStyle = COLOR_ROCK;
            c.globalAlpha = 0.5;
            const fallProgress: number = 1.0 - (trap.timer / TRAP_TELEGRAPH_TIME);
            for (let r: number = 0; r < 3; r++) {
              const rx: number = screenX - 6 + r * 6;
              const ry: number = screenY - 35 + fallProgress * 28;
              const rSize: number = 3 + r * 0.5;
              c.beginPath();
              c.moveTo(rx, ry - rSize);
              c.lineTo(rx + rSize, ry);
              c.lineTo(rx, ry + rSize);
              c.lineTo(rx - rSize, ry);
              c.closePath();
              c.fill();
            }
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.POISON_SPORES:
          if (isActive) {
            c.globalAlpha = 0.6;
            c.fillStyle = COLOR_POISON_CLOUD;
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.8, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 0.4;
            c.beginPath();
            c.arc(screenX + 5, screenY - 4, trap.size * 0.5, 0, Math.PI * 2);
            c.fill();
            c.beginPath();
            c.arc(screenX - 4, screenY + 3, trap.size * 0.4, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 0.3;
            c.fillStyle = '#4ade80';
            for (let p: number = 0; p < 4; p++) {
              const pAngle: number = (p / 4) * Math.PI * 2 + this.frameCount * 0.05;
              const pDist: number = trap.size * 0.5;
              const px: number = screenX + Math.cos(pAngle) * pDist;
              const py: number = screenY + Math.sin(pAngle) * pDist;
              c.beginPath();
              c.arc(px, py, 2, 0, Math.PI * 2);
              c.fill();
            }
            c.globalAlpha = 1.0;
          } else if (isTelegraph) {
            c.fillStyle = '#22c55e';
            c.globalAlpha = 0.3;
            c.beginPath();
            c.arc(screenX, screenY + 4, 3, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 0.15;
            c.beginPath();
            c.arc(screenX, screenY + 2, 5, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.LAVA_GEYSER:
          if (isActive) {
            const geyserH: number = 22 + Math.sin(this.frameCount * 0.2) * 6;
            c.globalAlpha = 0.3;
            c.fillStyle = COLOR_LAVA;
            c.fillRect(screenX - 12, screenY - geyserH * 0.7, 24, geyserH * 0.7);
            c.globalAlpha = 0.8;
            c.fillStyle = COLOR_LAVA_GEYSER;
            c.fillRect(screenX - 7, screenY - geyserH, 14, geyserH);
            c.fillStyle = '#fef08a';
            c.globalAlpha = 0.6;
            c.fillRect(screenX - 3, screenY - geyserH, 6, geyserH * 0.8);
            for (let splash: number = 0; splash < 4; splash++) {
              const sx: number = screenX + (Math.random() - 0.5) * 16;
              const sy: number = screenY - geyserH + Math.random() * 5;
              c.fillStyle = '#fbbf24';
              c.globalAlpha = 0.5;
              c.beginPath();
              c.arc(sx, sy, 1.5, 0, Math.PI * 2);
              c.fill();
            }
            c.globalAlpha = 1.0;
          } else if (isTelegraph) {
            c.fillStyle = COLOR_LAVA_GEYSER;
            c.globalAlpha = 0.25;
            c.beginPath();
            c.arc(screenX, screenY, 9, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = '#fef08a';
            c.globalAlpha = 0.15;
            c.beginPath();
            c.arc(screenX, screenY, 5, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.VOID_CRACK:
          c.fillStyle = COLOR_VOID_CRACK;
          if (isActive) {
            c.globalAlpha = 0.7 + 0.3 * Math.sin(this.frameCount * 0.15);
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.7, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = '#1e1b4b';
            c.globalAlpha = 0.9;
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.4, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = COLOR_VOID_PULL;
            c.globalAlpha = 0.4;
            c.beginPath();
            c.arc(screenX, screenY, trap.triggerRadius * 1.3, 0, Math.PI * 2);
            c.fill();
            c.strokeStyle = '#7c3aed';
            c.lineWidth = 1.5;
            c.globalAlpha = 0.5;
            for (let crack: number = 0; crack < 4; crack++) {
              const cAngle: number = (crack / 4) * Math.PI * 2 + this.frameCount * 0.02;
              c.beginPath();
              c.moveTo(screenX + Math.cos(cAngle) * trap.size * 0.4, screenY + Math.sin(cAngle) * trap.size * 0.4);
              c.lineTo(screenX + Math.cos(cAngle) * trap.size * 0.9, screenY + Math.sin(cAngle) * trap.size * 0.9);
              c.stroke();
            }
            c.globalAlpha = 1.0;
          } else {
            c.globalAlpha = 0.3;
            c.beginPath();
            c.arc(screenX, screenY, 7, 0, Math.PI * 2);
            c.fill();
            c.strokeStyle = COLOR_VOID_CRACK;
            c.lineWidth = 1;
            c.globalAlpha = 0.2;
            c.beginPath();
            c.arc(screenX, screenY, 10, 0, Math.PI * 2);
            c.stroke();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.WATER_VORTEX:
          if (isActive) {
            const spin: number = this.frameCount * 0.12;
            c.globalAlpha = 0.2;
            c.fillStyle = COLOR_VORTEX;
            c.beginPath();
            c.arc(screenX, screenY, 14, 0, Math.PI * 2);
            c.fill();
            c.strokeStyle = COLOR_VORTEX;
            c.lineWidth = 2.5;
            c.globalAlpha = 0.7;
            for (let ring: number = 0; ring < 4; ring++) {
              const r: number = 3 + ring * 4;
              c.beginPath();
              c.arc(screenX, screenY, r, spin + ring, spin + ring + Math.PI * 1.3);
              c.stroke();
            }
            c.fillStyle = '#ffffff';
            c.globalAlpha = 0.4;
            c.beginPath();
            c.arc(screenX, screenY, 2, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
            c.lineWidth = 1;
          } else {
            c.fillStyle = COLOR_VORTEX;
            c.globalAlpha = 0.2;
            c.beginPath();
            c.arc(screenX, screenY, 6, 0, Math.PI * 2);
            c.fill();
            c.strokeStyle = COLOR_VORTEX;
            c.lineWidth = 1;
            c.globalAlpha = 0.15;
            c.beginPath();
            c.arc(screenX, screenY, 9, 0, Math.PI * 2);
            c.stroke();
            c.globalAlpha = 1.0;
          }
          break;
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderMechanisms(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.mechanisms.length; i++) {
      const mech: MechanismInstance = this.mechanisms[i];
      const screenX: number = mech.x + offX;
      const screenY: number = mech.y + offY;

      if (screenX < -40 || screenX > this.screenW + 40 || screenY < -40 || screenY > this.screenH + 40) {
        continue;
      }

      switch (mech.mechanismType) {
        case MechanismType.PRESSURE_PLATE:
          c.fillStyle = '#374151';
          c.globalAlpha = 0.3;
          c.fillRect(screenX - 13, screenY - 13, 26, 26);
          if (mech.active) {
            c.fillStyle = COLOR_PLATE_ACTIVE;
            c.globalAlpha = 0.9;
            c.fillRect(screenX - 10, screenY - 8, 20, 16);
            c.fillStyle = '#4ade80';
            c.globalAlpha = 0.4;
            c.fillRect(screenX - 8, screenY - 6, 16, 12);
            c.fillStyle = '#ffffff';
            c.globalAlpha = 0.3;
            c.fillRect(screenX - 6, screenY - 4, 4, 2);
          } else {
            c.fillStyle = COLOR_PRESSURE_PLATE;
            c.globalAlpha = 0.6;
            c.fillRect(screenX - 10, screenY - 10, 20, 20);
            c.fillStyle = '#6b7280';
            c.globalAlpha = 0.3;
            c.fillRect(screenX - 8, screenY - 8, 16, 16);
            c.strokeStyle = '#4b5563';
            c.lineWidth = 1;
            c.globalAlpha = 0.4;
            c.strokeRect(screenX - 10, screenY - 10, 20, 20);
          }
          c.globalAlpha = 1.0;
          break;

        case MechanismType.LEVER:
          c.fillStyle = '#4b5563';
          c.fillRect(screenX - 5, screenY + 8, 10, 6);
          c.fillStyle = COLOR_LEVER;
          c.fillRect(screenX - 3, screenY - 12, 6, 24);
          c.fillStyle = '#6b7280';
          c.fillRect(screenX - 2, screenY - 10, 2, 20);
          c.save();
          c.translate(screenX, screenY);
          c.rotate(mech.rotation * Math.PI / 180);
          c.fillStyle = COLOR_LEVER_HANDLE;
          c.fillRect(-2.5, -16, 5, 16);
          c.fillStyle = '#9ca3af';
          c.fillRect(-1.5, -14, 2, 12);
          c.fillStyle = mech.active ? '#4ade80' : '#ef4444';
          c.beginPath();
          c.arc(0, -16, 4, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.4;
          c.beginPath();
          c.arc(-1, -17, 1.5, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.restore();
          break;

        case MechanismType.PUSH_BLOCK:
          const bx: number = mech.posX + offX;
          const by: number = mech.posY + offY;
          c.fillStyle = '#374151';
          c.globalAlpha = 0.2;
          c.fillRect(bx - 13, by - 11, 26, 26);
          c.fillStyle = COLOR_PUSH_BLOCK;
          c.globalAlpha = 1.0;
          c.fillRect(bx - 12, by - 12, 24, 24);
          c.fillStyle = '#737373';
          c.fillRect(bx - 10, by - 10, 20, 2);
          c.fillRect(bx - 10, by - 10, 2, 20);
          c.fillStyle = '#525252';
          c.fillRect(bx - 10, by + 8, 20, 2);
          c.fillRect(bx + 8, by - 10, 2, 20);
          c.fillStyle = '#737373';
          c.fillRect(bx - 4, by - 4, 3, 3);
          c.fillRect(bx + 2, by + 2, 3, 3);
          c.fillRect(bx - 3, by + 3, 2, 2);
          c.strokeStyle = '#525252';
          c.lineWidth = 1;
          c.strokeRect(bx - 12, by - 12, 24, 24);
          break;

        case MechanismType.CRYSTAL_REFLECTOR:
          c.save();
          c.translate(screenX, screenY);
          c.rotate(mech.rotation * Math.PI / 180);
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.3;
          c.beginPath();
          for (let v: number = 0; v < 6; v++) {
            const angle: number = (v / 6) * Math.PI * 2;
            const r: number = 12;
            if (v === 0) c.moveTo(Math.cos(angle) * r, Math.sin(angle) * r);
            else c.lineTo(Math.cos(angle) * r, Math.sin(angle) * r);
          }
          c.closePath();
          c.fill();
          c.fillStyle = COLOR_REFLECTOR;
          c.globalAlpha = 1.0;
          c.beginPath();
          for (let v: number = 0; v < 6; v++) {
            const angle: number = (v / 6) * Math.PI * 2;
            const r: number = 10;
            if (v === 0) c.moveTo(Math.cos(angle) * r, Math.sin(angle) * r);
            else c.lineTo(Math.cos(angle) * r, Math.sin(angle) * r);
          }
          c.closePath();
          c.fill();
          c.strokeStyle = '#a5b4fc';
          c.lineWidth = 1.5;
          c.globalAlpha = 0.6;
          c.beginPath();
          for (let v: number = 0; v < 6; v++) {
            const angle: number = (v / 6) * Math.PI * 2;
            const r: number = 10;
            if (v === 0) c.moveTo(Math.cos(angle) * r, Math.sin(angle) * r);
            else c.lineTo(Math.cos(angle) * r, Math.sin(angle) * r);
          }
          c.closePath();
          c.stroke();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.5 + 0.3 * Math.sin(this.frameCount * 0.1);
          c.beginPath();
          c.arc(0, 0, 4, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#c7d2fe';
          c.globalAlpha = 0.3;
          c.beginPath();
          c.arc(0, 0, 6, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.restore();
          break;

        case MechanismType.BREAKABLE_WALL:
          c.fillStyle = COLOR_BREAKABLE_WALL;
          c.fillRect(screenX - TILE_SIZE / 2, screenY - TILE_SIZE / 2, TILE_SIZE, TILE_SIZE);
          c.fillStyle = '#4a4a65';
          c.globalAlpha = 0.3;
          c.fillRect(screenX - TILE_SIZE / 2, screenY - TILE_SIZE / 2, TILE_SIZE, 2);
          c.fillRect(screenX - TILE_SIZE / 2, screenY - TILE_SIZE / 2, 2, TILE_SIZE);
          c.strokeStyle = '#3a3a55';
          c.lineWidth = 1.5;
          c.globalAlpha = 0.7;
          c.beginPath();
          c.moveTo(screenX - 8, screenY - 10);
          c.lineTo(screenX - 3, screenY - 2);
          c.lineTo(screenX + 2, screenY + 4);
          c.moveTo(screenX + 6, screenY - 8);
          c.lineTo(screenX + 1, screenY);
          c.lineTo(screenX - 2, screenY + 8);
          c.moveTo(screenX - 5, screenY + 5);
          c.lineTo(screenX, screenY + 2);
          c.stroke();
          c.globalAlpha = 1.0;
          break;

        case MechanismType.TELEPORT_RUNE:
          const runeColor: string = mech.active ? COLOR_TELEPORT_EXIT : COLOR_TELEPORT_ENTRY;
          const spin: number = this.frameCount * 0.04;
          c.globalAlpha = 0.15;
          c.fillStyle = runeColor;
          c.beginPath();
          c.arc(screenX, screenY, 16, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = runeColor;
          c.lineWidth = 2;
          c.globalAlpha = 0.6;
          c.beginPath();
          c.arc(screenX, screenY, 12, 0, Math.PI * 2);
          c.stroke();
          c.lineWidth = 1.5;
          c.globalAlpha = 0.5;
          c.beginPath();
          c.arc(screenX, screenY, 8, spin, spin + Math.PI * 1.5);
          c.stroke();
          for (let rune: number = 0; rune < 3; rune++) {
            const rAngle: number = spin * 2 + (rune / 3) * Math.PI * 2;
            const rx: number = screenX + Math.cos(rAngle) * 10;
            const ry: number = screenY + Math.sin(rAngle) * 10;
            c.fillStyle = runeColor;
            c.globalAlpha = 0.4;
            c.fillRect(rx - 1.5, ry - 1.5, 3, 3);
          }
          c.fillStyle = COLOR_TELEPORT_RUNE;
          c.globalAlpha = 0.3 + 0.2 * Math.sin(this.frameCount * 0.08);
          c.beginPath();
          c.arc(screenX, screenY, 6, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.4;
          c.beginPath();
          c.arc(screenX, screenY, 2, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.lineWidth = 1;
          break;
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderParticles(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.particles.length; i++) {
      const pt: Particle = this.particles[i];
      const alpha: number = pt.life / pt.maxLife;
      c.globalAlpha = alpha;
      c.fillStyle = pt.color;
      const sz: number = pt.size * alpha;
      c.fillRect(pt.x + offX - sz / 2, pt.y + offY - sz / 2, sz, sz);
    }
    c.globalAlpha = 1.0;
  }

  private initAmbientParticles(): void {
    const colors: string[] = ['#ffd70033', '#00ced133', '#ff69b433', '#4ade8033', '#60a5fa33'];
    for (let i: number = 0; i < 30; i++) {
      this.ambientParticles.push({
        x: Math.random() * this.screenW,
        y: Math.random() * this.screenH,
        vx: (Math.random() - 0.5) * 0.3,
        vy: -0.1 - Math.random() * 0.3,
        size: 1 + Math.random() * 2.5,
        alpha: 0.1 + Math.random() * 0.25,
        color: colors[Math.floor(Math.random() * colors.length)],
        life: Math.random() * 4000,
        maxLife: 3000 + Math.random() * 3000
      });
    }
  }

  private updateAmbientParticles(dt: number): void {
    const playerBiome: BiomeType = this.player !== null ?
      this.worldGen.getBiome(this.player.x, this.player.y) : BiomeType.NORMAL;

    for (let i: number = 0; i < this.ambientParticles.length; i++) {
      const ap: AmbientParticle = this.ambientParticles[i];
      ap.x += ap.vx;
      ap.y += ap.vy;
      ap.life -= dt;
      if (ap.life <= 0 || ap.y < -10 || ap.x < -10 || ap.x > this.screenW + 10) {
        ap.x = Math.random() * this.screenW;
        ap.y = this.screenH + 5;
        ap.life = ap.maxLife;
        ap.alpha = 0.1 + Math.random() * 0.25;
        switch (playerBiome) {
          case BiomeType.CRYSTAL:
            ap.color = Math.random() < 0.5 ? '#00ced150' : '#e0ffff40';
            ap.vx = (Math.random() - 0.5) * 0.5;
            ap.vy = -0.15 - Math.random() * 0.35;
            ap.size = 1 + Math.random() * 2;
            break;
          case BiomeType.MUSHROOM:
            ap.color = Math.random() < 0.5 ? '#ff69b435' : '#da70d640';
            ap.vx = (Math.random() - 0.5) * 0.2;
            ap.vy = -0.05 - Math.random() * 0.15;
            ap.size = 1.5 + Math.random() * 3;
            break;
          case BiomeType.WATER:
            ap.color = Math.random() < 0.5 ? '#1e90ff35' : '#00bfff40';
            ap.vx = (Math.random() - 0.5) * 0.15;
            ap.vy = -0.2 - Math.random() * 0.3;
            ap.size = 1 + Math.random() * 2.5;
            break;
          case BiomeType.LAVA:
            ap.color = Math.random() < 0.5 ? '#ff450045' : '#ff634840';
            ap.vx = (Math.random() - 0.5) * 0.4;
            ap.vy = -0.3 - Math.random() * 0.5;
            ap.size = 1 + Math.random() * 2;
            break;
          case BiomeType.SHADOW:
            ap.color = Math.random() < 0.6 ? '#7c3aed40' : '#4c1d9540';
            ap.vx = (Math.random() - 0.5) * 0.3;
            ap.vy = -0.2 - Math.random() * 0.4;
            ap.size = 1 + Math.random() * 2.5;
            break;
          default:
            const colors: string[] = ['#ffd70033', '#00ced133', '#ff69b433', '#4ade8033', '#60a5fa33'];
            ap.color = colors[Math.floor(Math.random() * colors.length)];
            ap.vx = (Math.random() - 0.5) * 0.3;
            ap.vy = -0.1 - Math.random() * 0.3;
            ap.size = 1 + Math.random() * 2.5;
            break;
        }
      }
    }
  }

  private renderAmbientParticles(c: CanvasRenderingContext2D): void {
    if (!this.settings.effectsEnabled) return;
    for (let i: number = 0; i < this.ambientParticles.length; i++) {
      const ap: AmbientParticle = this.ambientParticles[i];
      const fadeRatio: number = ap.life / ap.maxLife;
      const alpha: number = ap.alpha * (fadeRatio < 0.2 ? fadeRatio / 0.2 : 1.0);
      c.globalAlpha = alpha;
      c.fillStyle = ap.color;
      c.beginPath();
      c.arc(ap.x, ap.y, ap.size, 0, Math.PI * 2);
      c.fill();
    }
    c.globalAlpha = 1.0;
  }

  private renderVignette(c: CanvasRenderingContext2D, p: PlayerState): void {
    const cx: number = this.screenW / 2;
    const cy: number = this.screenH / 2;
    const radius: number = Math.max(this.screenW, this.screenH) * 0.7;

    const hpRatio: number = p.hp / PLAYER_MAX_HP;
    const isLowHP: boolean = hpRatio < 0.3;
    const lowHPIntensity: number = isLowHP ? (1.0 - hpRatio / 0.3) : 0;
    const pulse: number = isLowHP ? 0.5 + 0.5 * Math.sin(this.frameCount * 0.08) : 0;
    const vignetteAlpha: number = 0.45 + lowHPIntensity * pulse * 0.25;

    const gradient: CanvasGradient = c.createRadialGradient(cx, cy, radius * 0.4, cx, cy, radius);
    gradient.addColorStop(0, 'rgba(0,0,0,0)');
    gradient.addColorStop(1, 'rgba(0,0,0,' + vignetteAlpha + ')');
    c.fillStyle = gradient;
    c.fillRect(0, 0, this.screenW, this.screenH);

    if (isLowHP) {
      const redGrad: CanvasGradient = c.createRadialGradient(cx, cy, radius * 0.3, cx, cy, radius);
      redGrad.addColorStop(0, 'rgba(0,0,0,0)');
      redGrad.addColorStop(1, 'rgba(180,0,0,' + (lowHPIntensity * pulse * 0.15) + ')');
      c.fillStyle = redGrad;
      c.fillRect(0, 0, this.screenW, this.screenH);
    }

    if (this.damageFlashTimer > 0) {
      const flashAlpha: number = (this.damageFlashTimer / 200) * 0.35;
      c.fillStyle = 'rgba(255,0,0,' + flashAlpha + ')';
      c.fillRect(0, 0, this.screenW, this.screenH);
    }
  }

  private renderLighting(c: CanvasRenderingContext2D, offX: number, offY: number, p: PlayerState): void {
    if (!this.settings.effectsEnabled) return;

    const camWorldX: number = this.cameraX + this.screenW / 2;
    const camWorldY: number = this.cameraY + this.screenH / 2;
    const viewBiome: BiomeType = this.worldGen.getBiome(camWorldX, camWorldY);
    const depth: number = Math.min(1.0, Math.max(0, this.cameraY / (TILE_SIZE * 30)));
    const isShadow: boolean = viewBiome === BiomeType.SHADOW;
    const isLava: boolean = viewBiome === BiomeType.LAVA;

    const darknessAlpha: number = 0.25 + depth * 0.25 + (isShadow ? 0.15 : 0);
    let darknessR: number = 0;
    let darknessG: number = 0;
    let darknessB: number = 0;
    if (isShadow) {
      darknessR = 10; darknessG = 0; darknessB = 20;
    } else if (isLava) {
      darknessR = 15; darknessG = 5; darknessB = 0;
    }

    c.fillStyle = 'rgba(' + darknessR + ',' + darknessG + ',' + darknessB + ',' + darknessAlpha + ')';
    c.fillRect(0, 0, this.screenW, this.screenH);

    const prevOp: string = c.globalCompositeOperation;
    c.globalCompositeOperation = 'lighter';

    const playerSX: number = p.x + offX;
    const playerSY: number = p.y + offY;
    const playerRadius: number = 160 + Math.sin(this.frameCount * 0.02) * 10;
    const playerGlow: CanvasGradient = c.createRadialGradient(
      playerSX, playerSY, 0, playerSX, playerSY, playerRadius
    );
    playerGlow.addColorStop(0, 'rgba(255,200,100,0.40)');
    playerGlow.addColorStop(0.4, 'rgba(255,180,80,0.18)');
    playerGlow.addColorStop(1, 'rgba(0,0,0,0)');
    c.fillStyle = playerGlow;
    c.fillRect(playerSX - playerRadius, playerSY - playerRadius, playerRadius * 2, playerRadius * 2);

    const startTX: number = Math.floor(this.cameraX / TILE_SIZE) - 1;
    const startTY: number = Math.floor(this.cameraY / TILE_SIZE) - 1;
    const endTX: number = Math.ceil((this.cameraX + this.screenW) / TILE_SIZE) + 1;
    const endTY: number = Math.ceil((this.cameraY + this.screenH) / TILE_SIZE) + 1;

    for (let ty: number = startTY; ty <= endTY; ty++) {
      for (let tx: number = startTX; tx <= endTX; tx++) {
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);
        const sx: number = tx * TILE_SIZE + offX + TILE_SIZE / 2;
        const sy: number = ty * TILE_SIZE + offY + TILE_SIZE / 2;

        if (sx < -80 || sx > this.screenW + 80 || sy < -80 || sy > this.screenH + 80) continue;

        let radius: number = 0;
        let lr: number = 0;
        let lg: number = 0;
        let lb: number = 0;
        let la: number = 0;

        if (tile === TileType.GLOW_STONE) {
          radius = 55; lr = 255; lg = 215; lb = 0; la = 0.25;
        } else if (tile === TileType.CRYSTAL) {
          radius = 48; lr = 0; lg = 206; lb = 209; la = 0.22;
        } else if (tile === TileType.MUSHROOM) {
          radius = 42; lr = 255; lg = 105; lb = 180; la = 0.18;
        } else if (tile === TileType.LAVA) {
          radius = 65; lr = 255; lg = 100; lb = 0; la = 0.28;
        }

        if (radius > 0) {
          const flicker: number = Math.sin(this.frameCount * 0.03 + tx * 0.7 + ty * 1.3) * 4;
          const r: number = radius + flicker;
          const grad: CanvasGradient = c.createRadialGradient(sx, sy, 0, sx, sy, r);
          grad.addColorStop(0, 'rgba(' + lr + ',' + lg + ',' + lb + ',' + la + ')');
          grad.addColorStop(0.6, 'rgba(' + lr + ',' + lg + ',' + lb + ',' + (la * 0.4) + ')');
          grad.addColorStop(1, 'rgba(0,0,0,0)');
          c.fillStyle = grad;
          c.fillRect(sx - r, sy - r, r * 2, r * 2);
        }
      }
    }

    c.globalCompositeOperation = prevOp;
  }

  private renderMinimap(): void {
    if (this.minimapCtx === null || this.player === null) return;
    const mc: CanvasRenderingContext2D = this.minimapCtx;
    const size: number = MINIMAP_SIZE;
    const p: PlayerState = this.player;

    mc.fillStyle = COLOR_MINIMAP_BG;
    mc.fillRect(0, 0, size, size);

    const viewRange: number = 40;
    const playerTX: number = Math.floor(p.x / TILE_SIZE);
    const playerTY: number = Math.floor(p.y / TILE_SIZE);
    const scale: number = size / (viewRange * 2);

    for (let dy: number = -viewRange; dy <= viewRange; dy++) {
      for (let dx: number = -viewRange; dx <= viewRange; dx++) {
        const tx: number = playerTX + dx;
        const ty: number = playerTY + dy;
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);
        const sx: number = (dx + viewRange) * scale;
        const sy: number = (dy + viewRange) * scale;

        if (tile === TileType.WALL) {
          mc.fillStyle = '#2a2a4e';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.GLOW_STONE) {
          mc.fillStyle = '#ffd700';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.CRYSTAL) {
          mc.fillStyle = '#00ced1';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.WATER) {
          mc.fillStyle = '#1a3a5c';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.LAVA) {
          mc.fillStyle = '#8b2500';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        }
      }
    }

    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;
      const sdx: number = (s.x / TILE_SIZE) - playerTX;
      const sdy: number = (s.y / TILE_SIZE) - playerTY;
      if (Math.abs(sdx) > viewRange || Math.abs(sdy) > viewRange) continue;
      const sx: number = (sdx + viewRange) * scale;
      const sy: number = (sdy + viewRange) * scale;
      mc.fillStyle = COLOR_MINIMAP_ENEMY;
      mc.fillRect(sx - 1, sy - 1, 3, 3);
    }

    // Boss dots (larger, distinct color)
    for (let i: number = 0; i < this.bosses.length; i++) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;
      const bdx: number = (boss.x / TILE_SIZE) - playerTX;
      const bdy: number = (boss.y / TILE_SIZE) - playerTY;
      if (Math.abs(bdx) > viewRange || Math.abs(bdy) > viewRange) continue;
      const bsx: number = (bdx + viewRange) * scale;
      const bsy: number = (bdy + viewRange) * scale;
      mc.fillStyle = '#ff0000';
      mc.fillRect(bsx - 3, bsy - 3, 6, 6);
    }

    // Chest dots (yellow/gold)
    for (let i: number = 0; i < this.chests.length; i++) {
      const chest: ChestState = this.chests[i];
      if (!chest.active || chest.opened) continue;
      const cdx: number = (chest.x / TILE_SIZE) - playerTX;
      const cdy: number = (chest.y / TILE_SIZE) - playerTY;
      if (Math.abs(cdx) > viewRange || Math.abs(cdy) > viewRange) continue;
      const csx: number = (cdx + viewRange) * scale;
      const csy: number = (cdy + viewRange) * scale;
      mc.fillStyle = COLOR_CHEST_GLOW;
      mc.fillRect(csx - 2, csy - 2, 4, 4);
    }

    mc.fillStyle = COLOR_MINIMAP_PLAYER;
    mc.fillRect(size / 2 - 2, size / 2 - 2, 5, 5);

    mc.strokeStyle = '#4a5568';
    mc.lineWidth = 1;
    mc.strokeRect(0, 0, size, size);
  }

  // ==================== Boss Rendering ====================

  private renderBosses(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.bosses.length; i++) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;

      const screenX: number = boss.x + offX;
      const screenY: number = boss.y + offY;

      if (screenX < -60 || screenX > this.screenW + 60 || screenY < -60 || screenY > this.screenH + 60) {
        continue;
      }

      const bossColor: string = this.getBossColor(boss.bossType);
      const halfSize: number = boss.size / 2;
      const pulse: number = Math.sin(this.frameCount * 0.05) * 2;

      // Hit flash
      if (boss.hitFlash > 0) {
        c.globalAlpha = 0.5 + 0.5 * Math.sin(boss.hitFlash * 0.05);
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - halfSize - 2, screenY - halfSize - 2, boss.size + 4, boss.size + 4);
      }

      c.globalAlpha = 1.0;

      // Boss body based on type
      if (boss.bossType === BossType.CRYSTAL_GUARDIAN) {
        // Crystal shape - diamond
        c.fillStyle = bossColor;
        c.beginPath();
        c.moveTo(screenX, screenY - halfSize - pulse);
        c.lineTo(screenX + halfSize + pulse, screenY);
        c.lineTo(screenX, screenY + halfSize + pulse);
        c.lineTo(screenX - halfSize - pulse, screenY);
        c.closePath();
        c.fill();
        // Inner glow
        c.fillStyle = '#67e8f9';
        c.globalAlpha = 0.5 + 0.3 * Math.sin(this.frameCount * 0.08);
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.4, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
        // Eyes
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - 6, screenY - 4, 4, 6);
        c.fillRect(screenX + 3, screenY - 4, 4, 6);
      } else if (boss.bossType === BossType.MUSHROOM_KING) {
        // Mushroom cap (dome) + stem
        c.fillStyle = bossColor;
        c.beginPath();
        c.arc(screenX, screenY - 4, halfSize + pulse, Math.PI, 0);
        c.closePath();
        c.fill();
        // Spots on cap
        c.fillStyle = '#ff9ec4';
        c.beginPath();
        c.arc(screenX - 8, screenY - 12, 4, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(screenX + 6, screenY - 16, 3, 0, Math.PI * 2);
        c.fill();
        // Stem
        c.fillStyle = COLOR_MUSHROOM_STEM;
        c.fillRect(screenX - 8, screenY - 4, 16, halfSize);
        // Eyes
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - 5, screenY + 2, 4, 5);
        c.fillRect(screenX + 2, screenY + 2, 4, 5);
      } else if (boss.bossType === BossType.LAVA_BEAST) {
        // Rough rocky body
        c.fillStyle = bossColor;
        c.fillRect(screenX - halfSize, screenY - halfSize, boss.size, boss.size);
        // Lava cracks
        c.strokeStyle = '#ffd700';
        c.lineWidth = 2;
        c.globalAlpha = 0.6 + 0.4 * Math.sin(this.frameCount * 0.1);
        c.beginPath();
        c.moveTo(screenX - 10, screenY - 12);
        c.lineTo(screenX - 2, screenY + 4);
        c.lineTo(screenX + 8, screenY - 6);
        c.moveTo(screenX + 4, screenY + 2);
        c.lineTo(screenX - 6, screenY + 14);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
        // Eyes
        c.fillStyle = '#ffd700';
        c.fillRect(screenX - 7, screenY - 6, 5, 5);
        c.fillRect(screenX + 3, screenY - 6, 5, 5);
      } else if (boss.bossType === BossType.ABYSS_SIREN) {
        // Flowing water form
        c.fillStyle = bossColor;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + pulse, 0, Math.PI * 2);
        c.fill();
        // Water tendrils
        c.strokeStyle = COLOR_WATER_LIGHT;
        c.lineWidth = 3;
        c.globalAlpha = 0.6;
        for (let t: number = 0; t < 4; t++) {
          const angle: number = (t / 4) * Math.PI * 2 + this.frameCount * 0.03;
          const ex: number = screenX + Math.cos(angle) * (halfSize + 10);
          const ey: number = screenY + Math.sin(angle) * (halfSize + 10);
          c.beginPath();
          c.moveTo(screenX + Math.cos(angle) * halfSize * 0.5, screenY + Math.sin(angle) * halfSize * 0.5);
          c.quadraticCurveTo(
            screenX + Math.cos(angle + 0.5) * halfSize,
            screenY + Math.sin(angle + 0.5) * halfSize,
            ex, ey
          );
          c.stroke();
        }
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
        // Eyes
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(screenX - 6, screenY - 3, 4, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(screenX + 6, screenY - 3, 4, 0, Math.PI * 2);
        c.fill();
      } else if (boss.bossType === BossType.VOID_RIFT) {
        // Void portal - swirling dark mass
        c.fillStyle = bossColor;
        c.globalAlpha = 0.8;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + pulse + 4, 0, Math.PI * 2);
        c.fill();
        // Inner void
        c.fillStyle = '#0d0d1a';
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.5, 0, Math.PI * 2);
        c.fill();
        // Swirl effect
        c.strokeStyle = '#a855f7';
        c.lineWidth = 2;
        c.globalAlpha = 0.5;
        const spin: number = this.frameCount * 0.04;
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.7, spin, spin + Math.PI * 1.2);
        c.stroke();
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.9, spin + Math.PI, spin + Math.PI * 2.2);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
      }

      // Phase 2 indicator - pulsing aura
      if (boss.phase === BossPhase.PHASE_2) {
        c.strokeStyle = bossColor;
        c.lineWidth = 2;
        c.globalAlpha = 0.3 + 0.2 * Math.sin(this.frameCount * 0.1);
        c.beginPath();
        c.arc(screenX, screenY, halfSize + 8 + pulse, 0, Math.PI * 2);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderMaterialDrops(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.materialDrops.length; i++) {
      const drop: MaterialDrop = this.materialDrops[i];
      if (!drop.active) continue;

      const screenX: number = drop.x + offX;
      const screenY: number = drop.y + offY;

      if (screenX < -20 || screenX > this.screenW + 20 || screenY < -20 || screenY > this.screenH + 20) {
        continue;
      }

      const bob: number = Math.sin(this.frameCount * 0.06 + drop.bobPhase) * 3;
      const drawY: number = screenY + bob;

      let color: string = '#ffffff';
      if (drop.type === MaterialType.CRYSTAL_ORE) color = COLOR_CRYSTAL;
      else if (drop.type === MaterialType.MUSHROOM_ORE) color = COLOR_MUSHROOM_CAP;
      else if (drop.type === MaterialType.FLAME_ORE) color = COLOR_LAVA_LIGHT;
      else if (drop.type === MaterialType.ABYSS_ORE) color = COLOR_BOSS_ABYSS;
      else if (drop.type === MaterialType.VOID_ORE) color = COLOR_BOSS_VOID;
      else if (drop.type === MaterialType.CORE_NORMAL) color = '#c0c0c0';
      else if (drop.type === MaterialType.CORE_RARE) color = '#ffd700';
      else if (drop.type === MaterialType.FORM_CORE) color = '#e879f9';

      // Glow
      c.globalAlpha = 0.3;
      c.fillStyle = color;
      c.beginPath();
      c.arc(screenX, drawY, 8, 0, Math.PI * 2);
      c.fill();

      // Item
      c.globalAlpha = 1.0;
      c.fillStyle = color;
      c.fillRect(screenX - 4, drawY - 4, 8, 8);
      c.strokeStyle = '#ffffff';
      c.lineWidth = 1;
      c.strokeRect(screenX - 4, drawY - 4, 8, 8);
    }
    c.globalAlpha = 1.0;
  }

  private renderBossHPBar(c: CanvasRenderingContext2D): void {
    // Show HP bar for active boss
    const boss: BossState | null = this.activeBoss;
    if (boss === null || boss.defeated) {
      // Also check for any active optional boss
      for (let i: number = 0; i < this.bosses.length; i++) {
        if (this.bosses[i].active && !this.bosses[i].defeated) {
          this.drawBossHPBar(c, this.bosses[i]);
          return;
        }
      }
      return;
    }
    this.drawBossHPBar(c, boss);
  }

  private drawBossHPBar(c: CanvasRenderingContext2D, boss: BossState): void {
    const barW: number = 200;
    const barH: number = 12;
    const barX: number = (this.screenW - barW) / 2;
    const barY: number = 20;
    const hpRatio: number = Math.max(0, boss.hp / boss.maxHp);

    // Background
    c.fillStyle = COLOR_BOSS_HP_BG;
    c.globalAlpha = 0.8;
    c.fillRect(barX - 2, barY - 2, barW + 4, barH + 4);

    // HP bar
    c.fillStyle = COLOR_BOSS_HP_BAR;
    c.globalAlpha = 1.0;
    c.fillRect(barX, barY, barW * hpRatio, barH);

    // Border
    c.strokeStyle = '#ffffff';
    c.lineWidth = 1;
    c.globalAlpha = 0.5;
    c.strokeRect(barX - 2, barY - 2, barW + 4, barH + 4);

    // Boss name
    c.globalAlpha = 1.0;
    c.fillStyle = '#ffffff';
    c.font = '10px sans-serif';
    c.textAlign = 'center';
    let name: string = 'Boss';
    if (boss.bossType === BossType.CRYSTAL_GUARDIAN) name = 'Crystal Guardian';
    else if (boss.bossType === BossType.MUSHROOM_KING) name = 'Mushroom King';
    else if (boss.bossType === BossType.LAVA_BEAST) name = 'Lava Beast';
    else if (boss.bossType === BossType.ABYSS_SIREN) name = 'Abyss Siren';
    else if (boss.bossType === BossType.VOID_RIFT) name = 'Void Rift';
    if (boss.phase === BossPhase.PHASE_2) name += ' [Enraged]';
    c.fillText(name, this.screenW / 2, barY - 6);
  }

  // ==================== Chest System ====================

  private updateChestAnims(dt: number): void {
    for (let i: number = 0; i < this.chests.length; i++) {
      const chest: ChestState = this.chests[i];
      if (chest.openAnim > 0) {
        chest.openAnim -= dt;
        if (chest.openAnim < 0) chest.openAnim = 0;
      }
    }
  }

  private renderChests(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.chests.length; i++) {
      const chest: ChestState = this.chests[i];
      if (!chest.active) continue;
      const sx: number = chest.x - offX;
      const sy: number = chest.y - offY;
      if (sx < -30 || sx > this.screenW + 30 || sy < -30 || sy > this.screenH + 30) continue;

      const halfSize: number = CHEST_SIZE / 2;

      // Glow effect
      if (this.settings.effectsEnabled) {
        c.globalAlpha = 0.3 + Math.sin(this.frameCount * 0.05) * 0.1;
        c.fillStyle = COLOR_CHEST_GLOW;
        c.beginPath();
        c.arc(sx, sy, halfSize + 6, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      if (chest.chestType === ChestType.NORMAL) {
        // Brown wooden box
        c.fillStyle = COLOR_CHEST_NORMAL;
        c.fillRect(sx - halfSize, sy - halfSize, CHEST_SIZE, CHEST_SIZE);
        // Lid line
        c.fillStyle = '#6b4f10';
        c.fillRect(sx - halfSize, sy - 1, CHEST_SIZE, 2);
        // Lock
        c.fillStyle = '#c0a030';
        c.fillRect(sx - 1, sy - 3, 3, 3);
      } else if (chest.chestType === ChestType.ELITE) {
        // Gray iron box
        c.fillStyle = COLOR_CHEST_ELITE;
        c.fillRect(sx - halfSize - 1, sy - halfSize - 1, CHEST_SIZE + 2, CHEST_SIZE + 2);
        // Rune cross-hatch
        c.strokeStyle = '#a0b0c0';
        c.lineWidth = 1;
        c.globalAlpha = 0.6;
        c.beginPath();
        c.moveTo(sx - halfSize, sy - halfSize);
        c.lineTo(sx + halfSize, sy + halfSize);
        c.moveTo(sx + halfSize, sy - halfSize);
        c.lineTo(sx - halfSize, sy + halfSize);
        c.stroke();
        c.globalAlpha = 1.0;
        // Lock indicator
        if (!chest.guardianDefeated) {
          c.fillStyle = '#ff3333';
          c.fillRect(sx - 2, sy - 2, 4, 4);
        } else {
          c.fillStyle = '#33ff33';
          c.fillRect(sx - 2, sy - 2, 4, 4);
        }
      } else if (chest.chestType === ChestType.BOSS) {
        // Golden ornate box
        c.fillStyle = COLOR_CHEST_BOSS;
        c.fillRect(sx - halfSize - 2, sy - halfSize - 2, CHEST_SIZE + 4, CHEST_SIZE + 4);
        // Inner border
        c.strokeStyle = '#ffaa00';
        c.lineWidth = 2;
        c.strokeRect(sx - halfSize, sy - halfSize, CHEST_SIZE, CHEST_SIZE);
        // Star decoration
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.8;
        c.fillRect(sx - 1, sy - halfSize + 1, 2, 2);
        c.fillRect(sx - 1, sy + halfSize - 3, 2, 2);
        c.fillRect(sx - halfSize + 1, sy - 1, 2, 2);
        c.fillRect(sx + halfSize - 3, sy - 1, 2, 2);
        c.globalAlpha = 1.0;
      }

      // Open animation (lid lifting)
      if (chest.opened && chest.openAnim > 0) {
        c.fillStyle = chest.chestType === ChestType.BOSS ? COLOR_CHEST_BOSS :
          (chest.chestType === ChestType.ELITE ? COLOR_CHEST_ELITE : COLOR_CHEST_NORMAL);
        const lift: number = Math.min(chest.openAnim / 200, 1) * 6;
        c.fillRect(sx - halfSize, sy - halfSize - lift - 3, CHEST_SIZE, 3);
      }
    }
  }

  private checkChestInteraction(): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = 0; i < this.chests.length; i++) {
      const chest: ChestState = this.chests[i];
      if (!chest.active || chest.opened) continue;

      const dx: number = chest.x - p.x;
      const dy: number = chest.y - p.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < CHEST_INTERACT_RANGE) {
        // Boss chest: auto-open on spawn (already handled by boss death)
        // Elite chest: only if guardian defeated
        if (chest.chestType === ChestType.ELITE && !chest.guardianDefeated) continue;
        this.openChest(chest);
      }
    }
  }

  private openChest(chest: ChestState): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    chest.opened = true;
    chest.openAnim = 500;

    // Spawn light pillar particles
    if (this.settings.effectsEnabled) {
      this.particleMgr.magic(chest.x, chest.y, COLOR_CHEST_GLOW);
    }

    // Generate loot based on chest type
    if (chest.chestType === ChestType.NORMAL) {
      // Normal: 1-2 core_normal, 1-2 hp potions, small gold
      const coreCount: number = 1 + Math.floor(Math.random() * 2);
      const potionCount: number = 1 + Math.floor(Math.random() * 2);
      const goldCount: number = 5 + Math.floor(Math.random() * 10);
      p.inventory.coreNormal += coreCount;
      p.inventory.hpPotions += potionCount;
      p.inventory.gold += goldCount;
      this.spawnLootText(chest.x, chest.y, '+' + coreCount + ' Core');
    } else if (chest.chestType === ChestType.ELITE) {
      // Elite: 1 core_rare, 1 form_core, 2-3 hp potions
      const potionCount: number = 2 + Math.floor(Math.random() * 2);
      p.inventory.coreRare += 1;
      p.inventory.formCore += 1;
      p.inventory.hpPotions += potionCount;
      p.inventory.gold += 20;
      this.spawnLootText(chest.x, chest.y, '+Rare Core +Form Core');
    } else if (chest.chestType === ChestType.BOSS) {
      // Boss: 2-3 boss ore, 1-2 core_rare, chance form_core
      const oreCount: number = 2 + Math.floor(Math.random() * 2);
      const rareCount: number = 1 + Math.floor(Math.random() * 2);
      // Add boss-specific ore based on nearest boss type
      this.addBossOre(p, oreCount);
      p.inventory.coreRare += rareCount;
      if (Math.random() < 0.5) {
        p.inventory.formCore += 1;
      }
      p.inventory.gold += 50;
      this.spawnLootText(chest.x, chest.y, '+Boss Loot!');
    }

    this.autoSave();
  }

  private addBossOre(p: PlayerState, count: number): void {
    // Determine which boss ore to add based on player's current biome
    const biome: BiomeType = this.worldGen.getBiome(p.x, p.y);
    if (biome === BiomeType.CRYSTAL) {
      p.inventory.crystalOre += count;
    } else if (biome === BiomeType.MUSHROOM) {
      p.inventory.mushroomOre += count;
    } else if (biome === BiomeType.LAVA) {
      p.inventory.flameOre += count;
    } else if (biome === BiomeType.WATER) {
      p.inventory.abyssOre += count;
    } else if (biome === BiomeType.SHADOW) {
      p.inventory.voidOre += count;
    } else {
      // Default to crystal ore if in normal biome
      p.inventory.crystalOre += count;
    }
  }

  private spawnLootText(x: number, y: number, text: string): void {
    // Spawn floating text particle to show loot pickup
    if (this.settings.effectsEnabled) {
      this.particleMgr.sparks(x, y - 10, '#ffd700', 5);
    }
  }

  // ==================== Evolution System ====================

  private getBranchOreType(branch: EvolutionBranch): MaterialType {
    if (branch === EvolutionBranch.CRYSTAL) return MaterialType.CRYSTAL_ORE;
    if (branch === EvolutionBranch.FLAME) return MaterialType.FLAME_ORE;
    if (branch === EvolutionBranch.SHADOW) return MaterialType.VOID_ORE;
    if (branch === EvolutionBranch.TOXIN) return MaterialType.MUSHROOM_ORE;
    if (branch === EvolutionBranch.TIDE) return MaterialType.ABYSS_ORE;
    return MaterialType.CRYSTAL_ORE;
  }

  private getOreCount(inventory: Inventory, branch: EvolutionBranch): number {
    const oreType: MaterialType = this.getBranchOreType(branch);
    if (oreType === MaterialType.CRYSTAL_ORE) return inventory.crystalOre;
    if (oreType === MaterialType.FLAME_ORE) return inventory.flameOre;
    if (oreType === MaterialType.VOID_ORE) return inventory.voidOre;
    if (oreType === MaterialType.MUSHROOM_ORE) return inventory.mushroomOre;
    if (oreType === MaterialType.ABYSS_ORE) return inventory.abyssOre;
    return 0;
  }

  private deductOre(inventory: Inventory, branch: EvolutionBranch, count: number): void {
    const oreType: MaterialType = this.getBranchOreType(branch);
    if (oreType === MaterialType.CRYSTAL_ORE) inventory.crystalOre -= count;
    else if (oreType === MaterialType.FLAME_ORE) inventory.flameOre -= count;
    else if (oreType === MaterialType.VOID_ORE) inventory.voidOre -= count;
    else if (oreType === MaterialType.MUSHROOM_ORE) inventory.mushroomOre -= count;
    else if (oreType === MaterialType.ABYSS_ORE) inventory.abyssOre -= count;
  }

  canEvolve(): boolean {
    if (this.player === null) return false;
    const p: PlayerState = this.player;
    const level: number = p.evolutionLevel;
    if (level >= EvolutionLevel.LEVEL_3) return false;
    const nextLevel: number = level + 1;
    const branch: EvolutionBranch = p.evolutionBranch;
    const oreNeeded: number = EVOLUTION_COST_ORE[nextLevel];
    const normalNeeded: number = EVOLUTION_COST_NORMAL[nextLevel];
    const rareNeeded: number = EVOLUTION_COST_RARE[nextLevel];
    if (this.getOreCount(p.inventory, branch) < oreNeeded) return false;
    if (p.inventory.coreNormal < normalNeeded) return false;
    if (p.inventory.coreRare < rareNeeded) return false;
    return true;
  }

  tryEvolveWeapon(): boolean {
    if (!this.canEvolve()) return false;
    const p: PlayerState = this.player!;
    const nextLevel: number = p.evolutionLevel + 1;
    const branch: EvolutionBranch = p.evolutionBranch;
    const oreNeeded: number = EVOLUTION_COST_ORE[nextLevel];
    const normalNeeded: number = EVOLUTION_COST_NORMAL[nextLevel];
    const rareNeeded: number = EVOLUTION_COST_RARE[nextLevel];

    this.deductOre(p.inventory, branch, oreNeeded);
    p.inventory.coreNormal -= normalNeeded;
    p.inventory.coreRare -= rareNeeded;
    p.evolutionLevel = nextLevel as EvolutionLevel;

    // Evolution particle effect
    if (this.settings.effectsEnabled) {
      this.particleMgr.explosion(p.x, p.y, this.getBranchColor(branch), 20);
      this.particleMgr.magic(p.x, p.y, '#ffffff');
    }
    this.shakeTimer = 300;
    return true;
  }

  unlockWeaponForm(form: WeaponForm): boolean {
    if (this.player === null) return false;
    const p: PlayerState = this.player;
    if (p.unlockedForms.indexOf(form) >= 0) return false;
    if (p.inventory.formCore < FORM_UNLOCK_COST) return false;
    p.inventory.formCore -= FORM_UNLOCK_COST;
    p.unlockedForms.push(form);
    return true;
  }

  private getBranchColor(branch: EvolutionBranch): string {
    if (branch === EvolutionBranch.CRYSTAL) return '#00ced1';
    if (branch === EvolutionBranch.FLAME) return '#ff4500';
    if (branch === EvolutionBranch.SHADOW) return '#6b21a8';
    if (branch === EvolutionBranch.TOXIN) return '#32cd32';
    if (branch === EvolutionBranch.TIDE) return '#4169e1';
    return '#ffffff';
  }

  getEvolutionInfo(): string[] {
    if (this.player === null) return ['No player'];
    const p: PlayerState = this.player;
    const branchNames: string[] = ['Crystal', 'Flame', 'Shadow', 'Toxin', 'Tide'];
    const branch: string = branchNames[p.evolutionBranch] || 'Unknown';
    const level: number = p.evolutionLevel;
    const info: string[] = [];
    info.push('Branch: ' + branch);
    info.push('Level: ' + level + '/3');
    if (level < 3) {
      const next: number = level + 1;
      const oreNeeded: number = EVOLUTION_COST_ORE[next];
      const normalNeeded: number = EVOLUTION_COST_NORMAL[next];
      const rareNeeded: number = EVOLUTION_COST_RARE[next];
      const oreHave: number = this.getOreCount(p.inventory, p.evolutionBranch);
      info.push('Ore: ' + oreHave + '/' + oreNeeded);
      info.push('Core: ' + p.inventory.coreNormal + '/' + normalNeeded);
      info.push('Rare: ' + p.inventory.coreRare + '/' + rareNeeded);
    } else {
      info.push('MAX LEVEL');
    }
    return info;
  }

  getEvoBranch(): number {
    if (this.player === null) return 0;
    return this.player.evolutionBranch as number;
  }

  getEvoLevel(): number {
    if (this.player === null) return 0;
    return this.player.evolutionLevel as number;
  }

  getEvoOreHave(): number {
    if (this.player === null) return 0;
    return this.getOreCount(this.player.inventory, this.player.evolutionBranch);
  }

  getEvoOreNeed(): number {
    if (this.player === null) return 0;
    const level = this.player.evolutionLevel;
    if (level >= EvolutionLevel.LEVEL_3) return 0;
    return EVOLUTION_COST_ORE[level + 1];
  }

  getEvoNormalHave(): number {
    if (this.player === null) return 0;
    return this.player.inventory.coreNormal;
  }

  getEvoNormalNeed(): number {
    if (this.player === null) return 0;
    const level = this.player.evolutionLevel;
    if (level >= EvolutionLevel.LEVEL_3) return 0;
    return EVOLUTION_COST_NORMAL[level + 1];
  }

  getEvoRareHave(): number {
    if (this.player === null) return 0;
    return this.player.inventory.coreRare;
  }

  getEvoRareNeed(): number {
    if (this.player === null) return 0;
    const level = this.player.evolutionLevel;
    if (level >= EvolutionLevel.LEVEL_3) return 0;
    return EVOLUTION_COST_RARE[level + 1];
  }

  getEvoFormCore(): number {
    if (this.player === null) return 0;
    return this.player.inventory.formCore;
  }

  getUnlockedForms(): number[] {
    if (this.player === null) return [0];
    return this.player.unlockedForms.slice();
  }

  // === Transform Form Movement & Combat Methods ===

  private updateTransformMovement(p: PlayerState, dt: number, moveX: number, moveY: number): void {
    this.transformSystem!.updateMovement(p, dt, moveX, moveY);
  }

  private applyTransformCollision(p: PlayerState): void {
    this.transformSystem!.applyCollision(p);
  }

  private handleTransformAttack(p: PlayerState): void {
    this.transformSystem!.handleAttack(p);
  }

  private renderSlimeForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const size: number = 18; // Larger than normal slimes
    const squash: number = p.isJumping ? 0.8 : 1.0 + Math.sin(this.frameCount * 0.1) * 0.05;
    const stretch: number = p.isJumping ? 1.3 : 1.0 - Math.sin(this.frameCount * 0.1) * 0.05;

    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY);
    c.scale(squash, stretch);

    // Body
    c.fillStyle = COLOR_TRANSFORM_SLIME;
    c.beginPath();
    c.ellipse(0, 2, size / 2, size / 2.2, 0, 0, Math.PI * 2);
    c.fill();

    // Highlight
    c.fillStyle = COLOR_TRANSFORM_SLIME_DARK;
    c.beginPath();
    c.ellipse(0, 4, size / 2.5, size / 3, 0, 0, Math.PI * 2);
    c.fill();

    // Eyes
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(-4, -2, 3, 4, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(4, -2, 3, 4, 0, 0, Math.PI * 2);
    c.fill();

    // Pupils (face facing direction)
    const pupilOffX: number = Math.cos(p.facing) * 1.5;
    const pupilOffY: number = Math.sin(p.facing) * 1.5;
    c.fillStyle = '#1a1a2e';
    c.beginPath();
    c.arc(-4 + pupilOffX, -2 + pupilOffY, 1.5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4 + pupilOffX, -2 + pupilOffY, 1.5, 0, Math.PI * 2);
    c.fill();

    c.restore();
  }

  private renderGhostForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    c.save();
    c.globalAlpha = 0.5 + Math.sin(this.frameCount * 0.06) * 0.15;
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY - 3);

    // Ghost body (flowing shape)
    c.fillStyle = COLOR_TRANSFORM_GHOST;
    c.beginPath();
    c.arc(0, -4, 8, Math.PI, 0);
    c.lineTo(8, 6);
    // Wavy bottom
    for (let i: number = 0; i < 4; i++) {
      const wx: number = 8 - i * 4;
      const wy: number = 6 + (i % 2 === 0 ? 4 : 0);
      c.lineTo(wx, wy);
    }
    c.closePath();
    c.fill();

    // Dark overlay
    c.fillStyle = COLOR_TRANSFORM_GHOST_DARK;
    c.beginPath();
    c.arc(0, -2, 5, 0, Math.PI * 2);
    c.fill();

    // Eyes (glowing)
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(-3, -4, 2, 3, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(3, -4, 2, 3, 0, 0, Math.PI * 2);
    c.fill();

    c.restore();
  }

  private renderArmorForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const scale: number = 1.3;
    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY);
    c.scale(scale, scale);

    // Body (metallic)
    c.fillStyle = COLOR_TRANSFORM_ARMOR;
    c.fillRect(-6, -4, 12, 14);

    // Chest accent
    c.fillStyle = COLOR_TRANSFORM_ARMOR_ACCENT;
    c.fillRect(-4, -2, 8, 3);

    // Helmet
    c.fillStyle = '#64748b';
    c.fillRect(-5, -9, 10, 6);

    // Visor
    c.fillStyle = COLOR_TRANSFORM_ARMOR_ACCENT;
    const visorGlow: number = 0.6 + Math.sin(this.frameCount * 0.08) * 0.3;
    c.globalAlpha = visorGlow;
    c.fillRect(-4, -7, 8, 2);
    c.globalAlpha = 1.0;

    // Fists
    c.fillStyle = COLOR_TRANSFORM_ARMOR;
    c.fillRect(-8, 2, 3, 4);
    c.fillRect(5, 2, 3, 4);

    // Legs
    c.fillStyle = '#475569';
    c.fillRect(-4, 10, 3, 4);
    c.fillRect(1, 10, 3, 4);

    c.restore();
  }

  private renderIronManForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY - 2);

    // Body (red-gold armor)
    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-6, -4, 12, 14);

    // Gold accents
    c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
    c.fillRect(-5, 0, 10, 3);

    // Head/faceplate
    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-5, -9, 10, 6);
    c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
    c.fillRect(-4, -7, 8, 3);

    // Eyes (glowing white)
    c.fillStyle = '#ffffff';
    c.fillRect(-3, -7, 2, 1);
    c.fillRect(1, -7, 2, 1);

    // Arc reactor (chest)
    const reactorGlow: number = 0.7 + Math.sin(this.frameCount * 0.1) * 0.3;
    c.fillStyle = '#67e8f9';
    c.globalAlpha = reactorGlow;
    c.beginPath();
    c.arc(0, 2, 2.5, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    // Repulsor hands (glow when attacking)
    if (p.isAttacking) {
      c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
      c.globalAlpha = 0.9;
      c.beginPath();
      c.arc(-8, 3, 3, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(8, 3, 3, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Boots
    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-5, 10, 4, 4);
    c.fillRect(1, 10, 4, 4);

    c.restore();
  }

  private renderTransformAnim(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState): void {
    const maxDuration: number = this.transformAnimIsRevert ? TRANSFORM_REVERT_ANIM : TRANSFORM_ACTIVATE_ANIM;
    const progress: number = 1 - (p.transformAnimTimer / maxDuration);
    const cx: number = sx + PLAYER_SIZE / 2;
    const cy: number = sy + PLAYER_SIZE / 2;

    // Expanding flash ring
    c.save();
    c.globalAlpha = 1 - progress;
    c.strokeStyle = COLOR_TRANSFORM_FLASH;
    c.lineWidth = 3 - progress * 2;
    c.beginPath();
    c.arc(cx, cy, progress * 30, 0, Math.PI * 2);
    c.stroke();

    // Scale effect
    const scale: number = 0.5 + progress * 0.7;
    c.globalAlpha = Math.min(1, progress * 2);
    c.fillStyle = this.getTransformColor(p.transformForm);
    c.beginPath();
    c.arc(cx, cy, 8 * scale, 0, Math.PI * 2);
    c.fill();
    c.restore();
  }

  // ==================== State Machine ====================

  getPlayer(): PlayerState | null {
    return this.player;
  }

  getState(): GameState {
    return this.state;
  }

  setOnStateChange(cb: (state: GameState) => void): void {
    this.onStateChange = cb;
  }

  setOnSave(cb: () => void): void {
    this.onSave = cb;
  }

  private setState(newState: GameState): void {
    this.state = newState;
    if (this.onStateChange) {
      this.onStateChange(newState);
    }
  }

  pause(): void {
    if (this.state !== GameState.PLAYING) return;
    this.autoSave();
    this.setState(GameState.PAUSED);
    if (this.gameLoopId !== -1) {
      clearInterval(this.gameLoopId);
      this.gameLoopId = -1;
    }
  }

  resume(): void {
    if (this.state !== GameState.PAUSED) return;
    this.setState(GameState.PLAYING);
    this.startLoop();
  }

  quit(): void {
    this.autoSave();
    if (this.gameLoopId !== -1) {
      clearInterval(this.gameLoopId);
      this.gameLoopId = -1;
    }
    this.setState(GameState.LOADING);
  }

  restart(): void {
    if (this.gameLoopId !== -1) {
      clearInterval(this.gameLoopId);
      this.gameLoopId = -1;
    }
    this.chunks.clear();
    this.enemies = [];
    this.xpOrbs = [];
    this.particles = [];
    this.bosses = [];
    this.activeBoss = null;
    this.bossRoomLocked = false;
    this.materialDrops = [];
    this.bossRooms = [];
    this.chests = [];
    this.traps = [];
    this.mechanisms = [];
    this.secretRooms = [];
    this.transformCoreDrops = [];
    this.particleMgr.clear();
    this.activeChunkCaches.clear();
    this.cacheEntryPool = new Array(this.cacheCtxs.length).fill(null);
    this.freePoolIndices = [];
    for (let i: number = 0; i < this.cacheCtxs.length; i++) {
      this.freePoolIndices.push(i);
    }
    this.frameCount = 0;
    this.setState(GameState.PLAYING);
    if (this.ctx && this.minimapCtx) {
      this.init(this.ctx, this.minimapCtx, this.screenW, this.screenH, this.cacheCtxs, this.context);
    }
  }

  // ==================== Save/Load ====================

  getSaveData(): SaveData {
    const p: PlayerState = this.player!;
    return {
      version: SAVE_VERSION,
      timestamp: Date.now(),
      playerX: p.x,
      playerY: p.y,
      hp: p.hp,
      xp: p.xp,
      level: p.level,
      gender: p.gender,
      currentWeaponForm: p.currentWeaponForm,
      unlockedForms: p.unlockedForms.slice(),
      evolutionBranch: p.evolutionBranch,
      evolutionLevel: p.evolutionLevel,
      inventory: {
        crystalOre: p.inventory.crystalOre,
        mushroomOre: p.inventory.mushroomOre,
        flameOre: p.inventory.flameOre,
        abyssOre: p.inventory.abyssOre,
        voidOre: p.inventory.voidOre,
        coreNormal: p.inventory.coreNormal,
        coreRare: p.inventory.coreRare,
        formCore: p.inventory.formCore,
        hpPotions: p.inventory.hpPotions,
        gold: p.inventory.gold,
        transformCoreSlime: p.inventory.transformCoreSlime,
        transformCoreArmor: p.inventory.transformCoreArmor,
        transformCoreIronMan: p.inventory.transformCoreIronMan,
        transformCoreGhost: p.inventory.transformCoreGhost
      },
      isTransformed: p.isTransformed,
      transformForm: p.transformForm,
      transformEnergy: p.transformEnergy,
      transformMaxEnergy: p.transformMaxEnergy,
      unlockedTransforms: p.unlockedTransforms.slice(),
      exploredChunks: this.getExploredChunks()
    };
  }

  applySaveData(data: SaveData): void {
    if (!this.player) return;
    const p: PlayerState = this.player;
    p.x = data.playerX;
    p.y = data.playerY;
    p.hp = data.hp;
    p.xp = data.xp;
    p.level = data.level;
    p.gender = data.gender;
    p.currentWeaponForm = data.currentWeaponForm;
    p.unlockedForms = data.unlockedForms.slice();
    p.evolutionBranch = data.evolutionBranch;
    p.evolutionLevel = data.evolutionLevel;
    p.inventory = {
      crystalOre: data.inventory.crystalOre,
      mushroomOre: data.inventory.mushroomOre,
      flameOre: data.inventory.flameOre,
      abyssOre: data.inventory.abyssOre,
      voidOre: data.inventory.voidOre,
      coreNormal: data.inventory.coreNormal,
      coreRare: data.inventory.coreRare,
      formCore: data.inventory.formCore,
      hpPotions: data.inventory.hpPotions,
      gold: data.inventory.gold,
      transformCoreSlime: data.inventory.transformCoreSlime,
      transformCoreArmor: data.inventory.transformCoreArmor,
      transformCoreIronMan: data.inventory.transformCoreIronMan,
      transformCoreGhost: data.inventory.transformCoreGhost
    };
    p.isTransformed = data.isTransformed;
    p.transformForm = data.transformForm;
    p.transformEnergy = data.transformEnergy;
    p.transformMaxEnergy = data.transformMaxEnergy;
    p.unlockedTransforms = data.unlockedTransforms.slice();
    p.vx = 0;
    p.vy = 0;
    p.isAttacking = false;
    p.isDashing = false;
    p.isJumping = false;
    p.isDrilling = false;
    p.isEngulfed = false;
    p.invincibleTimer = 1000;

    this.cameraX = p.x - this.screenW / 2;
    this.cameraY = p.y - this.screenH / 2;

    this.chunks.clear();
    this.enemies = [];
    this.xpOrbs = [];
    this.bosses = [];
    this.chests = [];
    this.traps = [];
    this.mechanisms = [];
    this.materialDrops = [];
    this.particles = [];
    this.particleMgr.clear();
    this.activeChunkCaches.clear();
    this.cacheEntryPool = new Array(this.cacheCtxs.length).fill(null);
    this.freePoolIndices = [];
    for (let i: number = 0; i < this.cacheCtxs.length; i++) {
      this.freePoolIndices.push(i);
    }

    const ptx: number = Math.floor(p.x / TILE_SIZE);
    const pty: number = Math.floor(p.y / TILE_SIZE);
    this.loadChunksAround(ptx, pty);
  }

  getExploredChunks(): string[] {
    const keys: string[] = [];
    this.chunks.forEach((_: ChunkData, key: string) => {
      keys.push(key);
    });
    return keys;
  }

  private async autoSave(): Promise<void> {
    if (!this.context || !this.player) return;
    try {
      const { SaveManager } = await import('./SaveManager');
      const data: SaveData = this.getSaveData();
      await SaveManager.save(this.context as any, data);
      if (this.onSave) {
        this.onSave();
      }
    } catch (e) {
      console.error('autoSave failed: ' + JSON.stringify(e));
    }
  }

  private handlePlayerDeath(): void {
    if (!this.player) return;
    const p: PlayerState = this.player;
    p.hp = 0;

    if (this.settings.effectsEnabled) {
      this.particleMgr.explosion(p.x, p.y, '#ef4444', 20);
      this.particleMgr.sparks(p.x, p.y, '#fbbf24', 12);
    }
    this.shakeTimer = 500;
    this.audio.playPlayerDamage();

    this.autoSave();
    this.setState(GameState.GAME_OVER);
  }
}
