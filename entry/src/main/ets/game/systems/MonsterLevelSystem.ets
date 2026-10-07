import { System, SystemContext, Entity } from '@qiuyu/engine';
import { MONSTER_MIN_LEVEL, MONSTER_MAX_LEVEL } from '../GameConstants';

export class MonsterLevelSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    // No per-frame logic — level assignment happens at spawn time in ChunkLoadSystem
  }

  static calculateLevel(chunkDistance: number): number {
    // chunkDistance = max(|dx|, |dy|) from spawn chunk
    let minLevel: number = MONSTER_MIN_LEVEL;
    let maxLevel: number = MONSTER_MIN_LEVEL;

    if (chunkDistance <= 2) {
      minLevel = 1; maxLevel = 2;
    } else if (chunkDistance <= 5) {
      minLevel = 2; maxLevel = 4;
    } else if (chunkDistance <= 8) {
      minLevel = 3; maxLevel = 6;
    } else {
      minLevel = 5; maxLevel = MONSTER_MAX_LEVEL;
    }

    return minLevel + Math.floor(Math.random() * (maxLevel - minLevel + 1));
  }
}
