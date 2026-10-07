import { ResourceManager } from './ResourceManager';

export interface InputState {
  joyActive: boolean;
  joyDx: number;
  joyDy: number;
  jumpPressed: boolean;
  attackPressed: boolean;
  dashPressed: boolean;
  attackHeld: boolean;
  toolPressed: boolean;
}

export interface BaseContext {
  ctx: CanvasRenderingContext2D;
  minimapCtx: CanvasRenderingContext2D;
  screenW: number;
  screenH: number;
  input: InputState;
  resources: ResourceManager;
  frameCount: number;
}

export abstract class Scene {
  public onEnter(): void {}
  public onExit(): void {}
  public onPause(): void {}
  public onResume(): void {}

  abstract update(baseCtx: BaseContext, dt: number): void;
  abstract render(baseCtx: BaseContext): void;
}
