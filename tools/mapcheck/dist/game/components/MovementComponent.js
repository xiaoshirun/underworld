"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MovementComponent = void 0;
class MovementComponent {
    constructor() {
        this.facing = 1;
        this.isJumping = false;
        this.jumpTimer = 0;
        this.jumpHeight = 0;
        this.isDashing = false;
        this.dashTimer = 0;
        this.dashCooldown = 0;
        this.dashDirX = 0;
        this.dashDirY = 0;
        this.isDrilling = false;
        this.drillTargetX = 0;
        this.drillTargetY = 0;
        this.drillHitCount = 0;
        this.isUsingTool = false;
        this.toolCooldown = 0;
        this.isEngulfed = false;
        this.engulfEscapeCount = 0;
        this.engulfDamageTimer = 0;
    }
    getType() { return "movement"; }
    serialize() {
        const result = {};
        result["facing"] = this.facing;
        result["isJumping"] = this.isJumping;
        result["jumpTimer"] = this.jumpTimer;
        result["jumpHeight"] = this.jumpHeight;
        result["isDashing"] = this.isDashing;
        result["dashTimer"] = this.dashTimer;
        result["dashCooldown"] = this.dashCooldown;
        return result;
    }
    deserialize(data) {
        this.facing = data["facing"];
        this.isJumping = data["isJumping"];
        this.jumpTimer = data["jumpTimer"];
        this.jumpHeight = data["jumpHeight"];
        this.isDashing = data["isDashing"];
        this.dashTimer = data["dashTimer"];
        this.dashCooldown = data["dashCooldown"];
    }
}
exports.MovementComponent = MovementComponent;
