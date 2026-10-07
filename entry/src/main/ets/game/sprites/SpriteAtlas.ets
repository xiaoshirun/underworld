export class FrameCoord {
  sx: number;
  sy: number;
  constructor(sx: number, sy: number) {
    this.sx = sx;
    this.sy = sy;
  }
}

export class SpriteAtlas {
  readonly canvas: OffscreenCanvas;
  readonly imageBitmap: ImageBitmap;
  readonly cellW: number;
  readonly cellH: number;
  readonly cols: number;
  readonly rows: number;
  readonly frameCount: number;

  constructor(canvas: OffscreenCanvas, cellW: number, cellH: number, frameCount: number) {
    this.canvas = canvas;
    this.imageBitmap = canvas.transferToImageBitmap();
    this.cellW = cellW;
    this.cellH = cellH;
    this.cols = Math.ceil(Math.sqrt(frameCount));
    this.rows = Math.ceil(frameCount / this.cols);
    this.frameCount = frameCount;
  }

  getFrame(index: number): FrameCoord {
    const col: number = index % this.cols;
    const row: number = Math.floor(index / this.cols);
    return new FrameCoord(col * this.cellW, row * this.cellH);
  }
}
