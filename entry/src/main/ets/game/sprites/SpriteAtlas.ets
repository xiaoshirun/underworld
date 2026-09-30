export class SpriteAtlas {
  readonly canvas: OffscreenCanvas;
  readonly cellW: number;
  readonly cellH: number;
  readonly cols: number;
  readonly rows: number;
  readonly frameCount: number;

  constructor(canvas: OffscreenCanvas, cellW: number, cellH: number, frameCount: number) {
    this.canvas = canvas;
    this.cellW = cellW;
    this.cellH = cellH;
    this.cols = Math.ceil(Math.sqrt(frameCount));
    this.rows = Math.ceil(frameCount / this.cols);
    this.frameCount = frameCount;
  }

  getFrame(index: number): { sx: number, sy: number } {
    const col: number = index % this.cols;
    const row: number = Math.floor(index / this.cols);
    return { sx: col * this.cellW, sy: row * this.cellH };
  }
}
