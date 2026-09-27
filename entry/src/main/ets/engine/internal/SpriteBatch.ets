export interface DrawCommand {
  type: DrawType;
  x: number;
  y: number;
  w: number;
  h: number;
  color: string;
  alpha: number;
  radius: number;
  lineWidth: number;
  strokeColor: string;
}

export enum DrawType {
  RECT = 0,
  FILLED_RECT = 1,
  CIRCLE = 2,
  STROKE_RECT = 3,
  LINE = 4,
  ROUNDED_RECT = 5
}

export class SpriteBatch {
  private commands: DrawCommand[] = [];
  private sorted: boolean = false;
  private drawCount: number = 0;
  private stateChanges: number = 0;

  clear(): void {
    this.commands = [];
    this.sorted = false;
    this.drawCount = 0;
    this.stateChanges = 0;
  }

  addRect(x: number, y: number, w: number, h: number, color: string, alpha: number): void {
    this.commands.push({
      type: DrawType.FILLED_RECT,
      x: x, y: y, w: w, h: h,
      color: color, alpha: alpha,
      radius: 0, lineWidth: 0, strokeColor: ''
    });
    this.sorted = false;
  }

  addStrokeRect(x: number, y: number, w: number, h: number, color: string, lineWidth: number, alpha: number): void {
    this.commands.push({
      type: DrawType.STROKE_RECT,
      x: x, y: y, w: w, h: h,
      color: '', alpha: alpha,
      radius: 0, lineWidth: lineWidth, strokeColor: color
    });
    this.sorted = false;
  }

  addCircle(cx: number, cy: number, radius: number, color: string, alpha: number): void {
    this.commands.push({
      type: DrawType.CIRCLE,
      x: cx, y: cy, w: 0, h: 0,
      color: color, alpha: alpha,
      radius: radius, lineWidth: 0, strokeColor: ''
    });
    this.sorted = false;
  }

  addLine(x1: number, y1: number, x2: number, y2: number, color: string, lineWidth: number, alpha: number): void {
    this.commands.push({
      type: DrawType.LINE,
      x: x1, y: y1, w: x2, h: y2,
      color: color, alpha: alpha,
      radius: 0, lineWidth: lineWidth, strokeColor: color
    });
    this.sorted = false;
  }

  addRoundedRect(x: number, y: number, w: number, h: number, radius: number, color: string, alpha: number): void {
    this.commands.push({
      type: DrawType.ROUNDED_RECT,
      x: x, y: y, w: w, h: h,
      color: color, alpha: alpha,
      radius: radius, lineWidth: 0, strokeColor: ''
    });
    this.sorted = false;
  }

  private sortByColor(): void {
    if (this.sorted) return;
    const fillCmds: DrawCommand[] = [];
    const strokeCmds: DrawCommand[] = [];
    const circleCmds: DrawCommand[] = [];
    const lineCmds: DrawCommand[] = [];

    for (let i: number = 0; i < this.commands.length; i++) {
      const cmd: DrawCommand = this.commands[i];
      switch (cmd.type) {
        case DrawType.FILLED_RECT:
        case DrawType.ROUNDED_RECT:
          fillCmds.push(cmd);
          break;
        case DrawType.STROKE_RECT:
          strokeCmds.push(cmd);
          break;
        case DrawType.CIRCLE:
          circleCmds.push(cmd);
          break;
        case DrawType.LINE:
          lineCmds.push(cmd);
          break;
      }
    }

    fillCmds.sort((a: DrawCommand, b: DrawCommand): number => {
      if (a.color < b.color) return -1;
      if (a.color > b.color) return 1;
      return a.y - b.y;
    });

    this.commands = [];
    for (let i: number = 0; i < fillCmds.length; i++) this.commands.push(fillCmds[i]);
    for (let i: number = 0; i < circleCmds.length; i++) this.commands.push(circleCmds[i]);
    for (let i: number = 0; i < strokeCmds.length; i++) this.commands.push(strokeCmds[i]);
    for (let i: number = 0; i < lineCmds.length; i++) this.commands.push(lineCmds[i]);
    this.sorted = true;
  }

