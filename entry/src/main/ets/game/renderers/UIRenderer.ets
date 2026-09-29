import {
  MINIMAP_SIZE, TILE_SIZE,
  TileType, BiomeType, PlayerState, SlimeState, BossState, ChestState, ChestType,
  COLOR_MINIMAP_BG, COLOR_MINIMAP_ENEMY, COLOR_MINIMAP_PLAYER, COLOR_CHEST_GLOW,
  COLOR_CHEST_NORMAL, COLOR_CHEST_ELITE, COLOR_CHEST_BOSS,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export class UIRenderer {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  renderMinimap(): void {
    if (this.g.minimapCtx === null || this.g.player === null) return;
    const mc: CanvasRenderingContext2D = this.g.minimapCtx;
    const size: number = MINIMAP_SIZE;
    const p: PlayerState = this.g.player;

    // --- Background with biome tint ---
    const camWorldX: number = this.g.cameraX + this.g.screenW / 2;
    const camWorldY: number = this.g.cameraY + this.g.screenH / 2;
    const viewBiome: BiomeType = this.g.worldGen.getBiome(camWorldX, camWorldY);

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
    const playerTX: number = Math.floor(p.x / TILE_SIZE);
    const playerTY: number = Math.floor(p.y / TILE_SIZE);
    const scale: number = size / (viewRange * 2);

    for (let dy: number = -viewRange; dy <= viewRange; dy++) {
      for (let dx: number = -viewRange; dx <= viewRange; dx++) {
        const tx: number = playerTX + dx;
        const ty: number = playerTY + dy;
        const tile: number = this.g.getTile(tx * TILE_SIZE, ty * TILE_SIZE);
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
    for (let i: number = 0; i < this.g.enemies.length; i++) {
      const s: SlimeState = this.g.enemies[i];
      if (!s.active) continue;
      const sdx: number = (s.x / TILE_SIZE) - playerTX;
      const sdy: number = (s.y / TILE_SIZE) - playerTY;
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
    for (let i: number = 0; i < this.g.bosses.length; i++) {
      const boss: BossState = this.g.bosses[i];
      if (!boss.active || boss.defeated) continue;
      const bdx: number = (boss.x / TILE_SIZE) - playerTX;
      const bdy: number = (boss.y / TILE_SIZE) - playerTY;
      if (Math.abs(bdx) > viewRange || Math.abs(bdy) > viewRange) continue;
      const bsx: number = (bdx + viewRange) * scale;
      const bsy: number = (bdy + viewRange) * scale;
      // Pulsing boss marker
      const bPulse: number = 0.6 + 0.4 * Math.sin(this.g.frameCount * 0.08);
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
    for (let i: number = 0; i < this.g.chests.length; i++) {
      const chest: ChestState = this.g.chests[i];
      if (!chest.active || chest.opened) continue;
      const cdx: number = (chest.x / TILE_SIZE) - playerTX;
      const cdy: number = (chest.y / TILE_SIZE) - playerTY;
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
    const facing: number = p.facing;
    const dirX: number = Math.cos(facing);
    const dirY: number = Math.sin(facing);

    // Player glow
    const pPulse: number = 0.7 + 0.3 * Math.sin(this.g.frameCount * 0.06);
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
    const depth: number = Math.floor(p.y / (TILE_SIZE * 10));
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
