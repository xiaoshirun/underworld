import { Component, Serializable } from '@qiuyu/engine';

export class CombatComponent implements Component, Serializable {
  isAttacking: boolean = false;
  attackTimer: number = 0;
  invincibleTimer: number = 0;
  animFrame: number = 0;

  getType(): string { return "combat"; }

  serialize(): Record<string, Object> {
    const result: Record<string, Object> = {} as Record<string, Object>;
    result["attackTimer"] = this.attackTimer as Object;
    result["invincibleTimer"] = this.invincibleTimer as Object;
    return result;
  }

  deserialize(data: Record<string, Object>): void {
    this.attackTimer = data["attackTimer"] as number;
    this.invincibleTimer = data["invincibleTimer"] as number;
  }
}
