import { World, Entity, PositionComponent } from '@qiuyu/engine';
import {
  TrapState, TrapType, TRAP_TELEGRAPH_TIME,
  COLOR_TRAP_WARNING, COLOR_SPIKE, COLOR_SPIKE_TIP, COLOR_ROCK,
  COLOR_POISON_CLOUD, COLOR_LAVA, COLOR_LAVA_GEYSER,
  COLOR_VOID_CRACK, COLOR_VOID_PULL, COLOR_VORTEX,
} from '../GameConstants';
import { TrapComponent } from '../components/TrapComponent';
import { DrawCmdBuffer } from '../../native/DrawCmd';

function hexToRgb(hex: string): number[] {
  const h: string = hex.replace('#', '');
  const r: number = parseInt(h.substring(0, 2), 16) / 255;
  const g: number = parseInt(h.substring(2, 4), 16) / 255;
  const b: number = parseInt(h.substring(4, 6), 16) / 255;
  return [r, g, b];
}

export class TrapRenderer {

  render(c: CanvasRenderingContext2D, offX: number, offY: number,
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

  // ── New DrawCmd pipeline ──────────────────────────────────────────

  collectCommands(world: World, buf: DrawCmdBuffer, offX: number, offY: number,
    screenW: number, screenH: number, frameCount: number): void {
    const trapEntities: Entity[] = world.queryWithTag("trap");
    for (let i: number = 0; i < trapEntities.length; i++) {
      const entity: Entity = trapEntities[i];
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>("Position");
      const trap: TrapComponent | null = entity.getComponent<TrapComponent>("trap");
      if (pos === null || trap === null) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;
      if (screenX < -40 || screenX > screenW + 40 || screenY < -40 || screenY > screenH + 40) continue;
      if (trap.state === TrapState.IDLE) continue;

      const isActive: boolean = trap.state === TrapState.ACTIVE;
      const isTelegraph: boolean = trap.state === TrapState.TELEGRAPH;

      if (isTelegraph) {
        const pulse: number = 0.3 + 0.3 * Math.sin(frameCount * 0.3);
        const wc: number[] = hexToRgb(COLOR_TRAP_WARNING);
        buf.pushCircle(screenX, screenY, trap.triggerRadius, wc[0], wc[1], wc[2], pulse, 0, 0);
      }

      switch (trap.trapType) {
        case TrapType.GROUND_SPIKES:
          if (isActive) {
            const baseC: number[] = hexToRgb('#4b5563');
            buf.pushRect(screenX - 13, screenY + 4, 26, 4, baseC[0], baseC[1], baseC[2], 1, 0, 0);
            const spikeC: number[] = hexToRgb(COLOR_SPIKE);
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              buf.pushTriangle(spX - 3, spY, spX, spY - 16, spX + 3, spY, spikeC[0], spikeC[1], spikeC[2], 1, 0);
            }
            const tipC: number[] = hexToRgb(COLOR_SPIKE_TIP);
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              buf.pushTriangle(spX - 0.5, spY - 12, spX, spY - 16, spX + 0.5, spY - 12, tipC[0], tipC[1], tipC[2], 1, 0);
            }
            const hlC: number[] = hexToRgb('#9ca3af');
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              const spY: number = screenY + 6;
              buf.pushRect(spX - 1, spY - 8, 1, 6, hlC[0], hlC[1], hlC[2], 0.4, 0, 0);
            }
          } else {
            const hidC: number[] = hexToRgb('#374151');
            buf.pushRect(screenX - 13, screenY + 5, 26, 3, hidC[0], hidC[1], hidC[2], 0.4, 0, 0);
            for (let s: number = 0; s < 5; s++) {
              const spX: number = screenX - 10 + s * 5;
              buf.pushRect(spX - 1, screenY + 4, 2, 3, hidC[0], hidC[1], hidC[2], 0.4, 0, 0);
            }
          }
          break;

        case TrapType.FALLING_ROCKS:
          if (isActive) {
            const rockC: number[] = hexToRgb(COLOR_ROCK);
            for (let r: number = 0; r < 4; r++) {
              const rx: number = screenX - 9 + r * 6;
              const ry: number = screenY - 6 + Math.sin(r * 1.5) * 4;
              const rSize: number = 4 + Math.sin(r * 2.3) * 1.5;
              buf.pushCircle(rx, ry, rSize, rockC[0], rockC[1], rockC[2], 1, 0, 0);
              const hlC: number[] = hexToRgb('#9ca3af');
              buf.pushRect(rx - 1, ry - rSize * 0.5, 2, rSize * 0.5, hlC[0], hlC[1], hlC[2], 0.3, 0, 0);
            }
          } else if (isTelegraph) {
            const rockC: number[] = hexToRgb(COLOR_ROCK);
            const fallProgress: number = 1.0 - (trap.timer / TRAP_TELEGRAPH_TIME);
            for (let r: number = 0; r < 3; r++) {
              const rx: number = screenX - 6 + r * 6;
              const ry: number = screenY - 35 + fallProgress * 28;
              const rSize: number = 3 + r * 0.5;
              buf.pushCircle(rx, ry, rSize, rockC[0], rockC[1], rockC[2], 0.5, 0, 0);
            }
          }
          break;

        case TrapType.POISON_SPORES:
          if (isActive) {
            const poisonC: number[] = hexToRgb(COLOR_POISON_CLOUD);
            buf.pushCircle(screenX, screenY, trap.size * 0.8, poisonC[0], poisonC[1], poisonC[2], 0.6, 0, 0);
            buf.pushCircle(screenX + 5, screenY - 4, trap.size * 0.5, poisonC[0], poisonC[1], poisonC[2], 0.4, 0, 0);
            buf.pushCircle(screenX - 4, screenY + 3, trap.size * 0.4, poisonC[0], poisonC[1], poisonC[2], 0.4, 0, 0);
            const particleC: number[] = hexToRgb('#4ade80');
            for (let p: number = 0; p < 4; p++) {
              const pAngle: number = (p / 4) * Math.PI * 2 + frameCount * 0.05;
              const pDist: number = trap.size * 0.5;
              const px: number = screenX + Math.cos(pAngle) * pDist;
              const py: number = screenY + Math.sin(pAngle) * pDist;
              buf.pushCircle(px, py, 2, particleC[0], particleC[1], particleC[2], 0.3, 0, 0);
            }
          } else if (isTelegraph) {
            const tc: number[] = hexToRgb('#22c55e');
            buf.pushCircle(screenX, screenY + 4, 3, tc[0], tc[1], tc[2], 0.3, 0, 0);
            buf.pushCircle(screenX, screenY + 2, 5, tc[0], tc[1], tc[2], 0.15, 0, 0);
          }
          break;

        case TrapType.LAVA_GEYSER:
          if (isActive) {
            const geyserH: number = 22 + Math.sin(frameCount * 0.2) * 6;
            const lavaC: number[] = hexToRgb(COLOR_LAVA);
            buf.pushRect(screenX - 12, screenY - geyserH * 0.7, 24, geyserH * 0.7, lavaC[0], lavaC[1], lavaC[2], 0.3, 0, 0);
            const geyserC: number[] = hexToRgb(COLOR_LAVA_GEYSER);
            buf.pushRect(screenX - 7, screenY - geyserH, 14, geyserH, geyserC[0], geyserC[1], geyserC[2], 0.8, 0, 0);
            const hotC: number[] = hexToRgb('#fef08a');
            buf.pushRect(screenX - 3, screenY - geyserH, 6, geyserH * 0.8, hotC[0], hotC[1], hotC[2], 0.6, 0, 0);
            const splashC: number[] = hexToRgb('#fbbf24');
            for (let splash: number = 0; splash < 4; splash++) {
              const ssx: number = screenX + (Math.random() - 0.5) * 16;
              const ssy: number = screenY - geyserH + Math.random() * 5;
              buf.pushCircle(ssx, ssy, 1.5, splashC[0], splashC[1], splashC[2], 0.5, 0, 0);
            }
          } else if (isTelegraph) {
            const gc: number[] = hexToRgb(COLOR_LAVA_GEYSER);
            buf.pushCircle(screenX, screenY, 9, gc[0], gc[1], gc[2], 0.25, 0, 0);
            const hc: number[] = hexToRgb('#fef08a');
            buf.pushCircle(screenX, screenY, 5, hc[0], hc[1], hc[2], 0.15, 0, 0);
          }
          break;

        case TrapType.VOID_CRACK:
          const voidC: number[] = hexToRgb(COLOR_VOID_CRACK);
          if (isActive) {
            buf.pushCircle(screenX, screenY, trap.size * 0.7, voidC[0], voidC[1], voidC[2], 0.7 + 0.3 * Math.sin(frameCount * 0.15), 0, 0);
            buf.pushCircle(screenX, screenY, trap.size * 0.4, 0.118, 0.106, 0.294, 0.9, 0, 0);
            const pullC: number[] = hexToRgb(COLOR_VOID_PULL);
            buf.pushCircle(screenX, screenY, trap.triggerRadius * 1.3, pullC[0], pullC[1], pullC[2], 0.4, 0, 0);
            const crackC: number[] = hexToRgb('#7c3aed');
            for (let crack: number = 0; crack < 4; crack++) {
              const cAngle: number = (crack / 4) * Math.PI * 2 + frameCount * 0.02;
              const x1: number = screenX + Math.cos(cAngle) * trap.size * 0.4;
              const y1: number = screenY + Math.sin(cAngle) * trap.size * 0.4;
              const x2: number = screenX + Math.cos(cAngle) * trap.size * 0.9;
              const y2: number = screenY + Math.sin(cAngle) * trap.size * 0.9;
              buf.pushLine(x1, y1, x2, y2, 1.5, crackC[0], crackC[1], crackC[2], 0.5, 0);
            }
          } else {
            buf.pushCircle(screenX, screenY, 7, voidC[0], voidC[1], voidC[2], 0.3, 0, 0);
            buf.pushCircle(screenX, screenY, 10, voidC[0], voidC[1], voidC[2], 0.2, 0, 0);
          }
          break;

        case TrapType.WATER_VORTEX:
          if (isActive) {
            const vortC: number[] = hexToRgb(COLOR_VORTEX);
            buf.pushCircle(screenX, screenY, 14, vortC[0], vortC[1], vortC[2], 0.2, 0, 0);
            // Approximate spiral arcs with concentric circles
            for (let ring: number = 0; ring < 4; ring++) {
              const r: number = 3 + ring * 4;
              buf.pushCircle(screenX, screenY, r, vortC[0], vortC[1], vortC[2], 0.35, 0, 0);
            }
            buf.pushCircle(screenX, screenY, 2, 1, 1, 1, 0.4, 0, 0);
          } else {
            const vortC: number[] = hexToRgb(COLOR_VORTEX);
            buf.pushCircle(screenX, screenY, 6, vortC[0], vortC[1], vortC[2], 0.2, 0, 0);
            buf.pushCircle(screenX, screenY, 9, vortC[0], vortC[1], vortC[2], 0.15, 0, 0);
          }
          break;
      }
    }
  }
}
