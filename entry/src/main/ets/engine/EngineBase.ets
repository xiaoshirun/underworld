import { FRAME_INTERVAL, GameSettings } from '../game/GameConstants';
import { GameContext } from '../game/GameContext';

export class EngineBase extends GameContext {
  protected gameLoopId: number = -1;
  protected frameCount: number = 0;
  protected externalLoop: boolean = false;

  setExternalLoop(enabled: boolean): void {
    this.externalLoop = enabled;
  }

  init(ctx: CanvasRenderingContext2D, minimapCtx: CanvasRenderingContext2D,
    screenW: number, screenH: number, appContext?: Object): void {
    this.ctx = ctx;
    this.minimapCtx = minimapCtx;
    this.screenW = screenW;
    this.screenH = screenH;
    if (appContext) {
      this.context = appContext;
    }
    this.audio.init();
    this.onInit();
    this.startLoop();
  }

  protected onInit(): void {}

  update(dt: number): void {}

  render(): void {}

  protected startLoop(): void {
    if (this.externalLoop) return;
    this.gameLoopId = setInterval(() => {
      this.update(FRAME_INTERVAL);
      this.render();
      this.frameCount++;
    }, FRAME_INTERVAL);
  }

  protected stopLoop(): void {
    if (this.gameLoopId !== -1) {
      clearInterval(this.gameLoopId);
      this.gameLoopId = -1;
    }
  }

  destroy(): void {
    this.stopLoop();
    this.audio.destroy();
  }

  setInputJoy(active: boolean, dx: number, dy: number): void {
    this.input.joyActive = active;
    this.input.joyDx = dx;
    this.input.joyDy = dy;
  }

  setInputJump(pressed: boolean): void {
    this.input.jumpPressed = pressed;
  }

  setInputAttack(pressed: boolean): void {
    this.input.attackPressed = pressed;
  }

  setInputDash(pressed: boolean): void {
    this.input.dashPressed = pressed;
  }

  setInputTool(pressed: boolean): void {
    this.input.toolPressed = pressed;
  }

  setSettings(s: GameSettings): void {
    this.settings = s;
    this.audio.setSettings(s);
  }
}
