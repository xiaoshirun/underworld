import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { SpriteAtlas } from './SpriteAtlas';
import { SpriteCache } from './SpriteCache';
import { generateEnemyAtlas } from './EnemySpriteGenerator';
import { generateBossAtlas } from './BossSpriteGenerator';
import { generatePlayerCache } from './PlayerSpriteGenerator';
import { EnemyType, BossType } from '../GameConstants';

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
