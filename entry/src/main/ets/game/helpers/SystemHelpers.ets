import { Entity, World, SystemContext } from '@qiuyu/engine';
import { CameraComponent } from '../components/CameraComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import { ChunkData, TILE_SIZE, CHUNK_SIZE, TileType } from '../GameConstants';

export function shakeCamera(context: SystemContext, duration: number): void {
  const cameraEntity: Entity | null = context.world.findEntityByTag("camera");
  if (cameraEntity !== null) {
    const cam: CameraComponent | null = cameraEntity.getComponent<CameraComponent>("camera");
    if (cam !== null) {
      cam.shakeTimer = duration;
    }
  }
}

export function triggerDamageFlash(context: SystemContext): void {
  const gsEntity: Entity | null = context.world.findEntityByTag("gameState");
  if (gsEntity !== null) {
    const gs: GameStateComponent | null = gsEntity.getComponent<GameStateComponent>("gameState");
    if (gs !== null) {
      gs.damageFlashTimer = 200;
    }
  }
}

export function getTile(chunks: Map<string, Object>, worldX: number, worldY: number): number {
  const tx: number = Math.floor(worldX / TILE_SIZE);
  const ty: number = Math.floor(worldY / TILE_SIZE);
  const cx: number = Math.floor(tx / CHUNK_SIZE);
  const cy: number = Math.floor(ty / CHUNK_SIZE);
  const key: string = cx + ',' + cy;
  const chunk: ChunkData | undefined = chunks.get(key) as ChunkData | undefined;
  if (chunk === undefined) return TileType.WALL;
  const lx: number = tx - cx * CHUNK_SIZE;
  const ly: number = ty - cy * CHUNK_SIZE;
  return chunk.tiles[ly][lx];
}

export function setTile(chunks: Map<string, Object>, worldX: number, worldY: number, tileType: number): void {
  const tx: number = Math.floor(worldX / TILE_SIZE);
  const ty: number = Math.floor(worldY / TILE_SIZE);
  const cx: number = Math.floor(tx / CHUNK_SIZE);
  const cy: number = Math.floor(ty / CHUNK_SIZE);
  const key: string = cx + ',' + cy;
  const chunk: ChunkData | undefined = chunks.get(key) as ChunkData | undefined;
  if (chunk === undefined) return;
  const lx: number = tx - cx * CHUNK_SIZE;
  const ly: number = ty - cy * CHUNK_SIZE;
  chunk.tiles[ly][lx] = tileType;
}

export function isWalkable(tile: number): boolean {
  return tile !== TileType.WALL && tile !== TileType.VOID;
}
