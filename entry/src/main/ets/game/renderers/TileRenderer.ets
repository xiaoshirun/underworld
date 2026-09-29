import { World } from '@qiuyu/engine';
import {
  TILE_SIZE, CHUNK_SIZE,
  BiomeType, TileType,
  COLOR_WALL, COLOR_WALL_EDGE, COLOR_FLOOR, COLOR_FLOOR_VAR,
  COLOR_WATER, COLOR_WATER_LIGHT, COLOR_LAVA, COLOR_LAVA_LIGHT,
  COLOR_CRYSTAL, COLOR_CRYSTAL_GLOW,
  COLOR_MUSHROOM_CAP, COLOR_MUSHROOM_STEM, COLOR_MUSHROOM_GLOW,
  COLOR_GLOW_STONE, COLOR_GLOW, COLOR_PLANT, COLOR_PLANT_LIGHT,
  COLOR_SHADOW_FLOOR, COLOR_SHADOW_WALL,
  GameSettings, ChunkData,
} from '../GameConstants';
import { WorldGenerator } from '../WorldGenerator';

export class TileRenderer {

  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
         cameraY: number, screenW: number, screenH: number,
         settings: GameSettings, frameCount: number): void {
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    this.renderBackground(ctx, offX, offY, world, cameraX, cameraY, screenW, screenH, frameCount);
    this.renderWorld(ctx, offX, offY, world, cameraX, cameraY, screenW, screenH, frameCount);
  }

  private getTile(chunks: Map<string, Object>, worldX: number, worldY: number): number {
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

  private renderBackground(c: CanvasRenderingContext2D, offX: number, offY: number,
    world: World, cameraX: number, cameraY: number,
    screenW: number, screenH: number, frameCount: number): void {
    const w: number = screenW;
    const h: number = screenH;
    const depth: number = Math.min(1.0, Math.max(0, cameraY / (TILE_SIZE * 30)));

    const camWorldX: number = cameraX + screenW / 2;
    const camWorldY: number = cameraY + screenH / 2;
    const worldGen: WorldGenerator = world.worldGen as WorldGenerator;
    const viewBiome: BiomeType = worldGen.getBiome(camWorldX, camWorldY);

    let topC: string;
    let midC: string;
    let botC: string;
    let farSilhouetteC: string;
    let midSilhouetteC: string;

    switch (viewBiome) {
      case BiomeType.CRYSTAL:
        topC = '#0a1025'; midC = '#060d1a'; botC = '#030812';
        farSilhouetteC = '#0c1530'; midSilhouetteC = '#081020';
        break;
      case BiomeType.MUSHROOM:
        topC = '#150a1e'; midC = '#100718'; botC = '#0a0410';
        farSilhouetteC = '#1a0e28'; midSilhouetteC = '#120a1c';
        break;
      case BiomeType.WATER:
        topC = '#061520'; midC = '#041018'; botC = '#020a10';
        farSilhouetteC = '#081a28'; midSilhouetteC = '#051220';
        break;
      case BiomeType.LAVA:
        topC = '#1a0a05'; midC = '#120703'; botC = '#0a0402';
        farSilhouetteC = '#200e08'; midSilhouetteC = '#180a05';
        break;
      case BiomeType.SHADOW:
        topC = '#0d0520'; midC = '#080315'; botC = '#04020a';
        farSilhouetteC = '#0d0520'; midSilhouetteC = '#0a0318';
        break;
      default:
        if (depth < 0.3) {
          topC = '#0c0c1e'; midC = '#080814'; botC = '#050510';
        } else if (depth < 0.7) {
          topC = '#0a0818'; midC = '#06050f'; botC = '#03030a';
        } else {
          topC = '#0d0520'; midC = '#080315'; botC = '#04020a';
        }
        farSilhouetteC = depth > 0.5 ? '#0d0520' : '#0e0e1c';
        midSilhouetteC = depth > 0.5 ? '#0a0318' : '#0a0a16';
        break;
    }

    const grad: CanvasGradient = c.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, topC);
    grad.addColorStop(0.5, midC);
    grad.addColorStop(1, botC);
    c.fillStyle = grad;
    c.fillRect(0, 0, w, h);

    const farOffX: number = cameraX * 0.1;
    const farOffY: number = cameraY * 0.1;
    c.fillStyle = farSilhouetteC;
    c.globalAlpha = 0.6;
    const farStep: number = 80;
    const farStart: number = Math.floor(farOffX / farStep) * farStep;
    for (let fx: number = farStart - farStep; fx < farStart + w + farStep * 2; fx += farStep) {
      const sx: number = fx - farOffX;
      const hash: number = Math.abs(Math.floor(fx / farStep) * 2654435761) % 100;
      const stalH: number = 30 + (hash % 50);
      const stalW: number = 25 + (hash % 35);
      const ceilY: number = -(farOffY * 0.3) + (hash % 20);
      c.beginPath();
      c.moveTo(sx, ceilY);
      c.lineTo(sx + stalW / 2, ceilY + stalH);
      c.lineTo(sx + stalW, ceilY);
      c.fill();
      const floorY: number = h - (farOffY * 0.2) - (hash % 15);
      const stgH: number = 20 + (hash % 35);
      c.beginPath();
      c.moveTo(sx + 10, floorY);
      c.lineTo(sx + 10 + stalW / 2 - 5, floorY - stgH);
      c.lineTo(sx + 10 + stalW - 10, floorY);
      c.fill();
    }
    c.globalAlpha = 1.0;

    const midOffX: number = cameraX * 0.3;
    const midOffY: number = cameraY * 0.3;
    c.fillStyle = midSilhouetteC;
    c.globalAlpha = 0.4;
    const midStep: number = 50;
    const midStart: number = Math.floor(midOffX / midStep) * midStep;
    for (let mx: number = midStart - midStep; mx < midStart + w + midStep * 2; mx += midStep) {
      const sx: number = mx - midOffX;
      const hash: number = Math.abs(Math.floor(mx / midStep) * 48271) % 100;
      if (hash < 40) {
        const mStalH: number = 15 + (hash % 25);
        const ceilY: number = -(midOffY * 0.4) + (hash % 30);
        c.beginPath();
        c.moveTo(sx, ceilY);
        c.lineTo(sx + 8, ceilY + mStalH);
        c.lineTo(sx + 16, ceilY);
        c.fill();
      }
      if (hash > 60) {
        const mStgH: number = 10 + (hash % 20);
        const floorY: number = h - (midOffY * 0.3) - (hash % 20);
        c.beginPath();
        c.moveTo(sx + 5, floorY);
        c.lineTo(sx + 12, floorY - mStgH);
        c.lineTo(sx + 19, floorY);
        c.fill();
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderWorld(c: CanvasRenderingContext2D, offX: number, offY: number,
    world: World, cameraX: number, cameraY: number,
    screenW: number, screenH: number, frameCount: number): void {
    const chunks: Map<string, Object> = world.chunks;
    const startTX: number = Math.floor(cameraX / TILE_SIZE) - 1;
    const startTY: number = Math.floor(cameraY / TILE_SIZE) - 1;
    const endTX: number = Math.ceil((cameraX + screenW) / TILE_SIZE) + 1;
    const endTY: number = Math.ceil((cameraY + screenH) / TILE_SIZE) + 1;

    const camWorldX: number = cameraX + screenW / 2;
    const camWorldY: number = cameraY + screenH / 2;
    const worldGen: WorldGenerator = world.worldGen as WorldGenerator;
    const viewBiome: BiomeType = worldGen.getBiome(camWorldX, camWorldY);
    const isShadow: boolean = viewBiome === BiomeType.SHADOW;

    const floorColor: string = isShadow ? COLOR_SHADOW_FLOOR : COLOR_FLOOR;
    const floorVarColor: string = isShadow ? '#0a0a16' : COLOR_FLOOR_VAR;
    const wallColor: string = isShadow ? COLOR_SHADOW_WALL : COLOR_WALL;

    for (let ty: number = startTY; ty <= endTY; ty++) {
      for (let tx: number = startTX; tx <= endTX; tx++) {
        const screenX: number = tx * TILE_SIZE + offX;
        const screenY: number = ty * TILE_SIZE + offY;
        const tile: number = this.getTile(chunks, tx * TILE_SIZE, ty * TILE_SIZE);

        if (tile === TileType.WALL) {
          this.renderStaticWall(c, screenX, screenY, tx, ty, wallColor, isShadow, chunks);
        } else if (tile === TileType.FLOOR) {
          this.renderStaticFloor(c, screenX, screenY, tx, ty, floorColor, floorVarColor, isShadow, chunks);
        } else if (tile === TileType.BROKEN_WALL) {
          this.renderStaticBrokenWall(c, screenX, screenY);
        } else if (tile === TileType.PLANT) {
          this.renderStaticPlant(c, screenX, screenY, floorColor);
        } else if (tile === TileType.GLOW_STONE) {
          c.fillStyle = isShadow ? COLOR_SHADOW_FLOOR : COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const glowR: number = 20 + Math.sin(frameCount * 0.05 + tx) * 4;
          c.globalAlpha = 0.15;
          c.fillStyle = isShadow ? '#7c3aed' : COLOR_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, glowR, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = isShadow ? '#8b5cf6' : COLOR_GLOW_STONE;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, 5, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = isShadow ? '#c4b5fd' : '#fff8dc';
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2 - 1, screenY + TILE_SIZE / 2 - 1, 2, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.WATER) {
          const waveOff: number = Math.sin(frameCount * 0.03 + tx * 0.5) * 2;
          const waveOff2: number = Math.sin(frameCount * 0.05 + tx * 0.8) * 1.5;

          c.globalAlpha = 0.75;
          c.fillStyle = COLOR_WATER;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.globalAlpha = 1.0;

          c.fillStyle = '#0a1a3a';
          c.globalAlpha = 0.25;
          c.fillRect(screenX, screenY + TILE_SIZE - 8, TILE_SIZE, 8);
          c.globalAlpha = 1.0;

          const aboveWater: number = this.getTile(chunks, tx * TILE_SIZE, (ty - 1) * TILE_SIZE);
          if (aboveWater !== TileType.WATER) {
            c.fillStyle = COLOR_WATER_LIGHT;
            c.globalAlpha = 0.6;
            c.fillRect(screenX, screenY, TILE_SIZE, 2);
            c.globalAlpha = 0.3;
            c.fillRect(screenX, screenY + 2, TILE_SIZE, 1);
            c.globalAlpha = 1.0;
          }

          c.fillStyle = COLOR_WATER_LIGHT;
          c.globalAlpha = 0.3;
          c.fillRect(screenX + 4, screenY + 8 + waveOff, 24, 3);
          c.fillRect(screenX + 8, screenY + 20 - waveOff, 16, 2);
          c.globalAlpha = 0.15;
          c.fillRect(screenX + 2 + waveOff2, screenY + 14, 10, 2);
          c.fillRect(screenX + 18 - waveOff2, screenY + 26, 8, 2);
          c.globalAlpha = 1.0;

          const bubbleHash: number = ((tx * 61 + ty * 113) % 23);
          if (bubbleHash < 3) {
            const bubbleY: number = (frameCount * 0.3 + bubbleHash * 11) % TILE_SIZE;
            const bubbleX: number = 6 + bubbleHash * 9;
            c.fillStyle = '#ffffff';
            c.globalAlpha = 0.25;
            c.fillRect(screenX + bubbleX, screenY + TILE_SIZE - bubbleY, 2, 2);
            c.globalAlpha = 0.12;
            c.fillRect(screenX + bubbleX + 5, screenY + TILE_SIZE - bubbleY + 4, 1, 1);
            c.globalAlpha = 1.0;
          }
        } else if (tile === TileType.CRYSTAL) {
          c.fillStyle = COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const glow: number = 12 + Math.sin(frameCount * 0.04 + tx + ty) * 4;
          c.globalAlpha = 0.2;
          c.fillStyle = COLOR_CRYSTAL_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, glow, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = COLOR_CRYSTAL;
          c.beginPath();
          c.moveTo(screenX + TILE_SIZE / 2, screenY + 6);
          c.lineTo(screenX + TILE_SIZE / 2 + 6, screenY + TILE_SIZE / 2);
          c.lineTo(screenX + TILE_SIZE / 2, screenY + TILE_SIZE - 6);
          c.lineTo(screenX + TILE_SIZE / 2 - 6, screenY + TILE_SIZE / 2);
          c.closePath();
          c.fill();
          c.fillStyle = '#e0ffff';
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2 - 1, screenY + TILE_SIZE / 2 - 2, 2, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.MUSHROOM) {
          c.fillStyle = COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.globalAlpha = 0.15;
          c.fillStyle = COLOR_MUSHROOM_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, 14, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = COLOR_MUSHROOM_STEM;
          c.fillRect(screenX + 13, screenY + 16, 6, 12);
          c.fillStyle = COLOR_MUSHROOM_CAP;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + 14, 9, Math.PI, 0);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(screenX + 13, screenY + 11, 2, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(screenX + 19, screenY + 9, 1.5, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.LAVA) {
          const lavaOff: number = Math.sin(frameCount * 0.05 + tx * 0.7) * 3;
          const lavaOff2: number = Math.sin(frameCount * 0.08 + tx * 1.2) * 2;

          c.fillStyle = COLOR_LAVA;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);

          c.fillStyle = '#cd4a00';
          c.globalAlpha = 0.4;
          c.fillRect(screenX + 6, screenY + 10 + lavaOff2, 18, 6);
          c.globalAlpha = 1.0;

          c.fillStyle = COLOR_LAVA_LIGHT;
          c.globalAlpha = 0.6;
          c.fillRect(screenX + 4, screenY + 6 + lavaOff, 20, 4);
          c.fillRect(screenX + 10, screenY + 18 - lavaOff, 14, 3);
          c.globalAlpha = 1.0;

          const crustHash: number = ((tx * 43 + ty * 89) % 11);
          if (crustHash < 3) {
            c.fillStyle = '#3a0a00';
            c.globalAlpha = 0.5;
            c.fillRect(screenX + 2 + crustHash * 8, screenY + 4 + crustHash * 3, 6, 3);
            c.fillRect(screenX + 14 - crustHash * 2, screenY + 22 - crustHash * 4, 5, 2);
            c.globalAlpha = 1.0;
          }

          const aboveLava: number = this.getTile(chunks, tx * TILE_SIZE, (ty - 1) * TILE_SIZE);
          if (aboveLava !== TileType.LAVA) {
            c.fillStyle = '#ff6600';
            c.globalAlpha = 0.5 + Math.sin(frameCount * 0.06 + tx) * 0.15;
            c.fillRect(screenX, screenY, TILE_SIZE, 2);
            c.fillStyle = '#ffaa00';
            c.globalAlpha = 0.25;
            c.fillRect(screenX, screenY + 2, TILE_SIZE, 1);
            c.globalAlpha = 1.0;
          }

          const emberHash: number = ((tx * 71 + ty * 127) % 19);
          if (emberHash < 2) {
            const emberY: number = (frameCount * 0.5 + emberHash * 7) % TILE_SIZE;
            c.fillStyle = '#ffcc00';
            c.globalAlpha = 0.4;
            c.fillRect(screenX + 8 + emberHash * 10, screenY + TILE_SIZE - emberY, 1, 1);
            c.globalAlpha = 1.0;
          }
        }
      }
    }
  }

  private renderStaticWall(c: CanvasRenderingContext2D, screenX: number, screenY: number,
    tx: number, ty: number, wallColor: string, isShadow: boolean,
    chunks: Map<string, Object>): void {
    c.fillStyle = wallColor;
    c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);

    const brickH: number = 8;
    const brickW: number = 16;
    const row: number = ty % 2;
    c.fillStyle = isShadow ? '#2d1050' : COLOR_WALL_EDGE;
    c.fillRect(screenX, screenY, TILE_SIZE, 1);
    c.fillRect(screenX, screenY + brickH, TILE_SIZE, 1);
    c.fillRect(screenX, screenY + brickH * 2, TILE_SIZE, 1);
    c.fillRect(screenX, screenY + brickH * 3, TILE_SIZE, 1);
    const vOff: number = row === 0 ? 0 : brickW / 2;
    c.fillRect(screenX + vOff, screenY, 1, brickH);
    c.fillRect(screenX + vOff + brickW, screenY, 1, brickH);
    c.fillRect(screenX + vOff + brickW / 2, screenY + brickH, 1, brickH);
    c.fillRect(screenX + vOff + brickW * 1.5, screenY + brickH, 1, brickH);
    c.fillRect(screenX + vOff, screenY + brickH * 2, 1, brickH);
    c.fillRect(screenX + vOff + brickW, screenY + brickH * 2, 1, brickH);
    c.fillRect(screenX + vOff + brickW / 2, screenY + brickH * 3, 1, brickH);

    const hash: number = ((tx * 31 + ty * 17) % 7);
    if (hash === 0) {
      c.fillStyle = '#1f1f35';
      c.fillRect(screenX + 4, screenY + 3, 3, 2);
    } else if (hash === 1) {
      c.fillStyle = '#1f1f35';
      c.fillRect(screenX + 20, screenY + 18, 4, 2);
    } else if (hash === 3) {
      c.fillStyle = '#22223a';
      c.fillRect(screenX + 10, screenY + 12, 2, 3);
    }

    const oreHash: number = ((tx * 73 + ty * 137) % 47);
    if (oreHash < 3) {
      c.fillStyle = '#8b4513';
      c.fillRect(screenX + 6, screenY + 8, 4, 3);
      c.fillRect(screenX + 9, screenY + 10, 3, 4);
      c.fillStyle = '#cd7f32';
      c.fillRect(screenX + 7, screenY + 9, 2, 2);
      c.fillRect(screenX + 10, screenY + 11, 2, 2);
    } else if (oreHash === 3) {
      c.fillStyle = '#4a5568';
      c.fillRect(screenX + 18, screenY + 4, 5, 3);
      c.fillRect(screenX + 20, screenY + 6, 3, 4);
      c.fillStyle = '#718096';
      c.fillRect(screenX + 19, screenY + 5, 3, 2);
    } else if (oreHash === 4) {
      c.fillStyle = '#a0aec0';
      c.fillRect(screenX + 4, screenY + 20, 3, 3);
      c.fillRect(screenX + 6, screenY + 22, 4, 2);
      c.fillStyle = '#e2e8f0';
      c.fillRect(screenX + 5, screenY + 21, 2, 2);
    } else if (oreHash === 5) {
      c.fillStyle = '#b7791f';
      c.fillRect(screenX + 14, screenY + 14, 4, 3);
      c.fillRect(screenX + 16, screenY + 16, 3, 4);
      c.fillStyle = '#ecc94b';
      c.fillRect(screenX + 15, screenY + 15, 2, 2);
    }

    const belowTile: number = this.getTile(chunks, tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
    if (belowTile === TileType.FLOOR || belowTile === TileType.BROKEN_WALL) {
      c.fillStyle = isShadow ? '#4a1a6a' : '#2d6b3a';
      c.fillRect(screenX, screenY + TILE_SIZE - 3, TILE_SIZE, 3);
      c.fillStyle = isShadow ? '#6b2a9a' : '#3d8a4e';
      c.fillRect(screenX + 2, screenY + TILE_SIZE - 5, 2, 3);
      c.fillRect(screenX + 8, screenY + TILE_SIZE - 4, 1, 2);
      c.fillRect(screenX + 14, screenY + TILE_SIZE - 6, 2, 4);
      c.fillRect(screenX + 22, screenY + TILE_SIZE - 4, 1, 2);
      c.fillRect(screenX + 28, screenY + TILE_SIZE - 5, 2, 3);
    }

    const belowWall: number = this.getTile(chunks, tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
    if (belowWall !== TileType.WALL && belowWall !== TileType.FLOOR) {
      const vineHash: number = ((tx * 41 + ty * 67) % 11);
      if (vineHash < 3) {
        const vineLen: number = 6 + (vineHash * 4);
        c.fillStyle = isShadow ? '#3a1a5a' : '#1a4a2a';
        c.fillRect(screenX + 4 + vineHash * 3, screenY + TILE_SIZE, 1, vineLen);
        c.fillRect(screenX + 5 + vineHash * 3, screenY + TILE_SIZE + vineLen - 2, 1, 3);
        c.fillStyle = isShadow ? '#5a2a8a' : '#2d6b3a';
        c.fillRect(screenX + 3 + vineHash * 3, screenY + TILE_SIZE + vineLen, 3, 2);
      } else if (vineHash < 5) {
        c.fillStyle = isShadow ? '#3a1a5a' : '#1a4a2a';
        c.fillRect(screenX + 8, screenY + TILE_SIZE, 1, 4);
        c.fillRect(screenX + 18, screenY + TILE_SIZE, 1, 6);
        c.fillRect(screenX + 26, screenY + TILE_SIZE, 1, 3);
      }
    }
  }

  private renderStaticFloor(c: CanvasRenderingContext2D, screenX: number, screenY: number,
    tx: number, ty: number, floorColor: string, floorVarColor: string, isShadow: boolean,
    chunks: Map<string, Object>): void {
    const variant: number = ((tx * 7 + ty * 13) % 5);
    c.fillStyle = variant === 0 ? floorColor : variant === 1 ? floorVarColor : variant === 2 ? '#14142a' : variant === 3 ? '#10101e' : floorColor;
    c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);

    const hash: number = ((tx * 23 + ty * 11) % 8);
    if (hash === 0) {
      c.fillStyle = '#1e1e38';
      c.fillRect(screenX + 4, screenY + 8, 4, 3);
      c.fillRect(screenX + 18, screenY + 20, 3, 2);
    } else if (hash === 1) {
      c.fillStyle = '#0e0e1a';
      c.fillRect(screenX + 12, screenY + 4, 2, 2);
      c.fillRect(screenX + 24, screenY + 16, 3, 2);
      c.fillRect(screenX + 6, screenY + 24, 2, 2);
    } else if (hash === 2) {
      c.fillStyle = '#1a1a30';
      c.fillRect(screenX + 8, screenY + 14, 5, 3);
    } else if (hash === 4) {
      c.fillStyle = '#0c0c18';
      c.fillRect(screenX + 20, screenY + 6, 2, 3);
      c.fillRect(screenX + 2, screenY + 22, 3, 2);
    }

    c.fillStyle = '#0a0a14';
    c.globalAlpha = 0.12;
    c.fillRect(screenX, screenY + TILE_SIZE - 1, TILE_SIZE, 1);
    c.fillRect(screenX + TILE_SIZE - 1, screenY, 1, TILE_SIZE);
    c.globalAlpha = 1.0;

    const aboveTile: number = this.getTile(chunks, tx * TILE_SIZE, (ty - 1) * TILE_SIZE);
    if (aboveTile === TileType.WALL) {
      c.fillStyle = isShadow ? '#1a0a2e' : '#1a1a28';
      c.fillRect(screenX, screenY, TILE_SIZE, 3);
    }

    if (aboveTile !== TileType.WALL && aboveTile !== TileType.FLOOR) {
      const stHash: number = ((tx * 53 + ty * 97) % 13);
      if (stHash < 2) {
        c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
        c.fillRect(screenX + 12, screenY, 8, 2);
        c.fillRect(screenX + 14, screenY + 2, 4, 4);
        c.fillRect(screenX + 15, screenY + 6, 2, 4);
        c.fillStyle = isShadow ? '#3a2a5a' : '#3a3a50';
        c.fillRect(screenX + 13, screenY, 2, 3);
      } else if (stHash < 5) {
        c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
        c.fillRect(screenX + 6 + stHash * 4, screenY, 3, 2);
        c.fillRect(screenX + 7 + stHash * 4, screenY + 2, 1, 3 + stHash);
      }
    }

    const belowFloor: number = this.getTile(chunks, tx * TILE_SIZE, (ty + 1) * TILE_SIZE);
    if (belowFloor !== TileType.FLOOR && belowFloor !== TileType.WALL) {
      const smHash: number = ((tx * 37 + ty * 79) % 17);
      if (smHash < 2) {
        c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
        c.fillRect(screenX + 10, screenY + TILE_SIZE - 2, 12, 2);
        c.fillRect(screenX + 12, screenY + TILE_SIZE - 6, 8, 4);
        c.fillRect(screenX + 14, screenY + TILE_SIZE - 9, 4, 3);
        c.fillStyle = isShadow ? '#3a2a5a' : '#3a3a50';
        c.fillRect(screenX + 15, screenY + TILE_SIZE - 8, 2, 2);
      } else if (smHash < 5) {
        c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
        c.fillRect(screenX + 4 + smHash * 5, screenY + TILE_SIZE - 2, 3, 2);
        c.fillRect(screenX + 5 + smHash * 5, screenY + TILE_SIZE - 4 - smHash, 1, 2 + smHash);
      }
    }
  }

  private renderStaticBrokenWall(c: CanvasRenderingContext2D, screenX: number, screenY: number): void {
    c.fillStyle = '#2a2a3e';
    c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
    c.fillStyle = '#3a3a50';
    c.fillRect(screenX + 2, screenY + 2, 8, 6);
    c.fillRect(screenX + 16, screenY + 10, 10, 7);
    c.fillRect(screenX + 6, screenY + 20, 7, 8);
    c.fillStyle = '#4a4a60';
    c.fillRect(screenX + 4, screenY + 4, 4, 3);
    c.fillRect(screenX + 18, screenY + 12, 5, 3);
    c.fillStyle = '#1a1a2e';
    c.fillRect(screenX + 12, screenY + 2, 1, 8);
    c.fillRect(screenX + 14, screenY + 6, 1, 6);
    c.fillRect(screenX + 26, screenY + 18, 1, 10);
  }

  private renderStaticPlant(c: CanvasRenderingContext2D, screenX: number, screenY: number, floorColor: string): void {
    c.fillStyle = floorColor;
    c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
    c.fillStyle = COLOR_PLANT;
    c.fillRect(screenX + 14, screenY + 16, 4, 12);
    c.fillStyle = COLOR_PLANT_LIGHT;
    c.beginPath();
    c.arc(screenX + 16, screenY + 14, 6, 0, Math.PI * 2);
    c.fill();
    c.fillStyle = COLOR_PLANT;
    c.beginPath();
    c.arc(screenX + 12, screenY + 18, 4, 0, Math.PI * 2);
    c.fill();
  }
}
