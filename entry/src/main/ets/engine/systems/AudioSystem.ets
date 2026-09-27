// entry/src/main/ets/engine/systems/AudioSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { AudioSource } from '../components/AudioSource';
import { Transform } from '../components/Transform';

export class AudioSystem extends System {
  readonly name: string = 'audio';
  readonly dependencies: string[] = [];
  priority: number = 40;

  private soundCallbacks: Map<string, (soundId: string, volume: number) => void> = new Map();
  private maxSimultaneous: number = 6;
  private activeSounds: Map<string, number> = new Map();

  setSoundCallback(callback: (soundId: string, volume: number) => void): void {
    this.soundCallbacks.set('default', callback);
  }

  update(world: World, dt: number, entities: Entity[]): void {
    const sources: Entity[] = world.query('audioSource');
    for (const e of sources) {
      const source: AudioSource | undefined = world.getComponent<AudioSource>(e, 'audioSource');
      if (!source || !source.playing) continue;

      const current: number = this.activeSounds.get(source.soundId) ?? 0;
      if (current >= this.maxSimultaneous) {
        source.playing = false;
        continue;
      }

      let volume: number = source.volume;
      if (source.spatial) {
        const transform: Transform | undefined = world.getComponent<Transform>(e, 'transform');
        if (transform) {
          const cameraEntities: Entity[] = world.query('camera', 'transform');
          if (cameraEntities.length > 0) {
            const camTransform: Transform | undefined =
              world.getComponent<Transform>(cameraEntities[0], 'transform');
            if (camTransform) {
              const dx: number = transform.x - camTransform.x;
              const pan: number = Math.max(-1, Math.min(1, dx / 480));
              volume = volume * (1.0 - Math.abs(pan) * 0.5);
            }
          }
        }
      }

      const cb: ((soundId: string, volume: number) => void) | undefined =
        this.soundCallbacks.get('default');
      if (cb) {
        cb(source.soundId, volume);
      }

      this.activeSounds.set(source.soundId, current + 1);
      source.playing = false;
    }

    this.activeSounds.clear();
  }
}
