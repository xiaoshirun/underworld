import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class PhysicsSystem extends System {
  readonly name: string = 'physics';
  readonly dependencies: string[] = [];
  priority: number = 10;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: wrap PhysicsEngine, handle RigidBody+Collider
  }
}
