"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LevelComponent = void 0;
class LevelComponent {
    constructor() {
        this.level = 1;
        this.xp = 0;
    }
    getType() { return "level"; }
    getXpNeeded() {
        return 10 + (this.level - 1) * 5;
    }
    serialize() {
        const result = {};
        result["level"] = this.level;
        result["xp"] = this.xp;
        return result;
    }
    deserialize(data) {
        this.level = data["level"];
        this.xp = data["xp"];
    }
}
exports.LevelComponent = LevelComponent;
