import {
  PLAYER_SIZE,
  TRANSFORM_ACTIVATE_ANIM, TRANSFORM_REVERT_ANIM,
  WEAPON_FORM_STATS,
  GenderType, WeaponForm, EvolutionBranch, EvolutionLevel, TransformForm,
  PlayerState,
  COLOR_PLAYER_SKIN, COLOR_PLAYER_HAIR, COLOR_PLAYER_BODY, COLOR_PLAYER_BODY_DARK,
  COLOR_PLAYER_FEMALE_BODY, COLOR_PLAYER_FEMALE_BODY_DARK, COLOR_PLAYER_FEMALE_HAIR,
  COLOR_DRILL_TIP,
  COLOR_TRANSFORM_SLIME, COLOR_TRANSFORM_SLIME_DARK,
  COLOR_TRANSFORM_GHOST, COLOR_TRANSFORM_GHOST_DARK,
  COLOR_TRANSFORM_ARMOR, COLOR_TRANSFORM_ARMOR_ACCENT,
  COLOR_TRANSFORM_IRON_RED, COLOR_TRANSFORM_IRON_GOLD,
  COLOR_TRANSFORM_FLASH,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export class PlayerRenderer {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  render(c: CanvasRenderingContext2D, offX: number, offY: number, p: PlayerState): void {
    this.renderPlayer(c, offX, offY, p);
  }

  private renderPlayer(c: CanvasRenderingContext2D, offX: number, offY: number, p: PlayerState): void {
    const screenX: number = p.x + offX;
    const screenY: number = p.y + offY - p.jumpHeight;
    const half: number = PLAYER_SIZE / 2;

    if (p.isEngulfed) {
      c.globalAlpha = 0.5 + Math.sin(this.g.frameCount * 0.2) * 0.3;
      const engulfBodyColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY : COLOR_PLAYER_BODY;
      c.fillStyle = engulfBodyColor;
      c.beginPath();
      c.arc(screenX, screenY, half * 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      return;
    }

    if (p.invincibleTimer > 0 && Math.floor(this.g.frameCount / 3) % 2 === 0) {
      return;
    }

    if (p.isTransformed) {
      const bobY: number = p.isJumping ? -p.jumpHeight : Math.sin(this.g.frameCount * 0.08) * 1.5;
      if (p.transformForm === TransformForm.SLIME) {
        this.renderSlimeForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.GHOST) {
        this.renderGhostForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.ARMOR) {
        this.renderArmorForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.IRON_MAN) {
        this.renderIronManForm(c, screenX, screenY, p, bobY);
      }
      if (p.transformAnimTimer > 0) {
        this.renderTransformAnim(c, screenX, screenY, p);
      }
      return;
    }

    if (p.isJumping) {
      c.globalAlpha = 0.3;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, p.y + offY + half, half * 0.8, half * 0.3, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    const bobY: number = Math.sin(p.animFrame) * 1.5;
    const walkPhase: number = Math.sin(p.animFrame * 2);
    const isMoving: boolean = Math.abs(p.vx) > 0.1 || Math.abs(p.vy) > 0.1;
    const facingRight: boolean = Math.cos(p.facing) >= 0;

    const bodyColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY : COLOR_PLAYER_BODY;
    const bodyDarkColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY_DARK : COLOR_PLAYER_BODY_DARK;
    const hairColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_HAIR : COLOR_PLAYER_HAIR;

    if (!p.isJumping) {
      c.globalAlpha = 0.25;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, screenY + 13 + bobY, 7, 2.5, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    const legSwing: number = isMoving ? walkPhase * 3 : 0;
    c.fillStyle = '#4a3728';
    c.fillRect(screenX - 4, screenY + 5 + bobY, 3, 7);
    c.fillStyle = '#3d2b1a';
    c.fillRect(screenX - 3, screenY + 6 + bobY, 1, 5);
    c.fillStyle = '#4a3728';
    c.fillRect(screenX + 1, screenY + 5 + bobY, 3, 7);
    c.fillStyle = '#3d2b1a';
    c.fillRect(screenX + 2, screenY + 6 + bobY, 1, 5);
    c.fillStyle = '#3d2b1a';
    c.fillRect(screenX - 5, screenY + 10 + bobY + (isMoving ? legSwing : 0), 4, 3);
    c.fillRect(screenX + 1, screenY + 10 + bobY + (isMoving ? -legSwing : 0), 4, 3);
    c.fillStyle = '#5a4530';
    c.fillRect(screenX - 5, screenY + 10 + bobY + (isMoving ? legSwing : 0), 4, 1);
    c.fillRect(screenX + 1, screenY + 10 + bobY + (isMoving ? -legSwing : 0), 4, 1);
    c.fillStyle = '#2a1a0a';
    c.fillRect(screenX - 5, screenY + 12 + bobY + (isMoving ? legSwing : 0), 4, 1);
    c.fillRect(screenX + 1, screenY + 12 + bobY + (isMoving ? -legSwing : 0), 4, 1);

    c.fillStyle = bodyColor;
    c.fillRect(screenX - 5, screenY - 3 + bobY, 10, 9);
    c.fillStyle = bodyDarkColor;
    c.fillRect(screenX - 5, screenY + 3 + bobY, 10, 3);
    c.fillStyle = bodyDarkColor;
    c.globalAlpha = 0.4;
    c.fillRect(screenX - 3, screenY - 1 + bobY, 1, 5);
    c.fillRect(screenX + 2, screenY + 0 + bobY, 1, 4);
    c.globalAlpha = 1.0;
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.1;
    c.fillRect(screenX - 2, screenY - 2 + bobY, 4, 2);
    c.globalAlpha = 1.0;
    c.fillStyle = '#8b6914';
    c.fillRect(screenX - 5, screenY + 4 + bobY, 10, 2);
    c.fillStyle = '#6b4f0e';
    c.fillRect(screenX - 5, screenY + 4 + bobY, 10, 1);
    c.fillStyle = '#ffd700';
    c.fillRect(screenX - 1, screenY + 4 + bobY, 2, 2);
    c.fillStyle = '#fff8dc';
    c.fillRect(screenX - 1, screenY + 4 + bobY, 1, 1);

    const armSwing: number = isMoving ? walkPhase * 2 : 0;
    c.fillStyle = bodyColor;
    c.fillRect(screenX - 7, screenY - 2 + bobY + (isMoving ? -armSwing : 0), 3, 7);
    c.fillStyle = bodyDarkColor;
    c.fillRect(screenX - 7, screenY - 2 + bobY + (isMoving ? -armSwing : 0), 3, 1);
    c.fillStyle = bodyColor;
    c.fillRect(screenX + 4, screenY - 2 + bobY + (isMoving ? armSwing : 0), 3, 7);
    c.fillStyle = bodyDarkColor;
    c.fillRect(screenX + 4, screenY - 2 + bobY + (isMoving ? armSwing : 0), 3, 1);
    c.fillStyle = COLOR_PLAYER_SKIN;
    c.fillRect(screenX - 7, screenY + 4 + bobY + (isMoving ? -armSwing : 0), 3, 2);
    c.fillRect(screenX + 4, screenY + 4 + bobY + (isMoving ? armSwing : 0), 3, 2);
    c.fillStyle = '#e0b090';
    c.fillRect(screenX - 7, screenY + 5 + bobY + (isMoving ? -armSwing : 0), 3, 1);
    c.fillRect(screenX + 4, screenY + 5 + bobY + (isMoving ? armSwing : 0), 3, 1);

    c.fillStyle = COLOR_PLAYER_SKIN;
    c.fillRect(screenX - 4, screenY - 10 + bobY, 8, 7);
    c.fillStyle = '#e8c0a0';
    c.globalAlpha = 0.5;
    c.fillRect(screenX - 3, screenY - 5 + bobY, 2, 1);
    c.fillRect(screenX + 1, screenY - 5 + bobY, 2, 1);
    c.globalAlpha = 1.0;
    c.fillStyle = '#e0b090';
    c.fillRect(screenX - 3, screenY - 4 + bobY, 6, 1);
    c.fillStyle = '#d4a882';
    c.fillRect(screenX, screenY - 6 + bobY, 1, 2);

    c.fillStyle = hairColor;
    c.fillRect(screenX - 5, screenY - 12 + bobY, 10, 4);
    c.fillRect(screenX - 6, screenY - 10 + bobY, 2, 5);
    c.fillRect(screenX + 4, screenY - 10 + bobY, 2, 5);
    const hairHighlight: string = p.gender === GenderType.FEMALE ? '#7a3a9a' : '#9a5a3a';
    c.fillStyle = hairHighlight;
    c.fillRect(screenX - 4, screenY - 11 + bobY, 2, 1);
    c.fillRect(screenX + 1, screenY - 12 + bobY, 3, 1);
    c.fillRect(screenX - 2, screenY - 10 + bobY, 1, 2);
    c.fillStyle = p.gender === GenderType.FEMALE ? '#3a1050' : '#4a2a10';
    c.fillRect(screenX - 3, screenY - 9 + bobY, 1, 3);
    c.fillRect(screenX + 3, screenY - 10 + bobY, 1, 2);
    c.fillRect(screenX, screenY - 11 + bobY, 1, 1);
    if (p.gender === GenderType.FEMALE) {
      c.fillStyle = hairColor;
      c.fillRect(screenX - 7, screenY - 8 + bobY, 2, 10);
      c.fillRect(screenX + 5, screenY - 8 + bobY, 2, 10);
      c.fillStyle = '#7a3a9a';
      c.fillRect(screenX - 7, screenY - 6 + bobY, 1, 3);
      c.fillRect(screenX + 6, screenY - 7 + bobY, 1, 4);
      c.fillStyle = '#3a1050';
      c.fillRect(screenX - 6, screenY - 4 + bobY, 1, 5);
      c.fillRect(screenX + 5, screenY - 3 + bobY, 1, 4);
      c.fillStyle = hairColor;
      c.fillRect(screenX - 7, screenY + 1 + bobY, 1, 2);
      c.fillRect(screenX + 6, screenY + 1 + bobY, 1, 2);
    }

    const eyeOffX: number = facingRight ? 0 : -1;
    c.fillStyle = '#ffffff';
    c.fillRect(screenX - 2 + eyeOffX, screenY - 8 + bobY, 3, 3);
    c.fillRect(screenX + 1 + eyeOffX, screenY - 8 + bobY, 3, 3);
    c.fillStyle = '#4a90d9';
    c.fillRect(screenX - 1 + eyeOffX, screenY - 7 + bobY, 2, 2);
    c.fillRect(screenX + 2 + eyeOffX, screenY - 7 + bobY, 2, 2);
    c.fillStyle = '#1a1a2e';
    c.fillRect(screenX - 1 + eyeOffX, screenY - 7 + bobY, 1, 1);
    c.fillRect(screenX + 2 + eyeOffX, screenY - 7 + bobY, 1, 1);
    c.fillStyle = '#ffffff';
    c.fillRect(screenX - 1 + eyeOffX, screenY - 8 + bobY, 1, 1);
    c.fillRect(screenX + 2 + eyeOffX, screenY - 8 + bobY, 1, 1);
    c.globalAlpha = 0.6;
    c.fillRect(screenX + eyeOffX, screenY - 6 + bobY, 1, 1);
    c.fillRect(screenX + 3 + eyeOffX, screenY - 6 + bobY, 1, 1);
    c.globalAlpha = 1.0;
    c.fillStyle = hairColor;
    c.fillRect(screenX - 2 + eyeOffX, screenY - 9 + bobY, 3, 1);
    c.fillRect(screenX + 1 + eyeOffX, screenY - 9 + bobY, 3, 1);

    c.fillStyle = '#c0846a';
    c.fillRect(screenX, screenY - 4 + bobY, 2, 1);
    c.fillStyle = '#a06850';
    c.fillRect(screenX, screenY - 4 + bobY, 2, 1);

    this.renderDrill(c, screenX, screenY, p, bobY);
    this.renderWeaponOnPlayer(c, screenX, screenY, p, bobY);
    this.renderEvolutionEffects(c, screenX, screenY, p, bobY);
  }

  private renderDrill(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const drillLen: number = p.isDrilling ? 14 : 8;
    const drillOffX: number = Math.cos(p.facing) * (8 + (p.isDrilling ? 6 : 0));
    const drillOffY: number = Math.sin(p.facing) * (8 + (p.isDrilling ? 6 : 0));
    const baseX: number = sx + drillOffX;
    const baseY: number = sy + drillOffY + bobY;
    const fAng: number = p.facing;
    const perpX: number = -Math.sin(fAng);
    const perpY: number = Math.cos(fAng);

    c.fillStyle = '#6b7280';
    c.fillRect(baseX - 3, baseY - 3, 6, 6);
    c.fillStyle = '#9ca3af';
    c.fillRect(baseX - 3, baseY - 3, 6, 2);
    c.fillStyle = '#4b5563';
    c.fillRect(baseX - 3, baseY + 1, 6, 2);
    c.fillStyle = '#374151';
    c.fillRect(baseX - 2, baseY - 2, 1, 1);
    c.fillRect(baseX + 1, baseY - 2, 1, 1);
    c.fillRect(baseX - 2, baseY + 1, 1, 1);
    c.fillRect(baseX + 1, baseY + 1, 1, 1);

    const tipX: number = baseX + Math.cos(fAng) * drillLen;
    const tipY: number = baseY + Math.sin(fAng) * drillLen;
    c.strokeStyle = COLOR_DRILL_TIP;
    c.lineWidth = 3;
    c.beginPath();
    c.moveTo(baseX, baseY);
    c.lineTo(tipX, tipY);
    c.stroke();
    c.strokeStyle = '#fde68a';
    c.lineWidth = 1;
    c.beginPath();
    c.moveTo(baseX + perpX, baseY + perpY);
    c.lineTo(tipX + perpX, tipY + perpY);
    c.stroke();
    c.strokeStyle = '#b45309';
    c.lineWidth = 1;
    const spiralSegs: number = p.isDrilling ? 5 : 3;
    for (let i: number = 1; i <= spiralSegs; i++) {
      const t: number = i / (spiralSegs + 1);
      const gx: number = baseX + Math.cos(fAng) * drillLen * t;
      const gy: number = baseY + Math.sin(fAng) * drillLen * t;
      const groovePhase: number = t * Math.PI * 2 + (p.isDrilling ? this.g.frameCount * 0.3 : 0);
      const grooveOff: number = Math.sin(groovePhase) * 1.5;
      c.beginPath();
      c.moveTo(gx + perpX * grooveOff, gy + perpY * grooveOff);
      c.lineTo(gx - perpX * grooveOff, gy - perpY * grooveOff);
      c.stroke();
    }

    if (p.isDrilling) {
      c.fillStyle = '#ff6b00';
      c.globalAlpha = 0.5 + Math.random() * 0.3;
      c.beginPath();
      c.arc(tipX, tipY, 4 + Math.random() * 2, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#ffaa00';
      c.globalAlpha = 0.8;
      c.beginPath();
      c.arc(tipX, tipY, 2, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.9;
      for (let i: number = 0; i < 3; i++) {
        const sparkAng: number = fAng + (Math.random() - 0.5) * 1.5;
        const sparkDist: number = 3 + Math.random() * 5;
        const sparkX: number = tipX + Math.cos(sparkAng) * sparkDist;
        const sparkY: number = tipY + Math.sin(sparkAng) * sparkDist;
        c.fillRect(sparkX, sparkY, 1, 1);
      }
      c.globalAlpha = 1.0;
    }

    if (p.isAttacking) {
      this.renderWeaponAttackEffect(c, sx, sy, p, bobY);
    }
  }

  private renderWeaponAttackEffect(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const form: WeaponForm = p.currentWeaponForm;
    const formStats: number[] = WEAPON_FORM_STATS[form];
    const range: number = formStats[0];
    const width: number = formStats[1];
    const offX: number = Math.cos(p.facing) * range * 0.7;
    const offY: number = Math.sin(p.facing) * range * 0.7;
    const cx: number = sx + offX;
    const cy: number = sy + offY + bobY;
    const perpX: number = -Math.sin(p.facing);
    const perpY: number = Math.cos(p.facing);

    if (form === WeaponForm.BLADE) {
      const arcStart: number = p.facing - 1.0;
      const arcEnd: number = p.facing + 1.0;
      c.globalAlpha = 0.25;
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 8;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.85, arcStart, arcEnd);
      c.stroke();
      c.globalAlpha = 0.7;
      c.strokeStyle = '#93c5fd';
      c.lineWidth = 4;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.85, arcStart, arcEnd);
      c.stroke();
      c.globalAlpha = 0.9;
      c.strokeStyle = '#dbeafe';
      c.lineWidth = 1.5;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.7, arcStart, arcEnd);
      c.stroke();
      const sparkAng: number = p.facing + 0.8;
      const sparkX: number = sx + Math.cos(sparkAng) * range * 0.85;
      const sparkY: number = sy + bobY + Math.sin(sparkAng) * range * 0.85;
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.8;
      c.beginPath();
      c.arc(sparkX, sparkY, 2, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.WHIP) {
      const whipLen: number = range * 1.1;
      c.globalAlpha = 0.8;
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(sx + Math.cos(p.facing) * 8, sy + bobY + Math.sin(p.facing) * 8);
      const cp1x: number = sx + Math.cos(p.facing) * whipLen * 0.5 + perpX * 15;
      const cp1y: number = sy + bobY + Math.sin(p.facing) * whipLen * 0.5 + perpY * 15;
      const endX: number = sx + Math.cos(p.facing) * whipLen;
      const endY: number = sy + bobY + Math.sin(p.facing) * whipLen;
      c.quadraticCurveTo(cp1x, cp1y, endX, endY);
      c.stroke();
      c.globalAlpha = 0.6;
      c.fillStyle = '#e879f9';
      c.beginPath();
      c.arc(endX, endY, 5, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.3;
      c.fillStyle = '#f0abfc';
      c.beginPath();
      c.arc(endX, endY, 9, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.5;
      c.strokeStyle = '#d8b4fe';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const a: number = p.facing + (i - 1.5) * 0.5;
        c.beginPath();
        c.moveTo(endX, endY);
        c.lineTo(endX + Math.cos(a) * 8, endY + Math.sin(a) * 8);
        c.stroke();
      }
    } else if (form === WeaponForm.HAMMER) {
      c.globalAlpha = 0.5;
      c.fillStyle = '#f97316';
      c.beginPath();
      c.arc(cx, cy, width * 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.7;
      c.strokeStyle = '#fdba74';
      c.lineWidth = 3;
      c.beginPath();
      c.arc(cx, cy, width * 0.8, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.3;
      c.strokeStyle = '#fed7aa';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(cx, cy, width * 1.2, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.6;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      for (let i: number = 0; i < 6; i++) {
        const a: number = (Math.PI * 2 / 6) * i;
        c.beginPath();
        c.moveTo(cx + Math.cos(a) * width * 0.3, cy + Math.sin(a) * width * 0.3);
        c.lineTo(cx + Math.cos(a) * width * 1.0, cy + Math.sin(a) * width * 1.0);
        c.stroke();
      }
    } else if (form === WeaponForm.STAFF) {
      const boltX: number = sx + Math.cos(p.facing) * range;
      const boltY: number = sy + bobY + Math.sin(p.facing) * range;
      c.globalAlpha = 0.3;
      c.strokeStyle = '#38bdf8';
      c.lineWidth = 4;
      c.beginPath();
      c.moveTo(sx + Math.cos(p.facing) * 10, sy + bobY + Math.sin(p.facing) * 10);
      c.lineTo(boltX, boltY);
      c.stroke();
      c.globalAlpha = 0.35;
      c.fillStyle = '#0ea5e9';
      c.beginPath();
      c.arc(boltX, boltY, 12, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.85;
      c.fillStyle = '#7dd3fc';
      c.beginPath();
      c.arc(boltX, boltY, 6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.9;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(boltX, boltY, 2.5, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.DUAL_BLADES) {
      for (let side: number = -1; side <= 1; side += 2) {
        const arcCx: number = sx + perpX * 8 * side;
        const arcCy: number = sy + bobY + perpY * 8 * side;
        c.globalAlpha = 0.25;
        c.strokeStyle = '#fb923c';
        c.lineWidth = 6;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.7, p.facing - 0.8, p.facing + 0.8);
        c.stroke();
        c.globalAlpha = 0.75;
        c.strokeStyle = '#fdba74';
        c.lineWidth = 3;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.7, p.facing - 0.8, p.facing + 0.8);
        c.stroke();
        c.globalAlpha = 0.9;
        c.strokeStyle = '#fff7ed';
        c.lineWidth = 1;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.55, p.facing - 0.6, p.facing + 0.6);
        c.stroke();
      }
    } else if (form === WeaponForm.GREAT_AXE) {
      c.globalAlpha = 0.35;
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.7, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.7;
      c.strokeStyle = '#fca5a5';
      c.lineWidth = 4;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.9, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.3;
      c.strokeStyle = '#fecaca';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 1.2, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.5;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 2;
      for (let i: number = 0; i < 8; i++) {
        const a: number = (Math.PI * 2 / 8) * i;
        c.beginPath();
        c.moveTo(sx + Math.cos(a) * range * 0.4, sy + bobY + Math.sin(a) * range * 0.4);
        c.lineTo(sx + Math.cos(a) * range * 1.1, sy + bobY + Math.sin(a) * range * 1.1);
        c.stroke();
      }
    }

    c.globalAlpha = 1.0;
  }

  private renderWeaponOnPlayer(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const form: WeaponForm = p.currentWeaponForm;
    const handX: number = sx + 5;
    const handY: number = sy + 2 + bobY;
    const fAng: number = p.facing;
    const cosF: number = Math.cos(fAng);
    const sinF: number = Math.sin(fAng);
    const perpX: number = -sinF;
    const perpY: number = cosF;

    if (!p.isAttacking) {
      const formColors: string[][] = [
        ['#60a5fa', '#2563eb'],
        ['#a78bfa', '#7c3aed'],
        ['#9ca3af', '#4b5563'],
        ['#7dd3fc', '#0284c7'],
        ['#fb923c', '#c2410c'],
        ['#ef4444', '#991b1b'],
      ];
      const colors: string[] = formColors[form];
      const ballX: number = handX + cosF * 3;
      const ballY: number = handY + sinF * 3;
      const t: number = this.g.frameCount * 0.06;
      const pulse: number = Math.sin(t) * 0.8;
      const baseR: number = 3.5;
      c.globalAlpha = 0.15 + Math.sin(t * 0.7) * 0.05;
      c.fillStyle = colors[0];
      c.beginPath();
      c.arc(ballX, ballY, baseR + 2 + pulse, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.85;
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(ballX, ballY, baseR + pulse * 0.3, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#6b7280';
      c.globalAlpha = 0.5;
      c.beginPath();
      c.arc(ballX + cosF * 0.8, ballY + sinF * 0.8 + 1, baseR * 0.7, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.35;
      c.fillStyle = colors[0];
      const swirlX: number = ballX + Math.cos(t * 1.3) * 1.2;
      const swirlY: number = ballY + Math.sin(t * 1.3) * 1.2;
      c.beginPath();
      c.arc(swirlX, swirlY, 1.8, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.2;
      c.fillStyle = colors[1];
      const swirl2X: number = ballX + Math.cos(t * 0.9 + 2.5) * 1.5;
      const swirl2Y: number = ballY + Math.sin(t * 0.9 + 2.5) * 1.5;
      c.beginPath();
      c.arc(swirl2X, swirl2Y, 1.2, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.9;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(ballX - 1.2, ballY - 1.2, 1.2, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.4;
      c.fillStyle = '#f9fafb';
      c.beginPath();
      c.arc(ballX + 0.8, ballY + 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.25;
      c.strokeStyle = '#e5e7eb';
      c.lineWidth = 0.5;
      const rippleR: number = baseR * 0.6 + Math.sin(t * 2) * 0.5;
      c.beginPath();
      c.arc(ballX + Math.cos(t) * 0.5, ballY + Math.sin(t) * 0.5, rippleR, 0, Math.PI * 1.5);
      c.stroke();
      c.globalAlpha = 1.0;
      return;
    }

    if (form === WeaponForm.BLADE) {
      const len: number = 16;
      const tipX: number = handX + cosF * len;
      const tipY: number = handY + sinF * len;
      const baseX: number = handX + cosF * 3;
      const baseY: number = handY + sinF * 3;
      c.strokeStyle = '#3b82f6';
      c.lineWidth = 3.5;
      c.beginPath();
      c.moveTo(baseX - perpX * 0.5, baseY - perpY * 0.5);
      c.lineTo(tipX, tipY);
      c.stroke();
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(baseX, baseY);
      c.lineTo(tipX, tipY);
      c.stroke();
      c.strokeStyle = '#bfdbfe';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(baseX + perpX * 1, baseY + perpY * 1);
      c.lineTo(tipX, tipY);
      c.stroke();
      c.strokeStyle = '#2563eb';
      c.lineWidth = 0.8;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(baseX + cosF * 2, baseY + sinF * 2);
      c.lineTo(handX + cosF * (len - 3), handY + sinF * (len - 3));
      c.stroke();
      c.globalAlpha = 1.0;
      const guardCx: number = handX + cosF * 3;
      const guardCy: number = handY + sinF * 3;
      c.strokeStyle = '#b45309';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(guardCx + perpX * 3.5, guardCy + perpY * 3.5);
      c.lineTo(guardCx - perpX * 3.5, guardCy - perpY * 3.5);
      c.stroke();
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(guardCx + perpX * 3, guardCy + perpY * 3);
      c.lineTo(guardCx - perpX * 3, guardCy - perpY * 3);
      c.stroke();
      c.fillStyle = '#fcd34d';
      c.beginPath();
      c.arc(guardCx + perpX * 3.5, guardCy + perpY * 3.5, 1, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(guardCx - perpX * 3.5, guardCy - perpY * 3.5, 1, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#78350f';
      c.lineWidth = 0.8;
      for (let i: number = 0; i < 3; i++) {
        const t: number = 0.3 + i * 0.25;
        const gx: number = handX + cosF * 3 * t;
        const gy: number = handY + sinF * 3 * t;
        c.beginPath();
        c.moveTo(gx + perpX * 1.2, gy + perpY * 1.2);
        c.lineTo(gx - perpX * 1.2, gy - perpY * 1.2);
        c.stroke();
      }
      const pomX: number = handX - cosF * 1;
      const pomY: number = handY - sinF * 1;
      c.fillStyle = '#fbbf24';
      c.beginPath();
      c.arc(pomX, pomY, 1.5, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#fcd34d';
      c.beginPath();
      c.arc(pomX - 0.5, pomY - 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.8;
      c.beginPath();
      c.arc(tipX, tipY, 1.5, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.WHIP) {
      const len: number = 18;
      const segs: number = 6;
      c.strokeStyle = '#6d28d9';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      let prevX: number = handX;
      let prevY: number = handY;
      for (let i: number = 1; i <= segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + this.g.frameCount * 0.15) * 3 * t;
        const segX: number = handX + cosF * len * t + perpX * wave;
        const segY: number = handY + sinF * len * t + perpY * wave;
        c.lineTo(segX, segY);
        prevX = segX;
        prevY = segY;
      }
      c.stroke();
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 1.8;
      c.beginPath();
      c.moveTo(handX, handY);
      for (let i: number = 1; i <= segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + this.g.frameCount * 0.15) * 3 * t;
        const segX: number = handX + cosF * len * t + perpX * wave;
        const segY: number = handY + sinF * len * t + perpY * wave;
        c.lineTo(segX, segY);
      }
      c.stroke();
      c.fillStyle = '#c4b5fd';
      for (let i: number = 1; i < segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + this.g.frameCount * 0.15) * 3 * t;
        const jx: number = handX + cosF * len * t + perpX * wave;
        const jy: number = handY + sinF * len * t + perpY * wave;
        c.beginPath();
        c.arc(jx, jy, 0.8, 0, Math.PI * 2);
        c.fill();
      }
      c.strokeStyle = '#581c87';
      c.lineWidth = 1;
      for (let i: number = 0; i < 2; i++) {
        const t: number = 0.05 + i * 0.08;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.5, wy + perpY * 1.5);
        c.lineTo(wx - perpX * 1.5, wy - perpY * 1.5);
        c.stroke();
      }
      c.fillStyle = '#c026d3';
      c.beginPath();
      c.moveTo(prevX + cosF * 4, prevY + sinF * 4);
      c.lineTo(prevX + perpX * 2.5, prevY + perpY * 2.5);
      c.lineTo(prevX - perpX * 2.5, prevY - perpY * 2.5);
      c.closePath();
      c.fill();
      c.strokeStyle = '#e879f9';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(prevX + cosF * 3.5, prevY + sinF * 3.5);
      c.lineTo(prevX + perpX * 1.5, prevY + perpY * 1.5);
      c.stroke();
      c.fillStyle = '#d946ef';
      c.beginPath();
      c.moveTo(prevX + perpX * 2.5, prevY + perpY * 2.5);
      c.lineTo(prevX + perpX * 4 + cosF * 1, prevY + perpY * 4 + sinF * 1);
      c.lineTo(prevX + perpX * 1.5, prevY + perpY * 1.5);
      c.closePath();
      c.fill();
      c.beginPath();
      c.moveTo(prevX - perpX * 2.5, prevY - perpY * 2.5);
      c.lineTo(prevX - perpX * 4 + cosF * 1, prevY - perpY * 4 + sinF * 1);
      c.lineTo(prevX - perpX * 1.5, prevY - perpY * 1.5);
      c.closePath();
      c.fill();
    } else if (form === WeaponForm.HAMMER) {
      const len: number = 10;
      const headX: number = handX + cosF * len;
      const headY: number = handY + sinF * len;
      c.strokeStyle = '#713f12';
      c.lineWidth = 3.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(headX, headY);
      c.stroke();
      c.strokeStyle = '#8b6914';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(headX, headY);
      c.stroke();
      c.strokeStyle = '#a38524';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + perpX * 0.8, handY + perpY * 0.8);
      c.lineTo(headX + perpX * 0.8, headY + perpY * 0.8);
      c.stroke();
      c.strokeStyle = '#451a03';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const t: number = 0.15 + i * 0.18;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.8, wy + perpY * 1.8);
        c.lineTo(wx - perpX * 1.8, wy - perpY * 1.8);
        c.stroke();
      }
      c.save();
      c.translate(headX, headY);
      c.rotate(fAng);
      c.fillStyle = '#374151';
      c.fillRect(-3, -6, 12, 12);
      c.fillStyle = '#6b7280';
      c.fillRect(-2, -5, 10, 10);
      c.fillStyle = '#9ca3af';
      c.fillRect(-2, -5, 10, 3);
      c.fillStyle = '#4b5563';
      c.fillRect(-2, 2, 10, 3);
      c.strokeStyle = '#374151';
      c.lineWidth = 0.5;
      c.globalAlpha = 0.4;
      for (let i: number = 0; i < 3; i++) {
        const fy: number = -3 + i * 3;
        c.beginPath();
        c.moveTo(-1, fy);
        c.lineTo(7, fy);
        c.stroke();
      }
      c.globalAlpha = 1.0;
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(6, -3, 1, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(6, 3, 1, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#f3f4f6';
      c.beginPath();
      c.arc(5.5, -3.5, 0.4, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(5.5, 2.5, 0.4, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#9ca3af';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(8, -5);
      c.lineTo(8, 5);
      c.stroke();
      c.restore();
    } else if (form === WeaponForm.STAFF) {
      const len: number = 18;
      const orbX: number = handX + cosF * len;
      const orbY: number = handY + sinF * len;
      c.strokeStyle = '#4c1d95';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(orbX, orbY);
      c.stroke();
      c.strokeStyle = '#7c3aed';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(orbX, orbY);
      c.stroke();
      c.strokeStyle = '#8b5cf6';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX + perpX * 0.8, handY + perpY * 0.8);
      c.lineTo(orbX + perpX * 0.8, orbY + perpY * 0.8);
      c.stroke();
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      for (let i: number = 1; i <= 4; i++) {
        const t: number = i * 0.2;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.8, wy + perpY * 1.8);
        c.lineTo(wx - perpX * 1.8, wy - perpY * 1.8);
        c.stroke();
      }
      c.fillStyle = '#a78bfa';
      c.globalAlpha = 0.6;
      for (let i: number = 0; i < 3; i++) {
        const t: number = 0.15 + i * 0.25;
        const rx: number = handX + cosF * len * t + perpX * 0.5;
        const ry: number = handY + sinF * len * t + perpY * 0.5;
        c.beginPath();
        c.arc(rx, ry, 0.6, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 1.0;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.2;
      for (let i: number = 0; i < 3; i++) {
        const ang: number = fAng + (i - 1) * 1.2;
        c.beginPath();
        c.moveTo(orbX - cosF * 2, orbY - sinF * 2);
        c.lineTo(orbX + Math.cos(ang) * 3, orbY + Math.sin(ang) * 3);
        c.stroke();
      }
      const pulse: number = Math.sin(this.g.frameCount * 0.1) * 1.5;
      c.globalAlpha = 0.3;
      c.fillStyle = '#38bdf8';
      c.beginPath();
      c.arc(orbX, orbY, 5 + pulse, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.5;
      c.fillStyle = '#0ea5e9';
      c.beginPath();
      c.arc(orbX, orbY, 4, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.9;
      c.fillStyle = '#7dd3fc';
      c.beginPath();
      c.arc(orbX, orbY, 3, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#bae6fd';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      const swirlAng: number = this.g.frameCount * 0.08;
      c.beginPath();
      c.arc(orbX + Math.cos(swirlAng) * 1, orbY + Math.sin(swirlAng) * 1, 1.5, 0, Math.PI * 1.2);
      c.stroke();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.85;
      c.beginPath();
      c.arc(orbX - 1, orbY - 1, 1.2, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.4;
      c.beginPath();
      c.arc(orbX + 1, orbY + 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.DUAL_BLADES) {
      const len: number = 11;
      const rTipX: number = handX + cosF * len + perpX * 1.5;
      const rTipY: number = handY + sinF * len + perpY * 1.5;
      c.strokeStyle = '#c2410c';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      c.strokeStyle = '#fb923c';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      c.strokeStyle = '#fdba74';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + cosF * 2 + perpX * 0.5, handY + sinF * 2 + perpY * 0.5);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      c.strokeStyle = '#9a3412';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(handX + cosF * 2, handY + sinF * 2);
      c.lineTo(handX + cosF * (len - 2) + perpX * 1.5, handY + sinF * (len - 2) + perpY * 1.5);
      c.stroke();
      c.globalAlpha = 1.0;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX + perpX * 2.5, handY + perpY * 2.5);
      c.lineTo(handX - perpX * 1.5, handY - perpY * 1.5);
      c.stroke();
      c.strokeStyle = '#7c2d12';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX - cosF * 1 + perpX, handY - sinF * 1 + perpY);
      c.lineTo(handX - cosF * 1 - perpX, handY - sinF * 1 - perpY);
      c.stroke();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.7;
      c.beginPath();
      c.arc(rTipX, rTipY, 1, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      const handX2: number = sx - 5;
      const lTipX: number = handX2 + cosF * len - perpX * 1.5;
      const lTipY: number = handY + sinF * len - perpY * 1.5;
      c.strokeStyle = '#c2410c';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX2, handY);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      c.strokeStyle = '#fb923c';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX2, handY);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      c.strokeStyle = '#fdba74';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX2 + cosF * 2 - perpX * 0.5, handY + sinF * 2 - perpY * 0.5);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      c.strokeStyle = '#9a3412';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(handX2 + cosF * 2, handY + sinF * 2);
      c.lineTo(handX2 + cosF * (len - 2) - perpX * 1.5, handY + sinF * (len - 2) - perpY * 1.5);
      c.stroke();
      c.globalAlpha = 1.0;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX2 - perpX * 2.5, handY - perpY * 2.5);
      c.lineTo(handX2 + perpX * 1.5, handY + perpY * 1.5);
      c.stroke();
      c.strokeStyle = '#7c2d12';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX2 - cosF * 1 + perpX, handY - sinF * 1 + perpY);
      c.lineTo(handX2 - cosF * 1 - perpX, handY - sinF * 1 - perpY);
      c.stroke();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.7;
      c.beginPath();
      c.arc(lTipX, lTipY, 1, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.GREAT_AXE) {
      const len: number = 12;
      const axX: number = handX + cosF * len;
      const axY: number = handY + sinF * len;
      c.strokeStyle = '#451a03';
      c.lineWidth = 4;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(axX, axY);
      c.stroke();
      c.strokeStyle = '#78350f';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(axX, axY);
      c.stroke();
      c.strokeStyle = '#92400e';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + perpX * 1, handY + perpY * 1);
      c.lineTo(axX + perpX * 1, axY + perpY * 1);
      c.stroke();
      c.strokeStyle = '#1c0a00';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const t: number = 0.15 + i * 0.18;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 2, wy + perpY * 2);
        c.lineTo(wx - perpX * 2, wy - perpY * 2);
        c.stroke();
      }
      c.strokeStyle = '#6b7280';
      c.lineWidth = 2;
      const colX: number = handX + cosF * (len - 2);
      const colY: number = handY + sinF * (len - 2);
      c.beginPath();
      c.moveTo(colX + perpX * 2.5, colY + perpY * 2.5);
      c.lineTo(colX - perpX * 2.5, colY - perpY * 2.5);
      c.stroke();
      c.strokeStyle = '#9ca3af';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(colX + perpX * 2, colY + perpY * 2);
      c.lineTo(colX - perpX * 2, colY - perpY * 2);
      c.stroke();
      c.save();
      c.translate(axX, axY);
      c.rotate(fAng);
      c.fillStyle = '#991b1b';
      c.beginPath();
      c.moveTo(-1, -8);
      c.quadraticCurveTo(9, -6, 11, 0);
      c.quadraticCurveTo(9, 6, -1, 8);
      c.lineTo(-1, -8);
      c.closePath();
      c.fill();
      c.fillStyle = '#dc2626';
      c.beginPath();
      c.moveTo(0, -7);
      c.quadraticCurveTo(8, -5, 10, 0);
      c.quadraticCurveTo(8, 5, 0, 7);
      c.lineTo(0, -7);
      c.closePath();
      c.fill();
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.moveTo(1, -5);
      c.quadraticCurveTo(6, -3, 8, 0);
      c.quadraticCurveTo(6, 1, 1, 2);
      c.lineTo(1, -5);
      c.closePath();
      c.fill();
      c.strokeStyle = '#b91c1c';
      c.lineWidth = 0.5;
      c.globalAlpha = 0.5;
      for (let i: number = 0; i < 3; i++) {
        const fy: number = -4 + i * 3;
        c.beginPath();
        c.moveTo(2, fy);
        c.quadraticCurveTo(5, fy + 0.5, 7, fy);
        c.stroke();
      }
      c.globalAlpha = 1.0;
      c.strokeStyle = '#fca5a5';
      c.lineWidth = 1.2;
      c.beginPath();
      c.moveTo(1, -6);
      c.quadraticCurveTo(7, -4, 9, 0);
      c.stroke();
      c.strokeStyle = '#fecaca';
      c.lineWidth = 0.6;
      c.beginPath();
      c.moveTo(2, -5);
      c.quadraticCurveTo(6, -3, 8, 0);
      c.stroke();
      c.strokeStyle = '#7f1d1d';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(0, -7);
      c.lineTo(0, 7);
      c.stroke();
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(2, 0, 1, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#f3f4f6';
      c.beginPath();
      c.arc(1.5, -0.5, 0.4, 0, Math.PI * 2);
      c.fill();
      c.restore();
    }
  }

  private renderEvolutionEffects(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const level: number = p.evolutionLevel;
    if (level === EvolutionLevel.BASE) return;

    const branchColor: string = this.getBranchColor(p.evolutionBranch);
    const t: number = this.g.frameCount * 0.05;

    if (level >= EvolutionLevel.LEVEL_1) {
      c.globalAlpha = 0.15 + Math.sin(t) * 0.05;
      c.fillStyle = branchColor;
      c.beginPath();
      c.arc(sx, sy + bobY, 12, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    if (level >= EvolutionLevel.LEVEL_2) {
      const isMoving: boolean = Math.abs(p.vx) > 0.1 || Math.abs(p.vy) > 0.1;
      if (isMoving) {
        c.globalAlpha = 0.4;
        c.fillStyle = branchColor;
        for (let i: number = 0; i < 2; i++) {
          const px: number = sx + (Math.random() - 0.5) * 8;
          const py: number = sy + bobY + 6 + Math.random() * 4;
          c.beginPath();
          c.arc(px, py, 1 + Math.random(), 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
      }
    }

    if (level >= EvolutionLevel.LEVEL_3) {
      c.globalAlpha = 0.2 + Math.sin(t * 1.5) * 0.08;
      c.strokeStyle = branchColor;
      c.lineWidth = 1.5;
      c.beginPath();
      c.arc(sx, sy + bobY, 16 + Math.sin(t * 0.8) * 2, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 1.0;

      for (let i: number = 0; i < 3; i++) {
        const angle: number = t * 2 + (i * Math.PI * 2 / 3);
        const orbR: number = 14;
        const ox: number = sx + Math.cos(angle) * orbR;
        const oy: number = sy + bobY + Math.sin(angle) * orbR;
        c.globalAlpha = 0.6;
        c.fillStyle = branchColor;
        c.beginPath();
        c.arc(ox, oy, 1.5, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 1.0;
    }
  }

  private renderSlimeForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const size: number = 18;
    const squash: number = p.isJumping ? 0.8 : 1.0 + Math.sin(this.g.frameCount * 0.1) * 0.05;
    const stretch: number = p.isJumping ? 1.3 : 1.0 - Math.sin(this.g.frameCount * 0.1) * 0.05;

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

    const pupilOffX: number = Math.cos(p.facing) * 1.5;
    const pupilOffY: number = Math.sin(p.facing) * 1.5;
    c.fillStyle = '#1a1a2e';
    c.beginPath();
    c.arc(-4 + pupilOffX, -2 + pupilOffY, 1.5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4 + pupilOffX, -2 + pupilOffY, 1.5, 0, Math.PI * 2);
    c.fill();

    c.restore();
  }

  private renderGhostForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    c.save();
    c.globalAlpha = 0.5 + Math.sin(this.g.frameCount * 0.06) * 0.15;
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

  private renderArmorForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
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
    const visorGlow: number = 0.6 + Math.sin(this.g.frameCount * 0.08) * 0.3;
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

  private renderIronManForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
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

    const reactorGlow: number = 0.7 + Math.sin(this.g.frameCount * 0.1) * 0.3;
    c.fillStyle = '#67e8f9';
    c.globalAlpha = reactorGlow;
    c.beginPath();
    c.arc(0, 2, 2.5, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    if (p.isAttacking) {
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

  private renderTransformAnim(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState): void {
    const maxDuration: number = this.g.transformAnimIsRevert ? TRANSFORM_REVERT_ANIM : TRANSFORM_ACTIVATE_ANIM;
    const progress: number = 1 - (p.transformAnimTimer / maxDuration);
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
    c.fillStyle = this.getTransformColor(p.transformForm);
    c.beginPath();
    c.arc(cx, cy, 8 * scale, 0, Math.PI * 2);
    c.fill();
    c.restore();
  }

  private getTransformColor(form: TransformForm): string {
    if (form === TransformForm.SLIME) return COLOR_TRANSFORM_SLIME;
    if (form === TransformForm.GHOST) return COLOR_TRANSFORM_GHOST;
    if (form === TransformForm.ARMOR) return COLOR_TRANSFORM_ARMOR;
    return COLOR_TRANSFORM_IRON_GOLD;
  }

  private getBranchColor(branch: EvolutionBranch): string {
    if (branch === EvolutionBranch.CRYSTAL) return '#00ced1';
    if (branch === EvolutionBranch.FLAME) return '#ff4500';
    if (branch === EvolutionBranch.SHADOW) return '#6b21a8';
    if (branch === EvolutionBranch.TOXIN) return '#32cd32';
    if (branch === EvolutionBranch.TIDE) return '#4169e1';
    return '#ffffff';
  }
}
