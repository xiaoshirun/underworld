import { Entity, PositionComponent, VelocityComponent, HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { BossAIComponent } from '../components/BossAIComponent';
import { BOSS_HP, BOSS_SIZE } from '../GameConstants';

export class BossFactory {
  static create(x: number, y: number, bossType: number, bossRole: number): Entity {
    const entity: Entity = new Entity("boss");
    entity.addComponent(new PositionComponent(x, y));
    entity.addComponent(new VelocityComponent(0, 0));
    entity.addComponent(new HealthComponent(BOSS_HP, BOSS_HP));

    const ai: BossAIComponent = new BossAIComponent();
    ai.bossType = bossType;
    ai.bossRole = bossRole;
    entity.addComponent(ai);

    entity.addComponent(new ColliderComponent(BOSS_SIZE, BOSS_SIZE, 0, 0, false));
    return entity;
  }
}
