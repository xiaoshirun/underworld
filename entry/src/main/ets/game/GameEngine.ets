import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE, PLAYER_SPEED,
  DASH_SPEED, DASH_DURATION, DASH_COOLDOWN, ATTACK_DURATION, ATTACK_COOLDOWN,
  ATTACK_RANGE, ATTACK_WIDTH, PLAYER_MAX_HP, INVINCIBLE_DURATION,
  SLIME_SIZE, SLIME_SPEED, PURPLE_SLIME_SPEED, PURPLE_SLIME_DETECT,
  RED_SLIME_SPEED, RED_SLIME_DETECT, BLUE_SLIME_SPEED,
  SLIME_DAMAGE, SLIME_KNOCKBACK,
  ENGULF_DAMAGE_INTERVAL, ENGULF_ESCAPE_ATTACKS, DRILL_BREAK_HITS,
  XP_ORB_SIZE, XP_COLLECT_RANGE, XP_MAGNET_RANGE, LEVEL_UP_XP,
  MATERIAL_MAGNET_RANGE, MATERIAL_COLLECT_RANGE, MATERIAL_FLY_SPEED,
  CHUNK_LOAD_RADIUS,
  MINIMAP_SIZE, FRAME_INTERVAL, MINIMAP_UPDATE_INTERVAL, MAX_PARTICLES, MAX_DYN_TILE_CACHE,
  TileType, EnemyType, BiomeType, PlayerState, SlimeState, XpOrb, Particle,
  ChunkData, InputState, GameSettings, AmbientParticle, DynTileCacheEntry,
  GenderType, WeaponForm, EvolutionBranch, EvolutionLevel, SaveData,
  BossState, ChestState, ChestType, BossRoom, MaterialDrop, FloatingText, TrapInstance, MechanismInstance,
  Inventory, TrapType, TrapState,
  TransformCoreDrop, TransformUnlockNotify,
  MechanismType, SecretRoom,
  BossType, BossRole, BossPhase, MaterialType,
  BOSS_HP, BOSS_SIZE, BOSS_ATTACK_INTERVAL, BOSS_PHASE2_THRESHOLD,
  BOSS_RESPAWN_TIME, BOSS_ROOM_SIZE,
  PASSAGE_GUARDIAN_AGGRO, OPTIONAL_CHALLENGE_AGGRO,
  WEAPON_FORM_STATS, WEAPON_FORM_DAMAGE, EVOLUTION_DAMAGE_BONUS,
  WEAPON_SHAKE, WEAPON_HITSTOP,
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
} from './GameConstants';
import { WorldGenerator } from './WorldGenerator';
import { AudioManager } from './AudioManager';
import { DeviceProfile } from './DeviceProfile';
import { ResourceManager } from './ResourceManager';

export class GameEngine {
  private ctx: CanvasRenderingContext2D | null = null;
  private minimapCtx: CanvasRenderingContext2D | null = null;
  private worldGen: WorldGenerator = new WorldGenerator();
  private chunks: Map<string, ChunkData> = new Map();
  private player: PlayerState | null = null;
  private enemies: SlimeState[] = [];
  private xpOrbs: XpOrb[] = [];
  private particles: Particle[] = [];
  private cameraX: number = 0;
  private cameraY: number = 0;
  private screenW: number = 0;
  private screenH: number = 0;
  private gameLoopId: number = -1;
  private lastFrameTime: number = 0;
  private frameCount: number = 0;
  private shakeX: number = 0;
  private shakeY: number = 0;
  private shakeTimer: number = 0;
  private shakeIntensity: number = 3;
  private hitstopTimer: number = 0;
  private screenFlashTimer: number = 0;
  private screenFlashAlpha: number = 0;
  private audio: AudioManager = new AudioManager();
  private settings: GameSettings = { soundEnabled: true, effectsEnabled: true };
  private ambientParticles: AmbientParticle[] = [];
  private playerGender: GenderType = GenderType.MALE;
  private bosses: BossState[] = [];
  private activeBoss: BossState | null = null;
  private bossRoomLocked: boolean = false;
  private materialDrops: MaterialDrop[] = [];
  private floatingTexts: FloatingText[] = [];
  private bossRooms: BossRoom[] = [];
  private chests: ChestState[] = [];
  private traps: TrapInstance[] = [];
  private mechanisms: MechanismInstance[] = [];
  private secretRooms: SecretRoom[] = [];
  private teleportCooldown: number = 0;
  private transformCoreDrops: TransformCoreDrop[] = [];
  onDeath: (() => void) | null = null;
  private deathNotified: boolean = false;
  private autoSaveTimer: number = 0;
  onAutoSave: (() => void) | null = null;
  private transformUnlockNotifyTimer: number = 0;
  private transformUnlockNotifyForm: TransformForm = TransformForm.NONE;
  private transformAnimIsRevert: boolean = false;
  private chunkCacheShadow: Map<string, boolean> = new Map();
  private chunkCacheDirty: Set<string> = new Set();
  private chunkRenderQueue: string[] = [];
  private chunkRenderQueued: Set<string> = new Set();
  private chunkGenQueue: string[] = [];
  private chunkGenQueued: Set<string> = new Set();
  private bgGradCache: CanvasGradient | null = null;
  private bgGradDepth: number = -1;
  private bgGradW: number = 0;
  private bgGradH: number = 0;
  private vignetteGradCache: CanvasGradient | null = null;
  private vignetteW: number = 0;
  private vignetteH: number = 0;
  private bgParallaxW: number = 0;
  private bgParallaxH: number = 0;
  private bgParallaxCamCX: number = -999;
  private bgParallaxCamCY: number = -999;
  private profile: DeviceProfile | null = null;
  private resources: ResourceManager | null = null;
  private static readonly PARALLAX_KEY: string = '__bg_parallax__';
  private dynTileCache: Map<string, DynTileCacheEntry> = new Map();
  private dynTileOffscreen: OffscreenCanvas | null = null;
  private dynTileOffCtx: OffscreenCanvasRenderingContext2D | null = null;
  private chunkRenderOffscreen: OffscreenCanvas | null = null;
  private chunkRenderOffCtx: OffscreenCanvasRenderingContext2D | null = null;
  private input: InputState = {
    joyActive: false, joyDx: 0, joyDy: 0,
    jumpPressed: false, attackPressed: false, dashPressed: false, attackHeld: false,
    toolPressed: false
  };

  init(ctx: CanvasRenderingContext2D, minimapCtx: CanvasRenderingContext2D, screenW: number, screenH: number): void {
    this.ctx = ctx;
    this.minimapCtx = minimapCtx;
    this.screenW = screenW;
    this.screenH = screenH;

    // Detect device capabilities and create resource manager
    this.profile = DeviceProfile.detect();
    this.resources = new ResourceManager(this.profile.gpuMemoryBudget);
    console.info(this.profile.toString());

    this.loadChunksAround(0, 0);

    const startX: number = CHUNK_SIZE * TILE_SIZE / 2;
    const startY: number = CHUNK_SIZE * TILE_SIZE / 2;
    this.player = {
      x: startX, y: startY, vx: 0, vy: 0, hp: PLAYER_MAX_HP, isDead: false,
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
      transformFormAttackCooldown: 0,
      isDevouring: false,
      devourTimer: 0,
      devourCooldown: 0
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
    this.startLoop();
  }

  private startLoop(): void {
    this.lastFrameTime = Date.now();
    const loop = (): void => {
      if (this.ctx === null) return;
      try {
        const now: number = Date.now();
        const dt: number = Math.min(now - this.lastFrameTime, 50);
        this.lastFrameTime = now;
        this.update(dt);
        this.render();
        this.frameCount++;
      } catch (e) {
        console.error('[GameEngine] Game loop error:', String(e));
      }
      this.gameLoopId = setTimeout(loop, FRAME_INTERVAL);
    };
    this.gameLoopId = setTimeout(loop, FRAME_INTERVAL);
  }

  pause(): void {
    if (this.gameLoopId !== -1) {
      clearTimeout(this.gameLoopId);
      this.gameLoopId = -1;
    }
  }

  resume(): void {
    if (this.gameLoopId === -1 && this.ctx !== null) {
      this.startLoop();
    }
  }

  destroy(): void {
    if (this.gameLoopId !== -1) {
      clearTimeout(this.gameLoopId);
      this.gameLoopId = -1;
    }
    // Release all managed ImageBitmap resources (chunks + parallax)
    if (this.resources !== null) {
      this.resources.destroy();
      this.resources = null;
    }
    // Release dynamic tile cache (small, not in ResourceManager)
    this.dynTileCache.forEach((entry: DynTileCacheEntry) => {
      try { entry.bmp.close(); } catch (e) { /* ignore */ }
    });
    this.dynTileCache.clear();
    // Release OffscreenCanvas resources
    this.dynTileOffscreen = null;
    this.dynTileOffCtx = null;
    this.chunkRenderOffscreen = null;
    this.chunkRenderOffCtx = null;
    // Clear all collections
    this.chunks.clear();
    this.chunkCacheShadow.clear();
    this.chunkCacheDirty.clear();
    this.chunkRenderQueue = [];
    this.chunkRenderQueued.clear();
    this.chunkGenQueue = [];
    this.chunkGenQueued.clear();
    this.ctx = null;
    this.minimapCtx = null;
    this.player = null;
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

  getSaveData(): SaveData | null {
    if (this.player === null) return null;
    const p: PlayerState = this.player;
    return {
      playerX: p.x,
      playerY: p.y,
      hp: p.hp,
      xp: p.xp,
      level: p.level,
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
      currentWeaponForm: p.currentWeaponForm,
      unlockedForms: p.unlockedForms.slice(),
      evolutionBranch: p.evolutionBranch,
      evolutionLevel: p.evolutionLevel,
      isTransformed: false,
      transformForm: TransformForm.NONE,
      transformEnergy: p.transformEnergy,
      unlockedTransforms: p.unlockedTransforms.slice(),
      activeSkills: [],
      passiveSkills: [],
      timestamp: Date.now()
    };
  }

  restoreFromSave(data: SaveData): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;
    p.x = data.playerX;
    p.y = data.playerY;
    p.hp = data.hp;
    p.xp = data.xp;
    p.level = data.level;
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
    p.currentWeaponForm = data.currentWeaponForm;
    p.unlockedForms = data.unlockedForms.slice();
    p.evolutionBranch = data.evolutionBranch;
    p.evolutionLevel = data.evolutionLevel;
    p.isTransformed = false;
    p.transformForm = TransformForm.NONE;
    p.transformEnergy = data.transformEnergy;
    p.unlockedTransforms = data.unlockedTransforms.slice();
    p.isDead = false;
    p.hp = Math.max(1, p.hp);
    p.isAttacking = false;
    p.attackTimer = 0;
    p.isDashing = false;
    p.dashTimer = 0;
    p.dashCooldown = 0;
    p.isJumping = false;
    p.jumpTimer = 0;
    p.jumpHeight = 0;
    p.invincibleTimer = 0;
    p.isEngulfed = false;
    p.engulfSlimeIndex = -1;
    p.engulfEscapeCount = 0;
    p.isDrilling = false;
    p.drillHitCount = 0;
    p.isUsingTool = false;
    p.toolCooldown = 0;
    p.isDevouring = false;
    p.devourTimer = 0;
    p.devourCooldown = 0;
    this.deathNotified = false;
  }

  respawnPlayer(): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;
    const startX: number = CHUNK_SIZE * TILE_SIZE / 2;
    const startY: number = CHUNK_SIZE * TILE_SIZE / 2;
    p.x = startX;
    p.y = startY;
    p.vx = 0;
    p.vy = 0;
    p.hp = PLAYER_MAX_HP;
    p.isDead = false;
    p.isAttacking = false;
    p.attackTimer = 0;
    p.isDashing = false;
    p.dashTimer = 0;
    p.dashCooldown = 0;
    p.dashDirX = 0;
    p.dashDirY = 0;
    p.isJumping = false;
    p.jumpTimer = 0;
    p.jumpHeight = 0;
    p.invincibleTimer = 2000;
    p.isEngulfed = false;
    p.engulfSlimeIndex = -1;
    p.engulfEscapeCount = 0;
    p.isDrilling = false;
    p.drillHitCount = 0;
    p.isUsingTool = false;
    p.toolCooldown = 0;
    p.isTransformed = false;
    p.transformForm = TransformForm.NONE;
    p.transformAnimTimer = 0;
    p.transformFormAttackCooldown = 0;
    p.isDevouring = false;
    p.devourTimer = 0;
    p.devourCooldown = 0;
    this.deathNotified = false;
    this.updateCamera(p);
  }

