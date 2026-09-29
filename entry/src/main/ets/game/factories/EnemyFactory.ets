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
    // 根据 EnemyType 返回不同 HP，参考现有 SlimeState 初始化逻辑
    switch (enemyType) {
      case EnemyType.CRYSTAL: return SLIME_HP;
      case EnemyType.MUSHROOM: return SLIME_HP + 1;
      case EnemyType.FLAME: return SLIME_HP;
      case EnemyType.ABYSS: return SLIME_HP + 2;
      case EnemyType.VOID: return SLIME_HP + 1;
      case EnemyType.TOXIC: return SLIME_HP;
      default: return SLIME_HP;
    }
  }

  private static getSizeForType(enemyType: number): number {
    return SLIME_SIZE;
  }
}
