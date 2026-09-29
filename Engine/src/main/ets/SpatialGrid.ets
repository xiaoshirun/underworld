export class SpatialGrid<T> {
  private cellSize: number;
  private invCellSize: number;
  private cells: Map<string, T[]> = new Map<string, T[]>();

  constructor(cellSize: number = 128) {
    this.cellSize = cellSize;
    this.invCellSize = 1.0 / cellSize;
  }

  insert(x: number, y: number, item: T): void {
    const key: string = this.cellKey(x, y);
    let cell: T[] | undefined = this.cells.get(key);
    if (cell === undefined) {
      cell = [];
      this.cells.set(key, cell);
    }
    cell.push(item);
  }

  queryRadius(cx: number, cy: number, radius: number): T[] {
    const result: T[] = [];
    const minCX: number = Math.floor((cx - radius) * this.invCellSize);
    const maxCX: number = Math.floor((cx + radius) * this.invCellSize);
    const minCY: number = Math.floor((cy - radius) * this.invCellSize);
    const maxCY: number = Math.floor((cy + radius) * this.invCellSize);

    for (let gx: number = minCX; gx <= maxCX; gx++) {
      for (let gy: number = minCY; gy <= maxCY; gy++) {
        const key: string = `${gx},${gy}`;
        const cell: T[] | undefined = this.cells.get(key);
        if (cell !== undefined) {
          for (let i: number = 0; i < cell.length; i++) {
            result.push(cell[i]);
          }
        }
      }
    }
    return result;
  }

  queryRect(x: number, y: number, w: number, h: number): T[] {
    const result: T[] = [];
    const minCX: number = Math.floor(x * this.invCellSize);
    const maxCX: number = Math.floor((x + w) * this.invCellSize);
    const minCY: number = Math.floor(y * this.invCellSize);
    const maxCY: number = Math.floor((y + h) * this.invCellSize);

    for (let gx: number = minCX; gx <= maxCX; gx++) {
      for (let gy: number = minCY; gy <= maxCY; gy++) {
        const key: string = `${gx},${gy}`;
        const cell: T[] | undefined = this.cells.get(key);
        if (cell !== undefined) {
          for (let i: number = 0; i < cell.length; i++) {
            result.push(cell[i]);
          }
        }
      }
    }
    return result;
  }

  clear(): void {
    this.cells.clear();
  }

  private cellKey(x: number, y: number): string {
    const gx: number = Math.floor(x * this.invCellSize);
    const gy: number = Math.floor(y * this.invCellSize);
    return `${gx},${gy}`;
  }
}
