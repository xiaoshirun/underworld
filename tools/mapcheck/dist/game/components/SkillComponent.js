"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SkillComponent = void 0;
const GameConstants_1 = require("../GameConstants");
class SkillComponent {
    constructor() {
        this.activeSkills = [];
        this.passiveSkills = [];
        this.activeSlotCount = GameConstants_1.PLAYER_ACTIVE_SLOTS_BASE;
        this.passiveSlotCount = GameConstants_1.PLAYER_PASSIVE_SLOTS_BASE;
        this.selectedActiveIndex = 0;
        this.skillCooldown = 0;
    }
    getType() { return "skill"; }
    getSelectedSkill() {
        if (this.selectedActiveIndex < 0 || this.selectedActiveIndex >= this.activeSkills.length) {
            return null;
        }
        return this.activeSkills[this.selectedActiveIndex];
    }
    getSkillByFamily(family) {
        for (let i = 0; i < this.activeSkills.length; i++) {
            if (this.activeSkills[i].family === family) {
                return this.activeSkills[i];
            }
        }
        return null;
    }
    hasFamily(family) {
        return this.getSkillByFamily(family) !== null;
    }
    serialize() {
        const activeData = [];
        for (let i = 0; i < this.activeSkills.length; i++) {
            const s = this.activeSkills[i];
            const slotRecord = {};
            slotRecord["family"] = s.family;
            slotRecord["tier"] = s.tier;
            slotRecord["skillXp"] = s.skillXp;
            activeData.push(slotRecord);
        }
        const passiveData = [];
        for (let i = 0; i < this.passiveSkills.length; i++) {
            const p = this.passiveSkills[i];
            const pRecord = {};
            pRecord["branch"] = p.branch;
            pRecord["level"] = p.level;
            passiveData.push(pRecord);
        }
        const result = {};
        result["activeSkills"] = activeData;
        result["passiveSkills"] = passiveData;
        result["activeSlotCount"] = this.activeSlotCount;
        result["passiveSlotCount"] = this.passiveSlotCount;
        result["selectedActiveIndex"] = this.selectedActiveIndex;
        result["skillCooldown"] = this.skillCooldown;
        return result;
    }
    deserialize(data) {
        const activeData = data["activeSkills"];
        this.activeSkills = [];
        if (activeData !== null && activeData !== undefined) {
            for (let i = 0; i < activeData.length; i++) {
                const s = activeData[i];
                const slot = { family: s["family"], tier: s["tier"], skillXp: s["skillXp"] };
                this.activeSkills.push(slot);
            }
        }
        const passiveData = data["passiveSkills"];
        this.passiveSkills = [];
        if (passiveData !== null && passiveData !== undefined) {
            for (let i = 0; i < passiveData.length; i++) {
                const p = passiveData[i];
                const slot = { branch: p["branch"], level: p["level"] };
                this.passiveSkills.push(slot);
            }
        }
        this.activeSlotCount = data["activeSlotCount"];
        this.passiveSlotCount = data["passiveSlotCount"];
        this.selectedActiveIndex = data["selectedActiveIndex"];
        this.skillCooldown = data["skillCooldown"];
    }
}
exports.SkillComponent = SkillComponent;
