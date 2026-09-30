import { System, SystemContext, Entity } from '@qiuyu/engine';

export class CleanupSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    // World.update() 在系统循环后已执行 filter
    // 此系统作为显式清理步骤，处理需要额外清理逻辑的情况
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active) {
        // 移除所有组件引用，帮助 GC
        const components = e.getAllComponents();
        for (let j: number = 0; j < components.length; j++) {
          e.removeComponent(components[j].getType());
        }
      }
    }
  }
}
