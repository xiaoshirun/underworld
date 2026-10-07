"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SpatialGrid = void 0;
class SpatialGrid {
    constructor(cellSize = 128) {
        this.cells = new Map();
        this.cellSize = cellSize;
        this.invCellSize = 1.0 / cellSize;
    }
    insert(x, y, item) {
        const key = this.cellKey(x, y);
        let cell = this.cells.get(key);
        if (cell === undefined) {
            cell = [];
            this.cells.set(key, cell);
        }
        cell.push(item);
    }
    queryRadius(cx, cy, radius) {
        const result = [];
        const minCX = Math.floor((cx - radius) * this.invCellSize);
        const maxCX = Math.floor((cx + radius) * this.invCellSize);
        const minCY = Math.floor((cy - radius) * this.invCellSize);
        const maxCY = Math.floor((cy + radius) * this.invCellSize);
        for (let gx = minCX; gx <= maxCX; gx++) {
            for (let gy = minCY; gy <= maxCY; gy++) {
                const key = `${gx},${gy}`;
                const cell = this.cells.get(key);
                if (cell !== undefined) {
                    for (let i = 0; i < cell.length; i++) {
                        result.push(cell[i]);
                    }
                }
            }
        }
        return result;
    }
    queryRect(x, y, w, h) {
        const result = [];
        const minCX = Math.floor(x * this.invCellSize);
        const maxCX = Math.floor((x + w) * this.invCellSize);
        const minCY = Math.floor(y * this.invCellSize);
        const maxCY = Math.floor((y + h) * this.invCellSize);
        for (let gx = minCX; gx <= maxCX; gx++) {
            for (let gy = minCY; gy <= maxCY; gy++) {
                const key = `${gx},${gy}`;
                const cell = this.cells.get(key);
                if (cell !== undefined) {
                    for (let i = 0; i < cell.length; i++) {
                        result.push(cell[i]);
                    }
                }
            }
        }
        return result;
    }
    clear() {
        this.cells.clear();
    }
    cellKey(x, y) {
        const gx = Math.floor(x * this.invCellSize);
        const gy = Math.floor(y * this.invCellSize);
        return `${gx},${gy}`;
    }
}
exports.SpatialGrid = SpatialGrid;
