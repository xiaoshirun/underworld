import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { SpriteAtlas, FrameCoord } from './SpriteAtlas';
import { SpriteCache } from './SpriteCache';
import { generateEnemyAtlas } from './EnemySpriteGenerator';
import { generateBossAtlas } from './BossSpriteGenerator';
import { generatePlayerCache } from './PlayerSpriteGenerator';
import { EnemyType, BossType } from '../GameConstants';
import { NativeRenderer } from '../../native/NativeRenderer';

// External PNG sprite sheets in rawfile/sprites/. They are rendered from these
// same generators by tools/spritegen/generate.js — keep the file names in sync.
const ENEMY_SHEET_FILES: string[] = [
  'sprites/enemy_0_gray_slime.png',
  'sprites/enemy_1_purple_slime.png',
  'sprites/enemy_2_red_slime.png',
  'sprites/enemy_3_blue_slime.png',
  'sprites/enemy_4_yellow_slime.png',
  'sprites/enemy_5_ghost_slime.png',
  'sprites/enemy_6_humanoid_beast.png'
];
const BOSS_SHEET_FILES: string[] = [
  'sprites/boss_0_crystal_guardian.png',
  'sprites/boss_1_mushroom_king.png',
  'sprites/boss_2_lava_beast.png',
  'sprites/boss_3_abyss_siren.png',
  'sprites/boss_4_void_rift.png'
];
const ENEMY_SHEET_CELL: number = 64;
const ENEMY_SHEET_FRAMES: number = 16;
const BOSS_SHEET_CELL: number = 128;
const BOSS_SHEET_FRAMES: number = 12;
// Player sheet: 4x3 grid of 64px frames, row-major — keep order in sync with
// tools/spritegen/generate.js PLAYER_KEYS.
const PLAYER_SHEET_FILE: string = 'sprites/player_human.png';
const PLAYER_SHEET_CELL: number = 64;
const PLAYER_SHEET_FRAMES: number = 10;
const PLAYER_SHEET_KEYS: string[] = [
  'body_idle_R', 'body_idle_L',
  'body_walk_R_0', 'body_walk_R_1', 'body_walk_R_2', 'body_walk_R_3',
  'body_walk_L_0', 'body_walk_L_1', 'body_walk_L_2', 'body_walk_L_3'
];
// Extra standalone sheets (64px cells, SpriteAtlas grid formula)
const PLAYER_SLIME_SHEET_FILE: string = 'sprites/player_slime.png';
const PLAYER_SLIME_FRAMES: number = 16; // 0-7 facing right, 8-15 facing left
const WEAPON_SHEET_FILE: string = 'sprites/weapons.png';
const WEAPON_FRAMES: number = 6; // row-major by WeaponForm
const ATTACK_FX_SHEET_FILE: string = 'sprites/attack_fx.png';
const ATTACK_FX_FRAMES: number = 36; // form * 6 + progress step
const EXTRA_SHEET_CELL: number = 64;

export class SpriteManager {
  private enemyAtlases: Map<number, SpriteAtlas> = new Map<number, SpriteAtlas>();
  private bossAtlases: Map<number, SpriteAtlas> = new Map<number, SpriteAtlas>();
  private playerCache: SpriteCache = new SpriteCache();
  private playerSlimeAtlas: SpriteAtlas | null = null;
  private weaponAtlas: SpriteAtlas | null = null;
  private attackFxAtlas: SpriteAtlas | null = null;
  private ready: boolean = false;

  // Native texture pipeline
  private nativeRenderer: NativeRenderer | null = null;
  private nextTextureId: number = 1;

  // Texture ID constants — assigned during uploadNativeTextures()
  private enemyAtlasTexId: number = 0;
  private bossAtlasTexId: number = 0;
  private playerSlimeAtlasTexId: number = 0;
  private weaponAtlasTexId: number = 0;
  private attackFxAtlasTexId: number = 0;
  private playerCacheTexId: number = 0;