  getPlayerChunks(): number {
    return this.chunks.size;
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

  private chunkKey(cx: number, cy: number): string {
    return cx + ',' + cy;
  }

  private loadChunksAround(tileX: number, tileY: number): void {
    const radius: number = this.profile !== null ? this.profile.chunkLoadRadius : CHUNK_LOAD_RADIUS;
    const pcx: number = Math.floor(tileX / CHUNK_SIZE);
    const pcy: number = Math.floor(tileY / CHUNK_SIZE);
    for (let dy: number = -radius; dy <= radius; dy++) {
      for (let dx: number = -radius; dx <= radius; dx++) {
        const cx: number = pcx + dx;
        const cy: number = pcy + dy;
        const key: string = this.chunkKey(cx, cy);
        if (!this.chunks.has(key) && !this.chunkGenQueued.has(key)) {
          this.chunkGenQueue.push(key);
          this.chunkGenQueued.add(key);
        }
      }
    }
  }

  private processChunkGenQueue(): void {
    const maxPerFrame: number = 1;
    let processed: number = 0;
    while (this.chunkGenQueue.length > 0 && processed < maxPerFrame) {
      const key: string = this.chunkGenQueue.shift() as string;
      this.chunkGenQueued.delete(key);
      if (this.chunks.has(key)) continue;
      const idx: number = key.indexOf(',');
      const cx: number = parseInt(key.substring(0, idx));
      const cy: number = parseInt(key.substring(idx + 1));
      const chunk: ChunkData = this.worldGen.generateChunk(cx, cy);
      this.chunks.set(key, chunk);
      this.chunkCacheDirty.add(key);
      for (let i: number = 0; i < chunk.enemies.length; i++) {
        this.enemies.push(chunk.enemies[i]);
      }
      for (let i: number = 0; i < chunk.traps.length; i++) {
        this.traps.push(chunk.traps[i]);
      }
      for (let i: number = 0; i < chunk.mechanisms.length; i++) {
        this.mechanisms.push(chunk.mechanisms[i]);
      }
      for (let i: number = 0; i < chunk.secretRooms.length; i++) {
        this.secretRooms.push(chunk.secretRooms[i]);
      }
      for (let i: number = 0; i < chunk.bosses.length; i++) {
        this.bosses.push(chunk.bosses[i]);
      }
      for (let i: number = 0; i < chunk.chests.length; i++) {
        this.chests.push(chunk.chests[i]);
      }
      processed++;
    }
    if (processed > 0) {
      const wgRooms: BossRoom[] = this.worldGen.getBossRooms();
      for (let i: number = 0; i < wgRooms.length; i++) {
        const wgRoom: BossRoom = wgRooms[i];
        let found: boolean = false;
        for (let j: number = 0; j < this.bossRooms.length; j++) {
          if (this.bossRooms[j].chunkX === wgRoom.chunkX && this.bossRooms[j].chunkY === wgRoom.chunkY) {
            found = true;
            break;
          }
        }
        if (!found) {
          this.bossRooms.push({
            chunkX: wgRoom.chunkX, chunkY: wgRoom.chunkY,
            bossType: wgRoom.bossType,
            entered: false, defeated: false, chestSpawned: false
          });
        }
      }
    }
  }

  getTile(worldX: number, worldY: number): number {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = this.chunkKey(cx, cy);
    const chunk: ChunkData | undefined = this.chunks.get(key);
    if (chunk === undefined) return TileType.WALL;
    const lx: number = tx - cx * CHUNK_SIZE;
    const ly: number = ty - cy * CHUNK_SIZE;
    return chunk.tiles[ly][lx];
  }

  setTile(worldX: number, worldY: number, tileType: number): void {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = this.chunkKey(cx, cy);
    const chunk: ChunkData | undefined = this.chunks.get(key);
    if (chunk === undefined) return;
    const lx: number = tx - cx * CHUNK_SIZE;
    const ly: number = ty - cy * CHUNK_SIZE;
    chunk.tiles[ly][lx] = tileType;
    this.chunkCacheDirty.add(key);
  }

  private isWalkable(tile: number): boolean {
    return tile !== TileType.WALL && tile !== TileType.VOID;
  }

  private update(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    if (this.hitstopTimer > 0) {
      this.hitstopTimer -= dt;
      this.updateShake(dt);
      return;
    }
    if (this.screenFlashTimer > 0) {
      this.screenFlashTimer -= dt;
      this.screenFlashAlpha = Math.max(0, this.screenFlashTimer / 150);
    }

    const ptx: number = Math.floor(p.x / TILE_SIZE);
    const pty: number = Math.floor(p.y / TILE_SIZE);
    this.loadChunksAround(ptx, pty);
    this.processChunkGenQueue();
    this.processChunkRenderQueue();
    if (this.frameCount % 60 === 0) {
      this.evictFarChunks(ptx, pty);
    }

    this.updatePlayer(p, dt);
    if (p.isDead) return;
    // === Transform System Update ===
    this.updateTransformSystem(p, dt);
    this.updateEnemies(dt);
    this.updateBosses(dt);
    this.checkBossRoomEntry(p);
    this.autoSaveTimer += dt;
    if (this.autoSaveTimer >= 60000) {
      this.autoSaveTimer = 0;
      if (this.onAutoSave !== null) {
        this.onAutoSave();
      }
    }
    this.collectMaterialDrops(p);
    this.checkChestInteraction();
    this.updateChestAnims(dt);
    this.updateTraps(dt);
    this.updateMechanisms(dt);
    this.updateXpOrbs(dt);
    this.updateParticles(dt);
    this.updateAmbientParticles(dt);
    this.updateFloatingTexts(dt);
    this.updateCamera(p);
    this.updateShake(dt);
  }

  private updatePlayer(p: PlayerState, dt: number): void {
    // Death check
    if (p.hp <= 0) {
      p.hp = 0;
      if (!p.isDead) {
        p.isDead = true;
        this.deathNotified = false;
      }
      if (!this.deathNotified && this.onDeath !== null) {
        this.deathNotified = true;
        this.onDeath();
      }
      return;
    }
    if (p.isDead) {
      return;
    }

    if (p.isEngulfed) {
      this.updateEngulfedPlayer(p, dt);
      return;
    }

    let moveX: number = 0;
    let moveY: number = 0;

    if (this.input.joyActive) {
      const len: number = Math.sqrt(this.input.joyDx * this.input.joyDx + this.input.joyDy * this.input.joyDy);
      if (len > 0.1) {
        moveX = this.input.joyDx / len;
        moveY = this.input.joyDy / len;
        p.facing = Math.atan2(this.input.joyDy, this.input.joyDx);
      }
    }

    // === Transform Form Override ===
    if (p.isTransformed) {
      this.updateTransformMovement(p, dt, moveX, moveY);
      // Handle transform attack
      if (this.input.attackPressed) {
        this.input.attackPressed = false;
        this.handleTransformAttack(p);
      }
      // Handle jump for applicable forms
      if (this.input.jumpPressed && p.transformForm !== TransformForm.IRON_MAN) {
        this.input.jumpPressed = false;
        if (p.transformForm === TransformForm.SLIME) {
          p.isJumping = true;
          p.jumpTimer = 400; // Higher jump for slime
        } else {
          p.isJumping = true;
          p.jumpTimer = 300;
        }
      }
      // Skip normal movement/attack — transform handles it
      // Still need collision, enemy contact, etc.
      this.applyTransformCollision(p);
      return;
    }

    if (p.isDrilling) {
      // Allow joystick movement to cancel drilling
      if (this.input.joyActive) {
        const dLen: number = Math.sqrt(this.input.joyDx * this.input.joyDx + this.input.joyDy * this.input.joyDy);
        if (dLen > 0.3) {
          p.isDrilling = false;
          p.isUsingTool = false;
          p.drillHitCount = 0;
        }
      }
      if (p.isDrilling) {
        this.updateDrilling(p, dt);
        return;
      }
    }

    if (p.isDashing) {
      p.dashTimer -= dt;
      if (p.dashTimer <= 0) {
        p.isDashing = false;
      } else {
        p.vx = p.dashDirX * DASH_SPEED;
        p.vy = p.dashDirY * DASH_SPEED;
        if (this.settings.effectsEnabled && this.frameCount % 3 === 0) {
          this.spawnParticle(p.x, p.y + PLAYER_SIZE / 2, 0, 0, 200, COLOR_PLAYER_BODY, 4);
        }
      }
    } else {
      p.vx = moveX * PLAYER_SPEED;
      p.vy = moveY * PLAYER_SPEED;
    }

    const newX: number = p.x + p.vx;
    const newY: number = p.y + p.vy;
    if (!this.checkPlayerCollision(newX, p.y)) {
      p.x = newX;
    }
    if (!this.checkPlayerCollision(p.x, newY)) {
      p.y = newY;
    }

    if (this.input.jumpPressed && !p.isJumping) {
      p.isJumping = true;
      p.jumpTimer = 300;
      this.input.jumpPressed = false;
      this.audio.playJump();
    }
    if (p.isJumping) {
      p.jumpTimer -= dt;
      const progress: number = 1.0 - (p.jumpTimer / 300);
      p.jumpHeight = Math.sin(progress * Math.PI) * 12;
      if (p.jumpTimer <= 0) {
        p.isJumping = false;
        p.jumpHeight = 0;
      }
    }

    if (this.input.attackPressed && !p.isAttacking && p.attackTimer <= 0) {
      const formStats: number[] = WEAPON_FORM_STATS[p.currentWeaponForm];
      const formDuration: number = formStats[2];
      p.isAttacking = true;
      p.attackTimer = formDuration;
      this.input.attackPressed = false;
      this.performAttack(p);
    }
    if (p.isAttacking) {
      p.attackTimer -= dt;
      if (p.attackTimer <= 0) {
        p.isAttacking = false;
        const formStats: number[] = WEAPON_FORM_STATS[p.currentWeaponForm];
        p.attackTimer = formStats[3] - formStats[2];
      }
    } else if (p.attackTimer > 0) {
      p.attackTimer -= dt;
    }

    if (this.input.toolPressed && !p.isUsingTool && p.toolCooldown <= 0 && !p.isDrilling) {
      this.input.toolPressed = false;
      // Search for nearest wall in facing direction (3-tile radius)
      const cosF: number = Math.cos(p.facing);
      const sinF: number = Math.sin(p.facing);
      let bestTX: number = -1;
      let bestTY: number = -1;
      let bestDist: number = 9999;
      for (let r: number = 1; r <= 3; r++) {
        const checkX: number = p.x + cosF * TILE_SIZE * r;
        const checkY: number = p.y + sinF * TILE_SIZE * r;
        const ctx: number = Math.floor(checkX / TILE_SIZE);
        const cty: number = Math.floor(checkY / TILE_SIZE);
        // Also check adjacent tiles for forgiveness
        for (let ox: number = -1; ox <= 1; ox++) {
          for (let oy: number = -1; oy <= 1; oy++) {
            const ttx: number = ctx + ox;
            const tty: number = cty + oy;
            if (this.getTile(ttx * TILE_SIZE, tty * TILE_SIZE) === TileType.WALL) {
              const dx: number = (ttx * TILE_SIZE + TILE_SIZE / 2) - p.x;
              const dy: number = (tty * TILE_SIZE + TILE_SIZE / 2) - p.y;
              const dist: number = dx * dx + dy * dy;
              if (dist < bestDist) {
                bestDist = dist;
                bestTX = ttx;
                bestTY = tty;
              }
            }
          }
        }
      }
      if (bestTX >= 0) {
        p.isUsingTool = true;
        p.isDrilling = true;
        p.drillTargetX = bestTX;
        p.drillTargetY = bestTY;
        p.drillHitCount = 0;
        p.vx = 0;
        p.vy = 0;
        p.toolCooldown = 200;
      }
    }
    if (p.toolCooldown > 0) p.toolCooldown -= dt;
    if (p.isUsingTool && !p.isDrilling) {
      p.isUsingTool = false;
    }

    if (this.input.dashPressed && !p.isDashing && p.dashCooldown <= 0) {
      p.isDashing = true;
      p.dashTimer = DASH_DURATION;
      p.dashCooldown = DASH_COOLDOWN;
      p.invincibleTimer = DASH_DURATION;
      const dx: number = Math.cos(p.facing);
      const dy: number = Math.sin(p.facing);
      p.dashDirX = dx;
      p.dashDirY = dy;
      this.input.dashPressed = false;
      this.audio.playDash();
    }
    if (p.dashCooldown > 0) p.dashCooldown -= dt;
    if (p.invincibleTimer > 0) p.invincibleTimer -= dt;

    if (Math.abs(p.vx) > 0.1 || Math.abs(p.vy) > 0.1) {
      p.animFrame += 0.15;
    }
  }

  private updateDrilling(p: PlayerState, dt: number): void {
    const wallWorldX: number = p.drillTargetX * TILE_SIZE + TILE_SIZE / 2;
    const wallWorldY: number = p.drillTargetY * TILE_SIZE + TILE_SIZE / 2;
    p.facing = Math.atan2(wallWorldY - p.y, wallWorldX - p.x);

    // Cancel drill if player moves too far away
    const distToWall: number = Math.sqrt((p.x - wallWorldX) * (p.x - wallWorldX) + (p.y - wallWorldY) * (p.y - wallWorldY));
    if (distToWall > TILE_SIZE * 2.5) {
      p.isDrilling = false;
      p.drillHitCount = 0;
      return;
    }

    // Auto-progress: accumulate drill time in ms
    p.drillHitCount += dt;

    // Spawn drill particles continuously
    if (this.settings.effectsEnabled && this.frameCount % 3 === 0) {
      const angle: number = Math.random() * Math.PI * 2;
      this.spawnParticle(wallWorldX, wallWorldY,
        Math.cos(angle) * 1.5, Math.sin(angle) * 1.5, 200, COLOR_DRILL_PARTICLE, 2);
    }

    // Play drill hit sound every ~300ms (every 19 frames at 16ms/frame)
    if (this.frameCount % 19 === 0) {
      this.audio.playDrillHit();
    }

    // Break wall after DRILL_BREAK_HITS * 300ms of continuous drilling
    const breakTime: number = DRILL_BREAK_HITS * 300;
    if (p.drillHitCount >= breakTime) {
      this.setTile(wallWorldX, wallWorldY, TileType.BROKEN_WALL);
      this.audio.playWallBreak();
      if (this.settings.effectsEnabled) {
        for (let k: number = 0; k < 8; k++) {
          const angle: number = Math.random() * Math.PI * 2;
          const speed: number = 1 + Math.random() * 3;
          this.spawnParticle(wallWorldX, wallWorldY,
            Math.cos(angle) * speed, Math.sin(angle) * speed, 400, COLOR_WALL, 4);
        }
      }
      p.isDrilling = false;
      p.drillHitCount = 0;
    }
  }

  // === Transform System ===

  private updateTransformSystem(p: PlayerState, dt: number): void {
    // Cooldown tick when not transformed
    if (!p.isTransformed && p.transformCooldown > 0) {
      p.transformCooldown -= dt;
      if (p.transformCooldown < 0) p.transformCooldown = 0;
    }

    // Transform animation timer
    if (p.transformAnimTimer > 0) {
      p.transformAnimTimer -= dt;
      if (p.transformAnimTimer < 0) p.transformAnimTimer = 0;
    }

    // Unlock notification timer
    if (this.transformUnlockNotifyTimer > 0) {
      this.transformUnlockNotifyTimer -= dt;
      if (this.transformUnlockNotifyTimer < 0) this.transformUnlockNotifyTimer = 0;
    }

    if (!p.isTransformed) {
      // Passive energy regen when not transformed
      p.transformEnergy += TRANSFORM_PASSIVE_REGEN * (dt / 1000);
      if (p.transformEnergy > p.transformMaxEnergy) {
        p.transformEnergy = p.transformMaxEnergy;
      }
      return;
    }

    // Energy drain
    const formIndex: number = p.transformForm as number;
    const drainRate: number = TRANSFORM_DRAIN_RATES[formIndex];
    p.transformEnergy -= drainRate * (dt / 1000);

    // Form attack cooldown tick
    if (p.transformFormAttackCooldown > 0) {
      p.transformFormAttackCooldown -= dt;
      if (p.transformFormAttackCooldown < 0) p.transformFormAttackCooldown = 0;
    }

    // Auto-revert on energy depletion
    if (p.transformEnergy <= 0) {
      p.transformEnergy = 0;
      this.deactivateTransform();
    }

    // Form-specific ambient effects
    this.updateTransformAmbientEffects(p, dt);
  }

  private updateTransformAmbientEffects(p: PlayerState, dt: number): void {
    if (!this.settings.effectsEnabled) return;
    const form: TransformForm = p.transformForm;

    if (form === TransformForm.SLIME && this.frameCount % 20 === 0) {
      // Drip particles
      this.spawnParticle(p.x, p.y + PLAYER_SIZE, 0, 1, 400, COLOR_TRANSFORM_SLIME, 2);
    } else if (form === TransformForm.GHOST && this.frameCount % 5 === 0) {
      // Trailing wisps
      this.spawnParticle(p.x + (Math.random() - 0.5) * 8, p.y + (Math.random() - 0.5) * 8,
        (Math.random() - 0.5) * 0.5, -0.5 - Math.random() * 0.5, 300, COLOR_TRANSFORM_GHOST, 3);
    } else if (form === TransformForm.IRON_MAN && this.frameCount % 3 === 0) {
      // Jet flame particles from feet
      this.spawnParticle(p.x - 3, p.y + PLAYER_SIZE, (Math.random() - 0.5) * 0.5, 1.5 + Math.random(), 200,
        Math.random() > 0.5 ? '#ff6b00' : '#fbbf24', 2 + Math.random() * 2);
      this.spawnParticle(p.x + 3, p.y + PLAYER_SIZE, (Math.random() - 0.5) * 0.5, 1.5 + Math.random(), 200,
        Math.random() > 0.5 ? '#ff6b00' : '#fbbf24', 2 + Math.random() * 2);
    }
  }

  activateTransform(form: TransformForm): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;
    if (p.isTransformed) return;
    if (p.transformCooldown > 0) return;
    if (p.unlockedTransforms.indexOf(form as number) === -1) return;

    // Save weapon form
    p.savedWeaponForm = p.currentWeaponForm;

    // Activate
    p.isTransformed = true;
    p.transformForm = form;
    p.transformEnergy = p.transformMaxEnergy;
    p.transformAnimTimer = TRANSFORM_ACTIVATE_ANIM;
    this.transformAnimIsRevert = false;
    p.transformFormAttackCooldown = 0;

    // Spawn activation particles
    if (this.settings.effectsEnabled) {
      for (let i: number = 0; i < 12; i++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 2 + Math.random() * 3;
        const color: string = this.getTransformColor(form);
        this.spawnParticle(p.x, p.y, Math.cos(angle) * speed, Math.sin(angle) * speed, 600, color, 3 + Math.random() * 2);
      }
    }
    this.shakeTimer = 200;
  }

  deactivateTransform(): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;
    if (!p.isTransformed) return;

    // Restore weapon
    p.currentWeaponForm = p.savedWeaponForm;

    // Deactivate
    p.isTransformed = false;
    p.transformForm = TransformForm.NONE;
    p.transformAnimTimer = TRANSFORM_REVERT_ANIM;
    this.transformAnimIsRevert = true;

    // Set cooldown if energy depleted
    if (p.transformEnergy <= 0) {
      p.transformCooldown = TRANSFORM_COOLDOWN;
    }

