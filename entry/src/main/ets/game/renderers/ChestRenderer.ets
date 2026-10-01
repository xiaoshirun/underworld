import { World, Entity, PositionComponent } from '@qiuyu/engine';
import {
  ChestType, CHEST_SIZE,
  COLOR_CHEST_GLOW, COLOR_CHEST_NORMAL, COLOR_CHEST_ELITE, COLOR_CHEST_BOSS,
  GameSettings,
} from '../GameConstants';
import { ChestComponent } from '../components/ChestComponent';
import { DrawCmdBuffer } from '../../native/DrawCmd';

function hexToRgb(hex: string): number[] {
  const h: string = hex.replace('#', '');
  const r: number = parseInt(h.substring(0, 2), 16) / 255;
  const g: number = parseInt(h.substring(2, 4), 16) / 255;
  const b: number = parseInt(h.substring(4, 6), 16) / 255;
  return [r, g, b];
}

export class ChestRenderer {

  render(c: CanvasRenderingContext2D, offX: number, offY: number,
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

  // ── New DrawCmd pipeline ──────────────────────────────────────────

  collectCommands(world: World, buf: DrawCmdBuffer, offX: number, offY: number,
    screenW: number, screenH: number,
    settings: GameSettings, frameCount: number): void {
    const chestEntities: Entity[] = world.queryWithTag("chest");
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
      buf.pushCircle(sx, sy + halfSize + 3, halfSize + 2, 0, 0, 0, 0.2, 0, 0);

      if (chest.chestType === ChestType.NORMAL) {
        this.collectNormalChest(buf, sx, drawY, halfSize, chest, settings, frameCount);
      } else if (chest.chestType === ChestType.ELITE) {
        this.collectEliteChest(buf, sx, drawY, halfSize, chest, guardianDefeated, settings, frameCount);
      } else if (chest.chestType === ChestType.BOSS) {
        this.collectBossChest(buf, sx, drawY, halfSize, chest, settings, frameCount);
      }

      // Open animation
      if (chest.opened && chest.openAnim > 0) {
        const lift: number = Math.min(chest.openAnim / 200, 1) * 8;
        const lidColor: string = chest.chestType === ChestType.BOSS ? COLOR_CHEST_BOSS :
          (chest.chestType === ChestType.ELITE ? COLOR_CHEST_ELITE : COLOR_CHEST_NORMAL);
        const lc: number[] = hexToRgb(lidColor);
        buf.pushRect(sx - halfSize, drawY - halfSize - lift - 4, CHEST_SIZE, 4, lc[0], lc[1], lc[2], 1, 0, 0);
        if (settings.effectsEnabled) {
          const sparklePhase: number = (frameCount * 0.1 + i * 2) % 1;
          for (let sp: number = 0; sp < 3; sp++) {
            const spAngle: number = (sp / 3) * Math.PI * 2 + frameCount * 0.08;
            const spDist: number = 4 + sparklePhase * 8;
            const spx: number = sx + Math.cos(spAngle) * spDist;
            const spy: number = drawY - halfSize - lift + Math.sin(spAngle) * spDist * 0.5 - 4;
            buf.pushRect(spx - 1, spy - 1, 2, 2, 1, 1, 1, 0.6 * (1 - sparklePhase), 0, 0);
          }
        }
      }
    }
  }

