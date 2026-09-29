import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { CameraComponent } from '../components/CameraComponent';
import { DropFactory } from '../factories/DropFactory';
import {
  SLIME_KNOCKBACK,
  WEAPON_FORM_STATS,
  TRANSFORM_ENERGY_KILL_SLIME,
} from '../GameConstants';

interface AudioManager {
  playEnemyHit(): void;
  playEnemyDeath(): void;
}

export class PlayerCombatSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const pos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const movement: MovementComponent | null = player.getComponent<MovementComponent>("movement");
    const combat: CombatComponent | null = player.getComponent<CombatComponent>("combat");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const transform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
    if (pos === null || movement === null || combat === null || health === null || transform === null) return;

    if (health.isDead()) return;

    const audio: AudioManager = context.audio as AudioManager;

    // Handle attack trigger (engulf escape or normal attack initiation)
    if (context.input.attackPressed) {
      context.input.attackPressed = false;
      if (movement.isEngulfed) {
        movement.engulfEscapeCount++;
        audio.playEnemyHit();
        this.shakeCamera(context, 80);
        return;
      }
    }

    // Process active attack
    if (combat.isAttacking) {
      this.performAttack(entities, pos, movement, combat, transform, audio, context);
    }
  }

  private performAttack(
    entities: Entity[],
    pos: PositionComponent,
    movement: MovementComponent,
    combat: CombatComponent,
    transform: TransformComponent,
    audio: AudioManager,
    context: SystemContext
  ): void {
    const formStats: number[] = WEAPON_FORM_STATS[transform.currentWeaponForm];
    const formRange: number = formStats[0];
    const formWidth: number = formStats[1];

    const attackX: number = pos.x + Math.cos(movement.facing) * formRange;
    const attackY: number = pos.y + Math.sin(movement.facing) * formRange;

    // Query spatial grid for nearby entities
    const nearby: Entity[] = context.world.getSpatialGrid().queryRadius(attackX, attackY, formWidth + 60);

    for (let i: number = 0; i < nearby.length; i++) {
      const e: Entity = nearby[i];
      if (!e.active) continue;

      if (e.tag === "enemy") {
        const enemyPos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
        const enemyVel: VelocityComponent | null = e.getComponent<VelocityComponent>("Velocity");
        const enemyHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
        const ai: EnemyAIComponent | null = e.getComponent<EnemyAIComponent>("enemyAI");
        if (enemyPos === null || enemyVel === null || enemyHealth === null || ai === null) continue;

        const dx: number = enemyPos.x - attackX;
        const dy: number = enemyPos.y - attackY;
        const dist: number = Math.sqrt(dx * dx + dy * dy);
        if (dist < formWidth + ai.size) {
          enemyHealth.damage(1);
          ai.hitFlash = 150;
          const knockAngle: number = Math.atan2(dy, dx);
          enemyVel.vx = Math.cos(knockAngle) * SLIME_KNOCKBACK;
          enemyVel.vy = Math.sin(knockAngle) * SLIME_KNOCKBACK;
          this.shakeCamera(context, 100);
          audio.playEnemyHit();

          if (enemyHealth.isDead()) {
            this.onEnemyDeath(e, enemyPos, ai, transform, audio, context);
          }
        }
      } else if (e.tag === "boss") {
        const bossPos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
        const bossHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
        if (bossPos === null || bossHealth === null) continue;

        const dx: number = bossPos.x - attackX;
        const dy: number = bossPos.y - attackY;
        const dist: number = Math.sqrt(dx * dx + dy * dy);
        if (dist < formWidth + 60) {
          bossHealth.damage(1);
          this.shakeCamera(context, 120);
          audio.playEnemyHit();
        }
      }
    }
  }

  private onEnemyDeath(
    enemy: Entity,
    enemyPos: PositionComponent,
    ai: EnemyAIComponent,
    transform: TransformComponent,
    audio: AudioManager,
    context: SystemContext
  ): void {
    enemy.active = false;

    // Transform energy gain
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

  private shakeCamera(context: SystemContext, duration: number): void {
    const cameraEntity: Entity | null = context.world.findEntityByTag("camera");
    if (cameraEntity !== null) {
      const cam: CameraComponent = cameraEntity.getComponent<CameraComponent>("camera")!;
      cam.shakeTimer = duration;
    }
  }
}
