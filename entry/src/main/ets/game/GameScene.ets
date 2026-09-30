import { Scene, BaseContext, World, Entity, SystemContext } from '@qiuyu/engine';
import { AudioManager } from './AudioManager';
import { GameSettings, CHUNK_SIZE, TILE_SIZE } from './GameConstants';
import { WorldGenerator } from './WorldGenerator';
import { PlayerFactory } from './factories/PlayerFactory';
import { CameraComponent } from './components/CameraComponent';
import { GameStateComponent } from './components/GameStateComponent';

// Systems
import { SpatialRebuildSystem } from './systems/SpatialRebuildSystem';
import { ChunkLoadSystem } from './systems/ChunkLoadSystem';
import { PlayerMovementSystem } from './systems/PlayerMovementSystem';
import { PlayerCombatSystem } from './systems/PlayerCombatSystem';
import { EnemyAISystem } from './systems/EnemyAISystem';
import { BossSystem } from './systems/BossSystem';
import { TransformSystem } from './systems/TransformSystem';
import { TrapSystem } from './systems/TrapSystem';
import { MechanismSystem } from './systems/MechanismSystem';
import { ChestSystem } from './systems/ChestSystem';
import { MaterialDropSystem } from './systems/MaterialDropSystem';
import { XpLevelSystem } from './systems/XpLevelSystem';
import { DamageSystem } from './systems/DamageSystem';
import { EvolutionSystem } from './systems/EvolutionSystem';
import { CameraSystem } from './systems/CameraSystem';
import { ParticleSystem } from './systems/ParticleSystem';
import { AmbientParticleSystem } from './systems/AmbientParticleSystem';
import { SaveLoadSystem } from './systems/SaveLoadSystem';
import { CleanupSystem } from './systems/CleanupSystem';

// Renderers
import { TileRenderer } from './renderers/TileRenderer';
import { EffectRenderer } from './renderers/EffectRenderer';
import { EnemyRenderer } from './renderers/EnemyRenderer';
import { BossRenderer } from './renderers/BossRenderer';
import { PlayerRenderer } from './renderers/PlayerRenderer';
import { UIRenderer } from './renderers/UIRenderer';

export class GameScene extends Scene {
  private world: World;
  private audio: AudioManager;
  private settings: GameSettings;
  private saveLoadSystem: SaveLoadSystem;
  private evolutionSystem: EvolutionSystem;
  private tileRenderer: TileRenderer = new TileRenderer();
  private effectRenderer: EffectRenderer = new EffectRenderer();
  private enemyRenderer: EnemyRenderer = new EnemyRenderer();
  private bossRenderer: BossRenderer = new BossRenderer();
  private playerRenderer: PlayerRenderer = new PlayerRenderer();
  private uiRenderer: UIRenderer = new UIRenderer();

  private playerGender: number = 0;

  constructor(audio: AudioManager, settings: GameSettings, harmonyContext: Object | null = null) {
    super();
    this.audio = audio;
    this.settings = settings;
    this.world = new World();

    // Initialize world generator
    const worldGen: WorldGenerator = new WorldGenerator();
    this.world.worldGen = worldGen;

    // Create singleton entities
    const startX: number = CHUNK_SIZE * TILE_SIZE / 2;
    const startY: number = CHUNK_SIZE * TILE_SIZE / 2;

    this.world.addEntity(PlayerFactory.create(startX, startY));

    const cameraEntity: Entity = new Entity("camera");
    cameraEntity.addComponent(new CameraComponent());
    this.world.addEntity(cameraEntity);

    const gameStateEntity: Entity = new Entity("gameState");
    gameStateEntity.addComponent(new GameStateComponent());
    this.world.addEntity(gameStateEntity);

    // Register 19 systems in execution order
    this.world.addSystem(new SpatialRebuildSystem());
    this.world.addSystem(new ChunkLoadSystem());
    this.world.addSystem(new PlayerMovementSystem());
    this.world.addSystem(new PlayerCombatSystem());
    this.world.addSystem(new EnemyAISystem());
    this.world.addSystem(new BossSystem());
    this.world.addSystem(new TransformSystem());
    this.world.addSystem(new TrapSystem());
    this.world.addSystem(new MechanismSystem());
    this.world.addSystem(new ChestSystem());
    this.world.addSystem(new MaterialDropSystem());
    this.world.addSystem(new XpLevelSystem());
    this.world.addSystem(new DamageSystem());
    this.evolutionSystem = new EvolutionSystem();
    this.world.addSystem(this.evolutionSystem);
    this.world.addSystem(new CameraSystem());
    this.world.addSystem(new ParticleSystem());
    this.world.addSystem(new AmbientParticleSystem());
    this.saveLoadSystem = new SaveLoadSystem();
    this.saveLoadSystem.harmonyContext = harmonyContext;
    this.world.addSystem(this.saveLoadSystem);
    this.world.addSystem(new CleanupSystem());

    // Initialize camera position
    this.world.cameraX = startX - 360 / 2;
    this.world.cameraY = startY - 780 / 2;
  }

  update(baseCtx: BaseContext, dt: number): void {
    const sysCtx: SystemContext = {
      world: this.world,
      ctx: baseCtx.ctx,
      minimapCtx: baseCtx.minimapCtx,
      screenW: baseCtx.screenW,
      screenH: baseCtx.screenH,
      cameraX: this.world.cameraX,
      cameraY: this.world.cameraY,
      input: baseCtx.input,
      resources: baseCtx.resources,
      audio: this.audio as Object,
      settings: this.settings as Object,
      frameCount: baseCtx.frameCount,
      dt: dt
    };
    this.world.update(sysCtx, dt);
  }

  render(baseCtx: BaseContext): void {
    const camX: number = this.world.cameraX;
    const camY: number = this.world.cameraY;
    const w: World = this.world;
    const ctx: CanvasRenderingContext2D = baseCtx.ctx;
    const s: GameSettings = this.settings;
    const fc: number = baseCtx.frameCount;
    const sw: number = baseCtx.screenW;
    const sh: number = baseCtx.screenH;

    // Clear and fill background
    ctx.clearRect(0, 0, sw, sh);
    ctx.fillStyle = '#08080f';
    ctx.fillRect(0, 0, sw, sh);

    // Render layers in order
    this.tileRenderer.render(w, ctx, camX, camY, sw, sh, s, fc);
    this.effectRenderer.renderLighting(w, ctx, camX, camY, sw, sh, s, fc);
    this.enemyRenderer.render(w, ctx, camX, camY, sw, sh, s, fc);
    this.effectRenderer.render(w, ctx, camX, camY, sw, sh, s, fc);
    this.bossRenderer.render(w, ctx, camX, camY, sw, sh, s, fc);
    this.playerRenderer.render(w, ctx, camX, camY, sw, sh, s, fc);
    this.effectRenderer.renderVignetteAndDamage(w, ctx, camX, camY, sw, sh, s, fc);

    // Minimap (throttled by UIRenderer internally)
    this.uiRenderer.renderMinimap(w, baseCtx.minimapCtx, camX, camY, sw, sh, fc);
  }

  getWorld(): World {
    return this.world;
  }

  getSaveLoadSystem(): SaveLoadSystem {
    return this.saveLoadSystem;
  }

  getAudio(): AudioManager {
    return this.audio;
  }

  getSettings(): GameSettings {
    return this.settings;
  }

  setPlayerGender(gender: number): void {
    this.playerGender = gender;
  }

  getPlayerGender(): number {
    return this.playerGender;
  }

  getEvolutionSystem(): EvolutionSystem {
    return this.evolutionSystem;
  }
}
