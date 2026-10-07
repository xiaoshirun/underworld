"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WorldGenerator = void 0;
const GameConstants_1 = require("./GameConstants");
function chunkHash(cx, cy) {
    let h = (cx * 374761393 + cy * 668265263) | 0;
    h = ((h ^ (h >> 13)) * 1274126177) | 0;
    return (h ^ (h >> 16)) >>> 0;
}
function tileHash(tx, ty) {
    let h = (tx * 73856093 ^ ty * 19349663) | 0;
    h = ((h ^ (h >> 13)) * 83492791) | 0;
    return (h ^ (h >> 16)) >>> 0;
}
function hashToFloat(h) {
    return (h % 100000) / 100000;
}
function lerp(a, b, t) {
    return a + (b - a) * t;
}
function fade(t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
}
function valueNoise2D(x, y) {
    const xi = Math.floor(x);
    const yi = Math.floor(y);
    const xf = x - xi;
    const yf = y - yi;
    const u = fade(xf);
    const v = fade(yf);
    const n00 = hashToFloat(tileHash(xi, yi));
    const n10 = hashToFloat(tileHash(xi + 1, yi));
    const n01 = hashToFloat(tileHash(xi, yi + 1));
    const n11 = hashToFloat(tileHash(xi + 1, yi + 1));
    return lerp(lerp(n00, n10, u), lerp(n01, n11, u), v);
}
function fbm(x, y, octaves) {
    let value = 0;
    let amplitude = 1;
    let frequency = 1;
    let maxValue = 0;
    for (let i = 0; i < octaves; i++) {
        value += amplitude * valueNoise2D(x * frequency, y * frequency);
        maxValue += amplitude;
        amplitude *= 0.5;
        frequency *= 2;
    }
    return value / maxValue;
}
class WorldGenerator {
    constructor() {
        this.bossRooms = [];
        this.placedBossBiomes = []; // biome values that have a Passage Guardian placed
        this.defeatedOptionalBosses = []; // "cx,cy" keys
    }
    getBiome(worldX, worldY) {
        const temp = valueNoise2D(worldX * GameConstants_1.BIOME_SCALE, worldY * GameConstants_1.BIOME_SCALE);
        const moist = valueNoise2D((worldX + 500) * GameConstants_1.BIOME_SCALE, (worldY + 500) * GameConstants_1.BIOME_SCALE);
        const dist = Math.sqrt(worldX * worldX + worldY * worldY) * 0.001;
        if (dist > 0.5 && temp < 0.3 && moist > 0.5)
            return GameConstants_1.BiomeType.SHADOW;
        if (temp < 0.25)
            return GameConstants_1.BiomeType.WATER;
        if (temp > 0.75 && moist < 0.4)
            return GameConstants_1.BiomeType.LAVA;
        if (moist > 0.65)
            return GameConstants_1.BiomeType.MUSHROOM;
        if (temp > 0.55 && moist > 0.4)
            return GameConstants_1.BiomeType.CRYSTAL;
        return GameConstants_1.BiomeType.NORMAL;
    }
    getBossRooms() {
        return this.bossRooms;
    }
    markOptionalBossDefeated(cx, cy) {
        const key = cx + ',' + cy;
        if (this.defeatedOptionalBosses.indexOf(key) < 0) {
            this.defeatedOptionalBosses.push(key);
        }
    }
    generateChunk(cx, cy) {
        const size = GameConstants_1.CHUNK_SIZE;
        const tiles = [];
        if (cx === 0 && cy === 0) {
            for (let ly = 0; ly < size; ly++) {
                tiles[ly] = [];
                for (let lx = 0; lx < size; lx++) {
                    const wx = lx;
                    const wy = ly;
                    const noiseVal = fbm(wx * GameConstants_1.NOISE_SCALE, wy * GameConstants_1.NOISE_SCALE, 4);
                    tiles[ly][lx] = noiseVal < GameConstants_1.CAVE_THRESHOLD ? GameConstants_1.TileType.WALL : GameConstants_1.TileType.FLOOR;
                }
            }
            const center = Math.floor(size / 2);
            const clearR = 6;
            for (let dy = -clearR; dy <= clearR; dy++) {
                for (let dx = -clearR; dx <= clearR; dx++) {
                    const tx = center + dx;
                    const ty = center + dy;
                    if (tx >= 0 && tx < size && ty >= 0 && ty < size && dx * dx + dy * dy <= clearR * clearR) {
                        tiles[ty][tx] = GameConstants_1.TileType.FLOOR;
                    }
                }
            }
            return {
                tiles: tiles, enemies: [], generated: true,
                bosses: [], chests: [], traps: [], mechanisms: [], secretRooms: [],
                isBossRoom: false
            };
        }
        const noiseGrid = [];
        for (let ly = 0; ly < size; ly++) {
            noiseGrid[ly] = [];
            for (let lx = 0; lx < size; lx++) {
                const wx = cx * size + lx;
                const wy = cy * size + ly;
                noiseGrid[ly][lx] = fbm(wx * GameConstants_1.NOISE_SCALE, wy * GameConstants_1.NOISE_SCALE, 4);
            }
        }
        const biomeOriginX = cx * size;
        const biomeOriginY = cy * size;
        const chunkBiome = this.getBiome(biomeOriginX + size / 2, biomeOriginY + size / 2);
        const distFromOrigin = Math.sqrt(cx * cx + cy * cy);
        // 逐瓦片按世界坐标求 biome 阈值：若整块共用区块中心的阈值偏移，
        // 相邻区块 biome 分类不同处会出现地形接缝（同一噪声值边界两侧映射不同瓦片）。
        // biome 噪声本身按世界坐标连续，逐瓦片求值后阈值在边界两侧完全一致。
        // 坐标用像素中心，与渲染器 getBiome(camX, camY) 的像素约定一致，
        // 保证背景主题色与实际地形 biome 对应。
        for (let ly = 0; ly < size; ly++) {
            tiles[ly] = [];
            for (let lx = 0; lx < size; lx++) {
                let threshold = GameConstants_1.CAVE_THRESHOLD;
                const tileBiome = this.getBiome((cx * size + lx) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2, (cy * size + ly) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2);
                if (tileBiome === GameConstants_1.BiomeType.WATER)
                    threshold += 0.08;
                else if (tileBiome === GameConstants_1.BiomeType.LAVA)
                    threshold += 0.05;
                else if (tileBiome === GameConstants_1.BiomeType.CRYSTAL)
                    threshold -= 0.05;
                tiles[ly][lx] = noiseGrid[ly][lx] < threshold ? GameConstants_1.TileType.WALL : GameConstants_1.TileType.FLOOR;
            }
        }
        const passageRoom = this.tryPlacePassageGuardian(cx, cy, chunkBiome, distFromOrigin);
        let optionalBoss = null;
        if (passageRoom === null) {
            optionalBoss = this.tryPlaceOptionalBoss(cx, cy, chunkBiome, distFromOrigin);
        }
        const isBossRoom = passageRoom !== null;
        if (isBossRoom) {
            this.generateBossRoomTiles(tiles, cx, cy, chunkBiome);
            const bosses = [];
            if (passageRoom !== null) {
                const bossX = (cx * size + Math.floor(size / 2)) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
                const bossY = (cy * size + Math.floor(size / 2)) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
                bosses.push({
                    x: bossX, y: bossY, vx: 0, vy: 0,
                    hp: GameConstants_1.BOSS_HP, maxHp: GameConstants_1.BOSS_HP,
                    bossType: passageRoom.bossType,
                    bossRole: GameConstants_1.BossRole.PASSAGE_GUARDIAN,
                    phase: GameConstants_1.BossPhase.PHASE_1,
                    active: false, defeated: false,
                    attackTimer: 0, specialTimer: 0,
                    hitFlash: 0, size: GameConstants_1.BOSS_SIZE,
                    aggroRadius: GameConstants_1.PASSAGE_GUARDIAN_AGGRO,
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
        const secretRooms = this.generateSecretRooms(cx, cy, tiles, chunkBiome, distFromOrigin);
        const chests = this.generateChests(cx, cy, tiles, size, secretRooms, distFromOrigin);
        const chunkBoss = [];
        if (optionalBoss !== null) {
            chunkBoss.push(optionalBoss);
        }
        return {
            tiles: tiles, enemies: entities.enemies, generated: true,
            bosses: chunkBoss, chests: chests, traps: entities.traps,
            mechanisms: entities.mechanisms, secretRooms: secretRooms, isBossRoom: false
        };
    }
    generateEntities(cx, cy, tiles, size, biome, distFromOrigin) {
        const enemies = [];
        const traps = [];
        const mechanisms = [];
        const trapDensity = Math.min(0.02 + distFromOrigin * 0.003, 0.08);
        const mechDensity = Math.min(0.01 + distFromOrigin * 0.002, 0.04);
        for (let ly = 0; ly < size; ly++) {
            for (let lx = 0; lx < size; lx++) {
                if (tiles[ly][lx] !== GameConstants_1.TileType.FLOOR)
                    continue;
                const worldX = (cx * size + lx) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
                const worldY = (cy * size + ly) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
                const decH = tileHash(lx + cx * size + 1000, ly + cy * size + 2000);
                const decR = hashToFloat(decH);
                let decorated = false;
                // 逐瓦片求 biome：装饰与地形阈值一样，用世界坐标而非区块中心，
                // 避免相邻区块 biome 分类不同处边界装饰不匹配（如 SHADOW 化墙）。
                const tileBiome = this.getBiome((cx * size + lx) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2, (cy * size + ly) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2);
                if (tileBiome === GameConstants_1.BiomeType.MUSHROOM) {
                    if (decR < 0.06) {
                        tiles[ly][lx] = GameConstants_1.TileType.MUSHROOM;
                        decorated = true;
                    }
                    else if (decR < 0.10) {
                        tiles[ly][lx] = GameConstants_1.TileType.PLANT;
                        decorated = true;
                    }
                }
                else if (tileBiome === GameConstants_1.BiomeType.CRYSTAL) {
                    if (decR < 0.05) {
                        tiles[ly][lx] = GameConstants_1.TileType.CRYSTAL;
                        decorated = true;
                    }
                    else if (decR < 0.08) {
                        tiles[ly][lx] = GameConstants_1.TileType.GLOW_STONE;
                        decorated = true;
                    }
                }
                else if (tileBiome === GameConstants_1.BiomeType.WATER) {
                    if (decR < 0.03) {
                        tiles[ly][lx] = GameConstants_1.TileType.PLANT;
                        decorated = true;
                    }
                }
                else if (tileBiome === GameConstants_1.BiomeType.LAVA) {
                    if (decR < 0.02) {
                        tiles[ly][lx] = GameConstants_1.TileType.GLOW_STONE;
                        decorated = true;
                    }
                }
                else if (tileBiome === GameConstants_1.BiomeType.SHADOW) {
                    if (decR < 0.04) {
                        tiles[ly][lx] = GameConstants_1.TileType.GLOW_STONE;
                        decorated = true;
                    }
                    else if (decR < 0.06) {
                        tiles[ly][lx] = GameConstants_1.TileType.WALL;
                        decorated = true;
                    }
                }
                else {
                    if (decR < 0.015) {
                        tiles[ly][lx] = GameConstants_1.TileType.GLOW_STONE;
                        decorated = true;
                    }
                    else if (decR < 0.035) {
                        tiles[ly][lx] = GameConstants_1.TileType.PLANT;
                        decorated = true;
                    }
                }
                if (decorated)
                    continue;
                const enemyH = tileHash(lx + cx * size + 5000, ly + cy * size + 6000);
                const enemyR = hashToFloat(enemyH);
                let enemyType = GameConstants_1.EnemyType.GRAY_SLIME;
                let shouldPlaceEnemy = false;
                if (tileBiome === GameConstants_1.BiomeType.MUSHROOM) {
                    if (enemyR < 0.03) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.YELLOW_SLIME;
                    }
                    else if (enemyR < 0.05) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.GRAY_SLIME;
                    }
                }
                else if (tileBiome === GameConstants_1.BiomeType.CRYSTAL) {
                    if (enemyR < 0.02) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.GHOST_SLIME;
                    }
                    else if (enemyR < 0.04) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.PURPLE_SLIME;
                    }
                }
                else if (tileBiome === GameConstants_1.BiomeType.LAVA) {
                    if (enemyR < 0.03) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.RED_SLIME;
                    }
                    else if (enemyR < 0.05) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.PURPLE_SLIME;
                    }
                }
                else if (tileBiome === GameConstants_1.BiomeType.WATER) {
                    if (enemyR < 0.03) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.BLUE_SLIME;
                    }
                    else if (enemyR < 0.05) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.GRAY_SLIME;
                    }
                }
                else {
                    if (enemyR < 0.015) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.GRAY_SLIME;
                    }
                    else if (enemyR < 0.025) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.PURPLE_SLIME;
                    }
                    else if (enemyR < 0.03) {
                        shouldPlaceEnemy = true;
                        enemyType = GameConstants_1.EnemyType.BLUE_SLIME;
                    }
                }
                if (shouldPlaceEnemy) {
                    enemies.push({
                        x: worldX, y: worldY, vx: 0, vy: 0,
                        hp: GameConstants_1.SLIME_HP, maxHp: GameConstants_1.SLIME_HP,
                        enemyType: enemyType, active: true,
                        bouncePhase: hashToFloat(enemyH + 1) * Math.PI * 2,
                        hitFlash: 0, moveTimer: 0, targetX: 0, targetY: 0,
                        isEngulfing: false, engulfedPlayer: false,
                        size: GameConstants_1.SLIME_SIZE, chargeTimer: 0, isCharging: false, splitCount: 0
                    });
                }
                if (lx >= 2 && lx < size - 2 && ly >= 2 && ly < size - 2) {
                    const trapH = tileHash(lx + cx * size + 9000, ly + cy * size + 10000);
                    const trapR = hashToFloat(trapH);
                    if (trapR <= trapDensity) {
                        let trapType = GameConstants_1.TrapType.GROUND_SPIKES;
                        let placedTrap = false;
                        if (tileBiome === GameConstants_1.BiomeType.MUSHROOM) {
                            if (trapR < trapDensity * 0.5) {
                                trapType = GameConstants_1.TrapType.POISON_SPORES;
                                placedTrap = true;
                            }
                            else if (trapR < trapDensity * 0.8) {
                                trapType = GameConstants_1.TrapType.FALLING_ROCKS;
                                placedTrap = true;
                            }
                        }
                        else if (tileBiome === GameConstants_1.BiomeType.WATER) {
                            if (trapR < trapDensity * 0.7) {
                                trapType = GameConstants_1.TrapType.WATER_VORTEX;
                                placedTrap = true;
                            }
                        }
                        else if (tileBiome === GameConstants_1.BiomeType.LAVA) {
                            if (trapR < trapDensity * 0.5) {
                                trapType = GameConstants_1.TrapType.LAVA_GEYSER;
                                placedTrap = true;
                            }
                            else if (trapR < trapDensity * 0.8) {
                                trapType = GameConstants_1.TrapType.FALLING_ROCKS;
                                placedTrap = true;
                            }
                        }
                        else if (tileBiome === GameConstants_1.BiomeType.CRYSTAL) {
                            if (trapR < trapDensity * 0.7) {
                                placedTrap = true;
                            }
                        }
                        else if (tileBiome === GameConstants_1.BiomeType.SHADOW) {
                            if (trapR < trapDensity * 0.7) {
                                trapType = GameConstants_1.TrapType.VOID_CRACK;
                                placedTrap = true;
                            }
                        }
                        else {
                            if (trapR < trapDensity * 0.5) {
                                placedTrap = true;
                            }
                            else if (trapR < trapDensity * 0.8) {
                                trapType = GameConstants_1.TrapType.FALLING_ROCKS;
                                placedTrap = true;
                            }
                        }
                        if (placedTrap) {
                            traps.push({
                                x: worldX, y: worldY,
                                trapType: trapType,
                                state: GameConstants_1.TrapState.IDLE,
                                timer: 0,
                                triggerRadius: GameConstants_1.TRAP_TRIGGER_RADIUS,
                                damage: GameConstants_1.TRAP_DAMAGE,
                                size: GameConstants_1.TRAP_SIZE,
                                extraData: [0, 0]
                            });
                        }
                    }
                    const mechH = tileHash(lx + cx * size + 15000, ly + cy * size + 16000);
                    const mechR = hashToFloat(mechH);
                    if (mechR <= mechDensity) {
                        let mechType = GameConstants_1.MechanismType.PRESSURE_PLATE;
                        let placedMech = false;
                        if (tileBiome === GameConstants_1.BiomeType.CRYSTAL) {
                            if (mechR < mechDensity * 0.5) {
                                mechType = GameConstants_1.MechanismType.CRYSTAL_REFLECTOR;
                                placedMech = true;
                            }
                            else if (mechR < mechDensity * 0.8) {
                                placedMech = true;
                            }
                        }
                        else if (tileBiome === GameConstants_1.BiomeType.MUSHROOM) {
                            if (mechR < mechDensity * 0.5) {
                                mechType = GameConstants_1.MechanismType.LEVER;
                                placedMech = true;
                            }
                            else if (mechR < mechDensity * 0.8) {
                                mechType = GameConstants_1.MechanismType.PUSH_BLOCK;
                                placedMech = true;
                            }
                        }
                        else if (tileBiome === GameConstants_1.BiomeType.WATER) {
                            if (mechR < mechDensity * 0.5) {
                                mechType = GameConstants_1.MechanismType.LEVER;
                                placedMech = true;
                            }
                            else if (mechR < mechDensity * 0.8) {
                                mechType = GameConstants_1.MechanismType.TELEPORT_RUNE;
                                placedMech = true;
                            }
                        }
                        else if (tileBiome === GameConstants_1.BiomeType.LAVA) {
                            if (mechR < mechDensity * 0.5) {
                                placedMech = true;
                            }
                            else if (mechR < mechDensity * 0.8) {
                                mechType = GameConstants_1.MechanismType.LEVER;
                                placedMech = true;
                            }
                        }
                        else if (tileBiome === GameConstants_1.BiomeType.SHADOW) {
                            if (mechR < mechDensity * 0.5) {
                                mechType = GameConstants_1.MechanismType.TELEPORT_RUNE;
                                placedMech = true;
                            }
                            else if (mechR < mechDensity * 0.8) {
                                mechType = GameConstants_1.MechanismType.CRYSTAL_REFLECTOR;
                                placedMech = true;
                            }
                        }
                        else {
                            if (mechR < mechDensity * 0.4) {
                                placedMech = true;
                            }
                            else if (mechR < mechDensity * 0.7) {
                                mechType = GameConstants_1.MechanismType.PUSH_BLOCK;
                                placedMech = true;
                            }
                            else if (mechR < mechDensity * 0.9) {
                                mechType = GameConstants_1.MechanismType.BREAKABLE_WALL;
                                placedMech = true;
                            }
                        }
                        if (placedMech) {
                            mechanisms.push({
                                x: worldX, y: worldY,
                                mechanismType: mechType,
                                active: false,
                                linkedIndex: -1,
                                rotation: 0,
                                pushable: mechType === GameConstants_1.MechanismType.PUSH_BLOCK,
                                posX: worldX, posY: worldY
                            });
                        }
                    }
                }
            }
        }
        return { enemies: enemies, traps: traps, mechanisms: mechanisms };
    }
    generateSecretRooms(cx, cy, tiles, biome, distFromOrigin) {
        const rooms = [];
        if (cx === 0 && cy === 0)
            return rooms;
        const size = GameConstants_1.CHUNK_SIZE;
        const chance = Math.min(0.005 + distFromOrigin * 0.001, 0.02);
        for (let ly = 3; ly < size - 3; ly++) {
            for (let lx = 3; lx < size - 3; lx++) {
                if (tiles[ly][lx] !== GameConstants_1.TileType.WALL)
                    continue;
                const h = tileHash(lx + cx * size + 20000, ly + cy * size + 21000);
                const r = hashToFloat(h);
                if (r > chance)
                    continue;
                const hasFloorAdjacent = (ly > 0 && tiles[ly - 1][lx] === GameConstants_1.TileType.FLOOR) ||
                    (ly < size - 1 && tiles[ly + 1][lx] === GameConstants_1.TileType.FLOOR) ||
                    (lx > 0 && tiles[ly][lx - 1] === GameConstants_1.TileType.FLOOR) ||
                    (lx < size - 1 && tiles[ly][lx + 1] === GameConstants_1.TileType.FLOOR);
                if (!hasFloorAdjacent)
                    continue;
                const worldX = (cx * size + lx) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
                const worldY = (cy * size + ly) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
                tiles[ly][lx] = GameConstants_1.TileType.BROKEN_WALL;
                const chestType = distFromOrigin > 5 ? GameConstants_1.ChestType.ELITE : GameConstants_1.ChestType.NORMAL;
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
    generateChests(cx, cy, tiles, size, secretRooms, distFromOrigin) {
        const chests = [];
        if (cx === 0 && cy === 0)
            return chests;
        // Place elite chests inside secret rooms
        for (let i = 0; i < secretRooms.length; i++) {
            const room = secretRooms[i];
            // Place chest one tile past the broken wall (inside the secret area)
            const wallWX = (cx * size + room.wallTileX) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
            const wallWY = (cy * size + room.wallTileY) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
            // Find adjacent floor tile to place chest
            let chestX = wallWX;
            let chestY = wallWY;
            const wtx = room.wallTileX;
            const wty = room.wallTileY;
            if (wty > 0 && tiles[wty - 1][wtx] === GameConstants_1.TileType.FLOOR) {
                chestY = wallWY - GameConstants_1.TILE_SIZE;
            }
            else if (wty < size - 1 && tiles[wty + 1][wtx] === GameConstants_1.TileType.FLOOR) {
                chestY = wallWY + GameConstants_1.TILE_SIZE;
            }
            else if (wtx > 0 && tiles[wty][wtx - 1] === GameConstants_1.TileType.FLOOR) {
                chestX = wallWX - GameConstants_1.TILE_SIZE;
            }
            else if (wtx < size - 1 && tiles[wty][wtx + 1] === GameConstants_1.TileType.FLOOR) {
                chestX = wallWX + GameConstants_1.TILE_SIZE;
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
        const h = chunkHash(cx + 30000, cy + 40000);
        const r = hashToFloat(h);
        if (r > GameConstants_1.NORMAL_CHEST_CHANCE)
            return chests;
        // Find a suitable floor tile away from walls
        const startLx = 2 + (h % (size - 4));
        const startLy = 2 + ((h >> 8) % (size - 4));
        for (let attempt = 0; attempt < 20; attempt++) {
            const lx = (startLx + attempt * 3) % (size - 2) + 1;
            const ly = (startLy + attempt * 5) % (size - 2) + 1;
            if (tiles[ly][lx] !== GameConstants_1.TileType.FLOOR)
                continue;
            // Check not adjacent to walls (want open area)
            let wallAdj = false;
            for (let dy = -1; dy <= 1; dy++) {
                for (let dx = -1; dx <= 1; dx++) {
                    if (dx === 0 && dy === 0)
                        continue;
                    const ny = ly + dy;
                    const nx = lx + dx;
                    if (ny >= 0 && ny < size && nx >= 0 && nx < size) {
                        if (tiles[ny][nx] === GameConstants_1.TileType.WALL)
                            wallAdj = true;
                    }
                }
            }
            if (wallAdj)
                continue;
            const worldX = (cx * size + lx) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
            const worldY = (cy * size + ly) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
            chests.push({
                x: worldX, y: worldY,
                chestType: GameConstants_1.ChestType.NORMAL,
                opened: false, active: true,
                guardianDefeated: true, guardianCount: 0,
                openAnim: 0
            });
            break; // max 1 normal chest per chunk
        }
        return chests;
    }
    // ==================== Boss Room Generation ====================
    getBossTypeForBiome(biome) {
        if (biome === GameConstants_1.BiomeType.CRYSTAL)
            return GameConstants_1.BossType.CRYSTAL_GUARDIAN;
        if (biome === GameConstants_1.BiomeType.WATER)
            return GameConstants_1.BossType.ABYSS_SIREN;
        if (biome === GameConstants_1.BiomeType.SHADOW)
            return GameConstants_1.BossType.VOID_RIFT;
        if (biome === GameConstants_1.BiomeType.MUSHROOM)
            return GameConstants_1.BossType.MUSHROOM_KING;
        if (biome === GameConstants_1.BiomeType.LAVA)
            return GameConstants_1.BossType.LAVA_BEAST;
        return -1;
    }
    isPassageGuardianBiome(biome) {
        return biome === GameConstants_1.BiomeType.CRYSTAL || biome === GameConstants_1.BiomeType.WATER || biome === GameConstants_1.BiomeType.SHADOW;
    }
    isOptionalBossBiome(biome) {
        return biome === GameConstants_1.BiomeType.MUSHROOM || biome === GameConstants_1.BiomeType.LAVA;
    }
    tryPlacePassageGuardian(cx, cy, biome, distFromOrigin) {
        if (!this.isPassageGuardianBiome(biome))
            return null;
        if (distFromOrigin < 10)
            return null;
        // Check if this biome already has a boss room within 20 chunks
        const bossType = this.getBossTypeForBiome(biome);
        for (let i = 0; i < this.bossRooms.length; i++) {
            const existing = this.bossRooms[i];
            if (existing.bossType === bossType) {
                const dx = cx - existing.chunkX;
                const dy = cy - existing.chunkY;
                if (Math.sqrt(dx * dx + dy * dy) < 20)
                    return null;
            }
        }
        // Deterministic placement based on chunk hash
        const h = chunkHash(cx * 7 + 3000, cy * 7 + 4000);
        const r = hashToFloat(h);
        const chance = Math.min(0.03 + (distFromOrigin - 10) * 0.005, 0.12);
        if (r > chance)
            return null;
        const room = {
            chunkX: cx, chunkY: cy,
            bossType: bossType,
            entered: false,
            defeated: false,
            chestSpawned: false
        };
        this.bossRooms.push(room);
        return room;
    }
    tryPlaceOptionalBoss(cx, cy, biome, distFromOrigin) {
        if (!this.isOptionalBossBiome(biome))
            return null;
        if (distFromOrigin < 15)
            return null;
        // Check if already defeated
        const key = cx + ',' + cy;
        if (this.defeatedOptionalBosses.indexOf(key) >= 0)
            return null;
        // Very rare spawn - deterministic per chunk
        const h = chunkHash(cx * 11 + 5000, cy * 11 + 6000);
        const r = hashToFloat(h);
        if (r > 0.015)
            return null;
        // Find a floor tile near center for placement
        const size = GameConstants_1.CHUNK_SIZE;
        const center = Math.floor(size / 2);
        let spawnLX = center;
        let spawnLY = center;
        let found = false;
        for (let radius = 1; radius <= 8 && !found; radius++) {
            for (let dy = -radius; dy <= radius && !found; dy++) {
                for (let dx = -radius; dx <= radius && !found; dx++) {
                    const tx = center + dx;
                    const ty = center + dy;
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
        const bossType = this.getBossTypeForBiome(biome);
        const worldX = (cx * size + spawnLX) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
        const worldY = (cy * size + spawnLY) * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
        return {
            x: worldX, y: worldY, vx: 0, vy: 0,
            hp: GameConstants_1.BOSS_HP, maxHp: GameConstants_1.BOSS_HP,
            bossType: bossType,
            bossRole: GameConstants_1.BossRole.OPTIONAL_CHALLENGE,
            phase: GameConstants_1.BossPhase.PHASE_1,
            active: true, defeated: false,
            attackTimer: 0, specialTimer: 0,
            hitFlash: 0, size: GameConstants_1.BOSS_SIZE,
            aggroRadius: GameConstants_1.OPTIONAL_CHALLENGE_AGGRO,
            extraData: []
        };
    }
    generateBossRoomTiles(tiles, cx, cy, biome) {
        const size = GameConstants_1.CHUNK_SIZE;
        const center = Math.floor(size / 2);
        const roomRadius = Math.floor(GameConstants_1.BOSS_ROOM_SIZE / 2); // 7
        // Step 1: Clear entire room area to FLOOR (15x15)
        for (let ly = 0; ly < size; ly++) {
            for (let lx = 0; lx < size; lx++) {
                const dx = lx - center;
                const dy = ly - center;
                if (Math.abs(dx) <= roomRadius && Math.abs(dy) <= roomRadius) {
                    tiles[ly][lx] = GameConstants_1.TileType.FLOOR;
                }
            }
        }
        // Step 2: Clear approach corridors outside the room (2 tiles beyond each edge)
        const outerStart = roomRadius + 1;
        const outerEnd = roomRadius + 3;
        for (let d = -2; d <= 2; d++) {
            // Top corridor
            for (let ext = outerStart; ext <= outerEnd; ext++) {
                const ty = center - ext;
                const tx = center + d;
                if (ty >= 0 && ty < size && tx >= 0 && tx < size)
                    tiles[ty][tx] = GameConstants_1.TileType.FLOOR;
            }
            // Bottom corridor
            for (let ext = outerStart; ext <= outerEnd; ext++) {
                const ty = center + ext;
                const tx = center + d;
                if (ty >= 0 && ty < size && tx >= 0 && tx < size)
                    tiles[ty][tx] = GameConstants_1.TileType.FLOOR;
            }
            // Left corridor
            for (let ext = outerStart; ext <= outerEnd; ext++) {
                const tx = center - ext;
                const ty = center + d;
                if (tx >= 0 && tx < size && ty >= 0 && ty < size)
                    tiles[ty][tx] = GameConstants_1.TileType.FLOOR;
            }
            // Right corridor
            for (let ext = outerStart; ext <= outerEnd; ext++) {
                const tx = center + ext;
                const ty = center + d;
                if (tx >= 0 && tx < size && ty >= 0 && ty < size)
                    tiles[ty][tx] = GameConstants_1.TileType.FLOOR;
            }
        }
        // Step 3: Set WALL border ring around the room
        for (let ly = 0; ly < size; ly++) {
            for (let lx = 0; lx < size; lx++) {
                const dx = lx - center;
                const dy = ly - center;
                const maxD = Math.max(Math.abs(dx), Math.abs(dy));
                if (maxD === roomRadius + 1) {
                    tiles[ly][lx] = GameConstants_1.TileType.WALL;
                }
            }
        }
        // Step 4: Create entrance gap (3 tiles wide, deterministic direction)
        const entranceHash = chunkHash(cx * 13 + 7000, cy * 13 + 8000);
        const dir = entranceHash % 4; // 0=top, 1=bottom, 2=left, 3=right
        if (dir === 0) {
            // Entrance on top side
            for (let d = -1; d <= 1; d++) {
                tiles[center - roomRadius][center + d] = GameConstants_1.TileType.FLOOR;
                tiles[center - roomRadius - 1][center + d] = GameConstants_1.TileType.FLOOR;
            }
        }
        else if (dir === 1) {
            // Entrance on bottom side
            for (let d = -1; d <= 1; d++) {
                tiles[center + roomRadius][center + d] = GameConstants_1.TileType.FLOOR;
                tiles[center + roomRadius + 1][center + d] = GameConstants_1.TileType.FLOOR;
            }
        }
        else if (dir === 2) {
            // Entrance on left side
            for (let d = -1; d <= 1; d++) {
                tiles[center + d][center - roomRadius] = GameConstants_1.TileType.FLOOR;
                tiles[center + d][center - roomRadius - 1] = GameConstants_1.TileType.FLOOR;
            }
        }
        else {
            // Entrance on right side
            for (let d = -1; d <= 1; d++) {
                tiles[center + d][center + roomRadius] = GameConstants_1.TileType.FLOOR;
                tiles[center + d][center + roomRadius + 1] = GameConstants_1.TileType.FLOOR;
            }
        }
        // Step 5: Biome-themed border decoration
        for (let ly = 0; ly < size; ly++) {
            for (let lx = 0; lx < size; lx++) {
                if (tiles[ly][lx] !== GameConstants_1.TileType.FLOOR)
                    continue;
                const dx = lx - center;
                const dy = ly - center;
                const maxD = Math.max(Math.abs(dx), Math.abs(dy));
                if (maxD < roomRadius - 1)
                    continue; // Only decorate border area
                const th = tileHash(lx + cx * size + 30000, ly + cy * size + 31000);
                const tr = hashToFloat(th);
                if (biome === GameConstants_1.BiomeType.CRYSTAL) {
                    if (tr < 0.15)
                        tiles[ly][lx] = GameConstants_1.TileType.CRYSTAL;
                    else if (tr < 0.25)
                        tiles[ly][lx] = GameConstants_1.TileType.GLOW_STONE;
                }
                else if (biome === GameConstants_1.BiomeType.WATER) {
                    if (tr < 0.12)
                        tiles[ly][lx] = GameConstants_1.TileType.PLANT;
                }
                else if (biome === GameConstants_1.BiomeType.SHADOW) {
                    if (tr < 0.10)
                        tiles[ly][lx] = GameConstants_1.TileType.GLOW_STONE;
                }
            }
        }
    }
}
exports.WorldGenerator = WorldGenerator;
