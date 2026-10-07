"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.XpComponent = void 0;
class XpComponent {
    constructor() {
        this.xp = 0;
        this.level = 1;
    }
    getType() { return "xp"; }
    serialize() {
        const result = {};
        result["xp"] = this.xp;
        result["level"] = this.level;
        return result;
    }
    deserialize(data) {
        this.xp = data["xp"];
        this.level = data["level"];
    }
}
exports.XpComponent = XpComponent;
