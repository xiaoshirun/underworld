import { FRAME_INTERVAL, GameSettings } from '../game/GameConstants';
import { GameContext } from '../game/GameContext';
import { Engine, EngineDelegate } from 'engine';
import { common } from '@kit.AbilityKit';

class EngineBaseDelegate implements EngineDelegate {
  private owner: EngineBase;
  constructor(owner: EngineBase) {
    this.owner = owner;
  }
  onInit(): void {}
  onUpdate(dt: number): void { this.owner.update(dt); }
  onRender(): void { this.owner.render(); }
  onDestroy(): void {}
}

export class EngineBase extends GameContext {
  protected engine: Engine = new Engine();

  setExternalLoop(enabled: boolean): void {
    this.engine.setExternalLoop(enabled);
  }

  init(ctx: CanvasRenderingContext2D, minimapCtx: CanvasRenderingContext2D,
    screenW: number, screenH: number, appContext?: Object): void {
    this.ctx = ctx;
    this.minimapCtx = minimapCtx;
    this.screenW = screenW;
    this.screenH = screenH;
    if (appContext) {
      this.context = appContext;
      const abilityCtx: common.UIAbilityContext = appContext as common.UIAbilityContext;
      if (abilityCtx.resourceManager) {
        this.engine.resources.setFileProvider(abilityCtx.resourceManager);
      }
    }
    this.audio.init();
    this.engine.ctx = ctx;
    this.engine.minimapCtx = minimapCtx;
    this.engine.screenW = screenW;
    this.engine.screenH = screenH;
    this.engine.tickInterval = FRAME_INTERVAL;
    this.onInit();
    this.engine.setDelegate(new EngineBaseDelegate(this));
    this.engine.init(ctx, minimapCtx, screenW, screenH);
  }

  protected onInit(): void {}

  update(dt: number): void {}

  render(): void {}

  destroy(): void {
    this.engine.stop();
    this.audio.destroy();
  }

  startLoop(): void {
    this.engine.startLoop();
  }

  stopLoop(): void {
    this.engine.stop();
  }

  protected getEngine(): Engine {
    return this.engine;
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
