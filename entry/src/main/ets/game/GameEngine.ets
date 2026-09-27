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
import { EnemyAISystem } from './systems/EnemyAISystem';
import { BossSystem, BossBridge } from './systems/BossSystem';
import { TrapSystem } from './systems/TrapSystem';
import { MechanismSystem, MechanismBridge } from './systems/MechanismSystem';
import { ChunkLoadSystem } from './systems/ChunkLoadSystem';
import { DamageSystem, DamageBridge } from './systems/DamageSystem';
import { XpLevelSystem } from './systems/XpLevelSystem';
import { ChestSystem, ChestBridge } from './systems/ChestSystem';
import { MaterialDropSystem } from './systems/MaterialDropSystem';
import { EvolutionSystem } from './systems/EvolutionSystem';
import { SaveLoadSystem, SaveLoadBridge } from './systems/SaveLoadSystem';
import { TileRenderer } from './renderers/TileRenderer';
import { PlayerRenderer } from './renderers/PlayerRenderer';

export class GameEngine extends GameContext implements MovementBridge, TransformBridge, BossBridge, MechanismBridge, DamageBridge, ChestBridge, SaveLoadBridge {
  private movementSystem: PlayerMovementSystem | null = null;
  private combatSystem: PlayerCombatSystem | null = null;
  private transformSystem: TransformSystem | null = null;
  private enemyAISystem: EnemyAISystem | null = null;
  private bossSystem: BossSystem | null = null;
  private trapSystem: TrapSystem | null = null;
  private mechanismSystem: MechanismSystem | null = null;
  private chunkLoadSystem: ChunkLoadSystem | null = null;
  private damageSystem: DamageSystem | null = null;
  private xpLevelSystem: XpLevelSystem | null = null;
  private chestSystem: ChestSystem | null = null;
  private materialDropSystem: MaterialDropSystem | null = null;
  private evolutionSystem: EvolutionSystem | null = null;
  private saveLoadSystem: SaveLoadSystem | null = null;
  private tileRenderer: TileRenderer | null = null;
  private playerRenderer: PlayerRenderer | null = null;

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
    this.enemyAISystem = new EnemyAISystem(this);
    this.bossSystem = new BossSystem(this, this);
    this.trapSystem = new TrapSystem(this);
    this.mechanismSystem = new MechanismSystem(this, this);
    this.chunkLoadSystem = new ChunkLoadSystem(this);
    this.damageSystem = new DamageSystem(this, this);
    this.xpLevelSystem = new XpLevelSystem(this);
    this.chestSystem = new ChestSystem(this, this);
    this.materialDropSystem = new MaterialDropSystem(this);
    this.evolutionSystem = new EvolutionSystem(this);
    this.saveLoadSystem = new SaveLoadSystem(this, this);
    this.tileRenderer = new TileRenderer(this);
    this.playerRenderer = new PlayerRenderer(this);
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


  private update(dt: number): void {
    if (this.player === null) return;
    if (this.state !== GameState.PLAYING) return;
    const p: PlayerState = this.player;

    this.chunkLoadSystem!.update();
    this.damageSystem!.update(dt);

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
    this.enemyAISystem!.update(dt);
  }

  private updateXpOrbs(dt: number): void {
    this.xpLevelSystem!.update(dt);
  }

  private updateTraps(dt: number): void {
    this.trapSystem!.update(dt);
  }

  private updateMechanisms(dt: number): void {
    this.mechanismSystem!.update(dt);
  }

  checkBreakableWalls(p: PlayerState): void {
    this.movementSystem!.checkBreakableWalls(p);
  }

  // ==================== Boss System ====================

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
    this.bossSystem!.update(dt);
  }

  getCoreForBoss(bossType: BossType): TransformForm {
    return this.transformSystem!.getCoreForBoss(bossType);
  }

  private collectMaterialDrops(p: PlayerState): void {
    this.materialDropSystem!.update(p);
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

    this.tileRenderer!.render(c, offX, offY);
    this.renderLighting(c, offX, offY, p);
    this.renderXpOrbs(c, offX, offY);
    this.renderTraps(c, offX, offY);
    this.renderMechanisms(c, offX, offY);
    this.renderChests(c, offX, offY);
    this.renderEnemies(c, offX, offY);
    this.renderBosses(c, offX, offY);
    this.renderMaterialDrops(c, offX, offY);
    this.playerRenderer!.render(c, offX, offY, p);
    this.renderParticles(c, offX, offY);
    this.particleMgr.render(c, offX, offY);
    this.renderAmbientParticles(c);
    this.renderVignette(c, p);
    this.renderBossHPBar(c);

    if (this.frameCount % MINIMAP_UPDATE_INTERVAL === 0) {
      this.renderMinimap();
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
    this.chestSystem!.updateAnims(dt);
  }

  private checkChestInteraction(): void {
    this.chestSystem!.checkInteraction();
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

  // ==================== Evolution System ====================

  canEvolve(): boolean {
    return this.evolutionSystem!.canEvolve();
  }

  tryEvolveWeapon(): boolean {
    return this.evolutionSystem!.tryEvolveWeapon();
  }

  unlockWeaponForm(form: WeaponForm): boolean {
    return this.evolutionSystem!.unlockWeaponForm(form);
  }

  getEvolutionInfo(): string[] {
    return this.evolutionSystem!.getEvolutionInfo();
  }

  getEvoBranch(): number {
    return this.evolutionSystem!.getEvoBranch();
  }

  getEvoLevel(): number {
    return this.evolutionSystem!.getEvoLevel();
  }

  getEvoOreHave(): number {
    return this.evolutionSystem!.getEvoOreHave();
  }
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
    return this.saveLoadSystem!.getSaveData();
  }

  applySaveData(data: SaveData): void {
    this.saveLoadSystem!.applySaveData(data);
  }

  getExploredChunks(): string[] {
    return this.saveLoadSystem!.getExploredChunks();
  }

  async autoSave(): Promise<void> {
    await this.saveLoadSystem!.autoSave();
  }

}
