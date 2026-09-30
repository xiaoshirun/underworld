import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { TransformComponent } from '../components/TransformComponent';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { BossAIComponent } from '../components/BossAIComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { DropFactory } from '../factories/DropFactory';
import {
  PLAYER_SIZE,
  DASH_SPEED, ATTACK_DURATION,
  TransformForm,
  TRANSFORM_COOLDOWN, TRANSFORM_PASSIVE_REGEN,
  TRANSFORM_ACTIVATE_ANIM, TRANSFORM_REVERT_ANIM,
  TRANSFORM_DRAIN_RATES, TRANSFORM_SPEEDS, TRANSFORM_ATTACK_COSTS, TRANSFORM_ATTACK_COOLDOWNS,
  TRANSFORM_ENERGY_KILL_SLIME,
} from '../GameConstants';
import { shakeCamera, getTile, isWalkable } from '../helpers/SystemHelpers';
import { IAudioService } from '../interfaces/IAudioService';

// @deprecated — Use HumanFormSystem instead
export class TransformSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const transform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
    const movement: MovementComponent | null = player.getComponent<MovementComponent>("movement");
    const combat: CombatComponent | null = player.getComponent<CombatComponent>("combat");
    const pos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const vel: VelocityComponent | null = player.getComponent<VelocityComponent>("Velocity");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    if (transform === null || movement === null || combat === null ||
        pos === null || vel === null || health === null) return;

    if (health.isDead()) return;

    const dt: number = context.dt;
    const audio: IAudioService = context.audio as IAudioService;
    const chunks: Map<string, Object> = context.world.chunks;

    // --- Cooldown decay (when not transformed) ---
    if (!transform.isTransformed && transform.transformCooldown > 0) {
      transform.transformCooldown -= dt;
      if (transform.transformCooldown < 0) transform.transformCooldown = 0;
    }

    // --- Animation timer decay ---
    if (transform.transformAnimTimer > 0) {
      transform.transformAnimTimer -= dt;
      if (transform.transformAnimTimer < 0) transform.transformAnimTimer = 0;
    }

    // --- Not transformed: passive regen + activation check ---
    if (!transform.isTransformed) {
      transform.transformEnergy += TRANSFORM_PASSIVE_REGEN * (dt / 1000);
      if (transform.transformEnergy > transform.transformMaxEnergy) {
        transform.transformEnergy = transform.transformMaxEnergy;
      }

      // Check for activation request (external code sets transformForm to a valid form)
      if (transform.transformForm !== TransformForm.NONE &&
          transform.transformCooldown <= 0 &&
          transform.transformAnimTimer <= 0) {
        const inventory: InventoryComponent | null =
          player.getComponent<InventoryComponent>("inventory");
        if (inventory !== null && this.isFormUnlocked(transform.transformForm, inventory)) {
          this.activate(transform, combat, pos, context);
        } else {
          // Invalid request, reset form
          transform.transformForm = TransformForm.NONE;
        }
      }
      return;
    }

    // --- Transformed: energy drain ---
    const formIndex: number = transform.transformForm as number;
    const drainRate: number = TRANSFORM_DRAIN_RATES[formIndex];
    transform.transformEnergy -= drainRate * (dt / 1000);

    // --- Attack cooldown decay ---
    if (transform.transformFormAttackCooldown > 0) {
      transform.transformFormAttackCooldown -= dt;
      if (transform.transformFormAttackCooldown < 0) transform.transformFormAttackCooldown = 0;
    }

    // --- Energy depletion → auto-revert ---
    if (transform.transformEnergy <= 0) {
      transform.transformEnergy = 0;
      this.deactivate(transform, pos, context);
      return;
    }

    // --- Form-specific movement ---
    this.updateMovement(entities, movement, vel, pos, transform, audio, context);

    // --- Form-specific collision ---
    this.applyCollision(pos, vel, transform, chunks);

    // --- Form-specific attack ---
    if (context.input.attackPressed && combat.attackTimer <= 0) {
      context.input.attackPressed = false;
      this.handleAttack(entities, pos, movement, combat, transform, audio, context);
    }

    // --- Combat attack timer ---
    if (combat.isAttacking) {
      combat.attackTimer -= dt;
      if (combat.attackTimer <= 0) {
        combat.isAttacking = false;
        combat.attackTimer = 0;
      }
    }
  }

  private isFormUnlocked(form: number, inventory: InventoryComponent): boolean {
    if (form === TransformForm.SLIME) return inventory.transformCoreSlime > 0;
    if (form === TransformForm.GHOST) return inventory.transformCoreGhost > 0;
    if (form === TransformForm.ARMOR) return inventory.transformCoreArmor > 0;
    if (form === TransformForm.IRON_MAN) return inventory.transformCoreIronMan > 0;
    return false;
  }

  private activate(
    transform: TransformComponent,
    combat: CombatComponent,
    pos: PositionComponent,
    context: SystemContext
  ): void {
    transform.savedWeaponForm = transform.currentWeaponForm;
    transform.isTransformed = true;
    // transformForm is already set by the external request
    transform.transformEnergy = transform.transformMaxEnergy;
    transform.transformAnimTimer = TRANSFORM_ACTIVATE_ANIM;
    transform.transformFormAttackCooldown = 0;

    shakeCamera(context, 200);
  }

  private deactivate(
    transform: TransformComponent,
    pos: PositionComponent,
    context: SystemContext
  ): void {
    if (!transform.isTransformed) return;

    transform.currentWeaponForm = transform.savedWeaponForm;
    transform.isTransformed = false;
    transform.transformForm = TransformForm.NONE;
    transform.transformAnimTimer = TRANSFORM_REVERT_ANIM;

    if (transform.transformEnergy <= 0) {
      transform.transformCooldown = TRANSFORM_COOLDOWN;
    }
  }

  private updateMovement(
    entities: Entity[],
    movement: MovementComponent,
    vel: VelocityComponent,
    pos: PositionComponent,
    transform: TransformComponent,
    audio: IAudioService,
    context: SystemContext
  ): void {
    const form: TransformForm = transform.transformForm as TransformForm;
    const speed: number = TRANSFORM_SPEEDS[form as number];

    // Read joystick input
    let moveX: number = 0;
    let moveY: number = 0;
    if (context.input.joyActive) {
      const len: number = Math.sqrt(
        context.input.joyDx * context.input.joyDx + context.input.joyDy * context.input.joyDy
      );
      if (len > 0.1) {
        moveX = context.input.joyDx / len;
        moveY = context.input.joyDy / len;
      }
    }

    // Form-specific movement
    if (form === TransformForm.IRON_MAN) {
      // IronMan: free flight
      vel.vx = moveX * speed;
      vel.vy = moveY * speed;
    } else if (form === TransformForm.GHOST) {
      // Ghost: phasing movement
      vel.vx = moveX * speed;
      vel.vy = moveY * speed;
    } else if (form === TransformForm.SLIME) {
      // Slime: bounce movement with dash
      if (movement.isDashing) {
        movement.dashTimer -= context.dt;
        if (movement.dashTimer <= 0) {
          movement.isDashing = false;
        } else {
          vel.vx = movement.dashDirX * DASH_SPEED;
          vel.vy = movement.dashDirY * DASH_SPEED;
        }
      } else {
        vel.vx = moveX * speed;
        vel.vy = moveY * speed;
      }
    } else {
      // Armor: slow but powerful, dash with extra speed and dash damage
      if (movement.isDashing) {
        movement.dashTimer -= context.dt;
        if (movement.dashTimer <= 0) {
          movement.isDashing = false;
        } else {
          vel.vx = movement.dashDirX * DASH_SPEED * 1.5;
          vel.vy = movement.dashDirY * DASH_SPEED * 1.5;
          // Armor dash damage: 1 damage to enemies within 30px
          this.damageEnemiesAt(entities, pos.x, pos.y, 30, 1, transform, audio, context);
        }
      } else {
        vel.vx = moveX * speed;
        vel.vy = moveY * speed;
      }
    }

    // Update facing direction
    if (Math.abs(moveX) > 0.1 || Math.abs(moveY) > 0.1) {
      movement.facing = Math.atan2(moveY, moveX);
    }

    // Jump handling
    if (context.input.jumpPressed && !movement.isJumping) {
      movement.isJumping = true;
      if (form === TransformForm.SLIME) {
        movement.jumpTimer = 400;
      } else {
        movement.jumpTimer = 300;
      }
      context.input.jumpPressed = false;
    }
    if (movement.isJumping) {
      movement.jumpTimer -= context.dt;
      if (form === TransformForm.SLIME) {
        movement.jumpHeight = Math.sin((1 - movement.jumpTimer / 400) * Math.PI) * 16;
      } else {
        movement.jumpHeight = Math.sin((1 - movement.jumpTimer / 300) * Math.PI) * 8;
      }
      if (movement.jumpTimer <= 0) {
        movement.isJumping = false;
        movement.jumpHeight = 0;
      }
    }

    // Dash trigger
    if (context.input.dashPressed && !movement.isDashing && movement.dashCooldown <= 0) {
      movement.isDashing = true;
      movement.dashTimer = 200; // DASH_DURATION
      movement.dashCooldown = 800; // DASH_COOLDOWN
      const dx: number = Math.cos(movement.facing);
      const dy: number = Math.sin(movement.facing);
      movement.dashDirX = dx;
      movement.dashDirY = dy;
      context.input.dashPressed = false;
    }
    if (movement.dashCooldown > 0) {
      movement.dashCooldown -= context.dt;
    }
  }

  private applyCollision(
    pos: PositionComponent,
    vel: VelocityComponent,
    transform: TransformComponent,
    chunks: Map<string, Object>
  ): void {
    const newX: number = pos.x + vel.vx;
    const newY: number = pos.y + vel.vy;
    const form: TransformForm = transform.transformForm as TransformForm;

    if (form === TransformForm.GHOST) {
      // Ghost: no collision, pass through walls
      pos.x = newX;
      pos.y = newY;
    } else if (form === TransformForm.IRON_MAN) {
      // IronMan: axis-separated collision
      if (!this.checkPlayerCollision(newX, pos.y, chunks)) {
        pos.x = newX;
      }
      if (!this.checkPlayerCollision(pos.x, newY, chunks)) {
        pos.y = newY;
      }
    } else if (form === TransformForm.SLIME) {
      // Slime: bounce off walls
      if (!this.checkPlayerCollision(newX, pos.y, chunks)) {
        pos.x = newX;
      } else {
        vel.vx = -vel.vx;
      }
      if (!this.checkPlayerCollision(pos.x, newY, chunks)) {
        pos.y = newY;
      } else {
        vel.vy = -vel.vy;
      }
    } else {
      // Armor: normal axis-separated collision
      if (!this.checkPlayerCollision(newX, pos.y, chunks)) {
        pos.x = newX;
      }
      if (!this.checkPlayerCollision(pos.x, newY, chunks)) {
        pos.y = newY;
      }
    }
  }

  private handleAttack(
    entities: Entity[],
    pos: PositionComponent,
    movement: MovementComponent,
    combat: CombatComponent,
    transform: TransformComponent,
    audio: IAudioService,
    context: SystemContext
  ): void {
    const form: TransformForm = transform.transformForm as TransformForm;
    const formIndex: number = form as number;
    const cost: number = TRANSFORM_ATTACK_COSTS[formIndex];
    const cooldown: number = TRANSFORM_ATTACK_COOLDOWNS[formIndex];

    if (transform.transformFormAttackCooldown > 0) return;
    if (transform.transformEnergy < cost) return;

    transform.transformEnergy -= cost;
    transform.transformFormAttackCooldown = cooldown;
    combat.isAttacking = true;
    combat.attackTimer = ATTACK_DURATION;

    const cosF: number = Math.cos(movement.facing);
    const sinF: number = Math.sin(movement.facing);

    if (form === TransformForm.SLIME) {
      // Slime: 3-way spread attack
      for (let i: number = -1; i <= 1; i++) {
        const spreadAngle: number = movement.facing + i * 0.3;
        const sx: number = Math.cos(spreadAngle);
        const sy: number = Math.sin(spreadAngle);
        for (let d: number = 0; d < 80; d += 8) {
          const px: number = pos.x + sx * d;
          const py: number = pos.y + sy * d;
          this.damageEnemiesAt(entities, px, py, 10, 2, transform, audio, context);
        }
      }
    } else if (form === TransformForm.GHOST) {
      // Ghost: AoE radius damage
      this.damageEnemiesInRadius(entities, pos.x, pos.y, 80, 3, transform, audio, context);
    } else if (form === TransformForm.ARMOR) {
      // Armor: charge forward attack
      const chargeDist: number = 60;
      for (let d: number = 0; d < chargeDist; d += 6) {
        const cx: number = pos.x + cosF * d;
        const cy: number = pos.y + sinF * d;
        this.damageEnemiesAt(entities, cx, cy, 12, 5, transform, audio, context);
      }
      // Move player forward
      pos.x += cosF * chargeDist;
      pos.y += sinF * chargeDist;
      shakeCamera(context, 150);
    } else if (form === TransformForm.IRON_MAN) {
      // IronMan: beam attack
      const beamLen: number = 150;
      for (let d: number = 0; d < beamLen; d += 6) {
        const bx: number = pos.x + cosF * d;
        const by: number = pos.y + sinF * d;
        this.damageEnemiesAt(entities, bx, by, 8, 3, transform, audio, context);
      }
    }
  }

  private damageEnemiesAt(
    entities: Entity[],
    x: number, y: number,
    radius: number, damage: number,
    transform: TransformComponent,
    audio: IAudioService,
    context: SystemContext
  ): void {
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active) continue;

      if (e.tag === "enemy") {
        const enemyPos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
        const enemyHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
        const ai: EnemyAIComponent | null = e.getComponent<EnemyAIComponent>("enemyAI");
        if (enemyPos === null || enemyHealth === null || ai === null) continue;

        const dx: number = enemyPos.x - x;
        const dy: number = enemyPos.y - y;
        if (dx * dx + dy * dy < radius * radius) {
          enemyHealth.damage(damage);
          ai.hitFlash = 200;
          if (enemyHealth.isDead()) {
            this.onEnemyDeath(e, enemyPos, transform, audio, context);
          }
        }
      } else if (e.tag === "boss") {
        const bossPos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
        const bossHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
        const bossAi: BossAIComponent | null = e.getComponent<BossAIComponent>("bossAI");
        if (bossPos === null || bossHealth === null || bossAi === null) continue;

        const dx: number = bossPos.x - x;
        const dy: number = bossPos.y - y;
        if (dx * dx + dy * dy < radius * radius) {
          bossHealth.damage(damage);
          if (bossAi.extraData.length > 0) {
            bossAi.extraData[0] = 200; // hitFlash
          } else {
            bossAi.extraData.push(200);
          }
        }
      }
    }
  }

  private damageEnemiesInRadius(
    entities: Entity[],
    cx: number, cy: number,
    radius: number, damage: number,
    transform: TransformComponent,
    audio: IAudioService,
    context: SystemContext
  ): void {
    this.damageEnemiesAt(entities, cx, cy, radius, damage, transform, audio, context);
  }

  private onEnemyDeath(
    enemy: Entity,
    enemyPos: PositionComponent,
    transform: TransformComponent,
    audio: IAudioService,
    context: SystemContext
  ): void {
    enemy.active = false;

    // Transform energy gain from kill
    if (transform.isTransformed) {
      transform.transformEnergy += TRANSFORM_ENERGY_KILL_SLIME;
      if (transform.transformEnergy > transform.transformMaxEnergy) {
        transform.transformEnergy = transform.transformMaxEnergy;
      }
    }

    audio.playEnemyDeath();

    // Create XP orb drops
    const orbCount: number = 1 + Math.floor(Math.random() * 3);
    for (let k: number = 0; k < orbCount; k++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 5 + Math.random() * 15;
      const orb: Entity = DropFactory.createXpOrb(
        enemyPos.x + Math.cos(angle) * dist,
        enemyPos.y + Math.sin(angle) * dist,
        1
      );
      context.world.addEntity(orb);
    }
  }

  private checkPlayerCollision(x: number, y: number, chunks: Map<string, Object>): boolean {
    const halfSize: number = PLAYER_SIZE / 2;
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
