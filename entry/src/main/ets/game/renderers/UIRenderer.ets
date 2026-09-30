import { World, Entity, PositionComponent } from '@qiuyu/engine';
import {
  MINIMAP_SIZE, TILE_SIZE, CHUNK_SIZE,
  TileType, BiomeType, ChestType,
  COLOR_MINIMAP_BG, COLOR_MINIMAP_ENEMY, COLOR_MINIMAP_PLAYER, COLOR_CHEST_GLOW,
  COLOR_CHEST_NORMAL, COLOR_CHEST_ELITE, COLOR_CHEST_BOSS,
  ChunkData,
} from '../GameConstants';
import { MovementComponent } from '../components/MovementComponent';
import { BossAIComponent } from '../components/BossAIComponent';
import { ChestComponent } from '../components/ChestComponent';
import { WorldGenerator } from '../WorldGenerator';

export class UIRenderer {

  private getTile(chunks: Map<string, Object>, worldX: number, worldY: number): number {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = cx + ',' + cy;
    const chunk: ChunkData | undefined = chunks.get(key) as ChunkData;
    if (chunk === undefined) return TileType.WALL;
    const lx: number = tx - cx * CHUNK_SIZE;
    const ly: number = ty - cy * CHUNK_SIZE;
    return chunk.tiles[ly][lx];
  }

