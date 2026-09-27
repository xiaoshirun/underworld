import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class AudioSystem extends System {
  readonly name: string = 'audio';
  readonly dependencies: string[] = [];
  priority: number = 40;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: manage AudioSource component playback
  }
}
