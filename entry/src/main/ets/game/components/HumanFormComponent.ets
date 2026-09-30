import { Component, Serializable } from '@qiuyu/engine';
import { HumanFormStage, TRANSFORM_MAX_ENERGY, TRANSFORM_COOLDOWN } from '../GameConstants';

export class HumanFormComponent implements Component, Serializable {
  isHumanForm: boolean = false;
  humanFormStage: number = HumanFormStage.NONE;
  hasMask: boolean = false;
  maskFragments: number = 0;
  formEnergy: number = 0;
  formMaxEnergy: number = TRANSFORM_MAX_ENERGY;
  formCooldown: number = 0;
  animTimer: number = 0;

  getType(): string { return "humanForm"; }

  serialize(): Record<string, Object> {
    return {
      isHumanForm: this.isHumanForm,
      humanFormStage: this.humanFormStage,
      hasMask: this.hasMask,
      maskFragments: this.maskFragments,
      formEnergy: this.formEnergy,
      formMaxEnergy: this.formMaxEnergy,
      formCooldown: this.formCooldown
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.isHumanForm = data["isHumanForm"] as boolean;
    this.humanFormStage = data["humanFormStage"] as number;
    this.hasMask = data["hasMask"] as boolean;
    this.maskFragments = data["maskFragments"] as number;
    this.formEnergy = data["formEnergy"] as number;
    this.formMaxEnergy = data["formMaxEnergy"] as number;
    this.formCooldown = data["formCooldown"] as number;
  }
}
