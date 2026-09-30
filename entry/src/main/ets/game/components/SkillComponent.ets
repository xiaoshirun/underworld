import { Component, Serializable } from '@qiuyu/engine';
import { SkillSlot, PassiveSlot, PLAYER_ACTIVE_SLOTS_BASE, PLAYER_PASSIVE_SLOTS_BASE } from '../GameConstants';

export class SkillComponent implements Component, Serializable {
  activeSkills: SkillSlot[] = [];
  passiveSkills: PassiveSlot[] = [];
  activeSlotCount: number = PLAYER_ACTIVE_SLOTS_BASE;
  passiveSlotCount: number = PLAYER_PASSIVE_SLOTS_BASE;
  selectedActiveIndex: number = 0;
  skillCooldown: number = 0;

  getType(): string { return "skill"; }

  getSelectedSkill(): SkillSlot | null {
    if (this.selectedActiveIndex < 0 || this.selectedActiveIndex >= this.activeSkills.length) {
      return null;
    }
    return this.activeSkills[this.selectedActiveIndex];
  }

  getSkillByFamily(family: number): SkillSlot | null {
    for (let i: number = 0; i < this.activeSkills.length; i++) {
      if (this.activeSkills[i].family === family) {
        return this.activeSkills[i];
      }
    }
    return null;
  }

  hasFamily(family: number): boolean {
    return this.getSkillByFamily(family) !== null;
  }

  serialize(): Record<string, Object> {
    const activeData: Object[] = [];
    for (let i: number = 0; i < this.activeSkills.length; i++) {
      const s: SkillSlot = this.activeSkills[i];
      activeData.push({ family: s.family, tier: s.tier, skillXp: s.skillXp } as Object);
    }
    const passiveData: Object[] = [];
    for (let i: number = 0; i < this.passiveSkills.length; i++) {
      const p: PassiveSlot = this.passiveSkills[i];
      passiveData.push({ branch: p.branch, level: p.level } as Object);
    }
    return {
      activeSkills: activeData,
      passiveSkills: passiveData,
      activeSlotCount: this.activeSlotCount,
      passiveSlotCount: this.passiveSlotCount,
      selectedActiveIndex: this.selectedActiveIndex,
      skillCooldown: this.skillCooldown
    };
  }

  deserialize(data: Record<string, Object>): void {
    const activeData: Object[] = data["activeSkills"] as Object[];
    this.activeSkills = [];
    if (activeData !== null && activeData !== undefined) {
      for (let i: number = 0; i < activeData.length; i++) {
        const s: Record<string, Object> = activeData[i] as Record<string, Object>;
        const slot: SkillSlot = { family: s["family"] as number, tier: s["tier"] as number, skillXp: s["skillXp"] as number };
        this.activeSkills.push(slot);
      }
    }
    const passiveData: Object[] = data["passiveSkills"] as Object[];
    this.passiveSkills = [];
    if (passiveData !== null && passiveData !== undefined) {
      for (let i: number = 0; i < passiveData.length; i++) {
        const p: Record<string, Object> = passiveData[i] as Record<string, Object>;
        const slot: PassiveSlot = { branch: p["branch"] as number, level: p["level"] as number };
        this.passiveSkills.push(slot);
      }
    }
    this.activeSlotCount = data["activeSlotCount"] as number;
    this.passiveSlotCount = data["passiveSlotCount"] as number;
    this.selectedActiveIndex = data["selectedActiveIndex"] as number;
    this.skillCooldown = data["skillCooldown"] as number;
  }
}
