import { Entity, PositionComponent, VelocityComponent, HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { EnemyType, SLIME_SIZE, SLIME_HP, MONSTER_HP_SCALE_PER_LEVEL, MONSTER_SIZE_PER_4_LEVELS, HUMANOID_BEAST_HP } from '../GameConstants';

export class EnemyFactory {
  static createSlime(x: number, y: number, enemyType: number, level: number = 1): Entity {
    const entity: Entity = new Entity("enemy");
    entity.addComponent(new PositionComponent(x, y));
    entity.addComponent(new VelocityComponent(0, 0));

    const baseHp: number = EnemyFactory.getHpForType(enemyType);
    const scaledHp: number = Math.floor(baseHp * (1 + (level - 1) * MONSTER_HP_SCALE_PER_LEVEL));
    entity.addComponent(new HealthComponent(scaledHp, scaledHp));

    const ai: EnemyAIComponent = new EnemyAIComponent();
    ai.enemyType = enemyType;
    ai.level = level;
    ai.size = SLIME_SIZE + Math.floor(level / MONSTER_SIZE_PER_4_LEVELS);
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
      case EnemyType.HUMANOID_BEAST: return HUMANOID_BEAST_HP;
      default: return SLIME_HP;
    }
  }
}