  private collectNormalChest(buf: DrawCmdBuffer, sx: number, sy: number,
    halfSize: number, chest: ChestComponent, settings: GameSettings, frameCount: number): void {
    if (settings.effectsEnabled && !chest.opened) {
      const gc: number[] = hexToRgb(COLOR_CHEST_GLOW);
      buf.pushCircle(sx, sy, halfSize + 8, gc[0], gc[1], gc[2], 0.15 + Math.sin(frameCount * 0.05) * 0.05, 0, 0);
    }
    const bodyC: number[] = hexToRgb('#6b4f10');
    buf.pushRect(sx - halfSize, sy - halfSize + 2, CHEST_SIZE, CHEST_SIZE - 2, bodyC[0], bodyC[1], bodyC[2], 1, 0, 0);
    const grainC: number[] = hexToRgb('#5a4210');
    buf.pushRect(sx - halfSize + 2, sy - halfSize + 4, CHEST_SIZE - 4, 1, grainC[0], grainC[1], grainC[2], 0.4, 0, 0);
    buf.pushRect(sx - halfSize + 1, sy + 1, CHEST_SIZE - 2, 1, grainC[0], grainC[1], grainC[2], 0.4, 0, 0);
    buf.pushRect(sx - halfSize + 3, sy + halfSize - 3, CHEST_SIZE - 6, 1, grainC[0], grainC[1], grainC[2], 0.4, 0, 0);
    const normalC: number[] = hexToRgb(COLOR_CHEST_NORMAL);
    buf.pushRect(sx - halfSize, sy - halfSize + 2, CHEST_SIZE, 3, normalC[0], normalC[1], normalC[2], 1, 0, 0);
    const bandC: number[] = hexToRgb('#8b7332');
    buf.pushRect(sx - halfSize, sy - halfSize + 2, CHEST_SIZE, 1, bandC[0], bandC[1], bandC[2], 1, 0, 0);
    buf.pushRect(sx - halfSize, sy + 1, CHEST_SIZE, 2, bandC[0], bandC[1], bandC[2], 1, 0, 0);
    buf.pushRect(sx - halfSize, sy + halfSize - 1, CHEST_SIZE, 1, bandC[0], bandC[1], bandC[2], 1, 0, 0);
    const highlightC: number[] = hexToRgb('#c0a030');
    buf.pushRect(sx - halfSize + 1, sy + 1, CHEST_SIZE - 2, 1, highlightC[0], highlightC[1], highlightC[2], 0.5, 0, 0);
    buf.pushRect(sx - halfSize + 1, sy - halfSize + 3, 2, 2, highlightC[0], highlightC[1], highlightC[2], 1, 0, 0);
    buf.pushRect(sx + halfSize - 3, sy - halfSize + 3, 2, 2, highlightC[0], highlightC[1], highlightC[2], 1, 0, 0);
    buf.pushRect(sx - halfSize + 1, sy + halfSize - 2, 2, 2, highlightC[0], highlightC[1], highlightC[2], 1, 0, 0);
    buf.pushRect(sx + halfSize - 3, sy + halfSize - 2, 2, 2, highlightC[0], highlightC[1], highlightC[2], 1, 0, 0);
    const keyholeC: number[] = hexToRgb('#2a1a05');
    buf.pushRect(sx - 1, sy + 2, 3, 3, keyholeC[0], keyholeC[1], keyholeC[2], 1, 0, 0);
    const keyholeInnerC: number[] = hexToRgb('#3a2a10');
    buf.pushRect(sx, sy + 3, 1, 1, keyholeInnerC[0], keyholeInnerC[1], keyholeInnerC[2], 1, 0, 0);
    const lidC: number[] = hexToRgb('#7a5c18');
    buf.pushRect(sx - halfSize, sy - halfSize, CHEST_SIZE, 3, lidC[0], lidC[1], lidC[2], 1, 0, 0);
    buf.pushRect(sx - halfSize, sy - halfSize, CHEST_SIZE, 1, bandC[0], bandC[1], bandC[2], 1, 0, 0);
    buf.pushRect(sx - halfSize + 1, sy - halfSize + 1, 1, 1, bandC[0], bandC[1], bandC[2], 1, 0, 0);
    buf.pushRect(sx + halfSize - 2, sy - halfSize + 1, 1, 1, bandC[0], bandC[1], bandC[2], 1, 0, 0);
  }

