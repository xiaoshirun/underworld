// entry/src/main/ets/engine/systems/RenderSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { Transform } from '../components/Transform';
import { Sprite } from '../components/Sprite';
import { SpriteBatch } from '../internal/SpriteBatch';

interface RenderItem {
  zIndex: number;
  entity: Entity;
}

export class RenderSystem extends System {
  readonly name: string = 'render';
  readonly dependencies: string[] = [];
  priority: number = 100;

  private batch: SpriteBatch = new SpriteBatch();
  private screenWidth: number = 960;
  private screenHeight: number = 540;

  setScreenSize(w: number, h: number): void {
    this.screenWidth = w;
    this.screenHeight = h;
  }

  update(world: World, dt: number, entities: Entity[]): void {
    // No update logic needed; all work is in render()
  }

  render(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void {
    this.batch.clear();

    const items: RenderItem[] = [];
    const sprites: Entity[] = world.query('sprite', 'transform');

    for (const e of sprites) {
      const sprite: Sprite | undefined = world.getComponent<Sprite>(e, 'sprite');
      const transform: Transform | undefined = world.getComponent<Transform>(e, 'transform');
      if (!sprite || !transform || !sprite.visible) continue;

      if (transform.x + sprite.width < 0 || transform.x > this.screenWidth ||
        transform.y + sprite.height < 0 || transform.y > this.screenHeight) {
        continue;
      }

      items.push({ zIndex: transform.zIndex, entity: e });
    }

    items.sort((a: RenderItem, b: RenderItem): number => a.zIndex - b.zIndex);

    for (const item of items) {
      const sprite: Sprite | undefined = world.getComponent<Sprite>(item.entity, 'sprite');
      const transform: Transform | undefined = world.getComponent<Transform>(item.entity, 'transform');
      if (!sprite || !transform) continue;

      this.batch.addRect(
        transform.x, transform.y,
        sprite.width * transform.scaleX,
        sprite.height * transform.scaleY,
        sprite.color, sprite.alpha
      );
    }

    this.batch.flush(ctx);
  }

  getBatch(): SpriteBatch {
    return this.batch;
  }
}
