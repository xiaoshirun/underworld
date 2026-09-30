import { World, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import {
  TrapState, TrapType, TRAP_TELEGRAPH_TIME,
  MechanismType,
  Particle, AmbientParticle,
  BiomeType, TileType, TILE_SIZE, CHUNK_SIZE,
  ChestType, CHEST_SIZE,
  COLOR_TRAP_WARNING, COLOR_SPIKE, COLOR_SPIKE_TIP, COLOR_ROCK,
  COLOR_POISON_CLOUD, COLOR_LAVA, COLOR_LAVA_GEYSER,
  COLOR_VOID_CRACK, COLOR_VOID_PULL, COLOR_VORTEX,
  COLOR_PLATE_ACTIVE, COLOR_PRESSURE_PLATE, COLOR_LEVER, COLOR_LEVER_HANDLE,
  COLOR_PUSH_BLOCK, COLOR_REFLECTOR, COLOR_BREAKABLE_WALL,
  COLOR_TELEPORT_EXIT, COLOR_TELEPORT_ENTRY, COLOR_TELEPORT_RUNE,
  COLOR_CHEST_GLOW, COLOR_CHEST_NORMAL, COLOR_CHEST_ELITE, COLOR_CHEST_BOSS,
  GameSettings, ChunkData,
} from '../GameConstants';
import { TrapComponent } from '../components/TrapComponent';
import { MechanismComponent } from '../components/MechanismComponent';
import { ChestComponent } from '../components/ChestComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import { WorldGenerator } from '../WorldGenerator';

export class EffectRenderer {

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

  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
         cameraY: number, screenW: number, screenH: number,
         settings: GameSettings, frameCount: number): void {
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    this.renderTraps(ctx, offX, offY, world, screenW, screenH, frameCount);
    this.renderMechanisms(ctx, offX, offY, world, screenW, screenH, frameCount);
    this.renderChests(ctx, offX, offY, world, screenW, screenH, settings, frameCount);
  }

  renderParticles(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
                  cameraY: number, screenW: number, screenH: number,
                  settings: GameSettings, frameCount: number,
                  particles: Particle[]): void {
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    this.renderParticlesInternal(ctx, offX, offY, particles);
  }

  renderAmbient(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
                cameraY: number, screenW: number, screenH: number,
                settings: GameSettings, frameCount: number,
                ambientParticles: AmbientParticle[]): void {
    this.renderAmbientParticles(ctx, settings, ambientParticles);
  }

  renderVignetteAndDamage(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
                          cameraY: number, screenW: number, screenH: number,
                          settings: GameSettings, frameCount: number): void {
    this.renderVignette(ctx, world, screenW, screenH, frameCount);
  }

  renderLighting(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
                 cameraY: number, screenW: number, screenH: number,
                 settings: GameSettings, frameCount: number): void {
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    this.renderLightingInternal(ctx, offX, offY, world, cameraX, cameraY, screenW, screenH, settings, frameCount);
  }

  private renderTraps(c: CanvasRenderingContext2D, offX: number, offY: number,
    world: World, screenW: number, screenH: number, frameCount: number): void {
    const trapEntities: Entity[] = world.queryWithTag("trap");
    for (let i: number = 0; i < trapEntities.length; i++) {
      const entity: Entity = trapEntities[i];
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>("Position");
      const trap: TrapComponent | null = entity.getComponent<TrapComponent>("trap");
      if (pos === null || trap === null) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;

      if (screenX < -40 || screenX > screenW + 40 || screenY < -40 || screenY > screenH + 40) {
        continue;
      }

      if (trap.state === TrapState.IDLE) continue;

      const isActive: boolean = trap.state === TrapState.ACTIVE;
      const isTelegraph: boolean = trap.state === TrapState.TELEGRAPH;

      if (isTelegraph) {
        const pulse: number = 0.3 + 0.3 * Math.sin(frameCount * 0.3);
        c.globalAlpha = pulse;
        c.fillStyle = COLOR_TRAP_WARNING;
        c.beginPath();
        c.arc(screenX, screenY, trap.triggerRadius, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      switch (trap.trapType) {
        case TrapType.GROUND_SPIKES:
          if (isActive) {
            c.fillStyle = '#4b5563';
            c.fillRect(screenX - 13, screenY + 4, 26, 4);
            c.fillStyle = COLOR_SPIKE;
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              c.beginPath();
              c.moveTo(spX - 3, spY);
              c.lineTo(spX - 1, spY - 10);
              c.lineTo(spX, spY - 16);
              c.lineTo(spX + 1, spY - 10);
              c.lineTo(spX + 3, spY);
              c.closePath();
              c.fill();
            }
            c.fillStyle = COLOR_SPIKE_TIP;
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              c.beginPath();
              c.moveTo(spX - 0.5, spY - 12);
              c.lineTo(spX, spY - 16);
              c.lineTo(spX + 0.5, spY - 12);
              c.closePath();
              c.fill();
            }
            c.fillStyle = '#9ca3af';
            c.globalAlpha = 0.4;
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              c.fillRect(spX - 1, spY - 8, 1, 6);
            }
            c.globalAlpha = 1.0;
          } else {
            c.fillStyle = '#374151';
            c.globalAlpha = 0.4;
            c.fillRect(screenX - 13, screenY + 5, 26, 3);
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              c.fillRect(spX - 1, screenY + 4, 2, 3);
            }
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.FALLING_ROCKS:
          if (isActive) {
            for (let r: number = 0; r < 4; r++) {
              const rx: number = screenX - 9 + r * 6;
              const ry: number = screenY - 6 + Math.sin(r * 1.5) * 4;
              const rSize: number = 4 + Math.sin(r * 2.3) * 1.5;
              c.fillStyle = COLOR_ROCK;
              c.beginPath();
              c.moveTo(rx, ry - rSize);
              c.lineTo(rx + rSize * 0.8, ry - rSize * 0.3);
              c.lineTo(rx + rSize, ry + rSize * 0.5);
              c.lineTo(rx + rSize * 0.3, ry + rSize);
              c.lineTo(rx - rSize * 0.5, ry + rSize * 0.7);
              c.lineTo(rx - rSize, ry);
              c.closePath();
              c.fill();
              c.fillStyle = '#9ca3af';
              c.globalAlpha = 0.3;
              c.fillRect(rx - 1, ry - rSize * 0.5, 2, rSize * 0.5);
              c.globalAlpha = 1.0;
            }
          } else if (isTelegraph) {
            c.fillStyle = COLOR_ROCK;
            c.globalAlpha = 0.5;
            const fallProgress: number = 1.0 - (trap.timer / TRAP_TELEGRAPH_TIME);
            for (let r: number = 0; r < 3; r++) {
              const rx: number = screenX - 6 + r * 6;
              const ry: number = screenY - 35 + fallProgress * 28;
              const rSize: number = 3 + r * 0.5;
              c.beginPath();
              c.moveTo(rx, ry - rSize);
              c.lineTo(rx + rSize, ry);
              c.lineTo(rx, ry + rSize);
              c.lineTo(rx - rSize, ry);
              c.closePath();
              c.fill();
            }
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.POISON_SPORES:
          if (isActive) {
            c.globalAlpha = 0.6;
            c.fillStyle = COLOR_POISON_CLOUD;
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.8, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 0.4;
            c.beginPath();
            c.arc(screenX + 5, screenY - 4, trap.size * 0.5, 0, Math.PI * 2);
            c.fill();
            c.beginPath();
            c.arc(screenX - 4, screenY + 3, trap.size * 0.4, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 0.3;
            c.fillStyle = '#4ade80';
            for (let p: number = 0; p < 4; p++) {
              const pAngle: number = (p / 4) * Math.PI * 2 + frameCount * 0.05;
              const pDist: number = trap.size * 0.5;
              const px: number = screenX + Math.cos(pAngle) * pDist;
              const py: number = screenY + Math.sin(pAngle) * pDist;
              c.beginPath();
              c.arc(px, py, 2, 0, Math.PI * 2);
              c.fill();
            }
            c.globalAlpha = 1.0;
          } else if (isTelegraph) {
            c.fillStyle = '#22c55e';
            c.globalAlpha = 0.3;
            c.beginPath();
            c.arc(screenX, screenY + 4, 3, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 0.15;
            c.beginPath();
            c.arc(screenX, screenY + 2, 5, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.LAVA_GEYSER:
          if (isActive) {
            const geyserH: number = 22 + Math.sin(frameCount * 0.2) * 6;
            c.globalAlpha = 0.3;
            c.fillStyle = COLOR_LAVA;
            c.fillRect(screenX - 12, screenY - geyserH * 0.7, 24, geyserH * 0.7);
            c.globalAlpha = 0.8;
            c.fillStyle = COLOR_LAVA_GEYSER;
            c.fillRect(screenX - 7, screenY - geyserH, 14, geyserH);
            c.fillStyle = '#fef08a';
            c.globalAlpha = 0.6;
            c.fillRect(screenX - 3, screenY - geyserH, 6, geyserH * 0.8);
            for (let splash: number = 0; splash < 4; splash++) {
              const sx: number = screenX + (Math.random() - 0.5) * 16;
              const sy: number = screenY - geyserH + Math.random() * 5;
              c.fillStyle = '#fbbf24';
              c.globalAlpha = 0.5;
              c.beginPath();
              c.arc(sx, sy, 1.5, 0, Math.PI * 2);
              c.fill();
            }
            c.globalAlpha = 1.0;
          } else if (isTelegraph) {
            c.fillStyle = COLOR_LAVA_GEYSER;
            c.globalAlpha = 0.25;
            c.beginPath();
            c.arc(screenX, screenY, 9, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = '#fef08a';
            c.globalAlpha = 0.15;
            c.beginPath();
            c.arc(screenX, screenY, 5, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.VOID_CRACK:
          c.fillStyle = COLOR_VOID_CRACK;
          if (isActive) {
            c.globalAlpha = 0.7 + 0.3 * Math.sin(frameCount * 0.15);
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.7, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = '#1e1b4b';
            c.globalAlpha = 0.9;
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.4, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = COLOR_VOID_PULL;
            c.globalAlpha = 0.4;
            c.beginPath();
            c.arc(screenX, screenY, trap.triggerRadius * 1.3, 0, Math.PI * 2);
            c.fill();
            c.strokeStyle = '#7c3aed';
            c.lineWidth = 1.5;
            c.globalAlpha = 0.5;
            for (let crack: number = 0; crack < 4; crack++) {
              const cAngle: number = (crack / 4) * Math.PI * 2 + frameCount * 0.02;
              c.beginPath();
              c.moveTo(screenX + Math.cos(cAngle) * trap.size * 0.4, screenY + Math.sin(cAngle) * trap.size * 0.4);
              c.lineTo(screenX + Math.cos(cAngle) * trap.size * 0.9, screenY + Math.sin(cAngle) * trap.size * 0.9);
              c.stroke();
            }
            c.globalAlpha = 1.0;
          } else {
            c.globalAlpha = 0.3;
            c.beginPath();
            c.arc(screenX, screenY, 7, 0, Math.PI * 2);
            c.fill();
            c.strokeStyle = COLOR_VOID_CRACK;
            c.lineWidth = 1;
            c.globalAlpha = 0.2;
            c.beginPath();
            c.arc(screenX, screenY, 10, 0, Math.PI * 2);
            c.stroke();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.WATER_VORTEX:
          if (isActive) {
            const spin: number = frameCount * 0.12;
            c.globalAlpha = 0.2;
            c.fillStyle = COLOR_VORTEX;
            c.beginPath();
            c.arc(screenX, screenY, 14, 0, Math.PI * 2);
            c.fill();
            c.strokeStyle = COLOR_VORTEX;
            c.lineWidth = 2.5;
            c.globalAlpha = 0.7;
            for (let ring: number = 0; ring < 4; ring++) {
              const r: number = 3 + ring * 4;
              c.beginPath();
              c.arc(screenX, screenY, r, spin + ring, spin + ring + Math.PI * 1.3);
              c.stroke();
            }
            c.fillStyle = '#ffffff';
            c.globalAlpha = 0.4;
            c.beginPath();
            c.arc(screenX, screenY, 2, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
            c.lineWidth = 1;
          } else {
            c.fillStyle = COLOR_VORTEX;
            c.globalAlpha = 0.2;
            c.beginPath();
            c.arc(screenX, screenY, 6, 0, Math.PI * 2);
            c.fill();
            c.strokeStyle = COLOR_VORTEX;
            c.lineWidth = 1;
            c.globalAlpha = 0.15;
            c.beginPath();
            c.arc(screenX, screenY, 9, 0, Math.PI * 2);
            c.stroke();
            c.globalAlpha = 1.0;
          }
          break;
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderMechanisms(c: CanvasRenderingContext2D, offX: number, offY: number,
    world: World, screenW: number, screenH: number, frameCount: number): void {
    const mechEntities: Entity[] = world.queryWithTag("mechanism");
    for (let i: number = 0; i < mechEntities.length; i++) {
      const entity: Entity = mechEntities[i];
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>("Position");
      const mech: MechanismComponent | null = entity.getComponent<MechanismComponent>("mechanism");
      if (pos === null || mech === null) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;

      if (screenX < -40 || screenX > screenW + 40 || screenY < -40 || screenY > screenH + 40) {
        continue;
      }

      switch (mech.mechanismType) {
        case MechanismType.PRESSURE_PLATE:
          c.fillStyle = '#374151';
          c.globalAlpha = 0.3;
          c.fillRect(screenX - 13, screenY - 13, 26, 26);
          if (mech.active) {
            c.fillStyle = COLOR_PLATE_ACTIVE;
            c.globalAlpha = 0.9;
            c.fillRect(screenX - 10, screenY - 8, 20, 16);
            c.fillStyle = '#4ade80';
            c.globalAlpha = 0.4;
            c.fillRect(screenX - 8, screenY - 6, 16, 12);
            c.fillStyle = '#ffffff';
            c.globalAlpha = 0.3;
            c.fillRect(screenX - 6, screenY - 4, 4, 2);
          } else {
            c.fillStyle = COLOR_PRESSURE_PLATE;
            c.globalAlpha = 0.6;
            c.fillRect(screenX - 10, screenY - 10, 20, 20);
            c.fillStyle = '#6b7280';
            c.globalAlpha = 0.3;
            c.fillRect(screenX - 8, screenY - 8, 16, 16);
            c.strokeStyle = '#4b5563';
            c.lineWidth = 1;
            c.globalAlpha = 0.4;
            c.strokeRect(screenX - 10, screenY - 10, 20, 20);
          }
          c.globalAlpha = 1.0;
          break;

        case MechanismType.LEVER:
          c.fillStyle = '#4b5563';
          c.fillRect(screenX - 5, screenY + 8, 10, 6);
          c.fillStyle = COLOR_LEVER;
          c.fillRect(screenX - 3, screenY - 12, 6, 24);
          c.fillStyle = '#6b7280';
          c.fillRect(screenX - 2, screenY - 10, 2, 20);
          c.save();
          c.translate(screenX, screenY);
          c.rotate(mech.rotation * Math.PI / 180);
          c.fillStyle = COLOR_LEVER_HANDLE;
          c.fillRect(-2.5, -16, 5, 16);
          c.fillStyle = '#9ca3af';
          c.fillRect(-1.5, -14, 2, 12);
          c.fillStyle = mech.active ? '#4ade80' : '#ef4444';
          c.beginPath();
          c.arc(0, -16, 4, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.4;
          c.beginPath();
          c.arc(-1, -17, 1.5, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.restore();
          break;

        case MechanismType.PUSH_BLOCK:
          const bx: number = mech.posX + offX;
          const by: number = mech.posY + offY;
          c.fillStyle = '#374151';
          c.globalAlpha = 0.2;
          c.fillRect(bx - 13, by - 11, 26, 26);
          c.fillStyle = COLOR_PUSH_BLOCK;
          c.globalAlpha = 1.0;
          c.fillRect(bx - 12, by - 12, 24, 24);
          c.fillStyle = '#737373';
          c.fillRect(bx - 10, by - 10, 20, 2);
          c.fillRect(bx - 10, by - 10, 2, 20);
          c.fillStyle = '#525252';
          c.fillRect(bx - 10, by + 8, 20, 2);
          c.fillRect(bx + 8, by - 10, 2, 20);
          c.fillStyle = '#737373';
          c.fillRect(bx - 4, by - 4, 3, 3);
          c.fillRect(bx + 2, by + 2, 3, 3);
          c.fillRect(bx - 3, by + 3, 2, 2);
          c.strokeStyle = '#525252';
          c.lineWidth = 1;
          c.strokeRect(bx - 12, by - 12, 24, 24);
          break;

        case MechanismType.CRYSTAL_REFLECTOR:
          c.save();
          c.translate(screenX, screenY);
          c.rotate(mech.rotation * Math.PI / 180);
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.3;
          c.beginPath();
          for (let v: number = 0; v < 6; v++) {
            const angle: number = (v / 6) * Math.PI * 2;
            const r: number = 12;
            if (v === 0) c.moveTo(Math.cos(angle) * r, Math.sin(angle) * r);
            else c.lineTo(Math.cos(angle) * r, Math.sin(angle) * r);
          }
          c.closePath();
          c.fill();
          c.fillStyle = COLOR_REFLECTOR;
          c.globalAlpha = 1.0;
          c.beginPath();
          for (let v: number = 0; v < 6; v++) {
            const angle: number = (v / 6) * Math.PI * 2;
            const r: number = 10;
            if (v === 0) c.moveTo(Math.cos(angle) * r, Math.sin(angle) * r);
            else c.lineTo(Math.cos(angle) * r, Math.sin(angle) * r);
          }
          c.closePath();
          c.fill();
          c.strokeStyle = '#a5b4fc';
          c.lineWidth = 1.5;
          c.globalAlpha = 0.6;
          c.beginPath();
          for (let v: number = 0; v < 6; v++) {
            const angle: number = (v / 6) * Math.PI * 2;
            const r: number = 10;
            if (v === 0) c.moveTo(Math.cos(angle) * r, Math.sin(angle) * r);
            else c.lineTo(Math.cos(angle) * r, Math.sin(angle) * r);
          }
          c.closePath();
          c.stroke();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.5 + 0.3 * Math.sin(frameCount * 0.1);
          c.beginPath();
          c.arc(0, 0, 4, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#c7d2fe';
          c.globalAlpha = 0.3;
          c.beginPath();
          c.arc(0, 0, 6, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.restore();
          break;

        case MechanismType.BREAKABLE_WALL:
          c.fillStyle = COLOR_BREAKABLE_WALL;
          c.fillRect(screenX - TILE_SIZE / 2, screenY - TILE_SIZE / 2, TILE_SIZE, TILE_SIZE);
          c.fillStyle = '#4a4a65';
          c.globalAlpha = 0.3;
          c.fillRect(screenX - TILE_SIZE / 2, screenY - TILE_SIZE / 2, TILE_SIZE, 2);
          c.fillRect(screenX - TILE_SIZE / 2, screenY - TILE_SIZE / 2, 2, TILE_SIZE);
          c.strokeStyle = '#3a3a55';
          c.lineWidth = 1.5;
          c.globalAlpha = 0.7;
          c.beginPath();
          c.moveTo(screenX - 8, screenY - 10);
          c.lineTo(screenX - 3, screenY - 2);
          c.lineTo(screenX + 2, screenY + 4);
          c.moveTo(screenX + 6, screenY - 8);
          c.lineTo(screenX + 1, screenY);
          c.lineTo(screenX - 2, screenY + 8);
          c.moveTo(screenX - 5, screenY + 5);
          c.lineTo(screenX, screenY + 2);
          c.stroke();
          c.globalAlpha = 1.0;
          break;

        case MechanismType.TELEPORT_RUNE:
          const runeColor: string = mech.active ? COLOR_TELEPORT_EXIT : COLOR_TELEPORT_ENTRY;
          const spin: number = frameCount * 0.04;
          c.globalAlpha = 0.15;
          c.fillStyle = runeColor;
          c.beginPath();
          c.arc(screenX, screenY, 16, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = runeColor;
          c.lineWidth = 2;
          c.globalAlpha = 0.6;
          c.beginPath();
          c.arc(screenX, screenY, 12, 0, Math.PI * 2);
          c.stroke();
          c.lineWidth = 1.5;
          c.globalAlpha = 0.5;
          c.beginPath();
          c.arc(screenX, screenY, 8, spin, spin + Math.PI * 1.5);
          c.stroke();
          for (let rune: number = 0; rune < 3; rune++) {
            const rAngle: number = spin * 2 + (rune / 3) * Math.PI * 2;
            const rx: number = screenX + Math.cos(rAngle) * 10;
            const ry: number = screenY + Math.sin(rAngle) * 10;
            c.fillStyle = runeColor;
            c.globalAlpha = 0.4;
            c.fillRect(rx - 1.5, ry - 1.5, 3, 3);
          }
          c.fillStyle = COLOR_TELEPORT_RUNE;
          c.globalAlpha = 0.3 + 0.2 * Math.sin(frameCount * 0.08);
          c.beginPath();
          c.arc(screenX, screenY, 6, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.4;
          c.beginPath();
          c.arc(screenX, screenY, 2, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.lineWidth = 1;
          break;
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderParticlesInternal(c: CanvasRenderingContext2D, offX: number, offY: number,
    particles: Particle[]): void {
    for (let i: number = 0; i < particles.length; i++) {
      const pt: Particle = particles[i];
      const alpha: number = pt.life / pt.maxLife;
      c.globalAlpha = alpha;
      c.fillStyle = pt.color;
      const sz: number = pt.size * alpha;
      c.fillRect(pt.x + offX - sz / 2, pt.y + offY - sz / 2, sz, sz);
    }
    c.globalAlpha = 1.0;
  }

  private renderAmbientParticles(c: CanvasRenderingContext2D, settings: GameSettings,
    ambientParticles: AmbientParticle[]): void {
    if (!settings.effectsEnabled) return;
    for (let i: number = 0; i < ambientParticles.length; i++) {
      const ap: AmbientParticle = ambientParticles[i];
      const fadeRatio: number = ap.life / ap.maxLife;
      const alpha: number = ap.alpha * (fadeRatio < 0.2 ? fadeRatio / 0.2 : 1.0);
      c.globalAlpha = alpha;
      c.fillStyle = ap.color;
      c.beginPath();
      c.arc(ap.x, ap.y, ap.size, 0, Math.PI * 2);
      c.fill();
    }
    c.globalAlpha = 1.0;
  }

  private renderVignette(c: CanvasRenderingContext2D, world: World,
    screenW: number, screenH: number, frameCount: number): void {
    const cx: number = screenW / 2;
    const cy: number = screenH / 2;
    const radius: number = Math.max(screenW, screenH) * 0.7;

    // Get player health from ECS
    const playerEntity: Entity | null = world.findEntityByTag("player");
    let hpRatio: number = 1.0;
    if (playerEntity !== null) {
      const health: HealthComponent | null = playerEntity.getComponent<HealthComponent>("Health");
      if (health !== null) {
        hpRatio = health.current / health.max;
      }
    }

    const isLowHP: boolean = hpRatio < 0.3;
    const lowHPIntensity: number = isLowHP ? (1.0 - hpRatio / 0.3) : 0;
    const pulse: number = isLowHP ? 0.5 + 0.5 * Math.sin(frameCount * 0.08) : 0;
    const vignetteAlpha: number = 0.45 + lowHPIntensity * pulse * 0.25;

    const gradient: CanvasGradient = c.createRadialGradient(cx, cy, radius * 0.4, cx, cy, radius);
    gradient.addColorStop(0, 'rgba(0,0,0,0)');
    gradient.addColorStop(1, 'rgba(0,0,0,' + vignetteAlpha + ')');
    c.fillStyle = gradient;
    c.fillRect(0, 0, screenW, screenH);

    if (isLowHP) {
      const redGrad: CanvasGradient = c.createRadialGradient(cx, cy, radius * 0.3, cx, cy, radius);
      redGrad.addColorStop(0, 'rgba(0,0,0,0)');
      redGrad.addColorStop(1, 'rgba(180,0,0,' + (lowHPIntensity * pulse * 0.15) + ')');
      c.fillStyle = redGrad;
      c.fillRect(0, 0, screenW, screenH);
    }

    // Get damage flash timer from GameStateComponent
    const gameStateEntity: Entity | null = world.findEntityByTag("gameState");
    let damageFlashTimer: number = 0;
    if (gameStateEntity !== null) {
      const gsComp: GameStateComponent | null = gameStateEntity.getComponent<GameStateComponent>("gameState");
      if (gsComp !== null) {
        damageFlashTimer = gsComp.damageFlashTimer;
      }
    }

    if (damageFlashTimer > 0) {
      const flashAlpha: number = (damageFlashTimer / 200) * 0.35;
      c.fillStyle = 'rgba(255,0,0,' + flashAlpha + ')';
      c.fillRect(0, 0, screenW, screenH);
    }
  }

  private renderLightingInternal(c: CanvasRenderingContext2D, offX: number, offY: number,
    world: World, cameraX: number, cameraY: number,
    screenW: number, screenH: number, settings: GameSettings, frameCount: number): void {
    if (!settings.effectsEnabled) return;

    const chunks: Map<string, Object> = world.chunks;
    const camWorldX: number = cameraX + screenW / 2;
    const camWorldY: number = cameraY + screenH / 2;
    const worldGen: WorldGenerator = world.worldGen as WorldGenerator;
    const viewBiome: BiomeType = worldGen.getBiome(camWorldX, camWorldY);
    const depth: number = Math.min(1.0, Math.max(0, cameraY / (TILE_SIZE * 30)));
    const isShadow: boolean = viewBiome === BiomeType.SHADOW;
    const isLava: boolean = viewBiome === BiomeType.LAVA;

    const darknessAlpha: number = 0.25 + depth * 0.25 + (isShadow ? 0.15 : 0);
    let darknessR: number = 0;
    let darknessG: number = 0;
    let darknessB: number = 0;
    if (isShadow) {
      darknessR = 10; darknessG = 0; darknessB = 20;
    } else if (isLava) {
      darknessR = 15; darknessG = 5; darknessB = 0;
    }

    c.fillStyle = 'rgba(' + darknessR + ',' + darknessG + ',' + darknessB + ',' + darknessAlpha + ')';
    c.fillRect(0, 0, screenW, screenH);

    const prevOp: string = c.globalCompositeOperation;
    c.globalCompositeOperation = 'lighter';

    // Get player position from ECS
    const playerEntity: Entity | null = world.findEntityByTag("player");
    let playerSX: number = screenW / 2;
    let playerSY: number = screenH / 2;
    if (playerEntity !== null) {
      const playerPos: PositionComponent | null = playerEntity.getComponent<PositionComponent>("Position");
      if (playerPos !== null) {
        playerSX = playerPos.x + offX;
        playerSY = playerPos.y + offY;
      }
    }
    const playerRadius: number = 160 + Math.sin(frameCount * 0.02) * 10;
    const playerGlow: CanvasGradient = c.createRadialGradient(
      playerSX, playerSY, 0, playerSX, playerSY, playerRadius
    );
    playerGlow.addColorStop(0, 'rgba(255,200,100,0.40)');
    playerGlow.addColorStop(0.4, 'rgba(255,180,80,0.18)');
    playerGlow.addColorStop(1, 'rgba(0,0,0,0)');
    c.fillStyle = playerGlow;
    c.fillRect(playerSX - playerRadius, playerSY - playerRadius, playerRadius * 2, playerRadius * 2);

    const startTX: number = Math.floor(cameraX / TILE_SIZE) - 1;
    const startTY: number = Math.floor(cameraY / TILE_SIZE) - 1;
    const endTX: number = Math.ceil((cameraX + screenW) / TILE_SIZE) + 1;
    const endTY: number = Math.ceil((cameraY + screenH) / TILE_SIZE) + 1;

    for (let ty: number = startTY; ty <= endTY; ty++) {
      for (let tx: number = startTX; tx <= endTX; tx++) {
        const tile: number = this.getTile(chunks, tx * TILE_SIZE, ty * TILE_SIZE);
        const sx: number = tx * TILE_SIZE + offX + TILE_SIZE / 2;
        const sy: number = ty * TILE_SIZE + offY + TILE_SIZE / 2;

        if (sx < -80 || sx > screenW + 80 || sy < -80 || sy > screenH + 80) continue;

        let radius: number = 0;
        let lr: number = 0;
        let lg: number = 0;
        let lb: number = 0;
        let la: number = 0;

        if (tile === TileType.GLOW_STONE) {
          radius = 55; lr = 255; lg = 215; lb = 0; la = 0.25;
        } else if (tile === TileType.CRYSTAL) {
          radius = 48; lr = 0; lg = 206; lb = 209; la = 0.22;
        } else if (tile === TileType.MUSHROOM) {
          radius = 42; lr = 255; lg = 105; lb = 180; la = 0.18;
        } else if (tile === TileType.LAVA) {
          radius = 65; lr = 255; lg = 100; lb = 0; la = 0.28;
        }

        if (radius > 0) {
          const flicker: number = Math.sin(frameCount * 0.03 + tx * 0.7 + ty * 1.3) * 4;
          const r: number = radius + flicker;
          const grad: CanvasGradient = c.createRadialGradient(sx, sy, 0, sx, sy, r);
          grad.addColorStop(0, 'rgba(' + lr + ',' + lg + ',' + lb + ',' + la + ')');
          grad.addColorStop(0.6, 'rgba(' + lr + ',' + lg + ',' + lb + ',' + (la * 0.4) + ')');
          grad.addColorStop(1, 'rgba(0,0,0,0)');
          c.fillStyle = grad;
          c.fillRect(sx - r, sy - r, r * 2, r * 2);
        }
      }
    }

    c.globalCompositeOperation = prevOp;
  }

  private renderChests(c: CanvasRenderingContext2D, offX: number, offY: number,
    world: World, screenW: number, screenH: number,
    settings: GameSettings, frameCount: number): void {
    const chestEntities: Entity[] = world.queryWithTag("chest");

    // Determine if guardians are defeated (no active boss entities)
    const bossEntities: Entity[] = world.queryWithTag("boss");
    let bossActive: boolean = false;
    for (let b: number = 0; b < bossEntities.length; b++) {
      if (bossEntities[b].active) {
        bossActive = true;
        break;
      }
    }
    const guardianDefeated: boolean = !bossActive;

    for (let i: number = 0; i < chestEntities.length; i++) {
      const entity: Entity = chestEntities[i];
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>("Position");
      const chest: ChestComponent | null = entity.getComponent<ChestComponent>("chest");
      if (pos === null || chest === null) continue;

      const sx: number = pos.x + offX;
      const sy: number = pos.y + offY;
      if (sx < -40 || sx > screenW + 40 || sy < -40 || sy > screenH + 40) continue;

      const halfSize: number = CHEST_SIZE / 2;
      const bob: number = Math.sin(frameCount * 0.04 + i * 1.3) * 1.5;
      const drawY: number = sy + bob;

      // Ground shadow
      c.globalAlpha = 0.2;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(sx, sy + halfSize + 3, halfSize + 2, 3, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;

      if (chest.chestType === ChestType.NORMAL) {
        this.renderNormalChest(c, sx, drawY, halfSize, chest, settings, frameCount);
      } else if (chest.chestType === ChestType.ELITE) {
        this.renderEliteChest(c, sx, drawY, halfSize, chest, guardianDefeated, settings, frameCount);
      } else if (chest.chestType === ChestType.BOSS) {
        this.renderBossChest(c, sx, drawY, halfSize, chest, settings, frameCount);
      }

      // Open animation - lid lifting with sparkle
      if (chest.opened && chest.openAnim > 0) {
        const lift: number = Math.min(chest.openAnim / 200, 1) * 8;
        const lidColor: string = chest.chestType === ChestType.BOSS ? COLOR_CHEST_BOSS :
          (chest.chestType === ChestType.ELITE ? COLOR_CHEST_ELITE : COLOR_CHEST_NORMAL);
        c.fillStyle = lidColor;
        c.fillRect(sx - halfSize, drawY - halfSize - lift - 4, CHEST_SIZE, 4);
        // Sparkle particles when opening
        if (settings.effectsEnabled) {
          const sparklePhase: number = (frameCount * 0.1 + i * 2) % 1;
          for (let sp: number = 0; sp < 3; sp++) {
            const spAngle: number = (sp / 3) * Math.PI * 2 + frameCount * 0.08;
            const spDist: number = 4 + sparklePhase * 8;
            const spx: number = sx + Math.cos(spAngle) * spDist;
            const spy: number = drawY - halfSize - lift + Math.sin(spAngle) * spDist * 0.5 - 4;
            c.fillStyle = '#ffffff';
            c.globalAlpha = 0.6 * (1 - sparklePhase);
            c.fillRect(spx - 1, spy - 1, 2, 2);
          }
          c.globalAlpha = 1.0;
        }
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderNormalChest(c: CanvasRenderingContext2D, sx: number, sy: number,
    halfSize: number, chest: ChestComponent, settings: GameSettings, frameCount: number): void {
    // Glow aura
    if (settings.effectsEnabled && !chest.opened) {
      c.globalAlpha = 0.15 + Math.sin(frameCount * 0.05) * 0.05;
      c.fillStyle = COLOR_CHEST_GLOW;
      c.beginPath();
      c.arc(sx, sy, halfSize + 8, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Chest body (wooden)
    c.fillStyle = '#6b4f10';
    c.fillRect(sx - halfSize, sy - halfSize + 2, CHEST_SIZE, CHEST_SIZE - 2);

    // Wood grain lines
    c.fillStyle = '#5a4210';
    c.globalAlpha = 0.4;
    c.fillRect(sx - halfSize + 2, sy - halfSize + 4, CHEST_SIZE - 4, 1);
    c.fillRect(sx - halfSize + 1, sy + 1, CHEST_SIZE - 2, 1);
    c.fillRect(sx - halfSize + 3, sy + halfSize - 3, CHEST_SIZE - 6, 1);
    c.globalAlpha = 1.0;

    // Front face (lighter wood)
    c.fillStyle = COLOR_CHEST_NORMAL;
    c.fillRect(sx - halfSize, sy - halfSize + 2, CHEST_SIZE, 3);

    // Metal bands
    c.fillStyle = '#8b7332';
    c.fillRect(sx - halfSize, sy - halfSize + 2, CHEST_SIZE, 1);
    c.fillRect(sx - halfSize, sy + 1, CHEST_SIZE, 2);
    c.fillRect(sx - halfSize, sy + halfSize - 1, CHEST_SIZE, 1);

    // Metal band highlights
    c.fillStyle = '#c0a030';
    c.globalAlpha = 0.5;
    c.fillRect(sx - halfSize + 1, sy + 1, CHEST_SIZE - 2, 1);
    c.globalAlpha = 1.0;

    // Corner rivets
    c.fillStyle = '#c0a030';
    c.fillRect(sx - halfSize + 1, sy - halfSize + 3, 2, 2);
    c.fillRect(sx + halfSize - 3, sy - halfSize + 3, 2, 2);
    c.fillRect(sx - halfSize + 1, sy + halfSize - 2, 2, 2);
    c.fillRect(sx + halfSize - 3, sy + halfSize - 2, 2, 2);

    // Keyhole
    c.fillStyle = '#2a1a05';
    c.fillRect(sx - 1, sy + 2, 3, 3);
    c.fillStyle = '#3a2a10';
    c.fillRect(sx, sy + 3, 1, 1);

    // Lid (top part)
    c.fillStyle = '#7a5c18';
    c.fillRect(sx - halfSize, sy - halfSize, CHEST_SIZE, 3);
    c.fillStyle = '#8b7332';
    c.fillRect(sx - halfSize, sy - halfSize, CHEST_SIZE, 1);

    // Hinge dots
    c.fillStyle = '#8b7332';
    c.fillRect(sx - halfSize + 1, sy - halfSize + 1, 1, 1);
    c.fillRect(sx + halfSize - 2, sy - halfSize + 1, 1, 1);
  }

  private renderEliteChest(c: CanvasRenderingContext2D, sx: number, sy: number,
    halfSize: number, chest: ChestComponent, guardianDefeated: boolean,
    settings: GameSettings, frameCount: number): void {
    const eHalf: number = halfSize + 1;

    // Rune glow aura
    if (settings.effectsEnabled && !chest.opened) {
      const runeGlow: number = 0.2 + Math.sin(frameCount * 0.06) * 0.1;
      c.globalAlpha = runeGlow;
      c.fillStyle = '#67e8f9';
      c.beginPath();
      c.arc(sx, sy, eHalf + 10, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Chest body (metallic)
    c.fillStyle = '#505868';
    c.fillRect(sx - eHalf, sy - eHalf + 2, CHEST_SIZE + 2, CHEST_SIZE);

    // Metal panels
    c.fillStyle = COLOR_CHEST_ELITE;
    c.fillRect(sx - eHalf + 1, sy - eHalf + 3, CHEST_SIZE, CHEST_SIZE - 2);

    // Panel border highlight
    c.fillStyle = '#a0b0c0';
    c.globalAlpha = 0.4;
    c.fillRect(sx - eHalf + 1, sy - eHalf + 3, CHEST_SIZE, 1);
    c.fillRect(sx - eHalf + 1, sy - eHalf + 3, 1, CHEST_SIZE - 2);
    c.globalAlpha = 1.0;

    // Panel border shadow
    c.fillStyle = '#3a4050';
    c.globalAlpha = 0.5;
    c.fillRect(sx - eHalf + 1, sy + eHalf - 1, CHEST_SIZE, 1);
    c.fillRect(sx + eHalf, sy - eHalf + 3, 1, CHEST_SIZE - 2);
    c.globalAlpha = 1.0;

    // Rune engravings (X pattern)
    c.strokeStyle = '#67e8f9';
    c.lineWidth = 1;
    c.globalAlpha = 0.3 + Math.sin(frameCount * 0.04) * 0.15;
    c.beginPath();
    c.moveTo(sx - halfSize + 1, sy - halfSize + 1);
    c.lineTo(sx + halfSize - 1, sy + halfSize - 1);
    c.moveTo(sx + halfSize - 1, sy - halfSize + 1);
    c.lineTo(sx - halfSize + 1, sy + halfSize - 1);
    c.stroke();
    c.globalAlpha = 1.0;

    // Center gem
    if (!chest.opened) {
      const gemPulse: number = 0.6 + 0.4 * Math.sin(frameCount * 0.07);
      c.globalAlpha = 0.3 * gemPulse;
      c.fillStyle = '#67e8f9';
      c.beginPath();
      c.arc(sx, sy, 4, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      // Diamond gem shape
      c.fillStyle = '#22d3ee';
      c.beginPath();
      c.moveTo(sx, sy - 3);
      c.lineTo(sx + 2.5, sy);
      c.lineTo(sx, sy + 3);
      c.lineTo(sx - 2.5, sy);
      c.closePath();
      c.fill();
      // Gem highlight
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.6;
      c.fillRect(sx - 1, sy - 2, 1, 1);
      c.globalAlpha = 1.0;
    }

    // Corner brackets
    c.fillStyle = '#a0b0c0';
    const bLen: number = 4;
    // Top-left
    c.fillRect(sx - eHalf, sy - eHalf + 2, bLen, 1);
    c.fillRect(sx - eHalf, sy - eHalf + 2, 1, bLen);
    // Top-right
    c.fillRect(sx + eHalf - bLen + 1, sy - eHalf + 2, bLen, 1);
    c.fillRect(sx + eHalf, sy - eHalf + 2, 1, bLen);
    // Bottom-left
    c.fillRect(sx - eHalf, sy + eHalf, bLen, 1);
    c.fillRect(sx - eHalf, sy + eHalf - bLen + 1, 1, bLen);
    // Bottom-right
    c.fillRect(sx + eHalf - bLen + 1, sy + eHalf, bLen, 1);
    c.fillRect(sx + eHalf, sy + eHalf - bLen + 1, 1, bLen);

    // Lid
    c.fillStyle = '#606878';
    c.fillRect(sx - eHalf, sy - eHalf, CHEST_SIZE + 2, 3);
    c.fillStyle = '#a0b0c0';
    c.globalAlpha = 0.4;
    c.fillRect(sx - eHalf, sy - eHalf, CHEST_SIZE + 2, 1);
    c.globalAlpha = 1.0;

    // Guardian status indicator
    if (!guardianDefeated) {
      // Locked indicator - red pulsing
      const lockPulse: number = 0.5 + 0.5 * Math.sin(frameCount * 0.1);
      c.fillStyle = '#ff3333';
      c.globalAlpha = 0.3 * lockPulse;
      c.beginPath();
      c.arc(sx, sy + eHalf + 4, 3, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      c.fillStyle = '#ff3333';
      c.fillRect(sx - 1.5, sy + eHalf + 2.5, 3, 3);
      // Lock icon
      c.fillStyle = '#ff6666';
      c.fillRect(sx - 0.5, sy + eHalf + 3, 1, 1);
    } else {
      // Unlocked - green
      c.fillStyle = '#33ff33';
      c.globalAlpha = 0.3;
      c.beginPath();
      c.arc(sx, sy + eHalf + 4, 3, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      c.fillStyle = '#33ff33';
      c.fillRect(sx - 1.5, sy + eHalf + 2.5, 3, 3);
      c.fillStyle = '#66ff66';
      c.fillRect(sx - 0.5, sy + eHalf + 3, 1, 1);
    }
  }

  private renderBossChest(c: CanvasRenderingContext2D, sx: number, sy: number,
    halfSize: number, chest: ChestComponent, settings: GameSettings, frameCount: number): void {
    const bHalf: number = halfSize + 2;

    // Dramatic golden aura
    if (settings.effectsEnabled && !chest.opened) {
      const auraPulse: number = 0.25 + Math.sin(frameCount * 0.04) * 0.1;
      c.globalAlpha = auraPulse;
      c.fillStyle = COLOR_CHEST_BOSS;
      c.beginPath();
      c.arc(sx, sy, bHalf + 14, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = auraPulse * 0.5;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(sx, sy, bHalf + 8, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;

      // Orbiting sparkles
      for (let sp: number = 0; sp < 4; sp++) {
        const spAngle: number = (sp / 4) * Math.PI * 2 + frameCount * 0.03;
        const spDist: number = bHalf + 10;
        const spx: number = sx + Math.cos(spAngle) * spDist;
        const spy: number = sy + Math.sin(spAngle) * spDist * 0.6;
        c.fillStyle = '#ffd700';
        c.globalAlpha = 0.5 + 0.3 * Math.sin(frameCount * 0.08 + sp);
        c.fillRect(spx - 1, spy - 1, 2, 2);
      }
      c.globalAlpha = 1.0;
    }

    // Chest body (ornate gold)
    c.fillStyle = '#8b6914';
    c.fillRect(sx - bHalf, sy - bHalf + 3, CHEST_SIZE + 4, CHEST_SIZE + 2);

    // Front face
    c.fillStyle = COLOR_CHEST_BOSS;
    c.fillRect(sx - bHalf + 1, sy - bHalf + 4, CHEST_SIZE + 2, CHEST_SIZE);

    // Gold panel highlights
    c.fillStyle = '#ffe066';
    c.globalAlpha = 0.4;
    c.fillRect(sx - bHalf + 1, sy - bHalf + 4, CHEST_SIZE + 2, 1);
    c.fillRect(sx - bHalf + 1, sy - bHalf + 4, 1, CHEST_SIZE);
    c.globalAlpha = 1.0;

    // Gold panel shadows
    c.fillStyle = '#6b4f10';
    c.globalAlpha = 0.5;
    c.fillRect(sx - bHalf + 1, sy + bHalf + 1, CHEST_SIZE + 2, 1);
    c.fillRect(sx + bHalf + 1, sy - bHalf + 4, 1, CHEST_SIZE);
    c.globalAlpha = 1.0;

    // Decorative cross bands
    c.fillStyle = '#c0a030';
    c.fillRect(sx - bHalf, sy, CHEST_SIZE + 4, 2);
    c.fillRect(sx - 1, sy - bHalf + 3, 2, CHEST_SIZE + 2);

    // Band highlights
    c.fillStyle = '#ffe066';
    c.globalAlpha = 0.5;
    c.fillRect(sx - bHalf + 1, sy, CHEST_SIZE + 2, 1);
    c.fillRect(sx, sy - bHalf + 4, 1, CHEST_SIZE);
    c.globalAlpha = 1.0;

    // Corner gems
    const gemColors: string[] = ['#ef4444', '#3b82f6', '#22c55e', '#a855f7'];
    const gemPositions: number[][] = [
      [sx - bHalf + 2, sy - bHalf + 5],
      [sx + bHalf, sy - bHalf + 5],
      [sx - bHalf + 2, sy + bHalf],
      [sx + bHalf, sy + bHalf]
    ];
    for (let gi: number = 0; gi < 4; gi++) {
      const gx: number = gemPositions[gi][0];
      const gy: number = gemPositions[gi][1];
      c.fillStyle = gemColors[gi];
      c.beginPath();
      c.arc(gx, gy, 2, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.5;
      c.fillRect(gx - 1, gy - 1, 1, 1);
      c.globalAlpha = 1.0;
    }

    // Center lock plate
    c.fillStyle = '#c0a030';
    c.fillRect(sx - 3, sy - 2, 6, 5);
    c.fillStyle = '#ffe066';
    c.globalAlpha = 0.4;
    c.fillRect(sx - 3, sy - 2, 6, 1);
    c.globalAlpha = 1.0;

    // Keyhole
    c.fillStyle = '#2a1a05';
    c.beginPath();
    c.arc(sx, sy, 1.5, 0, Math.PI * 2);
    c.fill();
    c.fillRect(sx - 0.5, sy, 1, 2);

    // Chains on sides
    c.strokeStyle = '#8b7332';
    c.lineWidth = 1.5;
    c.globalAlpha = 0.6;
    // Left chain
    for (let cl: number = 0; cl < 3; cl++) {
      const cy: number = sy - 4 + cl * 4;
      c.beginPath();
      c.ellipse(sx - bHalf - 1, cy, 1.5, 2, 0, 0, Math.PI * 2);
      c.stroke();
    }
    // Right chain
    for (let cl: number = 0; cl < 3; cl++) {
      const cy: number = sy - 4 + cl * 4;
      c.beginPath();
      c.ellipse(sx + bHalf + 1, cy, 1.5, 2, 0, 0, Math.PI * 2);
      c.stroke();
    }
    c.globalAlpha = 1.0;
    c.lineWidth = 1;

    // Lid
    c.fillStyle = '#a07818';
    c.fillRect(sx - bHalf, sy - bHalf, CHEST_SIZE + 4, 4);
    c.fillStyle = '#ffe066';
    c.globalAlpha = 0.4;
    c.fillRect(sx - bHalf, sy - bHalf, CHEST_SIZE + 4, 1);
    c.globalAlpha = 1.0;

    // Lid rivets
    c.fillStyle = '#c0a030';
    c.fillRect(sx - bHalf + 2, sy - bHalf + 1, 2, 2);
    c.fillRect(sx + bHalf - 2, sy - bHalf + 1, 2, 2);
    c.fillRect(sx - 1, sy - bHalf + 1, 2, 2);
  }
}
