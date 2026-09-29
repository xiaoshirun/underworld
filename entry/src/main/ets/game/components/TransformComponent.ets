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
    return {
      isTransformed: this.isTransformed,
      transformForm: this.transformForm,
      savedWeaponForm: this.savedWeaponForm,
      currentWeaponForm: this.currentWeaponForm,
      transformEnergy: this.transformEnergy,
      transformMaxEnergy: this.transformMaxEnergy,
      transformCooldown: this.transformCooldown
    };
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
