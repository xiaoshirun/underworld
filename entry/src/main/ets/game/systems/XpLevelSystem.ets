import { System, SystemContext, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { LevelComponent } from '../components/LevelComponent';
import { XpPickupComponent } from '../components/XpPickupComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import {
  XP_COLLECT_RANGE, XP_MAGNET_RANGE,
  PLAYER_HP_PER_LEVEL,
  TRANSFORM_ENERGY_XP_ORB,
} from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';

export class XpLevelSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const level: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    if (playerPos === null || level === null || health === null) return;

    const audio: IAudioService = context.audio as IAudioService;

    for (let i: number = 0; i < entities.length; i++) {
      const orb: Entity = entities[i];
      if (!orb.active || orb.tag !== "xpOrb") continue;

      const orbPos: PositionComponent | null = orb.getComponent<PositionComponent>("Position");
      const pickup: XpPickupComponent | null = orb.getComponent<XpPickupComponent>("xpPickup");
      if (orbPos === null || pickup === null) continue;

      const dx: number = playerPos.x - orbPos.x;
      const dy: number = playerPos.y - orbPos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      // Magnet effect
      if (dist < XP_MAGNET_RANGE && dist > 1) {
        const pullSpeed: number = 3.0 * (1.0 - dist / XP_MAGNET_RANGE);
        orbPos.x += (dx / dist) * pullSpeed;
        orbPos.y += (dy / dist) * pullSpeed;
      }

      // Collect XP
      if (dist < XP_COLLECT_RANGE) {
        orb.active = false;
        level.xp += pickup.xpValue;

        // Human form energy bonus
        if (humanForm !== null && humanForm.isHumanForm) {
          humanForm.formEnergy += TRANSFORM_ENERGY_XP_ORB;
          if (humanForm.formEnergy > humanForm.formMaxEnergy) {
            humanForm.formEnergy = humanForm.formMaxEnergy;
          }
        }

        audio.playXpCollect();

        // Level up check (scaling XP curve)
        const xpNeeded: number = level.getXpNeeded();
        if (level.xp >= xpNeeded) {
          level.xp -= xpNeeded;
          level.level++;
          health.heal(PLAYER_HP_PER_LEVEL);
          if (health.current > health.max) {
            health.current = health.max;
          }
          // Increase max HP on level up
          health.max += PLAYER_HP_PER_LEVEL;
          audio.playLevelUp();
        }
      }
    }
  }
}
