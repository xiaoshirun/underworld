import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';

export class SpatialRebuildSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const grid = context.world.getSpatialGrid();
    grid.clear();
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (e.active && e.hasComponent("Position")) {
        const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
        grid.insert(pos.x, pos.y, e);
      }
    }
  }
}
