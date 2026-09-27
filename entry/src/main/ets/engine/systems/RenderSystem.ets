import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class RenderSystem extends System {
  readonly name: string = 'render';
  readonly dependencies: string[] = [];
  priority: number = 100;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: integrate SpriteBatch rendering
  }

  render(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void {
    // Phase 2: draw all Sprite+Transform entities sorted by zIndex
  }
}
