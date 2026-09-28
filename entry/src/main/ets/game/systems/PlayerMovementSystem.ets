import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE, PLAYER_SPEED,
  DASH_SPEED, DASH_DURATION, DASH_COOLDOWN,
  ATTACK_DURATION,
  DRILL_BREAK_HITS,
  SLIME_DAMAGE, ENGULF_DAMAGE_INTERVAL, ENGULF_ESCAPE_ATTACKS,
  INVINCIBLE_DURATION,
  TileType, PlayerState, SlimeState, TransformForm,
  WEAPON_FORM_STATS,
  COLOR_PLAYER_BODY, COLOR_DRILL_PARTICLE, COLOR_WALL, COLOR_BREAKABLE_WALL,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export interface MovementBridge {
  performAttack(p: PlayerState): void;
  updateTransformMovement(p: PlayerState, dt: number, moveX: number, moveY: number): void;
  handleTransformAttack(p: PlayerState): void;
  applyTransformCollision(p: PlayerState): void;
}

export class PlayerMovementSystem {
  private g: GameContext;
  private bridge: MovementBridge;

  constructor(g: GameContext, bridge: MovementBridge) {
    this.g = g;
    this.bridge = bridge;
  }

  update(dt: number): void {
    const p: PlayerState | null = this.g.player;
    if (p === null) return;

    if (p.isEngulfed) {
      this.updateEngulfedPlayer(p, dt);
      return;
    }

    let moveX: number = 0;
    let moveY: number = 0;

    if (this.g.input.joyActive) {
      const len: number = Math.sqrt(this.g.input.joyDx * this.g.input.joyDx + this.g.input.joyDy * this.g.input.joyDy);
      if (len > 0.1) {
        moveX = this.g.input.joyDx / len;
        moveY = this.g.input.joyDy / len;
        p.facing = Math.atan2(this.g.input.joyDy, this.g.input.joyDx);
      }
    }

    if (p.isTransformed) {
      this.bridge.updateTransformMovement(p, dt, moveX, moveY);
      if (this.g.input.attackPressed) {
        this.g.input.attackPressed = false;
        this.bridge.handleTransformAttack(p);
      }
      if (this.g.input.jumpPressed && p.transformForm !== TransformForm.IRON_MAN) {
        this.g.input.jumpPressed = false;
        if (p.transformForm === TransformForm.SLIME) {
          p.isJumping = true;
          p.jumpTimer = 400;
        } else {
          p.isJumping = true;
          p.jumpTimer = 300;
        }
      }
      this.bridge.applyTransformCollision(p);
      return;
    }

    if (p.isDrilling) {
      if (this.g.input.joyActive) {
        const dLen: number = Math.sqrt(this.g.input.joyDx * this.g.input.joyDx + this.g.input.joyDy * this.g.input.joyDy);
        if (dLen > 0.3) {
          p.isDrilling = false;
          p.isUsingTool = false;
          p.drillHitCount = 0;
        }
      }
      if (p.isDrilling) {
        this.updateDrilling(p, dt);
        return;
      }
    }

    if (p.isDashing) {
      p.dashTimer -= dt;
      if (p.dashTimer <= 0) {
        p.isDashing = false;
      } else {
        p.vx = p.dashDirX * DASH_SPEED;
        p.vy = p.dashDirY * DASH_SPEED;
        if (this.g.settings.effectsEnabled && this.g.frameCount % 3 === 0) {
          this.g.spawnParticle(p.x, p.y + PLAYER_SIZE / 2, 0, 0, 200, COLOR_PLAYER_BODY, 4);
        }
      }
    } else {
      p.vx = moveX * PLAYER_SPEED;
      p.vy = moveY * PLAYER_SPEED;
    }

    const newX: number = p.x + p.vx;
    const newY: number = p.y + p.vy;
    if (!this.checkPlayerCollision(newX, p.y)) {
      p.x = newX;
    }
    if (!this.checkPlayerCollision(p.x, newY)) {
      p.y = newY;
    }

    if (this.g.input.jumpPressed && !p.isJumping) {
      p.isJumping = true;
      p.jumpTimer = 300;
      this.g.input.jumpPressed = false;
      this.g.audio.playJump();
    }
    if (p.isJumping) {
      p.jumpTimer -= dt;
      const progress: number = 1.0 - (p.jumpTimer / 300);
      p.jumpHeight = Math.sin(progress * Math.PI) * 12;
      if (p.jumpTimer <= 0) {
        p.isJumping = false;
        p.jumpHeight = 0;
      }
    }

    if (this.g.input.attackPressed && !p.isAttacking && p.attackTimer <= 0) {
      const formStats: number[] = WEAPON_FORM_STATS[p.currentWeaponForm];
      const formDuration: number = formStats[2];
      p.isAttacking = true;
      p.attackTimer = formDuration;
      this.g.input.attackPressed = false;
      this.bridge.performAttack(p);
    }
    if (p.isAttacking) {
      p.attackTimer -= dt;
      if (p.attackTimer <= 0) {
        p.isAttacking = false;
        const formStats: number[] = WEAPON_FORM_STATS[p.currentWeaponForm];
        p.attackTimer = formStats[3] - formStats[2];
      }
    } else if (p.attackTimer > 0) {
      p.attackTimer -= dt;
    }

    if (this.g.input.toolPressed && !p.isUsingTool && p.toolCooldown <= 0 && !p.isDrilling) {
      this.g.input.toolPressed = false;
      const cosF: number = Math.cos(p.facing);
      const sinF: number = Math.sin(p.facing);
      let bestTX: number = -1;
      let bestTY: number = -1;
      let bestDist: number = 9999;
      for (let r: number = 1; r <= 3; r++) {
        const checkX: number = p.x + cosF * TILE_SIZE * r;
        const checkY: number = p.y + sinF * TILE_SIZE * r;
        const ctx2: number = Math.floor(checkX / TILE_SIZE);
        const cty: number = Math.floor(checkY / TILE_SIZE);
        for (let ox: number = -1; ox <= 1; ox++) {
          for (let oy: number = -1; oy <= 1; oy++) {
            const ttx: number = ctx2 + ox;
            const tty: number = cty + oy;
            if (this.g.getTile(ttx * TILE_SIZE, tty * TILE_SIZE) === TileType.WALL) {
              const dx: number = (ttx * TILE_SIZE + TILE_SIZE / 2) - p.x;
              const dy: number = (tty * TILE_SIZE + TILE_SIZE / 2) - p.y;
              const dist: number = dx * dx + dy * dy;
              if (dist < bestDist) {
                bestDist = dist;
                bestTX = ttx;
                bestTY = tty;
              }
            }
          }
        }
      }
      if (bestTX >= 0) {
        p.isUsingTool = true;
        p.isDrilling = true;
        p.drillTargetX = bestTX;
        p.drillTargetY = bestTY;
        p.drillHitCount = 0;
        p.vx = 0;
        p.vy = 0;
        p.toolCooldown = 200;
      }
    }
    if (p.toolCooldown > 0) p.toolCooldown -= dt;
    if (p.isUsingTool && !p.isDrilling) {
      p.isUsingTool = false;
    }

    if (this.g.input.dashPressed && !p.isDashing && p.dashCooldown <= 0) {
      p.isDashing = true;
      p.dashTimer = DASH_DURATION;
      p.dashCooldown = DASH_COOLDOWN;
      p.invincibleTimer = DASH_DURATION;
      const dx: number = Math.cos(p.facing);
      const dy: number = Math.sin(p.facing);
      p.dashDirX = dx;
      p.dashDirY = dy;
      this.g.input.dashPressed = false;
      this.g.audio.playDash();
    }
    if (p.dashCooldown > 0) p.dashCooldown -= dt;
    if (p.invincibleTimer > 0) p.invincibleTimer -= dt;

    if (Math.abs(p.vx) > 0.1 || Math.abs(p.vy) > 0.1) {
      p.animFrame += 0.15;
    }
  }

