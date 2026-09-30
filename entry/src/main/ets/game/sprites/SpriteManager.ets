import { SpriteAtlas } from './SpriteAtlas';
import { SpriteCache } from './SpriteCache';
import { generateEnemyAtlas } from './EnemySpriteGenerator';
import { generateBossAtlas } from './BossSpriteGenerator';
import { generatePlayerCache } from './PlayerSpriteGenerator';
import { EnemyType, BossType } from '../GameConstants';

export class SpriteManager {
  private enemyAtlases: Map<number, SpriteAtlas> = new Map<number, SpriteAtlas>();
  private bossAtlases: Map<number, SpriteAtlas> = new Map<number, SpriteAtlas>();
  private playerCache: SpriteCache = new SpriteCache();
  private ready: boolean = false;

  async generateAll(): Promise<void> {
    const startTime: number = Date.now();

    // Generate enemy atlases
    const enemyTypes: number[] = [0, 1, 2, 3, 4, 5]; // EnemyType values
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
}
