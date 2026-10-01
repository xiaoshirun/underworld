import { ResourceManager } from './ResourceManager';
import { SceneManager } from './SceneManager';
import { Scene, InputState, BaseContext } from './Scene';

export { InputState } from './Scene';

export class Engine {
  private gameLoopId: number = -1;
  private frameCount: number = 0;
  private externalLoop: boolean = false;
  resources: ResourceManager = new ResourceManager();
  sceneManager: SceneManager = new SceneManager();

  ctx: CanvasRenderingContext2D | null = null;
  minimapCtx: CanvasRenderingContext2D | null = null;
  screenW: number = 0;
  screenH: number = 0;
  cameraX: number = 0;
  cameraY: number = 0;
  onRender: (() => void) | null = null;

  tickInterval: number = 33;

  input: InputState = {
    joyActive: false, joyDx: 0, joyDy: 0,
    jumpPressed: false, attackPressed: false,
    dashPressed: false, attackHeld: false,
    toolPressed: false
  };

  init(ctx: CanvasRenderingContext2D, minimapCtx: CanvasRenderingContext2D,
    screenW: number, screenH: number): void {
    console.log('[Engine] init called: screenW=' + screenW + ' screenH=' + screenH);
    this.ctx = ctx;
    this.minimapCtx = minimapCtx;
    this.screenW = screenW;
    this.screenH = screenH;
    this.startLoop();
  }

  startLoop(): void {
    if (this.externalLoop) return;
    console.log('[Engine] startLoop: starting game loop with interval=' + this.tickInterval + 'ms');
    this.gameLoopId = setInterval(() => {
      try {
        this.tick(this.tickInterval);
        this.render();
      } catch (e) {
        console.error('[Engine] tick error: ' + String(e));
      }
    }, this.tickInterval);
  }

  setExternalLoop(enabled: boolean): void {
    this.externalLoop = enabled;
  }

  tick(dt: number): void {
    const activeScene: Scene | null = this.sceneManager.getActiveScene();
    if (activeScene !== null && this.ctx !== null && this.minimapCtx !== null) {
      const baseCtx: BaseContext = {
        ctx: this.ctx,
        minimapCtx: this.minimapCtx,
        screenW: this.screenW,
        screenH: this.screenH,
        input: this.input,
        resources: this.resources,
        frameCount: this.frameCount
      };
      this.sceneManager.update(baseCtx, dt);
    } else if (this.frameCount < 10) {
      console.log('[Engine] tick skipped: activeScene=' + (activeScene !== null) + ' ctx=' + (this.ctx !== null) + ' minimapCtx=' + (this.minimapCtx !== null));
    }
    if (this.frameCount % 60 === 0) {
      console.log('[Engine] tick frame=' + this.frameCount + ' screenW=' + this.screenW + ' screenH=' + this.screenH + ' joyActive=' + this.input.joyActive);
    }
    this.frameCount++;
  }

  render(): void {
    if (this.frameCount < 5) {
      console.log('[Engine] render called: frame=' + this.frameCount + ' activeScene=' + (this.sceneManager.getActiveScene() !== null) + ' ctx=' + (this.ctx !== null));
    }
    const activeScene: Scene | null = this.sceneManager.getActiveScene();
    if (activeScene !== null && this.ctx !== null && this.minimapCtx !== null) {
      const baseCtx: BaseContext = {
        ctx: this.ctx,
        minimapCtx: this.minimapCtx,
        screenW: this.screenW,
        screenH: this.screenH,
        input: this.input,
        resources: this.resources,
        frameCount: this.frameCount
      };
      this.sceneManager.render(baseCtx);
    } else if (this.frameCount < 10) {
      console.log('[Engine] render skipped: activeScene=' + (activeScene !== null) + ' ctx=' + (this.ctx !== null) + ' minimapCtx=' + (this.minimapCtx !== null));
    }
    // 触发 Canvas 重绘：ArkUI Canvas 绘制指令需在渲染阶段执行
    try {
      const ctxObj = this.ctx as Object as Record<string, Object> | null;
      if (ctxObj !== null) {
        const frameNode = ctxObj['canvas'];
        if (frameNode !== undefined && frameNode !== null) {
          const fnObj = frameNode as Object as Record<string, () => void>;
          if (typeof fnObj['invalidate'] === 'function') {
            fnObj['invalidate']();
          }
        }
      }
    } catch (e) {
      // ignore
    }
    if (this.onRender !== null) {
      this.onRender();
    }
  }

  stop(): void {
    if (this.gameLoopId !== -1) {
      clearInterval(this.gameLoopId);
      this.gameLoopId = -1;
    }
  }

  getFrameCount(): number {
    return this.frameCount;
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
}
