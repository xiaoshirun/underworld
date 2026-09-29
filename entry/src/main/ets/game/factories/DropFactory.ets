import { Entity, PositionComponent } from '@qiuyu/engine';
import { XpPickupComponent } from '../components/XpPickupComponent';
import { MaterialPickupComponent } from '../components/MaterialPickupComponent';
import { TransformCorePickupComponent } from '../components/TransformCorePickupComponent';

export class DropFactory {
  static createXpOrb(x: number, y: number, value: number): Entity {
    const entity: Entity = new Entity("xpOrb");
    entity.addComponent(new PositionComponent(x, y));
    const pickup: XpPickupComponent = new XpPickupComponent();
    pickup.xpValue = value;
    entity.addComponent(pickup);
    return entity;
  }

  static createMaterialDrop(x: number, y: number, materialType: number, amount: number): Entity {
    const entity: Entity = new Entity("materialDrop");
    entity.addComponent(new PositionComponent(x, y));
    const pickup: MaterialPickupComponent = new MaterialPickupComponent();
    pickup.materialType = materialType;
    pickup.amount = amount;
    pickup.bobPhase = Math.random() * Math.PI * 2;
    entity.addComponent(pickup);
    return entity;
  }

  static createTransformCore(x: number, y: number, form: number, rarity: number): Entity {
    const entity: Entity = new Entity("transformCore");
    entity.addComponent(new PositionComponent(x, y));
    const pickup: TransformCorePickupComponent = new TransformCorePickupComponent();
    pickup.form = form;
    pickup.rarity = rarity;
    entity.addComponent(pickup);
    return entity;
  }
}
