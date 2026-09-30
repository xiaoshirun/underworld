import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { EnemyFactory } from '../factories/EnemyFactory';
import { WorldEntityFactory } from '../factories/WorldEntityFactory';
import { BossFactory } from '../factories/BossFactory';
import { CHUNK_SIZE, TILE_SIZE, CHUNK_LOAD_RADIUS, ChunkData, SlimeState, TrapInstance, MechanismInstance, ChestState, BossState } from '../GameConstants';
import { WorldGenerator } from '../WorldGenerator';
import { MonsterLevelSystem } from './MonsterLevelSystem';

export class ChunkLoadSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const pos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    if (pos === null) return;

    const worldGen: WorldGenerator | null = context.world.worldGen as WorldGenerator | null;
    if (worldGen === null) return;

    const chunks: Map<string, Object> = context.world.chunks;

    const ptx: number = Math.floor(pos.x / TILE_SIZE);
    const pty: number = Math.floor(pos.y / TILE_SIZE);
    const pcx: number = Math.floor(ptx / CHUNK_SIZE);
    const pcy: number = Math.floor(pty / CHUNK_SIZE);

    for (let dy: number = -CHUNK_LOAD_RADIUS; dy <= CHUNK_LOAD_RADIUS; dy++) {
      for (let dx: number = -CHUNK_LOAD_RADIUS; dx <= CHUNK_LOAD_RADIUS; dx++) {
        const cx: number = pcx + dx;
        const cy: number = pcy + dy;
        const key: string = cx + ',' + cy;

        if (!chunks.has(key)) {
          const chunk: ChunkData = worldGen.generateChunk(cx, cy);
          chunks.set(key, chunk as Object);

          // Create enemy entities from chunk data
          const enemies: SlimeState[] = chunk.enemies;
          const chunkDist: number = Math.max(Math.abs(cx), Math.abs(cy));
          for (let i: number = 0; i < enemies.length; i++) {
            const e: SlimeState = enemies[i];
            const level: number = MonsterLevelSystem.calculateLevel(chunkDist);
            const enemy: Entity = EnemyFactory.createSlime(e.x, e.y, e.enemyType as number, level);
            context.world.addEntity(enemy);
          }

          // Create trap entities
          const traps: TrapInstance[] = chunk.traps;
          for (let i: number = 0; i < traps.length; i++) {
            const t: TrapInstance = traps[i];
            const trapEntity: Entity = WorldEntityFactory.createTrap(t.x, t.y, t.trapType as number);
            context.world.addEntity(trapEntity);
          }

          // Create mechanism entities
          const mechanisms: MechanismInstance[] = chunk.mechanisms;
          for (let i: number = 0; i < mechanisms.length; i++) {
            const m: MechanismInstance = mechanisms[i];
            const mechEntity: Entity = WorldEntityFactory.createMechanism(m.x, m.y, m.mechanismType as number);
            context.world.addEntity(mechEntity);
          }

          // Create chest entities
          const chests: ChestState[] = chunk.chests;
          for (let i: number = 0; i < chests.length; i++) {
            const c: ChestState = chests[i];
            const chestEntity: Entity = WorldEntityFactory.createChest(c.x, c.y, c.chestType as number);
            context.world.addEntity(chestEntity);
          }

          // Create boss entities
          const bosses: BossState[] = chunk.bosses;
          for (let i: number = 0; i < bosses.length; i++) {
            const b: BossState = bosses[i];
            const bossEntity: Entity = BossFactory.create(b.x, b.y, b.bossType as number, b.bossRole as number);
            context.world.addEntity(bossEntity);
          }
        }
      }
    }
  }
}
