import {
  COLOR_DRILL_TIP,
  COLOR_SLIME_BLUE,
  COLOR_SLIME_BLUE_LIGHT,
  COLOR_SLIME_EYE,
  COLOR_SLIME_PUPIL,
  EvolutionLevel,
  HumanFormStage,
  PLAYER_SIZE,
  TransformForm,
  GameSettings,
} from '../GameConstants';
import { World, Entity, PositionComponent, VelocityComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { WeaponRenderer } from './WeaponRenderer';
import { TransformFormRenderer } from './TransformFormRenderer';

interface PComp {
  pos: PositionComponent;
  vel: VelocityComponent;
  movement: MovementComponent;
  combat: CombatComponent;
  transform: TransformComponent;
  evolution: EvolutionComponent;
  humanForm: HumanFormComponent;
  frameCount: number;
  transformAnimIsRevert: boolean;
}

export class PlayerRenderer {
  private weaponRenderer: WeaponRenderer = new WeaponRenderer();
  private transformRenderer: TransformFormRenderer = new TransformFormRenderer();

  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number, cameraY: number, screenW: number, screenH: number, settings: GameSettings, frameCount: number): void {
    const player: Entity | null = world.findEntityByTag('player');
    if (player === null) return;
    const pos: PositionComponent | null = player.getComponent<PositionComponent>('Position');
    const vel: VelocityComponent | null = player.getComponent<VelocityComponent>('Velocity');
    const movement: MovementComponent | null = player.getComponent<MovementComponent>('movement');
    const combat: CombatComponent | null = player.getComponent<CombatComponent>('combat');
    const transform: TransformComponent | null = player.getComponent<TransformComponent>('transform');
    const evolution: EvolutionComponent | null = player.getComponent<EvolutionComponent>('evolution');
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>('humanForm');
    if (pos === null || vel === null || movement === null || combat === null || transform === null || evolution === null || humanForm === null) return;
    const pc: PComp = {
      pos: pos,
      vel: vel,
      movement: movement,
      combat: combat,
      transform: transform,
      evolution: evolution,
      humanForm: humanForm,
      frameCount: frameCount,
      transformAnimIsRevert: transform.transformForm === -1,
    };
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    this.renderPlayer(ctx, offX, offY, pc);
  }

  private renderPlayer(c: CanvasRenderingContext2D, offX: number, offY: number, pc: PComp): void {
    const screenX: number = pc.pos.x + offX;
    const screenY: number = pc.pos.y + offY - pc.movement.jumpHeight;
    const half: number = PLAYER_SIZE / 2;

    if (pc.movement.isEngulfed) {
      c.globalAlpha = 0.5 + Math.sin(pc.frameCount * 0.2) * 0.3;
      const engulfBodyColor: string = COLOR_SLIME_BLUE;
      c.fillStyle = engulfBodyColor;
      c.beginPath();
      c.arc(screenX, screenY, half * 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      return;
    }

    if (pc.combat.invincibleTimer > 0 && Math.floor(pc.frameCount / 3) % 2 === 0) {
      return;
    }

    // Human form rendering
    if (pc.humanForm.isHumanForm) {
      this.renderHumanForm(c, screenX, screenY, pc);
      return;
    }

    if (pc.transform.isTransformed) {
      const bobY: number = pc.movement.isJumping ? -pc.movement.jumpHeight : Math.sin(pc.frameCount * 0.08) * 1.5;
      if ((pc.transform.transformForm as TransformForm) === TransformForm.SLIME) {
        this.transformRenderer.renderSlimeForm(c, screenX, screenY, pc, bobY);
      } else if ((pc.transform.transformForm as TransformForm) === TransformForm.GHOST) {
        this.transformRenderer.renderGhostForm(c, screenX, screenY, pc, bobY);
      } else if ((pc.transform.transformForm as TransformForm) === TransformForm.ARMOR) {
        this.transformRenderer.renderArmorForm(c, screenX, screenY, pc, bobY);
      } else if ((pc.transform.transformForm as TransformForm) === TransformForm.IRON_MAN) {
        this.transformRenderer.renderIronManForm(c, screenX, screenY, pc, bobY);
      }
      if (pc.transform.transformAnimTimer > 0) {
        this.transformRenderer.renderTransformAnim(c, screenX, screenY, pc);
      }
      return;
    }

    if (pc.movement.isJumping) {
      c.globalAlpha = 0.3;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, pc.pos.y + offY + half, half * 0.8, half * 0.3, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    const bobY: number = pc.movement.isJumping ? -pc.movement.jumpHeight : Math.sin(pc.frameCount * 0.08) * 1.5;
    this.renderSlimeBody(c, screenX, screenY, pc, bobY);
    this.renderDrill(c, screenX, screenY, pc, bobY);
    this.renderEvolutionEffects(c, screenX, screenY, pc, bobY);
  }

  private renderSlimeBody(c: CanvasRenderingContext2D, screenX: number, screenY: number, pc: PComp, bobY: number): void {
    const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
    const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;
    const squish: number = isMoving ? Math.sin(pc.frameCount * 0.15) * 1.5 : Math.sin(pc.frameCount * 0.05) * 0.8;
    const bodyW: number = 12 + squish;
    const bodyH: number = 10 - squish * 0.5;

    // Shadow
    if (!pc.movement.isJumping) {
      c.globalAlpha = 0.25;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, screenY + bodyH * 0.5 + bobY, bodyW * 0.6, 3, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Main body (blob shape)
    c.fillStyle = COLOR_SLIME_BLUE;
    c.beginPath();
    c.ellipse(screenX, screenY + bobY, bodyW, bodyH, 0, 0, Math.PI * 2);
    c.fill();

    // Body highlight (top)
    c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
    c.globalAlpha = 0.5;
    c.beginPath();
    c.ellipse(screenX - 2, screenY - 3 + bobY, bodyW * 0.5, bodyH * 0.4, -0.3, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    // Body shine
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.3;
    c.beginPath();
    c.ellipse(screenX - 3, screenY - 4 + bobY, 3, 2, -0.4, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    // Bottom darker area
    c.fillStyle = '#1e40af';
    c.globalAlpha = 0.3;
    c.beginPath();
    c.ellipse(screenX, screenY + 3 + bobY, bodyW * 0.8, bodyH * 0.4, 0, 0, Math.PI);
    c.fill();
    c.globalAlpha = 1.0;

    // Eyes
    const eyeSpacing: number = 4;
    const eyeY: number = screenY - 2 + bobY;
    const eyeOffX: number = facingRight ? 1 : -1;

    // Eye whites
    c.fillStyle = COLOR_SLIME_EYE;
    c.beginPath();
    c.ellipse(screenX - eyeSpacing + eyeOffX, eyeY, 2.5, 3, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(screenX + eyeSpacing + eyeOffX, eyeY, 2.5, 3, 0, 0, Math.PI * 2);
    c.fill();

    // Pupils
    c.fillStyle = COLOR_SLIME_PUPIL;
    const pupilOff: number = facingRight ? 0.8 : -0.8;
    c.beginPath();
    c.arc(screenX - eyeSpacing + eyeOffX + pupilOff, eyeY + 0.5, 1.2, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(screenX + eyeSpacing + eyeOffX + pupilOff, eyeY + 0.5, 1.2, 0, Math.PI * 2);
    c.fill();

    // Eye shine
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.arc(screenX - eyeSpacing + eyeOffX + pupilOff - 0.5, eyeY - 0.8, 0.6, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(screenX + eyeSpacing + eyeOffX + pupilOff - 0.5, eyeY - 0.8, 0.6, 0, Math.PI * 2);
    c.fill();

    // Mouth (small smile)
    c.strokeStyle = '#1e3a5f';
    c.lineWidth = 0.8;
    c.beginPath();
    c.arc(screenX + eyeOffX, screenY + 2 + bobY, 2, 0.1, Math.PI - 0.1);
    c.stroke();
  }

  private renderHumanForm(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp): void {
    const stage: HumanFormStage = pc.humanForm.humanFormStage as HumanFormStage;
    const bobY: number = Math.sin(pc.frameCount * 0.06) * 1.5;
    const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;

    if (stage === HumanFormStage.PROTO) {
      this.renderHumanProto(c, sx, sy, pc, bobY, facingRight);
    } else if (stage === HumanFormStage.PHANTOM) {
      this.renderHumanPhantom(c, sx, sy, pc, bobY, facingRight);
    } else if (stage === HumanFormStage.ARMORED) {
      this.renderHumanArmored(c, sx, sy, pc, bobY, facingRight);
    } else if (stage === HumanFormStage.COMPLETE) {
      this.renderHumanComplete(c, sx, sy, pc, bobY, facingRight);
    }
  }

  private renderHumanProto(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number, facingRight: boolean): void {
    // Basic translucent humanoid outline — unstable form
    c.globalAlpha = 0.4 + Math.sin(pc.frameCount * 0.1) * 0.1;

    // Body
    c.fillStyle = '#8bb4d6';
    c.fillRect(sx - 4, sy - 6 + bobY, 8, 12);

    // Head
    c.beginPath();
    c.arc(sx, sy - 10 + bobY, 4, 0, Math.PI * 2);
    c.fill();

    // Legs
    c.fillRect(sx - 3, sy + 6 + bobY, 2, 6);
    c.fillRect(sx + 1, sy + 6 + bobY, 2, 6);

    // Arms
    c.fillRect(sx - 7, sy - 4 + bobY, 3, 8);
    c.fillRect(sx + 4, sy - 4 + bobY, 3, 8);

    // Eyes (simple dots)
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.7;
    c.fillRect(sx - 2, sy - 11 + bobY, 2, 2);
    c.fillRect(sx + 1, sy - 11 + bobY, 2, 2);

    c.globalAlpha = 1.0;
  }

  private renderHumanPhantom(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number, facingRight: boolean): void {
    // Ghost-like translucent humanoid with trailing wisps
    const t: number = pc.frameCount * 0.08;

    // Ghost trail
    c.globalAlpha = 0.15;
    c.fillStyle = '#a0c4e8';
    for (let i: number = 0; i < 3; i++) {
      const trailY: number = sy + 8 + i * 4 + Math.sin(t + i) * 2;
      c.beginPath();
      c.ellipse(sx + Math.sin(t + i * 0.5) * 2, trailY + bobY, 5 - i, 3, 0, 0, Math.PI * 2);
      c.fill();
    }

    // Body (semi-transparent)
    c.globalAlpha = 0.55 + Math.sin(t) * 0.1;
    c.fillStyle = '#7db8e0';
    c.fillRect(sx - 5, sy - 6 + bobY, 10, 14);

    // Head
    c.beginPath();
    c.arc(sx, sy - 10 + bobY, 5, 0, Math.PI * 2);
    c.fill();

    // Legs (wispy)
    c.globalAlpha = 0.35;
    c.fillRect(sx - 3, sy + 8 + bobY, 2, 5);
    c.fillRect(sx + 1, sy + 8 + bobY, 2, 5);

    // Arms
    c.globalAlpha = 0.45;
    c.fillRect(sx - 8, sy - 4 + bobY, 3, 9);
    c.fillRect(sx + 5, sy - 4 + bobY, 3, 9);

    // Eyes (glowing)
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.9;
    c.beginPath();
    c.arc(sx - 2, sy - 10 + bobY, 1.5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx + 2, sy - 10 + bobY, 1.5, 0, Math.PI * 2);
    c.fill();

    // Glow aura
    c.globalAlpha = 0.1;
    c.fillStyle = '#60a5fa';
    c.beginPath();
    c.arc(sx, sy + bobY, 18, 0, Math.PI * 2);
    c.fill();

    c.globalAlpha = 1.0;
  }

  private renderHumanArmored(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number, facingRight: boolean): void {
    // Armored humanoid with metallic colors
    const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
    const walkPhase: number = isMoving ? Math.sin(pc.frameCount * 0.15) * 3 : 0;

    // Shadow
    c.globalAlpha = 0.3;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(sx, sy + 14 + bobY, 8, 3, 0, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    // Legs (armored)
    c.fillStyle = '#4b5563';
    c.fillRect(sx - 4, sy + 6 + bobY + walkPhase, 3, 8);
    c.fillRect(sx + 1, sy + 6 + bobY - walkPhase, 3, 8);
    // Boots
    c.fillStyle = '#374151';
    c.fillRect(sx - 5, sy + 12 + bobY + walkPhase, 4, 2);
    c.fillRect(sx + 1, sy + 12 + bobY - walkPhase, 4, 2);

    // Body (armor)
    c.fillStyle = '#6b7280';
    c.fillRect(sx - 6, sy - 6 + bobY, 12, 13);
    // Chest plate highlight
    c.fillStyle = '#9ca3af';
    c.fillRect(sx - 5, sy - 5 + bobY, 10, 3);
    // Belt
    c.fillStyle = '#92400e';
    c.fillRect(sx - 6, sy + 4 + bobY, 12, 2);
    c.fillStyle = '#fbbf24';
    c.fillRect(sx - 1, sy + 4 + bobY, 2, 2);

    // Arms (armored)
    c.fillStyle = '#6b7280';
    c.fillRect(sx - 9, sy - 4 + bobY, 3, 9);
    c.fillRect(sx + 6, sy - 4 + bobY, 3, 9);
    // Gauntlets
    c.fillStyle = '#4b5563';
    c.fillRect(sx - 9, sy + 3 + bobY, 3, 3);
    c.fillRect(sx + 6, sy + 3 + bobY, 3, 3);

    // Head (helmet)
    c.fillStyle = '#6b7280';
    c.beginPath();
    c.arc(sx, sy - 10 + bobY, 5, 0, Math.PI * 2);
    c.fill();
    // Visor
    c.fillStyle = '#1e3a5f';
    c.fillRect(sx - 3, sy - 11 + bobY, 6, 3);
    // Eyes through visor
    c.fillStyle = '#60a5fa';
    c.fillRect(sx - 2, sy - 10 + bobY, 2, 1);
    c.fillRect(sx + 1, sy - 10 + bobY, 2, 1);
  }

  private renderHumanComplete(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number, facingRight: boolean): void {
    // Fully armored with glowing effects
    const t: number = pc.frameCount * 0.05;
    const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
    const walkPhase: number = isMoving ? Math.sin(pc.frameCount * 0.15) * 3 : 0;

    // Glow aura
    c.globalAlpha = 0.15 + Math.sin(t) * 0.05;
    c.fillStyle = '#60a5fa';
    c.beginPath();
    c.arc(sx, sy + bobY, 22, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    // Shadow
    c.globalAlpha = 0.35;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(sx, sy + 14 + bobY, 9, 3, 0, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    // Legs (enhanced armor)
    c.fillStyle = '#374151';
    c.fillRect(sx - 4, sy + 6 + bobY + walkPhase, 3, 8);
    c.fillRect(sx + 1, sy + 6 + bobY - walkPhase, 3, 8);
    // Leg glow lines
    c.fillStyle = '#60a5fa';
    c.globalAlpha = 0.5;
    c.fillRect(sx - 3, sy + 7 + bobY + walkPhase, 1, 6);
    c.fillRect(sx + 2, sy + 7 + bobY - walkPhase, 1, 6);
    c.globalAlpha = 1.0;
    // Boots
    c.fillStyle = '#1f2937';
    c.fillRect(sx - 5, sy + 12 + bobY + walkPhase, 4, 2);
    c.fillRect(sx + 1, sy + 12 + bobY - walkPhase, 4, 2);

    // Body (enhanced armor)
    c.fillStyle = '#4b5563';
    c.fillRect(sx - 7, sy - 6 + bobY, 14, 13);
    // Chest plate
    c.fillStyle = '#6b7280';
    c.fillRect(sx - 6, sy - 5 + bobY, 12, 4);
    // Chest glow
    c.fillStyle = '#60a5fa';
    c.globalAlpha = 0.6 + Math.sin(t * 2) * 0.2;
    c.beginPath();
    c.arc(sx, sy - 1 + bobY, 2, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;
    // Belt
    c.fillStyle = '#78350f';
    c.fillRect(sx - 7, sy + 4 + bobY, 14, 2);
    c.fillStyle = '#fbbf24';
    c.fillRect(sx - 1, sy + 4 + bobY, 2, 2);

    // Arms (enhanced)
    c.fillStyle = '#4b5563';
    c.fillRect(sx - 10, sy - 4 + bobY, 3, 10);
    c.fillRect(sx + 7, sy - 4 + bobY, 3, 10);
    // Arm glow lines
    c.fillStyle = '#60a5fa';
    c.globalAlpha = 0.4;
    c.fillRect(sx - 9, sy - 3 + bobY, 1, 8);
    c.fillRect(sx + 8, sy - 3 + bobY, 1, 8);
    c.globalAlpha = 1.0;
    // Gauntlets
    c.fillStyle = '#374151';
    c.fillRect(sx - 10, sy + 4 + bobY, 3, 3);
    c.fillRect(sx + 7, sy + 4 + bobY, 3, 3);

    // Head (enhanced helmet)
    c.fillStyle = '#4b5563';
    c.beginPath();
    c.arc(sx, sy - 10 + bobY, 6, 0, Math.PI * 2);
    c.fill();
    // Helmet crest
    c.fillStyle = '#60a5fa';
    c.fillRect(sx - 1, sy - 16 + bobY, 2, 4);
    // Visor
    c.fillStyle = '#1e3a5f';
    c.fillRect(sx - 4, sy - 11 + bobY, 8, 3);
    // Eyes (glowing)
    c.fillStyle = '#60a5fa';
    c.fillRect(sx - 3, sy - 10 + bobY, 2, 1);
    c.fillRect(sx + 1, sy - 10 + bobY, 2, 1);
    // Eye glow
    c.globalAlpha = 0.3;
    c.beginPath();
    c.arc(sx - 2, sy - 10 + bobY, 3, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx + 2, sy - 10 + bobY, 3, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    // Orbiting particles
    for (let i: number = 0; i < 4; i++) {
      const angle: number = t * 2 + (i * Math.PI * 2 / 4);
      const orbR: number = 16;
      const ox: number = sx + Math.cos(angle) * orbR;
      const oy: number = sy + bobY + Math.sin(angle) * orbR;
      c.globalAlpha = 0.5;
      c.fillStyle = '#60a5fa';
      c.beginPath();
      c.arc(ox, oy, 1.5, 0, Math.PI * 2);
      c.fill();
    }
    c.globalAlpha = 1.0;
  }

  private renderDrill(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number): void {
    const drillLen: number = pc.movement.isDrilling ? 14 : 8;
    const drillOffX: number = Math.cos(pc.movement.facing) * (8 + (pc.movement.isDrilling ? 6 : 0));
    const drillOffY: number = Math.sin(pc.movement.facing) * (8 + (pc.movement.isDrilling ? 6 : 0));
    const baseX: number = sx + drillOffX;
    const baseY: number = sy + drillOffY + bobY;
    const fAng: number = pc.movement.facing;
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
    const spiralSegs: number = pc.movement.isDrilling ? 5 : 3;
    for (let i: number = 1; i <= spiralSegs; i++) {
      const t: number = i / (spiralSegs + 1);
      const gx: number = baseX + Math.cos(fAng) * drillLen * t;
      const gy: number = baseY + Math.sin(fAng) * drillLen * t;
      const groovePhase: number = t * Math.PI * 2 + (pc.movement.isDrilling ? pc.frameCount * 0.3 : 0);
      const grooveOff: number = Math.sin(groovePhase) * 1.5;
      c.beginPath();
      c.moveTo(gx + perpX * grooveOff, gy + perpY * grooveOff);
      c.lineTo(gx - perpX * grooveOff, gy - perpY * grooveOff);
      c.stroke();
    }

    if (pc.movement.isDrilling) {
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

    if (pc.combat.isAttacking) {
      this.weaponRenderer.renderWeaponAttackEffect(c, sx, sy, pc, bobY);
    }
  }

  private renderEvolutionEffects(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number): void {
    const level: number = pc.evolution.evolutionLevel;
    if (level === EvolutionLevel.BASE) return;

    const branchColor: string = this.getEvoBranchColor(pc.evolution.evolutionBranch);
    const t: number = pc.frameCount * 0.05;

    if (level >= EvolutionLevel.LEVEL_1) {
      c.globalAlpha = 0.15 + Math.sin(t) * 0.05;
      c.fillStyle = branchColor;
      c.beginPath();
      c.arc(sx, sy + bobY, 12, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    if (level >= EvolutionLevel.LEVEL_2) {
      const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
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

  private getEvoBranchColor(branch: number): string {
    if (branch === 0) return '#00ced1'; // CRYSTAL
    if (branch === 1) return '#ff4500'; // FLAME
    if (branch === 2) return '#6b21a8'; // SHADOW
    if (branch === 3) return '#32cd32'; // TOXIN
    if (branch === 4) return '#4169e1'; // TIDE
    return '#ffffff';
  }
}
