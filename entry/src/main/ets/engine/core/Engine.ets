import { World } from './World';
import { Scene } from '../scene/Scene';
import { SceneManager } from '../scene/SceneManager';
import { ResourceManager } from '../resource/ResourceManager';
import { HarmonyOSPlatform } from '../platform/HarmonyOSPlatform';
import { common } from '@kit.AbilityKit';

export interface SceneDefinition {
  name: string;
  factory: () => Scene;
}

export interface EngineConfig {
  canvas: CanvasRenderingContext2D;
  screenWidth: number;
  screenHeight: number;
  targetFPS?: number;
  scenes: SceneDefinition[];
  entryScene: string;
  appContext?: common.UIAbilityContext;
}

export class Engine {
  readonly world: World = new World();
  readonly scenes: SceneManager = new SceneManager();
  readonly resources: ResourceManager = new ResourceManager();

  private canvas: CanvasRenderingContext2D | null = null;
  private screenWidth: number = 960;
  private screenHeight: number = 540;
  private targetFPS: number = 60;
  private running: boolean = false;
  private paused: boolean = false;
  private timerId: number = -1;
  private lastTime: number = 0;

  static async init(config: EngineConfig): Promise<Engine> {
    const engine: Engine = new Engine();
    engine.canvas = config.canvas;
    engine.screenWidth = config.screenWidth;
    engine.screenHeight = config.screenHeight;
    engine.scenes.canvasWidth = config.screenWidth;
    engine.scenes.canvasHeight = config.screenHeight;
    engine.targetFPS = config.targetFPS ?? 60;

    if (config.appContext) {
      HarmonyOSPlatform.setContext(config.appContext);
    }

    for (const sceneDef of config.scenes) {
      engine.scenes.register(sceneDef.name, sceneDef.factory);
    }

    engine.scenes.switchTo(config.entryScene);

    return engine;
  }

  start(): void {
    if (this.running) return;
    this.running = true;
    this.paused = false;
    this.lastTime = HarmonyOSPlatform.now();

    const interval: number = Math.floor(1000 / this.targetFPS);
    this.timerId = setInterval((): void => {
      this.tick();
    }, interval);
  }

  stop(): void {
    this.running = false;
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  pause(): void {
    this.paused = true;
  }

  resume(): void {
    this.paused = false;
    this.lastTime = HarmonyOSPlatform.now();
  }

  isRunning(): boolean {
    return this.running;
  }

  isPaused(): boolean {
    return this.paused;
  }

  private tick(): void {
    if (this.paused || !this.canvas) return;

    const now: number = HarmonyOSPlatform.now();
    const dt: number = now - this.lastTime;
    this.lastTime = now;

    const clampedDt: number = Math.min(dt, 50);

    this.scenes.update(clampedDt);

    const currentScene: Scene | null = this.scenes.current();
    if (currentScene) {
      currentScene.canvasWidth = this.screenWidth;
      currentScene.canvasHeight = this.screenHeight;
    }

    console.log('[Engine.tick] canvas:', !!this.canvas, 'size:', this.screenWidth, 'x', this.screenHeight);
    
    this.canvas.clearRect(0, 0, this.screenWidth, this.screenHeight);
    
    // Debug: draw a bright red rectangle to verify Canvas is working
    this.canvas.fillStyle = '#ff0000';
    this.canvas.fillRect(0, 0, 100, 100);
    
    this.scenes.render(this.canvas);
  }
}
