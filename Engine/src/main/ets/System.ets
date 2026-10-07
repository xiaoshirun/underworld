import { Entity } from './Entity';
import { World } from './World';
import { InputState } from './Scene';

export interface SystemContext {
  world: World;
  screenW: number;
  screenH: number;
  input: InputState;
  audio: Object;
  frameCount: number;
  dt: number;
}

export abstract class System {
  protected enabled: boolean = true;

  isEnabled(): boolean {
    return this.enabled;
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  abstract update(entities: Entity[], context: SystemContext): void;
}
