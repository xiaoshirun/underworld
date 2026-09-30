import { System, SystemContext, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { LevelComponent } from '../components/LevelComponent';
import { SkillComponent } from '../components/SkillComponent';
import { DevourComponent } from '../components/DevourComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import {
  DEVOUR_RANGE, DEVOUR_ANIM_DURATION,
  DEVOUR_BASE_SKILL_CHANCE, DEVOUR_SKILL_CHANCE_PER_LEVEL, DEVOUR_SKILL_CHANCE_CAP,
  DEVOUR_ENERGY_GAIN, DEVOUR_THRESHOLD_SAME_LEVEL, DEVOUR_THRESHOLD_HIGHER_LEVEL,
  DEVOUR_THRESHOLD_BOSS, DEVOUR_THRESHOLD_HUMANOID,
  SKILL_XP_PER_DEVOUR_SAME, SKILL_XP_PER_DEVOUR_OTHER,
  SKILL_TIER_2_XP, SKILL_TIER_3_XP,
  ENEMY_TYPE_TO_SKILL_FAMILY, SkillFamily, SkillTier, DevourState,
  HUMANOID_SPAWN_CHANCE, MASK_FRAGMENTS_NEEDED,
  SkillSlot,
} from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';

export class DevourSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const playerLevel: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const playerSkill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const devour: DevourComponent | null = player.getComponent<DevourComponent>("devour");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    if (playerPos === null || playerLevel === null || playerSkill === null || devour === null) return;

    const audio: IAudioService = context.audio as IAudioService;
    const dt: number = context.dt;

    // Update devour animation timer
    if (devour.state === DevourState.DEVOURING) {
      devour.devourTimer -= dt;
      if (devour.devourTimer <= 0) {
        devour.state = DevourState.IDLE;
        devour.devourTargetId = -1;
      }
      return; // Can't initiate new devour during animation
    }

    if (devour.state === DevourState.COOLDOWN) {
      devour.devourTimer -= dt;
      if (devour.devourTimer <= 0) {
        devour.state = DevourState.IDLE;
      }
      return;
    }

    // Check for devour input (attack pressed near weakened enemy)
    if (!context.input.attackPressed) return;

    // Find nearest enemy within devour range that meets HP threshold
    const nearby: Entity[] = context.world.getSpatialGrid().queryRadius(playerPos.x, playerPos.y, DEVOUR_RANGE + 30);
    let bestTarget: Entity | null = null;
    let bestDist: number = DEVOUR_RANGE + 1;

    for (let i: number = 0; i < nearby.length; i++) {
      const e: Entity = nearby[i];
      if (!e.active || (e.tag !== "enemy" && e.tag !== "boss")) continue;

      const ePos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const eHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
      if (ePos === null || eHealth === null) continue;

      const dx: number = ePos.x - playerPos.x;
      const dy: number = ePos.y - playerPos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist > DEVOUR_RANGE) continue;

      // Check HP threshold
      const hpFraction: number = eHealth.current / eHealth.max;
      let canDevour: boolean = false;

      if (e.tag === "enemy") {
        const ai: EnemyAIComponent | null = e.getComponent<EnemyAIComponent>("enemyAI");
        if (ai === null) continue;
        const enemyLevel: number = ai.level;

        if (enemyLevel <= playerLevel.level) {
          canDevour = hpFraction < DEVOUR_THRESHOLD_SAME_LEVEL;
        } else {
          canDevour = hpFraction < DEVOUR_THRESHOLD_HIGHER_LEVEL;
        }
      } else if (e.tag === "boss") {
        canDevour = hpFraction < DEVOUR_THRESHOLD_BOSS;
      }

      if (canDevour && dist < bestDist) {
        bestTarget = e;
        bestDist = dist;
      }
    }

    if (bestTarget === null) return; // No valid devour target — let normal attack proceed

    // Consume the attack input so PlayerCombatSystem doesn't also fire
    context.input.attackPressed = false;

    // Execute devour
    const targetHealth: HealthComponent = bestTarget.getComponent<HealthComponent>("Health")!;
    const targetPos: PositionComponent = bestTarget.getComponent<PositionComponent>("Position")!;

    bestTarget.active = false;

    // Start devour animation
    devour.state = DevourState.DEVOURING;
    devour.devourTimer = DEVOUR_ANIM_DURATION;

    // Grant XP
    let monsterLevel: number = 1;
    let isBoss: boolean = false;
    let isHumanoid: boolean = false;
    let skillFamily: number = SkillFamily.BOUNCE;

    if (bestTarget.tag === "enemy") {
      const ai: EnemyAIComponent | null = bestTarget.getComponent<EnemyAIComponent>("enemyAI");
      if (ai !== null) {
        monsterLevel = ai.level;
        skillFamily = ENEMY_TYPE_TO_SKILL_FAMILY[ai.enemyType] as number;
        isHumanoid = ai.enemyType === 6; // HUMANOID_BEAST type
      }
    } else {
      isBoss = true;
      monsterLevel = 5; // Boss minimum level
    }

    const xpGained: number = 3 + monsterLevel * 2;
    playerLevel.xp += xpGained;

    // Human form: mask fragment drop
    if (isHumanoid && humanForm !== null && !humanForm.hasMask) {
      humanForm.maskFragments++;
      if (humanForm.maskFragments >= MASK_FRAGMENTS_NEEDED) {
        humanForm.hasMask = true;
      }
    }

    // Skill acquisition chance
    const skillChance: number = Math.min(
      DEVOUR_BASE_SKILL_CHANCE + monsterLevel * DEVOUR_SKILL_CHANCE_PER_LEVEL,
      DEVOUR_SKILL_CHANCE_CAP
    );

    if (Math.random() < skillChance) {
      this.grantSkill(playerSkill, skillFamily);
    } else {
      // Even on failed skill acquisition, grant skill XP for the family
      this.addSkillXp(playerSkill, skillFamily, SKILL_XP_PER_DEVOUR_OTHER);
    }

    // Human form energy
    if (humanForm !== null && humanForm.isHumanForm) {
      humanForm.formEnergy += DEVOUR_ENERGY_GAIN;
      if (humanForm.formEnergy > humanForm.formMaxEnergy) {
        humanForm.formEnergy = humanForm.formMaxEnergy;
      }
    }

    audio.playEnemyDeath();
  }

  private grantSkill(skillComp: SkillComponent, family: number): void {
    const existing: SkillSlot | null = skillComp.getSkillByFamily(family);
    if (existing !== null) {
      // Already have this family — add skill XP toward next tier
      this.addSkillXp(skillComp, family, SKILL_XP_PER_DEVOUR_SAME);
    } else {
      // New skill — add as tier 1 if slot available
      if (skillComp.activeSkills.length < skillComp.activeSlotCount) {
        const slot: SkillSlot = { family: family, tier: SkillTier.TIER_1, skillXp: 0 };
        skillComp.activeSkills.push(slot);
      } else {
        // No slot available — add XP to closest family skill instead
        if (skillComp.activeSkills.length > 0) {
          this.addSkillXp(skillComp, skillComp.activeSkills[0].family, SKILL_XP_PER_DEVOUR_SAME);
        }
      }
    }
  }

  private addSkillXp(skillComp: SkillComponent, family: number, amount: number): void {
    const slot: SkillSlot | null = skillComp.getSkillByFamily(family);
    if (slot === null) return;

    slot.skillXp += amount;

    // Check tier progression
    if (slot.tier === SkillTier.TIER_1 && slot.skillXp >= SKILL_TIER_2_XP) {
      slot.tier = SkillTier.TIER_2;
      slot.skillXp -= SKILL_TIER_2_XP;
    } else if (slot.tier === SkillTier.TIER_2 && slot.skillXp >= SKILL_TIER_3_XP) {
      slot.tier = SkillTier.TIER_3;
      slot.skillXp -= SKILL_TIER_3_XP;
    }
  }
}
