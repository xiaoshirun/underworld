import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { CameraComponent } from '../components/CameraComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE, PLAYER_SPEED,
  DASH_SPEED, DASH_DURATION, DASH_COOLDOWN,
  DRILL_BREAK_HITS,
  SLIME_DAMAGE, ENGULF_DAMAGE_INTERVAL, ENGULF_ESCAPE_ATTACKS,
  INVINCIBLE_DURATION,
  TileType, TransformForm,
  WEAPON_FORM_STATS,
  ChunkData,
} from '../GameConstants';

interface AudioManager {
  playJump(): void;
  playDash(): void;
  playDrillHit(): void;
  playWallBreak(): void;
  playEngulf(): void;
  playPlayerDamage(): void;
}

export class PlayerMovementSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const pos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const vel: VelocityComponent | null = player.getComponent<VelocityComponent>("Velocity");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const movement: MovementComponent | null = player.getComponent<MovementComponent>("movement");
    const combat: CombatComponent | null = player.getComponent<CombatComponent>("combat");
    const transform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
    if (pos === null || vel === null || health === null || movement === null || combat === null || transform === null) return;

    if (health.isDead()) return;

    // Transform movement is handled by TransformSystem
    if (transform.isTransformed) return;

    const audio: AudioManager = context.audio as AudioManager;
    const chunks: Map<string, Object> = context.world.chunks;

    // Engulfed player logic
    if (movement.isEngulfed) {
      this.updateEngulfedPlayer(entities, player, pos, health, movement, combat, audio, context);
      return;
    }

    // Joystick input
    let moveX: number = 0;
    let moveY: number = 0;

    if (context.input.joyActive) {
      const len: number = Math.sqrt(context.input.joyDx * context.input.joyDx + context.input.joyDy * context.input.joyDy);
      if (len > 0.1) {
        moveX = context.input.joyDx / len;
        moveY = context.input.joyDy / len;
        movement.facing = Math.atan2(context.input.joyDy, context.input.joyDx);
      }
    }

    // Drilling: cancel if joystick moved significantly
    if (movement.isDrilling) {
      if (context.input.joyActive) {
        const dLen: number = Math.sqrt(context.input.joyDx * context.input.joyDx + context.input.joyDy * context.input.joyDy);
        if (dLen > 0.3) {
          movement.isDrilling = false;
          movement.isUsingTool = false;
          movement.drillHitCount = 0;
        }
      }
      if (movement.isDrilling) {
        this.updateDrilling(pos, movement, chunks, audio, context);
        return;
      }
    }

    // Dash movement
    if (movement.isDashing) {
      movement.dashTimer -= context.dt;
      if (movement.dashTimer <= 0) {
        movement.isDashing = false;
      } else {
        vel.vx = movement.dashDirX * DASH_SPEED;
        vel.vy = movement.dashDirY * DASH_SPEED;
      }
    } else {
      vel.vx = moveX * PLAYER_SPEED;
      vel.vy = moveY * PLAYER_SPEED;
    }

    // Collision resolution
    const newX: number = pos.x + vel.vx;
    const newY: number = pos.y + vel.vy;
    if (!this.checkPlayerCollision(newX, pos.y, transform, chunks)) {
      pos.x = newX;
    }
    if (!this.checkPlayerCollision(pos.x, newY, transform, chunks)) {
      pos.y = newY;
    }

    // Jump
    if (context.input.jumpPressed && !movement.isJumping) {
      movement.isJumping = true;
      movement.jumpTimer = 300;
      context.input.jumpPressed = false;
      audio.playJump();
    }
    if (movement.isJumping) {
      movement.jumpTimer -= context.dt;
      const progress: number = 1.0 - (movement.jumpTimer / 300);
      movement.jumpHeight = Math.sin(progress * Math.PI) * 12;
      if (movement.jumpTimer <= 0) {
        movement.isJumping = false;
        movement.jumpHeight = 0;
      }
    }

    // Attack trigger
    if (context.input.attackPressed && !combat.isAttacking && combat.attackTimer <= 0) {
      const formStats: number[] = WEAPON_FORM_STATS[transform.currentWeaponForm];
      const formDuration: number = formStats[2];
      combat.isAttacking = true;
      combat.attackTimer = formDuration;
      context.input.attackPressed = false;
    }
    // Attack timer: active phase then cooldown
    if (combat.isAttacking) {
      combat.attackTimer -= context.dt;
      if (combat.attackTimer <= 0) {
        combat.isAttacking = false;
        const formStats: number[] = WEAPON_FORM_STATS[transform.currentWeaponForm];
        combat.attackTimer = formStats[3] - formStats[2];
      }
    } else if (combat.attackTimer > 0) {
      combat.attackTimer -= context.dt;
    }

    // Tool / drill trigger
    if (context.input.toolPressed && !movement.isUsingTool && movement.toolCooldown <= 0 && !movement.isDrilling) {
      context.input.toolPressed = false;
      const cosF: number = Math.cos(movement.facing);
      const sinF: number = Math.sin(movement.facing);
      let bestTX: number = -1;
      let bestTY: number = -1;
      let bestDist: number = 9999;
      for (let r: number = 1; r <= 3; r++) {
        const checkX: number = pos.x + cosF * TILE_SIZE * r;
        const checkY: number = pos.y + sinF * TILE_SIZE * r;
        const ctx2: number = Math.floor(checkX / TILE_SIZE);
        const cty: number = Math.floor(checkY / TILE_SIZE);
        for (let ox: number = -1; ox <= 1; ox++) {
          for (let oy: number = -1; oy <= 1; oy++) {
            const ttx: number = ctx2 + ox;
            const tty: number = cty + oy;
            if (this.getTile(chunks, ttx * TILE_SIZE, tty * TILE_SIZE) === TileType.WALL) {
              const dx: number = (ttx * TILE_SIZE + TILE_SIZE / 2) - pos.x;
              const dy: number = (tty * TILE_SIZE + TILE_SIZE / 2) - pos.y;
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
        movement.isUsingTool = true;
        movement.isDrilling = true;
        movement.drillTargetX = bestTX;
        movement.drillTargetY = bestTY;
        movement.drillHitCount = 0;
        vel.vx = 0;
        vel.vy = 0;
        movement.toolCooldown = 200;
      }
    }
    if (movement.toolCooldown > 0) movement.toolCooldown -= context.dt;
    if (movement.isUsingTool && !movement.isDrilling) {
      movement.isUsingTool = false;
    }

    // Dash trigger
    if (context.input.dashPressed && !movement.isDashing && movement.dashCooldown <= 0) {
      movement.isDashing = true;
      movement.dashTimer = DASH_DURATION;
      movement.dashCooldown = DASH_COOLDOWN;
      combat.invincibleTimer = DASH_DURATION;
      const dx: number = Math.cos(movement.facing);
      const dy: number = Math.sin(movement.facing);
      movement.dashDirX = dx;
      movement.dashDirY = dy;
      context.input.dashPressed = false;
      audio.playDash();
    }
    if (movement.dashCooldown > 0) movement.dashCooldown -= context.dt;
    if (combat.invincibleTimer > 0) combat.invincibleTimer -= context.dt;

    // Animation
    if (Math.abs(vel.vx) > 0.1 || Math.abs(vel.vy) > 0.1) {
      combat.animFrame += 0.15;
    }
  }

  private updateDrilling(
    pos: PositionComponent,
    movement: MovementComponent,
    chunks: Map<string, Object>,
    audio: AudioManager,
    context: SystemContext
  ): void {
    const wallWorldX: number = movement.drillTargetX * TILE_SIZE + TILE_SIZE / 2;
    const wallWorldY: number = movement.drillTargetY * TILE_SIZE + TILE_SIZE / 2;
    movement.facing = Math.atan2(wallWorldY - pos.y, wallWorldX - pos.x);

    const distToWall: number = Math.sqrt(
      (pos.x - wallWorldX) * (pos.x - wallWorldX) + (pos.y - wallWorldY) * (pos.y - wallWorldY)
    );
    if (distToWall > TILE_SIZE * 2.5) {
      movement.isDrilling = false;
      movement.drillHitCount = 0;
      return;
    }

    movement.drillHitCount += context.dt;

    if (context.frameCount % 19 === 0) {
      audio.playDrillHit();
    }

    const breakTime: number = DRILL_BREAK_HITS * 300;
    if (movement.drillHitCount >= breakTime) {
      this.setTile(chunks, wallWorldX, wallWorldY, TileType.BROKEN_WALL);
      audio.playWallBreak();
      movement.isDrilling = false;
      movement.drillHitCount = 0;
    }
  }

  private updateEngulfedPlayer(
    entities: Entity[],
    player: Entity,
    pos: PositionComponent,
    health: HealthComponent,
    movement: MovementComponent,
    combat: CombatComponent,
    audio: AudioManager,
    context: SystemContext
  ): void {
    movement.engulfDamageTimer -= context.dt;
    if (movement.engulfDamageTimer <= 0) {
      health.damage(SLIME_DAMAGE);
      movement.engulfDamageTimer = ENGULF_DAMAGE_INTERVAL;
      audio.playPlayerDamage();
      this.shakeCamera(context, 100);
      const gsEntity: Entity | null = context.world.findEntityByTag("gameState");
      if (gsEntity !== null) {
        const gs: GameStateComponent | null = gsEntity.getComponent<GameStateComponent>("gameState");
        if (gs !== null) {
          gs.damageFlashTimer = 200;
        }
      }
    }

    if (movement.engulfEscapeCount >= ENGULF_ESCAPE_ATTACKS) {
      movement.isEngulfed = false;
      // Find the engulfing enemy
      let engulfingEnemy: Entity | null = null;
      for (let i: number = 0; i < entities.length; i++) {
        const e: Entity = entities[i];
        if (e.active && e.tag === "enemy") {
          const ai: EnemyAIComponent | null = e.getComponent<EnemyAIComponent>("enemyAI");
          if (ai !== null && ai.isEngulfing && ai.engulfedPlayer) {
            engulfingEnemy = e;
            break;
          }
        }
      }
      if (engulfingEnemy !== null) {
        const ai: EnemyAIComponent = engulfingEnemy.getComponent<EnemyAIComponent>("enemyAI")!;
        const enemyPos: PositionComponent = engulfingEnemy.getComponent<PositionComponent>("Position")!;
        ai.isEngulfing = false;
        ai.engulfedPlayer = false;
        const angle: number = Math.random() * Math.PI * 2;
        pos.x = enemyPos.x + Math.cos(angle) * 20;
        pos.y = enemyPos.y + Math.sin(angle) * 20;
      }
      movement.engulfEscapeCount = 0;
      combat.invincibleTimer = INVINCIBLE_DURATION;
    }
  }

  private checkPlayerCollision(
    x: number, y: number,
    transform: TransformComponent,
    chunks: Map<string, Object>
  ): boolean {
    if (transform.isTransformed && (transform.transformForm as number) === (TransformForm.GHOST as number)) {
      return false;
    }
    const halfSize: number = PLAYER_SIZE / 2;
    const cornersX: number[] = [x - halfSize, x + halfSize];
    const cornersY: number[] = [y - halfSize, y + halfSize];
    for (let i: number = 0; i < 2; i++) {
      for (let j: number = 0; j < 2; j++) {
        const tile: number = this.getTile(chunks, cornersX[i], cornersY[j]);
        if (!this.isWalkable(tile)) return true;
      }
    }
    return false;
  }

  private getTile(chunks: Map<string, Object>, worldX: number, worldY: number): number {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = cx + ',' + cy;
    const chunk: ChunkData | undefined = chunks.get(key) as ChunkData | undefined;
    if (chunk === undefined) return TileType.WALL;
    const lx: number = tx - cx * CHUNK_SIZE;
    const ly: number = ty - cy * CHUNK_SIZE;
    return chunk.tiles[ly][lx];
  }

  private isWalkable(tile: number): boolean {
    return tile !== TileType.WALL && tile !== TileType.VOID;
  }

  private setTile(chunks: Map<string, Object>, worldX: number, worldY: number, tileType: number): void {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = cx + ',' + cy;
    const chunk: ChunkData | undefined = chunks.get(key) as ChunkData | undefined;
    if (chunk === undefined) return;
    const lx: number = tx - cx * CHUNK_SIZE;
    const ly: number = ty - cy * CHUNK_SIZE;
    chunk.tiles[ly][lx] = tileType;
  }

  private shakeCamera(context: SystemContext, duration: number): void {
    const cameraEntity: Entity | null = context.world.findEntityByTag("camera");
    if (cameraEntity !== null) {
      const cam: CameraComponent = cameraEntity.getComponent<CameraComponent>("camera")!;
      cam.shakeTimer = duration;
    }
  }
}
