import { Entity } from './Entity';
import { System, SystemContext } from './System';
import { PositionComponent } from './Component';
import { SpatialGrid } from './SpatialGrid';

export class World {
  private entities: Entity[] = [];
  private systems: System[] = [];
  private spatialGrid: SpatialGrid<Entity> = new SpatialGrid<Entity>(128);
  chunks: Map<string, Object> = new Map<string, Object>();
  worldGen: Object | null = null;
  cameraX: number = 0;
  cameraY: number = 0;

  addEntity(entity: Entity): Entity {
    this.entities.push(entity);
    return entity;
  }

  removeEntity(entity: Entity): void {
    entity.active = false;
  }

  addSystem(system: System): void {
    this.systems.push(system);
  }

  query(componentType: string): Entity[] {
    const result: Entity[] = [];
    for (let i: number = 0; i < this.entities.length; i++) {
      const e: Entity = this.entities[i];
      if (e.active && e.hasComponent(componentType)) {
        result.push(e);
      }
    }
    return result;
  }

  queryWithTag(tag: string): Entity[] {
    const result: Entity[] = [];
    for (let i: number = 0; i < this.entities.length; i++) {
      const e: Entity = this.entities[i];
      if (e.active && e.tag === tag) {
        result.push(e);
      }
    }
    return result;
  }

  findEntityByTag(tag: string): Entity | null {
    for (let i: number = 0; i < this.entities.length; i++) {
      if (this.entities[i].active && this.entities[i].tag === tag) {
        return this.entities[i];
      }
    }
    return null;
  }

  rebuildSpatialGrid(): void {
    this.spatialGrid.clear();
    for (let i: number = 0; i < this.entities.length; i++) {
      const e: Entity = this.entities[i];
      if (e.active && e.hasComponent("Position")) {
        const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
        this.spatialGrid.insert(pos.x, pos.y, e);
      }
    }
  }

  getSpatialGrid(): SpatialGrid<Entity> {
    return this.spatialGrid;
  }

  getEntities(): Entity[] {
    return this.entities;
  }

  private updateFrameCount: number = 0;

  update(context: SystemContext, dt: number): void {
    const fc: number = this.updateFrameCount;
    if (fc < 5) {
      console.log('[World] update frame=' + fc + ' systems=' + this.systems.length + ' entities=' + this.entities.length + ' chunks=' + this.chunks.size + ' worldGen=' + (this.worldGen !== null));
    }
    for (let i: number = 0; i < this.systems.length; i++) {
      const sys: System = this.systems[i];
      if (sys.isEnabled()) {
        try {
          sys.update(this.entities, context);
        } catch (e) {
          console.error('[World] System #' + i + ' error: ' + String(e));
        }
      }
    }
    this.entities = this.entities.filter((e: Entity) => e.active);
    this.updateFrameCount++;
  }
}
