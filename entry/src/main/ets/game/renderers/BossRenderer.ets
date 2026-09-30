import { World, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import {
  BossType, BossPhase, MaterialType,
  BOSS_SIZE,
  COLOR_CRYSTAL, COLOR_MUSHROOM_CAP, COLOR_LAVA_LIGHT,
  COLOR_BOSS_ABYSS, COLOR_BOSS_VOID,
  COLOR_BOSS_HP_BAR, COLOR_BOSS_HP_BG,
  GameSettings,
  getBossColor,
} from '../GameConstants';
import { BossAIComponent } from '../components/BossAIComponent';
import { MaterialPickupComponent } from '../components/MaterialPickupComponent';
import { BossFormsRenderer } from './BossFormsRenderer';

export class BossRenderer {
  private formsRenderer: BossFormsRenderer = new BossFormsRenderer();

  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number, cameraY: number, screenW: number, screenH: number, settings: GameSettings, frameCount: number): void {
    const offX: number = -cameraX;
    const offY: number = -cameraY;
    this.renderBosses(world, ctx, offX, offY, screenW, screenH, frameCount);
    this.renderMaterialDrops(world, ctx, offX, offY, screenW, screenH, frameCount);
  }

  renderHPBar(world: World, c: CanvasRenderingContext2D, screenW: number, screenH: number, frameCount: number): void {
    this.renderBossHPBar(world, c, screenW, screenH, frameCount);
  }

  private renderBosses(world: World, c: CanvasRenderingContext2D, offX: number, offY: number, screenW: number, screenH: number, frameCount: number): void {
    const bosses: Entity[] = world.queryWithTag('boss');
    for (let i: number = 0; i < bosses.length; i++) {
      const entity: Entity = bosses[i];
      if (!entity.active) continue;

      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      const health: HealthComponent | null = entity.getComponent<HealthComponent>('Health');
      const ai: BossAIComponent | null = entity.getComponent<BossAIComponent>('bossAI');
      if (pos === null || health === null || ai === null) continue;
      if (ai.defeated) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;

      if (screenX < -80 || screenX > screenW + 80 || screenY < -80 || screenY > screenH + 80) {
        continue;
      }

      const bossColor: string = getBossColor(ai.bossType);
      const halfSize: number = BOSS_SIZE / 2;
      const pulse: number = Math.sin(frameCount * 0.05) * 2;
      const t: number = frameCount;
      const hitFlash: number = ai.extraData.length > 0 ? ai.extraData[0] : 0;

      // Ground shadow for all bosses
      c.globalAlpha = 0.2;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, screenY + halfSize + 4, halfSize * 0.8, 4, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;

      if (hitFlash > 0) {
        c.globalAlpha = 0.5 + 0.5 * Math.sin(hitFlash * 0.05);
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(screenX, screenY, halfSize + 4, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      if (ai.bossType === BossType.CRYSTAL_GUARDIAN) {
        this.formsRenderer.renderCrystalGuardian(c, screenX, screenY, halfSize, pulse, bossColor, ai, t);
      } else if (ai.bossType === BossType.MUSHROOM_KING) {
        this.formsRenderer.renderMushroomKing(c, screenX, screenY, halfSize, pulse, bossColor, ai, t);
      } else if (ai.bossType === BossType.LAVA_BEAST) {
        this.formsRenderer.renderLavaBeast(c, screenX, screenY, halfSize, pulse, bossColor, ai, t);
      } else if (ai.bossType === BossType.ABYSS_SIREN) {
        this.formsRenderer.renderAbyssSiren(c, screenX, screenY, halfSize, pulse, bossColor, ai, t);
      } else if (ai.bossType === BossType.VOID_RIFT) {
        this.formsRenderer.renderVoidRift(c, screenX, screenY, halfSize, pulse, bossColor, ai, t);
      }

      // Phase 2 aura
      if (ai.phase === BossPhase.PHASE_2) {
        this.renderPhase2Aura(c, screenX, screenY, halfSize, pulse, bossColor, t);
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderPhase2Aura(c: CanvasRenderingContext2D, sx: number, sy: number,
    hs: number, pulse: number, color: string, t: number): void {
    // Pulsing double ring
    c.strokeStyle = color;
    c.lineWidth = 2;
    c.globalAlpha = 0.3 + 0.2 * Math.sin(t * 0.1);
    c.beginPath();
    c.arc(sx, sy, hs + 8 + pulse, 0, Math.PI * 2);
    c.stroke();

    c.lineWidth = 1.5;
    c.globalAlpha = 0.2 + 0.15 * Math.sin(t * 0.12 + 1);
    c.beginPath();
    c.arc(sx, sy, hs + 14 + pulse, 0, Math.PI * 2);
    c.stroke();

    // Energy crackling particles
    for (let p: number = 0; p < 6; p++) {
      const pAng: number = (p / 6) * Math.PI * 2 + t * 0.05;
      const pDist: number = hs + 10 + Math.sin(t * 0.08 + p * 3) * 4;
      const px: number = sx + Math.cos(pAng) * pDist;
      const py: number = sy + Math.sin(pAng) * pDist;
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.4 + Math.sin(t * 0.15 + p * 2) * 0.3;
      c.fillRect(px - 1, py - 1, 2, 2);
    }

    // Red/danger tint flash
    c.fillStyle = '#ff0000';
    c.globalAlpha = 0.03 + 0.02 * Math.sin(t * 0.08);
    c.beginPath();
    c.arc(sx, sy, hs + 16, 0, Math.PI * 2);
    c.fill();

    c.globalAlpha = 1.0;
    c.lineWidth = 1;
  }

  private renderMaterialDrops(world: World, c: CanvasRenderingContext2D, offX: number, offY: number, screenW: number, screenH: number, frameCount: number): void {
    const t: number = frameCount;

    // Render materialDrop entities
    const matEntities: Entity[] = world.queryWithTag('materialDrop');
    for (let i: number = 0; i < matEntities.length; i++) {
      const entity: Entity = matEntities[i];
      if (!entity.active) continue;

      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      const pickup: MaterialPickupComponent | null = entity.getComponent<MaterialPickupComponent>('materialPickup');
      if (pos === null || pickup === null) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;

      if (screenX < -20 || screenX > screenW + 20 || screenY < -20 || screenY > screenH + 20) {
        continue;
      }

      const bob: number = Math.sin(t * 0.06 + pickup.bobPhase) * 3;
      const drawY: number = screenY + bob;

      this.drawMaterialDrop(c, screenX, drawY, pickup.materialType, pickup.bobPhase, t);
    }

    // Render transformCore entities
    const coreEntities: Entity[] = world.queryWithTag('transformCore');
    for (let i: number = 0; i < coreEntities.length; i++) {
      const entity: Entity = coreEntities[i];
      if (!entity.active) continue;

      const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
      if (pos === null) continue;

      const screenX: number = pos.x + offX;
      const screenY: number = pos.y + offY;

      if (screenX < -20 || screenX > screenW + 20 || screenY < -20 || screenY > screenH + 20) {
        continue;
      }

      const bob: number = Math.sin(t * 0.06) * 3;
      const drawY: number = screenY + bob;

      // Transform cores render as FORM_CORE style
      this.drawMaterialDrop(c, screenX, drawY, MaterialType.FORM_CORE, 0, t);
    }

    c.globalAlpha = 1.0;
  }

  private drawMaterialDrop(c: CanvasRenderingContext2D, screenX: number, drawY: number, materialType: number, bobPhase: number, t: number): void {
    let color: string = '#ffffff';
    if (materialType === MaterialType.CRYSTAL_ORE) color = COLOR_CRYSTAL;
    else if (materialType === MaterialType.MUSHROOM_ORE) color = COLOR_MUSHROOM_CAP;
    else if (materialType === MaterialType.FLAME_ORE) color = COLOR_LAVA_LIGHT;
    else if (materialType === MaterialType.ABYSS_ORE) color = COLOR_BOSS_ABYSS;
    else if (materialType === MaterialType.VOID_ORE) color = COLOR_BOSS_VOID;
    else if (materialType === MaterialType.CORE_NORMAL) color = '#c0c0c0';
    else if (materialType === MaterialType.CORE_RARE) color = '#ffd700';
    else if (materialType === MaterialType.FORM_CORE) color = '#e879f9';

    const isCore: boolean = materialType === MaterialType.CORE_NORMAL ||
      materialType === MaterialType.CORE_RARE || materialType === MaterialType.FORM_CORE;

    // Outer glow
    c.globalAlpha = 0.25 + Math.sin(t * 0.08 + bobPhase) * 0.1;
    c.fillStyle = color;
    c.beginPath();
    c.arc(screenX, drawY, 10, 0, Math.PI * 2);
    c.fill();

    if (isCore) {
      // Core drops: round with inner glow and ring
      c.globalAlpha = 0.9;
      c.fillStyle = color;
      c.beginPath();
      c.arc(screenX, drawY, 5, 0, Math.PI * 2);
      c.fill();

      // Inner highlight
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.4;
      c.beginPath();
      c.arc(screenX - 1.5, drawY - 1.5, 2, 0, Math.PI * 2);
      c.fill();

      // Orbiting ring
      c.strokeStyle = color;
      c.lineWidth = 1;
      c.globalAlpha = 0.5;
      const ringAng: number = t * 0.06 + bobPhase;
      c.beginPath();
      c.ellipse(screenX, drawY, 7, 3, ringAng, 0, Math.PI * 2);
      c.stroke();

      // Sparkle
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.5 + Math.sin(t * 0.12 + bobPhase) * 0.3;
      const spAng: number = t * 0.05 + bobPhase;
      const spX: number = screenX + Math.cos(spAng) * 6;
      const spY: number = drawY + Math.sin(spAng) * 3;
      c.fillRect(spX - 0.5, spY - 0.5, 1, 1);
    } else {
      // Ore drops: diamond/crystal shape
      c.globalAlpha = 0.9;
      c.fillStyle = color;
      c.beginPath();
      c.moveTo(screenX, drawY - 5);
      c.lineTo(screenX + 4, drawY);
      c.lineTo(screenX, drawY + 5);
      c.lineTo(screenX - 4, drawY);
      c.closePath();
      c.fill();

      // Crystal edge highlight
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.3;
      c.beginPath();
      c.moveTo(screenX, drawY - 5);
      c.lineTo(screenX + 4, drawY);
      c.lineTo(screenX, drawY);
      c.closePath();
      c.fill();

      // Outline
      c.strokeStyle = '#ffffff';
      c.lineWidth = 0.8;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(screenX, drawY - 5);
      c.lineTo(screenX + 4, drawY);
      c.lineTo(screenX, drawY + 5);
      c.lineTo(screenX - 4, drawY);
      c.closePath();
      c.stroke();

      // Sparkle
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.4 + Math.sin(t * 0.1 + bobPhase * 2) * 0.3;
      c.fillRect(screenX - 1, drawY - 6, 1, 1);
    }
  }

  private renderBossHPBar(world: World, c: CanvasRenderingContext2D, screenW: number, screenH: number, frameCount: number): void {
    const bosses: Entity[] = world.queryWithTag('boss');
    let activeBossEntity: Entity | null = null;
    let activeBossAI: BossAIComponent | null = null;
    let activeBossHealth: HealthComponent | null = null;

    for (let i: number = 0; i < bosses.length; i++) {
      const entity: Entity = bosses[i];
      if (!entity.active) continue;
      const ai: BossAIComponent | null = entity.getComponent<BossAIComponent>('bossAI');
      const health: HealthComponent | null = entity.getComponent<HealthComponent>('Health');
      if (ai === null || health === null) continue;
      if (ai.defeated) continue;
      if (ai.active) {
        activeBossEntity = entity;
        activeBossAI = ai;
        activeBossHealth = health;
        break;
      }
    }

    if (activeBossAI === null || activeBossHealth === null) {
      // No active boss found
      return;
    }

    this.drawBossHPBar(c, activeBossAI, activeBossHealth, screenW, frameCount);
  }

  private drawBossHPBar(c: CanvasRenderingContext2D, ai: BossAIComponent, health: HealthComponent, screenW: number, frameCount: number): void {
    const barW: number = 220;
    const barH: number = 14;
    const barX: number = (screenW - barW) / 2;
    const barY: number = 22;
    const hpRatio: number = Math.max(0, health.current / health.max);
    const t: number = frameCount;

    // Boss name
    c.fillStyle = '#ffffff';
    c.font = '11px sans-serif';
    c.textAlign = 'center';
    c.globalAlpha = 0.9;
    let name: string = 'Boss';
    if (ai.bossType === BossType.CRYSTAL_GUARDIAN) name = '\u2666 Crystal Guardian';
    else if (ai.bossType === BossType.MUSHROOM_KING) name = '\u2654 Mushroom King';
    else if (ai.bossType === BossType.LAVA_BEAST) name = '\u2668 Lava Beast';
    else if (ai.bossType === BossType.ABYSS_SIREN) name = '\u2620 Abyss Siren';
    else if (ai.bossType === BossType.VOID_RIFT) name = '\u25CE Void Rift';
    if (ai.phase === BossPhase.PHASE_2) name += '  [Enraged]';
    c.fillText(name, screenW / 2, barY - 6);

    // Bar background with border
    c.fillStyle = '#0a0a14';
    c.globalAlpha = 0.85;
    c.fillRect(barX - 3, barY - 3, barW + 6, barH + 6);

    // Inner bg
    c.fillStyle = COLOR_BOSS_HP_BG;
    c.globalAlpha = 0.9;
    c.fillRect(barX - 1, barY - 1, barW + 2, barH + 2);

    // HP bar with gradient-like effect (two layers)
    const fillW: number = barW * hpRatio;
    if (fillW > 0) {
      // Bottom layer - darker
      let barColor1: string = COLOR_BOSS_HP_BAR;
      let barColor2: string = '#ff8888';
      if (ai.phase === BossPhase.PHASE_2) {
        barColor1 = '#ff4444';
        barColor2 = '#ff8800';
      }
      c.fillStyle = barColor1;
      c.globalAlpha = 1.0;
      c.fillRect(barX, barY, fillW, barH);

      // Top highlight stripe
      c.fillStyle = barColor2;
      c.globalAlpha = 0.4;
      c.fillRect(barX, barY, fillW, barH * 0.4);

      // Shimmer
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.1 + Math.sin(t * 0.06) * 0.05;
      c.fillRect(barX, barY, fillW, 2);
    }

    // Phase divider marks
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.2;
    c.fillRect(barX + barW * 0.25, barY, 1, barH);
    c.fillRect(barX + barW * 0.5, barY, 1, barH);
    c.fillRect(barX + barW * 0.75, barY, 1, barH);

    // Decorative corner brackets
    c.strokeStyle = '#ffffff';
    c.lineWidth = 1.5;
    c.globalAlpha = 0.5;
    const cornerLen: number = 6;
    // Top-left
    c.beginPath();
    c.moveTo(barX - 3, barY - 3 + cornerLen);
    c.lineTo(barX - 3, barY - 3);
    c.lineTo(barX - 3 + cornerLen, barY - 3);
    c.stroke();
    // Top-right
    c.beginPath();
    c.moveTo(barX + barW + 3 - cornerLen, barY - 3);
    c.lineTo(barX + barW + 3, barY - 3);
    c.lineTo(barX + barW + 3, barY - 3 + cornerLen);
    c.stroke();
    // Bottom-left
    c.beginPath();
    c.moveTo(barX - 3, barY + barH + 3 - cornerLen);
    c.lineTo(barX - 3, barY + barH + 3);
    c.lineTo(barX - 3 + cornerLen, barY + barH + 3);
    c.stroke();
    // Bottom-right
    c.beginPath();
    c.moveTo(barX + barW + 3 - cornerLen, barY + barH + 3);
    c.lineTo(barX + barW + 3, barY + barH + 3);
    c.lineTo(barX + barW + 3, barY + barH + 3 - cornerLen);
    c.stroke();

    // Enraged pulsing border
    if (ai.phase === BossPhase.PHASE_2) {
      c.strokeStyle = '#ff4444';
      c.lineWidth = 1;
      c.globalAlpha = 0.3 + 0.2 * Math.sin(t * 0.1);
      c.strokeRect(barX - 4, barY - 4, barW + 8, barH + 8);
    }

    c.globalAlpha = 1.0;
    c.lineWidth = 1;
  }
}
