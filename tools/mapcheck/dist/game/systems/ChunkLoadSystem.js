"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChunkLoadSystem = void 0;
const engine_1 = require("@qiuyu/engine");
const EnemyFactory_1 = require("../factories/EnemyFactory");
const WorldEntityFactory_1 = require("../factories/WorldEntityFactory");
const BossFactory_1 = require("../factories/BossFactory");
const GameConstants_1 = require("../GameConstants");
const MonsterLevelSystem_1 = require("./MonsterLevelSystem");
const HumanoidBeastSystem_1 = require("./HumanoidBeastSystem");
const MAX_CHUNKS_PER_FRAME = 2;
class ChunkLoadSystem extends engine_1.System {
    constructor() {
        super(...arguments);
        this.loggedFirstLoad = false;
        this.totalLoaded = 0;
        this.diagFrame = 0;
    }
    update(entities, context) {
        const fc = context.frameCount;
        if (fc < 10) {
            console.log('[ChunkLoadSystem] frame=' + fc + ' entities=' + entities.length + ' worldGen=' + (context.world.worldGen !== null) + ' chunks=' + context.world.chunks.size);
        }
        const player = context.world.findEntityByTag("player");
        if (player === null) {
            if (fc < 10)
                console.error('[ChunkLoadSystem] PLAYER NOT FOUND by tag!');
            return;
        }
        if (fc < 10) {
            console.log('[ChunkLoadSystem] Player found: id=' + player.id + ' active=' + player.active);
        }
        const pos = player.getComponent("Position");
        if (pos === null) {
            if (fc < 10)
                console.error('[ChunkLoadSystem] Player has NO Position component!');
            return;
        }
        const worldGen = context.world.worldGen;
        if (worldGen === null) {
            if (fc < 10)
                console.error('[ChunkLoadSystem] worldGen is NULL!');
            return;
        }
        const chunks = context.world.chunks;
        const ptx = Math.floor(pos.x / GameConstants_1.TILE_SIZE);
        const pty = Math.floor(pos.y / GameConstants_1.TILE_SIZE);
        const pcx = Math.floor(ptx / GameConstants_1.CHUNK_SIZE);
        const pcy = Math.floor(pty / GameConstants_1.CHUNK_SIZE);
        if (fc < 10) {
            console.log('[ChunkLoadSystem] pos=(' + pos.x.toFixed(0) + ',' + pos.y.toFixed(0) + ') tile=(' + ptx + ',' + pty + ') chunk=(' + pcx + ',' + pcy + ')');
        }
        const pending = [];
        for (let dy = -GameConstants_1.CHUNK_LOAD_RADIUS; dy <= GameConstants_1.CHUNK_LOAD_RADIUS; dy++) {
            for (let dx = -GameConstants_1.CHUNK_LOAD_RADIUS; dx <= GameConstants_1.CHUNK_LOAD_RADIUS; dx++) {
                const cx = pcx + dx;
                const cy = pcy + dy;
                const key = cx + ',' + cy;
                if (!chunks.has(key)) {
                    pending.push([cx, cy, dx * dx + dy * dy]);
                }
            }
        }
        if (pending.length === 0)
            return;
        pending.sort((a, b) => a[2] - b[2]);
        const toLoad = pending.length < MAX_CHUNKS_PER_FRAME ? pending.length : MAX_CHUNKS_PER_FRAME;
        for (let i = 0; i < toLoad; i++) {
            const cx = pending[i][0];
            const cy = pending[i][1];
            const key = cx + ',' + cy;
            if (chunks.has(key))
                continue;
            try {
                const chunk = worldGen.generateChunk(cx, cy);
                chunks.set(key, chunk);
                this.totalLoaded++;
                const chunkDist = Math.max(Math.abs(cx), Math.abs(cy));
                const enemies = chunk.enemies;
                for (let j = 0; j < enemies.length; j++) {
                    const e = enemies[j];
                    const level = MonsterLevelSystem_1.MonsterLevelSystem.calculateLevel(chunkDist);
                    let enemyType = e.enemyType;
                    if (chunkDist > 2 && HumanoidBeastSystem_1.HumanoidBeastSystem.shouldReplaceWithHumanoid()) {
                        enemyType = HumanoidBeastSystem_1.HumanoidBeastSystem.getHumanoidType();
                    }
                    const enemy = EnemyFactory_1.EnemyFactory.createSlime(e.x, e.y, enemyType, level);
                    context.world.addEntity(enemy);
                }
                const traps = chunk.traps;
                for (let j = 0; j < traps.length; j++) {
                    const t = traps[j];
                    const trapEntity = WorldEntityFactory_1.WorldEntityFactory.createTrap(t.x, t.y, t.trapType);
                    context.world.addEntity(trapEntity);
                }
                const mechanisms = chunk.mechanisms;
                for (let j = 0; j < mechanisms.length; j++) {
                    const m = mechanisms[j];
                    const mechEntity = WorldEntityFactory_1.WorldEntityFactory.createMechanism(m.x, m.y, m.mechanismType);
                    context.world.addEntity(mechEntity);
                }
                const chests = chunk.chests;
                for (let j = 0; j < chests.length; j++) {
                    const c = chests[j];
                    const chestEntity = WorldEntityFactory_1.WorldEntityFactory.createChest(c.x, c.y, c.chestType);
                    context.world.addEntity(chestEntity);
                }
                const bosses = chunk.bosses;
                for (let j = 0; j < bosses.length; j++) {
                    const b = bosses[j];
                    const bossEntity = BossFactory_1.BossFactory.create(b.x, b.y, b.bossType, b.bossRole);
                    context.world.addEntity(bossEntity);
                }
                if (!this.loggedFirstLoad) {
                    console.log('[ChunkLoadSystem] First chunk loaded: (' + cx + ',' + cy + ') total=' + this.totalLoaded + ' pending=' + pending.length);
                    this.loggedFirstLoad = true;
                }
            }
            catch (e) {
                console.error('[ChunkLoadSystem] Failed to load chunk (' + cx + ',' + cy + '): ' + String(e));
            }
        }
        if (this.totalLoaded >= 49 && this.loggedFirstLoad) {
            console.log('[ChunkLoadSystem] All chunks loaded: ' + this.totalLoaded + ' chunks');
        }
    }
}
exports.ChunkLoadSystem = ChunkLoadSystem;
