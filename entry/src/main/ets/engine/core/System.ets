import { Entity } from './Entity';
import { World } from './World';

export abstract class System {
  abstract readonly name: string;
  abstract readonly dependencies: string[];
  priority: number = 0;
  enabled: boolean = true;

  abstract update(world: World, dt: number, entities: Entity[]): void;

  render?(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void;

  onAdd?(world: World): void;
  onRemove?(world: World): void;
}
