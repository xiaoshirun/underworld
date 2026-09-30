import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { TrapComponent } from '../components/TrapComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import { CameraComponent } from '../components/CameraComponent';
import {
  TRAP_TELEGRAPH_TIME, TRAP_ACTIVE_TIME, TRAP_COOLDOWN_TIME,
  INVINCIBLE_DURATION,
  TrapType, TrapState, TransformForm,
} from '../GameConstants';

interface AudioManager {
  playPlayerDamage(): void;
}

export class TrapSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const playerHealth: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const playerCombat: CombatComponent | null = player.getComponent<CombatComponent>("combat");
    const playerTransform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
    const playerVel: VelocityComponent | null = player.getComponent<VelocityComponent>("Velocity");
    if (playerPos === null || playerHealth === null || playerCombat === null || playerTransform === null) return;

    if (playerHealth.isDead()) return;

    const audio: AudioManager = context.audio as AudioManager;
    const dt: number = context.dt;

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "trap") continue;

      const pos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const trap: TrapComponent | null = e.getComponent<TrapComponent>("trap");
      if (pos === null || trap === null) continue;

      const dx: number = playerPos.x - pos.x;
      const dy: number = playerPos.y - pos.y;
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
            audio.playPlayerDamage();
          }
          break;

        case TrapState.ACTIVE: {
          // Void crack pull effect — applies every frame while active
          if (trap.trapType === TrapType.VOID_CRACK && dist < trap.triggerRadius * 1.5 && dist > 1) {
            if (playerVel !== null) {
              const pullStrength: number = 0.8 * (1.0 - dist / (trap.triggerRadius * 1.5));
              playerVel.vx -= (dx / dist) * pullStrength;
              playerVel.vy -= (dy / dist) * pullStrength;
            }
          }

          // Damage check
          if (dist < trap.size) {
            if (playerCombat.invincibleTimer <= 0) {
              // Iron Man hovers — immune to ground traps
              const isIronMan: boolean = playerTransform.isTransformed &&
                (playerTransform.transformForm as number) === (TransformForm.IRON_MAN as number);

              if (!isIronMan) {
                playerHealth.damage(trap.damage);
                playerCombat.invincibleTimer = INVINCIBLE_DURATION;
                this.shakeCamera(context, 150);
                this.setDamageFlash(context);

                // Water vortex displaces the player
                if (trap.trapType === TrapType.WATER_VORTEX) {
                  playerPos.x += (Math.random() - 0.5) * 120;
                  playerPos.y += (Math.random() - 0.5) * 120;
                }
              }
            }
          }

          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.COOLDOWN;
            trap.timer = TRAP_COOLDOWN_TIME;
          }
          break;
        }

        case TrapState.COOLDOWN:
          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.IDLE;
          }
          break;
      }
    }
  }

  private shakeCamera(context: SystemContext, duration: number): void {
    const cameraEntity: Entity | null = context.world.findEntityByTag("camera");
    if (cameraEntity !== null) {
      const cam: CameraComponent | null = cameraEntity.getComponent<CameraComponent>("camera");
      if (cam !== null) {
        cam.shakeTimer = duration;
      }
    }
  }

  private setDamageFlash(context: SystemContext): void {
    const gsEntity: Entity | null = context.world.findEntityByTag("gameState");
    if (gsEntity !== null) {
      const gs: GameStateComponent | null = gsEntity.getComponent<GameStateComponent>("gameState");
      if (gs !== null) {
        gs.damageFlashTimer = 200;
      }
    }
  }
}
