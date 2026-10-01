import { Scene, BaseContext, World, Entity, SystemContext } from '@qiuyu/engine';
import { AudioManager } from './AudioManager';
import { GameSettings, CHUNK_SIZE, TILE_SIZE, ChunkData } from './GameConstants';
import { WorldGenerator } from './WorldGenerator';
import { PlayerFactory } from './factories/PlayerFactory';
import { CameraComponent } from './components/CameraComponent';
import { GameStateComponent } from './components/GameStateComponent';
import { DrawCmdBuffer } from '../native/DrawCmd';
import { NativeRenderer } from '../native/NativeRenderer';

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
import { DevourSystem } from './systems/DevourSystem';
import { SkillSystem } from './systems/SkillSystem';
import { MonsterLevelSystem } from './systems/MonsterLevelSystem';
import { HumanoidBeastSystem } from './systems/HumanoidBeastSystem';
import { HumanFormSystem } from './systems/HumanFormSystem';
import { PassiveTreeSystem } from './systems/PassiveTreeSystem';

// Renderers
import { TileRenderer } from './renderers/TileRenderer';
import { EffectRenderer } from './renderers/EffectRenderer';
import { EnemyRenderer } from './renderers/EnemyRenderer';
import { BossRenderer } from './renderers/BossRenderer';
import { PlayerRenderer } from './renderers/PlayerRenderer';
import { SpriteManager } from './sprites/SpriteManager';

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
  private spriteManager: SpriteManager = new SpriteManager();
  private harmonyContext: Object | null = null;
  public frameCount: number = 0;
  public screenW: number = 360;
  public screenH: number = 780;

  constructor(audio: AudioManager, settings: GameSettings, harmonyContext: Object | null = null) {
    super();
    this.audio = audio;
    this.settings = settings;
    this.harmonyContext = harmonyContext;
    this.world = new World();

    // Initialize world generator
    const worldGen: WorldGenerator = new WorldGenerator();
    this.world.worldGen = worldGen;

    // Pre-load spawn chunk to guarantee the player's starting area renders immediately
    try {
      const spawnChunk: ChunkData = worldGen.generateChunk(0, 0);
      this.world.chunks.set('0,0', spawnChunk as Object);
      console.log('[GameScene] Pre-loaded spawn chunk (0,0)');
    } catch (e) {
      console.error('[GameScene] Failed to pre-load spawn chunk: ' + String(e));
    }

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
    this.world.addSystem(new MonsterLevelSystem());
    this.world.addSystem(new HumanoidBeastSystem());
    this.world.addSystem(new PlayerMovementSystem());
    this.world.addSystem(new PlayerCombatSystem());
    this.world.addSystem(new DevourSystem());
    this.world.addSystem(new SkillSystem());
    this.world.addSystem(new EnemyAISystem());
    this.world.addSystem(new BossSystem());
    this.world.addSystem(new TransformSystem());
    this.world.addSystem(new HumanFormSystem());
    this.world.addSystem(new TrapSystem());
    this.world.addSystem(new MechanismSystem());
    this.world.addSystem(new ChestSystem());
    this.world.addSystem(new MaterialDropSystem());
    this.world.addSystem(new XpLevelSystem());
    this.world.addSystem(new DamageSystem());
    this.evolutionSystem = new EvolutionSystem();
    this.world.addSystem(this.evolutionSystem);
    this.world.addSystem(new PassiveTreeSystem());
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

  async initSprites(nativeRenderer?: NativeRenderer): Promise<void> {
    if (nativeRenderer !== undefined) {
      this.spriteManager.setNativeRenderer(nativeRenderer);
    }
    await this.spriteManager.generateAll(this.harmonyContext);
  }

  getSpriteManager(): SpriteManager {
    return this.spriteManager;
  }

  update(baseCtx: BaseContext, dt: number): void {
    this.frameCount = baseCtx.frameCount;
    this.screenW = baseCtx.screenW;
    this.screenH = baseCtx.screenH;
    const sysCtx: SystemContext = {
      world: this.world,
      screenW: baseCtx.screenW,
      screenH: baseCtx.screenH,
      input: baseCtx.input,
      audio: this.audio as Object,
      frameCount: baseCtx.frameCount,
      dt: dt
    };
    if (baseCtx.frameCount < 5) {
      console.log('[GameScene] update frame=' + baseCtx.frameCount + ' dt=' + dt + ' entities=' + this.world.getEntities().length + ' joyActive=' + baseCtx.input.joyActive + ' chunks=' + this.world.chunks.size);
    }
    this.world.update(sysCtx, dt);
  }

  collectCommands(buf: DrawCmdBuffer): void {
    const camX: number = this.world.cameraX;
    const camY: number = this.world.cameraY;
    const w: World = this.world;
    const s: GameSettings = this.settings;
    const fc: number = this.frameCount;
    const sw: number = this.screenW;
    const sh: number = this.screenH;
    const sm: SpriteManager = this.spriteManager;

    // 1. Tiles
    this.tileRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc);

    // 2. Lighting
    this.effectRenderer.collectLightingCommands(w, buf, camX, camY, sw, sh, s, fc);

    // 3. Enemies
    this.enemyRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, sm);

    // 4. Traps, mechanisms, chests
    this.effectRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc);

    // 5. Bosses
    this.bossRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, sm);

    // 6. Player (includes weapon + transform form)
    this.playerRenderer.collectCommands(w, buf, camX, camY, sw, sh, s, fc, sm);

    // 7. Vignette + damage flash
    this.effectRenderer.collectVignetteCommands(w, buf, sw, sh, fc);
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

  getEvolutionSystem(): EvolutionSystem {
    return this.evolutionSystem;
  }
}