    // Revert particles
    if (this.settings.effectsEnabled) {
      for (let i: number = 0; i < 6; i++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 1 + Math.random() * 2;
        this.spawnParticle(p.x, p.y, -Math.cos(angle) * speed, -Math.sin(angle) * speed, 400, '#ffffff', 2);
      }
    }
  }

  private getTransformColor(form: TransformForm): string {
    if (form === TransformForm.SLIME) return COLOR_TRANSFORM_SLIME;
    if (form === TransformForm.GHOST) return COLOR_TRANSFORM_GHOST;
    if (form === TransformForm.ARMOR) return COLOR_TRANSFORM_ARMOR;
    return COLOR_TRANSFORM_IRON_GOLD;
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

  private updateEngulfedPlayer(p: PlayerState, dt: number): void {
    p.engulfDamageTimer -= dt;
    if (p.engulfDamageTimer <= 0) {
      p.hp -= SLIME_DAMAGE;
      if (p.hp < 0) p.hp = 0;
      p.engulfDamageTimer = ENGULF_DAMAGE_INTERVAL;
      this.audio.playPlayerDamage();
      this.shakeTimer = 100;
    }

    // Check for escape attack input
    if (this.input.attackPressed) {
      this.input.attackPressed = false;
      p.engulfEscapeCount++;
      this.audio.playEnemyHit();
      this.shakeTimer = 80;
    }

    if (p.engulfEscapeCount >= ENGULF_ESCAPE_ATTACKS) {
      p.isEngulfed = false;
      if (p.engulfSlimeIndex >= 0 && p.engulfSlimeIndex < this.enemies.length) {
        const s: SlimeState = this.enemies[p.engulfSlimeIndex];
        s.isEngulfing = false;
        s.engulfedPlayer = false;
        const angle: number = Math.random() * Math.PI * 2;
        p.x = s.x + Math.cos(angle) * 20;
        p.y = s.y + Math.sin(angle) * 20;
      }
      p.engulfSlimeIndex = -1;
      p.engulfEscapeCount = 0;
      p.invincibleTimer = INVINCIBLE_DURATION;
    }
  }

  private checkPlayerCollision(x: number, y: number): boolean {
    // Ghost form phases through walls
    if (this.player !== null && this.player.isTransformed &&
        this.player.transformForm === TransformForm.GHOST) {
      return false;
    }
    const halfSize: number = PLAYER_SIZE / 2;
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

  private performAttack(p: PlayerState): void {
    if (p.isEngulfed) {
      p.engulfEscapeCount++;
      this.audio.playEnemyHit();
      this.shakeTimer = 80;
      return;
    }

    const form: number = p.currentWeaponForm;
    const formStats: number[] = WEAPON_FORM_STATS[form];
    const formRange: number = formStats[0];
    const formWidth: number = formStats[1];
    const baseDamage: number = WEAPON_FORM_DAMAGE[form];
    const evoLevel: number = p.evolutionLevel;
    const damage: number = baseDamage + evoLevel * EVOLUTION_DAMAGE_BONUS;
    const shakeParams: number[] = WEAPON_SHAKE[form];
    const hitstop: number = WEAPON_HITSTOP[form];

    const attackX: number = p.x + Math.cos(p.facing) * formRange;
    const attackY: number = p.y + Math.sin(p.facing) * formRange;
    let didHit: boolean = false;
    let hitBoss: boolean = false;

    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;
      const dx: number = s.x - attackX;
      const dy: number = s.y - attackY;
      const distSq: number = dx * dx + dy * dy;
      const hitRange: number = formWidth + s.size;
      if (distSq < hitRange * hitRange) {
        s.hp -= damage;
        s.hitFlash = 200;
        didHit = true;
        const knockAngle: number = Math.atan2(dy, dx);
        s.vx = Math.cos(knockAngle) * SLIME_KNOCKBACK;
        s.vy = Math.sin(knockAngle) * SLIME_KNOCKBACK;
        this.audio.playEnemyHit();
        this.floatingTexts.push({
          x: s.x, y: s.y - s.size,
          text: damage.toString(),
          color: evoLevel >= 2 ? '#fbbf24' : '#e2e8f0',
          life: 1200, maxLife: 1200
        });
        if (this.settings.effectsEnabled) {
          const hitAngle: number = Math.atan2(dy, dx);
          for (let k: number = 0; k < 8; k++) {
            const spread: number = (k / 8) * Math.PI * 2;
            const angle: number = hitAngle + spread;
            const speed: number = 2 + Math.random() * 3;
            this.spawnParticle(s.x, s.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 350, COLOR_DAMAGE_PARTICLE, 3);
          }
          for (let k: number = 0; k < 4; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 0.5 + Math.random() * 1.5;
            this.spawnParticle(s.x, s.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 500, '#ffffff', 2);
          }
        }
        if (s.hp <= 0) {
          this.onEnemyDeath(s);
        }
      }
    }

    // Check boss hits
    for (let i: number = 0; i < this.bosses.length; i++) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;
      const dx: number = boss.x - attackX;
      const dy: number = boss.y - attackY;
      const hitRange: number = formWidth + boss.size * 0.6;
      const distSq: number = dx * dx + dy * dy;
      if (distSq < hitRange * hitRange) {
        boss.hp -= damage;
        boss.hitFlash = 250;
        didHit = true;
        hitBoss = true;
        this.audio.playEnemyHit();
        this.floatingTexts.push({
          x: boss.x, y: boss.y - boss.size,
          text: damage.toString(),
          color: evoLevel >= 2 ? '#fbbf24' : '#e2e8f0',
          life: 1200, maxLife: 1200
        });
        if (this.settings.effectsEnabled) {
          const bossColor: string = this.getBossColor(boss.bossType);
          for (let k: number = 0; k < 12; k++) {
            const angle: number = (k / 12) * Math.PI * 2;
            const speed: number = 2 + Math.random() * 4;
            this.spawnParticle(boss.x, boss.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 500, bossColor, 5);
          }
          for (let k: number = 0; k < 6; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 2;
            this.spawnParticle(boss.x, boss.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 600, '#ffffff', 3);
          }
        }
      }
    }

    if (didHit) {
      this.shakeTimer = shakeParams[1];
      this.shakeIntensity = shakeParams[0];
      this.hitstopTimer = hitstop;
    }
    if (hitBoss) {
      this.screenFlashTimer = 150;
      this.screenFlashAlpha = 0.3;
    }

    if (this.settings.effectsEnabled) {
      for (let k: number = 0; k < 3; k++) {
        const spread: number = (Math.random() - 0.5) * 0.8;
        const angle: number = p.facing + spread;
        const speed: number = 2 + Math.random() * 2;
        this.spawnParticle(attackX, attackY,
          Math.cos(angle) * speed, Math.sin(angle) * speed, 200, COLOR_ATTACK_FLASH, 2);
      }
    }
  }

  private onEnemyDeath(s: SlimeState): void {
    s.active = false;
    // Transform energy recovery on kill
    if (this.player !== null && this.player.isTransformed) {
      this.player.transformEnergy += TRANSFORM_ENERGY_KILL_SLIME;
      if (this.player.transformEnergy > this.player.transformMaxEnergy) {
        this.player.transformEnergy = this.player.transformMaxEnergy;
      }
    }
    this.audio.playEnemyDeath();
    if (this.settings.effectsEnabled) {
      for (let k: number = 0; k < 10; k++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 1 + Math.random() * 2;
        this.spawnParticle(s.x, s.y,
          Math.cos(angle) * speed, Math.sin(angle) * speed, 500, this.getEnemyColor(s), 4);
      }
    }
    const orbCount: number = 1 + Math.floor(Math.random() * 3);
    for (let k: number = 0; k < orbCount; k++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 5 + Math.random() * 15;
      this.xpOrbs.push({
        x: s.x + Math.cos(angle) * dist,
        y: s.y + Math.sin(angle) * dist,
        value: 1, bobPhase: Math.random() * Math.PI * 2, active: true
      });
    }
  }

  private getEnemyColor(s: SlimeState): string {
    switch (s.enemyType) {
      case EnemyType.GRAY_SLIME: return COLOR_SLIME_GRAY_LIGHT;
      case EnemyType.PURPLE_SLIME: return COLOR_SLIME_PURPLE_LIGHT;
      case EnemyType.RED_SLIME: return COLOR_SLIME_RED_LIGHT;
      case EnemyType.BLUE_SLIME: return COLOR_SLIME_BLUE_LIGHT;
      case EnemyType.YELLOW_SLIME: return COLOR_SLIME_YELLOW_LIGHT;
      case EnemyType.GHOST_SLIME: return COLOR_SLIME_GHOST_LIGHT;
      default: return COLOR_SLIME_GRAY_LIGHT;
    }
  }

  private updateEnemies(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;
    const cullDist: number = Math.max(this.screenW, this.screenH) * 1.5;
    const cullDistSq: number = cullDist * cullDist;
    const purpleDetectSq: number = PURPLE_SLIME_DETECT * PURPLE_SLIME_DETECT;
    const redDetectSq: number = RED_SLIME_DETECT * RED_SLIME_DETECT;
    const ghostDetectSq: number = (PURPLE_SLIME_DETECT * 1.5) * (PURPLE_SLIME_DETECT * 1.5);

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
      const distSq: number = dx * dx + dy * dy;

      if (distSq > cullDistSq) continue;

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
          if (distSq < purpleDetectSq && distSq > 1) {
            const dist: number = Math.sqrt(distSq);
            s.vx += (dx / dist) * PURPLE_SLIME_SPEED * 0.1;
            s.vy += (dy / dist) * PURPLE_SLIME_SPEED * 0.1;
            const engulfDist: number = s.size + PLAYER_SIZE;
            if (dist < engulfDist && p.invincibleTimer <= 0 && !p.isEngulfed) {
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
          if (distSq < redDetectSq && distSq > 1) {
            const dist: number = Math.sqrt(distSq);
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
          if (distSq < purpleDetectSq && distSq > 1) {
            const dist: number = Math.sqrt(distSq);
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
          if (distSq < ghostDetectSq && distSq > 1) {
            const dist: number = Math.sqrt(distSq);
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
      const speedSq: number = s.vx * s.vx + s.vy * s.vy;
      const maxSpeedSq: number = maxSpeed * maxSpeed;
      if (speedSq > maxSpeedSq) {
        const speed: number = Math.sqrt(speedSq);
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
        const contactDistSq: number = cdx * cdx + cdy * cdy;
        const contactRange: number = PLAYER_SIZE / 2 + s.size / 2;
        if (contactDistSq < contactRange * contactRange) {
          let incomingDamage: number = SLIME_DAMAGE;
          if (p.isTransformed) {
            const reduction: number = TRANSFORM_DAMAGE_REDUCTION[p.transformForm as number];
            incomingDamage = Math.max(1, Math.floor(incomingDamage * (1 - reduction)));
          }
          p.hp -= incomingDamage;
          if (p.hp < 0) p.hp = 0;
          p.invincibleTimer = (p.isTransformed && p.transformForm === TransformForm.GHOST) ? 1500 : INVINCIBLE_DURATION;
          const knockAngle: number = Math.atan2(cdy, cdx);
          const knockBack: number = (p.isTransformed && p.transformForm === TransformForm.ARMOR) ? 2.5 : 5;
          p.x -= Math.cos(knockAngle) * knockBack;
          p.y -= Math.sin(knockAngle) * knockBack;
          this.shakeTimer = 150;
          this.audio.playPlayerDamage();
          if (this.settings.effectsEnabled) {
            for (let k: number = 0; k < 4; k++) {
              const angle: number = Math.random() * Math.PI * 2;
              const spd: number = 1 + Math.random() * 2;
              this.spawnParticle(p.x, p.y,
                Math.cos(angle) * spd, Math.sin(angle) * spd, 300, COLOR_DAMAGE_PARTICLE, 3);
            }
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
      const distSq: number = dx * dx + dy * dy;
      const magnetRangeSq: number = XP_MAGNET_RANGE * XP_MAGNET_RANGE;

      if (distSq < magnetRangeSq && distSq > 1) {
        const dist: number = Math.sqrt(distSq);
        const pullSpeed: number = 3.0 * (1.0 - dist / XP_MAGNET_RANGE);
        orb.x += (dx / dist) * pullSpeed;
        orb.y += (dy / dist) * pullSpeed;
      }

      if (distSq < XP_COLLECT_RANGE * XP_COLLECT_RANGE) {
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
          if (p.hp < PLAYER_MAX_HP) {
            const heal: number = Math.max(1, Math.floor(PLAYER_MAX_HP * 0.2));
            p.hp = Math.min(PLAYER_MAX_HP, p.hp + heal);
          }
          this.audio.playLevelUp();
          if (this.settings.effectsEnabled) {
            for (let k: number = 0; k < 15; k++) {
              const angle: number = Math.random() * Math.PI * 2;
              const speed: number = 2 + Math.random() * 3;
              this.spawnParticle(p.x, p.y,
                Math.cos(angle) * speed, Math.sin(angle) * speed, 600, COLOR_XP_ORB, 4);
            }
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
      const distSq: number = dx * dx + dy * dy;

      switch (trap.state) {
        case TrapState.IDLE: {
          const triggerSq: number = trap.triggerRadius * trap.triggerRadius;
          if (distSq < triggerSq) {
            trap.state = TrapState.TELEGRAPH;
            trap.timer = TRAP_TELEGRAPH_TIME;
          }
          break;
        }

        case TrapState.TELEGRAPH:
          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.ACTIVE;
            trap.timer = TRAP_ACTIVE_TIME;
            this.audio.playPlayerDamage();
          }
          break;

        case TrapState.ACTIVE: {
          trap.timer -= dt;
          if (trap.trapType === TrapType.VOID_CRACK) {
            const pullRange: number = trap.triggerRadius * 1.5;
            const pullRangeSq: number = pullRange * pullRange;
            if (distSq < pullRangeSq) {
              const dist: number = Math.sqrt(distSq);
              const pullStrength: number = 0.8 * (1.0 - dist / pullRange);
              p.vx -= (dx / dist) * pullStrength;
              p.vy -= (dy / dist) * pullStrength;
            }
          }
          const sizeSq: number = trap.size * trap.size;
          if (distSq < sizeSq) {
            if (p.invincibleTimer <= 0) {
              // Iron Man hovers — immune to ground traps and terrain
              if (p.isTransformed && p.transformForm === TransformForm.IRON_MAN) {
                // Skip trap damage for Iron Man
              } else {
                let trapDmg: number = trap.damage;
                if (p.isTransformed) {
                  const reduction: number = TRANSFORM_DAMAGE_REDUCTION[p.transformForm as number];
                  trapDmg = Math.max(1, Math.floor(trapDmg * (1 - reduction)));
                }
                p.hp -= trapDmg;
                p.invincibleTimer = INVINCIBLE_DURATION;
                this.shakeTimer = 150;
              if (this.settings.effectsEnabled) {
                for (let k: number = 0; k < 6; k++) {
                  const angle: number = Math.random() * Math.PI * 2;
                  const speed: number = 1.5 + Math.random() * 2;
                  this.spawnParticle(p.x, p.y,
                    Math.cos(angle) * speed, Math.sin(angle) * speed, 400, COLOR_DAMAGE_PARTICLE, 3);
                }
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
        }

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
      const distSq: number = dx * dx + dy * dy;

      switch (mech.mechanismType) {
        case MechanismType.PRESSURE_PLATE: {
          const wasActive: boolean = mech.active;
          const plateRangeSq: number = PRESSURE_PLATE_RANGE * PRESSURE_PLATE_RANGE;
          mech.active = distSq < plateRangeSq;
          if (mech.active !== wasActive) {
            this.checkMechanismLinks(mech);
          }
          break;
        }

        case MechanismType.PUSH_BLOCK: {
          const pushRangeSq: number = (PLAYER_SIZE + 12) * (PLAYER_SIZE + 12);
          if (mech.pushable && distSq < pushRangeSq) {
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
        }

        case MechanismType.TELEPORT_RUNE: {
          const interactSq: number = MECH_INTERACT_RANGE * MECH_INTERACT_RANGE;
          if (distSq < interactSq && this.teleportCooldown <= 0) {
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
        }

        case MechanismType.LEVER: {
          const leverInteractSq: number = MECH_INTERACT_RANGE * MECH_INTERACT_RANGE;
          if (distSq < leverInteractSq && this.input.toolPressed) {
            this.input.toolPressed = false;
            mech.active = !mech.active;
            mech.rotation = mech.active ? 45 : -45;
            this.audio.playDrillHit();
            this.checkMechanismLinks(mech);
          }
          break;
        }

        case MechanismType.CRYSTAL_REFLECTOR: {
          const reflectSq: number = MECH_INTERACT_RANGE * MECH_INTERACT_RANGE;
          if (distSq < reflectSq && this.input.toolPressed) {
            this.input.toolPressed = false;
            mech.rotation = (mech.rotation + 60) % 360;
            this.audio.playDrillHit();
          }
          break;
        }
      }
    }

    this.checkBreakableWalls(p);
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

  private checkBreakableWalls(p: PlayerState): void {
    if (!p.isDrilling) return;
    const wallTX: number = p.drillTargetX;
    const wallTY: number = p.drillTargetY;
    const wallWorldX: number = wallTX * TILE_SIZE + TILE_SIZE / 2;
    const wallWorldY: number = wallTY * TILE_SIZE + TILE_SIZE / 2;

    for (let i: number = 0; i < this.secretRooms.length; i++) {
      const room: SecretRoom = this.secretRooms[i];
      if (room.revealed) continue;
      const roomWX: number = (room.chunkX * CHUNK_SIZE + room.wallTileX) * TILE_SIZE + TILE_SIZE / 2;
      const roomWY: number = (room.chunkY * CHUNK_SIZE + room.wallTileY) * TILE_SIZE + TILE_SIZE / 2;
      const dx: number = wallWorldX - roomWX;
      const dy: number = wallWorldY - roomWY;
      if (Math.abs(dx) < TILE_SIZE && Math.abs(dy) < TILE_SIZE) {
        room.revealed = true;
        this.setTile(roomWX, roomWY, TileType.FLOOR);
        this.audio.playWallBreak();
        this.shakeTimer = 200;
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 12; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 3;
            this.spawnParticle(roomWX, roomWY,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 600, COLOR_BREAKABLE_WALL, 4);
          }
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
      if (this.onAutoSave !== null) {
        this.onAutoSave();
      }
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
      const distSq: number = dx * dx + dy * dy;

      // Movement AI
      if (boss.bossRole === BossRole.PASSAGE_GUARDIAN) {
        // Always chase player in sealed room
        if (distSq > 1) {
          const dist: number = Math.sqrt(distSq);
          const speed: number = 1.5;
          boss.vx = (dx / dist) * speed;
          boss.vy = (dy / dist) * speed;
        }
      } else {
        // Optional Challenge - only chase within aggro radius
        const aggroSq: number = boss.aggroRadius * boss.aggroRadius;
        if (distSq < aggroSq) {
          if (distSq > 1) {
            const dist: number = Math.sqrt(distSq);
            const speed: number = 1.8;
            boss.vx = (dx / dist) * speed;
            boss.vy = (dy / dist) * speed;
          }
        } else {
          // Wander randomly
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
      const bossMeleeRange: number = boss.size + PLAYER_SIZE + 20;
      if (boss.attackTimer <= 0 && distSq < bossMeleeRange * bossMeleeRange) {
        // Melee attack
        boss.attackTimer = BOSS_ATTACK_INTERVAL;
        if (p.invincibleTimer <= 0) {
          p.hp -= 2;
          p.invincibleTimer = INVINCIBLE_DURATION;
          this.audio.playPlayerDamage();
          this.shakeTimer = 200;
          // Knockback
          if (distSq > 1) {
            const dist: number = Math.sqrt(distSq);
            p.vx = -(dx / dist) * 6;
            p.vy = -(dy / dist) * 6;
          }
          if (this.settings.effectsEnabled) {
            for (let k: number = 0; k < 8; k++) {
              const angle: number = Math.random() * Math.PI * 2;
              const speed: number = 1 + Math.random() * 2;
              this.spawnParticle(p.x, p.y,
                Math.cos(angle) * speed, Math.sin(angle) * speed, 400, COLOR_DAMAGE_PARTICLE, 3);
            }
          }
        }
      }

      // Phase transition
      if (boss.phase === BossPhase.PHASE_1 && boss.hp <= boss.maxHp * BOSS_PHASE2_THRESHOLD) {
        boss.phase = BossPhase.PHASE_2;
        boss.hitFlash = 500;
        this.shakeTimer = 400;
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 20; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 2 + Math.random() * 4;
            this.spawnParticle(boss.x, boss.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 800, this.getBossColor(boss.bossType), 5);
          }
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
          for (let k: number = 0; k < 30; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 5;
            this.spawnParticle(boss.x, boss.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 1000, this.getBossColor(boss.bossType), 4 + Math.random() * 4);
          }
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
      }

      // Hit flash decay
      if (boss.hitFlash > 0) {
        boss.hitFlash -= dt;
      }
    }
  }

  private getBossColor(bossType: BossType): string {
    if (bossType === BossType.CRYSTAL_GUARDIAN) return COLOR_BOSS_CRYSTAL;
    if (bossType === BossType.MUSHROOM_KING) return COLOR_BOSS_MUSHROOM;
    if (bossType === BossType.LAVA_BEAST) return COLOR_BOSS_LAVA;
    if (bossType === BossType.ABYSS_SIREN) return COLOR_BOSS_ABYSS;
    return COLOR_BOSS_VOID;
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
        active: true, flyProgress: 0
      });
    }

    // Always drop a rare core
    this.materialDrops.push({
      x: boss.x + (Math.random() - 0.5) * 40,
      y: boss.y + (Math.random() - 0.5) * 40,
      type: MaterialType.CORE_RARE, count: 1,
      bobPhase: Math.random() * Math.PI * 2,
      active: true, flyProgress: 0
    });

    // Drop transform core (first defeat only — check if player already has it)
    const transformDrop: TransformForm = this.getTransformCoreForBoss(boss.bossType);
    if (transformDrop !== TransformForm.NONE) {
      const alreadyHas: boolean = this.player !== null &&
        this.player.unlockedTransforms.indexOf(transformDrop) !== -1;
      if (!alreadyHas) {
        this.materialDrops.push({
          x: boss.x + (Math.random() - 0.5) * 30,
          y: boss.y + (Math.random() - 0.5) * 30,
          type: MaterialType.FORM_CORE, count: 1,
          bobPhase: Math.random() * Math.PI * 2,
          active: true, flyProgress: 0
        });
        // Mark which transform core via extraData — use a separate tracking mechanism
        // Store transform form in a parallel array indexed by drop
        this.transformCoreDrops.push({ dropIndex: this.materialDrops.length - 1, form: transformDrop } as TransformCoreDrop);
      }
    }
  }

  private getTransformCoreForBoss(bossType: BossType): TransformForm {
    if (bossType === BossType.MUSHROOM_KING) return TransformForm.SLIME;
    if (bossType === BossType.CRYSTAL_GUARDIAN) return TransformForm.ARMOR;
    if (bossType === BossType.LAVA_BEAST) return TransformForm.IRON_MAN;
    if (bossType === BossType.VOID_RIFT) return TransformForm.GHOST;
    return TransformForm.NONE;
  }

  private collectMaterialDrops(p: PlayerState): void {
    const magnetRangeSq: number = MATERIAL_MAGNET_RANGE * MATERIAL_MAGNET_RANGE;
    const collectRangeSq: number = MATERIAL_COLLECT_RANGE * MATERIAL_COLLECT_RANGE;
    for (let i: number = this.materialDrops.length - 1; i >= 0; i--) {
      const drop: MaterialDrop = this.materialDrops[i];
      if (!drop.active) continue;

      const dx: number = p.x - drop.x;
      const dy: number = p.y - drop.y;
      const distSq: number = dx * dx + dy * dy;

      if (distSq < collectRangeSq) {
        drop.active = false;
        if (drop.type === MaterialType.CRYSTAL_ORE) p.inventory.crystalOre += drop.count;
        else if (drop.type === MaterialType.MUSHROOM_ORE) p.inventory.mushroomOre += drop.count;
        else if (drop.type === MaterialType.FLAME_ORE) p.inventory.flameOre += drop.count;
        else if (drop.type === MaterialType.ABYSS_ORE) p.inventory.abyssOre += drop.count;
        else if (drop.type === MaterialType.VOID_ORE) p.inventory.voidOre += drop.count;
        else if (drop.type === MaterialType.CORE_NORMAL) p.inventory.coreNormal += drop.count;
        else if (drop.type === MaterialType.CORE_RARE) p.inventory.coreRare += drop.count;
        else if (drop.type === MaterialType.FORM_CORE) p.inventory.formCore += drop.count;

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
        this.floatingTexts.push({
          x: drop.x, y: drop.y - 10,
          text: '+1 ' + this.getMaterialName(drop.type),
          color: this.getMaterialColor(drop.type),
          life: 1200, maxLife: 1200
        } as FloatingText);
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 6; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 2;
            this.spawnParticle(drop.x, drop.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 400, '#ffd700', 3);
          }
        }
      } else if (distSq < magnetRangeSq && distSq > 1) {
        const dist: number = Math.sqrt(distSq);
        const pullSpeed: number = 2.5 * (1.0 - dist / MATERIAL_MAGNET_RANGE);
        drop.x += (dx / dist) * pullSpeed;
        drop.y += (dy / dist) * pullSpeed;
        drop.flyProgress = Math.min(drop.flyProgress + 0.02, 1.0);
      }
    }

    if (this.materialDrops.length > 50) {
      const active: MaterialDrop[] = [];
      for (let i: number = 0; i < this.materialDrops.length; i++) {
        if (this.materialDrops[i].active) active.push(this.materialDrops[i]);
      }
      this.materialDrops = active;
    }
  }

  private getMaterialName(type: MaterialType): string {
    if (type === MaterialType.CRYSTAL_ORE) return '水晶矿';
    if (type === MaterialType.MUSHROOM_ORE) return '蘑菇矿';
    if (type === MaterialType.FLAME_ORE) return '火焰矿';
    if (type === MaterialType.ABYSS_ORE) return '深渊矿';
    if (type === MaterialType.VOID_ORE) return '虚空矿';
    if (type === MaterialType.CORE_NORMAL) return '普通核心';
    if (type === MaterialType.CORE_RARE) return '稀有核心';
    if (type === MaterialType.FORM_CORE) return '变身核心';
    return '材料';
  }

  private getMaterialColor(type: MaterialType): string {
    if (type === MaterialType.CRYSTAL_ORE) return COLOR_CRYSTAL;
    if (type === MaterialType.MUSHROOM_ORE) return COLOR_MUSHROOM_CAP;
    if (type === MaterialType.FLAME_ORE) return COLOR_LAVA_LIGHT;
    if (type === MaterialType.ABYSS_ORE) return COLOR_BOSS_ABYSS;
    if (type === MaterialType.VOID_ORE) return COLOR_BOSS_VOID;
    if (type === MaterialType.CORE_NORMAL) return '#c0c0c0';
    if (type === MaterialType.CORE_RARE) return '#ffd700';
    if (type === MaterialType.FORM_CORE) return '#e879f9';
    return '#ffffff';
  }

  private updateFloatingTexts(dt: number): void {
    for (let i: number = this.floatingTexts.length - 1; i >= 0; i--) {
      const ft: FloatingText = this.floatingTexts[i];
      ft.life -= dt;
      ft.y -= 0.5;
      if (ft.life <= 0) {
        this.floatingTexts.splice(i, 1);
      }
    }
  }

  private spawnParticle(x: number, y: number, vx: number, vy: number, life: number, color: string, size: number): void {
    if (this.particles.length >= (this.profile !== null ? this.profile.maxParticles : MAX_PARTICLES)) return;
    this.particles.push({ x: x, y: y, vx: vx, vy: vy, life: life, maxLife: life, color: color, size: size });
  }

  private updateParticles(dt: number): void {
    for (let i: number = this.particles.length - 1; i >= 0; i--) {
      const pt: Particle = this.particles[i];
      pt.x += pt.vx;
      pt.y += pt.vy;
      pt.vx *= 0.95;
      pt.vy *= 0.95;
      pt.life -= dt;
      if (pt.life <= 0) {
        this.particles[i] = this.particles[this.particles.length - 1];
        this.particles.pop();
      }
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
      const progress: number = Math.max(0, this.shakeTimer) / 200;
      const intensity: number = this.shakeIntensity * progress;
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
    this.renderXpOrbs(c, offX, offY);
    this.renderTraps(c, offX, offY);
    this.renderMechanisms(c, offX, offY);
    this.renderChests(c, offX, offY);
    this.renderEnemies(c, offX, offY);
    this.renderBosses(c, offX, offY);
    this.renderMaterialDrops(c, offX, offY);
    this.renderFloatingTexts(c, offX, offY);
    this.renderPlayer(c, offX, offY, p);
    this.renderParticles(c, offX, offY);
    this.renderAmbientParticles(c);
    this.renderVignette(c);
    this.renderBossHPBar(c);

    if (this.screenFlashTimer > 0 && this.screenFlashAlpha > 0) {
      c.globalAlpha = this.screenFlashAlpha;
      c.fillStyle = '#ffffff';
      c.fillRect(0, 0, this.screenW, this.screenH);
      c.globalAlpha = 1.0;
    }

    if (this.frameCount % 30 === 0) {
      this.renderMinimap();
    }
  }

  private renderBackground(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    const w: number = this.screenW;
    const h: number = this.screenH;
    const depth: number = Math.min(1.0, Math.max(0, this.cameraY / (TILE_SIZE * 30)));

    // Layer 1: Depth-based gradient (cached)
    const depthBucket: number = depth < 0.3 ? 0 : (depth < 0.7 ? 1 : 2);
    if (this.bgGradCache === null || this.bgGradDepth !== depthBucket ||
        this.bgGradW !== w || this.bgGradH !== h) {
      const grad: CanvasGradient = c.createLinearGradient(0, 0, 0, h);
      if (depthBucket === 0) {
        grad.addColorStop(0, '#0c0c1e');
        grad.addColorStop(0.5, '#080814');
        grad.addColorStop(1, '#050510');
      } else if (depthBucket === 1) {
        grad.addColorStop(0, '#0a0818');
        grad.addColorStop(0.5, '#06050f');
        grad.addColorStop(1, '#03030a');
      } else {
        grad.addColorStop(0, '#0d0520');
        grad.addColorStop(0.5, '#080315');
        grad.addColorStop(1, '#04020a');
      }
      this.bgGradCache = grad;
      this.bgGradDepth = depthBucket;
      this.bgGradW = w;
      this.bgGradH = h;
    }
    c.fillStyle = this.bgGradCache;
    c.fillRect(0, 0, w, h);

    // Layers 2+3: Parallax cave formations (cached to offscreen canvas)
    const parallaxChunkSize: number = this.profile !== null ? this.profile.parallaxChunkSize : 400;
    if (this.profile === null || this.profile.parallaxEnabled) {
    const camCX: number = Math.floor(this.cameraX / parallaxChunkSize);
    const camCY: number = Math.floor(this.cameraY / parallaxChunkSize);
    if (!this.resources!.has(GameEngine.PARALLAX_KEY) || this.bgParallaxW !== w || this.bgParallaxH !== h ||
        this.bgParallaxCamCX !== camCX || this.bgParallaxCamCY !== camCY) {
      const pw: number = w + parallaxChunkSize * 2;
      const ph: number = h + parallaxChunkSize * 2;
      const offscreen: OffscreenCanvas = new OffscreenCanvas(pw, ph);
      const pc: OffscreenCanvasRenderingContext2D = offscreen.getContext('2d') as OffscreenCanvasRenderingContext2D;
      const baseOffX: number = camCX * parallaxChunkSize - parallaxChunkSize;
      const baseOffY: number = camCY * parallaxChunkSize - parallaxChunkSize;

      // Far layer (0.1x parallax)
      const farStep: number = 80;
      const farBaseOffX: number = baseOffX * 0.1;
      const farBaseOffY: number = baseOffY * 0.1;
      pc.fillStyle = depth > 0.5 ? '#0d0520' : '#0e0e1c';
      pc.globalAlpha = 0.6;
      const farStart: number = Math.floor(farBaseOffX / farStep) * farStep;
      for (let fx: number = farStart - farStep; fx < farBaseOffX + pw + farStep * 2; fx += farStep) {
        const sx: number = fx - farBaseOffX + parallaxChunkSize;
        const hash: number = Math.abs(Math.floor(fx / farStep) * 2654435761) % 100;
        const stalH: number = 30 + (hash % 50);
        const stalW: number = 25 + (hash % 35);
        const ceilY: number = -(farBaseOffY * 0.3) + (hash % 20) + parallaxChunkSize;
        pc.beginPath();
        pc.moveTo(sx, ceilY);
        pc.lineTo(sx + stalW / 2, ceilY + stalH);
        pc.lineTo(sx + stalW, ceilY);
        pc.fill();
        const floorY: number = ph - parallaxChunkSize - (farBaseOffY * 0.2) - (hash % 15);
        const stgH: number = 20 + (hash % 35);
        pc.beginPath();
        pc.moveTo(sx + 10, floorY);
        pc.lineTo(sx + 10 + stalW / 2 - 5, floorY - stgH);
        pc.lineTo(sx + 10 + stalW - 10, floorY);
        pc.fill();
      }

      // Mid layer (0.3x parallax)
      const midStep: number = 50;
      const midBaseOffX: number = baseOffX * 0.3;
      const midBaseOffY: number = baseOffY * 0.3;
      pc.fillStyle = depth > 0.5 ? '#0a0318' : '#0a0a16';
      pc.globalAlpha = 0.4;
      const midStart: number = Math.floor(midBaseOffX / midStep) * midStep;
      for (let mx: number = midStart - midStep; mx < midBaseOffX + pw + midStep * 2; mx += midStep) {
        const sx: number = mx - midBaseOffX + parallaxChunkSize;
        const hash: number = Math.abs(Math.floor(mx / midStep) * 48271) % 100;
        if (hash < 40) {
          const mStalH: number = 15 + (hash % 25);
          const ceilY: number = -(midBaseOffY * 0.4) + (hash % 30) + parallaxChunkSize;
          pc.beginPath();
          pc.moveTo(sx, ceilY);
          pc.lineTo(sx + 8, ceilY + mStalH);
          pc.lineTo(sx + 16, ceilY);
          pc.fill();
        }
        if (hash > 60) {
          const mStgH: number = 10 + (hash % 20);
          const floorY: number = ph - parallaxChunkSize - (midBaseOffY * 0.3) - (hash % 20);
          pc.beginPath();
          pc.moveTo(sx + 5, floorY);
          pc.lineTo(sx + 12, floorY - mStgH);
          pc.lineTo(sx + 19, floorY);
          pc.fill();
        }
      }
      pc.globalAlpha = 1.0;
      const bmp: ImageBitmap = offscreen.transferToImageBitmap();
      this.resources!.put(GameEngine.PARALLAX_KEY, bmp, pw * ph * 4);
      this.bgParallaxW = w;
      this.bgParallaxH = h;
      this.bgParallaxCamCX = camCX;
      this.bgParallaxCamCY = camCY;
    }

    const drawOffX: number = -(this.cameraX - camCX * parallaxChunkSize) * 0.1 + parallaxChunkSize - this.cameraX * 0.1 + camCX * parallaxChunkSize * 0.1;
    const drawOffY: number = -(this.cameraY - camCY * parallaxChunkSize) * 0.1 + parallaxChunkSize - this.cameraY * 0.1 + camCY * parallaxChunkSize * 0.1;
    const parallaxBmp: ImageBitmap | undefined = this.resources!.get(GameEngine.PARALLAX_KEY);
    if (parallaxBmp !== undefined) {
      c.drawImage(parallaxBmp, drawOffX, drawOffY);
    }
    }
  }

  private renderChunkStaticLayer(cx: number, cy: number, isShadow: boolean): ImageBitmap {
    const chunkPixelSize: number = CHUNK_SIZE * TILE_SIZE;
    const renderScale: number = this.profile !== null ? this.profile.renderScale : 0.5;
    const renderSize: number = Math.floor(chunkPixelSize * renderScale);
    if (this.chunkRenderOffscreen === null) {
      this.chunkRenderOffscreen = new OffscreenCanvas(renderSize, renderSize);
      this.chunkRenderOffCtx = this.chunkRenderOffscreen.getContext('2d') as OffscreenCanvasRenderingContext2D;
    }
    const oc: OffscreenCanvasRenderingContext2D = this.chunkRenderOffCtx!;
    oc.setTransform(renderScale, 0, 0, renderScale, 0, 0);
    oc.clearRect(0, 0, chunkPixelSize, chunkPixelSize);

    const floorColor: string = isShadow ? COLOR_SHADOW_FLOOR : COLOR_FLOOR;
    const floorVarColor: string = isShadow ? '#0a0a16' : COLOR_FLOOR_VAR;
    const wallColor: string = isShadow ? COLOR_SHADOW_WALL : COLOR_WALL;

    const baseTX: number = cx * CHUNK_SIZE;
    const baseTY: number = cy * CHUNK_SIZE;

    for (let ly: number = 0; ly < CHUNK_SIZE; ly++) {
      for (let lx: number = 0; lx < CHUNK_SIZE; lx++) {
        const tx: number = baseTX + lx;
        const ty: number = baseTY + ly;
        const screenX: number = lx * TILE_SIZE;
        const screenY: number = ly * TILE_SIZE;
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);

        if (tile === TileType.WALL) {
          oc.fillStyle = wallColor;
          oc.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const brickH: number = 8;
          const brickW: number = 16;
          const row: number = ty % 2;
          oc.fillStyle = isShadow ? '#2d1050' : COLOR_WALL_EDGE;
          oc.fillRect(screenX, screenY, TILE_SIZE, 1);
          oc.fillRect(screenX, screenY + brickH, TILE_SIZE, 1);
          oc.fillRect(screenX, screenY + brickH * 2, TILE_SIZE, 1);
          oc.fillRect(screenX, screenY + brickH * 3, TILE_SIZE, 1);
          const vOff: number = row === 0 ? 0 : brickW / 2;
          oc.fillRect(screenX + vOff, screenY, 1, brickH);
          oc.fillRect(screenX + vOff + brickW, screenY, 1, brickH);
          oc.fillRect(screenX + vOff + brickW / 2, screenY + brickH, 1, brickH);
          oc.fillRect(screenX + vOff + brickW * 1.5, screenY + brickH, 1, brickH);
          oc.fillRect(screenX + vOff, screenY + brickH * 2, 1, brickH);
          oc.fillRect(screenX + vOff + brickW, screenY + brickH * 2, 1, brickH);
          oc.fillRect(screenX + vOff + brickW / 2, screenY + brickH * 3, 1, brickH);
          const hash: number = ((tx * 31 + ty * 17) % 7);
          if (hash === 0) {
            oc.fillStyle = '#1f1f35';
            oc.fillRect(screenX + 4, screenY + 3, 3, 2);
          } else if (hash === 1) {
            oc.fillStyle = '#1f1f35';
            oc.fillRect(screenX + 20, screenY + 18, 4, 2);
          } else if (hash === 3) {
            oc.fillStyle = '#22223a';
            oc.fillRect(screenX + 10, screenY + 12, 2, 3);
          }
          const oreHash: number = ((tx * 73 + ty * 137) % 47);
          if (oreHash < 3) {
            oc.fillStyle = '#8b4513';
            oc.fillRect(screenX + 6, screenY + 8, 4, 3);
            oc.fillRect(screenX + 9, screenY + 10, 3, 4);
            oc.fillStyle = '#cd7f32';
            oc.fillRect(screenX + 7, screenY + 9, 2, 2);
            oc.fillRect(screenX + 10, screenY + 11, 2, 2);
          } else if (oreHash === 3) {
            oc.fillStyle = '#4a5568';
            oc.fillRect(screenX + 18, screenY + 4, 5, 3);
            oc.fillRect(screenX + 20, screenY + 6, 3, 4);
            oc.fillStyle = '#718096';
            oc.fillRect(screenX + 19, screenY + 5, 3, 2);
          } else if (oreHash === 4) {
            oc.fillStyle = '#a0aec0';
            oc.fillRect(screenX + 4, screenY + 20, 3, 3);
            oc.fillRect(screenX + 6, screenY + 22, 4, 2);
            oc.fillStyle = '#e2e8f0';
            oc.fillRect(screenX + 5, screenY + 21, 2, 2);
          } else if (oreHash === 5) {
            oc.fillStyle = '#b7791f';
            oc.fillRect(screenX + 14, screenY + 14, 4, 3);
            oc.fillRect(screenX + 16, screenY + 16, 3, 4);
            oc.fillStyle = '#ecc94b';
            oc.fillRect(screenX + 15, screenY + 15, 2, 2);
          }
          const belowTile: number = this.getTile(tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
          if (belowTile === TileType.FLOOR || belowTile === TileType.BROKEN_WALL) {
            oc.fillStyle = isShadow ? '#4a1a6a' : '#2d6b3a';
            oc.fillRect(screenX, screenY + TILE_SIZE - 3, TILE_SIZE, 3);
            oc.fillStyle = isShadow ? '#6b2a9a' : '#3d8a4e';
            oc.fillRect(screenX + 2, screenY + TILE_SIZE - 5, 2, 3);
            oc.fillRect(screenX + 8, screenY + TILE_SIZE - 4, 1, 2);
            oc.fillRect(screenX + 14, screenY + TILE_SIZE - 6, 2, 4);
            oc.fillRect(screenX + 22, screenY + TILE_SIZE - 4, 1, 2);
            oc.fillRect(screenX + 28, screenY + TILE_SIZE - 5, 2, 3);
          }
          const belowWall: number = this.getTile(tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
          if (belowWall !== TileType.WALL && belowWall !== TileType.FLOOR) {
            const vineHash: number = ((tx * 41 + ty * 67) % 11);
            if (vineHash < 3) {
              const vineLen: number = 6 + (vineHash * 4);
              oc.fillStyle = isShadow ? '#3a1a5a' : '#1a4a2a';
              oc.fillRect(screenX + 4 + vineHash * 3, screenY + TILE_SIZE, 1, vineLen);
              oc.fillRect(screenX + 5 + vineHash * 3, screenY + TILE_SIZE + vineLen - 2, 1, 3);
              oc.fillStyle = isShadow ? '#5a2a8a' : '#2d6b3a';
              oc.fillRect(screenX + 3 + vineHash * 3, screenY + TILE_SIZE + vineLen, 3, 2);
            } else if (vineHash < 5) {
              oc.fillStyle = isShadow ? '#3a1a5a' : '#1a4a2a';
              oc.fillRect(screenX + 8, screenY + TILE_SIZE, 1, 4);
              oc.fillRect(screenX + 18, screenY + TILE_SIZE, 1, 6);
              oc.fillRect(screenX + 26, screenY + TILE_SIZE, 1, 3);
            }
          }
        } else if (tile === TileType.FLOOR) {
          const variant: number = ((tx * 7 + ty * 13) % 5);
          oc.fillStyle = variant === 0 ? floorColor : variant === 1 ? floorVarColor : variant === 2 ? '#14142a' : variant === 3 ? '#10101e' : floorColor;
          oc.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const hash: number = ((tx * 23 + ty * 11) % 8);
          if (hash === 0) {
            oc.fillStyle = '#1e1e38';
            oc.fillRect(screenX + 4, screenY + 8, 4, 3);
            oc.fillRect(screenX + 18, screenY + 20, 3, 2);
          } else if (hash === 1) {
            oc.fillStyle = '#0e0e1a';
            oc.fillRect(screenX + 12, screenY + 4, 2, 2);
            oc.fillRect(screenX + 24, screenY + 16, 3, 2);
            oc.fillRect(screenX + 6, screenY + 24, 2, 2);
          } else if (hash === 2) {
            oc.fillStyle = '#1a1a30';
            oc.fillRect(screenX + 8, screenY + 14, 5, 3);
          } else if (hash === 4) {
            oc.fillStyle = '#0c0c18';
            oc.fillRect(screenX + 20, screenY + 6, 2, 3);
            oc.fillRect(screenX + 2, screenY + 22, 3, 2);
          }
          oc.fillStyle = '#0a0a14';
          oc.globalAlpha = 0.12;
          oc.fillRect(screenX, screenY + TILE_SIZE - 1, TILE_SIZE, 1);
          oc.fillRect(screenX + TILE_SIZE - 1, screenY, 1, TILE_SIZE);
          oc.globalAlpha = 1.0;
          const aboveTile: number = this.getTile(tx * TILE_SIZE, (ty - 1) * TILE_SIZE);
          if (aboveTile === TileType.WALL) {
            oc.fillStyle = isShadow ? '#1a0a2e' : '#1a1a28';
            oc.fillRect(screenX, screenY, TILE_SIZE, 3);
          }
          if (aboveTile !== TileType.WALL && aboveTile !== TileType.FLOOR) {
            const stHash: number = ((tx * 53 + ty * 97) % 13);
            if (stHash < 2) {
              oc.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
              oc.fillRect(screenX + 12, screenY, 8, 2);
              oc.fillRect(screenX + 14, screenY + 2, 4, 4);
              oc.fillRect(screenX + 15, screenY + 6, 2, 4);
              oc.fillStyle = isShadow ? '#3a2a5a' : '#3a3a50';
              oc.fillRect(screenX + 13, screenY, 2, 3);
            } else if (stHash < 5) {
              oc.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
              oc.fillRect(screenX + 6 + stHash * 4, screenY, 3, 2);
              oc.fillRect(screenX + 7 + stHash * 4, screenY + 2, 1, 3 + stHash);
            }
          }
          const belowFloor: number = this.getTile(tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
          if (belowFloor !== TileType.FLOOR && belowFloor !== TileType.WALL) {
            const smHash: number = ((tx * 37 + ty * 79) % 17);
            if (smHash < 2) {
              oc.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
              oc.fillRect(screenX + 10, screenY + TILE_SIZE - 2, 12, 2);
              oc.fillRect(screenX + 12, screenY + TILE_SIZE - 6, 8, 4);
              oc.fillRect(screenX + 14, screenY + TILE_SIZE - 9, 4, 3);
              oc.fillStyle = isShadow ? '#3a2a5a' : '#3a3a50';
              oc.fillRect(screenX + 15, screenY + TILE_SIZE - 8, 2, 2);
            } else if (smHash < 5) {
              oc.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
              oc.fillRect(screenX + 4 + smHash * 5, screenY + TILE_SIZE - 2, 3, 2);
              oc.fillRect(screenX + 5 + smHash * 5, screenY + TILE_SIZE - 4 - smHash, 1, 2 + smHash);
            }
          }
        } else if (tile === TileType.BROKEN_WALL) {
          oc.fillStyle = '#2a2a3e';
          oc.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          oc.fillStyle = '#3a3a50';
          oc.fillRect(screenX + 2, screenY + 2, 8, 6);
          oc.fillRect(screenX + 16, screenY + 10, 10, 7);
          oc.fillRect(screenX + 6, screenY + 20, 7, 8);
          oc.fillStyle = '#4a4a60';
          oc.fillRect(screenX + 4, screenY + 4, 4, 3);
          oc.fillRect(screenX + 18, screenY + 12, 5, 3);
          oc.fillStyle = '#1a1a2e';
          oc.fillRect(screenX + 12, screenY + 2, 1, 8);
          oc.fillRect(screenX + 14, screenY + 6, 1, 6);
          oc.fillRect(screenX + 26, screenY + 18, 1, 10);
        }
      }
    }
    return this.chunkRenderOffscreen!.transferToImageBitmap();
  }

  private processChunkRenderQueue(): void {
    if (this.chunkRenderQueue.length === 0) return;
    const key: string = this.chunkRenderQueue.shift() as string;
    this.chunkRenderQueued.delete(key);
    const idx: number = key.indexOf(',');
    const cx: number = parseInt(key.substring(0, idx));
    const cy: number = parseInt(key.substring(idx + 1));
    const chunkWorldX: number = (cx + 0.5) * CHUNK_SIZE * TILE_SIZE;
    const chunkWorldY: number = (cy + 0.5) * CHUNK_SIZE * TILE_SIZE;
    const biome: BiomeType = this.worldGen.getBiome(chunkWorldX, chunkWorldY);
    const isShadow: boolean = biome === BiomeType.SHADOW;
    const bitmap: ImageBitmap = this.renderChunkStaticLayer(cx, cy, isShadow);
    const renderScale: number = this.profile !== null ? this.profile.renderScale : 0.5;
    const renderSize: number = Math.floor(CHUNK_SIZE * TILE_SIZE * renderScale);
    this.resources!.put(key, bitmap, renderSize * renderSize * 4);
    this.chunkCacheShadow.set(key, isShadow);
    this.chunkCacheDirty.delete(key);
  }

  private evictFarChunks(playerTX: number, playerTY: number): void {
    const pcx: number = Math.floor(playerTX / CHUNK_SIZE);
    const pcy: number = Math.floor(playerTY / CHUNK_SIZE);
    const evictRadius: number = this.profile !== null ? this.profile.chunkLoadRadius : CHUNK_LOAD_RADIUS;
    const evictDist: number = evictRadius + 3;
    const keysToRemove: string[] = [];
    const allKeys: string[] = this.resources!.keys();
    for (let k: number = 0; k < allKeys.length; k++) {
      const key: string = allKeys[k];
      const idx: number = key.indexOf(',');
      const cx: number = parseInt(key.substring(0, idx));
      const cy: number = parseInt(key.substring(idx + 1));
      if (Math.abs(cx - pcx) > evictDist || Math.abs(cy - pcy) > evictDist) {
        keysToRemove.push(key);
      }
    }
    for (let i: number = 0; i < keysToRemove.length; i++) {
      const key: string = keysToRemove[i];
      this.resources!.remove(key);
      this.chunkCacheShadow.delete(key);
      this.chunkCacheDirty.delete(key);
    }
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
    const floorColor: string = isShadow ? COLOR_SHADOW_FLOOR : COLOR_FLOOR;
    const wallColor: string = isShadow ? COLOR_SHADOW_WALL : COLOR_WALL;

    const chunkPixelSize: number = CHUNK_SIZE * TILE_SIZE;
    const startCX: number = Math.floor(startTX / CHUNK_SIZE);
    const startCY: number = Math.floor(startTY / CHUNK_SIZE);
    const endCX: number = Math.floor(endTX / CHUNK_SIZE);
    const endCY: number = Math.floor(endTY / CHUNK_SIZE);

    for (let cy: number = startCY; cy <= endCY; cy++) {
      for (let cx: number = startCX; cx <= endCX; cx++) {
        const key: string = this.chunkKey(cx, cy);
        if (!this.chunks.has(key)) continue;
        const cached: ImageBitmap | undefined = this.resources!.get(key);
        if (cached !== undefined) {
          const drawX: number = cx * chunkPixelSize + offX;
          const drawY: number = cy * chunkPixelSize + offY;
          c.drawImage(cached, drawX, drawY, chunkPixelSize, chunkPixelSize);
        }
        if (this.chunkCacheDirty.has(key) || cached === undefined) {
          if (!this.chunkRenderQueued.has(key)) {
            this.chunkRenderQueue.push(key);
            this.chunkRenderQueued.add(key);
          }
        }
      }
    }

    for (let ty: number = startTY; ty <= endTY; ty++) {
      for (let tx: number = startTX; tx <= endTX; tx++) {
        const screenX: number = tx * TILE_SIZE + offX;
        const screenY: number = ty * TILE_SIZE + offY;
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);

        if (tile === TileType.WALL || tile === TileType.FLOOR || tile === TileType.BROKEN_WALL) {
          const tileCX: number = Math.floor(tx / CHUNK_SIZE);
          const tileCY: number = Math.floor(ty / CHUNK_SIZE);
          const tileKey: string = this.chunkKey(tileCX, tileCY);
          if (this.resources!.has(tileKey)) continue;
          c.fillStyle = tile === TileType.WALL ? wallColor : (tile === TileType.FLOOR ? floorColor : '#2a2a3e');
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          continue;
        }

        this.renderDynamicTileCached(c, tx, ty, tile, screenX, screenY, isShadow);
      }
    }
  }

  private renderDynamicTileCached(c: CanvasRenderingContext2D, tx: number, ty: number,
    tile: number, screenX: number, screenY: number, isShadow: boolean): void {
    const key: string = tx + ',' + ty;
    const cached: DynTileCacheEntry | undefined = this.dynTileCache.get(key);
    const regenInterval: number = 8;
    const shouldRegen: boolean = cached === undefined ||
      (this.frameCount - cached.gen) >= regenInterval;

    if (shouldRegen) {
      if (this.dynTileOffscreen === null) {
        this.dynTileOffscreen = new OffscreenCanvas(TILE_SIZE, TILE_SIZE);
        this.dynTileOffCtx = this.dynTileOffscreen.getContext('2d') as OffscreenCanvasRenderingContext2D;
      }
      const oc: OffscreenCanvasRenderingContext2D = this.dynTileOffCtx!;
      oc.clearRect(0, 0, TILE_SIZE, TILE_SIZE);
      this.renderDynamicTile(oc, tx, ty, tile, 0, 0, isShadow);
      const bmp: ImageBitmap = this.dynTileOffscreen!.transferToImageBitmap();
      if (cached !== undefined) {
        cached.bmp.close();
      }
      const entry: DynTileCacheEntry = { bmp: bmp, gen: this.frameCount };
      this.dynTileCache.set(key, entry);

      const maxCache: number = this.profile !== null ? this.profile.maxDynTileCache : MAX_DYN_TILE_CACHE;
    if (this.dynTileCache.size > maxCache) {
        const firstKey: string = this.dynTileCache.keys().next().value as string;
        const oldEntry: DynTileCacheEntry | undefined = this.dynTileCache.get(firstKey);
        if (oldEntry !== undefined) {
          oldEntry.bmp.close();
        }
        this.dynTileCache.delete(firstKey);
      }

      c.drawImage(bmp, screenX, screenY);
    } else {
      c.drawImage(cached!.bmp, screenX, screenY);
    }
  }

  private renderDynamicTile(c: OffscreenCanvasRenderingContext2D, tx: number, ty: number,
    tile: number, screenX: number, screenY: number, isShadow: boolean): void {
    if (tile === TileType.GLOW_STONE) {
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
    } else if (tile === TileType.PLANT) {
      c.fillStyle = isShadow ? COLOR_SHADOW_FLOOR : COLOR_FLOOR;
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
    } else if (tile === TileType.WATER) {
      const waveOff: number = Math.sin(this.frameCount * 0.03 + tx * 0.5) * 2;
      const waveOff2: number = Math.sin(this.frameCount * 0.05 + tx * 0.8) * 1.5;
      c.globalAlpha = 0.75;
      c.fillStyle = COLOR_WATER;
      c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
      c.globalAlpha = 1.0;
      c.fillStyle = '#0a1a3a';
      c.globalAlpha = 0.25;
      c.fillRect(screenX, screenY + TILE_SIZE - 8, TILE_SIZE, 8);
      c.globalAlpha = 1.0;
      const aboveWater: number = this.getTile(tx * TILE_SIZE, (ty - 1) * TILE_SIZE);
      if (aboveWater !== TileType.WATER) {
        c.fillStyle = COLOR_WATER_LIGHT;
        c.globalAlpha = 0.6;
        c.fillRect(screenX, screenY, TILE_SIZE, 2);
        c.globalAlpha = 0.3;
        c.fillRect(screenX, screenY + 2, TILE_SIZE, 1);
        c.globalAlpha = 1.0;
      }
      c.fillStyle = COLOR_WATER_LIGHT;
      c.globalAlpha = 0.3;
      c.fillRect(screenX + 4, screenY + 8 + waveOff, 24, 3);
      c.fillRect(screenX + 8, screenY + 20 - waveOff, 16, 2);
      c.globalAlpha = 0.15;
      c.fillRect(screenX + 2 + waveOff2, screenY + 14, 10, 2);
      c.fillRect(screenX + 18 - waveOff2, screenY + 26, 8, 2);
      c.globalAlpha = 1.0;
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
      c.fillStyle = COLOR_LAVA;
      c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
      c.fillStyle = '#cd4a00';
      c.globalAlpha = 0.4;
      c.fillRect(screenX + 6, screenY + 10 + lavaOff2, 18, 6);
      c.globalAlpha = 1.0;
      c.fillStyle = COLOR_LAVA_LIGHT;
      c.globalAlpha = 0.6;
      c.fillRect(screenX + 4, screenY + 6 + lavaOff, 20, 4);
      c.fillRect(screenX + 10, screenY + 18 - lavaOff, 14, 3);
      c.globalAlpha = 1.0;
      const crustHash: number = ((tx * 43 + ty * 89) % 11);
      if (crustHash < 3) {
        c.fillStyle = '#3a0a00';
        c.globalAlpha = 0.5;
        c.fillRect(screenX + 2 + crustHash * 8, screenY + 4 + crustHash * 3, 6, 3);
        c.fillRect(screenX + 14 - crustHash * 2, screenY + 22 - crustHash * 4, 5, 2);
        c.globalAlpha = 1.0;
      }
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

    // === Terraria-style character rendering ===
    // Scale: character is ~28px tall, ~14px wide

    // Character outline for visibility against dark backgrounds
    c.fillStyle = '#000000';
    c.globalAlpha = 0.6;
    c.fillRect(screenX - 7, screenY - 13 + bobY, 14, 27);
    c.globalAlpha = 1.0;

    // Shadow under feet
    if (!p.isJumping) {
      c.globalAlpha = 0.2;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, screenY + 12 + bobY, 6, 2, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Legs with walking animation
    const legSwing: number = isMoving ? walkPhase * 3 : 0;
    c.fillStyle = '#4a3728';
    c.fillRect(screenX - 4, screenY + 5 + bobY, 3, 7);
    c.fillRect(screenX + 1, screenY + 5 + bobY, 3, 7);
    // Boots
    c.fillStyle = '#3d2b1a';
    c.fillRect(screenX - 5, screenY + 10 + bobY + (isMoving ? legSwing : 0), 4, 3);
    c.fillRect(screenX + 1, screenY + 10 + bobY + (isMoving ? -legSwing : 0), 4, 3);

    // Body / torso
    c.fillStyle = bodyColor;
    c.fillRect(screenX - 5, screenY - 3 + bobY, 10, 9);
    // Body shading
    c.fillStyle = bodyDarkColor;
    c.fillRect(screenX - 5, screenY + 3 + bobY, 10, 3);
    // Belt
    c.fillStyle = '#8b6914';
    c.fillRect(screenX - 5, screenY + 4 + bobY, 10, 2);
    // Belt buckle
    c.fillStyle = '#ffd700';
    c.fillRect(screenX - 1, screenY + 4 + bobY, 2, 2);

    // Arms
    const armSwing: number = isMoving ? walkPhase * 2 : 0;
    c.fillStyle = bodyColor;
    // Left arm
    c.fillRect(screenX - 7, screenY - 2 + bobY + (isMoving ? -armSwing : 0), 3, 7);
    // Right arm (holds weapon side)
    c.fillRect(screenX + 4, screenY - 2 + bobY + (isMoving ? armSwing : 0), 3, 7);
    // Hands (skin color)
    c.fillStyle = COLOR_PLAYER_SKIN;
    c.fillRect(screenX - 7, screenY + 4 + bobY + (isMoving ? -armSwing : 0), 3, 2);
    c.fillRect(screenX + 4, screenY + 4 + bobY + (isMoving ? armSwing : 0), 3, 2);

    // Head
    c.fillStyle = COLOR_PLAYER_SKIN;
    c.fillRect(screenX - 4, screenY - 10 + bobY, 8, 7);
    // Chin shading
    c.fillStyle = '#e0b090';
    c.fillRect(screenX - 3, screenY - 4 + bobY, 6, 1);

    // Hair
    c.fillStyle = hairColor;
    // Top of hair
    c.fillRect(screenX - 5, screenY - 12 + bobY, 10, 4);
    // Side hair
    c.fillRect(screenX - 6, screenY - 10 + bobY, 2, 5);
    c.fillRect(screenX + 4, screenY - 10 + bobY, 2, 5);
    // Hair detail strands
    c.fillStyle = p.gender === GenderType.FEMALE ? '#5a2a7a' : '#7a4a2a';
    c.fillRect(screenX - 4, screenY - 11 + bobY, 2, 2);
    c.fillRect(screenX + 2, screenY - 11 + bobY, 2, 2);
    // Female long hair
    if (p.gender === GenderType.FEMALE) {
      c.fillStyle = hairColor;
      c.fillRect(screenX - 7, screenY - 8 + bobY, 2, 10);
      c.fillRect(screenX + 5, screenY - 8 + bobY, 2, 10);
      c.fillStyle = '#5a2a7a';
      c.fillRect(screenX - 6, screenY - 6 + bobY, 1, 6);
      c.fillRect(screenX + 5, screenY - 6 + bobY, 1, 6);
    }

    // Eyes
    const eyeOffX: number = facingRight ? 0 : -1;
    c.fillStyle = '#ffffff';
    c.fillRect(screenX - 2 + eyeOffX, screenY - 8 + bobY, 3, 3);
    c.fillRect(screenX + 1 + eyeOffX, screenY - 8 + bobY, 3, 3);
    // Pupils
    c.fillStyle = '#1a1a2e';
    c.fillRect(screenX - 1 + eyeOffX, screenY - 7 + bobY, 2, 2);
    c.fillRect(screenX + 2 + eyeOffX, screenY - 7 + bobY, 2, 2);
    // Eye shine
    c.fillStyle = '#ffffff';
    c.fillRect(screenX - 1 + eyeOffX, screenY - 8 + bobY, 1, 1);
    c.fillRect(screenX + 2 + eyeOffX, screenY - 8 + bobY, 1, 1);

    // Mouth
    c.fillStyle = '#c0846a';
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

    c.fillStyle = COLOR_DRILL_BASE;
    c.fillRect(baseX - 2, baseY - 2, 4, 4);

    const tipX: number = baseX + Math.cos(p.facing) * drillLen;
    const tipY: number = baseY + Math.sin(p.facing) * drillLen;
    c.strokeStyle = COLOR_DRILL_TIP;
    c.lineWidth = 3;
    c.beginPath();
    c.moveTo(baseX, baseY);
    c.lineTo(tipX, tipY);
    c.stroke();

    if (p.isDrilling) {
      c.fillStyle = COLOR_ATTACK_FLASH;
      c.globalAlpha = 0.6;
      c.beginPath();
      c.arc(tipX, tipY, 5 + Math.random() * 3, 0, Math.PI * 2);
      c.fill();
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

    const GHOST_LAYERS: number = 2;
    for (let g: number = GHOST_LAYERS; g >= 1; g--) {
      const scale: number = 1.0 - g * 0.15;
      const alpha: number = 0.18 - g * 0.04;
      this.drawWeaponEffect(c, form, sx, sy, bobY, p.facing, range * scale, width * scale, alpha);
    }

    const offX: number = Math.cos(p.facing) * range * 0.7;
    const offY: number = Math.sin(p.facing) * range * 0.7;
    const cx: number = sx + offX;
    const cy: number = sy + offY + bobY;

    c.globalAlpha = 0.65;

    if (form === WeaponForm.BLADE) {
      const arcStart: number = p.facing - 0.8;
      const arcEnd: number = p.facing + 0.8;
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 3;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.8, arcStart, arcEnd);
      c.stroke();
      c.strokeStyle = '#93c5fd';
      c.lineWidth = 1.5;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.6, arcStart, arcEnd);
      c.stroke();
    } else if (form === WeaponForm.WHIP) {
      const whipLen: number = range * 1.0;
      const perpX: number = -Math.sin(p.facing);
      const perpY: number = Math.cos(p.facing);
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(sx + Math.cos(p.facing) * 8, sy + bobY + Math.sin(p.facing) * 8);
      const cp1x: number = sx + Math.cos(p.facing) * whipLen * 0.5 + perpX * 12;
      const cp1y: number = sy + bobY + Math.sin(p.facing) * whipLen * 0.5 + perpY * 12;
      const endX: number = sx + Math.cos(p.facing) * whipLen;
      const endY: number = sy + bobY + Math.sin(p.facing) * whipLen;
      c.quadraticCurveTo(cp1x, cp1y, endX, endY);
      c.stroke();
    } else if (form === WeaponForm.HAMMER) {
      c.fillStyle = '#f97316';
      c.beginPath();
      c.arc(cx, cy, width * 0.5, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#fdba74';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(cx, cy, width * 0.7, 0, Math.PI * 2);
      c.stroke();
    } else if (form === WeaponForm.STAFF) {
      const boltX: number = sx + Math.cos(p.facing) * range;
      const boltY: number = sy + bobY + Math.sin(p.facing) * range;
      c.fillStyle = '#38bdf8';
      c.beginPath();
      c.arc(boltX, boltY, 5, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#7dd3fc';
      c.globalAlpha = 0.4;
      c.beginPath();
      c.arc(boltX, boltY, 9, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.DUAL_BLADES) {
      const perpX: number = -Math.sin(p.facing);
      const perpY: number = Math.cos(p.facing);
      c.strokeStyle = '#fb923c';
      c.lineWidth = 2.5;
      for (let side: number = -1; side <= 1; side += 2) {
        const arcCx: number = sx + perpX * 6 * side;
        const arcCy: number = sy + bobY + perpY * 6 * side;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.6, p.facing - 0.6, p.facing + 0.6);
        c.stroke();
      }
    } else if (form === WeaponForm.GREAT_AXE) {
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.9, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#fca5a5';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 1.1, 0, Math.PI * 2);
      c.stroke();
    }

    c.globalAlpha = 1.0;
  }

  private drawWeaponEffect(c: CanvasRenderingContext2D, form: WeaponForm, sx: number, sy: number, bobY: number, facing: number, range: number, width: number, alpha: number): void {
    c.globalAlpha = alpha;
    const offX: number = Math.cos(facing) * range * 0.7;
    const offY: number = Math.sin(facing) * range * 0.7;
    const cx: number = sx + offX;
    const cy: number = sy + offY + bobY;

    if (form === WeaponForm.BLADE) {
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.8, facing - 0.8, facing + 0.8);
      c.stroke();
    } else if (form === WeaponForm.WHIP) {
      const whipLen: number = range * 1.0;
      const perpX: number = -Math.sin(facing);
      const perpY: number = Math.cos(facing);
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(sx + Math.cos(facing) * 8, sy + bobY + Math.sin(facing) * 8);
      c.quadraticCurveTo(
        sx + Math.cos(facing) * whipLen * 0.5 + perpX * 12,
        sy + bobY + Math.sin(facing) * whipLen * 0.5 + perpY * 12,
        sx + Math.cos(facing) * whipLen,
        sy + bobY + Math.sin(facing) * whipLen
      );
      c.stroke();
    } else if (form === WeaponForm.HAMMER) {
      c.fillStyle = '#f97316';
      c.beginPath();
      c.arc(cx, cy, width * 0.5, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.STAFF) {
      c.fillStyle = '#38bdf8';
      c.beginPath();
      c.arc(sx + Math.cos(facing) * range, sy + bobY + Math.sin(facing) * range, 4, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.DUAL_BLADES) {
      const perpX: number = -Math.sin(facing);
      const perpY: number = Math.cos(facing);
      c.strokeStyle = '#fb923c';
      c.lineWidth = 1.5;
      for (let side: number = -1; side <= 1; side += 2) {
        c.beginPath();
        c.arc(sx + perpX * 6 * side, sy + bobY + perpY * 6 * side, range * 0.6, facing - 0.6, facing + 0.6);
        c.stroke();
      }
    } else if (form === WeaponForm.GREAT_AXE) {
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.9, 0, Math.PI * 2);
      c.fill();
    }
  }

  private renderWeaponOnPlayer(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const form: WeaponForm = p.currentWeaponForm;
    const handX: number = sx + 5;
    const handY: number = sy + 2 + bobY;
    const fAng: number = p.facing;
    const cosF: number = Math.cos(fAng);
    const sinF: number = Math.sin(fAng);

    c.globalAlpha = 0.85;

    if (form === WeaponForm.BLADE) {
      const len: number = 10;
      c.strokeStyle = '#93c5fd';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(handX + cosF * len, handY + sinF * len);
      c.stroke();
      c.strokeStyle = '#bfdbfe';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + cosF * 2, handY + sinF * 2);
      c.lineTo(handX + cosF * len, handY + sinF * len);
      c.stroke();
    } else if (form === WeaponForm.WHIP) {
      const len: number = 12;
      const perpX: number = -sinF;
      const perpY: number = cosF;
      c.strokeStyle = '#c4b5fd';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX, handY);
      const cpX: number = handX + cosF * len * 0.5 + perpX * 4;
      const cpY: number = handY + sinF * len * 0.5 + perpY * 4;
      const endX: number = handX + cosF * len;
      const endY: number = handY + sinF * len;
      c.quadraticCurveTo(cpX, cpY, endX, endY);
      c.stroke();
    } else if (form === WeaponForm.HAMMER) {
      const len: number = 7;
      c.strokeStyle = '#a3a3a3';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(handX + cosF * len, handY + sinF * len);
      c.stroke();
      c.fillStyle = '#78716c';
      const hx: number = handX + cosF * len;
      const hy: number = handY + sinF * len;
      c.fillRect(hx - 3, hy - 3, 6, 6);
    } else if (form === WeaponForm.STAFF) {
      const len: number = 14;
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(handX + cosF * len, handY + sinF * len);
      c.stroke();
      const orbX: number = handX + cosF * len;
      const orbY: number = handY + sinF * len;
      c.fillStyle = '#38bdf8';
      c.beginPath();
      c.arc(orbX, orbY, 2.5, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.3;
      c.fillStyle = '#7dd3fc';
      c.beginPath();
      c.arc(orbX, orbY, 4, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.DUAL_BLADES) {
      const len: number = 8;
      c.strokeStyle = '#fdba74';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(handX + cosF * len, handY + sinF * len);
      c.stroke();
      const handX2: number = sx - 5;
      c.beginPath();
      c.moveTo(handX2, handY);
      c.lineTo(handX2 + cosF * len, handY + sinF * len);
      c.stroke();
    } else if (form === WeaponForm.GREAT_AXE) {
      const len: number = 9;
      c.strokeStyle = '#a3a3a3';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(handX + cosF * len, handY + sinF * len);
      c.stroke();
      const axX: number = handX + cosF * len;
      const axY: number = handY + sinF * len;
      const perpX: number = -sinF;
      const perpY: number = cosF;
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.moveTo(axX + perpX * 4, axY + perpY * 4);
      c.lineTo(axX - perpX * 4, axY - perpY * 4);
      c.lineTo(axX + cosF * 5, axY + sinF * 5);
      c.closePath();
      c.fill();
    }

    c.globalAlpha = 1.0;
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

      const sc: number = s.size / 20;
      const bp: number = s.bouncePhase;
      const flash: boolean = s.hitFlash > 0;
      const cx: number = screenX;
      const cy: number = screenY;
      const halfW: number = this.screenW * 0.5;
      const halfH: number = this.screenH * 0.5;
      const dxCenter: number = screenX - halfW;
      const dyCenter: number = screenY - halfH;
      const lodThresholdSq: number = (halfW * halfW + halfH * halfH) * 0.35;
      const isDistant: boolean = (dxCenter * dxCenter + dyCenter * dyCenter) > lodThresholdSq;

      if (s.enemyType === EnemyType.GRAY_SLIME) {
        const bounce: number = Math.sin(bp) * 2 * sc;
        const squash: number = 1 + Math.sin(bp) * 0.08;
        c.save();
        c.translate(cx, cy + bounce);
        c.scale(squash, 1 / squash);
        c.globalAlpha = 0.2;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 12 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
        } else {
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_GRAY;
        }
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_GRAY_LIGHT;
          c.beginPath();
          c.ellipse(-3 * sc, -4 * sc, 6 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.4;
          c.beginPath();
          c.ellipse(-5 * sc, -6 * sc, 2 * sc, 1.5 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-4 * sc, -1 * sc, 2.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(4 * sc, -1 * sc, 2.5 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_PUPIL;
          c.beginPath();
          c.arc(-3.5 * sc, -0.5 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -0.5 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = COLOR_SLIME_PUPIL;
          c.lineWidth = 0.8;
          c.beginPath();
          c.arc(0, 3 * sc, 2 * sc, 0.1, Math.PI - 0.1);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.PURPLE_SLIME) {
        const bounce: number = Math.sin(bp * 1.3) * 1.5 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        if (!flash && !isDistant) {
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
        if (!isDistant) {
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
        }
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
        } else {
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_PURPLE;
        }
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_PURPLE_LIGHT;
          c.beginPath();
          c.ellipse(-3 * sc, -4 * sc, 7 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-4 * sc, -2 * sc, 2.8 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(4 * sc, -2 * sc, 2.8 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#ff0040';
          c.beginPath();
          c.arc(-3.5 * sc, -1.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1a1a2e';
          c.beginPath();
          c.arc(-3.5 * sc, -1.5 * sc, 0.8 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1.5 * sc, 0.8 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#4c1d95';
          c.lineWidth = 1.2 * sc;
          c.beginPath();
          c.moveTo(-7 * sc, -5 * sc);
          c.lineTo(-2 * sc, -4 * sc);
          c.stroke();
          c.beginPath();
          c.moveTo(7 * sc, -5 * sc);
          c.lineTo(2 * sc, -4 * sc);
          c.stroke();
          if (s.isEngulfing) {
            c.fillStyle = '#2d1060';
            c.beginPath();
            c.ellipse(0, 5 * sc, 5 * sc, 4 * sc, 0, 0, Math.PI * 2);
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
        if (!flash && !isDistant) {
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
        if (!flash && !isDistant) {
          for (let fi: number = 0; fi < 5; fi++) {
            const angle: number = -Math.PI * 0.8 + (fi / 4) * Math.PI * 0.6;
            const len: number = (5 + Math.sin(this.frameCount * 0.1 + fi) * 2) * sc;
            const sx: number = Math.cos(angle) * 12 * sc;
            const sy: number = Math.sin(angle) * 10 * sc;
            const ex: number = sx + Math.cos(angle) * len;
            const ey: number = sy + Math.sin(angle) * len;
            c.fillStyle = '#ff6600';
            c.globalAlpha = 0.7;
            c.beginPath();
            c.moveTo(sx - 1.5 * sc, sy);
            c.lineTo(ex, ey);
            c.lineTo(sx + 1.5 * sc, sy);
            c.closePath();
            c.fill();
          }
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
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-3.5 * sc, -1.5 * sc, 2.2 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(4 * sc, -1.5 * sc, 2.2 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#ffcc00';
          c.beginPath();
          c.arc(-3 * sc, -1 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1a1a2e';
          c.beginPath();
          c.arc(-3 * sc, -1 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#7f1d1d';
          c.lineWidth = 1 * sc;
          c.beginPath();
          c.moveTo(-3 * sc, 4 * sc);
          c.lineTo(-1 * sc, 3 * sc);
          c.lineTo(1 * sc, 4 * sc);
          c.lineTo(3 * sc, 3 * sc);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.BLUE_SLIME) {
        const bounce: number = Math.sin(bp * 0.8) * 1.5 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        if (!flash && !isDistant) {
          for (let d: number = 0; d < 5; d++) {
            const angle: number = (d / 5) * Math.PI * 2 + this.frameCount * 0.02;
            const dist: number = (16 + Math.sin(this.frameCount * 0.03 + d * 2) * 3) * sc;
            const dx: number = Math.cos(angle) * dist;
            const dy: number = Math.sin(angle) * dist * 0.7 - 2.5 * sc;
            c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
            c.globalAlpha = 0.4 + Math.sin(this.frameCount * 0.04 + d) * 0.2;
            c.beginPath();
            c.arc(dx, dy, 1.3 * sc, 0, Math.PI * 2);
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
        } else {
          c.globalAlpha = 0.75;
          c.fillStyle = COLOR_SLIME_BLUE;
        }
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash && !isDistant) {
          c.globalAlpha = 0.3;
          c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
          const rippleOff: number = Math.sin(this.frameCount * 0.04) * 1.5 * sc;
          c.beginPath();
          c.ellipse(0, rippleOff, 10 * sc, 7 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#93c5fd';
          c.lineWidth = 0.8 * sc;
          c.globalAlpha = 0.4;
          for (let w: number = 0; w < 2; w++) {
            const wy: number = (-2 + w * 5) * sc;
            const woff: number = Math.sin(this.frameCount * 0.05 + w) * 2 * sc;
            c.beginPath();
            c.moveTo(-7 * sc, wy + woff);
            c.quadraticCurveTo(0, wy - woff - 1.5 * sc, 7 * sc, wy + woff);
            c.stroke();
          }
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-3.5 * sc, -1 * sc, 2.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(3.5 * sc, -1 * sc, 2.5 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#1e40af';
          c.beginPath();
          c.arc(-3 * sc, -0.5 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4 * sc, -0.5 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#1e3a5f';
          c.lineWidth = 0.8;
          c.beginPath();
          c.arc(0, 2.5 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.YELLOW_SLIME) {
        const bounce: number = Math.abs(Math.sin(bp * 1.1)) * 3 * sc;
        c.save();
        c.translate(cx, cy - bounce);
        if (!flash && !isDistant) {
          c.globalAlpha = 0.08 + Math.sin(this.frameCount * 0.04) * 0.03;
          c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
          c.beginPath();
          c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
          c.fill();
          for (let sp: number = 0; sp < 6; sp++) {
            const angle: number = (sp / 6) * Math.PI * 2 + this.frameCount * 0.03;
            const dist: number = (14 + Math.sin(this.frameCount * 0.05 + sp * 3) * 4) * sc;
            const sx: number = Math.cos(angle) * dist;
            const sy: number = Math.sin(angle) * dist * 0.6;
            const sparkSize: number = (0.8 + Math.sin(this.frameCount * 0.08 + sp * 2) * 0.5) * sc;
            c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
            c.globalAlpha = 0.5 + Math.sin(this.frameCount * 0.06 + sp) * 0.3;
            c.beginPath();
            c.moveTo(sx, sy - sparkSize * 2);
            c.lineTo(sx + sparkSize * 0.5, sy - sparkSize * 0.5);
            c.lineTo(sx + sparkSize * 2, sy);
            c.lineTo(sx + sparkSize * 0.5, sy + sparkSize * 0.5);
            c.lineTo(sx, sy + sparkSize * 2);
            c.lineTo(sx - sparkSize * 0.5, sy + sparkSize * 0.5);
            c.lineTo(sx - sparkSize * 2, sy);
            c.lineTo(sx - sparkSize * 0.5, sy - sparkSize * 0.5);
            c.closePath();
            c.fill();
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
        } else {
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_YELLOW;
        }
        c.beginPath();
        c.ellipse(0, 0, 12 * sc, 10 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
          c.beginPath();
          c.ellipse(-2.5 * sc, -3.5 * sc, 5.5 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.5;
          c.beginPath();
          c.ellipse(-4 * sc, -5.5 * sc, 2 * sc, 1.5 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-3 * sc, -0.5 * sc, 2.2 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(3 * sc, -0.5 * sc, 2.2 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#92400e';
          c.beginPath();
          c.arc(-2.5 * sc, 0, 1 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.5 * sc, 0, 1 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#92400e';
          c.lineWidth = 0.8;
          c.beginPath();
          c.arc(0, 2.5 * sc, 3 * sc, 0.1, Math.PI - 0.1);
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
        const float: number = Math.sin(bp * 0.5) * 3 * sc;
        const phase: number = Math.sin(this.frameCount * 0.05) * 0.15;
        c.save();
        c.translate(cx, cy + float);
        if (!flash && !isDistant) {
          c.globalAlpha = 0.06 + Math.sin(this.frameCount * 0.04) * 0.03;
          c.fillStyle = COLOR_SLIME_GHOST;
          c.beginPath();
          c.ellipse(0, 0, 22 * sc, 20 * sc, 0, 0, Math.PI * 2);
          c.fill();
          for (let w: number = 0; w < 4; w++) {
            const wAngle: number = (w / 4) * Math.PI * 2 + this.frameCount * 0.02;
            const wDist: number = (10 + Math.sin(this.frameCount * 0.03 + w * 2) * 5) * sc;
            const wx: number = Math.cos(wAngle) * wDist;
            const wy: number = Math.sin(wAngle) * wDist * 0.5 + 5 * sc;
            c.fillStyle = COLOR_SLIME_GHOST_LIGHT;
            c.globalAlpha = 0.15 + Math.sin(this.frameCount * 0.05 + w) * 0.1;
            c.beginPath();
            c.ellipse(wx, wy, 2.5 * sc, 1.5 * sc, wAngle, 0, Math.PI * 2);
            c.fill();
          }
        }
        const bodyAlpha: number = flash ? 0.9 : (0.45 + phase);
        c.globalAlpha = bodyAlpha;
        if (flash) {
          c.fillStyle = '#ffffff';
        } else {
          c.fillStyle = COLOR_SLIME_GHOST;
        }
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
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_GHOST_LIGHT;
          c.globalAlpha = 0.2;
          c.beginPath();
          c.ellipse(0, -2 * sc, 7 * sc, 6 * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = flash ? 0.9 : 0.8;
        c.fillStyle = flash ? '#ffffff' : '#e2e8f0';
        c.beginPath();
        c.ellipse(-4 * sc, -3 * sc, 2.5 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -3 * sc, 2.5 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.9;
          c.beginPath();
          c.ellipse(-4 * sc, -2.5 * sc, 1.2 * sc, 1.5 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.ellipse(4 * sc, -2.5 * sc, 1.2 * sc, 1.5 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.6;
          c.beginPath();
          c.ellipse(0, 3 * sc, 2.5 * sc, (2 + Math.sin(this.frameCount * 0.04)) * sc, 0, 0, Math.PI * 2);
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
        const barW: number = s.size * 1.2;
        const barH: number = 4;
        const barY: number = screenY - s.size / 2 - 8;
        const barX: number = screenX - barW / 2;
        c.fillStyle = '#1a1a2e';
        c.fillRect(barX - 1, barY - 1, barW + 2, barH + 2);
        c.fillStyle = '#374151';
        c.fillRect(barX, barY, barW, barH);
        c.fillStyle = '#ef4444';
        c.fillRect(barX, barY, barW * (s.hp / s.maxHp), barH);
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
            c.fillStyle = COLOR_SPIKE;
            for (let s: number = 0; s < 5; s++) {
              const sx: number = screenX - 10 + s * 5;
              const sy: number = screenY + 6;
              c.beginPath();
              c.moveTo(sx - 3, sy);
              c.lineTo(sx, sy - 14);
              c.lineTo(sx + 3, sy);
              c.closePath();
              c.fill();
            }
            c.fillStyle = COLOR_SPIKE_TIP;
            for (let s: number = 0; s < 5; s++) {
              const sx: number = screenX - 10 + s * 5;
              const sy: number = screenY + 6;
              c.beginPath();
              c.moveTo(sx - 1, sy - 10);
              c.lineTo(sx, sy - 14);
              c.lineTo(sx + 1, sy - 10);
              c.closePath();
              c.fill();
            }
          } else {
            c.fillStyle = COLOR_SPIKE;
            c.globalAlpha = 0.3;
            c.fillRect(screenX - 12, screenY + 4, 24, 3);
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.FALLING_ROCKS:
          if (isActive) {
            c.fillStyle = COLOR_ROCK;
            for (let r: number = 0; r < 4; r++) {
              const rx: number = screenX - 8 + r * 6;
              const ry: number = screenY - 6 + Math.sin(r * 1.5) * 4;
              c.fillRect(rx, ry, 5, 5);
            }
          } else if (isTelegraph) {
            c.fillStyle = COLOR_ROCK;
            c.globalAlpha = 0.4;
            const fallProgress: number = 1.0 - (trap.timer / TRAP_TELEGRAPH_TIME);
            for (let r: number = 0; r < 3; r++) {
              const rx: number = screenX - 6 + r * 6;
              const ry: number = screenY - 30 + fallProgress * 24;
              c.fillRect(rx, ry, 4, 4);
            }
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.POISON_SPORES:
          if (isActive) {
            c.globalAlpha = 0.5;
            c.fillStyle = COLOR_POISON_CLOUD;
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.8, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 0.3;
            c.beginPath();
            c.arc(screenX + 4, screenY - 3, trap.size * 0.5, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.LAVA_GEYSER:
          if (isActive) {
            const geyserH: number = 20 + Math.sin(this.frameCount * 0.2) * 5;
            c.fillStyle = COLOR_LAVA_GEYSER;
            c.globalAlpha = 0.8;
            c.fillRect(screenX - 6, screenY - geyserH, 12, geyserH);
            c.globalAlpha = 0.4;
            c.fillStyle = COLOR_LAVA;
            c.fillRect(screenX - 10, screenY - geyserH * 0.6, 20, geyserH * 0.6);
            c.globalAlpha = 1.0;
          } else if (isTelegraph) {
            c.fillStyle = COLOR_LAVA_GEYSER;
            c.globalAlpha = 0.2;
            c.beginPath();
            c.arc(screenX, screenY, 8, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.VOID_CRACK:
          c.fillStyle = COLOR_VOID_CRACK;
          if (isActive) {
            c.globalAlpha = 0.7 + 0.3 * Math.sin(this.frameCount * 0.15);
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.6, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = COLOR_VOID_PULL;
            c.globalAlpha = 0.4;
            c.beginPath();
            c.arc(screenX, screenY, trap.triggerRadius * 1.2, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          } else {
            c.globalAlpha = 0.3;
            c.beginPath();
            c.arc(screenX, screenY, 6, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.WATER_VORTEX:
          if (isActive) {
            const spin: number = this.frameCount * 0.1;
            c.strokeStyle = COLOR_VORTEX;
            c.lineWidth = 2;
            c.globalAlpha = 0.7;
            for (let ring: number = 0; ring < 3; ring++) {
              const r: number = 4 + ring * 5;
              c.beginPath();
              c.arc(screenX, screenY, r, spin + ring, spin + ring + Math.PI * 1.2);
              c.stroke();
            }
            c.globalAlpha = 1.0;
            c.lineWidth = 1;
          } else {
            c.fillStyle = COLOR_VORTEX;
            c.globalAlpha = 0.2;
            c.beginPath();
            c.arc(screenX, screenY, 5, 0, Math.PI * 2);
            c.fill();
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
          c.fillStyle = mech.active ? COLOR_PLATE_ACTIVE : COLOR_PRESSURE_PLATE;
          c.globalAlpha = mech.active ? 0.9 : 0.5;
          c.fillRect(screenX - 10, screenY - 10, 20, 20);
          c.globalAlpha = 0.3;
          c.fillStyle = mech.active ? COLOR_PLATE_ACTIVE : COLOR_PRESSURE_PLATE;
          c.fillRect(screenX - 12, screenY - 12, 24, 24);
          c.globalAlpha = 1.0;
          break;

        case MechanismType.LEVER:
          c.fillStyle = COLOR_LEVER;
          c.fillRect(screenX - 3, screenY - 12, 6, 24);
          c.save();
          c.translate(screenX, screenY);
          c.rotate(mech.rotation * Math.PI / 180);
          c.fillStyle = COLOR_LEVER_HANDLE;
          c.fillRect(-2, -14, 4, 14);
          c.beginPath();
          c.arc(0, -14, 4, 0, Math.PI * 2);
          c.fill();
          c.restore();
          break;

        case MechanismType.PUSH_BLOCK:
          const bx: number = mech.posX + offX;
          const by: number = mech.posY + offY;
          c.fillStyle = COLOR_PUSH_BLOCK;
          c.fillRect(bx - 12, by - 12, 24, 24);
          c.strokeStyle = '#737373';
          c.lineWidth = 1;
          c.strokeRect(bx - 12, by - 12, 24, 24);
          c.fillStyle = '#737373';
          c.fillRect(bx - 4, by - 4, 3, 3);
          c.fillRect(bx + 2, by + 2, 3, 3);
          break;

        case MechanismType.CRYSTAL_REFLECTOR:
          c.save();
          c.translate(screenX, screenY);
          c.rotate(mech.rotation * Math.PI / 180);
          c.fillStyle = COLOR_REFLECTOR;
          c.beginPath();
          for (let v: number = 0; v < 6; v++) {
            const angle: number = (v / 6) * Math.PI * 2;
            const r: number = 10;
            if (v === 0) c.moveTo(Math.cos(angle) * r, Math.sin(angle) * r);
            else c.lineTo(Math.cos(angle) * r, Math.sin(angle) * r);
          }
          c.closePath();
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.5 + 0.3 * Math.sin(this.frameCount * 0.1);
          c.beginPath();
          c.arc(0, 0, 4, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.restore();
          break;

        case MechanismType.BREAKABLE_WALL:
          c.fillStyle = COLOR_BREAKABLE_WALL;
          c.fillRect(screenX - TILE_SIZE / 2, screenY - TILE_SIZE / 2, TILE_SIZE, TILE_SIZE);
          c.strokeStyle = '#3a3a55';
          c.lineWidth = 1;
          c.beginPath();
          c.moveTo(screenX - 8, screenY - 10);
          c.lineTo(screenX + 2, screenY + 4);
          c.moveTo(screenX + 6, screenY - 8);
          c.lineTo(screenX - 2, screenY + 8);
          c.stroke();
          break;

        case MechanismType.TELEPORT_RUNE:
          const runeColor: string = mech.active ? COLOR_TELEPORT_EXIT : COLOR_TELEPORT_ENTRY;
          const spin: number = this.frameCount * 0.03;
          c.strokeStyle = runeColor;
          c.lineWidth = 2;
          c.globalAlpha = 0.6;
          c.beginPath();
          c.arc(screenX, screenY, 12, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.4;
          c.beginPath();
          c.arc(screenX, screenY, 8, spin, spin + Math.PI * 1.5);
          c.stroke();
          c.fillStyle = COLOR_TELEPORT_RUNE;
          c.globalAlpha = 0.3 + 0.2 * Math.sin(this.frameCount * 0.08);
          c.beginPath();
          c.arc(screenX, screenY, 6, 0, Math.PI * 2);
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
      if (alpha < 0.05) continue;
      const sz: number = pt.size * alpha;
      if (sz < 0.5) continue;
      c.globalAlpha = alpha;
      c.fillStyle = pt.color;
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
    const isShadowBiome: boolean = playerBiome === BiomeType.SHADOW;

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
        if (isShadowBiome) {
          ap.color = Math.random() < 0.6 ? '#7c3aed40' : '#4c1d9540';
          ap.vy = -0.2 - Math.random() * 0.4;
        } else {
          const colors: string[] = ['#ffd70033', '#00ced133', '#ff69b433', '#4ade8033', '#60a5fa33'];
          ap.color = colors[Math.floor(Math.random() * colors.length)];
          ap.vy = -0.1 - Math.random() * 0.3;
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
      const s: number = ap.size;
      c.fillRect(ap.x - s, ap.y - s, s * 2, s * 2);
    }
    c.globalAlpha = 1.0;
  }

  private renderVignette(c: CanvasRenderingContext2D): void {
    const w: number = this.screenW;
    const h: number = this.screenH;
    if (this.vignetteGradCache === null || this.vignetteW !== w || this.vignetteH !== h) {
      const cx: number = w / 2;
      const cy: number = h / 2;
      const radius: number = Math.max(w, h) * 0.7;
      const gradient: CanvasGradient = c.createRadialGradient(cx, cy, radius * 0.4, cx, cy, radius);
      gradient.addColorStop(0, 'rgba(0,0,0,0)');
      gradient.addColorStop(1, 'rgba(0,0,0,0.45)');
      this.vignetteGradCache = gradient;
      this.vignetteW = w;
      this.vignetteH = h;
    }
    c.fillStyle = this.vignetteGradCache;
    c.fillRect(0, 0, w, h);
  }

  private renderMinimap(): void {
    if (this.minimapCtx === null || this.player === null) return;
    const mc: CanvasRenderingContext2D = this.minimapCtx;
    const size: number = MINIMAP_SIZE;
    const p: PlayerState = this.player;

    mc.fillStyle = COLOR_MINIMAP_BG;
    mc.fillRect(0, 0, size, size);

    const viewRange: number = 24;
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
      const color: string = this.getMaterialColor(drop.type);

      c.globalAlpha = 0.25;
      c.fillStyle = color;
      c.beginPath();
      c.arc(screenX, drawY, 10, 0, Math.PI * 2);
      c.fill();

      c.globalAlpha = 1.0;
      c.fillStyle = color;
      if (drop.type === MaterialType.CORE_RARE) {
        c.beginPath();
        c.moveTo(screenX, drawY - 6);
        c.lineTo(screenX + 5, drawY - 2);
        c.lineTo(screenX + 3, drawY + 5);
        c.lineTo(screenX - 3, drawY + 5);
        c.lineTo(screenX - 5, drawY - 2);
        c.closePath();
        c.fill();
        c.strokeStyle = '#fff8dc';
        c.lineWidth = 1;
        c.stroke();
      } else if (drop.type === MaterialType.FORM_CORE) {
        c.beginPath();
        c.arc(screenX, drawY, 5, 0, Math.PI * 2);
        c.fill();
        c.strokeStyle = '#ffffff';
        c.lineWidth = 1.5;
        c.stroke();
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.6 + 0.3 * Math.sin(this.frameCount * 0.1 + drop.bobPhase);
        c.beginPath();
        c.arc(screenX, drawY, 3, 0, Math.PI * 2);
        c.fill();
      } else if (drop.type === MaterialType.CORE_NORMAL) {
        c.beginPath();
        c.moveTo(screenX, drawY - 5);
        c.lineTo(screenX + 5, drawY);
        c.lineTo(screenX, drawY + 5);
        c.lineTo(screenX - 5, drawY);
        c.closePath();
        c.fill();
        c.strokeStyle = '#e2e8f0';
        c.lineWidth = 1;
        c.stroke();
      } else if (drop.type === MaterialType.CRYSTAL_ORE) {
        c.beginPath();
        c.moveTo(screenX, drawY - 6);
        c.lineTo(screenX + 4, drawY);
        c.lineTo(screenX, drawY + 6);
        c.lineTo(screenX - 4, drawY);
        c.closePath();
        c.fill();
        c.strokeStyle = '#e0ffff';
        c.lineWidth = 1;
        c.stroke();
      } else if (drop.type === MaterialType.FLAME_ORE) {
        c.beginPath();
        c.moveTo(screenX, drawY - 6);
        c.quadraticCurveTo(screenX + 5, drawY - 2, screenX + 3, drawY + 4);
        c.lineTo(screenX, drawY + 2);
        c.lineTo(screenX - 3, drawY + 4);
        c.quadraticCurveTo(screenX - 5, drawY - 2, screenX, drawY - 6);
        c.fill();
      } else if (drop.type === MaterialType.MUSHROOM_ORE) {
        c.beginPath();
        c.arc(screenX, drawY - 2, 5, Math.PI, 0);
        c.fill();
        c.fillRect(screenX - 2, drawY - 2, 4, 5);
      } else if (drop.type === MaterialType.ABYSS_ORE) {
        c.beginPath();
        c.moveTo(screenX, drawY - 5);
        c.lineTo(screenX + 4, drawY - 1);
        c.lineTo(screenX + 2, drawY + 5);
        c.lineTo(screenX - 2, drawY + 5);
        c.lineTo(screenX - 4, drawY - 1);
        c.closePath();
        c.fill();
        c.strokeStyle = '#6366f1';
        c.lineWidth = 1;
        c.stroke();
      } else if (drop.type === MaterialType.VOID_ORE) {
        c.beginPath();
        c.arc(screenX, drawY, 5, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = '#1a0a2e';
        c.beginPath();
        c.arc(screenX, drawY, 2.5, 0, Math.PI * 2);
        c.fill();
      } else {
        c.fillRect(screenX - 4, drawY - 4, 8, 8);
        c.strokeStyle = '#ffffff';
        c.lineWidth = 1;
        c.strokeRect(screenX - 4, drawY - 4, 8, 8);
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderFloatingTexts(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.floatingTexts.length; i++) {
      const ft: FloatingText = this.floatingTexts[i];
      const alpha: number = Math.max(ft.life / ft.maxLife, 0);
      const screenX: number = ft.x + offX;
      const screenY: number = ft.y + offY;
      c.globalAlpha = alpha;
      c.fillStyle = ft.color;
      c.font = '10px sans-serif';
      c.textAlign = 'center';
      c.fillText(ft.text, screenX, screenY);
    }
    c.globalAlpha = 1.0;
    c.textAlign = 'left';
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
    if (boss.bossType === BossType.CRYSTAL_GUARDIAN) name = '水晶守卫';
    else if (boss.bossType === BossType.MUSHROOM_KING) name = '蘑菇王';
    else if (boss.bossType === BossType.LAVA_BEAST) name = '熔岩兽';
    else if (boss.bossType === BossType.ABYSS_SIREN) name = '深渊海妖';
    else if (boss.bossType === BossType.VOID_RIFT) name = '虚空裂隙';
    if (boss.phase === BossPhase.PHASE_2) name += ' [狂暴]';
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
      const distSq: number = dx * dx + dy * dy;

      if (distSq < CHEST_INTERACT_RANGE * CHEST_INTERACT_RANGE) {
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
      for (let k: number = 0; k < 12; k++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 1 + Math.random() * 2;
        this.spawnParticle(chest.x, chest.y,
          Math.cos(angle) * speed, -2 - Math.random() * 3,
          600, COLOR_CHEST_GLOW, 3);
      }
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
      for (let k: number = 0; k < 5; k++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 0.5 + Math.random();
        this.spawnParticle(x, y - 10,
          Math.cos(angle) * speed, -1.5 - Math.random(),
          400, '#ffd700', 2);
      }
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
      for (let k: number = 0; k < 20; k++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 2 + Math.random() * 4;
        this.spawnParticle(p.x, p.y,
          Math.cos(angle) * speed, Math.sin(angle) * speed,
          800, this.getBranchColor(branch), 3 + Math.random() * 3);
      }
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
    if (this.player === null) return ['无玩家'];
    const p: PlayerState = this.player;
    const branchNames: string[] = ['水晶', '火焰', '暗影', '剧毒', '潮汐'];
    const branch: string = branchNames[p.evolutionBranch] || '未知';
    const level: number = p.evolutionLevel;
    const info: string[] = [];
    info.push('分支: ' + branch);
    info.push('等级: ' + level + '/3');
    if (level < 3) {
      const next: number = level + 1;
      const oreNeeded: number = EVOLUTION_COST_ORE[next];
      const normalNeeded: number = EVOLUTION_COST_NORMAL[next];
      const rareNeeded: number = EVOLUTION_COST_RARE[next];
      const oreHave: number = this.getOreCount(p.inventory, p.evolutionBranch);
      info.push('矿石: ' + oreHave + '/' + oreNeeded);
      info.push('核心: ' + p.inventory.coreNormal + '/' + normalNeeded);
      info.push('稀有: ' + p.inventory.coreRare + '/' + rareNeeded);
    } else {
      info.push('满级');
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
    const form: TransformForm = p.transformForm;
    const speed: number = TRANSFORM_SPEEDS[form as number];

    if (form === TransformForm.IRON_MAN) {
      // Flight: direct movement in all directions, no gravity
      p.vx = moveX * speed;
      p.vy = moveY * speed;
    } else if (form === TransformForm.GHOST) {
      // Ghost: normal movement but no wall collision
      p.vx = moveX * speed;
      p.vy = moveY * speed;
    } else if (form === TransformForm.SLIME) {
      // Slime: normal movement with higher speed
      if (p.isDashing) {
        p.dashTimer -= dt;
        if (p.dashTimer <= 0) p.isDashing = false;
        else {
          p.vx = p.dashDirX * DASH_SPEED;
          p.vy = p.dashDirY * DASH_SPEED;
        }
      } else {
        p.vx = moveX * speed;
        p.vy = moveY * speed;
      }
    } else {
      // ARMOR: slower, heavy feel
      if (p.isDashing) {
        p.dashTimer -= dt;
        if (p.dashTimer <= 0) p.isDashing = false;
        else {
          p.vx = p.dashDirX * DASH_SPEED * 1.5;
          p.vy = p.dashDirY * DASH_SPEED * 1.5;
          // Dash damage to enemies
          this.checkTransformDashDamage(p);
        }
      } else {
        p.vx = moveX * speed;
        p.vy = moveY * speed;
      }
    }

    // Facing direction
    if (Math.abs(moveX) > 0.1 || Math.abs(moveY) > 0.1) {
      p.facing = Math.atan2(moveY, moveX);
    }

    // Jump timer
    if (p.isJumping) {
      p.jumpTimer -= dt;
      if (form === TransformForm.SLIME) {
        p.jumpHeight = Math.sin((1 - p.jumpTimer / 400) * Math.PI) * 16;
      } else {
        p.jumpHeight = Math.sin((1 - p.jumpTimer / 300) * Math.PI) * 8;
      }
      if (p.jumpTimer <= 0) {
        p.isJumping = false;
        p.jumpHeight = 0;
      }
    }
  }

  private applyTransformCollision(p: PlayerState): void {
    const newX: number = p.x + p.vx;
    const newY: number = p.y + p.vy;

    if (p.transformForm === TransformForm.GHOST) {
      // Ghost: no wall collision — phase through everything
      p.x = newX;
      p.y = newY;
    } else if (p.transformForm === TransformForm.IRON_MAN) {
      // Iron Man: wall collision but ignore terrain damage
      if (!this.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      }
      if (!this.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      }
    } else if (p.transformForm === TransformForm.SLIME) {
      // Slime: wall bounce
      if (!this.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      } else {
        p.vx = -p.vx; // Bounce off wall
      }
      if (!this.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      } else {
        p.vy = -p.vy;
      }
    } else {
      // ARMOR: normal collision
      if (!this.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      }
      if (!this.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      }
    }
  }

  private handleTransformAttack(p: PlayerState): void {
    const form: TransformForm = p.transformForm;
    const formIndex: number = form as number;
    const cost: number = TRANSFORM_ATTACK_COSTS[formIndex];
    const cooldown: number = TRANSFORM_ATTACK_COOLDOWNS[formIndex];

    if (p.transformFormAttackCooldown > 0) return;
    if (p.transformEnergy < cost) return;

    p.transformEnergy -= cost;
    p.transformFormAttackCooldown = cooldown;
    p.isAttacking = true;
    p.attackTimer = ATTACK_DURATION;

    const cosF: number = Math.cos(p.facing);
    const sinF: number = Math.sin(p.facing);

    if (form === TransformForm.SLIME) {
      // Split Shot: 3 small slimes shoot outward
      for (let i: number = -1; i <= 1; i++) {
        const spreadAngle: number = p.facing + i * 0.3;
        const sx: number = Math.cos(spreadAngle);
        const sy: number = Math.sin(spreadAngle);
        // Spawn projectile-like particles that damage enemies
        for (let d: number = 0; d < 80; d += 8) {
          const px: number = p.x + sx * d;
          const py: number = p.y + sy * d;
          this.damageEnemiesAt(px, py, 10, 2);
        }
        if (this.settings.effectsEnabled) {
          for (let d: number = 0; d < 60; d += 12) {
            this.spawnParticle(p.x + sx * d, p.y + sy * d,
              sx * 0.5, sy * 0.5, 300, COLOR_TRANSFORM_SLIME, 4);
          }
        }
      }
    } else if (form === TransformForm.GHOST) {
      // Soul Shockwave: expanding ring
      if (this.settings.effectsEnabled) {
        for (let a: number = 0; a < Math.PI * 2; a += 0.3) {
          this.spawnParticle(p.x + Math.cos(a) * 20, p.y + Math.sin(a) * 20,
            Math.cos(a) * 2, Math.sin(a) * 2, 400, COLOR_TRANSFORM_GHOST, 3);
        }
      }
      this.damageEnemiesInRadius(p.x, p.y, 80, 3);
    } else if (form === TransformForm.ARMOR) {
      // Rider Kick: charge forward 60px
      const chargeDist: number = 60;
      for (let d: number = 0; d < chargeDist; d += 6) {
        const cx: number = p.x + cosF * d;
        const cy: number = p.y + sinF * d;
        this.damageEnemiesAt(cx, cy, 12, 5);
      }
      // Move player forward
      p.x += cosF * chargeDist;
      p.y += sinF * chargeDist;
      if (this.settings.effectsEnabled) {
        for (let d: number = 0; d < chargeDist; d += 10) {
          this.spawnParticle(p.x - cosF * d, p.y - sinF * d,
            (Math.random() - 0.5) * 2, (Math.random() - 0.5) * 2, 400, COLOR_TRANSFORM_ARMOR_ACCENT, 4);
        }
      }
      this.shakeTimer = 150;
    } else if (form === TransformForm.IRON_MAN) {
      // Repulsor Beam: projectile traveling 150px
      const beamLen: number = 150;
      for (let d: number = 0; d < beamLen; d += 6) {
        const bx: number = p.x + cosF * d;
        const by: number = p.y + sinF * d;
        this.damageEnemiesAt(bx, by, 8, 3);
      }
      if (this.settings.effectsEnabled) {
        for (let d: number = 0; d < beamLen; d += 10) {
          this.spawnParticle(p.x + cosF * d, p.y + sinF * d,
            cosF * 0.3 + (Math.random() - 0.5), sinF * 0.3 + (Math.random() - 0.5),
            250, COLOR_TRANSFORM_IRON_GOLD, 3);
        }
      }
    }
  }

  private damageEnemiesAt(x: number, y: number, radius: number, damage: number): void {
    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;
      const dx: number = s.x - x;
      const dy: number = s.y - y;
      if (dx * dx + dy * dy < radius * radius) {
        s.hp -= damage;
        s.hitFlash = 200;
        if (this.settings.effectsEnabled) {
          this.spawnParticle(s.x, s.y, 0, -1, 300, COLOR_DAMAGE_PARTICLE, 3);
        }
        if (s.hp <= 0) {
          this.onEnemyDeath(s);
        }
      }
    }
    // Also damage bosses
    for (let i: number = 0; i < this.bosses.length; i++) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;
      const dx: number = boss.x - x;
      const dy: number = boss.y - y;
      if (dx * dx + dy * dy < radius * radius) {
        boss.hp -= damage;
        boss.hitFlash = 200;
        if (this.settings.effectsEnabled) {
          this.spawnParticle(boss.x, boss.y, 0, -1, 300, COLOR_DAMAGE_PARTICLE, 3);
        }
      }
    }
  }

  private damageEnemiesInRadius(cx: number, cy: number, radius: number, damage: number): void {
    this.damageEnemiesAt(cx, cy, radius, damage);
  }

  private checkTransformDashDamage(p: PlayerState): void {
    // Armor dash: damage enemies in path
    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;
      const dx: number = s.x - p.x;
      const dy: number = s.y - p.y;
      if (dx * dx + dy * dy < 30 * 30) {
        s.hp -= 1;
        s.hitFlash = 200;
        if (s.hp <= 0) {
          this.onEnemyDeath(s);
        }
      }
    }
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
}