  /** Placeholder atlas dimensions for native texture generation. */
  private static readonly TEX_SIZE: number = 64;
  private static readonly BOSS_TEX_SIZE: number = 128;

  setNativeRenderer(nr: NativeRenderer): void {
    this.nativeRenderer = nr;
  }

  async generateAll(harmonyContext: Object | null = null): Promise<void> {
    try {
      // Test OffscreenCanvas support
      const testCanvas: OffscreenCanvas = new OffscreenCanvas(1, 1);
      const testCtx: Object | null = testCanvas.getContext('2d');
      if (testCtx === null) {
        console.warn('[SpriteManager] OffscreenCanvas 2D context not available, using procedural fallback');
        return;
      }

      const startTime: number = Date.now();

      // Generate enemy atlases
      const enemyTypes: number[] = [0, 1, 2, 3, 4, 5, 6]; // EnemyType values
      for (const t of enemyTypes) {
        this.enemyAtlases.set(t, generateEnemyAtlas(t as EnemyType));
      }

      // Yield to main thread between batches
      await new Promise<void>((resolve: (v: void) => void) => setTimeout(resolve, 0));

      // Generate boss atlases
      const bossTypes: number[] = [0, 1, 2, 3, 4]; // BossType values
      for (const t of bossTypes) {
        this.bossAtlases.set(t, generateBossAtlas(t as BossType));
      }

      await new Promise<void>((resolve: (v: void) => void) => setTimeout(resolve, 0));

      // Generate player cache
      this.playerCache = generatePlayerCache();

      this.ready = true;
      const elapsed: number = Date.now() - startTime;
      console.info(`[SpriteManager] Generated all sprites in ${elapsed}ms`);

      // Prefer external PNG sheets when present; procedural output stays as fallback.
      if (harmonyContext !== null) {
        await this.overlayExternalSheets(harmonyContext);
      }

      // Upload placeholder native textures for the GPU pipeline
      this.uploadNativeTextures();
    } catch (e) {
      console.warn(`[SpriteManager] Sprite generation failed: ${e}, using procedural fallback`);
      this.ready = false;
    }
  }

  isReady(): boolean {
    return this.ready;
  }

  getEnemyAtlas(type: EnemyType): SpriteAtlas {
    return this.enemyAtlases.get(type as number) as SpriteAtlas;
  }

  getBossAtlas(type: BossType): SpriteAtlas {
    return this.bossAtlases.get(type as number) as SpriteAtlas;
  }

  getPlayerCache(): SpriteCache {
    return this.playerCache;
  }

  /** Player blue-slime sheet (0-7 right / 8-15 left bounce cycle). */
  getPlayerSlimeAtlas(): SpriteAtlas | null {
    return this.playerSlimeAtlas;
  }

  /** Weapon icons, row-major by WeaponForm value. */
  getWeaponAtlas(): SpriteAtlas | null {
    return this.weaponAtlas;
  }

  /** Attack slash frames: form * 6 + progress step. */
  getAttackFxAtlas(): SpriteAtlas | null {
    return this.attackFxAtlas;
  }

  // ── Native texture ID getters ──────────────────────────────────────

  getEnemyAtlasTextureId(): number { return this.enemyAtlasTexId; }
  getBossAtlasTextureId(): number { return this.bossAtlasTexId; }
  getPlayerSlimeAtlasTextureId(): number { return this.playerSlimeAtlasTexId; }
  getWeaponAtlasTextureId(): number { return this.weaponAtlasTexId; }
  getAttackFxAtlasTextureId(): number { return this.attackFxAtlasTexId; }
  getPlayerCacheTextureId(): number { return this.playerCacheTexId; }

  /**
   * Return the source rect (srcX, srcY) for a named player-cache frame inside
   * the packed native texture (4 cols x 3 rows of 64px cells).
   * Returns null if the key is unknown.
   */
  getPlayerCacheFrameSrc(key: string): FrameCoord | null {
    const idx: number = PLAYER_SHEET_KEYS.indexOf(key);
    if (idx < 0) return null;
    const cols: number = 4;
    const col: number = idx % cols;
    const row: number = Math.floor(idx / cols);
    return new FrameCoord(col * 64, row * 64);
  }

