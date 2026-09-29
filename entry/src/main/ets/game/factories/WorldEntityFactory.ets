import { Entity, PositionComponent, ColliderComponent } from '@qiuyu/engine';
import { TrapComponent } from '../components/TrapComponent';
import { MechanismComponent } from '../components/MechanismComponent';
import { ChestComponent } from '../components/ChestComponent';

export class WorldEntityFactory {
  static createTrap(x: number, y: number, trapType: number): Entity {
    const entity: Entity = new Entity("trap");
    entity.addComponent(new PositionComponent(x, y));
    const trap: TrapComponent = new TrapComponent();
    trap.trapType = trapType;
    entity.addComponent(trap);
    entity.addComponent(new ColliderComponent(16, 16, 0, 0, false));
    return entity;
  }

  static createMechanism(x: number, y: number, mechanismType: number): Entity {
    const entity: Entity = new Entity("mechanism");
    entity.addComponent(new PositionComponent(x, y));
    const mech: MechanismComponent = new MechanismComponent();
    mech.mechanismType = mechanismType;
    mech.posX = x;
    mech.posY = y;
    entity.addComponent(mech);
    entity.addComponent(new ColliderComponent(16, 16, 0, 0, true));
    return entity;
  }

  static createChest(x: number, y: number, chestType: number): Entity {
    const entity: Entity = new Entity("chest");
    entity.addComponent(new PositionComponent(x, y));
    const chest: ChestComponent = new ChestComponent();
    chest.chestType = chestType;
    entity.addComponent(chest);
    entity.addComponent(new ColliderComponent(16, 16, 0, 0, true));
    return entity;
  }
}
