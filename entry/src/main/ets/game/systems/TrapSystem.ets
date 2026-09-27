import {
  INVINCIBLE_DURATION,
  TRAP_TELEGRAPH_TIME, TRAP_ACTIVE_TIME, TRAP_COOLDOWN_TIME,
  TrapState, TrapType, PlayerState, TrapInstance, TransformForm,
  COLOR_DAMAGE_PARTICLE,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export class TrapSystem {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  update(dt: number): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;

    for (let i: number = 0; i < this.g.traps.length; i++) {
      const trap: TrapInstance = this.g.traps[i];
      const dx: number = p.x - trap.x;
      const dy: number = p.y - trap.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (trap.state) {
        case TrapState.IDLE:
          if (dist < trap.triggerRadius) {
            trap.state = TrapState.TELEGRAPH;
            trap.timer = TRAP_TELEGRAPH_TIME;
          }
          break;

        case TrapState.TELEGRAPH:
          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.ACTIVE;
            trap.timer = TRAP_ACTIVE_TIME;
            this.g.audio.playPlayerDamage();
          }
          break;

        case TrapState.ACTIVE:
          trap.timer -= dt;
          if (trap.trapType === TrapType.VOID_CRACK && dist < trap.triggerRadius * 1.5) {
            const pullStrength: number = 0.8 * (1.0 - dist / (trap.triggerRadius * 1.5));
            p.vx -= (dx / dist) * pullStrength;
            p.vy -= (dy / dist) * pullStrength;
          }
          if (dist < trap.size) {
            if (p.invincibleTimer <= 0) {
              if (p.isTransformed && p.transformForm === TransformForm.IRON_MAN) {
                // Iron Man hovers — immune to ground traps
              } else {
                p.hp -= trap.damage;
                p.invincibleTimer = INVINCIBLE_DURATION;
                this.g.shakeTimer = 150;
                this.g.damageFlashTimer = 200;
                if (this.g.settings.effectsEnabled) {
                  this.g.particleMgr.sparks(p.x, p.y, COLOR_DAMAGE_PARTICLE, 6);
                }
                if (trap.trapType === TrapType.WATER_VORTEX) {
                  p.x += (Math.random() - 0.5) * 120;
                  p.y += (Math.random() - 0.5) * 120;
                }
              }
            }
          }
          if (trap.timer <= 0) {
            trap.state = TrapState.COOLDOWN;
            trap.timer = TRAP_COOLDOWN_TIME;
          }
          break;

        case TrapState.COOLDOWN:
          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.IDLE;
          }
          break;
      }
    }
  }
}
