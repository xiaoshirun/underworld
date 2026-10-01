import { Scene, BaseContext } from './Scene';

export class SceneManager {
  private stack: Scene[] = [];
  private active: Scene | null = null;

  update(context: BaseContext, dt: number): void {
    if (this.active !== null) {
      this.active.update(context, dt);
    }
  }

  pushScene(scene: Scene): void {
    if (this.active !== null) {
      this.active.onPause();
      this.stack.push(this.active);
    }
    this.active = scene;
    scene.onEnter();
  }

  popScene(): Scene | null {
    if (this.active === null) {
      return null;
    }
    const leaving: Scene = this.active;
    leaving.onExit();
    this.active = this.stack.length > 0 ? this.stack.pop()! : null;
    if (this.active !== null) {
      this.active.onResume();
    }
    return leaving;
  }

  replaceScene(scene: Scene): void {
    if (this.active !== null) {
      this.active.onExit();
    }
    this.active = scene;
    scene.onEnter();
  }

  getActiveScene(): Scene | null {
    return this.active;
  }

  getStackSize(): number {
    return this.stack.length;
  }
}
