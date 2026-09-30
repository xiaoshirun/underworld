import { System, SystemContext, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { XpComponent } from '../components/XpComponent';
import { XpPickupComponent } from '../components/XpPickupComponent';
import { TransformComponent } from '../components/TransformComponent';
import {
  PLAYER_MAX_HP, XP_COLLECT_RANGE, XP_MAGNET_RANGE, LEVEL_UP_XP,
  TRANSFORM_ENERGY_XP_ORB,
} from '../GameConstants';

interface AudioManager {
  playXpCollect(): void;
  playLevelUp(): void;
}

export class XpLevelSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const xp: XpComponent | null = player.getComponent<XpComponent>("xp");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const transform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
    if (playerPos === null || xp === null || health === null) return;

    const audio: AudioManager = context.audio as AudioManager;

    for (let i: number = 0; i < entities.length; i++) {
      const orb: Entity = entities[i];
      if (!orb.active || orb.tag !== "xpOrb") continue;

      const orbPos: PositionComponent | null = orb.getComponent<PositionComponent>("Position");
      const pickup: XpPickupComponent | null = orb.getComponent<XpPickupComponent>("xpPickup");
      if (orbPos === null || pickup === null) continue;

      const dx: number = playerPos.x - orbPos.x;
      const dy: number = playerPos.y - orbPos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      // Magnet effect: pull orb toward player
      if (dist < XP_MAGNET_RANGE && dist > 1) {
        const pullSpeed: number = 3.0 * (1.0 - dist / XP_MAGNET_RANGE);
        orbPos.x += (dx / dist) * pullSpeed;
        orbPos.y += (dy / dist) * pullSpeed;
      }

      // Collect XP
      if (dist < XP_COLLECT_RANGE) {
        orb.active = false;
        xp.xp += pickup.xpValue;

        // Transform energy bonus
        if (transform !== null && transform.isTransformed) {
          transform.transformEnergy += TRANSFORM_ENERGY_XP_ORB;
          if (transform.transformEnergy > transform.transformMaxEnergy) {
            transform.transformEnergy = transform.transformMaxEnergy;
          }
        }

        audio.playXpCollect();

        // Level up check
        if (xp.xp >= LEVEL_UP_XP) {
          xp.xp -= LEVEL_UP_XP;
          xp.level++;
          health.heal(1);
          if (health.current > PLAYER_MAX_HP) {
            health.current = PLAYER_MAX_HP;
          }
          audio.playLevelUp();
        }
      }
    }
  }
}
