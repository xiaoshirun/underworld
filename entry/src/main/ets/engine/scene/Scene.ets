export abstract class Scene {
  readonly name: string;
  canvasWidth: number = 960;
  canvasHeight: number = 540;

  constructor(name: string) {
    this.name = name;
  }

  onLoad(): void | Promise<void> {
    // Override for resource loading
  }

  onEnter(): void {
    // Override when scene becomes active
  }

  onPause(): void {
    // Override when pushed below another scene
  }

  onResume(): void {
    // Override when restored to top of stack
  }

  onExit(): void {
    // Override when scene is removed
  }

  abstract update(dt: number): void;
  abstract render(ctx: CanvasRenderingContext2D): void;
}
