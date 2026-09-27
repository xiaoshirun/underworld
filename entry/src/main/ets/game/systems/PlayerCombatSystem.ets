import {
  TILE_SIZE, PLAYER_SIZE,
  SLIME_KNOCKBACK,
  PlayerState, SlimeState, BossState,
  EnemyType, TransformForm,
  WEAPON_FORM_STATS,
  TRANSFORM_ENERGY_KILL_SLIME,
  COLOR_DAMAGE_PARTICLE, COLOR_ATTACK_FLASH,
  COLOR_SLIME_GRAY_LIGHT, COLOR_SLIME_PURPLE_LIGHT, COLOR_SLIME_RED_LIGHT,
  COLOR_SLIME_BLUE_LIGHT, COLOR_SLIME_YELLOW_LIGHT, COLOR_SLIME_GHOST_LIGHT,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export class PlayerCombatSystem {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  performAttack(p: PlayerState): void {
    if (p.isEngulfed) {
      p.engulfEscapeCount++;
      this.g.audio.playEnemyHit();
      this.g.shakeTimer = 80;
      return;
    }

    const formStats: number[] = WEAPON_FORM_STATS[p.currentWeaponForm];
    const formRange: number = formStats[0];
    const formWidth: number = formStats[1];

    const attackX: number = p.x + Math.cos(p.facing) * formRange;
    const attackY: number = p.y + Math.sin(p.facing) * formRange;

    for (let i: number = 0; i < this.g.enemies.length; i++) {
      const s: SlimeState = this.g.enemies[i];
      if (!s.active) continue;
      const dx: number = s.x - attackX;
      const dy: number = s.y - attackY;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist < formWidth + s.size) {
        s.hp--;
        s.hitFlash = 150;
        const knockAngle: number = Math.atan2(dy, dx);
        s.vx = Math.cos(knockAngle) * SLIME_KNOCKBACK;
        s.vy = Math.sin(knockAngle) * SLIME_KNOCKBACK;
        this.g.shakeTimer = 100;
        this.g.audio.playEnemyHit();
        if (this.g.settings.effectsEnabled) {
          this.g.particleMgr.sparks(s.x, s.y, COLOR_DAMAGE_PARTICLE, 6);
        }
        if (s.hp <= 0) {
          this.onEnemyDeath(s);
        }
      }
    }

    for (let i: number = 0; i < this.g.bosses.length; i++) {
      const boss: BossState = this.g.bosses[i];
      if (!boss.active || boss.defeated) continue;
      const dx: number = boss.x - attackX;
      const dy: number = boss.y - attackY;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist < formWidth + boss.size * 0.6) {
        boss.hp--;
        boss.hitFlash = 200;
        this.g.shakeTimer = 120;
        this.g.audio.playEnemyHit();
        if (this.g.settings.effectsEnabled) {
          this.g.particleMgr.explosion(boss.x, boss.y, this.g.getBossColor(boss.bossType), 8);
        }
      }
    }

    if (this.g.settings.effectsEnabled) {
      for (let k: number = 0; k < 3; k++) {
        const spread: number = (Math.random() - 0.5) * 0.8;
        const angle: number = p.facing + spread;
        const speed: number = 2 + Math.random() * 2;
        this.g.spawnParticle(attackX, attackY,
          Math.cos(angle) * speed, Math.sin(angle) * speed, 200, COLOR_ATTACK_FLASH, 2);
      }
    }
  }

  onEnemyDeath(s: SlimeState): void {
    s.active = false;
    if (this.g.player !== null && this.g.player.isTransformed) {
      this.g.player.transformEnergy += TRANSFORM_ENERGY_KILL_SLIME;
      if (this.g.player.transformEnergy > this.g.player.transformMaxEnergy) {
        this.g.player.transformEnergy = this.g.player.transformMaxEnergy;
      }
    }
    this.g.audio.playEnemyDeath();
    if (this.g.settings.effectsEnabled) {
      this.g.particleMgr.explosion(s.x, s.y, this.getEnemyColor(s), 10);
    }
    const orbCount: number = 1 + Math.floor(Math.random() * 3);
    for (let k: number = 0; k < orbCount; k++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 5 + Math.random() * 15;
      this.g.xpOrbs.push({
        x: s.x + Math.cos(angle) * dist,
        y: s.y + Math.sin(angle) * dist,
        value: 1, bobPhase: Math.random() * Math.PI * 2, active: true
      });
    }
  }

  private getEnemyColor(s: SlimeState): string {
    switch (s.enemyType) {
      case EnemyType.GRAY_SLIME: return COLOR_SLIME_GRAY_LIGHT;
      case EnemyType.PURPLE_SLIME: return COLOR_SLIME_PURPLE_LIGHT;
      case EnemyType.RED_SLIME: return COLOR_SLIME_RED_LIGHT;
      case EnemyType.BLUE_SLIME: return COLOR_SLIME_BLUE_LIGHT;
      case EnemyType.YELLOW_SLIME: return COLOR_SLIME_YELLOW_LIGHT;
      case EnemyType.GHOST_SLIME: return COLOR_SLIME_GHOST_LIGHT;
      default: return COLOR_SLIME_GRAY_LIGHT;
    }
  }
}
