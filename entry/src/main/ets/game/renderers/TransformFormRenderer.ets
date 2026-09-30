import { PositionComponent, VelocityComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { PComp } from './PlayerRenderer';
import {
  COLOR_TRANSFORM_ARMOR,
  COLOR_TRANSFORM_ARMOR_ACCENT,
  COLOR_TRANSFORM_FLASH,
  COLOR_TRANSFORM_GHOST,
  COLOR_TRANSFORM_GHOST_DARK,
  COLOR_TRANSFORM_IRON_GOLD,
  COLOR_TRANSFORM_IRON_RED,
  COLOR_TRANSFORM_SLIME,
  COLOR_TRANSFORM_SLIME_DARK,
  EvolutionBranch,
  PLAYER_SIZE,
  TRANSFORM_ACTIVATE_ANIM,
  TRANSFORM_REVERT_ANIM,
  TransformForm,
} from '../GameConstants';

export class TransformFormRenderer {

  public renderSlimeForm(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number): void {
    const size: number = 18;
    const squash: number = pc.movement.isJumping ? 0.8 : 1.0 + Math.sin(pc.frameCount * 0.1) * 0.05;
    const stretch: number = pc.movement.isJumping ? 1.3 : 1.0 - Math.sin(pc.frameCount * 0.1) * 0.05;

    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY);
    c.scale(squash, stretch);

    c.fillStyle = COLOR_TRANSFORM_SLIME;
    c.beginPath();
    c.ellipse(0, 2, size / 2, size / 2.2, 0, 0, Math.PI * 2);
    c.fill();

    c.fillStyle = COLOR_TRANSFORM_SLIME_DARK;
    c.beginPath();
    c.ellipse(0, 4, size / 2.5, size / 3, 0, 0, Math.PI * 2);
    c.fill();

    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(-4, -2, 3, 4, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(4, -2, 3, 4, 0, 0, Math.PI * 2);
    c.fill();

    const pupilOffX: number = Math.cos(pc.movement.facing) * 1.5;
    const pupilOffY: number = Math.sin(pc.movement.facing) * 1.5;
    c.fillStyle = '#1a1a2e';
    c.beginPath();
    c.arc(-4 + pupilOffX, -2 + pupilOffY, 1.5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4 + pupilOffX, -2 + pupilOffY, 1.5, 0, Math.PI * 2);
    c.fill();

    c.restore();
  }

  public renderGhostForm(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number): void {
    c.save();
    c.globalAlpha = 0.5 + Math.sin(pc.frameCount * 0.06) * 0.15;
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY - 3);

    c.fillStyle = COLOR_TRANSFORM_GHOST;
    c.beginPath();
    c.arc(0, -4, 8, Math.PI, 0);
    c.lineTo(8, 6);
    for (let i: number = 0; i < 4; i++) {
      const wx: number = 8 - i * 4;
      const wy: number = 6 + (i % 2 === 0 ? 4 : 0);
      c.lineTo(wx, wy);
    }
    c.closePath();
    c.fill();

    c.fillStyle = COLOR_TRANSFORM_GHOST_DARK;
    c.beginPath();
    c.arc(0, -2, 5, 0, Math.PI * 2);
    c.fill();

    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(-3, -4, 2, 3, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(3, -4, 2, 3, 0, 0, Math.PI * 2);
    c.fill();

    c.restore();
  }

  public renderArmorForm(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number): void {
    const scale: number = 1.3;
    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY);
    c.scale(scale, scale);

    c.fillStyle = COLOR_TRANSFORM_ARMOR;
    c.fillRect(-6, -4, 12, 14);

    c.fillStyle = COLOR_TRANSFORM_ARMOR_ACCENT;
    c.fillRect(-4, -2, 8, 3);

    c.fillStyle = '#64748b';
    c.fillRect(-5, -9, 10, 6);

    c.fillStyle = COLOR_TRANSFORM_ARMOR_ACCENT;
    const visorGlow: number = 0.6 + Math.sin(pc.frameCount * 0.08) * 0.3;
    c.globalAlpha = visorGlow;
    c.fillRect(-4, -7, 8, 2);
    c.globalAlpha = 1.0;

    c.fillStyle = COLOR_TRANSFORM_ARMOR;
    c.fillRect(-8, 2, 3, 4);
    c.fillRect(5, 2, 3, 4);

    c.fillStyle = '#475569';
    c.fillRect(-4, 10, 3, 4);
    c.fillRect(1, 10, 3, 4);

    c.restore();
  }

  public renderIronManForm(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number): void {
    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY - 2);

    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-6, -4, 12, 14);

    c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
    c.fillRect(-5, 0, 10, 3);

    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-5, -9, 10, 6);
    c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
    c.fillRect(-4, -7, 8, 3);

    c.fillStyle = '#ffffff';
    c.fillRect(-3, -7, 2, 1);
    c.fillRect(1, -7, 2, 1);

    const reactorGlow: number = 0.7 + Math.sin(pc.frameCount * 0.1) * 0.3;
    c.fillStyle = '#67e8f9';
    c.globalAlpha = reactorGlow;
    c.beginPath();
    c.arc(0, 2, 2.5, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    if (pc.combat.isAttacking) {
      c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
      c.globalAlpha = 0.9;
      c.beginPath();
      c.arc(-8, 3, 3, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(8, 3, 3, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-5, 10, 4, 4);
    c.fillRect(1, 10, 4, 4);

    c.restore();
  }

  public renderTransformAnim(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp): void {
    const maxDuration: number = pc.transformAnimIsRevert ? TRANSFORM_REVERT_ANIM : TRANSFORM_ACTIVATE_ANIM;
    const progress: number = 1 - (pc.transform.transformAnimTimer / maxDuration);
    const cx: number = sx + PLAYER_SIZE / 2;
    const cy: number = sy + PLAYER_SIZE / 2;

    c.save();
    c.globalAlpha = 1 - progress;
    c.strokeStyle = COLOR_TRANSFORM_FLASH;
    c.lineWidth = 3 - progress * 2;
    c.beginPath();
    c.arc(cx, cy, progress * 30, 0, Math.PI * 2);
    c.stroke();

    const scale: number = 0.5 + progress * 0.7;
    c.globalAlpha = Math.min(1, progress * 2);
    c.fillStyle = this.getTransformColor((pc.transform.transformForm as TransformForm));
    c.beginPath();
    c.arc(cx, cy, 8 * scale, 0, Math.PI * 2);
    c.fill();
    c.restore();
  }

  public getTransformColor(form: TransformForm): string {
    if (form === TransformForm.SLIME) return COLOR_TRANSFORM_SLIME;
    if (form === TransformForm.GHOST) return COLOR_TRANSFORM_GHOST;
    if (form === TransformForm.ARMOR) return COLOR_TRANSFORM_ARMOR;
    return COLOR_TRANSFORM_IRON_GOLD;
  }

  public getBranchColor(branch: EvolutionBranch): string {
    if (branch === EvolutionBranch.CRYSTAL) return '#00ced1';
    if (branch === EvolutionBranch.FLAME) return '#ff4500';
    if (branch === EvolutionBranch.SHADOW) return '#6b21a8';
    if (branch === EvolutionBranch.TOXIN) return '#32cd32';
    if (branch === EvolutionBranch.TIDE) return '#4169e1';
    return '#ffffff';
  }
}
