import { System, SystemContext, Entity } from '@qiuyu/engine';
import { HUMANOID_SPAWN_CHANCE, EnemyType } from '../GameConstants';

export class HumanoidBeastSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    // No per-frame logic — spawn check happens in ChunkLoadSystem
  }

  static shouldReplaceWithHumanoid(): boolean {
    return Math.random() < HUMANOID_SPAWN_CHANCE;
  }

  static getHumanoidType(): number {
    return EnemyType.HUMANOID_BEAST;
  }
}
