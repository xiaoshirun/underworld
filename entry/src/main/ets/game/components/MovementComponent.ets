import { Component, Serializable } from '@qiuyu/engine';

export class MovementComponent implements Component, Serializable {
  facing: number = 1;
  isJumping: boolean = false;
  jumpTimer: number = 0;
  jumpHeight: number = 0;
  isDashing: boolean = false;
  dashTimer: number = 0;
  dashCooldown: number = 0;
  dashDirX: number = 0;
  dashDirY: number = 0;
  isDrilling: boolean = false;
  drillTargetX: number = 0;
  drillTargetY: number = 0;
  drillHitCount: number = 0;
  isUsingTool: boolean = false;
  toolCooldown: number = 0;
  isEngulfed: boolean = false;
  engulfEscapeCount: number = 0;
  engulfDamageTimer: number = 0;

  getType(): string { return "movement"; }

  serialize(): Record<string, Object> {
    const result: Record<string, Object> = {} as Record<string, Object>;
    result["facing"] = this.facing as Object;
    result["isJumping"] = this.isJumping as Object;
    result["jumpTimer"] = this.jumpTimer as Object;
    result["jumpHeight"] = this.jumpHeight as Object;
    result["isDashing"] = this.isDashing as Object;
    result["dashTimer"] = this.dashTimer as Object;
    result["dashCooldown"] = this.dashCooldown as Object;
    return result;
  }

  deserialize(data: Record<string, Object>): void {
    this.facing = data["facing"] as number;
    this.isJumping = data["isJumping"] as boolean;
    this.jumpTimer = data["jumpTimer"] as number;
    this.jumpHeight = data["jumpHeight"] as number;
    this.isDashing = data["isDashing"] as boolean;
    this.dashTimer = data["dashTimer"] as number;
    this.dashCooldown = data["dashCooldown"] as number;
  }
}
