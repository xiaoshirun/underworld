import { System, SystemContext, Entity } from '@qiuyu/engine';
import { SkillComponent } from '../components/SkillComponent';
import { LevelComponent } from '../components/LevelComponent';
import { SKILL_STATS, PLAYER_DAMAGE_PER_LEVEL, SkillTier } from '../GameConstants';

export class SkillSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    if (skill === null) return;

    // Tick cooldown
    if (skill.skillCooldown > 0) {
      skill.skillCooldown -= context.dt;
      if (skill.skillCooldown < 0) {
        skill.skillCooldown = 0;
      }
    }
  }

  static getSkillDamage(family: number, tier: number, playerLevel: number): number {
    const tierIndex: number = tier - 1; // SkillTier.TIER_1 = 1 → index 0
    if (tierIndex < 0 || tierIndex >= SKILL_STATS[family].length) return 1;
    const baseDamage: number = SKILL_STATS[family][tierIndex][0];
    return baseDamage + Math.floor(playerLevel * PLAYER_DAMAGE_PER_LEVEL / 3);
  }

  static getSkillRange(family: number, tier: number): number {
    const tierIndex: number = tier - 1;
    if (tierIndex < 0 || tierIndex >= SKILL_STATS[family].length) return 30;
    return SKILL_STATS[family][tierIndex][1];
  }

  static getSkillCooldown(family: number, tier: number): number {
    const tierIndex: number = tier - 1;
    if (tierIndex < 0 || tierIndex >= SKILL_STATS[family].length) return 800;
    return SKILL_STATS[family][tierIndex][2];
  }

  static getSkillAoeRadius(family: number, tier: number): number {
    const tierIndex: number = tier - 1;
    if (tierIndex < 0 || tierIndex >= SKILL_STATS[family].length) return 0;
    return SKILL_STATS[family][tierIndex][3];
  }
}
