import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class InputSystem extends System {
  readonly name: string = 'input';
  readonly dependencies: string[] = [];
  priority: number = 0;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: consume platform input, write PlayerInput components
  }
}
