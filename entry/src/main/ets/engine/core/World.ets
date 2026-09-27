import { Entity, EntityPool, getIndex } from './Entity';
import { System } from './System';

interface ComponentEntry {
  data: Map<number, Object>;
}

export class World {
  private pool: EntityPool = new EntityPool();
  private components: Map<string, ComponentEntry> = new Map();
  private systems: System[] = [];
  private systemsByName: Map<string, System> = new Map();
  private pendingDestroy: Entity[] = [];
  private queryCache: Map<string, Entity[]> = new Map();
  private cacheDirty: Set<string> = new Set();
  private indexToEntity: Map<number, Entity> = new Map();

  createEntity(): Entity {
    const entity: Entity = this.pool.acquire();
    this.indexToEntity.set(getIndex(entity), entity);
    this.invalidateAllQueries();
    return entity;
  }

  destroyEntity(entity: Entity): void {
    this.pendingDestroy.push(entity);
  }

  private processPendingDestroys(): void {
    if (this.pendingDestroy.length === 0) return;
    for (const entity of this.pendingDestroy) {
      if (!this.pool.isValid(entity)) continue;
      const index: number = getIndex(entity);
      this.components.forEach((entry: ComponentEntry) => {
        entry.data.delete(index);
      });
      this.indexToEntity.delete(index);
      this.pool.release(entity);
    }
    this.pendingDestroy = [];
    this.invalidateAllQueries();
  }

  addComponent<T extends Object>(entity: Entity, tag: string, component: T): void {
    const index: number = getIndex(entity);
    let entry: ComponentEntry | undefined = this.components.get(tag);
    if (!entry) {
      entry = { data: new Map<number, Object>() };
      this.components.set(tag, entry);
    }
    entry.data.set(index, component);
    this.invalidateQueriesFor(tag);
  }

  getComponent<T>(entity: Entity, tag: string): T | undefined {
    const index: number = getIndex(entity);
    const entry: ComponentEntry | undefined = this.components.get(tag);
    if (!entry) return undefined;
    return entry.data.get(index) as T | undefined;
  }

  removeComponent(entity: Entity, tag: string): void {
    const index: number = getIndex(entity);
    const entry: ComponentEntry | undefined = this.components.get(tag);
    if (!entry) return;
    entry.data.delete(index);
    this.invalidateQueriesFor(tag);
  }

  hasComponent(entity: Entity, tag: string): boolean {
    const index: number = getIndex(entity);
    const entry: ComponentEntry | undefined = this.components.get(tag);
    if (!entry) return false;
    return entry.data.has(index);
  }

  query(...tags: string[]): Entity[] {
    const cacheKey: string = tags.sort().join(',');
    const cached: Entity[] | undefined = this.queryCache.get(cacheKey);
    if (cached && !this.cacheDirty.has(cacheKey)) {
      return cached;
    }

    const result: Entity[] = [];
    const entries: ComponentEntry[] = [];
    for (const tag of tags) {
      const entry: ComponentEntry | undefined = this.components.get(tag);
      if (!entry) {
        this.queryCache.set(cacheKey, []);
        return [];
      }
      entries.push(entry);
    }

    entries.sort((a: ComponentEntry, b: ComponentEntry): number => a.data.size - b.data.size);
    const smallest: Map<number, Object> = entries[0].data;

    smallest.forEach((_value: Object, index: number) => {
      let match: boolean = true;
      for (let i: number = 1; i < entries.length; i++) {
        if (!entries[i].data.has(index)) {
          match = false;
          break;
        }
      }
      if (match) {
        const fullEntity: Entity | undefined = this.indexToEntity.get(index);
        if (fullEntity !== undefined) {
          result.push(fullEntity);
        }
      }
    });

    this.queryCache.set(cacheKey, result);
    this.cacheDirty.delete(cacheKey);
    return result;
  }

  addSystem(system: System): void {
    this.systems.push(system);
    this.systemsByName.set(system.name, system);
    this.sortSystems();
    if (system.onAdd) {
      system.onAdd(this);
    }
  }

  removeSystem(name: string): void {
    const system: System | undefined = this.systemsByName.get(name);
    if (!system) return;
    if (system.onRemove) {
      system.onRemove(this);
    }
    const idx: number = this.systems.indexOf(system);
    if (idx >= 0) this.systems.splice(idx, 1);
    this.systemsByName.delete(name);
  }

  getSystem(name: string): System | undefined {
    return this.systemsByName.get(name);
  }

  update(dt: number): void {
    for (const system of this.systems) {
      if (!system.enabled) continue;
      const entities: Entity[] = this.query();
      system.update(this, dt, entities);
    }
    this.processPendingDestroys();
  }

  render(ctx: CanvasRenderingContext2D): void {
    for (const system of this.systems) {
      if (!system.enabled || !system.render) continue;
      const entities: Entity[] = this.query();
      system.render(this, ctx, entities);
    }
  }

  isEntityAlive(entity: Entity): boolean {
    return this.pool.isValid(entity);
  }

  getEntityCount(): number {
    return this.pool.count();
  }

  private sortSystems(): void {
    this.systems.sort((a: System, b: System): number => {
      if (a.priority !== b.priority) return a.priority - b.priority;
      if (a.dependencies.indexOf(b.name) >= 0) return 1;
      if (b.dependencies.indexOf(a.name) >= 0) return -1;
      return 0;
    });
  }

  private invalidateQueriesFor(tag: string): void {
    this.queryCache.forEach((_value: Entity[], key: string) => {
      const tags: string[] = key.split(',');
      if (tags.indexOf(tag) >= 0) {
        this.cacheDirty.add(key);
      }
    });
  }

  private invalidateAllQueries(): void {
    this.queryCache.forEach((_value: Entity[], key: string) => {
      this.cacheDirty.add(key);
    });
  }
}