  flush(c: CanvasRenderingContext2D): void {
    this.sortByColor();

    let lastColor: string = '';
    let lastAlpha: number = -1;
    let lastLineWidth: number = -1;

    for (let i: number = 0; i < this.commands.length; i++) {
      const cmd: DrawCommand = this.commands[i];

      if (cmd.alpha !== lastAlpha) {
        c.globalAlpha = cmd.alpha;
        lastAlpha = cmd.alpha;
        this.stateChanges++;
      }

      switch (cmd.type) {
        case DrawType.FILLED_RECT:
          if (cmd.color !== lastColor) {
            c.fillStyle = cmd.color;
            lastColor = cmd.color;
            this.stateChanges++;
          }
          c.fillRect(cmd.x, cmd.y, cmd.w, cmd.h);
          break;

        case DrawType.ROUNDED_RECT:
          if (cmd.color !== lastColor) {
            c.fillStyle = cmd.color;
            lastColor = cmd.color;
            this.stateChanges++;
          }
          this.fillRoundedRect(c, cmd.x, cmd.y, cmd.w, cmd.h, cmd.radius);
          break;

        case DrawType.CIRCLE:
          if (cmd.color !== lastColor) {
            c.fillStyle = cmd.color;
            lastColor = cmd.color;
            this.stateChanges++;
          }
          c.beginPath();
          c.arc(cmd.x, cmd.y, cmd.radius, 0, Math.PI * 2);
          c.fill();
          break;

        case DrawType.STROKE_RECT:
          if (cmd.strokeColor !== lastColor) {
            c.strokeStyle = cmd.strokeColor;
            lastColor = cmd.strokeColor;
            this.stateChanges++;
          }
          if (cmd.lineWidth !== lastLineWidth) {
            c.lineWidth = cmd.lineWidth;
            lastLineWidth = cmd.lineWidth;
            this.stateChanges++;
          }
          c.strokeRect(cmd.x, cmd.y, cmd.w, cmd.h);
          break;

        case DrawType.LINE:
          if (cmd.color !== lastColor) {
            c.strokeStyle = cmd.color;
            lastColor = cmd.color;
            this.stateChanges++;
          }
          if (cmd.lineWidth !== lastLineWidth) {
            c.lineWidth = cmd.lineWidth;
            lastLineWidth = cmd.lineWidth;
            this.stateChanges++;
          }
          c.beginPath();
          c.moveTo(cmd.x, cmd.y);
          c.lineTo(cmd.w, cmd.h);
          c.stroke();
          break;
      }

      this.drawCount++;
    }

    c.globalAlpha = 1.0;
  }

  private fillRoundedRect(c: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
    c.beginPath();
    c.moveTo(x + r, y);
    c.lineTo(x + w - r, y);
    c.arcTo(x + w, y, x + w, y + r, r);
    c.lineTo(x + w, y + h - r);
    c.arcTo(x + w, y + h, x + w - r, y + h, r);
    c.lineTo(x + r, y + h);
    c.arcTo(x, y + h, x, y + h - r, r);
    c.lineTo(x, y + r);
    c.arcTo(x, y, x + r, y, r);
    c.closePath();
    c.fill();
  }

  getDrawCount(): number {
    return this.drawCount;
  }

  getStateChanges(): number {
    return this.stateChanges;
  }

  getCommandCount(): number {
    return this.commands.length;
  }
}

export class TileBatchRenderer {
  private batch: SpriteBatch = new SpriteBatch();
  private tileSize: number;

  constructor(tileSize: number) {
    this.tileSize = tileSize;
  }

  clear(): void {
    this.batch.clear();
  }

  addTile(screenX: number, screenY: number, color: string): void {
    this.batch.addRect(screenX, screenY, this.tileSize, this.tileSize, color, 1.0);
  }

  addTileWithAlpha(screenX: number, screenY: number, color: string, alpha: number): void {
    this.batch.addRect(screenX, screenY, this.tileSize, this.tileSize, color, alpha);
  }

  addPartialTile(screenX: number, screenY: number, w: number, h: number, color: string): void {
    this.batch.addRect(screenX, screenY, w, h, color, 1.0);
  }

  flush(c: CanvasRenderingContext2D): void {
    this.batch.flush(c);
  }

  getStats(): { draws: number; stateChanges: number; commands: number } {
    return {
      draws: this.batch.getDrawCount(),
      stateChanges: this.batch.getStateChanges(),
      commands: this.batch.getCommandCount()
    };
  }
}

export class EntityBatchRenderer {
  private batch: SpriteBatch = new SpriteBatch();

  clear(): void {
    this.batch.clear();
  }

  addEntity(x: number, y: number, w: number, h: number, color: string, alpha: number): void {
    this.batch.addRect(x, y, w, h, color, alpha);
  }

  addEntityCircle(cx: number, cy: number, radius: number, color: string, alpha: number): void {
    this.batch.addCircle(cx, cy, radius, color, alpha);
  }

  addEntityBorder(x: number, y: number, w: number, h: number, borderColor: string, borderWidth: number, alpha: number): void {
    this.batch.addStrokeRect(x, y, w, h, borderColor, borderWidth, alpha);
  }

  flush(c: CanvasRenderingContext2D): void {
    this.batch.flush(c);
  }
}

export class GlowBatchRenderer {
  private batch: SpriteBatch = new SpriteBatch();

  clear(): void {
    this.batch.clear();
  }

  addGlow(cx: number, cy: number, radius: number, color: string, alpha: number): void {
    this.batch.addCircle(cx, cy, radius, color, alpha * 0.15);
    this.batch.addCircle(cx, cy, radius * 0.6, color, alpha * 0.25);
    this.batch.addCircle(cx, cy, radius * 0.3, color, alpha * 0.4);
  }

  addSoftGlow(cx: number, cy: number, radius: number, color: string, alpha: number): void {
    this.batch.addCircle(cx, cy, radius, color, alpha * 0.08);
    this.batch.addCircle(cx, cy, radius * 0.5, color, alpha * 0.15);
  }

  flush(c: CanvasRenderingContext2D): void {
    this.batch.flush(c);
  }
}
