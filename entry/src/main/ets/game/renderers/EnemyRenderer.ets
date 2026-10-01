import { World, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import {
  EnemyType,
  XP_ORB_SIZE,
  COLOR_SLIME_GRAY, COLOR_SLIME_GRAY_LIGHT, COLOR_SLIME_PURPLE, COLOR_SLIME_PURPLE_LIGHT,
  COLOR_SLIME_RED, COLOR_SLIME_RED_LIGHT, COLOR_SLIME_BLUE, COLOR_SLIME_BLUE_LIGHT,
  COLOR_SLIME_YELLOW, COLOR_SLIME_YELLOW_LIGHT, COLOR_SLIME_GHOST, COLOR_SLIME_GHOST_LIGHT,
  COLOR_SLIME_PUPIL,
  COLOR_XP_ORB, COLOR_XP_GLOW,
  GameSettings,
} from '../GameConstants';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { LevelComponent } from '../components/LevelComponent';
import { XpPickupComponent } from '../components/XpPickupComponent';
import { SpriteManager } from '../sprites/SpriteManager';
import { SpriteAtlas, FrameCoord } from '../sprites/SpriteAtlas';
import { drawHumanoidBeast } from '../sprites/HumanoidBeastSprite';
import { DrawCmdBuffer } from '../../native/DrawCmd';

function hexToRgb(hex: string): number[] {
  const r: number = parseInt(hex.slice(1, 3), 16) / 255;
  const g: number = parseInt(hex.slice(3, 5), 16) / 255;
  const b: number = parseInt(hex.slice(5, 7), 16) / 255;
  return [r, g, b];
}

export class EnemyRenderer {
  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number, cameraY: number,
         screenW: number, screenH: number, settings: GameSettings, frameCount: number,
         spriteManager: SpriteManager | null = null): void {
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    if (spriteManager === null || !spriteManager.isReady()) {
      this.renderEnemiesProcedural(world, ctx, offX, offY, screenW, screenH, frameCount);
      this.renderXpOrbs(world, ctx, offX, offY, screenW, screenH, frameCount);
      return;
    }
    this.renderEnemiesSprite(world, ctx, offX, offY, screenW, screenH, frameCount, spriteManager);
    this.renderXpOrbs(world, ctx, offX, offY, screenW, screenH, frameCount);
  }

  private renderEnemiesProcedural(world: World, c: CanvasRenderingContext2D, offX: number, offY: number, screenW: number, screenH: number, frameCount: number): void {
    const enemies: Entity[] = world.queryWithTag('enemy');
    const player: Entity | null = world.findEntityByTag("player");
    const playerLevelComp: LevelComponent | null = player !== null ? player.getComponent<LevelComponent>("level") : null;
    const playerLevel: number = playerLevelComp !== null ? playerLevelComp.level : 1;
    for (let i: number = 0; i < enemies.length; i++) {
      const entity: Entity = enemies[i];
      if (!entity.active) continue;

      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      const health: HealthComponent | null = entity.getComponent<HealthComponent>('Health');
      const ai: EnemyAIComponent | null = entity.getComponent<EnemyAIComponent>('enemyAI');
      if (pos === null || health === null || ai === null) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;

      if (screenX < -50 || screenX > screenW + 50 || screenY < -50 || screenY > screenH + 50) {
        continue;
      }

      const sc: number = ai.size / 48;
      const bp: number = ai.bouncePhase;
      const flash: boolean = ai.hitFlash > 0;
      const cx: number = screenX;
      const cy: number = screenY;

      if (ai.enemyType === EnemyType.GRAY_SLIME) {
        const bounce: number = Math.sin(bp) * 3 * sc;
        const squash: number = 1 + Math.sin(bp) * 0.12;
        c.save();
        c.translate(cx, cy + bounce);
        c.scale(squash, 1 / squash);
        c.globalAlpha = 0.2;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 14 * sc, 13 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.fill();
        } else {
          c.strokeStyle = '#1a1a2e';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_GRAY;
          c.beginPath();
          c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = COLOR_SLIME_GRAY_LIGHT;
          c.beginPath();
          c.ellipse(-3 * sc, -4 * sc, 6 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.45;
          c.beginPath();
          c.ellipse(-5 * sc, -6 * sc, 2.5 * sc, 1.8 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 0.2;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(4 * sc, 3 * sc, 2 * sc, 1.5 * sc, 0.3, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-4 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_PUPIL;
          c.beginPath();
          c.arc(-3.5 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-4 * sc, -1.2 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4 * sc, -1.2 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = COLOR_SLIME_PUPIL;
          c.lineWidth = 1 * sc;
          c.beginPath();
          c.arc(0, 3.5 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
          c.stroke();
        }
        c.restore();
      } else if (ai.enemyType === EnemyType.PURPLE_SLIME) {
        const bounce: number = Math.sin(bp * 1.3) * 1.5 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        if (!flash) {
          c.globalAlpha = 0.12 + Math.sin(frameCount * 0.05) * 0.05;
          c.fillStyle = COLOR_SLIME_PURPLE;
          c.beginPath();
          c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 0.25;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 14 * sc, 13 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        for (let t: number = 0; t < 4; t++) {
          const angle: number = (t / 4) * Math.PI * 2 + frameCount * 0.03;
          const tx: number = Math.cos(angle) * 16 * sc;
          const ty: number = Math.sin(angle) * 10 * sc + 4 * sc;
          if (flash) {
            c.globalAlpha = 0.9;
            c.fillStyle = '#ffffff';
          } else {
            c.globalAlpha = 0.9;
            c.fillStyle = COLOR_SLIME_PURPLE;
          }
          c.beginPath();
          c.ellipse(tx, ty, 3 * sc, 2 * sc, angle, 0, Math.PI * 2);
          c.fill();
        }
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
        } else {
          c.strokeStyle = '#1a0533';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(0, 0, 16 * sc, 14 * sc, 0, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_PURPLE;
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = COLOR_SLIME_PURPLE_LIGHT;
          c.beginPath();
          c.ellipse(-3 * sc, -4 * sc, 7 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
          const dripPhase: number = (frameCount * 0.03) % 1;
          for (let d: number = 0; d < 3; d++) {
            const dx: number = (-6 + d * 6) * sc;
            const dy: number = 10 * sc + dripPhase * 8 * sc;
            const dAlpha: number = 0.6 * (1 - dripPhase);
            c.globalAlpha = dAlpha;
            c.fillStyle = COLOR_SLIME_PURPLE;
            c.beginPath();
            c.ellipse(dx, dy, 1.5 * sc, (2 + dripPhase * 3) * sc, 0, 0, Math.PI * 2);
            c.fill();
          }
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-4 * sc, -2 * sc, 3.2 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -2 * sc, 3.2 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#ff0040';
          c.beginPath();
          c.arc(-3.5 * sc, -1.5 * sc, 1.8 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1.5 * sc, 1.8 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1a1a2e';
          c.beginPath();
          c.arc(-3.5 * sc, -1.5 * sc, 0.9 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1.5 * sc, 0.9 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-4.2 * sc, -2.2 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.8 * sc, -2.2 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#4c1d95';
          c.lineWidth = 1.5 * sc;
          c.beginPath();
          c.moveTo(-8 * sc, -6 * sc);
          c.lineTo(-2 * sc, -4.5 * sc);
          c.stroke();
          c.beginPath();
          c.moveTo(8 * sc, -6 * sc);
          c.lineTo(2 * sc, -4.5 * sc);
          c.stroke();
          if (ai.isEngulfing) {
            c.fillStyle = '#2d1060';
            c.beginPath();
            c.ellipse(0, 5 * sc, 6 * sc, 5 * sc, 0, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = '#1a0533';
            c.beginPath();
            c.ellipse(0, 6 * sc, 3 * sc, 2.5 * sc, 0, 0, Math.PI * 2);
            c.fill();
          } else {
            c.fillStyle = '#2d1060';
            c.beginPath();
            c.ellipse(0, 5 * sc, 5 * sc, 3 * sc, 0, 0, Math.PI * 2);
            c.fill();
          }
        }
        c.restore();
      } else if (ai.enemyType === EnemyType.RED_SLIME) {
        const charge: number = ai.isCharging ? Math.abs(Math.sin(frameCount * 0.08)) : Math.abs(Math.sin(frameCount * 0.04)) * 0.3;
        c.save();
        c.translate(cx, cy);
        if (!flash) {
          c.globalAlpha = 0.1 + charge * 0.1;
          c.fillStyle = '#ff4444';
          c.beginPath();
          c.ellipse(0, 0, (18 + charge * 2) * sc, (16 + charge * 2) * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 0.25;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 13 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          for (let fi: number = 0; fi < 7; fi++) {
            const angle: number = -Math.PI * 0.8 + (fi / 6) * Math.PI * 0.6;
            const flicker: number = Math.sin(frameCount * 0.12 + fi * 1.5) * 3;
            const len: number = (6 + flicker + charge * 3) * sc;
            const sx: number = Math.cos(angle) * 12 * sc;
            const sy: number = Math.sin(angle) * 10 * sc;
            const ex: number = sx + Math.cos(angle) * len;
            const ey: number = sy + Math.sin(angle) * len;
            c.fillStyle = fi % 2 === 0 ? '#ff6600' : '#ffaa00';
            c.globalAlpha = 0.7;
            c.beginPath();
            c.moveTo(sx - 2 * sc, sy);
            c.lineTo(ex, ey);
            c.lineTo(sx + 2 * sc, sy);
            c.closePath();
            c.fill();
          }
          c.strokeStyle = '#7f1d1d';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(1 * sc, 0, 15 * sc, 12 * sc, 0.1, 0, Math.PI * 2);
          c.stroke();
        }
        c.globalAlpha = 1.0;
        if (flash) {
          c.fillStyle = '#ffffff';
        } else {
          c.fillStyle = COLOR_SLIME_RED;
        }
        c.beginPath();
        c.ellipse(1 * sc, 0, 14 * sc, 11 * sc, 0.1, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_RED_LIGHT;
          c.beginPath();
          c.ellipse(-2 * sc, -3.5 * sc, 6 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-3.5 * sc, -1.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -1.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#ffcc00';
          c.beginPath();
          c.arc(-3 * sc, -1 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1a1a2e';
          c.beginPath();
          c.arc(-3 * sc, -1 * sc, 0.7 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1 * sc, 0.7 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-3.5 * sc, -1.8 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4 * sc, -1.8 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#7f1d1d';
          c.lineWidth = 1.5 * sc;
          c.beginPath();
          c.moveTo(-7 * sc, -5 * sc);
          c.lineTo(-2 * sc, -3.5 * sc);
          c.stroke();
          c.beginPath();
          c.moveTo(7 * sc, -5 * sc);
          c.lineTo(2 * sc, -3.5 * sc);
          c.stroke();
          c.strokeStyle = '#7f1d1d';
          c.lineWidth = 1.2 * sc;
          c.beginPath();
          c.moveTo(-4 * sc, 4 * sc);
          c.lineTo(-2 * sc, 2.5 * sc);
          c.lineTo(0, 4 * sc);
          c.lineTo(2 * sc, 2.5 * sc);
          c.lineTo(4 * sc, 4 * sc);
          c.stroke();
        }
        c.restore();
      } else if (ai.enemyType === EnemyType.BLUE_SLIME) {
        const bounce: number = Math.sin(bp * 0.8) * 1.5 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        if (!flash) {
          for (let d: number = 0; d < 6; d++) {
            const angle: number = (d / 6) * Math.PI * 2 + frameCount * 0.02;
            const dist: number = (16 + Math.sin(frameCount * 0.03 + d * 2) * 3) * sc;
            const dx: number = Math.cos(angle) * dist;
            const dy: number = Math.sin(angle) * dist * 0.7 - 2.5 * sc;
            c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
            c.globalAlpha = 0.4 + Math.sin(frameCount * 0.04 + d) * 0.2;
            c.beginPath();
            c.moveTo(dx, dy - 2 * sc);
            c.lineTo(dx + 1 * sc, dy - 0.5 * sc);
            c.lineTo(dx + 2 * sc, dy);
            c.lineTo(dx + 1 * sc, dy + 0.5 * sc);
            c.lineTo(dx, dy + 2 * sc);
            c.lineTo(dx - 1 * sc, dy + 0.5 * sc);
            c.lineTo(dx - 2 * sc, dy);
            c.lineTo(dx - 1 * sc, dy - 0.5 * sc);
            c.closePath();
            c.fill();
          }
        }
        c.globalAlpha = 0.2;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 13 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.fill();
        } else {
          c.strokeStyle = '#0c2d5e';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.7;
          c.fillStyle = COLOR_SLIME_BLUE;
          c.beginPath();
          c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 0.3;
          c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
          const rippleOff: number = Math.sin(frameCount * 0.04) * 1.5 * sc;
          c.beginPath();
          c.ellipse(0, rippleOff, 10 * sc, 7 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.15;
          c.beginPath();
          c.ellipse(-4 * sc, -5 * sc, 4 * sc, 3 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#93c5fd';
          c.lineWidth = 0.8 * sc;
          c.globalAlpha = 0.4;
          for (let w: number = 0; w < 3; w++) {
            const wy: number = (-3 + w * 4) * sc;
            const woff: number = Math.sin(frameCount * 0.05 + w) * 2 * sc;
            c.beginPath();
            c.moveTo(-8 * sc, wy + woff);
            c.quadraticCurveTo(0, wy - woff - 1.5 * sc, 8 * sc, wy + woff);
            c.stroke();
          }
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-3.5 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(3.5 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#1e40af';
          c.beginPath();
          c.arc(-3 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-3.5 * sc, -1.2 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.5 * sc, -1.2 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#1e3a5f';
          c.lineWidth = 1 * sc;
          c.beginPath();
          c.arc(0, 3 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
          c.stroke();
        }
        c.restore();
      } else if (ai.enemyType === EnemyType.YELLOW_SLIME) {
        const bounce: number = Math.abs(Math.sin(bp * 1.1)) * 4 * sc;
        c.save();
        c.translate(cx, cy - bounce);
        if (!flash) {
          c.globalAlpha = 0.08 + Math.sin(frameCount * 0.04) * 0.03;
          c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
          c.beginPath();
          c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
          c.fill();
          for (let sp: number = 0; sp < 8; sp++) {
            const angle: number = (sp / 8) * Math.PI * 2 + frameCount * 0.04;
            const dist: number = (14 + Math.sin(frameCount * 0.06 + sp * 3) * 4) * sc;
            const sx: number = Math.cos(angle) * dist;
            const sy: number = Math.sin(angle) * dist * 0.6;
            const sparkSize: number = (1 + Math.sin(frameCount * 0.1 + sp * 2) * 0.6) * sc;
            c.fillStyle = sp % 2 === 0 ? COLOR_SLIME_YELLOW_LIGHT : '#ffffff';
            c.globalAlpha = 0.6 + Math.sin(frameCount * 0.08 + sp) * 0.3;
            c.beginPath();
            c.moveTo(sx, sy - sparkSize * 2);
            c.lineTo(sx + sparkSize * 0.4, sy - sparkSize * 0.4);
            c.lineTo(sx + sparkSize * 2, sy);
            c.lineTo(sx + sparkSize * 0.4, sy + sparkSize * 0.4);
            c.lineTo(sx, sy + sparkSize * 2);
            c.lineTo(sx - sparkSize * 0.4, sy + sparkSize * 0.4);
            c.lineTo(sx - sparkSize * 2, sy);
            c.lineTo(sx - sparkSize * 0.4, sy - sparkSize * 0.4);
            c.closePath();
            c.fill();
          }
          if (Math.random() < 0.3) {
            const boltAngle: number = Math.random() * Math.PI * 2;
            const boltDist: number = 10 * sc;
            const bx: number = Math.cos(boltAngle) * boltDist;
            const by: number = Math.sin(boltAngle) * boltDist * 0.6;
            c.strokeStyle = '#fef08a';
            c.lineWidth = 1 * sc;
            c.globalAlpha = 0.7;
            c.beginPath();
            c.moveTo(bx, by);
            c.lineTo(bx + 3 * sc, by - 2 * sc);
            c.lineTo(bx + 1 * sc, by - 1 * sc);
            c.lineTo(bx + 4 * sc, by - 4 * sc);
            c.stroke();
          }
        }
        c.globalAlpha = 0.15;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, (13 + bounce / sc) * sc, 11 * sc, 2.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(0, 0, 13 * sc, 11 * sc, 0, 0, Math.PI * 2);
          c.fill();
        } else {
          c.strokeStyle = '#78350f';
          c.lineWidth = 2 * sc;
          c.globalAlpha = 0.8;
          c.beginPath();
          c.ellipse(0, 0, 13 * sc, 11 * sc, 0, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_YELLOW;
          c.beginPath();
          c.ellipse(0, 0, 12 * sc, 10 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
          c.beginPath();
          c.ellipse(-2.5 * sc, -3.5 * sc, 5.5 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.5;
          c.beginPath();
          c.ellipse(-4 * sc, -5.5 * sc, 2.5 * sc, 1.8 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(-3 * sc, -0.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(3 * sc, -0.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#92400e';
          c.beginPath();
          c.arc(-2.5 * sc, 0, 1.3 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.5 * sc, 0, 1.3 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(-3 * sc, -0.8 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3 * sc, -0.8 * sc, 0.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#92400e';
          c.lineWidth = 1 * sc;
          c.beginPath();
          c.arc(0, 3 * sc, 3.5 * sc, 0.1, Math.PI - 0.1);
          c.stroke();
          c.fillStyle = '#f59e0b';
          c.globalAlpha = 0.3;
          c.beginPath();
          c.ellipse(-6 * sc, 2 * sc, 2 * sc, 1.2 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.ellipse(6 * sc, 2 * sc, 2 * sc, 1.2 * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.restore();
      } else if (ai.enemyType === EnemyType.GHOST_SLIME) {
        const float: number = Math.sin(bp * 0.5) * 4 * sc;
        const phase: number = Math.sin(frameCount * 0.05) * 0.15;
        c.save();
        c.translate(cx, cy + float);
        if (!flash) {
          c.globalAlpha = 0.06 + Math.sin(frameCount * 0.04) * 0.03;
          c.fillStyle = COLOR_SLIME_GHOST;
          c.beginPath();
          c.ellipse(0, 0, 22 * sc, 20 * sc, 0, 0, Math.PI * 2);
          c.fill();
          for (let w: number = 0; w < 5; w++) {
            const wAngle: number = (w / 5) * Math.PI * 2 + frameCount * 0.02;
            const wDist: number = (10 + Math.sin(frameCount * 0.03 + w * 2) * 5) * sc;
            const wx: number = Math.cos(wAngle) * wDist;
            const wy: number = Math.sin(wAngle) * wDist * 0.5 + 5 * sc;
            c.fillStyle = COLOR_SLIME_GHOST_LIGHT;
            c.globalAlpha = 0.15 + Math.sin(frameCount * 0.05 + w) * 0.1;
            c.beginPath();
            c.ellipse(wx, wy, 2.5 * sc, 1.5 * sc, wAngle, 0, Math.PI * 2);
            c.fill();
          }
          for (let trail: number = 0; trail < 3; trail++) {
            const ty: number = 8 * sc + trail * 4 * sc;
            const tx: number = Math.sin(frameCount * 0.04 + trail * 2) * 3 * sc;
            c.fillStyle = COLOR_SLIME_GHOST;
            c.globalAlpha = 0.1 * (1 - trail * 0.3);
            c.beginPath();
            c.ellipse(tx, ty, (4 - trail) * sc, (2 - trail * 0.5) * sc, 0, 0, Math.PI * 2);
            c.fill();
          }
        }
        const bodyAlpha: number = flash ? 0.9 : (0.45 + phase);
        c.globalAlpha = bodyAlpha;
        if (flash) {
          c.fillStyle = '#ffffff';
        } else {
          c.strokeStyle = '#334155';
          c.lineWidth = 1.5 * sc;
          c.globalAlpha = bodyAlpha * 0.6;
          c.beginPath();
          c.moveTo(-12 * sc, 4 * sc);
          c.quadraticCurveTo(-13 * sc, -10 * sc, 0, -12 * sc);
          c.quadraticCurveTo(13 * sc, -10 * sc, 12 * sc, 4 * sc);
          const wv1: number = Math.sin(frameCount * 0.06) * 1.5 * sc;
          const wv2: number = Math.sin(frameCount * 0.06 + 1) * 1.5 * sc;
          const wv3: number = Math.sin(frameCount * 0.06 + 2) * 1.5 * sc;
          c.quadraticCurveTo(10 * sc, 10 * sc + wv1, 6 * sc, 8 * sc);
          c.quadraticCurveTo(3 * sc, 12 * sc + wv2, 0, 9 * sc);
          c.quadraticCurveTo(-3 * sc, 12 * sc + wv3, -6 * sc, 8 * sc);
          c.quadraticCurveTo(-10 * sc, 10 * sc + wv1, -12 * sc, 4 * sc);
          c.closePath();
          c.stroke();
          c.globalAlpha = bodyAlpha;
          c.fillStyle = COLOR_SLIME_GHOST;
          c.beginPath();
          c.moveTo(-12 * sc, 4 * sc);
          c.quadraticCurveTo(-13 * sc, -10 * sc, 0, -12 * sc);
          c.quadraticCurveTo(13 * sc, -10 * sc, 12 * sc, 4 * sc);
          c.quadraticCurveTo(10 * sc, 10 * sc + wv1, 6 * sc, 8 * sc);
          c.quadraticCurveTo(3 * sc, 12 * sc + wv2, 0, 9 * sc);
          c.quadraticCurveTo(-3 * sc, 12 * sc + wv3, -6 * sc, 8 * sc);
          c.quadraticCurveTo(-10 * sc, 10 * sc + wv1, -12 * sc, 4 * sc);
          c.closePath();
          c.fill();
          c.fillStyle = COLOR_SLIME_GHOST_LIGHT;
          c.globalAlpha = 0.25;
          c.beginPath();
          c.ellipse(0, -2 * sc, 7 * sc, 6 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.1;
          c.beginPath();
          c.ellipse(-3 * sc, -6 * sc, 4 * sc, 2.5 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = flash ? 0.9 : 0.85;
        c.fillStyle = flash ? '#ffffff' : '#e2e8f0';
        c.beginPath();
        c.ellipse(-4 * sc, -3 * sc, 2.8 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -3 * sc, 2.8 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.9;
          c.beginPath();
          c.ellipse(-4 * sc, -2.5 * sc, 1.5 * sc, 2 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.ellipse(4 * sc, -2.5 * sc, 1.5 * sc, 2 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#94a3b8';
          c.globalAlpha = 0.6;
          c.beginPath();
          c.arc(-4.5 * sc, -3.5 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.5 * sc, -3.5 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.6;
          c.beginPath();
          c.ellipse(0, 3 * sc, 3 * sc, (2.5 + Math.sin(frameCount * 0.04)) * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.restore();
      } else if (ai.enemyType === EnemyType.HUMANOID_BEAST) {
        const bounce: number = Math.sin(bp) * 2 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        drawHumanoidBeast(c, flash, frameCount, sc);
        c.restore();
      }

      c.globalAlpha = 1.0;
      if (ai.isCharging && ai.enemyType !== EnemyType.RED_SLIME) {
        const halfSize: number = ai.size / 2;
        c.globalAlpha = 0.4;
        c.fillStyle = COLOR_SLIME_RED;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + 6, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      if (health.current < health.max) {
        const barW: number = ai.size;
        const barH: number = 3;
        const barY: number = screenY - ai.size / 2 - 6;
        c.fillStyle = '#374151';
        c.fillRect(screenX - barW / 2, barY, barW, barH);
        c.fillStyle = '#ef4444';
        c.fillRect(screenX - barW / 2, barY, barW * (health.current / health.max), barH);
      }

      // Level indicator above health bar
      const levelY: number = screenY - ai.size / 2 - 12;
      const level: number = ai.level;
      const levelColor: string = level > playerLevel ? '#ef4444' : (level < playerLevel ? '#22c55e' : '#ffffff');
      c.globalAlpha = 1.0;
      c.font = '8px monospace';
      c.fillStyle = levelColor;
      c.textAlign = 'center';
      c.fillText('Lv' + level.toString(), screenX, levelY);
    }
  }

  private renderEnemiesSprite(world: World, c: CanvasRenderingContext2D, offX: number, offY: number,
      screenW: number, screenH: number, frameCount: number, sm: SpriteManager): void {
    const enemies: Entity[] = world.queryWithTag('enemy');
    const player: Entity | null = world.findEntityByTag("player");
    const playerLevelComp: LevelComponent | null = player !== null ? player.getComponent<LevelComponent>("level") : null;
    const playerLevel: number = playerLevelComp !== null ? playerLevelComp.level : 1;
    for (let i: number = 0; i < enemies.length; i++) {
      const entity: Entity = enemies[i];
      if (!entity.active) continue;

      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      const health: HealthComponent | null = entity.getComponent<HealthComponent>('Health');
      const ai: EnemyAIComponent | null = entity.getComponent<EnemyAIComponent>('enemyAI');
      if (pos === null || health === null || ai === null) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;
      if (screenX < -50 || screenX > screenW + 50 || screenY < -50 || screenY > screenH + 50) continue;

      const sc: number = ai.size / 48;
      const flash: boolean = ai.hitFlash > 0;

      { // HUMANOID_BEAST now consumes its atlas like every other enemy

        const atlas: SpriteAtlas = sm.getEnemyAtlas(ai.enemyType);
        const bounceFrame: number = Math.floor(((ai.bouncePhase % (Math.PI * 2)) / (Math.PI * 2)) * 8) % 8;

        let frameIndex: number;
        if (ai.enemyType === EnemyType.PURPLE_SLIME) {
          frameIndex = (ai.isEngulfing ? 8 : 0) + bounceFrame;
        } else if (ai.enemyType === EnemyType.RED_SLIME) {
          frameIndex = (ai.isCharging ? 8 : 0) + bounceFrame;
        } else {
          frameIndex = (flash ? 8 : 0) + bounceFrame;
        }

        const frame: FrameCoord = atlas.getFrame(frameIndex);
        const destW: number = atlas.cellW * sc;
        const destH: number = atlas.cellH * sc;
        const destX: number = screenX - destW / 2;
        const destY: number = screenY - destH / 2;

        c.drawImage(atlas.imageBitmap, frame.sx, frame.sy, atlas.cellW, atlas.cellH,
                    destX, destY, destW, destH);

        // Flash overlay for PURPLE/RED (their flash frames aren't in atlas)
        if (flash && (ai.enemyType === EnemyType.PURPLE_SLIME || ai.enemyType === EnemyType.RED_SLIME)) {
          c.globalAlpha = 0.6;
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.ellipse(screenX, screenY, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
        }
      }

      // Charging indicator (stays real-time)
      c.globalAlpha = 1.0;
      if (ai.isCharging && ai.enemyType !== EnemyType.RED_SLIME) {
        const halfSize: number = ai.size / 2;
        c.globalAlpha = 0.4;
        c.fillStyle = COLOR_SLIME_RED;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + 6, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      // Health bar (stays real-time)
      if (health.current < health.max) {
        const barW: number = ai.size;
        const barH: number = 3;
        const barY: number = screenY - ai.size / 2 - 6;
        c.fillStyle = '#374151';
        c.fillRect(screenX - barW / 2, barY, barW, barH);
        c.fillStyle = '#ef4444';
        c.fillRect(screenX - barW / 2, barY, barW * (health.current / health.max), barH);
      }

      // Level indicator above health bar
      const levelY: number = screenY - ai.size / 2 - 12;
      const level: number = ai.level;
      const levelColor: string = level > playerLevel ? '#ef4444' : (level < playerLevel ? '#22c55e' : '#ffffff');
      c.globalAlpha = 1.0;
      c.font = '8px monospace';
      c.fillStyle = levelColor;
      c.textAlign = 'center';
      c.fillText('Lv' + level.toString(), screenX, levelY);
    }
  }

  private renderXpOrbs(world: World, c: CanvasRenderingContext2D, offX: number, offY: number, screenW: number, screenH: number, frameCount: number): void {
    const orbs: Entity[] = world.queryWithTag('xpOrb');
    for (let i: number = 0; i < orbs.length; i++) {
      const entity: Entity = orbs[i];
      if (!entity.active) continue;

      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      const pickup: XpPickupComponent | null = entity.getComponent<XpPickupComponent>('xpPickup');
      if (pos === null || pickup === null) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;

      if (screenX < -20 || screenX > screenW + 20 || screenY < -20 || screenY > screenH + 20) {
        continue;
      }

      const bob: number = Math.sin(pickup.magnetPhase) * 2;

      c.globalAlpha = 0.2;
      c.fillStyle = COLOR_XP_GLOW;
      c.beginPath();
      c.arc(screenX, screenY + bob, XP_ORB_SIZE + 4, 0, Math.PI * 2);
      c.fill();

      c.globalAlpha = 0.9;
      c.fillStyle = COLOR_XP_ORB;
      c.beginPath();
      c.arc(screenX, screenY + bob, XP_ORB_SIZE, 0, Math.PI * 2);
      c.fill();

      c.globalAlpha = 1.0;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(screenX - 1, screenY - 1 + bob, 2, 0, Math.PI * 2);
      c.fill();
    }
    c.globalAlpha = 1.0;
  }

  collectCommands(world: World, buf: DrawCmdBuffer, cameraX: number, cameraY: number,
      screenW: number, screenH: number, settings: GameSettings, frameCount: number,
      spriteManager: SpriteManager | null = null): void {
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    if (spriteManager === null || !spriteManager.isReady()) {
      this.collectEnemiesProcedural(world, buf, offX, offY, screenW, screenH, frameCount);
    } else {
      this.collectEnemiesSprite(world, buf, offX, offY, screenW, screenH, frameCount, spriteManager);
    }
    this.collectXpOrbsCommands(world, buf, offX, offY, screenW, screenH, frameCount);
  }

  private collectEnemiesProcedural(world: World, buf: DrawCmdBuffer, offX: number, offY: number,
      screenW: number, screenH: number, frameCount: number): void {
    const enemies: Entity[] = world.queryWithTag('enemy');
    const player: Entity | null = world.findEntityByTag("player");
    const playerLevelComp: LevelComponent | null = player !== null ? player.getComponent<LevelComponent>("level") : null;
    const playerLevel: number = playerLevelComp !== null ? playerLevelComp.level : 1;
    for (let i: number = 0; i < enemies.length; i++) {
      const entity: Entity = enemies[i];
      if (!entity.active) continue;
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      const health: HealthComponent | null = entity.getComponent<HealthComponent>('Health');
      const ai: EnemyAIComponent | null = entity.getComponent<EnemyAIComponent>('enemyAI');
      if (pos === null || health === null || ai === null) continue;
      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;
      if (screenX < -50 || screenX > screenW + 50 || screenY < -50 || screenY > screenH + 50) continue;
      const sc: number = ai.size / 48;
      const bp: number = ai.bouncePhase;
      const flash: boolean = ai.hitFlash > 0;

      if (ai.enemyType === EnemyType.GRAY_SLIME) {
        const bounce: number = Math.sin(bp) * 3 * sc;
        const squash: number = 1 + Math.sin(bp) * 0.12;
        const cy: number = screenY + bounce;
        buf.pushCircle(screenX, cy + 14 * sc, 13 * sc * squash, 0, 0, 0, 0.2, 0, 0);
        if (flash) {
          buf.pushCircle(screenX, cy, 15 * sc, 1, 1, 1, 0.9, 0, 0);
        } else {
          const bodyC: number[] = hexToRgb(COLOR_SLIME_GRAY);
          const outC: number[] = hexToRgb('#1a1a2e');
          const lightC: number[] = hexToRgb(COLOR_SLIME_GRAY_LIGHT);
          buf.pushCircle(screenX, cy, 15 * sc, outC[0], outC[1], outC[2], 0.8, 0, 0);
          buf.pushCircle(screenX, cy, 14 * sc, bodyC[0], bodyC[1], bodyC[2], 0.9, 0, 0);
          buf.pushCircle(screenX - 3 * sc, cy - 4 * sc, 6 * sc, lightC[0], lightC[1], lightC[2], 0.9, 0, 0);
          buf.pushCircle(screenX - 5 * sc, cy - 6 * sc, 2.5 * sc, 1, 1, 1, 0.45, 0, 0);
          buf.pushCircle(screenX + 4 * sc, cy + 3 * sc, 2 * sc, 1, 1, 1, 0.2, 0, 0);
        }
        buf.pushCircle(screenX - 4 * sc, cy - 1 * sc, 3 * sc, 1, 1, 1, 1.0, 0, 0);
        buf.pushCircle(screenX + 4 * sc, cy - 1 * sc, 3 * sc, 1, 1, 1, 1.0, 0, 0);
        if (!flash) {
          const pupilC: number[] = hexToRgb(COLOR_SLIME_PUPIL);
          buf.pushCircle(screenX - 3.5 * sc, cy - 0.5 * sc, 1.5 * sc, pupilC[0], pupilC[1], pupilC[2], 1, 0, 0);
          buf.pushCircle(screenX + 4.5 * sc, cy - 0.5 * sc, 1.5 * sc, pupilC[0], pupilC[1], pupilC[2], 1, 0, 0);
          buf.pushCircle(screenX - 4 * sc, cy - 1.2 * sc, 0.6 * sc, 1, 1, 1, 1, 0, 0);
          buf.pushCircle(screenX + 4 * sc, cy - 1.2 * sc, 0.6 * sc, 1, 1, 1, 1, 0, 0);
          buf.pushLine(screenX - 2.5 * sc, cy + 3.5 * sc, screenX + 2.5 * sc, cy + 3.5 * sc, 1 * sc, pupilC[0], pupilC[1], pupilC[2], 1, 0);
        }
      } else if (ai.enemyType === EnemyType.PURPLE_SLIME) {
        const bounce: number = Math.sin(bp * 1.3) * 1.5 * sc;
        const cy: number = screenY + bounce;
        const bodyC: number[] = hexToRgb(COLOR_SLIME_PURPLE);
        const lightC: number[] = hexToRgb(COLOR_SLIME_PURPLE_LIGHT);
        if (!flash) {
          const glowA: number = 0.12 + Math.sin(frameCount * 0.05) * 0.05;
          buf.pushCircle(screenX, cy, 20 * sc, bodyC[0], bodyC[1], bodyC[2], glowA, 0, 0);
        }
        buf.pushCircle(screenX, cy + 14 * sc, 13 * sc, 0, 0, 0, 0.25, 0, 0);
        for (let t: number = 0; t < 4; t++) {
          const angle: number = (t / 4) * Math.PI * 2 + frameCount * 0.03;
          const tx: number = screenX + Math.cos(angle) * 16 * sc;
          const ty: number = cy + Math.sin(angle) * 10 * sc + 4 * sc;
          if (flash) {
            buf.pushCircle(tx, ty, 3 * sc, 1, 1, 1, 0.9, 0, 0);
          } else {
            buf.pushCircle(tx, ty, 3 * sc, bodyC[0], bodyC[1], bodyC[2], 0.9, 0, 0);
          }
        }
        if (flash) {
          buf.pushCircle(screenX, cy, 16 * sc, 1, 1, 1, 0.9, 0, 0);
        } else {
          const outC: number[] = hexToRgb('#1a0533');
          buf.pushCircle(screenX, cy, 16 * sc, outC[0], outC[1], outC[2], 0.8, 0, 0);
          buf.pushCircle(screenX, cy, 15 * sc, bodyC[0], bodyC[1], bodyC[2], 0.9, 0, 0);
          buf.pushCircle(screenX - 3 * sc, cy - 4 * sc, 7 * sc, lightC[0], lightC[1], lightC[2], 0.9, 0, 0);
          const dripPhase: number = (frameCount * 0.03) % 1;
          for (let d: number = 0; d < 3; d++) {
            const dx: number = screenX + (-6 + d * 6) * sc;
            const dy: number = cy + 10 * sc + dripPhase * 8 * sc;
            const dAlpha: number = 0.6 * (1 - dripPhase);
            buf.pushCircle(dx, dy, 1.5 * sc, bodyC[0], bodyC[1], bodyC[2], dAlpha, 0, 0);
          }
        }
        buf.pushCircle(screenX - 4 * sc, cy - 2 * sc, 3.2 * sc, 1, 1, 1, 1.0, 0, 0);
        buf.pushCircle(screenX + 4 * sc, cy - 2 * sc, 3.2 * sc, 1, 1, 1, 1.0, 0, 0);
        if (!flash) {
          buf.pushCircle(screenX - 3.5 * sc, cy - 1.5 * sc, 1.8 * sc, 1, 0, 0.251, 1, 0, 0);
          buf.pushCircle(screenX + 4.5 * sc, cy - 1.5 * sc, 1.8 * sc, 1, 0, 0.251, 1, 0, 0);
          buf.pushCircle(screenX - 3.5 * sc, cy - 1.5 * sc, 0.9 * sc, 0.102, 0.102, 0.18, 1, 0, 0);
          buf.pushCircle(screenX + 4.5 * sc, cy - 1.5 * sc, 0.9 * sc, 0.102, 0.102, 0.18, 1, 0, 0);
          buf.pushCircle(screenX - 4.2 * sc, cy - 2.2 * sc, 0.5 * sc, 1, 1, 1, 1, 0, 0);
          buf.pushCircle(screenX + 3.8 * sc, cy - 2.2 * sc, 0.5 * sc, 1, 1, 1, 1, 0, 0);
          const brC: number[] = hexToRgb('#4c1d95');
          buf.pushLine(screenX - 8 * sc, cy - 6 * sc, screenX - 2 * sc, cy - 4.5 * sc, 1.5 * sc, brC[0], brC[1], brC[2], 1, 0);
          buf.pushLine(screenX + 8 * sc, cy - 6 * sc, screenX + 2 * sc, cy - 4.5 * sc, 1.5 * sc, brC[0], brC[1], brC[2], 1, 0);
          if (ai.isEngulfing) {
            buf.pushCircle(screenX, cy + 5 * sc, 6 * sc, 0.176, 0.063, 0.376, 1, 0, 0);
            buf.pushCircle(screenX, cy + 6 * sc, 3 * sc, 0.102, 0.02, 0.2, 1, 0, 0);
          } else {
            buf.pushCircle(screenX, cy + 5 * sc, 5 * sc, 0.176, 0.063, 0.376, 1, 0, 0);
          }
        }
      } else if (ai.enemyType === EnemyType.RED_SLIME) {
        const charge: number = ai.isCharging ? Math.abs(Math.sin(frameCount * 0.08)) : Math.abs(Math.sin(frameCount * 0.04)) * 0.3;
        const bodyC: number[] = hexToRgb(COLOR_SLIME_RED);
        const lightC: number[] = hexToRgb(COLOR_SLIME_RED_LIGHT);
        if (!flash) {
          buf.pushCircle(screenX, screenY, (18 + charge * 2) * sc, 1, 0.267, 0.267, 0.1 + charge * 0.1, 0, 0);
        }
        buf.pushCircle(screenX, screenY + 13 * sc, 12 * sc, 0, 0, 0, 0.25, 0, 0);
        if (!flash) {
          for (let fi: number = 0; fi < 7; fi++) {
            const angle: number = -Math.PI * 0.8 + (fi / 6) * Math.PI * 0.6;
            const flicker: number = Math.sin(frameCount * 0.12 + fi * 1.5) * 3;
            const len: number = (6 + flicker + charge * 3) * sc;
            const sx2: number = screenX + Math.cos(angle) * 12 * sc;
            const sy2: number = screenY + Math.sin(angle) * 10 * sc;
            const ex: number = sx2 + Math.cos(angle) * len;
            const ey: number = sy2 + Math.sin(angle) * len;
            const fC: number[] = hexToRgb(fi % 2 === 0 ? '#ff6600' : '#ffaa00');
            buf.pushLine(sx2, sy2, ex, ey, 2 * sc, fC[0], fC[1], fC[2], 0.7, 0);
          }
          const outC: number[] = hexToRgb('#7f1d1d');
          buf.pushCircle(screenX + 1 * sc, screenY, 15 * sc, outC[0], outC[1], outC[2], 0.8, 0, 0);
        }
        if (flash) {
          buf.pushCircle(screenX + 1 * sc, screenY, 14 * sc, 1, 1, 1, 1, 0, 0);
        } else {
          buf.pushCircle(screenX + 1 * sc, screenY, 14 * sc, bodyC[0], bodyC[1], bodyC[2], 1, 0, 0);
          buf.pushCircle(screenX - 2 * sc, screenY - 3.5 * sc, 6 * sc, lightC[0], lightC[1], lightC[2], 1, 0, 0);
        }
        buf.pushCircle(screenX - 3.5 * sc, screenY - 1.5 * sc, 2.8 * sc, 1, 1, 1, 1.0, 0, 0);
        buf.pushCircle(screenX + 4 * sc, screenY - 1.5 * sc, 2.8 * sc, 1, 1, 1, 1.0, 0, 0);
        if (!flash) {
          buf.pushCircle(screenX - 3 * sc, screenY - 1 * sc, 1.5 * sc, 1, 0.8, 0, 1, 0, 0);
          buf.pushCircle(screenX + 4.5 * sc, screenY - 1 * sc, 1.5 * sc, 1, 0.8, 0, 1, 0, 0);
          buf.pushCircle(screenX - 3 * sc, screenY - 1 * sc, 0.7 * sc, 0.102, 0.102, 0.18, 1, 0, 0);
          buf.pushCircle(screenX + 4.5 * sc, screenY - 1 * sc, 0.7 * sc, 0.102, 0.102, 0.18, 1, 0, 0);
          buf.pushCircle(screenX - 3.5 * sc, screenY - 1.8 * sc, 0.5 * sc, 1, 1, 1, 1, 0, 0);
          buf.pushCircle(screenX + 4 * sc, screenY - 1.8 * sc, 0.5 * sc, 1, 1, 1, 1, 0, 0);
          const brC: number[] = hexToRgb('#7f1d1d');
          buf.pushLine(screenX - 7 * sc, screenY - 5 * sc, screenX - 2 * sc, screenY - 3.5 * sc, 1.5 * sc, brC[0], brC[1], brC[2], 1, 0);
          buf.pushLine(screenX + 7 * sc, screenY - 5 * sc, screenX + 2 * sc, screenY - 3.5 * sc, 1.5 * sc, brC[0], brC[1], brC[2], 1, 0);
          buf.pushLine(screenX - 4 * sc, screenY + 4 * sc, screenX - 2 * sc, screenY + 2.5 * sc, 1.2 * sc, brC[0], brC[1], brC[2], 1, 0);
          buf.pushLine(screenX - 2 * sc, screenY + 2.5 * sc, screenX, screenY + 4 * sc, 1.2 * sc, brC[0], brC[1], brC[2], 1, 0);
          buf.pushLine(screenX, screenY + 4 * sc, screenX + 2 * sc, screenY + 2.5 * sc, 1.2 * sc, brC[0], brC[1], brC[2], 1, 0);
          buf.pushLine(screenX + 2 * sc, screenY + 2.5 * sc, screenX + 4 * sc, screenY + 4 * sc, 1.2 * sc, brC[0], brC[1], brC[2], 1, 0);
        }
      } else if (ai.enemyType === EnemyType.BLUE_SLIME) {
        const bounce: number = Math.sin(bp * 0.8) * 1.5 * sc;
        const cy: number = screenY + bounce;
        const bodyC: number[] = hexToRgb(COLOR_SLIME_BLUE);
        const lightC: number[] = hexToRgb(COLOR_SLIME_BLUE_LIGHT);
        if (!flash) {
          for (let d: number = 0; d < 6; d++) {
            const angle: number = (d / 6) * Math.PI * 2 + frameCount * 0.02;
            const dist: number = (16 + Math.sin(frameCount * 0.03 + d * 2) * 3) * sc;
            const dx: number = screenX + Math.cos(angle) * dist;
            const dy: number = cy + Math.sin(angle) * dist * 0.7 - 2.5 * sc;
            const dAlpha: number = 0.4 + Math.sin(frameCount * 0.04 + d) * 0.2;
            buf.pushCircle(dx, dy, 2 * sc, lightC[0], lightC[1], lightC[2], dAlpha, 0, 0);
          }
        }
        buf.pushCircle(screenX, cy + 13 * sc, 12 * sc, 0, 0, 0, 0.2, 0, 0);
        if (flash) {
          buf.pushCircle(screenX, cy, 15 * sc, 1, 1, 1, 0.9, 0, 0);
        } else {
          const outC: number[] = hexToRgb('#0c2d5e');
          buf.pushCircle(screenX, cy, 15 * sc, outC[0], outC[1], outC[2], 0.8, 0, 0);
          buf.pushCircle(screenX, cy, 14 * sc, bodyC[0], bodyC[1], bodyC[2], 0.7, 0, 0);
          const rippleOff: number = Math.sin(frameCount * 0.04) * 1.5 * sc;
          buf.pushCircle(screenX, cy + rippleOff, 10 * sc, lightC[0], lightC[1], lightC[2], 0.3, 0, 0);
          buf.pushCircle(screenX - 4 * sc, cy - 5 * sc, 4 * sc, 1, 1, 1, 0.15, 0, 0);
          for (let w: number = 0; w < 3; w++) {
            const wy: number = cy + (-3 + w * 4) * sc;
            const woff: number = Math.sin(frameCount * 0.05 + w) * 2 * sc;
            buf.pushLine(screenX - 8 * sc, wy + woff, screenX + 8 * sc, wy - woff, 0.8 * sc, 0.576, 0.773, 0.988, 0.4, 0);
          }
        }
        buf.pushCircle(screenX - 3.5 * sc, cy - 1 * sc, 3 * sc, 1, 1, 1, 1.0, 0, 0);
        buf.pushCircle(screenX + 3.5 * sc, cy - 1 * sc, 3 * sc, 1, 1, 1, 1.0, 0, 0);
        if (!flash) {
          buf.pushCircle(screenX - 3 * sc, cy - 0.5 * sc, 1.5 * sc, 0.118, 0.251, 0.686, 1, 0, 0);
          buf.pushCircle(screenX + 4 * sc, cy - 0.5 * sc, 1.5 * sc, 0.118, 0.251, 0.686, 1, 0, 0);
          buf.pushCircle(screenX - 3.5 * sc, cy - 1.2 * sc, 0.5 * sc, 1, 1, 1, 1, 0, 0);
          buf.pushCircle(screenX + 3.5 * sc, cy - 1.2 * sc, 0.5 * sc, 1, 1, 1, 1, 0, 0);
          const mC: number[] = hexToRgb('#1e3a5f');
          buf.pushLine(screenX - 2.5 * sc, cy + 3 * sc, screenX + 2.5 * sc, cy + 3 * sc, 1 * sc, mC[0], mC[1], mC[2], 1, 0);
        }
      } else if (ai.enemyType === EnemyType.YELLOW_SLIME) {
        const bounce: number = Math.abs(Math.sin(bp * 1.1)) * 4 * sc;
        const cy: number = screenY - bounce;
        const bodyC: number[] = hexToRgb(COLOR_SLIME_YELLOW);
        const lightC: number[] = hexToRgb(COLOR_SLIME_YELLOW_LIGHT);
        if (!flash) {
          buf.pushCircle(screenX, cy, 20 * sc, lightC[0], lightC[1], lightC[2], 0.08 + Math.sin(frameCount * 0.04) * 0.03, 0, 0);
          for (let sp: number = 0; sp < 8; sp++) {
            const angle: number = (sp / 8) * Math.PI * 2 + frameCount * 0.04;
            const dist: number = (14 + Math.sin(frameCount * 0.06 + sp * 3) * 4) * sc;
            const spx: number = screenX + Math.cos(angle) * dist;
            const spy: number = cy + Math.sin(angle) * dist * 0.6;
            const sparkSize: number = (1 + Math.sin(frameCount * 0.1 + sp * 2) * 0.6) * sc;
            const sC: number[] = hexToRgb(sp % 2 === 0 ? COLOR_SLIME_YELLOW_LIGHT : '#ffffff');
            const sA: number = 0.6 + Math.sin(frameCount * 0.08 + sp) * 0.3;
            buf.pushRect(spx - sparkSize, spy - sparkSize, sparkSize * 2, sparkSize * 2, sC[0], sC[1], sC[2], sA, 0, 0);
          }
        }
        buf.pushCircle(screenX, cy + (13 + bounce / sc) * sc, 11 * sc, 0, 0, 0, 0.15, 0, 0);
        if (flash) {
          buf.pushCircle(screenX, cy, 13 * sc, 1, 1, 1, 0.9, 0, 0);
        } else {
          const outC: number[] = hexToRgb('#78350f');
          buf.pushCircle(screenX, cy, 13 * sc, outC[0], outC[1], outC[2], 0.8, 0, 0);
          buf.pushCircle(screenX, cy, 12 * sc, bodyC[0], bodyC[1], bodyC[2], 0.9, 0, 0);
          buf.pushCircle(screenX - 2.5 * sc, cy - 3.5 * sc, 5.5 * sc, lightC[0], lightC[1], lightC[2], 0.9, 0, 0);
          buf.pushCircle(screenX - 4 * sc, cy - 5.5 * sc, 2.5 * sc, 1, 1, 1, 0.5, 0, 0);
        }
        buf.pushCircle(screenX - 3 * sc, cy - 0.5 * sc, 2.8 * sc, 1, 1, 1, 1.0, 0, 0);
        buf.pushCircle(screenX + 3 * sc, cy - 0.5 * sc, 2.8 * sc, 1, 1, 1, 1.0, 0, 0);
        if (!flash) {
          buf.pushCircle(screenX - 2.5 * sc, cy, 1.3 * sc, 0.573, 0.251, 0.055, 1, 0, 0);
          buf.pushCircle(screenX + 3.5 * sc, cy, 1.3 * sc, 0.573, 0.251, 0.055, 1, 0, 0);
          buf.pushCircle(screenX - 3 * sc, cy - 0.8 * sc, 0.5 * sc, 1, 1, 1, 1, 0, 0);
          buf.pushCircle(screenX + 3 * sc, cy - 0.8 * sc, 0.5 * sc, 1, 1, 1, 1, 0, 0);
          const mC: number[] = hexToRgb('#92400e');
          buf.pushLine(screenX - 3.5 * sc, cy + 3 * sc, screenX + 3.5 * sc, cy + 3 * sc, 1 * sc, mC[0], mC[1], mC[2], 1, 0);
          buf.pushCircle(screenX - 6 * sc, cy + 2 * sc, 2 * sc, 0.961, 0.62, 0.043, 0.3, 0, 0);
          buf.pushCircle(screenX + 6 * sc, cy + 2 * sc, 2 * sc, 0.961, 0.62, 0.043, 0.3, 0, 0);
        }
      } else if (ai.enemyType === EnemyType.GHOST_SLIME) {
        const float: number = Math.sin(bp * 0.5) * 4 * sc;
        const phase: number = Math.sin(frameCount * 0.05) * 0.15;
        const cy: number = screenY + float;
        const bodyC: number[] = hexToRgb(COLOR_SLIME_GHOST);
        const lightC: number[] = hexToRgb(COLOR_SLIME_GHOST_LIGHT);
        if (!flash) {
          buf.pushCircle(screenX, cy, 22 * sc, bodyC[0], bodyC[1], bodyC[2], 0.06, 0, 0);
          for (let w: number = 0; w < 5; w++) {
            const wAngle: number = (w / 5) * Math.PI * 2 + frameCount * 0.02;
            const wDist: number = (10 + Math.sin(frameCount * 0.03 + w * 2) * 5) * sc;
            const wx: number = screenX + Math.cos(wAngle) * wDist;
            const wy: number = cy + Math.sin(wAngle) * wDist * 0.5 + 5 * sc;
            const wA: number = 0.15 + Math.sin(frameCount * 0.05 + w) * 0.1;
            buf.pushCircle(wx, wy, 2.5 * sc, lightC[0], lightC[1], lightC[2], wA, 0, 0);
          }
          for (let trail: number = 0; trail < 3; trail++) {
            const ty: number = cy + 8 * sc + trail * 4 * sc;
            const tx: number = screenX + Math.sin(frameCount * 0.04 + trail * 2) * 3 * sc;
            const tA: number = 0.1 * (1 - trail * 0.3);
            buf.pushCircle(tx, ty, (4 - trail) * sc, bodyC[0], bodyC[1], bodyC[2], tA, 0, 0);
          }
        }
        const bodyAlpha: number = flash ? 0.9 : (0.45 + phase);
        if (flash) {
          buf.pushCircle(screenX, cy, 12 * sc, 1, 1, 1, bodyAlpha, 0, 0);
        } else {
          buf.pushCircle(screenX, cy, 12 * sc, bodyC[0], bodyC[1], bodyC[2], bodyAlpha, 0, 0);
          buf.pushCircle(screenX, cy - 2 * sc, 7 * sc, lightC[0], lightC[1], lightC[2], 0.25, 0, 0);
          buf.pushCircle(screenX - 3 * sc, cy - 6 * sc, 4 * sc, 1, 1, 1, 0.1, 0, 0);
        }
        const eyeC: number[] = hexToRgb(flash ? '#ffffff' : '#e2e8f0');
        buf.pushCircle(screenX - 4 * sc, cy - 3 * sc, 2.8 * sc, eyeC[0], eyeC[1], eyeC[2], flash ? 0.9 : 0.85, 0, 0);
        buf.pushCircle(screenX + 4 * sc, cy - 3 * sc, 2.8 * sc, eyeC[0], eyeC[1], eyeC[2], flash ? 0.9 : 0.85, 0, 0);
        if (!flash) {
          buf.pushCircle(screenX - 4 * sc, cy - 2.5 * sc, 1.5 * sc, 0.118, 0.161, 0.231, 0.9, 0, 0);
          buf.pushCircle(screenX + 4 * sc, cy - 2.5 * sc, 1.5 * sc, 0.118, 0.161, 0.231, 0.9, 0, 0);
          buf.pushCircle(screenX - 4.5 * sc, cy - 3.5 * sc, 0.6 * sc, 0.58, 0.639, 0.718, 0.6, 0, 0);
          buf.pushCircle(screenX + 3.5 * sc, cy - 3.5 * sc, 0.6 * sc, 0.58, 0.639, 0.718, 0.6, 0, 0);
          buf.pushCircle(screenX, cy + 3 * sc, 3 * sc, 0.118, 0.161, 0.231, 0.6, 0, 0);
        }
      } else if (ai.enemyType === EnemyType.HUMANOID_BEAST) {
        const bounce: number = Math.sin(bp) * 2 * sc;
        const cy: number = screenY + bounce;
        if (flash) {
          buf.pushCircle(screenX, cy, 15 * sc, 1, 1, 1, 0.9, 0, 0);
        } else {
          const bodyC: number[] = hexToRgb('#5a3a2a');
          buf.pushCircle(screenX, cy, 14 * sc, bodyC[0], bodyC[1], bodyC[2], 0.9, 0, 0);
          buf.pushCircle(screenX, cy - 3 * sc, 6 * sc, 0.4, 0.25, 0.16, 0.9, 0, 0);
          buf.pushCircle(screenX - 4 * sc, cy - 2 * sc, 2.5 * sc, 1, 0.3, 0.3, 0.9, 0, 0);
          buf.pushCircle(screenX + 4 * sc, cy - 2 * sc, 2.5 * sc, 1, 0.3, 0.3, 0.9, 0, 0);
          buf.pushCircle(screenX, cy + 6 * sc, 4 * sc, 0.3, 0.15, 0.1, 0.8, 0, 0);
        }
      }

      if (ai.isCharging && ai.enemyType !== EnemyType.RED_SLIME) {
        const halfSize: number = ai.size / 2;
        const rC: number[] = hexToRgb(COLOR_SLIME_RED);
        buf.pushCircle(screenX, screenY, halfSize + 6, rC[0], rC[1], rC[2], 0.4, 0, 0);
      }

      if (health.current < health.max) {
        const barW: number = ai.size;
        const barH: number = 3;
        const barY: number = screenY - ai.size / 2 - 6;
        buf.pushRect(screenX - barW / 2, barY, barW, barH, 0.216, 0.255, 0.318, 1, 0, 0);
        buf.pushRect(screenX - barW / 2, barY, barW * (health.current / health.max), barH, 0.937, 0.267, 0.267, 1, 0, 0);
      }

      const levelY: number = screenY - ai.size / 2 - 12;
      const level: number = ai.level;
      let lr: number = 1; let lg: number = 1; let lb: number = 1;
      if (level > playerLevel) { lr = 0.937; lg = 0.267; lb = 0.267; }
      else if (level < playerLevel) { lr = 0.133; lg = 0.773; lb = 0.369; }
      buf.pushRect(screenX - 6, levelY - 4, 12, 5, lr, lg, lb, 1, 0, 0);
    }
  }

  private collectEnemiesSprite(world: World, buf: DrawCmdBuffer, offX: number, offY: number,
      screenW: number, screenH: number, frameCount: number, sm: SpriteManager): void {
    const enemies: Entity[] = world.queryWithTag('enemy');
    const player: Entity | null = world.findEntityByTag("player");
    const playerLevelComp: LevelComponent | null = player !== null ? player.getComponent<LevelComponent>("level") : null;
    const playerLevel: number = playerLevelComp !== null ? playerLevelComp.level : 1;
    for (let i: number = 0; i < enemies.length; i++) {
      const entity: Entity = enemies[i];
      if (!entity.active) continue;
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      const health: HealthComponent | null = entity.getComponent<HealthComponent>('Health');
      const ai: EnemyAIComponent | null = entity.getComponent<EnemyAIComponent>('enemyAI');
      if (pos === null || health === null || ai === null) continue;
      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;
      if (screenX < -50 || screenX > screenW + 50 || screenY < -50 || screenY > screenH + 50) continue;
      const sc: number = ai.size / 48;
      const flash: boolean = ai.hitFlash > 0;
      const atlas: SpriteAtlas = sm.getEnemyAtlas(ai.enemyType);
      const bounceFrame: number = Math.floor(((ai.bouncePhase % (Math.PI * 2)) / (Math.PI * 2)) * 8) % 8;
      let frameIndex: number;
      if (ai.enemyType === EnemyType.PURPLE_SLIME) {
        frameIndex = (ai.isEngulfing ? 8 : 0) + bounceFrame;
      } else if (ai.enemyType === EnemyType.RED_SLIME) {
        frameIndex = (ai.isCharging ? 8 : 0) + bounceFrame;
      } else {
        frameIndex = (flash ? 8 : 0) + bounceFrame;
      }
      const frame: FrameCoord = atlas.getFrame(frameIndex);
      const destW: number = atlas.cellW * sc;
      const destH: number = atlas.cellH * sc;
      buf.pushSprite(sm.getEnemyAtlasTextureId(), screenX - destW / 2, screenY - destH / 2, destW, destH,
        frame.sx, frame.sy, atlas.cellW, atlas.cellH,
        sm.getTextureWidth(sm.getEnemyAtlasTextureId()), sm.getTextureHeight(sm.getEnemyAtlasTextureId()),
        1, 1, 1, 1, 0, 0, 0, 0);
      if (flash && (ai.enemyType === EnemyType.PURPLE_SLIME || ai.enemyType === EnemyType.RED_SLIME)) {
        buf.pushCircle(screenX, screenY, 15 * sc, 1, 1, 1, 0.6, 0, 0);
      }
      if (ai.isCharging && ai.enemyType !== EnemyType.RED_SLIME) {
        const halfSize: number = ai.size / 2;
        const rC: number[] = hexToRgb(COLOR_SLIME_RED);
        buf.pushCircle(screenX, screenY, halfSize + 6, rC[0], rC[1], rC[2], 0.4, 0, 0);
      }
      if (health.current < health.max) {
        const barW: number = ai.size;
        const barH: number = 3;
        const barY: number = screenY - ai.size / 2 - 6;
        buf.pushRect(screenX - barW / 2, barY, barW, barH, 0.216, 0.255, 0.318, 1, 0, 0);
        buf.pushRect(screenX - barW / 2, barY, barW * (health.current / health.max), barH, 0.937, 0.267, 0.267, 1, 0, 0);
      }
      const levelY: number = screenY - ai.size / 2 - 12;
      const level: number = ai.level;
      let lr: number = 1; let lg: number = 1; let lb: number = 1;
      if (level > playerLevel) { lr = 0.937; lg = 0.267; lb = 0.267; }
      else if (level < playerLevel) { lr = 0.133; lg = 0.773; lb = 0.369; }
      buf.pushRect(screenX - 6, levelY - 4, 12, 5, lr, lg, lb, 1, 0, 0);
    }
  }

  private collectXpOrbsCommands(world: World, buf: DrawCmdBuffer, offX: number, offY: number,
      screenW: number, screenH: number, frameCount: number): void {
    const orbs: Entity[] = world.queryWithTag('xpOrb');
    const orbC: number[] = hexToRgb(COLOR_XP_ORB);
    const glowC: number[] = hexToRgb(COLOR_XP_GLOW);
    for (let i: number = 0; i < orbs.length; i++) {
      const entity: Entity = orbs[i];
      if (!entity.active) continue;
      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      const pickup: XpPickupComponent | null = entity.getComponent<XpPickupComponent>('xpPickup');
      if (pos === null || pickup === null) continue;
      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;
      if (screenX < -20 || screenX > screenW + 20 || screenY < -20 || screenY > screenH + 20) continue;
      const bob: number = Math.sin(pickup.magnetPhase) * 2;
      buf.pushCircle(screenX, screenY + bob, XP_ORB_SIZE + 4, glowC[0], glowC[1], glowC[2], 0.2, 0, 0);
      buf.pushCircle(screenX, screenY + bob, XP_ORB_SIZE, orbC[0], orbC[1], orbC[2], 0.9, 0, 0);
      buf.pushCircle(screenX - 1, screenY - 1 + bob, 2, 1, 1, 1, 1, 0, 0);
    }
  }
}
