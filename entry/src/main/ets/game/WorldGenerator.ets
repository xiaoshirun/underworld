import {
  CHUNK_SIZE, TILE_SIZE, NOISE_SCALE, CAVE_THRESHOLD, BIOME_SCALE,
  TileType, EnemyType, BiomeType, SlimeState, ChunkData,
  SLIME_HP, SLIME_SIZE,
  TrapType, TrapState, TrapInstance,
  TRAP_TELEGRAPH_TIME, TRAP_ACTIVE_TIME, TRAP_COOLDOWN_TIME,
  TRAP_TRIGGER_RADIUS, TRAP_DAMAGE, TRAP_SIZE,
  MechanismType, MechanismInstance, SecretRoom, ChestType, ChestState,
  MECH_INTERACT_RANGE, PRESSURE_PLATE_RANGE,
  CHEST_SIZE, NORMAL_CHEST_CHANCE,
  BossType, BossRole, BossRoom, BossState, BossPhase,
  BOSS_ROOM_SIZE, BOSS_HP, BOSS_SIZE,
  PASSAGE_GUARDIAN_AGGRO, OPTIONAL_CHALLENGE_AGGRO
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
  private bossRooms: BossRoom[] = [];
  private placedBossBiomes: number[] = []; // biome values that have a Passage Guardian placed
  private defeatedOptionalBosses: string[] = []; // "cx,cy" keys

  getBiome(worldX: number, worldY: number): BiomeType {
    const temp: number = valueNoise2D(worldX * BIOME_SCALE, worldY * BIOME_SCALE);
    const moist: number = valueNoise2D((worldX + 500) * BIOME_SCALE, (worldY + 500) * BIOME_SCALE);
    const dist: number = Math.sqrt(worldX * worldX + worldY * worldY) * 0.001;
    if (dist > 0.5 && temp < 0.3 && moist > 0.5) return BiomeType.SHADOW;
    if (temp < 0.25) return BiomeType.WATER;
    if (temp > 0.75 && moist < 0.4) return BiomeType.LAVA;
    if (moist > 0.65) return BiomeType.MUSHROOM;
    if (temp > 0.55 && moist > 0.4) return BiomeType.CRYSTAL;
    return BiomeType.NORMAL;
  }

  getBossRooms(): BossRoom[] {
    return this.bossRooms;
  }

  markOptionalBossDefeated(cx: number, cy: number): void {
    const key: string = cx + ',' + cy;
    if (this.defeatedOptionalBosses.indexOf(key) < 0) {
      this.defeatedOptionalBosses.push(key);
    }
  }

  generateChunk(cx: number, cy: number): ChunkData {
    const size: number = CHUNK_SIZE;
    const tiles: number[][] = [];

    if (cx === 0 && cy === 0) {
      for (let ly: number = 0; ly < size; ly++) {
        tiles[ly] = [];
        for (let lx: number = 0; lx < size; lx++) {
          const wx: number = lx;
          const wy: number = ly;
          const noiseVal: number = fbm(wx * NOISE_SCALE, wy * NOISE_SCALE, 4);
          tiles[ly][lx] = noiseVal < CAVE_THRESHOLD ? TileType.WALL : TileType.FLOOR;
        }
      }
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
      return {
        tiles: tiles, enemies: [], generated: true,
        bosses: [], chests: [], traps: [], mechanisms: [], secretRooms: [],
        isBossRoom: false
      };
    }

    const noiseGrid: number[][] = [];
    for (let ly: number = 0; ly < size; ly++) {
      noiseGrid[ly] = [];
      for (let lx: number = 0; lx < size; lx++) {
        const wx: number = cx * size + lx;
        const wy: number = cy * size + ly;
        noiseGrid[ly][lx] = fbm(wx * NOISE_SCALE, wy * NOISE_SCALE, 4);
      }
    }

    const biomeOriginX: number = cx * size;
    const biomeOriginY: number = cy * size;
    const chunkBiome: BiomeType = this.getBiome(biomeOriginX + size / 2, biomeOriginY + size / 2);
    const distFromOrigin: number = Math.sqrt(cx * cx + cy * cy);

    let threshold: number = CAVE_THRESHOLD;
    if (chunkBiome === BiomeType.WATER) threshold += 0.08;
    if (chunkBiome === BiomeType.LAVA) threshold += 0.05;
    if (chunkBiome === BiomeType.CRYSTAL) threshold -= 0.05;

    for (let ly: number = 0; ly < size; ly++) {
      tiles[ly] = [];
      for (let lx: number = 0; lx < size; lx++) {
        tiles[ly][lx] = noiseGrid[ly][lx] < threshold ? TileType.WALL : TileType.FLOOR;
      }
    }

    const passageRoom: BossRoom | null = this.tryPlacePassageGuardian(cx, cy, chunkBiome, distFromOrigin);
    let optionalBoss: BossState | null = null;
    if (passageRoom === null) {
      optionalBoss = this.tryPlaceOptionalBoss(cx, cy, chunkBiome, distFromOrigin);
    }
    const isBossRoom: boolean = passageRoom !== null;

    if (isBossRoom) {
      this.generateBossRoomTiles(tiles, cx, cy, chunkBiome);
      const bosses: BossState[] = [];
      if (passageRoom !== null) {
        const bossX: number = (cx * size + Math.floor(size / 2)) * TILE_SIZE + TILE_SIZE / 2;
        const bossY: number = (cy * size + Math.floor(size / 2)) * TILE_SIZE + TILE_SIZE / 2;
        bosses.push({
          x: bossX, y: bossY, vx: 0, vy: 0,
          hp: BOSS_HP, maxHp: BOSS_HP,
          bossType: passageRoom.bossType,
          bossRole: BossRole.PASSAGE_GUARDIAN,
          phase: BossPhase.PHASE_1,
          active: false, defeated: false,
          attackTimer: 0, specialTimer: 0,
          hitFlash: 0, size: BOSS_SIZE,
          aggroRadius: PASSAGE_GUARDIAN_AGGRO,
          extraData: []
        });
      }
      return {
        tiles: tiles, enemies: [], generated: true,
        bosses: bosses, chests: [], traps: [], mechanisms: [], secretRooms: [],
        isBossRoom: true
      };
    }

    const entities = this.generateEntities(cx, cy, tiles, size, chunkBiome, distFromOrigin);
    const secretRooms: SecretRoom[] = this.generateSecretRooms(cx, cy, tiles, chunkBiome, distFromOrigin);
    const chests: ChestState[] = this.generateChests(cx, cy, tiles, size, secretRooms, distFromOrigin);

    const chunkBoss: BossState[] = [];
    if (optionalBoss !== null) {
      chunkBoss.push(optionalBoss);
    }

    return {
      tiles: tiles, enemies: entities.enemies, generated: true,
      bosses: chunkBoss, chests: chests, traps: entities.traps,
      mechanisms: entities.mechanisms, secretRooms: secretRooms, isBossRoom: false
    };
  }

  private generateEntities(cx: number, cy: number, tiles: number[][], size: number,
    biome: BiomeType, distFromOrigin: number):
    { enemies: SlimeState[], traps: TrapInstance[], mechanisms: MechanismInstance[] } {
    const enemies: SlimeState[] = [];
    const traps: TrapInstance[] = [];
    const mechanisms: MechanismInstance[] = [];
    const trapDensity: number = Math.min(0.02 + distFromOrigin * 0.003, 0.08);
    const mechDensity: number = Math.min(0.01 + distFromOrigin * 0.002, 0.04);

    for (let ly: number = 0; ly < size; ly++) {
      for (let lx: number = 0; lx < size; lx++) {
        if (tiles[ly][lx] !== TileType.FLOOR) continue;
        const worldX: number = (cx * size + lx) * TILE_SIZE + TILE_SIZE / 2;
        const worldY: number = (cy * size + ly) * TILE_SIZE + TILE_SIZE / 2;

        const decH: number = tileHash(lx + cx * size + 1000, ly + cy * size + 2000);
        const decR: number = hashToFloat(decH);
        let decorated: boolean = false;

        if (biome === BiomeType.MUSHROOM) {
          if (decR < 0.06) { tiles[ly][lx] = TileType.MUSHROOM; decorated = true; }
          else if (decR < 0.10) { tiles[ly][lx] = TileType.PLANT; decorated = true; }
        } else if (biome === BiomeType.CRYSTAL) {
          if (decR < 0.05) { tiles[ly][lx] = TileType.CRYSTAL; decorated = true; }
          else if (decR < 0.08) { tiles[ly][lx] = TileType.GLOW_STONE; decorated = true; }
        } else if (biome === BiomeType.WATER) {
          if (decR < 0.03) { tiles[ly][lx] = TileType.PLANT; decorated = true; }
        } else if (biome === BiomeType.LAVA) {
          if (decR < 0.02) { tiles[ly][lx] = TileType.GLOW_STONE; decorated = true; }
        } else if (biome === BiomeType.SHADOW) {
          if (decR < 0.04) { tiles[ly][lx] = TileType.GLOW_STONE; decorated = true; }
          else if (decR < 0.06) { tiles[ly][lx] = TileType.WALL; decorated = true; }
        } else {
          if (decR < 0.015) { tiles[ly][lx] = TileType.GLOW_STONE; decorated = true; }
          else if (decR < 0.035) { tiles[ly][lx] = TileType.PLANT; decorated = true; }
        }
        if (decorated) continue;

        const enemyH: number = tileHash(lx + cx * size + 5000, ly + cy * size + 6000);
        const enemyR: number = hashToFloat(enemyH);
        let enemyType: EnemyType = EnemyType.GRAY_SLIME;
        let shouldPlaceEnemy: boolean = false;

        if (biome === BiomeType.MUSHROOM) {
          if (enemyR < 0.03) { shouldPlaceEnemy = true; enemyType = EnemyType.YELLOW_SLIME; }
          else if (enemyR < 0.05) { shouldPlaceEnemy = true; enemyType = EnemyType.GRAY_SLIME; }
        } else if (biome === BiomeType.CRYSTAL) {
          if (enemyR < 0.02) { shouldPlaceEnemy = true; enemyType = EnemyType.GHOST_SLIME; }
          else if (enemyR < 0.04) { shouldPlaceEnemy = true; enemyType = EnemyType.PURPLE_SLIME; }
        } else if (biome === BiomeType.LAVA) {
          if (enemyR < 0.03) { shouldPlaceEnemy = true; enemyType = EnemyType.RED_SLIME; }
          else if (enemyR < 0.05) { shouldPlaceEnemy = true; enemyType = EnemyType.PURPLE_SLIME; }
        } else if (biome === BiomeType.WATER) {
          if (enemyR < 0.03) { shouldPlaceEnemy = true; enemyType = EnemyType.BLUE_SLIME; }
          else if (enemyR < 0.05) { shouldPlaceEnemy = true; enemyType = EnemyType.GRAY_SLIME; }
        } else {
          if (enemyR < 0.015) { shouldPlaceEnemy = true; enemyType = EnemyType.GRAY_SLIME; }
          else if (enemyR < 0.025) { shouldPlaceEnemy = true; enemyType = EnemyType.PURPLE_SLIME; }
          else if (enemyR < 0.03) { shouldPlaceEnemy = true; enemyType = EnemyType.BLUE_SLIME; }
        }

        if (shouldPlaceEnemy) {
          enemies.push({
            x: worldX, y: worldY, vx: 0, vy: 0,
            hp: SLIME_HP, maxHp: SLIME_HP,
            enemyType: enemyType, active: true,
            bouncePhase: hashToFloat(enemyH + 1) * Math.PI * 2,
            hitFlash: 0, moveTimer: 0, targetX: 0, targetY: 0,
            isEngulfing: false, engulfedPlayer: false,
            size: SLIME_SIZE, chargeTimer: 0, isCharging: false, splitCount: 0
          });
        }

        if (lx >= 2 && lx < size - 2 && ly >= 2 && ly < size - 2) {
          const trapH: number = tileHash(lx + cx * size + 9000, ly + cy * size + 10000);
          const trapR: number = hashToFloat(trapH);
          if (trapR <= trapDensity) {
            let trapType: TrapType = TrapType.GROUND_SPIKES;
            let placedTrap: boolean = false;

            if (biome === BiomeType.MUSHROOM) {
              if (trapR < trapDensity * 0.5) { trapType = TrapType.POISON_SPORES; placedTrap = true; }
              else if (trapR < trapDensity * 0.8) { trapType = TrapType.FALLING_ROCKS; placedTrap = true; }
            } else if (biome === BiomeType.WATER) {
              if (trapR < trapDensity * 0.7) { trapType = TrapType.WATER_VORTEX; placedTrap = true; }
            } else if (biome === BiomeType.LAVA) {
              if (trapR < trapDensity * 0.5) { trapType = TrapType.LAVA_GEYSER; placedTrap = true; }
              else if (trapR < trapDensity * 0.8) { trapType = TrapType.FALLING_ROCKS; placedTrap = true; }
            } else if (biome === BiomeType.CRYSTAL) {
              if (trapR < trapDensity * 0.7) { placedTrap = true; }
            } else if (biome === BiomeType.SHADOW) {
              if (trapR < trapDensity * 0.7) { trapType = TrapType.VOID_CRACK; placedTrap = true; }
            } else {
              if (trapR < trapDensity * 0.5) { placedTrap = true; }
              else if (trapR < trapDensity * 0.8) { trapType = TrapType.FALLING_ROCKS; placedTrap = true; }
            }

            if (placedTrap) {
              traps.push({
                x: worldX, y: worldY,
                trapType: trapType,
                state: TrapState.IDLE,
                timer: 0,
                triggerRadius: TRAP_TRIGGER_RADIUS,
                damage: TRAP_DAMAGE,
                size: TRAP_SIZE,
                extraData: [0, 0]
              });
            }
          }

          const mechH: number = tileHash(lx + cx * size + 15000, ly + cy * size + 16000);
          const mechR: number = hashToFloat(mechH);
          if (mechR <= mechDensity) {
            let mechType: MechanismType = MechanismType.PRESSURE_PLATE;
            let placedMech: boolean = false;

            if (biome === BiomeType.CRYSTAL) {
              if (mechR < mechDensity * 0.5) { mechType = MechanismType.CRYSTAL_REFLECTOR; placedMech = true; }
              else if (mechR < mechDensity * 0.8) { placedMech = true; }
            } else if (biome === BiomeType.MUSHROOM) {
              if (mechR < mechDensity * 0.5) { mechType = MechanismType.LEVER; placedMech = true; }
              else if (mechR < mechDensity * 0.8) { mechType = MechanismType.PUSH_BLOCK; placedMech = true; }
            } else if (biome === BiomeType.WATER) {
              if (mechR < mechDensity * 0.5) { mechType = MechanismType.LEVER; placedMech = true; }
              else if (mechR < mechDensity * 0.8) { mechType = MechanismType.TELEPORT_RUNE; placedMech = true; }
            } else if (biome === BiomeType.LAVA) {
              if (mechR < mechDensity * 0.5) { placedMech = true; }
              else if (mechR < mechDensity * 0.8) { mechType = MechanismType.LEVER; placedMech = true; }
            } else if (biome === BiomeType.SHADOW) {
              if (mechR < mechDensity * 0.5) { mechType = MechanismType.TELEPORT_RUNE; placedMech = true; }
              else if (mechR < mechDensity * 0.8) { mechType = MechanismType.CRYSTAL_REFLECTOR; placedMech = true; }
            } else {
              if (mechR < mechDensity * 0.4) { placedMech = true; }
              else if (mechR < mechDensity * 0.7) { mechType = MechanismType.PUSH_BLOCK; placedMech = true; }
              else if (mechR < mechDensity * 0.9) { mechType = MechanismType.BREAKABLE_WALL; placedMech = true; }
            }

            if (placedMech) {
              mechanisms.push({
                x: worldX, y: worldY,
                mechanismType: mechType,
                active: false,
                linkedIndex: -1,
                rotation: 0,
                pushable: mechType === MechanismType.PUSH_BLOCK,
                posX: worldX, posY: worldY
              });
            }
          }
        }
      }
    }
    return { enemies: enemies, traps: traps, mechanisms: mechanisms };
  }

  private generateSecretRooms(cx: number, cy: number, tiles: number[][], biome: BiomeType, distFromOrigin: number): SecretRoom[] {
    const rooms: SecretRoom[] = [];
    if (cx === 0 && cy === 0) return rooms;

    const size: number = CHUNK_SIZE;
    const chance: number = Math.min(0.005 + distFromOrigin * 0.001, 0.02);

    for (let ly: number = 3; ly < size - 3; ly++) {
      for (let lx: number = 3; lx < size - 3; lx++) {
        if (tiles[ly][lx] !== TileType.WALL) continue;
        const h: number = tileHash(lx + cx * size + 20000, ly + cy * size + 21000);
        const r: number = hashToFloat(h);
        if (r > chance) continue;

        const hasFloorAdjacent: boolean =
          (ly > 0 && tiles[ly - 1][lx] === TileType.FLOOR) ||
          (ly < size - 1 && tiles[ly + 1][lx] === TileType.FLOOR) ||
          (lx > 0 && tiles[ly][lx - 1] === TileType.FLOOR) ||
          (lx < size - 1 && tiles[ly][lx + 1] === TileType.FLOOR);

        if (!hasFloorAdjacent) continue;

        const worldX: number = (cx * size + lx) * TILE_SIZE + TILE_SIZE / 2;
        const worldY: number = (cy * size + ly) * TILE_SIZE + TILE_SIZE / 2;

        tiles[ly][lx] = TileType.BROKEN_WALL;

        const chestType: ChestType = distFromOrigin > 5 ? ChestType.ELITE : ChestType.NORMAL;
        rooms.push({
          chunkX: cx, chunkY: cy,
          wallTileX: lx, wallTileY: ly,
          revealed: false,
          chestType: chestType
        });
      }
    }
    return rooms;
  }

  // ==================== Chest Generation ====================

  private generateChests(cx: number, cy: number, tiles: number[][], size: number,
    secretRooms: SecretRoom[], distFromOrigin: number): ChestState[] {
    const chests: ChestState[] = [];
    if (cx === 0 && cy === 0) return chests;

    // Place elite chests inside secret rooms
    for (let i: number = 0; i < secretRooms.length; i++) {
      const room: SecretRoom = secretRooms[i];
      // Place chest one tile past the broken wall (inside the secret area)
      const wallWX: number = (cx * size + room.wallTileX) * TILE_SIZE + TILE_SIZE / 2;
      const wallWY: number = (cy * size + room.wallTileY) * TILE_SIZE + TILE_SIZE / 2;
      // Find adjacent floor tile to place chest
      let chestX: number = wallWX;
      let chestY: number = wallWY;
      const wtx: number = room.wallTileX;
      const wty: number = room.wallTileY;
      if (wty > 0 && tiles[wty - 1][wtx] === TileType.FLOOR) {
        chestY = wallWY - TILE_SIZE;
      } else if (wty < size - 1 && tiles[wty + 1][wtx] === TileType.FLOOR) {
        chestY = wallWY + TILE_SIZE;
      } else if (wtx > 0 && tiles[wty][wtx - 1] === TileType.FLOOR) {
        chestX = wallWX - TILE_SIZE;
      } else if (wtx < size - 1 && tiles[wty][wtx + 1] === TileType.FLOOR) {
        chestX = wallWX + TILE_SIZE;
      }
      chests.push({
        x: chestX, y: chestY,
        chestType: room.chestType,
        opened: false, active: true,
        guardianDefeated: true, guardianCount: 0,
        openAnim: 0
      });
    }

    // Place normal chests in open world (max 1 per chunk)
    const h: number = chunkHash(cx + 30000, cy + 40000);
    const r: number = hashToFloat(h);
    if (r > NORMAL_CHEST_CHANCE) return chests;

    // Find a suitable floor tile away from walls
    const startLx: number = 2 + (h % (size - 4));
    const startLy: number = 2 + ((h >> 8) % (size - 4));
    for (let attempt: number = 0; attempt < 20; attempt++) {
      const lx: number = (startLx + attempt * 3) % (size - 2) + 1;
      const ly: number = (startLy + attempt * 5) % (size - 2) + 1;
      if (tiles[ly][lx] !== TileType.FLOOR) continue;

      // Check not adjacent to walls (want open area)
      let wallAdj: boolean = false;
      for (let dy: number = -1; dy <= 1; dy++) {
        for (let dx: number = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          const ny: number = ly + dy;
          const nx: number = lx + dx;
          if (ny >= 0 && ny < size && nx >= 0 && nx < size) {
            if (tiles[ny][nx] === TileType.WALL) wallAdj = true;
          }
        }
      }
      if (wallAdj) continue;

      const worldX: number = (cx * size + lx) * TILE_SIZE + TILE_SIZE / 2;
      const worldY: number = (cy * size + ly) * TILE_SIZE + TILE_SIZE / 2;
      chests.push({
        x: worldX, y: worldY,
        chestType: ChestType.NORMAL,
        opened: false, active: true,
        guardianDefeated: true, guardianCount: 0,
        openAnim: 0
      });
      break; // max 1 normal chest per chunk
    }

    return chests;
  }

  // ==================== Boss Room Generation ====================

  private getBossTypeForBiome(biome: BiomeType): BossType | -1 {
    if (biome === BiomeType.CRYSTAL) return BossType.CRYSTAL_GUARDIAN;
    if (biome === BiomeType.WATER) return BossType.ABYSS_SIREN;
    if (biome === BiomeType.SHADOW) return BossType.VOID_RIFT;
    if (biome === BiomeType.MUSHROOM) return BossType.MUSHROOM_KING;
    if (biome === BiomeType.LAVA) return BossType.LAVA_BEAST;
    return -1;
  }

  private isPassageGuardianBiome(biome: BiomeType): boolean {
    return biome === BiomeType.CRYSTAL || biome === BiomeType.WATER || biome === BiomeType.SHADOW;
  }

  private isOptionalBossBiome(biome: BiomeType): boolean {
    return biome === BiomeType.MUSHROOM || biome === BiomeType.LAVA;
  }

  private tryPlacePassageGuardian(cx: number, cy: number, biome: BiomeType, distFromOrigin: number): BossRoom | null {
    if (!this.isPassageGuardianBiome(biome)) return null;
    if (distFromOrigin < 10) return null;

    // Check if this biome already has a boss room within 20 chunks
    const bossType: BossType = this.getBossTypeForBiome(biome) as BossType;
    for (let i: number = 0; i < this.bossRooms.length; i++) {
      const existing: BossRoom = this.bossRooms[i];
      if (existing.bossType === bossType) {
        const dx: number = cx - existing.chunkX;
        const dy: number = cy - existing.chunkY;
        if (Math.sqrt(dx * dx + dy * dy) < 20) return null;
      }
    }

    // Deterministic placement based on chunk hash
    const h: number = chunkHash(cx * 7 + 3000, cy * 7 + 4000);
    const r: number = hashToFloat(h);
    const chance: number = Math.min(0.03 + (distFromOrigin - 10) * 0.005, 0.12);
    if (r > chance) return null;

    const room: BossRoom = {
      chunkX: cx, chunkY: cy,
      bossType: bossType,
      entered: false,
      defeated: false,
      chestSpawned: false
    };
    this.bossRooms.push(room);
    return room;
  }

  private tryPlaceOptionalBoss(cx: number, cy: number, biome: BiomeType, distFromOrigin: number): BossState | null {
    if (!this.isOptionalBossBiome(biome)) return null;
    if (distFromOrigin < 15) return null;

    // Check if already defeated
    const key: string = cx + ',' + cy;
    if (this.defeatedOptionalBosses.indexOf(key) >= 0) return null;

    // Very rare spawn - deterministic per chunk
    const h: number = chunkHash(cx * 11 + 5000, cy * 11 + 6000);
    const r: number = hashToFloat(h);
    if (r > 0.015) return null;

    // Find a floor tile near center for placement
    const size: number = CHUNK_SIZE;
    const center: number = Math.floor(size / 2);
    let spawnLX: number = center;
    let spawnLY: number = center;
    let found: boolean = false;

    for (let radius: number = 1; radius <= 8 && !found; radius++) {
      for (let dy: number = -radius; dy <= radius && !found; dy++) {
        for (let dx: number = -radius; dx <= radius && !found; dx++) {
          const tx: number = center + dx;
          const ty: number = center + dy;
          if (tx >= 0 && tx < size && ty >= 0 && ty < size) {
            // Note: tiles may still have walls here since we haven't decorated yet
            // We'll use the center regardless - the boss is large and powerful
            spawnLX = tx;
            spawnLY = ty;
            found = true;
          }
        }
      }
    }

    const bossType: BossType = this.getBossTypeForBiome(biome) as BossType;
    const worldX: number = (cx * size + spawnLX) * TILE_SIZE + TILE_SIZE / 2;
    const worldY: number = (cy * size + spawnLY) * TILE_SIZE + TILE_SIZE / 2;

    return {
      x: worldX, y: worldY, vx: 0, vy: 0,
      hp: BOSS_HP, maxHp: BOSS_HP,
      bossType: bossType,
      bossRole: BossRole.OPTIONAL_CHALLENGE,
      phase: BossPhase.PHASE_1,
      active: true, defeated: false,
      attackTimer: 0, specialTimer: 0,
      hitFlash: 0, size: BOSS_SIZE,
      aggroRadius: OPTIONAL_CHALLENGE_AGGRO,
      extraData: []
    };
  }

  private generateBossRoomTiles(tiles: number[][], cx: number, cy: number, biome: BiomeType): void {
    const size: number = CHUNK_SIZE;
    const center: number = Math.floor(size / 2);
    const roomRadius: number = Math.floor(BOSS_ROOM_SIZE / 2); // 7

    // Step 1: Clear entire room area to FLOOR (15x15)
    for (let ly: number = 0; ly < size; ly++) {
      for (let lx: number = 0; lx < size; lx++) {
        const dx: number = lx - center;
        const dy: number = ly - center;
        if (Math.abs(dx) <= roomRadius && Math.abs(dy) <= roomRadius) {
          tiles[ly][lx] = TileType.FLOOR;
        }
      }
    }

    // Step 2: Clear approach corridors outside the room (2 tiles beyond each edge)
    const outerStart: number = roomRadius + 1;
    const outerEnd: number = roomRadius + 3;
    for (let d: number = -2; d <= 2; d++) {
      // Top corridor
      for (let ext: number = outerStart; ext <= outerEnd; ext++) {
        const ty: number = center - ext;
        const tx: number = center + d;
        if (ty >= 0 && ty < size && tx >= 0 && tx < size) tiles[ty][tx] = TileType.FLOOR;
      }
      // Bottom corridor
      for (let ext: number = outerStart; ext <= outerEnd; ext++) {
        const ty: number = center + ext;
        const tx: number = center + d;
        if (ty >= 0 && ty < size && tx >= 0 && tx < size) tiles[ty][tx] = TileType.FLOOR;
      }
      // Left corridor
      for (let ext: number = outerStart; ext <= outerEnd; ext++) {
        const tx: number = center - ext;
        const ty: number = center + d;
        if (tx >= 0 && tx < size && ty >= 0 && ty < size) tiles[ty][tx] = TileType.FLOOR;
      }
      // Right corridor
      for (let ext: number = outerStart; ext <= outerEnd; ext++) {
        const tx: number = center + ext;
        const ty: number = center + d;
        if (tx >= 0 && tx < size && ty >= 0 && ty < size) tiles[ty][tx] = TileType.FLOOR;
      }
    }

    // Step 3: Set WALL border ring around the room
    for (let ly: number = 0; ly < size; ly++) {
      for (let lx: number = 0; lx < size; lx++) {
        const dx: number = lx - center;
        const dy: number = ly - center;
        const maxD: number = Math.max(Math.abs(dx), Math.abs(dy));
        if (maxD === roomRadius + 1) {
          tiles[ly][lx] = TileType.WALL;
        }
      }
    }

    // Step 4: Create entrance gap (3 tiles wide, deterministic direction)
    const entranceHash: number = chunkHash(cx * 13 + 7000, cy * 13 + 8000);
    const dir: number = entranceHash % 4; // 0=top, 1=bottom, 2=left, 3=right

    if (dir === 0) {
      // Entrance on top side
      for (let d: number = -1; d <= 1; d++) {
        tiles[center - roomRadius][center + d] = TileType.FLOOR;
        tiles[center - roomRadius - 1][center + d] = TileType.FLOOR;
      }
    } else if (dir === 1) {
      // Entrance on bottom side
      for (let d: number = -1; d <= 1; d++) {
        tiles[center + roomRadius][center + d] = TileType.FLOOR;
        tiles[center + roomRadius + 1][center + d] = TileType.FLOOR;
      }
    } else if (dir === 2) {
      // Entrance on left side
      for (let d: number = -1; d <= 1; d++) {
        tiles[center + d][center - roomRadius] = TileType.FLOOR;
        tiles[center + d][center - roomRadius - 1] = TileType.FLOOR;
      }
    } else {
      // Entrance on right side
      for (let d: number = -1; d <= 1; d++) {
        tiles[center + d][center + roomRadius] = TileType.FLOOR;
        tiles[center + d][center + roomRadius + 1] = TileType.FLOOR;
      }
    }

    // Step 5: Biome-themed border decoration
    for (let ly: number = 0; ly < size; ly++) {
      for (let lx: number = 0; lx < size; lx++) {
        if (tiles[ly][lx] !== TileType.FLOOR) continue;
        const dx: number = lx - center;
        const dy: number = ly - center;
        const maxD: number = Math.max(Math.abs(dx), Math.abs(dy));
        if (maxD < roomRadius - 1) continue; // Only decorate border area

        const th: number = tileHash(lx + cx * size + 30000, ly + cy * size + 31000);
        const tr: number = hashToFloat(th);

        if (biome === BiomeType.CRYSTAL) {
          if (tr < 0.15) tiles[ly][lx] = TileType.CRYSTAL;
          else if (tr < 0.25) tiles[ly][lx] = TileType.GLOW_STONE;
        } else if (biome === BiomeType.WATER) {
          if (tr < 0.12) tiles[ly][lx] = TileType.PLANT;
        } else if (biome === BiomeType.SHADOW) {
          if (tr < 0.10) tiles[ly][lx] = TileType.GLOW_STONE;
        }
      }
    }
  }
}
