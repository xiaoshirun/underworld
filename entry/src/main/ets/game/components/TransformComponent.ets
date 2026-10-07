import { Component, Serializable } from '@qiuyu/engine';

export class TransformComponent implements Component, Serializable {
  isTransformed: boolean = false;
  transformForm: number = -1;
  savedWeaponForm: number = 0;
  currentWeaponForm: number = 0;
  transformEnergy: number = 0;
  transformMaxEnergy: number = 100;
  transformCooldown: number = 0;
  transformAnimTimer: number = 0;
  transformFormAttackCooldown: number = 0;

  getType(): string { return "transform"; }

  serialize(): Record<string, Object> {
    const result: Record<string, Object> = {} as Record<string, Object>;
    result["isTransformed"] = this.isTransformed as Object;
    result["transformForm"] = this.transformForm as Object;
    result["savedWeaponForm"] = this.savedWeaponForm as Object;
    result["currentWeaponForm"] = this.currentWeaponForm as Object;
    result["transformEnergy"] = this.transformEnergy as Object;
    result["transformMaxEnergy"] = this.transformMaxEnergy as Object;
    result["transformCooldown"] = this.transformCooldown as Object;
    return result;
  }

  deserialize(data: Record<string, Object>): void {
    this.isTransformed = data["isTransformed"] as boolean;
    this.transformForm = data["transformForm"] as number;
    this.savedWeaponForm = data["savedWeaponForm"] as number;
    this.currentWeaponForm = data["currentWeaponForm"] as number;
    this.transformEnergy = data["transformEnergy"] as number;
    this.transformMaxEnergy = data["transformMaxEnergy"] as number;
    this.transformCooldown = data["transformCooldown"] as number;
  }
}
