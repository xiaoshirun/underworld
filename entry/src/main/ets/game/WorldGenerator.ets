import {
  CHUNK_SIZE, TILE_SIZE, NOISE_SCALE, CAVE_THRESHOLD, BIOME_SCALE,
  TileType, EnemyType, BiomeType, SlimeState, ChunkData,
  SLIME_HP, SLIME_SIZE
} from './GameConstants';

function chunkHash(cx: number, cy: number): number {
  let h: number = (cx * 374761393 + cy * 668265263) | 0;
  h = ((h ^ (h >> 13)) * 1274126177) | 0;
  return (h ^ (h >> 16)) >>> 0;
}

function tileHash(tx: number, ty: number): number {
  let h: number = (tx * 73856093 ^ ty * 19349663) | 0;
  h = ((h ^ (h >> 13)) * 83492791) | 0;
  return (h ^ (h >> 16)) >>> 0;
}

function hashToFloat(h: number): number {
  return (h % 100000) / 100000;
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

function fade(t: number): number {
  return t * t * t * (t * (t * 6 - 15) + 10);
}

function valueNoise2D(x: number, y: number): number {
  const xi: number = Math.floor(x);
  const yi: number = Math.floor(y);
  const xf: number = x - xi;
  const yf: number = y - yi;
  const u: number = fade(xf);
  const v: number = fade(yf);
  const n00: number = hashToFloat(tileHash(xi, yi));
  const n10: number = hashToFloat(tileHash(xi + 1, yi));
  const n01: number = hashToFloat(tileHash(xi, yi + 1));
  const n11: number = hashToFloat(tileHash(xi + 1, yi + 1));
  return lerp(lerp(n00, n10, u), lerp(n01, n11, u), v);
}

function fbm(x: number, y: number, octaves: number): number {
  let value: number = 0;
  let amplitude: number = 1;
  let frequency: number = 1;
  let maxValue: number = 0;
  for (let i: number = 0; i < octaves; i++) {
    value += amplitude * valueNoise2D(x * frequency, y * frequency);
    maxValue += amplitude;
    amplitude *= 0.5;
    frequency *= 2;
  }
  return value / maxValue;
}

export class WorldGenerator {
  getBiome(worldX: number, worldY: number): BiomeType {
    const temp: number = valueNoise2D(worldX * BIOME_SCALE, worldY * BIOME_SCALE);
    const moist: number = valueNoise2D((worldX + 500) * BIOME_SCALE, (worldY + 500) * BIOME_SCALE);
    if (temp < 0.25) return BiomeType.WATER;
    if (temp > 0.75 && moist < 0.4) return BiomeType.LAVA;
    if (moist > 0.65) return BiomeType.MUSHROOM;
    if (temp > 0.55 && moist > 0.4) return BiomeType.CRYSTAL;
    return BiomeType.NORMAL;
  }

  generateChunk(cx: number, cy: number): ChunkData {
    const size: number = CHUNK_SIZE;
    const tiles: number[][] = [];
    const biomeOriginX: number = cx * size;
    const biomeOriginY: number = cy * size;

    for (let ly: number = 0; ly < size; ly++) {
      tiles[ly] = [];
      for (let lx: number = 0; lx < size; lx++) {
        const wx: number = cx * size + lx;
        const wy: number = cy * size + ly;
        const noiseVal: number = fbm(wx * NOISE_SCALE, wy * NOISE_SCALE, 4);
        const biome: BiomeType = this.getBiome(wx, wy);
        let threshold: number = CAVE_THRESHOLD;
        if (biome === BiomeType.WATER) threshold += 0.08;
        if (biome === BiomeType.LAVA) threshold += 0.05;
        if (biome === BiomeType.CRYSTAL) threshold -= 0.05;

        if (noiseVal < threshold) {
          tiles[ly][lx] = TileType.WALL;
        } else {
          tiles[ly][lx] = TileType.FLOOR;
        }
      }
    }

    if (cx === 0 && cy === 0) {
      const center: number = Math.floor(size / 2);
      const clearR: number = 6;
      for (let dy: number = -clearR; dy <= clearR; dy++) {
        for (let dx: number = -clearR; dx <= clearR; dx++) {
          const tx: number = center + dx;
          const ty: number = center + dy;
          if (tx >= 0 && tx < size && ty >= 0 && ty < size && dx * dx + dy * dy <= clearR * clearR) {
            tiles[ty][tx] = TileType.FLOOR;
          }
        }
      }
    }

    this.decorateChunk(tiles, cx, cy, size, biomeOriginX, biomeOriginY);
    const enemies: SlimeState[] = this.generateChunkEnemies(cx, cy, tiles, size, biomeOriginX, biomeOriginY);

    return { tiles: tiles, enemies: enemies, generated: true };
  }

  private decorateChunk(tiles: number[][], cx: number, cy: number, size: number, bx: number, by: number): void {
    const biome: BiomeType = this.getBiome(bx + size / 2, by + size / 2);

    for (let ly: number = 0; ly < size; ly++) {
      for (let lx: number = 0; lx < size; lx++) {
        if (tiles[ly][lx] !== TileType.FLOOR) continue;
        const h: number = tileHash(lx + cx * size + 1000, ly + cy * size + 2000);
        const r: number = hashToFloat(h);

        if (biome === BiomeType.MUSHROOM) {
          if (r < 0.06) tiles[ly][lx] = TileType.MUSHROOM;
          else if (r < 0.10) tiles[ly][lx] = TileType.PLANT;
        } else if (biome === BiomeType.CRYSTAL) {
          if (r < 0.05) tiles[ly][lx] = TileType.CRYSTAL;
          else if (r < 0.08) tiles[ly][lx] = TileType.GLOW_STONE;
        } else if (biome === BiomeType.WATER) {
          if (r < 0.03) tiles[ly][lx] = TileType.PLANT;
        } else if (biome === BiomeType.LAVA) {
          if (r < 0.02) tiles[ly][lx] = TileType.GLOW_STONE;
        } else {
          if (r < 0.015) tiles[ly][lx] = TileType.GLOW_STONE;
          else if (r < 0.035) tiles[ly][lx] = TileType.PLANT;
        }
      }
    }
  }

  private generateChunkEnemies(cx: number, cy: number, tiles: number[][], size: number, bx: number, by: number): SlimeState[] {
    const enemies: SlimeState[] = [];
    const biome: BiomeType = this.getBiome(bx + size / 2, by + size / 2);
    if (cx === 0 && cy === 0) return enemies;

    for (let ly: number = 0; ly < size; ly++) {
      for (let lx: number = 0; lx < size; lx++) {
        if (tiles[ly][lx] !== TileType.FLOOR) continue;
        const h: number = tileHash(lx + cx * size + 5000, ly + cy * size + 6000);
        const r: number = hashToFloat(h);
        const worldX: number = (cx * size + lx) * TILE_SIZE + TILE_SIZE / 2;
        const worldY: number = (cy * size + ly) * TILE_SIZE + TILE_SIZE / 2;

        let enemyType: EnemyType = EnemyType.GRAY_SLIME;
        let shouldPlace: boolean = false;

        if (biome === BiomeType.MUSHROOM) {
          if (r < 0.03) { shouldPlace = true; enemyType = EnemyType.YELLOW_SLIME; }
          else if (r < 0.05) { shouldPlace = true; enemyType = EnemyType.GRAY_SLIME; }
        } else if (biome === BiomeType.CRYSTAL) {
          if (r < 0.02) { shouldPlace = true; enemyType = EnemyType.GHOST_SLIME; }
          else if (r < 0.04) { shouldPlace = true; enemyType = EnemyType.PURPLE_SLIME; }
        } else if (biome === BiomeType.LAVA) {
          if (r < 0.03) { shouldPlace = true; enemyType = EnemyType.RED_SLIME; }
          else if (r < 0.05) { shouldPlace = true; enemyType = EnemyType.PURPLE_SLIME; }
        } else if (biome === BiomeType.WATER) {
          if (r < 0.03) { shouldPlace = true; enemyType = EnemyType.BLUE_SLIME; }
          else if (r < 0.05) { shouldPlace = true; enemyType = EnemyType.GRAY_SLIME; }
        } else {
          if (r < 0.015) { shouldPlace = true; enemyType = EnemyType.GRAY_SLIME; }
          else if (r < 0.025) { shouldPlace = true; enemyType = EnemyType.PURPLE_SLIME; }
          else if (r < 0.03) { shouldPlace = true; enemyType = EnemyType.BLUE_SLIME; }
        }

        if (shouldPlace) {
          enemies.push({
            x: worldX, y: worldY, vx: 0, vy: 0,
            hp: SLIME_HP, maxHp: SLIME_HP,
            enemyType: enemyType, active: true,
            bouncePhase: hashToFloat(h + 1) * Math.PI * 2,
            hitFlash: 0, moveTimer: 0, targetX: 0, targetY: 0,
            isEngulfing: false, engulfedPlayer: false,
            size: SLIME_SIZE, chargeTimer: 0, isCharging: false, splitCount: 0
          });
        }
      }
    }
    return enemies;
  }
}
