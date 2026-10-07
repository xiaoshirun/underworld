"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SpriteAtlas = exports.FrameCoord = void 0;
class FrameCoord {
    constructor(sx, sy) {
        this.sx = sx;
        this.sy = sy;
    }
}
exports.FrameCoord = FrameCoord;
class SpriteAtlas {
    constructor(canvas, cellW, cellH, frameCount) {
        this.canvas = canvas;
        this.imageBitmap = canvas.transferToImageBitmap();
        this.cellW = cellW;
        this.cellH = cellH;
        this.cols = Math.ceil(Math.sqrt(frameCount));
        this.rows = Math.ceil(frameCount / this.cols);
        this.frameCount = frameCount;
    }
    getFrame(index) {
        const col = index % this.cols;
        const row = Math.floor(index / this.cols);
        return new FrameCoord(col * this.cellW, row * this.cellH);
    }
}
exports.SpriteAtlas = SpriteAtlas;