  private updateDrilling(p: PlayerState, dt: number): void {
    const wallWorldX: number = p.drillTargetX * TILE_SIZE + TILE_SIZE / 2;
    const wallWorldY: number = p.drillTargetY * TILE_SIZE + TILE_SIZE / 2;
    p.facing = Math.atan2(wallWorldY - p.y, wallWorldX - p.x);

    const distToWall: number = Math.sqrt((p.x - wallWorldX) * (p.x - wallWorldX) + (p.y - wallWorldY) * (p.y - wallWorldY));
    if (distToWall > TILE_SIZE * 2.5) {
      p.isDrilling = false;
      p.drillHitCount = 0;
      return;
    }

    p.drillHitCount += dt;

    if (this.g.settings.effectsEnabled && this.g.frameCount % 3 === 0) {
      const angle: number = Math.random() * Math.PI * 2;
      this.g.spawnParticle(wallWorldX, wallWorldY,
        Math.cos(angle) * 1.5, Math.sin(angle) * 1.5, 200, COLOR_DRILL_PARTICLE, 2);
    }

    if (this.g.frameCount % 19 === 0) {
      this.g.audio.playDrillHit();
    }

    const breakTime: number = DRILL_BREAK_HITS * 300;
    if (p.drillHitCount >= breakTime) {
      this.g.setTile(wallWorldX, wallWorldY, TileType.BROKEN_WALL);
      this.g.audio.playWallBreak();
      if (this.g.settings.effectsEnabled) {
        for (let k: number = 0; k < 8; k++) {
          const angle: number = Math.random() * Math.PI * 2;
          const speed: number = 1 + Math.random() * 3;
          this.g.spawnParticle(wallWorldX, wallWorldY,
            Math.cos(angle) * speed, Math.sin(angle) * speed, 400, COLOR_WALL, 4);
        }
      }
      p.isDrilling = false;
      p.drillHitCount = 0;
    }
  }

