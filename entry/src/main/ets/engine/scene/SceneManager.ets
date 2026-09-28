import { Scene } from './Scene';

export interface Transition {
  type: 'fade' | 'slide-left' | 'slide-right' | 'slide-up' | 'dissolve';
  duration: number;
}

interface SceneEntry {
  factory: () => Scene;
  instance: Scene | null;
  loaded: boolean;
}

export class SceneManager {
  canvasWidth: number = 960;
  canvasHeight: number = 540;
  private registry: Map<string, SceneEntry> = new Map();
  private stack: Scene[] = [];
  private transitioning: boolean = false;
  private transitionProgress: number = 0;
  private transitionDuration: number = 0;
  private transitionType: string = 'fade';
  private pendingAction: (() => void) | null = null;

  register(name: string, factory: () => Scene): void {
    this.registry.set(name, { factory: factory, instance: null, loaded: false });
  }

  switchTo(name: string, transition?: Transition): void {
    const entry: SceneEntry | undefined = this.registry.get(name);
    if (!entry) {
      console.error('[SceneManager] Scene not registered: ' + name);
      return;
    }

    if (transition) {
      this.startTransition(transition, (): void => {
        while (this.stack.length > 0) {
          const old: Scene = this.stack.pop()!;
          old.onExit();
        }
        this.pushSceneInstance(entry);
      });
    } else {
      while (this.stack.length > 0) {
        const old: Scene = this.stack.pop()!;
        old.onExit();
      }
      this.pushSceneInstance(entry);
    }
  }

  push(name: string, transition?: Transition): void {
    const entry: SceneEntry | undefined = this.registry.get(name);
    if (!entry) {
      console.error('[SceneManager] Scene not registered: ' + name);
      return;
    }

    if (this.stack.length > 0) {
      this.stack[this.stack.length - 1].onPause();
    }

    if (transition) {
      this.startTransition(transition, (): void => {
        this.pushSceneInstance(entry);
      });
    } else {
      this.pushSceneInstance(entry);
    }
  }

  pop(transition?: Transition): void {
    if (this.stack.length <= 1) return;

    if (transition) {
      this.startTransition(transition, (): void => {
        const old: Scene = this.stack.pop()!;
        old.onExit();
        if (this.stack.length > 0) {
          this.stack[this.stack.length - 1].onResume();
        }
      });
    } else {
      const old: Scene = this.stack.pop()!;
      old.onExit();
      if (this.stack.length > 0) {
        this.stack[this.stack.length - 1].onResume();
      }
    }
  }

  current(): Scene | null {
    return this.stack.length > 0 ? this.stack[this.stack.length - 1] : null;
  }

  isTransitioning(): boolean {
    return this.transitioning;
  }

  update(dt: number): void {
    if (this.transitioning) {
      this.transitionProgress += dt;
      if (this.transitionProgress >= this.transitionDuration) {
        this.transitioning = false;
        if (this.pendingAction) {
          this.pendingAction();
          this.pendingAction = null;
        }
      }
      return;
    }

    const scene: Scene | null = this.current();
    if (scene) {
      scene.update(dt);
    }
  }

  render(ctx: CanvasRenderingContext2D): void {
    const scene: Scene | null = this.current();
    if (scene) {
      scene.render(ctx);
    }

    if (this.transitioning) {
      this.renderTransition(ctx);
    }
  }

  private pushSceneInstance(entry: SceneEntry): void {
    if (!entry.instance) {
      entry.instance = entry.factory();
    }
    const scene: Scene = entry.instance;
    scene.canvasWidth = this.canvasWidth;
    scene.canvasHeight = this.canvasHeight;
    this.stack.push(scene);
    if (!entry.loaded) {
      const result: void | Promise<void> = scene.onLoad();
      if (result instanceof Promise) {
        result.then((): void => {
          entry.loaded = true;
          scene.onEnter();
        });
        return;
      }
      entry.loaded = true;
    }
    scene.onEnter();
  }

  private startTransition(transition: Transition, action: () => void): void {
    this.transitioning = true;
    this.transitionProgress = 0;
    this.transitionDuration = transition.duration;
    this.transitionType = transition.type;
    this.pendingAction = action;
  }

  private renderTransition(ctx: CanvasRenderingContext2D): void {
    const progress: number = this.transitionDuration > 0
      ? Math.min(1.0, this.transitionProgress / this.transitionDuration)
      : 1.0;
    const canvasWidth: number = this.canvasWidth;
    const canvasHeight: number = this.canvasHeight;

    switch (this.transitionType) {
      case 'fade':
        ctx.fillStyle = '#000000';
        ctx.globalAlpha = progress < 0.5 ? progress * 2 : (1.0 - progress) * 2;
        ctx.fillRect(0, 0, canvasWidth, canvasHeight);
        ctx.globalAlpha = 1.0;
        break;
      case 'slide-left':
        ctx.fillStyle = '#000000';
        ctx.fillRect(0, 0, canvasWidth * (1.0 - progress), canvasHeight);
        break;
      case 'slide-right':
        ctx.fillStyle = '#000000';
        const slideRightX: number = canvasWidth * progress;
        ctx.fillRect(slideRightX, 0, canvasWidth - slideRightX, canvasHeight);
        break;
      case 'slide-up':
        ctx.fillStyle = '#000000';
        ctx.fillRect(0, 0, canvasWidth, canvasHeight * (1.0 - progress));
        break;
      case 'dissolve':
        ctx.fillStyle = '#000000';
        ctx.globalAlpha = progress < 0.5 ? progress * 2 : (1.0 - progress) * 2;
        ctx.fillRect(0, 0, canvasWidth, canvasHeight);
        ctx.globalAlpha = 1.0;
        break;
    }
  }
}