  private collectEliteChest(buf: DrawCmdBuffer, sx: number, sy: number,
    halfSize: number, chest: ChestComponent, guardianDefeated: boolean,
    settings: GameSettings, frameCount: number): void {
    const eHalf: number = halfSize + 1;
    if (settings.effectsEnabled && !chest.opened) {
      const runeGlow: number = 0.2 + Math.sin(frameCount * 0.06) * 0.1;
      buf.pushCircle(sx, sy, eHalf + 10, 0.404, 0.91, 0.976, runeGlow, 0, 0);
    }
    const bodyC: number[] = hexToRgb('#505868');
    buf.pushRect(sx - eHalf, sy - eHalf + 2, CHEST_SIZE + 2, CHEST_SIZE, bodyC[0], bodyC[1], bodyC[2], 1, 0, 0);
    const eliteC: number[] = hexToRgb(COLOR_CHEST_ELITE);
    buf.pushRect(sx - eHalf + 1, sy - eHalf + 3, CHEST_SIZE, CHEST_SIZE - 2, eliteC[0], eliteC[1], eliteC[2], 1, 0, 0);
    const borderHiC: number[] = hexToRgb('#a0b0c0');
    buf.pushRect(sx - eHalf + 1, sy - eHalf + 3, CHEST_SIZE, 1, borderHiC[0], borderHiC[1], borderHiC[2], 0.4, 0, 0);
    buf.pushRect(sx - eHalf + 1, sy - eHalf + 3, 1, CHEST_SIZE - 2, borderHiC[0], borderHiC[1], borderHiC[2], 0.4, 0, 0);
    const borderShC: number[] = hexToRgb('#3a4050');
    buf.pushRect(sx - eHalf + 1, sy + eHalf - 1, CHEST_SIZE, 1, borderShC[0], borderShC[1], borderShC[2], 0.5, 0, 0);
    buf.pushRect(sx + eHalf, sy - eHalf + 3, 1, CHEST_SIZE - 2, borderShC[0], borderShC[1], borderShC[2], 0.5, 0, 0);
    // Rune X pattern
    const runeAlpha: number = 0.3 + Math.sin(frameCount * 0.04) * 0.15;
    buf.pushLine(sx - halfSize + 1, sy - halfSize + 1, sx + halfSize - 1, sy + halfSize - 1, 1, 0.404, 0.91, 0.976, runeAlpha, 0);
    buf.pushLine(sx + halfSize - 1, sy - halfSize + 1, sx - halfSize + 1, sy + halfSize - 1, 1, 0.404, 0.91, 0.976, runeAlpha, 0);
    // Center gem
    if (!chest.opened) {
      const gemPulse: number = 0.6 + 0.4 * Math.sin(frameCount * 0.07);
      buf.pushCircle(sx, sy, 4, 0.404, 0.91, 0.976, 0.3 * gemPulse, 0, 0);
      const gemC: number[] = hexToRgb('#22d3ee');
      buf.pushTriangle(sx, sy - 3, sx + 2.5, sy, sx, sy + 3, gemC[0], gemC[1], gemC[2], 1, 0);
      buf.pushTriangle(sx, sy - 3, sx - 2.5, sy, sx, sy + 3, gemC[0], gemC[1], gemC[2], 1, 0);
      buf.pushRect(sx - 1, sy - 2, 1, 1, 1, 1, 1, 0.6, 0, 0);
    }
    // Corner brackets
    const bracketC: number[] = hexToRgb('#a0b0c0');
    const bLen: number = 4;
    buf.pushRect(sx - eHalf, sy - eHalf + 2, bLen, 1, bracketC[0], bracketC[1], bracketC[2], 1, 0, 0);
    buf.pushRect(sx - eHalf, sy - eHalf + 2, 1, bLen, bracketC[0], bracketC[1], bracketC[2], 1, 0, 0);
    buf.pushRect(sx + eHalf - bLen + 1, sy - eHalf + 2, bLen, 1, bracketC[0], bracketC[1], bracketC[2], 1, 0, 0);
    buf.pushRect(sx + eHalf, sy - eHalf + 2, 1, bLen, bracketC[0], bracketC[1], bracketC[2], 1, 0, 0);
    buf.pushRect(sx - eHalf, sy + eHalf, bLen, 1, bracketC[0], bracketC[1], bracketC[2], 1, 0, 0);
    buf.pushRect(sx - eHalf, sy + eHalf - bLen + 1, 1, bLen, bracketC[0], bracketC[1], bracketC[2], 1, 0, 0);
    buf.pushRect(sx + eHalf - bLen + 1, sy + eHalf, bLen, 1, bracketC[0], bracketC[1], bracketC[2], 1, 0, 0);
    buf.pushRect(sx + eHalf, sy + eHalf - bLen + 1, 1, bLen, bracketC[0], bracketC[1], bracketC[2], 1, 0, 0);
    // Lid
    const lidC: number[] = hexToRgb('#606878');
    buf.pushRect(sx - eHalf, sy - eHalf, CHEST_SIZE + 2, 3, lidC[0], lidC[1], lidC[2], 1, 0, 0);
    buf.pushRect(sx - eHalf, sy - eHalf, CHEST_SIZE + 2, 1, bracketC[0], bracketC[1], bracketC[2], 0.4, 0, 0);
    // Guardian status
    if (!guardianDefeated) {
      const lockPulse: number = 0.5 + 0.5 * Math.sin(frameCount * 0.1);
      buf.pushCircle(sx, sy + eHalf + 4, 3, 1, 0.2, 0.2, 0.3 * lockPulse, 0, 0);
      buf.pushRect(sx - 1.5, sy + eHalf + 2.5, 3, 3, 1, 0.2, 0.2, 1, 0, 0);
      buf.pushRect(sx - 0.5, sy + eHalf + 3, 1, 1, 1, 0.4, 0.4, 1, 0, 0);
    } else {
      buf.pushCircle(sx, sy + eHalf + 4, 3, 0.2, 1, 0.2, 0.3, 0, 0);
      buf.pushRect(sx - 1.5, sy + eHalf + 2.5, 3, 3, 0.2, 1, 0.2, 1, 0, 0);
      buf.pushRect(sx - 0.5, sy + eHalf + 3, 1, 1, 0.4, 1, 0.4, 1, 0, 0);
    }
  }

