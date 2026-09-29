import { Scene } from '../engine/scene/Scene';
import { GameEngine } from './GameEngine';

export class GameScene extends Scene {
  readonly gameEngine: GameEngine;

  constructor(gameEngine: GameEngine) {
    super('game');
    this.gameEngine = gameEngine;
  }

  onLoad(): void {
  }

  onEnter(): void {
  }

  update(dt: number): void {
    this.gameEngine.update(dt);
    this.gameEngine.frameCount++;
  }

  render(ctx: CanvasRenderingContext2D): void {
    this.gameEngine.render();
  }
}
