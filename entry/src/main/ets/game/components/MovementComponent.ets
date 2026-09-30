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
    return {
      facing: this.facing, isJumping: this.isJumping,
      jumpTimer: this.jumpTimer, jumpHeight: this.jumpHeight,
      isDashing: this.isDashing, dashTimer: this.dashTimer,
      dashCooldown: this.dashCooldown
    };
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
