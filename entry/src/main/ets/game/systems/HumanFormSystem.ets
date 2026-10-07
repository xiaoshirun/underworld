import { System, SystemContext, Entity, HealthComponent } from '@qiuyu/engine';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { SkillComponent } from '../components/SkillComponent';
import {
  TRANSFORM_PASSIVE_REGEN, TRANSFORM_COOLDOWN, TRANSFORM_MAX_ENERGY,
  TRANSFORM_DRAIN_RATES, TRANSFORM_ATTACK_COSTS, TRANSFORM_ATTACK_COOLDOWNS,
  HUMAN_FORM_HP_BONUS, HUMAN_FORM_ACTIVE_SLOTS, HUMAN_FORM_PASSIVE_SLOTS,
  HumanFormStage, DEVOUR_ENERGY_GAIN,
} from '../GameConstants';

export class HumanFormSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const hf: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    if (hf === null) return;

    const dtSec: number = context.dt / 1000;

    if (!hf.isHumanForm) {
      // Passive regen when not in human form
      if (hf.hasMask && hf.formCooldown > 0) {
        hf.formCooldown -= context.dt;
        if (hf.formCooldown < 0) hf.formCooldown = 0;
      }

      // Auto-regen energy
      if (hf.hasMask && hf.formCooldown <= 0) {
        hf.formEnergy += TRANSFORM_PASSIVE_REGEN * dtSec;
        if (hf.formEnergy > hf.formMaxEnergy) hf.formEnergy = hf.formMaxEnergy;
      }

      // Check for transform activation (tool pressed + has mask + energy sufficient + cooldown ready)
      if (context.input.toolPressed && hf.hasMask && hf.formCooldown <= 0 && hf.formEnergy >= 20) {
        this.activateHumanForm(hf, skill, health);
        context.input.toolPressed = false;
      }
      return;
    }

    // In human form — drain energy
    const stageIndex: number = hf.humanFormStage >= 0 ? hf.humanFormStage : 0;
    const drainRate: number = TRANSFORM_DRAIN_RATES[stageIndex];
    hf.formEnergy -= drainRate * dtSec;

    // Animation timer
    if (hf.animTimer > 0) {
      hf.animTimer -= context.dt;
    }

    // Energy depleted — revert
    if (hf.formEnergy <= 0) {
      this.deactivateHumanForm(hf, skill, health);
    }
  }

  private activateHumanForm(hf: HumanFormComponent, skill: SkillComponent | null, health: HealthComponent | null): void {
    hf.isHumanForm = true;
    if (hf.humanFormStage < 0) hf.humanFormStage = HumanFormStage.PROTO;
    hf.formEnergy = hf.formMaxEnergy;
    hf.animTimer = 800; // Activation animation

    // Apply stage bonuses to skill slots
    if (skill !== null) {
      const stageIndex: number = hf.humanFormStage;
      skill.activeSlotCount = HUMAN_FORM_ACTIVE_SLOTS[stageIndex];
      skill.passiveSlotCount = HUMAN_FORM_PASSIVE_SLOTS[stageIndex];
    }

    // Apply HP bonus
    if (health !== null) {
      const bonus: number = HUMAN_FORM_HP_BONUS[hf.humanFormStage];
      const baseMax: number = health.max;
      health.max = Math.floor(baseMax * (1 + bonus));
      if (health.current > health.max) health.current = health.max;
    }
  }

  private deactivateHumanForm(hf: HumanFormComponent, skill: SkillComponent | null, health: HealthComponent | null): void {
    hf.isHumanForm = false;
    hf.formEnergy = 0;
    hf.formCooldown = TRANSFORM_COOLDOWN;
    hf.animTimer = 500; // Revert animation

    // Restore base skill slots
    if (skill !== null) {
      skill.activeSlotCount = 1; // PLAYER_ACTIVE_SLOTS_BASE
      skill.passiveSlotCount = 1; // PLAYER_PASSIVE_SLOTS_BASE
      if (skill.selectedActiveIndex >= skill.activeSkills.length) {
        skill.selectedActiveIndex = 0;
      }
    }

    // Restore base HP (remove bonus)
    if (health !== null) {
      const bonus: number = HUMAN_FORM_HP_BONUS[hf.humanFormStage >= 0 ? hf.humanFormStage : 0];
      health.max = Math.floor(health.max / (1 + bonus));
      if (health.current > health.max) health.current = health.max;
    }
  }
}
