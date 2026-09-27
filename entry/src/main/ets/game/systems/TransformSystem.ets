import {
  TILE_SIZE, PLAYER_SIZE,
  DASH_SPEED, ATTACK_DURATION,
  TransformForm, PlayerState, SlimeState, BossState, BossType,
  TRANSFORM_MAX_ENERGY, TRANSFORM_COOLDOWN, TRANSFORM_PASSIVE_REGEN,
  TRANSFORM_DRAIN_RATES, TRANSFORM_SPEEDS, TRANSFORM_ATTACK_COSTS, TRANSFORM_ATTACK_COOLDOWNS,
  TRANSFORM_ENERGY_KILL_SLIME, TRANSFORM_ACTIVATE_ANIM, TRANSFORM_REVERT_ANIM,
  COLOR_TRANSFORM_SLIME, COLOR_TRANSFORM_GHOST, COLOR_TRANSFORM_ARMOR, COLOR_TRANSFORM_IRON_GOLD,
  COLOR_DAMAGE_PARTICLE,
} from '../GameConstants';
import { GameContext } from '../GameContext';
import { ParticleShape, EmitterConfig } from '../ParticleSystem';

export interface TransformBridge {
  onEnemyDeath(s: SlimeState): void;
  checkPlayerCollision(x: number, y: number): boolean;
}

export class TransformSystem {
  private g: GameContext;
  private bridge: TransformBridge;

  constructor(g: GameContext, bridge: TransformBridge) {
    this.g = g;
    this.bridge = bridge;
  }

  update(p: PlayerState, dt: number): void {
    if (!p.isTransformed && p.transformCooldown > 0) {
      p.transformCooldown -= dt;
      if (p.transformCooldown < 0) p.transformCooldown = 0;
    }

    if (p.transformAnimTimer > 0) {
      p.transformAnimTimer -= dt;
      if (p.transformAnimTimer < 0) p.transformAnimTimer = 0;
    }

    if (this.g.transformUnlockNotifyTimer > 0) {
      this.g.transformUnlockNotifyTimer -= dt;
      if (this.g.transformUnlockNotifyTimer < 0) this.g.transformUnlockNotifyTimer = 0;
    }

    if (!p.isTransformed) {
      p.transformEnergy += TRANSFORM_PASSIVE_REGEN * (dt / 1000);
      if (p.transformEnergy > p.transformMaxEnergy) {
        p.transformEnergy = p.transformMaxEnergy;
      }
      return;
    }

    const formIndex: number = p.transformForm as number;
    const drainRate: number = TRANSFORM_DRAIN_RATES[formIndex];
    p.transformEnergy -= drainRate * (dt / 1000);

    if (p.transformFormAttackCooldown > 0) {
      p.transformFormAttackCooldown -= dt;
      if (p.transformFormAttackCooldown < 0) p.transformFormAttackCooldown = 0;
    }

    if (p.transformEnergy <= 0) {
      p.transformEnergy = 0;
      this.deactivate();
    }

    this.updateAmbientEffects(p, dt);
  }

  private updateAmbientEffects(p: PlayerState, dt: number): void {
    if (!this.g.settings.effectsEnabled) return;
    const form: TransformForm = p.transformForm;

    if (form === TransformForm.SLIME && this.g.frameCount % 20 === 0) {
      this.g.spawnParticle(p.x, p.y + PLAYER_SIZE, 0, 1, 400, COLOR_TRANSFORM_SLIME, 2);
    } else if (form === TransformForm.GHOST && this.g.frameCount % 5 === 0) {
      this.g.spawnParticle(p.x + (Math.random() - 0.5) * 8, p.y + (Math.random() - 0.5) * 8,
        (Math.random() - 0.5) * 0.5, -0.5 - Math.random() * 0.5, 300, COLOR_TRANSFORM_GHOST, 3);
    } else if (form === TransformForm.IRON_MAN && this.g.frameCount % 3 === 0) {
      this.g.spawnParticle(p.x - 3, p.y + PLAYER_SIZE, (Math.random() - 0.5) * 0.5, 1.5 + Math.random(), 200,
        Math.random() > 0.5 ? '#ff6b00' : '#fbbf24', 2 + Math.random() * 2);
      this.g.spawnParticle(p.x + 3, p.y + PLAYER_SIZE, (Math.random() - 0.5) * 0.5, 1.5 + Math.random(), 200,
        Math.random() > 0.5 ? '#ff6b00' : '#fbbf24', 2 + Math.random() * 2);
    }
  }

  activate(form: TransformForm): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;
    if (p.isTransformed) return;
    if (p.transformCooldown > 0) return;
    if (p.unlockedTransforms.indexOf(form as number) === -1) return;

    p.savedWeaponForm = p.currentWeaponForm;

    p.isTransformed = true;
    p.transformForm = form;
    p.transformEnergy = p.transformMaxEnergy;
    p.transformAnimTimer = TRANSFORM_ACTIVATE_ANIM;
    this.g.transformAnimIsRevert = false;
    p.transformFormAttackCooldown = 0;

