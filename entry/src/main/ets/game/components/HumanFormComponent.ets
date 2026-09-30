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
    const result: Record<string, Object> = {} as Record<string, Object>;
    result["isHumanForm"] = this.isHumanForm as Object;
    result["humanFormStage"] = this.humanFormStage as Object;
    result["hasMask"] = this.hasMask as Object;
    result["maskFragments"] = this.maskFragments as Object;
    result["formEnergy"] = this.formEnergy as Object;
    result["formMaxEnergy"] = this.formMaxEnergy as Object;
    result["formCooldown"] = this.formCooldown as Object;
    return result;
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
