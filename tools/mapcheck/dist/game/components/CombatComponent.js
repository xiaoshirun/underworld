"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CombatComponent = void 0;
class CombatComponent {
    constructor() {
        this.isAttacking = false;
        this.attackTimer = 0;
        this.invincibleTimer = 0;
        this.animFrame = 0;
    }
    getType() { return "combat"; }
    serialize() {
        const result = {};
        result["attackTimer"] = this.attackTimer;
        result["invincibleTimer"] = this.invincibleTimer;
        return result;
    }
    deserialize(data) {
        this.attackTimer = data["attackTimer"];
        this.invincibleTimer = data["invincibleTimer"];
    }
}
exports.CombatComponent = CombatComponent;
