import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { EnemyFactory } from '../factories/EnemyFactory';
import { WorldEntityFactory } from '../factories/WorldEntityFactory';
import { BossFactory } from '../factories/BossFactory';
import { CHUNK_SIZE, TILE_SIZE, CHUNK_LOAD_RADIUS, ChunkData, SlimeState, TrapInstance, MechanismInstance, ChestState, BossState } from '../GameConstants';
import { WorldGenerator } from '../WorldGenerator';
import { MonsterLevelSystem } from './MonsterLevelSystem';
import { HumanoidBeastSystem } from './HumanoidBeastSystem';

const MAX_CHUNKS_PER_FRAME: number = 2;

export class ChunkLoadSystem extends System {
  private loggedFirstLoad: boolean = false;
  private totalLoaded: number = 0;
  private diagFrame: number = 0;

  update(entities: Entity[], context: SystemContext): void {
    const fc: number = context.frameCount;

    if (fc < 10) {
      console.log('[ChunkLoadSystem] frame=' + fc + ' entities=' + entities.length + ' worldGen=' + (context.world.worldGen !== null) + ' chunks=' + context.world.chunks.size);
    }

    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) {
      if (fc < 10) console.error('[ChunkLoadSystem] PLAYER NOT FOUND by tag!');
      return;
    }

    if (fc < 10) {
      console.log('[ChunkLoadSystem] Player found: id=' + player.id + ' active=' + player.active);
    }

    const pos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    if (pos === null) {
      if (fc < 10) console.error('[ChunkLoadSystem] Player has NO Position component!');
      return;
    }

    const worldGen: WorldGenerator | null = context.world.worldGen as WorldGenerator | null;
    if (worldGen === null) {
      if (fc < 10) console.error('[ChunkLoadSystem] worldGen is NULL!');
      return;
    }

    const chunks: Map<string, Object> = context.world.chunks;

    const ptx: number = Math.floor(pos.x / TILE_SIZE);
    const pty: number = Math.floor(pos.y / TILE_SIZE);
    const pcx: number = Math.floor(ptx / CHUNK_SIZE);
    const pcy: number = Math.floor(pty / CHUNK_SIZE);

    if (fc < 10) {
      console.log('[ChunkLoadSystem] pos=(' + pos.x.toFixed(0) + ',' + pos.y.toFixed(0) + ') tile=(' + ptx + ',' + pty + ') chunk=(' + pcx + ',' + pcy + ')');
    }

    const pending: number[][] = [];
    for (let dy: number = -CHUNK_LOAD_RADIUS; dy <= CHUNK_LOAD_RADIUS; dy++) {
      for (let dx: number = -CHUNK_LOAD_RADIUS; dx <= CHUNK_LOAD_RADIUS; dx++) {
        const cx: number = pcx + dx;
        const cy: number = pcy + dy;
        const key: string = cx + ',' + cy;
        if (!chunks.has(key)) {
          pending.push([cx, cy, dx * dx + dy * dy]);
        }
      }
    }

    if (pending.length === 0) return;

    pending.sort((a: number[], b: number[]): number => a[2] - b[2]);

    const toLoad: number = pending.length < MAX_CHUNKS_PER_FRAME ? pending.length : MAX_CHUNKS_PER_FRAME;
    for (let i: number = 0; i < toLoad; i++) {
      const cx: number = pending[i][0];
      const cy: number = pending[i][1];
      const key: string = cx + ',' + cy;
      if (chunks.has(key)) continue;

      try {
        const chunk: ChunkData = worldGen.generateChunk(cx, cy);
        chunks.set(key, chunk as Object);
        this.totalLoaded++;

        const chunkDist: number = Math.max(Math.abs(cx), Math.abs(cy));

        const enemies: SlimeState[] = chunk.enemies;
        for (let j: number = 0; j < enemies.length; j++) {
          const e: SlimeState = enemies[j];
          const level: number = MonsterLevelSystem.calculateLevel(chunkDist);
          let enemyType: number = e.enemyType as number;
          if (chunkDist > 2 && HumanoidBeastSystem.shouldReplaceWithHumanoid()) {
            enemyType = HumanoidBeastSystem.getHumanoidType();
          }
          const enemy: Entity = EnemyFactory.createSlime(e.x, e.y, enemyType, level);
          context.world.addEntity(enemy);
        }

        const traps: TrapInstance[] = chunk.traps;
        for (let j: number = 0; j < traps.length; j++) {
          const t: TrapInstance = traps[j];
          const trapEntity: Entity = WorldEntityFactory.createTrap(t.x, t.y, t.trapType as number);
          context.world.addEntity(trapEntity);
        }

        const mechanisms: MechanismInstance[] = chunk.mechanisms;
        for (let j: number = 0; j < mechanisms.length; j++) {
          const m: MechanismInstance = mechanisms[j];
          const mechEntity: Entity = WorldEntityFactory.createMechanism(m.x, m.y, m.mechanismType as number);
          context.world.addEntity(mechEntity);
        }

        const chests: ChestState[] = chunk.chests;
        for (let j: number = 0; j < chests.length; j++) {
          const c: ChestState = chests[j];
          const chestEntity: Entity = WorldEntityFactory.createChest(c.x, c.y, c.chestType as number);
          context.world.addEntity(chestEntity);
        }

        const bosses: BossState[] = chunk.bosses;
        for (let j: number = 0; j < bosses.length; j++) {
          const b: BossState = bosses[j];
          const bossEntity: Entity = BossFactory.create(b.x, b.y, b.bossType as number, b.bossRole as number);
          context.world.addEntity(bossEntity);
        }

        if (!this.loggedFirstLoad) {
          console.log('[ChunkLoadSystem] First chunk loaded: (' + cx + ',' + cy + ') total=' + this.totalLoaded + ' pending=' + pending.length);
          this.loggedFirstLoad = true;
        }
      } catch (e) {
        console.error('[ChunkLoadSystem] Failed to load chunk (' + cx + ',' + cy + '): ' + String(e));
      }
    }

    if (this.totalLoaded >= 49 && this.loggedFirstLoad) {
      console.log('[ChunkLoadSystem] All chunks loaded: ' + this.totalLoaded + ' chunks');
    }
  }
}
