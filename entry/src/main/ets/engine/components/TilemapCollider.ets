export interface TilemapCollider {
  tileMap: number[][];
  tileSize: number;
  isSolid: (tile: number) => boolean;
}

export function createTilemapCollider(tileMap: number[][], tileSize: number, isSolid: (tile: number) => boolean): TilemapCollider {
  return { tileMap: tileMap, tileSize: tileSize, isSolid: isSolid };
}
