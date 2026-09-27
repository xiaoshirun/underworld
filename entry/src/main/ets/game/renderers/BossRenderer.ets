import {
  BossState, BossType, BossPhase, MaterialDrop, MaterialType,
  COLOR_MUSHROOM_STEM, COLOR_WATER_LIGHT,
  COLOR_CRYSTAL, COLOR_MUSHROOM_CAP, COLOR_LAVA_LIGHT,
  COLOR_BOSS_ABYSS, COLOR_BOSS_VOID,
  COLOR_BOSS_HP_BAR, COLOR_BOSS_HP_BG,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export class BossRenderer {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  render(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    this.renderBosses(c, offX, offY);
    this.renderMaterialDrops(c, offX, offY);
  }

  renderHPBar(c: CanvasRenderingContext2D): void {
    this.renderBossHPBar(c);
  }

  private renderBosses(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.g.bosses.length; i++) {
      const boss: BossState = this.g.bosses[i];
      if (!boss.active || boss.defeated) continue;

      const screenX: number = boss.x + offX;
      const screenY: number = boss.y + offY;

      if (screenX < -60 || screenX > this.g.screenW + 60 || screenY < -60 || screenY > this.g.screenH + 60) {
        continue;
      }

      const bossColor: string = this.g.getBossColor(boss.bossType);
      const halfSize: number = boss.size / 2;
      const pulse: number = Math.sin(this.g.frameCount * 0.05) * 2;

      if (boss.hitFlash > 0) {
        c.globalAlpha = 0.5 + 0.5 * Math.sin(boss.hitFlash * 0.05);
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - halfSize - 2, screenY - halfSize - 2, boss.size + 4, boss.size + 4);
      }

      c.globalAlpha = 1.0;

      if (boss.bossType === BossType.CRYSTAL_GUARDIAN) {
        c.fillStyle = bossColor;
        c.beginPath();
        c.moveTo(screenX, screenY - halfSize - pulse);
        c.lineTo(screenX + halfSize + pulse, screenY);
        c.lineTo(screenX, screenY + halfSize + pulse);
        c.lineTo(screenX - halfSize - pulse, screenY);
        c.closePath();
        c.fill();
        c.fillStyle = '#67e8f9';
        c.globalAlpha = 0.5 + 0.3 * Math.sin(this.g.frameCount * 0.08);
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.4, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - 6, screenY - 4, 4, 6);
        c.fillRect(screenX + 3, screenY - 4, 4, 6);
      } else if (boss.bossType === BossType.MUSHROOM_KING) {
        c.fillStyle = bossColor;
        c.beginPath();
        c.arc(screenX, screenY - 4, halfSize + pulse, Math.PI, 0);
        c.closePath();
        c.fill();
        c.fillStyle = '#ff9ec4';
        c.beginPath();
        c.arc(screenX - 8, screenY - 12, 4, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(screenX + 6, screenY - 16, 3, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = COLOR_MUSHROOM_STEM;
        c.fillRect(screenX - 8, screenY - 4, 16, halfSize);
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - 5, screenY + 2, 4, 5);
        c.fillRect(screenX + 2, screenY + 2, 4, 5);
      } else if (boss.bossType === BossType.LAVA_BEAST) {
        c.fillStyle = bossColor;
        c.fillRect(screenX - halfSize, screenY - halfSize, boss.size, boss.size);
        c.strokeStyle = '#ffd700';
        c.lineWidth = 2;
        c.globalAlpha = 0.6 + 0.4 * Math.sin(this.g.frameCount * 0.1);
        c.beginPath();
        c.moveTo(screenX - 10, screenY - 12);
        c.lineTo(screenX - 2, screenY + 4);
        c.lineTo(screenX + 8, screenY - 6);
        c.moveTo(screenX + 4, screenY + 2);
        c.lineTo(screenX - 6, screenY + 14);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
        c.fillStyle = '#ffd700';
        c.fillRect(screenX - 7, screenY - 6, 5, 5);
        c.fillRect(screenX + 3, screenY - 6, 5, 5);
      } else if (boss.bossType === BossType.ABYSS_SIREN) {
        c.fillStyle = bossColor;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + pulse, 0, Math.PI * 2);
        c.fill();
        c.strokeStyle = COLOR_WATER_LIGHT;
        c.lineWidth = 3;
        c.globalAlpha = 0.6;
        for (let t: number = 0; t < 4; t++) {
          const angle: number = (t / 4) * Math.PI * 2 + this.g.frameCount * 0.03;
          const ex: number = screenX + Math.cos(angle) * (halfSize + 10);
          const ey: number = screenY + Math.sin(angle) * (halfSize + 10);
          c.beginPath();
          c.moveTo(screenX + Math.cos(angle) * halfSize * 0.5, screenY + Math.sin(angle) * halfSize * 0.5);
          c.quadraticCurveTo(
            screenX + Math.cos(angle + 0.5) * halfSize,
            screenY + Math.sin(angle + 0.5) * halfSize,
            ex, ey
          );
          c.stroke();
        }
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(screenX - 6, screenY - 3, 4, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(screenX + 6, screenY - 3, 4, 0, Math.PI * 2);
        c.fill();
      } else if (boss.bossType === BossType.VOID_RIFT) {
        c.fillStyle = bossColor;
        c.globalAlpha = 0.8;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + pulse + 4, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = '#0d0d1a';
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.5, 0, Math.PI * 2);
        c.fill();
        c.strokeStyle = '#a855f7';
        c.lineWidth = 2;
        c.globalAlpha = 0.5;
        const spin: number = this.g.frameCount * 0.04;
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.7, spin, spin + Math.PI * 1.2);
        c.stroke();
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.9, spin + Math.PI, spin + Math.PI * 2.2);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
      }

      if (boss.phase === BossPhase.PHASE_2) {
        c.strokeStyle = bossColor;
        c.lineWidth = 2;
        c.globalAlpha = 0.3 + 0.2 * Math.sin(this.g.frameCount * 0.1);
        c.beginPath();
        c.arc(screenX, screenY, halfSize + 8 + pulse, 0, Math.PI * 2);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderMaterialDrops(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.g.materialDrops.length; i++) {
      const drop: MaterialDrop = this.g.materialDrops[i];
      if (!drop.active) continue;

      const screenX: number = drop.x + offX;
      const screenY: number = drop.y + offY;

      if (screenX < -20 || screenX > this.g.screenW + 20 || screenY < -20 || screenY > this.g.screenH + 20) {
        continue;
      }

      const bob: number = Math.sin(this.g.frameCount * 0.06 + drop.bobPhase) * 3;
      const drawY: number = screenY + bob;

      let color: string = '#ffffff';
      if (drop.type === MaterialType.CRYSTAL_ORE) color = COLOR_CRYSTAL;
      else if (drop.type === MaterialType.MUSHROOM_ORE) color = COLOR_MUSHROOM_CAP;
      else if (drop.type === MaterialType.FLAME_ORE) color = COLOR_LAVA_LIGHT;
      else if (drop.type === MaterialType.ABYSS_ORE) color = COLOR_BOSS_ABYSS;
      else if (drop.type === MaterialType.VOID_ORE) color = COLOR_BOSS_VOID;
      else if (drop.type === MaterialType.CORE_NORMAL) color = '#c0c0c0';
      else if (drop.type === MaterialType.CORE_RARE) color = '#ffd700';
      else if (drop.type === MaterialType.FORM_CORE) color = '#e879f9';

      c.globalAlpha = 0.3;
      c.fillStyle = color;
      c.beginPath();
      c.arc(screenX, drawY, 8, 0, Math.PI * 2);
      c.fill();

      c.globalAlpha = 1.0;
      c.fillStyle = color;
      c.fillRect(screenX - 4, drawY - 4, 8, 8);
      c.strokeStyle = '#ffffff';
      c.lineWidth = 1;
      c.strokeRect(screenX - 4, drawY - 4, 8, 8);
    }
    c.globalAlpha = 1.0;
  }

  private renderBossHPBar(c: CanvasRenderingContext2D): void {
    const boss: BossState | null = this.g.activeBoss;
    if (boss === null || boss.defeated) {
      for (let i: number = 0; i < this.g.bosses.length; i++) {
        if (this.g.bosses[i].active && !this.g.bosses[i].defeated) {
          this.drawBossHPBar(c, this.g.bosses[i]);
          return;
        }
      }
      return;
    }
    this.drawBossHPBar(c, boss);
  }

  private drawBossHPBar(c: CanvasRenderingContext2D, boss: BossState): void {
    const barW: number = 200;
    const barH: number = 12;
    const barX: number = (this.g.screenW - barW) / 2;
    const barY: number = 20;
    const hpRatio: number = Math.max(0, boss.hp / boss.maxHp);

    c.fillStyle = COLOR_BOSS_HP_BG;
    c.globalAlpha = 0.8;
    c.fillRect(barX - 2, barY - 2, barW + 4, barH + 4);

    c.fillStyle = COLOR_BOSS_HP_BAR;
    c.globalAlpha = 1.0;
    c.fillRect(barX, barY, barW * hpRatio, barH);

    c.strokeStyle = '#ffffff';
    c.lineWidth = 1;
    c.globalAlpha = 0.5;
    c.strokeRect(barX - 2, barY - 2, barW + 4, barH + 4);

    c.globalAlpha = 1.0;
    c.fillStyle = '#ffffff';
    c.font = '10px sans-serif';
    c.textAlign = 'center';
    let name: string = 'Boss';
    if (boss.bossType === BossType.CRYSTAL_GUARDIAN) name = 'Crystal Guardian';
    else if (boss.bossType === BossType.MUSHROOM_KING) name = 'Mushroom King';
    else if (boss.bossType === BossType.LAVA_BEAST) name = 'Lava Beast';
    else if (boss.bossType === BossType.ABYSS_SIREN) name = 'Abyss Siren';
    else if (boss.bossType === BossType.VOID_RIFT) name = 'Void Rift';
    if (boss.phase === BossPhase.PHASE_2) name += ' [Enraged]';
    c.fillText(name, this.g.screenW / 2, barY - 6);
  }
}
