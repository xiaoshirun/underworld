import { Component, Serializable } from '@qiuyu/engine';

export class CombatComponent implements Component, Serializable {
  isAttacking: boolean = false;
  attackTimer: number = 0;
  invincibleTimer: number = 0;
  animFrame: number = 0;

  getType(): string { return "combat"; }

  serialize(): Record<string, Object> {
    return {
      attackTimer: this.attackTimer,
      invincibleTimer: this.invincibleTimer
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.attackTimer = data["attackTimer"] as number;
    this.invincibleTimer = data["invincibleTimer"] as number;
  }
}
