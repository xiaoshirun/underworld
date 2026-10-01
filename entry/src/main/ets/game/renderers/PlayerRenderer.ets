import {
  COLOR_DRILL_TIP,
  COLOR_SLIME_BLUE,
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
import { drawPlayerSlimeBody } from '../sprites/PlayerSlimeSprite';
import { SpriteManager } from '../sprites/SpriteManager';
import { SpriteAtlas, FrameCoord } from '../sprites/SpriteAtlas';
import { SpriteCache } from '../sprites/SpriteCache';
import { DrawCmdBuffer } from '../../native/DrawCmd';

function hexToRgb(hex: string): number[] {
  const h: string = hex.replace('#', '');
  const r: number = parseInt(h.substring(0, 2), 16) / 255;
  const g: number = parseInt(h.substring(2, 4), 16) / 255;
  const b: number = parseInt(h.substring(4, 6), 16) / 255;
  return [r, g, b];
}

export interface PComp {
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

  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number, cameraY: number, screenW: number, screenH: number, settings: GameSettings, frameCount: number, spriteManager: SpriteManager | null = null): void {
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
    this.renderPlayer(ctx, offX, offY, pc, spriteManager);
  }

  private renderPlayer(c: CanvasRenderingContext2D, offX: number, offY: number, pc: PComp, spriteManager: SpriteManager | null = null): void {
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
      this.renderHumanForm(c, screenX, screenY, pc, spriteManager);
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
    this.renderSlimeBody(c, screenX, screenY, pc, bobY, spriteManager);
    this.renderDrill(c, screenX, screenY, pc, bobY);
    this.renderEvolutionEffects(c, screenX, screenY, pc, bobY);
  }

  private renderSlimeBody(c: CanvasRenderingContext2D, screenX: number, screenY: number, pc: PComp, bobY: number, spriteManager: SpriteManager | null = null): void {
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

    const slimeAtlas: SpriteAtlas | null = spriteManager !== null ? spriteManager.getPlayerSlimeAtlas() : null;
    if (slimeAtlas !== null) {
      const bounceFrame: number = Math.floor(((pc.frameCount * 0.12) % (Math.PI * 2)) / (Math.PI * 2) * 8) % 8;
      const frameIndex: number = (facingRight ? 0 : 8) + bounceFrame;
      const frame: FrameCoord = slimeAtlas.getFrame(frameIndex);
      const drawSize: number = 32;
      c.drawImage(slimeAtlas.imageBitmap, frame.sx, frame.sy, slimeAtlas.cellW, slimeAtlas.cellH,
                  screenX - drawSize / 2, screenY + bobY - drawSize / 2, drawSize, drawSize);
    } else {
      drawPlayerSlimeBody(c, screenX, screenY + bobY, bodyW, bodyH, facingRight);
    }
  }

  private renderHumanForm(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, spriteManager: SpriteManager | null = null): void {
    const stage: HumanFormStage = pc.humanForm.humanFormStage as HumanFormStage;
    const bobY: number = Math.sin(pc.frameCount * 0.06) * 1.5;
    const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;
    const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;

    const playerCache: SpriteCache | null = spriteManager !== null && spriteManager.isReady() ? spriteManager.getPlayerCache() : null;
    if (playerCache !== null && playerCache.size() > 0) {
      this.renderHumanFormSprite(c, sx, sy, pc, stage, bobY, facingRight, isMoving, playerCache);
    } else if (stage === HumanFormStage.PROTO) {
      this.renderHumanProto(c, sx, sy, pc, bobY, facingRight);
    } else if (stage === HumanFormStage.PHANTOM) {
      this.renderHumanPhantom(c, sx, sy, pc, bobY, facingRight);
    } else if (stage === HumanFormStage.ARMORED) {
      this.renderHumanArmored(c, sx, sy, pc, bobY, facingRight);
    } else if (stage === HumanFormStage.COMPLETE) {
      this.renderHumanComplete(c, sx, sy, pc, bobY, facingRight);
    }
  }

  private renderHumanFormSprite(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp,
      stage: HumanFormStage, bobY: number, facingRight: boolean, isMoving: boolean, playerCache: SpriteCache): void {
    const dir: string = facingRight ? 'R' : 'L';
    let key: string;
    if (isMoving) {
      const walkPhase: number = Math.floor((pc.frameCount * 0.15 / (Math.PI * 2)) * 4) % 4;
      key = `body_walk_${dir}_${walkPhase}`;
    } else {
      key = `body_idle_${dir}`;
    }
    const frame: ImageBitmap | undefined = playerCache.get(key);
    if (frame === undefined) {
      if (stage === HumanFormStage.PROTO) {
        this.renderHumanProto(c, sx, sy, pc, bobY, facingRight);
      } else if (stage === HumanFormStage.PHANTOM) {
        this.renderHumanPhantom(c, sx, sy, pc, bobY, facingRight);
      } else if (stage === HumanFormStage.ARMORED) {
        this.renderHumanArmored(c, sx, sy, pc, bobY, facingRight);
      } else {
        this.renderHumanComplete(c, sx, sy, pc, bobY, facingRight);
      }
      return;
    }

    const frameW: number = 64;
    const frameH: number = 64;
    const drawW: number = 32;
    const drawH: number = 32;

    if (stage === HumanFormStage.PROTO) {
      c.globalAlpha = 0.4 + Math.sin(pc.frameCount * 0.1) * 0.1;
    } else if (stage === HumanFormStage.PHANTOM) {
      c.globalAlpha = 0.55 + Math.sin(pc.frameCount * 0.08) * 0.1;
    } else {
      c.globalAlpha = 1.0;
    }

    c.drawImage(frame, 0, 0, frameW, frameH, sx - drawW / 2, sy + bobY - drawH / 2, drawW, drawH);
    c.globalAlpha = 1.0;

    if (stage === HumanFormStage.PHANTOM) {
      const t: number = pc.frameCount * 0.08;
      c.globalAlpha = 0.15;
      c.fillStyle = '#a0c4e8';
      for (let i: number = 0; i < 3; i++) {
        const trailY: number = sy + 8 + i * 4 + Math.sin(t + i) * 2;
        c.beginPath();
        c.ellipse(sx + Math.sin(t + i * 0.5) * 2, trailY + bobY, 5 - i, 3, 0, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 0.1;
      c.fillStyle = '#60a5fa';
      c.beginPath();
      c.arc(sx, sy + bobY, 18, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    if (stage === HumanFormStage.COMPLETE) {
      const t: number = pc.frameCount * 0.05;
      c.globalAlpha = 0.15 + Math.sin(t) * 0.05;
      c.fillStyle = '#60a5fa';
      c.beginPath();
      c.arc(sx, sy + bobY, 22, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.6 + Math.sin(t * 2) * 0.2;
      c.beginPath();
      c.arc(sx, sy - 1 + bobY, 2, 0, Math.PI * 2);
      c.fill();
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

  // ── New DrawCmd pipeline ──────────────────────────────────────────

  collectCommands(world: World, buf: DrawCmdBuffer, cameraX: number, cameraY: number, screenW: number, screenH: number, settings: GameSettings, frameCount: number, spriteManager: SpriteManager | null = null): void {
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
      pos: pos, vel: vel, movement: movement, combat: combat,
      transform: transform, evolution: evolution, humanForm: humanForm,
      frameCount: frameCount, transformAnimIsRevert: transform.transformForm === -1,
    };
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    this.collectPlayerCommands(buf, offX, offY, pc, spriteManager);
  }

  private collectPlayerCommands(buf: DrawCmdBuffer, offX: number, offY: number, pc: PComp, spriteManager: SpriteManager | null = null): void {
    const screenX: number = pc.pos.x + offX;
    const screenY: number = pc.pos.y + offY - pc.movement.jumpHeight;
    const half: number = PLAYER_SIZE / 2;

    if (pc.movement.isEngulfed) {
      const ec: number[] = hexToRgb(COLOR_SLIME_BLUE);
      buf.pushCircle(screenX, screenY, half * 0.6, ec[0], ec[1], ec[2], 0.5 + Math.sin(pc.frameCount * 0.2) * 0.3, 0, 0);
      return;
    }

    if (pc.combat.invincibleTimer > 0 && Math.floor(pc.frameCount / 3) % 2 === 0) return;

    if (pc.humanForm.isHumanForm) {
      this.collectHumanFormCommands(buf, screenX, screenY, pc, spriteManager);
      return;
    }

    if (pc.transform.isTransformed) {
      const bobY: number = pc.movement.isJumping ? -pc.movement.jumpHeight : Math.sin(pc.frameCount * 0.08) * 1.5;
      if ((pc.transform.transformForm as TransformForm) === TransformForm.SLIME) {
        this.transformRenderer.collectSlimeFormCommands(buf, screenX, screenY, pc, bobY);
      } else if ((pc.transform.transformForm as TransformForm) === TransformForm.GHOST) {
        this.transformRenderer.collectGhostFormCommands(buf, screenX, screenY, pc, bobY);
      } else if ((pc.transform.transformForm as TransformForm) === TransformForm.ARMOR) {
        this.transformRenderer.collectArmorFormCommands(buf, screenX, screenY, pc, bobY);
      } else if ((pc.transform.transformForm as TransformForm) === TransformForm.IRON_MAN) {
        this.transformRenderer.collectIronManFormCommands(buf, screenX, screenY, pc, bobY);
      }
      if (pc.transform.transformAnimTimer > 0) {
        this.transformRenderer.collectTransformAnimCommands(buf, screenX, screenY, pc);
      }
      return;
    }

    if (pc.movement.isJumping) {
      buf.pushCircle(screenX, pc.pos.y + offY + half, half * 0.55, 0, 0, 0, 0.25, 0, 0);
    }

    const bobY: number = pc.movement.isJumping ? -pc.movement.jumpHeight : Math.sin(pc.frameCount * 0.08) * 1.5;
    this.collectSlimeBodyCommands(buf, screenX, screenY, pc, bobY, spriteManager);
    this.weaponRenderer.collectWeaponOnPlayerCommands(buf, screenX, screenY, pc, bobY);
    this.collectDrillCommands(buf, screenX, screenY, pc, bobY);
    this.collectEvolutionCommands(buf, screenX, screenY, pc, bobY);
    if (pc.combat.isAttacking) {
      this.weaponRenderer.collectAttackEffectCommands(buf, screenX, screenY, pc, bobY);
    }
  }

  private collectSlimeBodyCommands(buf: DrawCmdBuffer, screenX: number, screenY: number, pc: PComp, bobY: number, spriteManager: SpriteManager | null = null): void {
    const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
    const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;
    const squish: number = isMoving ? Math.sin(pc.frameCount * 0.15) * 1.5 : Math.sin(pc.frameCount * 0.05) * 0.8;
    const bodyW: number = 12 + squish;
    const bodyH: number = 10 - squish * 0.5;

    if (!pc.movement.isJumping) {
      buf.pushCircle(screenX, screenY + bodyH * 0.5 + bobY, bodyW * 0.45, 0, 0, 0, 0.25, 0, 0);
    }

    // Use sprite atlas or procedural fallback
    const slimeAtlas: SpriteAtlas | null = spriteManager !== null ? spriteManager.getPlayerSlimeAtlas() : null;
    if (slimeAtlas !== null) {
      const bounceFrame: number = Math.floor(((pc.frameCount * 0.12) % (Math.PI * 2)) / (Math.PI * 2) * 8) % 8;
      const frameIndex: number = (facingRight ? 0 : 8) + bounceFrame;
      const frame: FrameCoord = slimeAtlas.getFrame(frameIndex);
      const drawSize: number = 32;
      buf.pushSprite(0, screenX - drawSize / 2, screenY + bobY - drawSize / 2, drawSize, drawSize,
        frame.sx, frame.sy, slimeAtlas.cellW, slimeAtlas.cellH, 1, 1, 1, 1, 0, 0, facingRight ? 0 : 1, 0);
    } else {
      const slimeC: number[] = hexToRgb(COLOR_SLIME_BLUE);
      buf.pushCircle(screenX, screenY + bobY, bodyW * 0.5, slimeC[0], slimeC[1], slimeC[2], 0.9, 0, 0);
      buf.pushCircle(screenX, screenY + bobY - bodyH * 0.3, bodyW * 0.35, slimeC[0] * 1.15, slimeC[1] * 1.15, slimeC[2] * 1.15, 0.7, 0, 0);
      // Eyes
      const eyeOffX: number = facingRight ? 2 : -2;
      buf.pushCircle(screenX + eyeOffX - 2, screenY + bobY - 2, 1.5, 1, 1, 1, 0.9, 0, 0);
      buf.pushCircle(screenX + eyeOffX + 2, screenY + bobY - 2, 1.5, 1, 1, 1, 0.9, 0, 0);
      buf.pushCircle(screenX + eyeOffX - 2, screenY + bobY - 2, 0.7, 0, 0, 0, 1, 0, 0);
      buf.pushCircle(screenX + eyeOffX + 2, screenY + bobY - 2, 0.7, 0, 0, 0, 1, 0, 0);
    }
  }

  private collectHumanFormCommands(buf: DrawCmdBuffer, sx: number, sy: number, pc: PComp, spriteManager: SpriteManager | null = null): void {
    const stage: HumanFormStage = pc.humanForm.humanFormStage as HumanFormStage;
    const bobY: number = Math.sin(pc.frameCount * 0.06) * 1.5;
    const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;

    // Try sprite path
    const playerCache: SpriteCache | null = spriteManager !== null && spriteManager.isReady() ? spriteManager.getPlayerCache() : null;
    if (playerCache !== null && playerCache.size() > 0) {
      const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
      const dir: string = facingRight ? 'R' : 'L';
      const key: string = isMoving ? `body_walk_${dir}_${Math.floor((pc.frameCount * 0.15 / (Math.PI * 2)) * 4) % 4}` : `body_idle_${dir}`;
      const frame: ImageBitmap | undefined = playerCache.get(key);
      if (frame !== undefined) {
        let alpha: number = 1.0;
        if (stage === HumanFormStage.PROTO) alpha = 0.4 + Math.sin(pc.frameCount * 0.1) * 0.1;
        else if (stage === HumanFormStage.PHANTOM) alpha = 0.55 + Math.sin(pc.frameCount * 0.08) * 0.1;
        buf.pushSprite(0, sx - 16, sy + bobY - 16, 32, 32, 0, 0, 64, 64, 1, 1, 1, alpha, 0, 0, facingRight ? 0 : 1, 0);
      } else {
        this.collectHumanFormProcedural(buf, sx, sy, pc, stage, bobY, facingRight);
      }
    } else {
      this.collectHumanFormProcedural(buf, sx, sy, pc, stage, bobY, facingRight);
    }
  }

  private collectHumanFormProcedural(buf: DrawCmdBuffer, sx: number, sy: number, pc: PComp, stage: HumanFormStage, bobY: number, facingRight: boolean): void {
    const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
    const walkPhase: number = isMoving ? Math.sin(pc.frameCount * 0.15) * 3 : 0;
    const t: number = pc.frameCount * 0.08;

    if (stage === HumanFormStage.PROTO) {
      const alpha: number = 0.4 + Math.sin(pc.frameCount * 0.1) * 0.1;
      const bodyC: number[] = hexToRgb('#8bb4d6');
      buf.pushRect(sx - 4, sy - 6 + bobY, 8, 12, bodyC[0], bodyC[1], bodyC[2], alpha, 0, 0);
      buf.pushCircle(sx, sy - 10 + bobY, 4, bodyC[0], bodyC[1], bodyC[2], alpha, 0, 0);
      buf.pushRect(sx - 3, sy + 6 + bobY, 2, 6, bodyC[0], bodyC[1], bodyC[2], alpha, 0, 0);
      buf.pushRect(sx + 1, sy + 6 + bobY, 2, 6, bodyC[0], bodyC[1], bodyC[2], alpha, 0, 0);
      buf.pushRect(sx - 7, sy - 4 + bobY, 3, 8, bodyC[0], bodyC[1], bodyC[2], alpha, 0, 0);
      buf.pushRect(sx + 4, sy - 4 + bobY, 3, 8, bodyC[0], bodyC[1], bodyC[2], alpha, 0, 0);
      buf.pushRect(sx - 2, sy - 11 + bobY, 2, 2, 1, 1, 1, 0.7, 0, 0);
      buf.pushRect(sx + 1, sy - 11 + bobY, 2, 2, 1, 1, 1, 0.7, 0, 0);
    } else if (stage === HumanFormStage.PHANTOM) {
      // Ghost trail
      const trailC: number[] = hexToRgb('#a0c4e8');
      for (let i: number = 0; i < 3; i++) {
        const trailY: number = sy + 8 + i * 4 + Math.sin(t + i) * 2;
        buf.pushCircle(sx + Math.sin(t + i * 0.5) * 2, trailY + bobY, 4 - i * 0.5, trailC[0], trailC[1], trailC[2], 0.15, 0, 0);
      }
      const bodyC: number[] = hexToRgb('#7db8e0');
      const alpha: number = 0.55 + Math.sin(t) * 0.1;
      buf.pushRect(sx - 5, sy - 6 + bobY, 10, 14, bodyC[0], bodyC[1], bodyC[2], alpha, 0, 0);
      buf.pushCircle(sx, sy - 10 + bobY, 5, bodyC[0], bodyC[1], bodyC[2], alpha, 0, 0);
      buf.pushRect(sx - 3, sy + 8 + bobY, 2, 5, bodyC[0], bodyC[1], bodyC[2], 0.35, 0, 0);
      buf.pushRect(sx + 1, sy + 8 + bobY, 2, 5, bodyC[0], bodyC[1], bodyC[2], 0.35, 0, 0);
      buf.pushRect(sx - 8, sy - 4 + bobY, 3, 9, bodyC[0], bodyC[1], bodyC[2], 0.45, 0, 0);
      buf.pushRect(sx + 5, sy - 4 + bobY, 3, 9, bodyC[0], bodyC[1], bodyC[2], 0.45, 0, 0);
      buf.pushCircle(sx - 2, sy - 10 + bobY, 1.5, 1, 1, 1, 0.9, 0, 0);
      buf.pushCircle(sx + 2, sy - 10 + bobY, 1.5, 1, 1, 1, 0.9, 0, 0);
      buf.pushCircle(sx, sy + bobY, 18, 0.376, 0.647, 0.98, 0.1, 0, 0);
    } else if (stage === HumanFormStage.ARMORED) {
      const shadowC: number[] = [0, 0, 0];
      buf.pushCircle(sx, sy + 14 + bobY, 5.5, shadowC[0], shadowC[1], shadowC[2], 0.3, 0, 0);
      const legC: number[] = hexToRgb('#4b5563');
      buf.pushRect(sx - 4, sy + 6 + bobY + walkPhase, 3, 8, legC[0], legC[1], legC[2], 1, 0, 0);
      buf.pushRect(sx + 1, sy + 6 + bobY - walkPhase, 3, 8, legC[0], legC[1], legC[2], 1, 0, 0);
      const bootC: number[] = hexToRgb('#374151');
      buf.pushRect(sx - 5, sy + 12 + bobY + walkPhase, 4, 2, bootC[0], bootC[1], bootC[2], 1, 0, 0);
      buf.pushRect(sx + 1, sy + 12 + bobY - walkPhase, 4, 2, bootC[0], bootC[1], bootC[2], 1, 0, 0);
      const armorC: number[] = hexToRgb('#6b7280');
      buf.pushRect(sx - 6, sy - 6 + bobY, 12, 13, armorC[0], armorC[1], armorC[2], 1, 0, 0);
      const hiC: number[] = hexToRgb('#9ca3af');
      buf.pushRect(sx - 5, sy - 5 + bobY, 10, 3, hiC[0], hiC[1], hiC[2], 1, 0, 0);
      const beltC: number[] = hexToRgb('#92400e');
      buf.pushRect(sx - 6, sy + 4 + bobY, 12, 2, beltC[0], beltC[1], beltC[2], 1, 0, 0);
      const buckleC: number[] = hexToRgb('#fbbf24');
      buf.pushRect(sx - 1, sy + 4 + bobY, 2, 2, buckleC[0], buckleC[1], buckleC[2], 1, 0, 0);
      buf.pushRect(sx - 9, sy - 4 + bobY, 3, 9, armorC[0], armorC[1], armorC[2], 1, 0, 0);
      buf.pushRect(sx + 6, sy - 4 + bobY, 3, 9, armorC[0], armorC[1], armorC[2], 1, 0, 0);
      buf.pushRect(sx - 9, sy + 3 + bobY, 3, 3, legC[0], legC[1], legC[2], 1, 0, 0);
      buf.pushRect(sx + 6, sy + 3 + bobY, 3, 3, legC[0], legC[1], legC[2], 1, 0, 0);
      buf.pushCircle(sx, sy - 10 + bobY, 5, armorC[0], armorC[1], armorC[2], 1, 0, 0);
      const visorC: number[] = hexToRgb('#1e3a5f');
      buf.pushRect(sx - 3, sy - 11 + bobY, 6, 3, visorC[0], visorC[1], visorC[2], 1, 0, 0);
      const eyeC: number[] = hexToRgb('#60a5fa');
      buf.pushRect(sx - 2, sy - 10 + bobY, 2, 1, eyeC[0], eyeC[1], eyeC[2], 1, 0, 0);
      buf.pushRect(sx + 1, sy - 10 + bobY, 2, 1, eyeC[0], eyeC[1], eyeC[2], 1, 0, 0);
    } else {
      // COMPLETE stage
      const t2: number = pc.frameCount * 0.05;
      buf.pushCircle(sx, sy + bobY, 22, 0.376, 0.647, 0.98, 0.15 + Math.sin(t2) * 0.05, 0, 0);
      buf.pushCircle(sx, sy + 14 + bobY, 6, 0, 0, 0, 0.35, 0, 0);
      const legC: number[] = hexToRgb('#374151');
      buf.pushRect(sx - 4, sy + 6 + bobY + walkPhase, 3, 8, legC[0], legC[1], legC[2], 1, 0, 0);
      buf.pushRect(sx + 1, sy + 6 + bobY - walkPhase, 3, 8, legC[0], legC[1], legC[2], 1, 0, 0);
      const glowC: number[] = hexToRgb('#60a5fa');
      buf.pushRect(sx - 3, sy + 7 + bobY + walkPhase, 1, 6, glowC[0], glowC[1], glowC[2], 0.5, 0, 0);
      buf.pushRect(sx + 2, sy + 7 + bobY - walkPhase, 1, 6, glowC[0], glowC[1], glowC[2], 0.5, 0, 0);
      const bootC: number[] = hexToRgb('#1f2937');
      buf.pushRect(sx - 5, sy + 12 + bobY + walkPhase, 4, 2, bootC[0], bootC[1], bootC[2], 1, 0, 0);
      buf.pushRect(sx + 1, sy + 12 + bobY - walkPhase, 4, 2, bootC[0], bootC[1], bootC[2], 1, 0, 0);
      const bodyC: number[] = hexToRgb('#4b5563');
      buf.pushRect(sx - 7, sy - 6 + bobY, 14, 13, bodyC[0], bodyC[1], bodyC[2], 1, 0, 0);
      const chestC: number[] = hexToRgb('#6b7280');
      buf.pushRect(sx - 6, sy - 5 + bobY, 12, 4, chestC[0], chestC[1], chestC[2], 1, 0, 0);
      buf.pushCircle(sx, sy - 1 + bobY, 2, glowC[0], glowC[1], glowC[2], 0.6 + Math.sin(t2 * 2) * 0.2, 0, 0);
      const beltC: number[] = hexToRgb('#78350f');
      buf.pushRect(sx - 7, sy + 4 + bobY, 14, 2, beltC[0], beltC[1], beltC[2], 1, 0, 0);
      const buckleC: number[] = hexToRgb('#fbbf24');
      buf.pushRect(sx - 1, sy + 4 + bobY, 2, 2, buckleC[0], buckleC[1], buckleC[2], 1, 0, 0);
      buf.pushRect(sx - 10, sy - 4 + bobY, 3, 10, bodyC[0], bodyC[1], bodyC[2], 1, 0, 0);
      buf.pushRect(sx + 7, sy - 4 + bobY, 3, 10, bodyC[0], bodyC[1], bodyC[2], 1, 0, 0);
      buf.pushRect(sx - 9, sy - 3 + bobY, 1, 8, glowC[0], glowC[1], glowC[2], 0.4, 0, 0);
      buf.pushRect(sx + 8, sy - 3 + bobY, 1, 8, glowC[0], glowC[1], glowC[2], 0.4, 0, 0);
      buf.pushRect(sx - 10, sy + 4 + bobY, 3, 3, legC[0], legC[1], legC[2], 1, 0, 0);
      buf.pushRect(sx + 7, sy + 4 + bobY, 3, 3, legC[0], legC[1], legC[2], 1, 0, 0);
      buf.pushCircle(sx, sy - 10 + bobY, 6, bodyC[0], bodyC[1], bodyC[2], 1, 0, 0);
      buf.pushRect(sx - 1, sy - 16 + bobY, 2, 4, glowC[0], glowC[1], glowC[2], 1, 0, 0);
      const visorC: number[] = hexToRgb('#1e3a5f');
      buf.pushRect(sx - 4, sy - 11 + bobY, 8, 3, visorC[0], visorC[1], visorC[2], 1, 0, 0);
      buf.pushRect(sx - 3, sy - 10 + bobY, 2, 1, glowC[0], glowC[1], glowC[2], 1, 0, 0);
      buf.pushRect(sx + 1, sy - 10 + bobY, 2, 1, glowC[0], glowC[1], glowC[2], 1, 0, 0);
      buf.pushCircle(sx - 2, sy - 10 + bobY, 3, glowC[0], glowC[1], glowC[2], 0.3, 0, 0);
      buf.pushCircle(sx + 2, sy - 10 + bobY, 3, glowC[0], glowC[1], glowC[2], 0.3, 0, 0);
      for (let i: number = 0; i < 4; i++) {
        const angle: number = t2 * 2 + (i * Math.PI * 2 / 4);
        const orbR: number = 16;
        buf.pushCircle(sx + Math.cos(angle) * orbR, sy + bobY + Math.sin(angle) * orbR, 1.5, glowC[0], glowC[1], glowC[2], 0.5, 0, 0);
      }
    }
  }

  private collectDrillCommands(buf: DrawCmdBuffer, sx: number, sy: number, pc: PComp, bobY: number): void {
    const drillLen: number = pc.movement.isDrilling ? 14 : 8;
    const drillOffX: number = Math.cos(pc.movement.facing) * (8 + (pc.movement.isDrilling ? 6 : 0));
    const drillOffY: number = Math.sin(pc.movement.facing) * (8 + (pc.movement.isDrilling ? 6 : 0));
    const baseX: number = sx + drillOffX;
    const baseY: number = sy + drillOffY + bobY;
    const fAng: number = pc.movement.facing;

    const baseC: number[] = hexToRgb('#6b7280');
    buf.pushRect(baseX - 3, baseY - 3, 6, 6, baseC[0], baseC[1], baseC[2], 1, 0, 0);
    const hiC: number[] = hexToRgb('#9ca3af');
    buf.pushRect(baseX - 3, baseY - 3, 6, 2, hiC[0], hiC[1], hiC[2], 1, 0, 0);
    const loC: number[] = hexToRgb('#4b5563');
    buf.pushRect(baseX - 3, baseY + 1, 6, 2, loC[0], loC[1], loC[2], 1, 0, 0);
    const screwC: number[] = hexToRgb('#374151');
    buf.pushRect(baseX - 2, baseY - 2, 1, 1, screwC[0], screwC[1], screwC[2], 1, 0, 0);
    buf.pushRect(baseX + 1, baseY - 2, 1, 1, screwC[0], screwC[1], screwC[2], 1, 0, 0);
    buf.pushRect(baseX - 2, baseY + 1, 1, 1, screwC[0], screwC[1], screwC[2], 1, 0, 0);
    buf.pushRect(baseX + 1, baseY + 1, 1, 1, screwC[0], screwC[1], screwC[2], 1, 0, 0);

    const tipX: number = baseX + Math.cos(fAng) * drillLen;
    const tipY: number = baseY + Math.sin(fAng) * drillLen;
    const drillC: number[] = hexToRgb(COLOR_DRILL_TIP);
    buf.pushLine(baseX, baseY, tipX, tipY, 3, drillC[0], drillC[1], drillC[2], 1, 0);
    const highlightC: number[] = hexToRgb('#fde68a');
    const perpX: number = -Math.sin(fAng);
    const perpY: number = Math.cos(fAng);
    buf.pushLine(baseX + perpX, baseY + perpY, tipX + perpX, tipY + perpY, 1, highlightC[0], highlightC[1], highlightC[2], 1, 0);

    const grooveC: number[] = hexToRgb('#b45309');
    const spiralSegs: number = pc.movement.isDrilling ? 5 : 3;
    for (let i: number = 1; i <= spiralSegs; i++) {
      const t: number = i / (spiralSegs + 1);
      const gx: number = baseX + Math.cos(fAng) * drillLen * t;
      const gy: number = baseY + Math.sin(fAng) * drillLen * t;
      const groovePhase: number = t * Math.PI * 2 + (pc.movement.isDrilling ? pc.frameCount * 0.3 : 0);
      const grooveOff: number = Math.sin(groovePhase) * 1.5;
      buf.pushLine(gx + perpX * grooveOff, gy + perpY * grooveOff, gx - perpX * grooveOff, gy - perpY * grooveOff, 1, grooveC[0], grooveC[1], grooveC[2], 1, 0);
    }

    if (pc.movement.isDrilling) {
      buf.pushCircle(tipX, tipY, 5, 1, 0.42, 0, 0.5, 0, 0);
      buf.pushCircle(tipX, tipY, 2, 1, 0.667, 0, 0.8, 0, 0);
    }
  }

  private collectEvolutionCommands(buf: DrawCmdBuffer, sx: number, sy: number, pc: PComp, bobY: number): void {
    const level: number = pc.evolution.evolutionLevel;
    if (level === EvolutionLevel.BASE) return;

    const branchColor: string = this.getEvoBranchColor(pc.evolution.evolutionBranch);
    const bc: number[] = hexToRgb(branchColor);
    const t: number = pc.frameCount * 0.05;

    if (level >= EvolutionLevel.LEVEL_1) {
      buf.pushCircle(sx, sy + bobY, 12, bc[0], bc[1], bc[2], 0.15 + Math.sin(t) * 0.05, 0, 0);
    }

    if (level >= EvolutionLevel.LEVEL_2) {
      const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
      if (isMoving) {
        for (let i: number = 0; i < 2; i++) {
          const px: number = sx + (Math.random() - 0.5) * 8;
          const py: number = sy + bobY + 6 + Math.random() * 4;
          buf.pushCircle(px, py, 1.5, bc[0], bc[1], bc[2], 0.4, 0, 0);
        }
      }
    }

    if (level >= EvolutionLevel.LEVEL_3) {
      buf.pushCircle(sx, sy + bobY, 16 + Math.sin(t * 0.8) * 2, bc[0], bc[1], bc[2], 0.2, 0, 0);
      for (let i: number = 0; i < 3; i++) {
        const angle: number = t * 2 + (i * Math.PI * 2 / 3);
        const orbR: number = 14;
        buf.pushCircle(sx + Math.cos(angle) * orbR, sy + bobY + Math.sin(angle) * orbR, 1.5, bc[0], bc[1], bc[2], 0.6, 0, 0);
      }
    }
  }
}