  // ── Native texture upload ──────────────────────────────────────────

  /**
   * Generate placeholder RGBA pixel data for each atlas and upload to the GPU
   * via NativeRenderer.loadTextureRaw(). Each atlas gets a distinctive colour so
   * that mis-wired texture IDs are immediately visible during debugging.
   */
  private uploadNativeTextures(): void {
    const nr: NativeRenderer | null = this.nativeRenderer;
    if (nr === null) {
      console.warn('[SpriteManager] No NativeRenderer set — skipping native texture upload');
      return;
    }

    const sz: number = SpriteManager.TEX_SIZE;
    const bSz: number = SpriteManager.BOSS_TEX_SIZE;

    // Enemy atlas: 4x4 grid of 64px cells = 256x256, tinted red-orange
    this.enemyAtlasTexId = this.nextTextureId++;
    const enemyCols: number = Math.ceil(Math.sqrt(16));
    const enemyRows: number = Math.ceil(16 / enemyCols);
    const enemyPixels: Uint8Array = this.generatePlaceholderPixels(
      enemyCols * sz, enemyRows * sz, 0.7, 0.45, 0.3);
    nr.loadTextureRaw(this.enemyAtlasTexId, enemyPixels.buffer as ArrayBuffer,
      enemyCols * sz, enemyRows * sz);
    this.setAtlasTextureId(this.enemyAtlases, this.enemyAtlasTexId);

    // Boss atlas: 4x3 grid of 128px cells = 512x384, tinted purple
    this.bossAtlasTexId = this.nextTextureId++;
    const bossCols: number = Math.ceil(Math.sqrt(12));
    const bossRows: number = Math.ceil(12 / bossCols);
    const bossPixels: Uint8Array = this.generatePlaceholderPixels(
      bossCols * bSz, bossRows * bSz, 0.55, 0.2, 0.7);
    nr.loadTextureRaw(this.bossAtlasTexId, bossPixels.buffer as ArrayBuffer,
      bossCols * bSz, bossRows * bSz);
    this.setAtlasTextureId(this.bossAtlases, this.bossAtlasTexId);

    // Player slime atlas: 4x4 grid of 64px = 256x256, tinted blue
    if (this.playerSlimeAtlas !== null) {
      this.playerSlimeAtlasTexId = this.nextTextureId++;
      const psCols: number = Math.ceil(Math.sqrt(16));
      const psRows: number = Math.ceil(16 / psCols);
      const psPixels: Uint8Array = this.generatePlaceholderPixels(
        psCols * sz, psRows * sz, 0.3, 0.5, 0.85);
      nr.loadTextureRaw(this.playerSlimeAtlasTexId, psPixels.buffer as ArrayBuffer,
        psCols * sz, psRows * sz);
      this.playerSlimeAtlas.textureId = this.playerSlimeAtlasTexId;
    }

    // Weapon atlas: 3x2 grid of 64px = 192x128, tinted silver
    if (this.weaponAtlas !== null) {
      this.weaponAtlasTexId = this.nextTextureId++;
      const wCols: number = Math.ceil(Math.sqrt(6));
      const wRows: number = Math.ceil(6 / wCols);
      const wPixels: Uint8Array = this.generatePlaceholderPixels(
        wCols * sz, wRows * sz, 0.75, 0.75, 0.8);
      nr.loadTextureRaw(this.weaponAtlasTexId, wPixels.buffer as ArrayBuffer,
        wCols * sz, wRows * sz);
      this.weaponAtlas.textureId = this.weaponAtlasTexId;
    }

    // Attack FX atlas: 6x6 grid of 64px = 384x384, tinted yellow-orange
    if (this.attackFxAtlas !== null) {
      this.attackFxAtlasTexId = this.nextTextureId++;
      const fxCols: number = Math.ceil(Math.sqrt(36));
      const fxRows: number = Math.ceil(36 / fxCols);
      const fxPixels: Uint8Array = this.generatePlaceholderPixels(
        fxCols * sz, fxRows * sz, 0.9, 0.7, 0.2);
      nr.loadTextureRaw(this.attackFxAtlasTexId, fxPixels.buffer as ArrayBuffer,
        fxCols * sz, fxRows * sz);
      this.attackFxAtlas.textureId = this.attackFxAtlasTexId;
    }

    // Player cache: pack 10 frames into 4x3 grid of 64px = 256x192, tinted green
    this.playerCacheTexId = this.nextTextureId++;
    const pcCols: number = 4;
    const pcRows: number = 3;
    const pcPixels: Uint8Array = this.generatePlaceholderPixels(
      pcCols * sz, pcRows * sz, 0.3, 0.75, 0.4);
    nr.loadTextureRaw(this.playerCacheTexId, pcPixels.buffer as ArrayBuffer,
      pcCols * sz, pcRows * sz);

    console.info(`[SpriteManager] Uploaded ${this.nextTextureId - 1} native textures`);
  }

