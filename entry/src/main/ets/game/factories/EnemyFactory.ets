import { Entity, PositionComponent, VelocityComponent, HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { EnemyType, SLIME_SIZE, SLIME_HP } from '../GameConstants';

export class EnemyFactory {
  static createSlime(x: number, y: number, enemyType: number): Entity {
    const entity: Entity = new Entity("enemy");
    entity.addComponent(new PositionComponent(x, y));
    entity.addComponent(new VelocityComponent(0, 0));

    const hp: number = EnemyFactory.getHpForType(enemyType);
    entity.addComponent(new HealthComponent(hp, hp));

    const ai: EnemyAIComponent = new EnemyAIComponent();
    ai.enemyType = enemyType;
    ai.size = EnemyFactory.getSizeForType(enemyType);
    entity.addComponent(ai);

    const size: number = ai.size;
    entity.addComponent(new ColliderComponent(size, size, 0, 0, false));
    return entity;
  }

  private static getHpForType(enemyType: number): number {
    switch (enemyType) {
      case EnemyType.GRAY_SLIME: return SLIME_HP;
      case EnemyType.PURPLE_SLIME: return SLIME_HP + 1;
      case EnemyType.RED_SLIME: return SLIME_HP + 2;
      case EnemyType.BLUE_SLIME: return SLIME_HP;
      case EnemyType.YELLOW_SLIME: return SLIME_HP + 1;
      case EnemyType.GHOST_SLIME: return SLIME_HP + 1;
      default: return SLIME_HP;
    }
  }

  private static getSizeForType(enemyType: number): number {
    return SLIME_SIZE;
  }
}
