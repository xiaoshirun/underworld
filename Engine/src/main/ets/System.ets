import { Entity } from './Entity';
import { World } from './World';
import { InputState } from './Scene';
import { ResourceManager } from './ResourceManager';

export interface SystemContext {
  world: World;
  ctx: CanvasRenderingContext2D;
  minimapCtx: CanvasRenderingContext2D;
  screenW: number;
  screenH: number;
  cameraX: number;
  cameraY: number;
  input: InputState;
  resources: ResourceManager;
  audio: Object;
  settings: Object;
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
