import { Scene } from '../engine/scene/Scene';

export class MainMenuScene extends Scene {
  private selectedOption: number = 0;
  private options: string[] = ['New Game', 'Continue', 'Settings'];

  constructor() {
    super('main-menu');
  }

  onLoad(): void {
  }

  onEnter(): void {
    this.selectedOption = 0;
  }

  update(dt: number): void {
  }

  render(ctx: CanvasRenderingContext2D): void {
    const w: number = ctx.canvas.width;
    const h: number = ctx.canvas.height;

    ctx.fillStyle = '#08080f';
    ctx.fillRect(0, 0, w, h);

    ctx.fillStyle = '#ffffff';
    ctx.font = '32px monospace';
    ctx.textAlign = 'center';
    ctx.fillText('Underground Explorer', w / 2, h / 3);

    ctx.font = '20px monospace';
    for (let i: number = 0; i < this.options.length; i++) {
      const y: number = h / 2 + i * 40;
      ctx.fillStyle = i === this.selectedOption ? '#ffd700' : '#aaaaaa';
      ctx.fillText(this.options[i], w / 2, y);
    }
  }
}