  /** Fill a WxH RGBA buffer with a soft gradient placeholder in the given colour. */
  private generatePlaceholderPixels(w: number, h: number,
      r: number, g: number, b: number): Uint8Array {
    const pixels: Uint8Array = new Uint8Array(w * h * 4);
    const rB: number = Math.floor(r * 255);
    const gB: number = Math.floor(g * 255);
    const bB: number = Math.floor(b * 255);
    for (let y: number = 0; y < h; y++) {
      for (let x: number = 0; x < w; x++) {
        const idx: number = (y * w + x) * 4;
        // Slight vignette gradient for visual interest
        const cx: number = (x / w - 0.5) * 2;
        const cy: number = (y / h - 0.5) * 2;
        const vignette: number = Math.max(0.5, 1.0 - (cx * cx + cy * cy) * 0.3);
        pixels[idx] = Math.floor(rB * vignette);
        pixels[idx + 1] = Math.floor(gB * vignette);
        pixels[idx + 2] = Math.floor(bB * vignette);
        pixels[idx + 3] = 255;
      }
    }
    return pixels;
  }

  /** Set textureId on all SpriteAtlas entries in a map. */
  private setAtlasTextureId(atlases: Map<number, SpriteAtlas>, texId: number): void {
    const iter = atlases.entries();
    let entry = iter.next();
    while (!entry.done) {
      entry.value[1].textureId = texId;
      entry = iter.next();
    }
  }

  /** Replace procedural atlases with rawfile PNG sheets where available. */
  private async overlayExternalSheets(harmonyContext: Object): Promise<void> {
    const ctx: common.UIAbilityContext = harmonyContext as common.UIAbilityContext;
    let loaded: number = 0;

    for (let t: number = 0; t < ENEMY_SHEET_FILES.length; t++) {
      const atlas: SpriteAtlas | null =
        await this.loadSheetAtlas(ctx, ENEMY_SHEET_FILES[t], ENEMY_SHEET_CELL, ENEMY_SHEET_FRAMES);
      if (atlas !== null) {
        this.enemyAtlases.set(t, atlas);
        loaded++;
      }
    }

    for (let t: number = 0; t < BOSS_SHEET_FILES.length; t++) {
      const atlas: SpriteAtlas | null =
        await this.loadSheetAtlas(ctx, BOSS_SHEET_FILES[t], BOSS_SHEET_CELL, BOSS_SHEET_FRAMES);
      if (atlas !== null) {
        this.bossAtlases.set(t, atlas);
        loaded++;
      }
    }

    const playerCache: SpriteCache | null = await this.loadPlayerSheet(ctx);
    if (playerCache !== null) {
      this.playerCache = playerCache;
      loaded++;
    }

    this.playerSlimeAtlas =
      await this.loadSheetAtlas(ctx, PLAYER_SLIME_SHEET_FILE, EXTRA_SHEET_CELL, PLAYER_SLIME_FRAMES);
    if (this.playerSlimeAtlas !== null) {
      loaded++;
    }
    this.weaponAtlas =
      await this.loadSheetAtlas(ctx, WEAPON_SHEET_FILE, EXTRA_SHEET_CELL, WEAPON_FRAMES);
    if (this.weaponAtlas !== null) {
      loaded++;
    }
    this.attackFxAtlas =
      await this.loadSheetAtlas(ctx, ATTACK_FX_SHEET_FILE, EXTRA_SHEET_CELL, ATTACK_FX_FRAMES);
    if (this.attackFxAtlas !== null) {
      loaded++;
    }

    if (loaded > 0) {
      console.info(`[SpriteManager] Loaded ${loaded} external sprite sheets from rawfile`);
    }
  }