    if (this.g.settings.effectsEnabled) {
      this.g.particleMgr.magic(p.x, p.y, this.getColor(form));
    }
    this.g.shakeTimer = 200;
  }

  deactivate(): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;
    if (!p.isTransformed) return;

    p.currentWeaponForm = p.savedWeaponForm;

    p.isTransformed = false;
    p.transformForm = TransformForm.NONE;
    p.transformAnimTimer = TRANSFORM_REVERT_ANIM;
    this.g.transformAnimIsRevert = true;

    if (p.transformEnergy <= 0) {
      p.transformCooldown = TRANSFORM_COOLDOWN;
    }

    if (this.g.settings.effectsEnabled) {
      this.g.particleMgr.dust(p.x, p.y);
    }
  }

  private getColor(form: TransformForm): string {
    if (form === TransformForm.SLIME) return COLOR_TRANSFORM_SLIME;
    if (form === TransformForm.GHOST) return COLOR_TRANSFORM_GHOST;
    if (form === TransformForm.ARMOR) return COLOR_TRANSFORM_ARMOR;
    return COLOR_TRANSFORM_IRON_GOLD;
  }

  updateMovement(p: PlayerState, dt: number, moveX: number, moveY: number): void {
    const form: TransformForm = p.transformForm;
    const speed: number = TRANSFORM_SPEEDS[form as number];

    if (form === TransformForm.IRON_MAN) {
      p.vx = moveX * speed;
      p.vy = moveY * speed;
    } else if (form === TransformForm.GHOST) {
      p.vx = moveX * speed;
      p.vy = moveY * speed;
    } else if (form === TransformForm.SLIME) {
      if (p.isDashing) {
        p.dashTimer -= dt;
        if (p.dashTimer <= 0) p.isDashing = false;
        else {
          p.vx = p.dashDirX * DASH_SPEED;
          p.vy = p.dashDirY * DASH_SPEED;
        }
      } else {
        p.vx = moveX * speed;
        p.vy = moveY * speed;
      }
    } else {
      if (p.isDashing) {
        p.dashTimer -= dt;
        if (p.dashTimer <= 0) p.isDashing = false;
        else {
          p.vx = p.dashDirX * DASH_SPEED * 1.5;
          p.vy = p.dashDirY * DASH_SPEED * 1.5;
          this.checkDashDamage(p);
        }
      } else {
        p.vx = moveX * speed;
        p.vy = moveY * speed;
      }
    }

    if (Math.abs(moveX) > 0.1 || Math.abs(moveY) > 0.1) {
      p.facing = Math.atan2(moveY, moveX);
    }

    if (p.isJumping) {
      p.jumpTimer -= dt;
      if (form === TransformForm.SLIME) {
        p.jumpHeight = Math.sin((1 - p.jumpTimer / 400) * Math.PI) * 16;
      } else {
        p.jumpHeight = Math.sin((1 - p.jumpTimer / 300) * Math.PI) * 8;
      }
      if (p.jumpTimer <= 0) {
        p.isJumping = false;
        p.jumpHeight = 0;
      }
    }
  }

  applyCollision(p: PlayerState): void {
    const newX: number = p.x + p.vx;
    const newY: number = p.y + p.vy;

    if (p.transformForm === TransformForm.GHOST) {
      p.x = newX;
      p.y = newY;
    } else if (p.transformForm === TransformForm.IRON_MAN) {
      if (!this.bridge.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      }
      if (!this.bridge.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      }
    } else if (p.transformForm === TransformForm.SLIME) {
      if (!this.bridge.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      } else {
        p.vx = -p.vx;
      }
      if (!this.bridge.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      } else {
        p.vy = -p.vy;
      }
    } else {
      if (!this.bridge.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      }
      if (!this.bridge.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      }
    }
  }

  handleAttack(p: PlayerState): void {
    const form: TransformForm = p.transformForm;
    const formIndex: number = form as number;
    const cost: number = TRANSFORM_ATTACK_COSTS[formIndex];
    const cooldown: number = TRANSFORM_ATTACK_COOLDOWNS[formIndex];

    if (p.transformFormAttackCooldown > 0) return;
    if (p.transformEnergy < cost) return;

    p.transformEnergy -= cost;
    p.transformFormAttackCooldown = cooldown;
    p.isAttacking = true;
    p.attackTimer = ATTACK_DURATION;

    const cosF: number = Math.cos(p.facing);
    const sinF: number = Math.sin(p.facing);

    if (form === TransformForm.SLIME) {
      for (let i: number = -1; i <= 1; i++) {
        const spreadAngle: number = p.facing + i * 0.3;
        const sx: number = Math.cos(spreadAngle);
        const sy: number = Math.sin(spreadAngle);
        for (let d: number = 0; d < 80; d += 8) {
          const px: number = p.x + sx * d;
          const py: number = p.y + sy * d;
          this.damageEnemiesAt(px, py, 10, 2);
        }
        if (this.g.settings.effectsEnabled) {
          for (let d: number = 0; d < 60; d += 12) {
            this.g.spawnParticle(p.x + sx * d, p.y + sy * d,
              sx * 0.5, sy * 0.5, 300, COLOR_TRANSFORM_SLIME, 4);
          }
        }
      }
    } else if (form === TransformForm.GHOST) {
      if (this.g.settings.effectsEnabled) {
        const ghostRing: EmitterConfig = {
          x: p.x, y: p.y,
          count: 16,
          speedMin: 1.5, speedMax: 2.5,
          angleMin: 0, angleMax: Math.PI * 2,
          lifeMin: 300, lifeMax: 400,
          sizeMin: 2, sizeMax: 4,
          endSizeMin: 0, endSizeMax: 1,
          colors: [COLOR_TRANSFORM_GHOST, '#b0e0e6'],
          endColors: [],
          gravity: 0,
          friction: 0.97,
          shape: ParticleShape.RING,
          shrink: true,
          fadeOut: true,
          spreadX: 6, spreadY: 6
        };
        this.g.particleMgr.burst(ghostRing);
      }
      this.damageEnemiesInRadius(p.x, p.y, 80, 3);
    } else if (form === TransformForm.ARMOR) {
      const chargeDist: number = 60;
      for (let d: number = 0; d < chargeDist; d += 6) {
        const cx: number = p.x + cosF * d;
        const cy: number = p.y + sinF * d;
        this.damageEnemiesAt(cx, cy, 12, 5);
      }
      p.x += cosF * chargeDist;
      p.y += sinF * chargeDist;
      if (this.g.settings.effectsEnabled) {
        for (let d: number = 0; d < chargeDist; d += 10) {
          this.g.spawnParticle(p.x - cosF * d, p.y - sinF * d,
            (Math.random() - 0.5) * 2, (Math.random() - 0.5) * 2, 400, '#8b5cf6', 4);
        }
      }
      this.g.shakeTimer = 150;
    } else if (form === TransformForm.IRON_MAN) {
      const beamLen: number = 150;
      for (let d: number = 0; d < beamLen; d += 6) {
        const bx: number = p.x + cosF * d;
        const by: number = p.y + sinF * d;
        this.damageEnemiesAt(bx, by, 8, 3);
      }
      if (this.g.settings.effectsEnabled) {
        for (let d: number = 0; d < beamLen; d += 10) {
          this.g.spawnParticle(p.x + cosF * d, p.y + sinF * d,
            cosF * 0.3 + (Math.random() - 0.5), sinF * 0.3 + (Math.random() - 0.5),
            250, COLOR_TRANSFORM_IRON_GOLD, 3);
        }
      }
    }
  }

  private damageEnemiesAt(x: number, y: number, radius: number, damage: number): void {
    for (let i: number = 0; i < this.g.enemies.length; i++) {
      const s: SlimeState = this.g.enemies[i];
      if (!s.active) continue;
      const dx: number = s.x - x;
      const dy: number = s.y - y;
      if (dx * dx + dy * dy < radius * radius) {
        s.hp -= damage;
        s.hitFlash = 200;
        if (this.g.settings.effectsEnabled) {
          this.g.particleMgr.sparks(s.x, s.y, COLOR_DAMAGE_PARTICLE, 3);
        }
        if (s.hp <= 0) {
          this.bridge.onEnemyDeath(s);
        }
      }
    }
  }

  private damageEnemiesInRadius(cx: number, cy: number, radius: number, damage: number): void {
    this.damageEnemiesAt(cx, cy, radius, damage);
    if (this.g.activeBoss !== null && this.g.activeBoss.active && !this.g.activeBoss.defeated) {
      const dx: number = this.g.activeBoss.x - cx;
      const dy: number = this.g.activeBoss.y - cy;
      if (dx * dx + dy * dy < radius * radius) {
        this.g.activeBoss.hp -= damage;
        this.g.activeBoss.hitFlash = 200;
      }
    }
  }

  private checkDashDamage(p: PlayerState): void {
    for (let i: number = 0; i < this.g.enemies.length; i++) {
      const s: SlimeState = this.g.enemies[i];
      if (!s.active) continue;
      const dx: number = s.x - p.x;
      const dy: number = s.y - p.y;
      if (dx * dx + dy * dy < 30 * 30) {
        s.hp -= 1;
        s.hitFlash = 200;
        if (s.hp <= 0) {
          this.bridge.onEnemyDeath(s);
        }
      }
    }
  }

  getCoreForBoss(bossType: BossType): TransformForm {
    if (bossType === BossType.MUSHROOM_KING) return TransformForm.SLIME;
    if (bossType === BossType.CRYSTAL_GUARDIAN) return TransformForm.ARMOR;
    if (bossType === BossType.LAVA_BEAST) return TransformForm.IRON_MAN;
    if (bossType === BossType.VOID_RIFT) return TransformForm.GHOST;
    return TransformForm.NONE;
  }
}
