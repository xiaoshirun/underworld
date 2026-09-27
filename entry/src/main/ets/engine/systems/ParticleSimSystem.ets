import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class ParticleSimSystem extends System {
  readonly name: string = 'particleSim';
  readonly dependencies: string[] = [];
  priority: number = 30;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: wrap ParticleManager algorithms
  }

  render(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void {
    // Phase 2: render particles
  }
}