  private collectBossChest(buf: DrawCmdBuffer, sx: number, sy: number,
    halfSize: number, chest: ChestComponent, settings: GameSettings, frameCount: number): void {
    const bHalf: number = halfSize + 2;
    if (settings.effectsEnabled && !chest.opened) {
      const auraPulse: number = 0.25 + Math.sin(frameCount * 0.04) * 0.1;
      const bossC: number[] = hexToRgb(COLOR_CHEST_BOSS);
      buf.pushCircle(sx, sy, bHalf + 14, bossC[0], bossC[1], bossC[2], auraPulse, 0, 0);
      buf.pushCircle(sx, sy, bHalf + 8, 1, 1, 1, auraPulse * 0.5, 0, 0);
      for (let sp: number = 0; sp < 4; sp++) {
        const spAngle: number = (sp / 4) * Math.PI * 2 + frameCount * 0.03;
        const spDist: number = bHalf + 10;
        const spx: number = sx + Math.cos(spAngle) * spDist;
        const spy: number = sy + Math.sin(spAngle) * spDist * 0.6;
        buf.pushRect(spx - 1, spy - 1, 2, 2, 1, 0.843, 0, 0.5 + 0.3 * Math.sin(frameCount * 0.08 + sp), 0, 0);
      }
    }
    const bodyC: number[] = hexToRgb('#8b6914');
    buf.pushRect(sx - bHalf, sy - bHalf + 3, CHEST_SIZE + 4, CHEST_SIZE + 2, bodyC[0], bodyC[1], bodyC[2], 1, 0, 0);
    const bossC: number[] = hexToRgb(COLOR_CHEST_BOSS);
    buf.pushRect(sx - bHalf + 1, sy - bHalf + 4, CHEST_SIZE + 2, CHEST_SIZE, bossC[0], bossC[1], bossC[2], 1, 0, 0);
    const hiC: number[] = hexToRgb('#ffe066');
    buf.pushRect(sx - bHalf + 1, sy - bHalf + 4, CHEST_SIZE + 2, 1, hiC[0], hiC[1], hiC[2], 0.4, 0, 0);
    buf.pushRect(sx - bHalf + 1, sy - bHalf + 4, 1, CHEST_SIZE, hiC[0], hiC[1], hiC[2], 0.4, 0, 0);
    const shC: number[] = hexToRgb('#6b4f10');
    buf.pushRect(sx - bHalf + 1, sy + bHalf + 1, CHEST_SIZE + 2, 1, shC[0], shC[1], shC[2], 0.5, 0, 0);
    buf.pushRect(sx + bHalf + 1, sy - bHalf + 4, 1, CHEST_SIZE, shC[0], shC[1], shC[2], 0.5, 0, 0);
    const crossC: number[] = hexToRgb('#c0a030');
    buf.pushRect(sx - bHalf, sy, CHEST_SIZE + 4, 2, crossC[0], crossC[1], crossC[2], 1, 0, 0);
    buf.pushRect(sx - 1, sy - bHalf + 3, 2, CHEST_SIZE + 2, crossC[0], crossC[1], crossC[2], 1, 0, 0);
    buf.pushRect(sx - bHalf + 1, sy, CHEST_SIZE + 2, 1, hiC[0], hiC[1], hiC[2], 0.5, 0, 0);
    buf.pushRect(sx, sy - bHalf + 4, 1, CHEST_SIZE, hiC[0], hiC[1], hiC[2], 0.5, 0, 0);
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
      const gc: number[] = hexToRgb(gemColors[gi]);
      buf.pushCircle(gx, gy, 2, gc[0], gc[1], gc[2], 1, 0, 0);
      buf.pushRect(gx - 1, gy - 1, 1, 1, 1, 1, 1, 0.5, 0, 0);
    }
    // Center lock plate
    buf.pushRect(sx - 3, sy - 2, 6, 5, crossC[0], crossC[1], crossC[2], 1, 0, 0);
    buf.pushRect(sx - 3, sy - 2, 6, 1, hiC[0], hiC[1], hiC[2], 0.4, 0, 0);
    // Keyhole
    buf.pushCircle(sx, sy, 1.5, 0.165, 0.102, 0.02, 1, 0, 0);
    buf.pushRect(sx - 0.5, sy, 1, 2, 0.165, 0.102, 0.02, 1, 0, 0);
    // Chains (ellipse approximated as circles)
    const chainC: number[] = hexToRgb('#8b7332');
    for (let cl: number = 0; cl < 3; cl++) {
      const cy: number = sy - 4 + cl * 4;
      buf.pushCircle(sx - bHalf - 1, cy, 1.75, chainC[0], chainC[1], chainC[2], 0.6, 0, 0);
      buf.pushCircle(sx + bHalf + 1, cy, 1.75, chainC[0], chainC[1], chainC[2], 0.6, 0, 0);
    }
    // Lid
    const lidC: number[] = hexToRgb('#a07818');
    buf.pushRect(sx - bHalf, sy - bHalf, CHEST_SIZE + 4, 4, lidC[0], lidC[1], lidC[2], 1, 0, 0);
    buf.pushRect(sx - bHalf, sy - bHalf, CHEST_SIZE + 4, 1, hiC[0], hiC[1], hiC[2], 0.4, 0, 0);
    buf.pushRect(sx - bHalf + 2, sy - bHalf + 1, 2, 2, crossC[0], crossC[1], crossC[2], 1, 0, 0);
    buf.pushRect(sx + bHalf - 2, sy - bHalf + 1, 2, 2, crossC[0], crossC[1], crossC[2], 1, 0, 0);
    buf.pushRect(sx - 1, sy - bHalf + 1, 2, 2, crossC[0], crossC[1], crossC[2], 1, 0, 0);
  }
}
