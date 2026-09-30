import {
  COLOR_DRILL_TIP,
  COLOR_PLAYER_BODY,
  COLOR_PLAYER_BODY_DARK,
  COLOR_PLAYER_FEMALE_BODY,
  COLOR_PLAYER_FEMALE_BODY_DARK,
  COLOR_PLAYER_FEMALE_HAIR,
  COLOR_PLAYER_HAIR,
  COLOR_PLAYER_SKIN,
  EvolutionLevel,
  PLAYER_SIZE,
  TransformForm,
  GameSettings,
} from '../GameConstants';
import { World, Entity, PositionComponent, VelocityComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { WeaponRenderer } from './WeaponRenderer';
import { TransformFormRenderer } from './TransformFormRenderer';
import { SpriteManager } from '../sprites/SpriteManager';
import { SpriteCache } from '../sprites/SpriteCache';

interface PComp {
  pos: PositionComponent;
  vel: VelocityComponent;
  movement: MovementComponent;
  combat: CombatComponent;
  transform: TransformComponent;
  evolution: EvolutionComponent;
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
    if (pos === null || vel === null || movement === null || combat === null || transform === null || evolution === null) return;
    const pc: PComp = {
      pos: pos,
      vel: vel,
      movement: movement,
      combat: combat,
      transform: transform,
      evolution: evolution,
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
      const engulfBodyColor: string = COLOR_PLAYER_BODY;
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

    // Determine sprite cache key
    const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
    const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;
    const dir: string = facingRight ? 'R' : 'L';
    let cachedBobY: number;

    if (spriteManager !== null && spriteManager.isReady()) {
      const playerCache: SpriteCache = spriteManager.getPlayerCache();
      let cacheKey: string;
      if (!isMoving) {
        cacheKey = `body_idle_${dir}`;
        cachedBobY = 0;
      } else {
        const walkFrame: number = Math.floor(((pc.combat.animFrame % (Math.PI * 2)) / (Math.PI * 2)) * 4) % 4;
        cacheKey = `body_walk_${dir}_${walkFrame}`;
        cachedBobY = Math.sin(walkFrame * Math.PI / 2) * 1.5;
      }

      const cachedFrame: OffscreenCanvas | undefined = playerCache.get(cacheKey);
      if (cachedFrame !== undefined) {
        c.drawImage(cachedFrame, screenX - 32, screenY - 32);
      } else {
        this.drawPlayerBodyProcedural(c, screenX, screenY, pc);
        cachedBobY = Math.sin(pc.combat.animFrame) * 1.5;
      }
    } else {
      this.drawPlayerBodyProcedural(c, screenX, screenY, pc);
      cachedBobY = Math.sin(pc.combat.animFrame) * 1.5;
    }

    this.renderDrill(c, screenX, screenY, pc, cachedBobY);
    this.weaponRenderer.renderWeaponOnPlayer(c, screenX, screenY, pc, cachedBobY);
    this.renderEvolutionEffects(c, screenX, screenY, pc, cachedBobY);
  }

  private drawPlayerBodyProcedural(c: CanvasRenderingContext2D, screenX: number, screenY: number, pc: PComp): void {
    const bobY: number = Math.sin(pc.combat.animFrame) * 1.5;
    const walkPhase: number = Math.sin(pc.combat.animFrame * 2);
    const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
    const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;

    const bodyColor: string = COLOR_PLAYER_BODY;
    const bodyDarkColor: string = COLOR_PLAYER_BODY_DARK;
    const hairColor: string = COLOR_PLAYER_HAIR;

    if (!pc.movement.isJumping) {
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
    const hairHighlight: string = '#9a5a3a';
    c.fillStyle = hairHighlight;
    c.fillRect(screenX - 4, screenY - 11 + bobY, 2, 1);
    c.fillRect(screenX + 1, screenY - 12 + bobY, 3, 1);
    c.fillRect(screenX - 2, screenY - 10 + bobY, 1, 2);
    c.fillStyle = '#4a2a10';
    c.fillRect(screenX - 3, screenY - 9 + bobY, 1, 3);
    c.fillRect(screenX + 3, screenY - 10 + bobY, 1, 2);
    c.fillRect(screenX, screenY - 11 + bobY, 1, 1);

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
