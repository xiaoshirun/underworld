"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TransformComponent = void 0;
class TransformComponent {
    constructor() {
        this.isTransformed = false;
        this.transformForm = -1;
        this.savedWeaponForm = 0;
        this.currentWeaponForm = 0;
        this.transformEnergy = 0;
        this.transformMaxEnergy = 100;
        this.transformCooldown = 0;
        this.transformAnimTimer = 0;
        this.transformFormAttackCooldown = 0;
    }
    getType() { return "transform"; }
    serialize() {
        const result = {};
        result["isTransformed"] = this.isTransformed;
        result["transformForm"] = this.transformForm;
        result["savedWeaponForm"] = this.savedWeaponForm;
        result["currentWeaponForm"] = this.currentWeaponForm;
        result["transformEnergy"] = this.transformEnergy;
        result["transformMaxEnergy"] = this.transformMaxEnergy;
        result["transformCooldown"] = this.transformCooldown;
        return result;
    }
    deserialize(data) {
        this.isTransformed = data["isTransformed"];
        this.transformForm = data["transformForm"];
        this.savedWeaponForm = data["savedWeaponForm"];
        this.currentWeaponForm = data["currentWeaponForm"];
        this.transformEnergy = data["transformEnergy"];
        this.transformMaxEnergy = data["transformMaxEnergy"];
        this.transformCooldown = data["transformCooldown"];
    }
}
exports.TransformComponent = TransformComponent;
