"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HumanFormComponent = void 0;
const GameConstants_1 = require("../GameConstants");
class HumanFormComponent {
    constructor() {
        this.isHumanForm = false;
        this.humanFormStage = GameConstants_1.HumanFormStage.NONE;
        this.hasMask = false;
        this.maskFragments = 0;
        this.formEnergy = 0;
        this.formMaxEnergy = GameConstants_1.TRANSFORM_MAX_ENERGY;
        this.formCooldown = 0;
        this.animTimer = 0;
    }
    getType() { return "humanForm"; }
    serialize() {
        const result = {};
        result["isHumanForm"] = this.isHumanForm;
        result["humanFormStage"] = this.humanFormStage;
        result["hasMask"] = this.hasMask;
        result["maskFragments"] = this.maskFragments;
        result["formEnergy"] = this.formEnergy;
        result["formMaxEnergy"] = this.formMaxEnergy;
        result["formCooldown"] = this.formCooldown;
        return result;
    }
    deserialize(data) {
        this.isHumanForm = data["isHumanForm"];
        this.humanFormStage = data["humanFormStage"];
        this.hasMask = data["hasMask"];
        this.maskFragments = data["maskFragments"];
        this.formEnergy = data["formEnergy"];
        this.formMaxEnergy = data["formMaxEnergy"];
        this.formCooldown = data["formCooldown"];
    }
}
exports.HumanFormComponent = HumanFormComponent;
