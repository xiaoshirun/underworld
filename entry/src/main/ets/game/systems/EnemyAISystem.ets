import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import {
  PLAYER_SIZE, SLIME_SIZE, SLIME_SPEED, PURPLE_SLIME_SPEED, PURPLE_SLIME_DETECT,
  RED_SLIME_SPEED, RED_SLIME_DETECT, BLUE_SLIME_SPEED,
  SLIME_DAMAGE, INVINCIBLE_DURATION,
  TransformForm, EnemyType,
  TRANSFORM_DAMAGE_REDUCTION,
  TILE_SIZE,
  TileType,
} from '../GameConstants';
import { shakeCamera, triggerDamageFlash, getTile, isWalkable } from '../helpers/SystemHelpers';
import { IAudioService } from '../interfaces/IAudioService';

export class EnemyAISystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const playerHealth: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const playerMovement: MovementComponent | null = player.getComponent<MovementComponent>("movement");
    const playerCombat: CombatComponent | null = player.getComponent<CombatComponent>("combat");
    const playerTransform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
    if (playerPos === null || playerHealth === null || playerMovement === null ||
        playerCombat === null || playerTransform === null) return;

    if (playerHealth.isDead()) return;

    const audio: IAudioService = context.audio as IAudioService;
    const chunks: Map<string, Object> = context.world.chunks;

    for (let idx: number = 0; idx < entities.length; idx++) {
      const e: Entity = entities[idx];
      if (!e.active || e.tag !== "enemy") continue;

      const pos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const vel: VelocityComponent | null = e.getComponent<VelocityComponent>("Velocity");
      const ai: EnemyAIComponent | null = e.getComponent<EnemyAIComponent>("enemyAI");
      if (pos === null || vel === null || ai === null) continue;

      // Bounce animation and hit flash decay
      ai.bouncePhase += 0.05;
      if (ai.hitFlash > 0) ai.hitFlash -= context.dt;

      // Velocity damping
      vel.vx *= 0.9;
      vel.vy *= 0.9;

      // Skip AI behavior if engulfing
      if (ai.isEngulfing) continue;

      const dx: number = playerPos.x - pos.x;
      const dy: number = playerPos.y - pos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      // AI behavior by type
      switch (ai.enemyType) {
        case EnemyType.GRAY_SLIME: {
          ai.moveTimer -= context.dt;
          if (ai.moveTimer <= 0) {
            ai.moveTimer = 2000 + Math.random() * 3000;
            const angle: number = Math.random() * Math.PI * 2;
            ai.targetX = Math.cos(angle) * SLIME_SPEED;
            ai.targetY = Math.sin(angle) * SLIME_SPEED;
          }
          vel.vx += ai.targetX * 0.02;
          vel.vy += ai.targetY * 0.02;
          break;
        }
        case EnemyType.PURPLE_SLIME: {
          if (dist < PURPLE_SLIME_DETECT && dist > 1) {
            vel.vx += (dx / dist) * PURPLE_SLIME_SPEED * 0.1;
            vel.vy += (dy / dist) * PURPLE_SLIME_SPEED * 0.1;
            if (dist < ai.size + PLAYER_SIZE && playerCombat.invincibleTimer <= 0 && !playerMovement.isEngulfed) {
              if (Math.random() < 0.01) {
                ai.isEngulfing = true;
                ai.engulfedPlayer = true;
                playerMovement.isEngulfed = true;
                playerMovement.engulfEscapeCount = 0;
                playerMovement.engulfDamageTimer = 1000;
                audio.playEngulf();
              }
            }
          }
          break;
        }
        case EnemyType.RED_SLIME: {
          if (dist < RED_SLIME_DETECT && dist > 1) {
            if (!ai.isCharging) {
              ai.chargeTimer -= context.dt;
              if (ai.chargeTimer <= 0) {
                ai.isCharging = true;
                ai.chargeTimer = 500;
                vel.vx = (dx / dist) * RED_SLIME_SPEED * 2;
                vel.vy = (dy / dist) * RED_SLIME_SPEED * 2;
              } else {
                vel.vx += (dx / dist) * RED_SLIME_SPEED * 0.03;
                vel.vy += (dy / dist) * RED_SLIME_SPEED * 0.03;
              }
            } else {
              ai.chargeTimer -= context.dt;
              if (ai.chargeTimer <= 0) {
                ai.isCharging = false;
                ai.chargeTimer = 1500;
              }
            }
          }
          break;
        }
        case EnemyType.BLUE_SLIME: {
          if (dist < PURPLE_SLIME_DETECT && dist > 1) {
            vel.vx += (dx / dist) * BLUE_SLIME_SPEED * 0.05;
            vel.vy += (dy / dist) * BLUE_SLIME_SPEED * 0.05;
          }
          ai.moveTimer -= context.dt;
          if (ai.moveTimer <= 0) {
            ai.moveTimer = 1500 + Math.random() * 2000;
            const angle: number = Math.random() * Math.PI * 2;
            ai.targetX = Math.cos(angle) * BLUE_SLIME_SPEED * 0.5;
            ai.targetY = Math.sin(angle) * BLUE_SLIME_SPEED * 0.5;
          }
          vel.vx += ai.targetX * 0.01;
          vel.vy += ai.targetY * 0.01;
          break;
        }
        case EnemyType.YELLOW_SLIME: {
          ai.moveTimer -= context.dt;
          if (ai.moveTimer <= 0) {
            ai.moveTimer = 3000 + Math.random() * 2000;
            const angle: number = Math.random() * Math.PI * 2;
            ai.targetX = Math.cos(angle) * SLIME_SPEED * 0.5;
            ai.targetY = Math.sin(angle) * SLIME_SPEED * 0.5;
          }
          vel.vx += ai.targetX * 0.01;
          vel.vy += ai.targetY * 0.01;
          break;
        }
        case EnemyType.GHOST_SLIME: {
          if (dist < PURPLE_SLIME_DETECT * 1.5 && dist > 1) {
            const speed: number = PURPLE_SLIME_SPEED * 0.8;
            vel.vx += (dx / dist) * speed * 0.08;
            vel.vy += (dy / dist) * speed * 0.08;
          }
          break;
        }
      }

      // Speed clamping
      let maxSpeed: number = SLIME_SPEED;
      switch (ai.enemyType) {
        case EnemyType.PURPLE_SLIME: maxSpeed = PURPLE_SLIME_SPEED; break;
        case EnemyType.RED_SLIME: maxSpeed = ai.isCharging ? RED_SLIME_SPEED * 2 : RED_SLIME_SPEED; break;
        case EnemyType.BLUE_SLIME: maxSpeed = BLUE_SLIME_SPEED; break;
        case EnemyType.GHOST_SLIME: maxSpeed = PURPLE_SLIME_SPEED * 0.8; break;
        default: maxSpeed = SLIME_SPEED; break;
      }
      const speed: number = Math.sqrt(vel.vx * vel.vx + vel.vy * vel.vy);
      if (speed > maxSpeed) {
        vel.vx = (vel.vx / speed) * maxSpeed;
        vel.vy = (vel.vy / speed) * maxSpeed;
      }

      // Movement with collision
      const newX: number = pos.x + vel.vx;
      const newY: number = pos.y + vel.vy;
      if (ai.enemyType === EnemyType.GHOST_SLIME) {
        pos.x = newX;
        pos.y = newY;
      } else {
        if (!this.checkCollision(newX, pos.y, chunks)) { pos.x = newX; } else { vel.vx = -vel.vx; }
        if (!this.checkCollision(pos.x, newY, chunks)) { pos.y = newY; } else { vel.vy = -vel.vy; }
      }

      // Contact damage to player
      if (playerCombat.invincibleTimer <= 0 && !playerMovement.isEngulfed && !ai.isEngulfing) {
        const cdx: number = playerPos.x - pos.x;
        const cdy: number = playerPos.y - pos.y;
        const cdist: number = Math.sqrt(cdx * cdx + cdy * cdy);
        if (cdist < PLAYER_SIZE / 2 + ai.size / 2) {
          let incomingDamage: number = SLIME_DAMAGE;
          if (playerTransform.isTransformed) {
            const reduction: number = TRANSFORM_DAMAGE_REDUCTION[playerTransform.transformForm as number];
            incomingDamage = Math.max(1, Math.floor(incomingDamage * (1 - reduction)));
          }
          playerHealth.damage(incomingDamage);
          const isGhost: boolean = playerTransform.isTransformed &&
            (playerTransform.transformForm as number) === (TransformForm.GHOST as number);
          const isArmor: boolean = playerTransform.isTransformed &&
            (playerTransform.transformForm as number) === (TransformForm.ARMOR as number);
          playerCombat.invincibleTimer = isGhost ? 1500 : INVINCIBLE_DURATION;
          const knockAngle: number = Math.atan2(cdy, cdx);
          const knockBack: number = isArmor ? 2.5 : 5;
          playerPos.x -= Math.cos(knockAngle) * knockBack;
          playerPos.y -= Math.sin(knockAngle) * knockBack;
          shakeCamera(context, 150);
          audio.playPlayerDamage();
          triggerDamageFlash(context);
        }
      }
    }
  }

  private checkCollision(x: number, y: number, chunks: Map<string, Object>): boolean {
    const halfSize: number = SLIME_SIZE / 2;
    const cornersX: number[] = [x - halfSize, x + halfSize];
    const cornersY: number[] = [y - halfSize, y + halfSize];
    for (let i: number = 0; i < 2; i++) {
      for (let j: number = 0; j < 2; j++) {
        const tile: number = getTile(chunks, cornersX[i], cornersY[j]);
        if (!isWalkable(tile)) return true;
      }
    }
    return false;
  }
}
