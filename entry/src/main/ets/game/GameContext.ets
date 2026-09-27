import {
  TILE_SIZE, CHUNK_SIZE, CHUNK_LOAD_RADIUS,
  TileType, BiomeType,
  ChunkData, PlayerState, SlimeState, XpOrb, Particle,
  InputState, GameSettings, AmbientParticle,
  GenderType, BossState, BossRoom, MaterialDrop, ChestState,
  TrapInstance, MechanismInstance, SecretRoom, TransformCoreDrop,
  TransformForm, GameState,
} from './GameConstants';
import { WorldGenerator } from './WorldGenerator';
import { AudioManager } from './AudioManager';
import { ParticleManager } from './ParticleSystem';
import { PhysicsEngine } from './PhysicsEngine';
import { TileBatchRenderer, GlowBatchRenderer } from './SpriteBatch';

export interface ChunkCacheEntry {
  key: string;
  poolIndex: number;
  isShadow: boolean;
}

export class GameContext {
  ctx: CanvasRenderingContext2D | null = null;
  minimapCtx: CanvasRenderingContext2D | null = null;
  cacheCtxs: CanvasRenderingContext2D[] = [];
  chunkPixelSize: number = CHUNK_SIZE * TILE_SIZE;
  cacheEntryPool: (ChunkCacheEntry | null)[] = [];
  activeChunkCaches: Map<string, ChunkCacheEntry> = new Map();
  freePoolIndices: number[] = [];
  lastCacheIsShadow: boolean = false;
  worldGen: WorldGenerator = new WorldGenerator();
  chunks: Map<string, ChunkData> = new Map();
  player: PlayerState | null = null;
  enemies: SlimeState[] = [];
  xpOrbs: XpOrb[] = [];
  particles: Particle[] = [];
  cameraX: number = 0;
  cameraY: number = 0;
  screenW: number = 0;
  screenH: number = 0;
  gameLoopId: number = -1;
  frameCount: number = 0;
  shakeX: number = 0;
  shakeY: number = 0;
  shakeTimer: number = 0;
  damageFlashTimer: number = 0;
  audio: AudioManager = new AudioManager();
  settings: GameSettings = { soundEnabled: true, effectsEnabled: true };
  ambientParticles: AmbientParticle[] = [];
  playerGender: GenderType = GenderType.MALE;
  bosses: BossState[] = [];
  activeBoss: BossState | null = null;
  bossRoomLocked: boolean = false;
  materialDrops: MaterialDrop[] = [];
  bossRooms: BossRoom[] = [];
  chests: ChestState[] = [];
  traps: TrapInstance[] = [];
  mechanisms: MechanismInstance[] = [];
  secretRooms: SecretRoom[] = [];
  teleportCooldown: number = 0;
  transformCoreDrops: TransformCoreDrop[] = [];
  transformUnlockNotifyTimer: number = 0;
  transformUnlockNotifyForm: TransformForm = TransformForm.NONE;
  transformAnimIsRevert: boolean = false;
  particleMgr: ParticleManager = new ParticleManager();
  physics: PhysicsEngine = new PhysicsEngine();
  tileBatch: TileBatchRenderer = new TileBatchRenderer(TILE_SIZE);
  glowBatch: GlowBatchRenderer = new GlowBatchRenderer();
  input: InputState = {
    joyActive: false, joyDx: 0, joyDy: 0,
    jumpPressed: false, attackPressed: false, dashPressed: false, attackHeld: false,
    toolPressed: false
  };
  state: GameState = GameState.PLAYING;
  onStateChange: ((state: GameState) => void) | null = null;
  onSave: (() => void) | null = null;
  context: Object | null = null;

  chunkKey(cx: number, cy: number): string {
    return cx + ',' + cy;
  }

  loadChunksAround(tileX: number, tileY: number): void {
    const pcx: number = Math.floor(tileX / CHUNK_SIZE);
    const pcy: number = Math.floor(tileY / CHUNK_SIZE);
    for (let dy: number = -CHUNK_LOAD_RADIUS; dy <= CHUNK_LOAD_RADIUS; dy++) {
      for (let dx: number = -CHUNK_LOAD_RADIUS; dx <= CHUNK_LOAD_RADIUS; dx++) {
        const cx: number = pcx + dx;
        const cy: number = pcy + dy;
        const key: string = this.chunkKey(cx, cy);
        if (!this.chunks.has(key)) {
          const chunk: ChunkData = this.worldGen.generateChunk(cx, cy);
          this.chunks.set(key, chunk);
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
        }
      }
    }
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
    this.invalidateChunkCache(key);
  }

  invalidateChunkCache(key: string): void {
    const entry: ChunkCacheEntry | undefined = this.activeChunkCaches.get(key);
    if (entry !== undefined) {
      this.cacheEntryPool[entry.poolIndex] = null;
      this.freePoolIndices.push(entry.poolIndex);
      this.activeChunkCaches.delete(key);
    }
  }

  invalidateAllChunkCaches(): void {
    this.activeChunkCaches.clear();
    this.cacheEntryPool = new Array(this.cacheCtxs.length).fill(null);
    this.freePoolIndices = [];
    for (let i: number = 0; i < this.cacheCtxs.length; i++) {
      this.freePoolIndices.push(i);
    }
  }

  isWalkable(tile: number): boolean {
    return tile !== TileType.WALL && tile !== TileType.VOID;
  }

  spawnParticle(x: number, y: number, vx: number, vy: number, life: number, color: string, size: number): void {
    this.particles.push({ x: x, y: y, vx: vx, vy: vy, life: life, maxLife: life, color: color, size: size });
  }

  updateParticles(dt: number): void {
    for (let i: number = this.particles.length - 1; i >= 0; i--) {
      const pt: Particle = this.particles[i];
      pt.x += pt.vx;
      pt.y += pt.vy;
      pt.vx *= 0.95;
      pt.vy *= 0.95;
      pt.life -= dt;
      if (pt.life <= 0) {
        this.particles.splice(i, 1);
      }
    }
  }
}
