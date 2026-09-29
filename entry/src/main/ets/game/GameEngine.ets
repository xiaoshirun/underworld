import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_MAX_HP, LEVEL_UP_XP,
  FRAME_INTERVAL, MINIMAP_UPDATE_INTERVAL,
  TileType, BiomeType, PlayerState, SlimeState,
  ChunkData, GameSettings, AmbientParticle,
  GenderType, WeaponForm, EvolutionBranch, EvolutionLevel,
  BossState, BossRoom, Inventory, TransformUnlockNotify,
  BossType, EVOLUTION_COST_ORE, EVOLUTION_COST_NORMAL, EVOLUTION_COST_RARE,
  COLOR_BG, TransformForm, TRANSFORM_MAX_ENERGY,
  GameState, SaveData, AUTO_SAVE_INTERVAL,
} from './GameConstants';
import { EngineBase } from '../engine/EngineBase';
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
import { EnemyRenderer } from './renderers/EnemyRenderer';
import { BossRenderer } from './renderers/BossRenderer';
import { EffectRenderer } from './renderers/EffectRenderer';
import { UIRenderer } from './renderers/UIRenderer';

export class GameEngine extends EngineBase implements MovementBridge, TransformBridge, BossBridge, MechanismBridge, DamageBridge, ChestBridge, SaveLoadBridge {
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
  private enemyRenderer: EnemyRenderer | null = null;
  private bossRenderer: BossRenderer | null = null;
  private effectRenderer: EffectRenderer | null = null;
  private uiRenderer: UIRenderer | null = null;

  protected onInit(): void {
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

    this.cameraX = startX - this.screenW / 2;
    this.cameraY = startY - this.screenH / 2;

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
    this.enemyRenderer = new EnemyRenderer(this);
    this.bossRenderer = new BossRenderer(this);
    this.effectRenderer = new EffectRenderer(this);
    this.uiRenderer = new UIRenderer(this);
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

  setGender(g: GenderType): void {
    this.playerGender = g;
    if (this.player !== null) {
      this.player.gender = g;
    }
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


  update(dt: number): void {
    if (this.player === null) {
      return;
    }
    if (this.state !== GameState.PLAYING) {
      return;
    }
    const p: PlayerState = this.player;

    this.rebuildSpatialGrids();
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

  performAttack(p: PlayerState): void {
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

  render(): void {
    if (this.ctx === null || this.player === null) {
      return;
    }
    const c: CanvasRenderingContext2D = this.ctx;
    const p: PlayerState = this.player;

    c.clearRect(0, 0, this.screenW, this.screenH);
    c.fillStyle = COLOR_BG;
    c.fillRect(0, 0, this.screenW, this.screenH);

    const offX: number = -this.cameraX + this.shakeX;
    const offY: number = -this.cameraY + this.shakeY;

    this.tileRenderer!.render(c, offX, offY);
    this.effectRenderer!.renderLighting(c, offX, offY, p);
    this.enemyRenderer!.render(c, offX, offY);
    this.effectRenderer!.render(c, offX, offY);
    this.bossRenderer!.render(c, offX, offY);
    this.playerRenderer!.render(c, offX, offY, p);
    this.effectRenderer!.renderParticles(c, offX, offY);
    this.particleMgr.render(c, offX, offY);
    this.effectRenderer!.renderAmbient(c);
    this.effectRenderer!.renderVignetteAndDamage(c, p);
    this.bossRenderer!.renderHPBar(c);

    if (this.frameCount % MINIMAP_UPDATE_INTERVAL === 0) {
      this.uiRenderer!.renderMinimap();
    }
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

  // ==================== Boss Rendering ====================

  // ==================== Chest System ====================

  private updateChestAnims(dt: number): void {
    this.chestSystem!.updateAnims(dt);
  }

  private checkChestInteraction(): void {
    this.chestSystem!.checkInteraction();
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

  getEvoBranch(): number {
    return this.evolutionSystem!.getEvoBranch();
  }

  getEvoLevel(): number {
    return this.evolutionSystem!.getEvoLevel();
  }

  getEvoOreHave(): number {
    return this.evolutionSystem!.getEvoOreHave();
  }

  getEvoOreHaveForBranch(branch: number): number {
    return this.evolutionSystem!.getEvoOreHaveForBranch(branch);
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

  updateTransformMovement(p: PlayerState, dt: number, moveX: number, moveY: number): void {
    this.transformSystem!.updateMovement(p, dt, moveX, moveY);
  }

  applyTransformCollision(p: PlayerState): void {
    this.transformSystem!.applyCollision(p);
  }

  handleTransformAttack(p: PlayerState): void {
    this.transformSystem!.handleAttack(p);
  }

  activateTransform(form: TransformForm): void {
    this.transformSystem!.activate(form);
  }

  deactivateTransform(): void {
    this.transformSystem!.deactivate();
  }

  onEnemyDeath(s: SlimeState): void {
    this.combatSystem!.onEnemyDeath(s);
  }

  checkPlayerCollision(x: number, y: number): boolean {
    return this.movementSystem!.checkPlayerCollision(x, y);
  }


  // ==================== State Machine ====================

  getPlayer(): PlayerState | null {
    return this.player;
  }

  setOnStateChange(cb: (state: GameState) => void): void {
    this.onStateChange = cb;
  }

  setOnSave(cb: () => void): void {
    this.onSave = cb;
  }

  setState(newState: GameState): void {
    this.state = newState;
    if (this.onStateChange) {
      this.onStateChange(newState);
    }
  }

  pause(): void {
    if (this.state !== GameState.PLAYING) return;
    this.autoSave();
    this.setState(GameState.PAUSED);
    this.stopLoop();
  }

  resume(): void {
    if (this.state !== GameState.PAUSED) return;
    this.setState(GameState.PLAYING);
    this.startLoop();
  }

  quit(): void {
    this.autoSave();
    this.stopLoop();
    this.setState(GameState.LOADING);
  }

  restart(): void {
    this.stopLoop();
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
    this.frameCount = 0;
    this.setState(GameState.PLAYING);
    if (this.ctx && this.minimapCtx) {
      this.init(this.ctx, this.minimapCtx, this.screenW, this.screenH, this.context ?? undefined);
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
