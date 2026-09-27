import {
  PLAYER_MAX_HP, XP_ORB_SIZE, XP_COLLECT_RANGE, XP_MAGNET_RANGE, LEVEL_UP_XP,
  TRANSFORM_ENERGY_XP_ORB,
  PlayerState, XpOrb,
  COLOR_XP_ORB,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export class XpLevelSystem {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  update(dt: number): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;

    for (let i: number = 0; i < this.g.xpOrbs.length; i++) {
      const orb: XpOrb = this.g.xpOrbs[i];
      if (!orb.active) continue;

      orb.bobPhase += 0.08;

      const dx: number = p.x - orb.x;
      const dy: number = p.y - orb.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < XP_MAGNET_RANGE && dist > 1) {
        const pullSpeed: number = 3.0 * (1.0 - dist / XP_MAGNET_RANGE);
        orb.x += (dx / dist) * pullSpeed;
        orb.y += (dy / dist) * pullSpeed;
      }

      if (dist < XP_COLLECT_RANGE) {
        orb.active = false;
        p.xp += orb.value;
        if (p.isTransformed) {
          p.transformEnergy += TRANSFORM_ENERGY_XP_ORB;
          if (p.transformEnergy > p.transformMaxEnergy) {
            p.transformEnergy = p.transformMaxEnergy;
          }
        }
        this.g.audio.playXpCollect();
        if (p.xp >= LEVEL_UP_XP) {
          p.xp -= LEVEL_UP_XP;
          p.level++;
          if (p.hp < PLAYER_MAX_HP) p.hp++;
          this.g.audio.playLevelUp();
          if (this.g.settings.effectsEnabled) {
            this.g.particleMgr.magic(p.x, p.y, COLOR_XP_ORB);
          }
        }
      }
    }

    if (this.g.xpOrbs.length > 200) {
      const active: XpOrb[] = [];
      for (let i: number = 0; i < this.g.xpOrbs.length; i++) {
        if (this.g.xpOrbs[i].active) active.push(this.g.xpOrbs[i]);
      }
      this.g.xpOrbs = active;
    }
  }
}