  private updateEngulfedPlayer(p: PlayerState, dt: number): void {
    p.engulfDamageTimer -= dt;
    if (p.engulfDamageTimer <= 0) {
      p.hp -= SLIME_DAMAGE;
      if (p.hp < 0) p.hp = 0;
      p.engulfDamageTimer = ENGULF_DAMAGE_INTERVAL;
      this.g.damageFlashTimer = 200;
      this.g.audio.playPlayerDamage();
      this.g.shakeTimer = 100;
    }

    if (p.engulfEscapeCount >= ENGULF_ESCAPE_ATTACKS) {
      p.isEngulfed = false;
      if (p.engulfSlimeIndex >= 0 && p.engulfSlimeIndex < this.g.enemies.length) {
        const s: SlimeState = this.g.enemies[p.engulfSlimeIndex];
        s.isEngulfing = false;
        s.engulfedPlayer = false;
        const angle: number = Math.random() * Math.PI * 2;
        p.x = s.x + Math.cos(angle) * 20;
        p.y = s.y + Math.sin(angle) * 20;
      }
      p.engulfSlimeIndex = -1;
      p.engulfEscapeCount = 0;
      p.invincibleTimer = INVINCIBLE_DURATION;
    }
  }

  checkPlayerCollision(x: number, y: number): boolean {
    if (this.g.player !== null && this.g.player.isTransformed &&
        this.g.player.transformForm === TransformForm.GHOST) {
      return false;
    }
    const halfSize: number = PLAYER_SIZE / 2;
    const cornersX: number[] = [x - halfSize, x + halfSize];
    const cornersY: number[] = [y - halfSize, y + halfSize];
    for (let i: number = 0; i < 2; i++) {
      for (let j: number = 0; j < 2; j++) {
        const tile: number = this.g.getTile(cornersX[i], cornersY[j]);
        if (!this.g.isWalkable(tile)) return true;
      }
    }
    return false;
  }

  checkBreakableWalls(p: PlayerState): void {
    if (!p.isDrilling) return;
    const wallTX: number = p.drillTargetX;
    const wallTY: number = p.drillTargetY;
    const wallWorldX: number = wallTX * TILE_SIZE + TILE_SIZE / 2;
    const wallWorldY: number = wallTY * TILE_SIZE + TILE_SIZE / 2;

    for (let i: number = 0; i < this.g.secretRooms.length; i++) {
      const room = this.g.secretRooms[i];
      if (room.revealed) continue;
      const roomWX: number = (room.chunkX * CHUNK_SIZE + room.wallTileX) * TILE_SIZE + TILE_SIZE / 2;
      const roomWY: number = (room.chunkY * CHUNK_SIZE + room.wallTileY) * TILE_SIZE + TILE_SIZE / 2;
      const dx: number = wallWorldX - roomWX;
      const dy: number = wallWorldY - roomWY;
      if (Math.abs(dx) < TILE_SIZE && Math.abs(dy) < TILE_SIZE) {
        room.revealed = true;
        this.g.setTile(roomWX, roomWY, TileType.FLOOR);
        this.g.audio.playWallBreak();
        this.g.shakeTimer = 200;
        if (this.g.settings.effectsEnabled) {
          for (let k: number = 0; k < 12; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 3;
            this.g.spawnParticle(roomWX, roomWY,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 600, COLOR_BREAKABLE_WALL, 4);
          }
        }
      }
    }
  }
}