  /** Decode a rawfile PNG into a PixelMap directly from its content buffer. */
  private async decodeRawImage(ctx: common.UIAbilityContext, filePath: string): Promise<image.PixelMap> {
    const buffer = await ctx.resourceManager.getRawFileContent(filePath);
    const imageSource: image.ImageSource = image.createImageSource(buffer);
    const pixelMap: image.PixelMap = await imageSource.createPixelMap();
    imageSource.release();
    return pixelMap;
  }

  /** Decode one sheet PNG and rebuild a SpriteAtlas with the standard frame layout. */
  private async loadSheetAtlas(ctx: common.UIAbilityContext, filePath: string,
    cellSize: number, frameCount: number): Promise<SpriteAtlas | null> {
    try {
      const pixelMap: image.PixelMap = await this.decodeRawImage(ctx, filePath);

      // Same grid math as SpriteAtlas, matching the generator's sheet layout.
      const cols: number = Math.ceil(Math.sqrt(frameCount));
      const rows: number = Math.ceil(frameCount / cols);
      const sheetW: number = cols * cellSize;
      const sheetH: number = rows * cellSize;
      const canvas: OffscreenCanvas = new OffscreenCanvas(sheetW, sheetH);
      const c: OffscreenCanvasRenderingContext2D = canvas.getContext('2d') as OffscreenCanvasRenderingContext2D;
      c.drawImage(pixelMap, 0, 0, sheetW, sheetH, 0, 0, sheetW, sheetH);
      return new SpriteAtlas(canvas, cellSize, cellSize, frameCount);
    } catch (e) {
      console.warn(`[SpriteManager] External sheet unavailable, using procedural: ${filePath}: ${e}`);
      return null;
    }
  }

  /** Slice the player sheet PNG into per-frame SpriteCache entries. */
  private async loadPlayerSheet(ctx: common.UIAbilityContext): Promise<SpriteCache | null> {
    try {
      const pixelMap: image.PixelMap = await this.decodeRawImage(ctx, PLAYER_SHEET_FILE);

      const cols: number = Math.ceil(Math.sqrt(PLAYER_SHEET_FRAMES));
      const cache: SpriteCache = new SpriteCache();
      for (let i: number = 0; i < PLAYER_SHEET_FRAMES; i++) {
        const col: number = i % cols;
        const row: number = Math.floor(i / cols);
        const frame: OffscreenCanvas = new OffscreenCanvas(PLAYER_SHEET_CELL, PLAYER_SHEET_CELL);
        const fc: OffscreenCanvasRenderingContext2D =
          frame.getContext('2d') as OffscreenCanvasRenderingContext2D;
        fc.drawImage(pixelMap, col * PLAYER_SHEET_CELL, row * PLAYER_SHEET_CELL,
          PLAYER_SHEET_CELL, PLAYER_SHEET_CELL, 0, 0, PLAYER_SHEET_CELL, PLAYER_SHEET_CELL);
        cache.set(PLAYER_SHEET_KEYS[i], frame.transferToImageBitmap());
      }
      console.info(`[SpriteManager] Loaded ${PLAYER_SHEET_FRAMES} player frames from rawfile`);
      return cache;
    } catch (e) {
      console.warn(`[SpriteManager] External player sheet unavailable, using procedural: ${e}`);
      return null;
    }
  }
}