  renderMinimap(world: World, minimapCtx: CanvasRenderingContext2D, cameraX: number, cameraY: number, screenW: number, screenH: number, frameCount: number): void {
    const mc: CanvasRenderingContext2D = minimapCtx;
    const size: number = MINIMAP_SIZE;

    const player: Entity | null = world.findEntityByTag('player');
    if (player === null) return;
    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>('Position');
    const playerMovement: MovementComponent | null = player.getComponent<MovementComponent>('movement');
    if (playerPos === null || playerMovement === null) return;

    // --- Background with biome tint ---
    const camWorldX: number = cameraX + screenW / 2;
    const camWorldY: number = cameraY + screenH / 2;
    const worldGen: WorldGenerator | null = world.worldGen as WorldGenerator | null;
    const viewBiome: BiomeType = worldGen !== null ? worldGen.getBiome(camWorldX, camWorldY) : BiomeType.CRYSTAL;

    let biomeTint: string = '#0a0a15';
    switch (viewBiome) {
      case BiomeType.CRYSTAL: biomeTint = '#060d1a'; break;
      case BiomeType.MUSHROOM: biomeTint = '#100718'; break;
      case BiomeType.WATER: biomeTint = '#041018'; break;
      case BiomeType.LAVA: biomeTint = '#120703'; break;
      case BiomeType.SHADOW: biomeTint = '#080315'; break;
      default: biomeTint = '#0a0a15'; break;
    }
    mc.fillStyle = biomeTint;
    mc.fillRect(0, 0, size, size);

    // --- Inner vignette ---
    const vigGrad: CanvasGradient = mc.createRadialGradient(
      size / 2, size / 2, size * 0.25,
      size / 2, size / 2, size * 0.7
    );
    vigGrad.addColorStop(0, 'rgba(0,0,0,0)');
    vigGrad.addColorStop(1, 'rgba(0,0,0,0.4)');
    mc.fillStyle = vigGrad;
    mc.fillRect(0, 0, size, size);

    // --- Terrain ---
    const viewRange: number = 40;
    const playerTX: number = Math.floor(playerPos.x / TILE_SIZE);
    const playerTY: number = Math.floor(playerPos.y / TILE_SIZE);
    const scale: number = size / (viewRange * 2);

    for (let dy: number = -viewRange; dy <= viewRange; dy++) {
      for (let dx: number = -viewRange; dx <= viewRange; dx++) {
        const tx: number = playerTX + dx;
        const ty: number = playerTY + dy;
        const tile: number = this.getTile(world.chunks, tx * TILE_SIZE, ty * TILE_SIZE);
        const sx: number = (dx + viewRange) * scale;
        const sy: number = (dy + viewRange) * scale;

        if (tile === TileType.WALL) {
          mc.fillStyle = '#2a2a4e';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.GLOW_STONE) {
          mc.fillStyle = '#ffd700';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.CRYSTAL) {
          mc.fillStyle = '#00ced1';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.WATER) {
          mc.fillStyle = '#1a3a5c';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.LAVA) {
          mc.fillStyle = '#8b2500';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.MUSHROOM) {
          mc.fillStyle = '#3d1a2e';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        }
      }
    }

    // --- Enemies ---
    const enemies: Entity[] = world.queryWithTag('enemy');
    for (let i: number = 0; i < enemies.length; i++) {
      const entity: Entity = enemies[i];
      if (!entity.active) continue;
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      if (pos === null) continue;
      const sdx: number = (pos.x / TILE_SIZE) - playerTX;
      const sdy: number = (pos.y / TILE_SIZE) - playerTY;
      if (Math.abs(sdx) > viewRange || Math.abs(sdy) > viewRange) continue;
      const sx: number = (sdx + viewRange) * scale;
      const sy: number = (sdy + viewRange) * scale;
      mc.fillStyle = COLOR_MINIMAP_ENEMY;
      mc.globalAlpha = 0.8;
      mc.fillRect(sx - 1, sy - 1, 2, 2);
      mc.globalAlpha = 0.3;
      mc.fillRect(sx - 2, sy - 2, 4, 4);
      mc.globalAlpha = 1.0;
    }

    // --- Bosses ---
    const bosses: Entity[] = world.queryWithTag('boss');
    for (let i: number = 0; i < bosses.length; i++) {
      const entity: Entity = bosses[i];
      if (!entity.active) continue;
      const ai: BossAIComponent | null = entity.getComponent<BossAIComponent>('bossAI');
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      if (ai === null || pos === null) continue;
      if (ai.defeated) continue;
      const bdx: number = (pos.x / TILE_SIZE) - playerTX;
      const bdy: number = (pos.y / TILE_SIZE) - playerTY;
      if (Math.abs(bdx) > viewRange || Math.abs(bdy) > viewRange) continue;
      const bsx: number = (bdx + viewRange) * scale;
      const bsy: number = (bdy + viewRange) * scale;
      // Pulsing boss marker
      const bPulse: number = 0.6 + 0.4 * Math.sin(frameCount * 0.08);
      mc.globalAlpha = 0.25 * bPulse;
      mc.fillStyle = '#ff0000';
      mc.fillRect(bsx - 5, bsy - 5, 10, 10);
      mc.globalAlpha = 0.9;
      mc.fillStyle = '#ff0000';
      mc.fillRect(bsx - 3, bsy - 3, 6, 6);
      mc.globalAlpha = 1.0;
      mc.fillStyle = '#ff6666';
      mc.fillRect(bsx - 1, bsy - 1, 2, 2);
    }

    // --- Chests ---
    const chests: Entity[] = world.queryWithTag('chest');
    for (let i: number = 0; i < chests.length; i++) {
      const entity: Entity = chests[i];
      if (!entity.active) continue;
      const chest: ChestComponent | null = entity.getComponent<ChestComponent>('chest');
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      if (chest === null || pos === null) continue;
      if (chest.opened) continue;
      const cdx: number = (pos.x / TILE_SIZE) - playerTX;
      const cdy: number = (pos.y / TILE_SIZE) - playerTY;
      if (Math.abs(cdx) > viewRange || Math.abs(cdy) > viewRange) continue;
      const csx: number = (cdx + viewRange) * scale;
      const csy: number = (cdy + viewRange) * scale;
      let chestColor: string = COLOR_CHEST_NORMAL;
      if (chest.chestType === ChestType.ELITE) chestColor = COLOR_CHEST_ELITE;
      else if (chest.chestType === ChestType.BOSS) chestColor = COLOR_CHEST_BOSS;
      mc.globalAlpha = 0.3;
      mc.fillStyle = chestColor;
      mc.fillRect(csx - 3, csy - 3, 6, 6);
      mc.globalAlpha = 0.9;
      mc.fillRect(csx - 2, csy - 2, 4, 4);
      mc.globalAlpha = 1.0;
    }

    // --- Player direction indicator (triangle) ---
    const pcx: number = size / 2;
    const pcy: number = size / 2;
    const facing: number = playerMovement.facing;
    const dirX: number = Math.cos(facing);
    const dirY: number = Math.sin(facing);

    // Player glow
    const pPulse: number = 0.7 + 0.3 * Math.sin(frameCount * 0.06);
    mc.globalAlpha = 0.2 * pPulse;
    mc.fillStyle = COLOR_MINIMAP_PLAYER;
    mc.beginPath();
    mc.arc(pcx, pcy, 6, 0, Math.PI * 2);
    mc.fill();

    // Direction triangle
    mc.globalAlpha = 1.0;
    mc.fillStyle = COLOR_MINIMAP_PLAYER;
    mc.beginPath();
    const triLen: number = 5;
    const triW: number = 3;
    const perpX: number = -dirY;
    const perpY: number = dirX;
    mc.moveTo(pcx + dirX * triLen, pcy + dirY * triLen);
    mc.lineTo(pcx - dirX * 2 + perpX * triW, pcy - dirY * 2 + perpY * triW);
    mc.lineTo(pcx - dirX * 2 - perpX * triW, pcy - dirY * 2 - perpY * triW);
    mc.closePath();
    mc.fill();

    // Center dot
    mc.fillStyle = '#ffffff';
    mc.beginPath();
    mc.arc(pcx, pcy, 1.5, 0, Math.PI * 2);
    mc.fill();

    // --- Decorative border ---
    // Outer frame
    mc.strokeStyle = '#3a3a5c';
    mc.lineWidth = 2;
    mc.strokeRect(1, 1, size - 2, size - 2);

    // Inner frame
    mc.strokeStyle = '#252540';
    mc.lineWidth = 1;
    mc.strokeRect(3, 3, size - 6, size - 6);

    // Corner ornaments
    const cornerSize: number = 6;
    mc.strokeStyle = '#5a5a8c';
    mc.lineWidth = 1.5;
    // Top-left
    mc.beginPath();
    mc.moveTo(1, cornerSize + 1);
    mc.lineTo(1, 1);
    mc.lineTo(cornerSize + 1, 1);
    mc.stroke();
    // Top-right
    mc.beginPath();
    mc.moveTo(size - cornerSize - 1, 1);
    mc.lineTo(size - 1, 1);
    mc.lineTo(size - 1, cornerSize + 1);
    mc.stroke();
    // Bottom-left
    mc.beginPath();
    mc.moveTo(1, size - cornerSize - 1);
    mc.lineTo(1, size - 1);
    mc.lineTo(cornerSize + 1, size - 1);
    mc.stroke();
    // Bottom-right
    mc.beginPath();
    mc.moveTo(size - cornerSize - 1, size - 1);
    mc.lineTo(size - 1, size - 1);
    mc.lineTo(size - 1, size - cornerSize - 1);
    mc.stroke();

    // Corner dots
    mc.fillStyle = '#6a6a9c';
    mc.fillRect(0, 0, 2, 2);
    mc.fillRect(size - 2, 0, 2, 2);
    mc.fillRect(0, size - 2, 2, 2);
    mc.fillRect(size - 2, size - 2, 2, 2);

    // --- Depth display ---
    const depth: number = Math.floor(playerPos.y / (TILE_SIZE * 10));
    mc.globalAlpha = 0.7;
    mc.fillStyle = '#000000';
    mc.fillRect(size / 2 - 14, size - 11, 28, 9);
    mc.globalAlpha = 1.0;
    mc.fillStyle = '#8888aa';
    mc.font = '7px sans-serif';
    mc.textAlign = 'center';
    mc.fillText(depth + 'F', size / 2, size - 3);

    // --- Legend markers ---
    const legendY: number = 7;
    const legendX: number = 6;
    const legendSpacing: number = 10;

    // Enemy marker
    mc.globalAlpha = 0.8;
    mc.fillStyle = COLOR_MINIMAP_ENEMY;
    mc.fillRect(legendX, legendY, 3, 3);
    mc.globalAlpha = 1.0;

    // Boss marker
    mc.fillStyle = '#ff0000';
    mc.fillRect(legendX + legendSpacing, legendY, 4, 4);
    mc.fillStyle = '#ff6666';
    mc.fillRect(legendX + legendSpacing + 1, legendY + 1, 2, 2);

    // Chest marker
    mc.fillStyle = COLOR_CHEST_GLOW;
    mc.fillRect(legendX + legendSpacing * 2, legendY, 3, 3);
  }
}
