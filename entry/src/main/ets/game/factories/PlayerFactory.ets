import { Entity, PositionComponent, VelocityComponent, HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { XpComponent } from '../components/XpComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { PLAYER_MAX_HP } from '../GameConstants';

export class PlayerFactory {
  static create(startX: number, startY: number): Entity {
    const entity: Entity = new Entity("player");
    entity.addComponent(new PositionComponent(startX, startY));
    entity.addComponent(new VelocityComponent(0, 0));
    entity.addComponent(new HealthComponent(PLAYER_MAX_HP, PLAYER_MAX_HP));
    entity.addComponent(new MovementComponent());
    entity.addComponent(new CombatComponent());
    entity.addComponent(new TransformComponent());
    entity.addComponent(new InventoryComponent());
    entity.addComponent(new XpComponent());
    entity.addComponent(new EvolutionComponent());
    entity.addComponent(new ColliderComponent(20, 20, 0, 0));
    return entity;
  }
}
