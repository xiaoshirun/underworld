"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DevourComponent = void 0;
const GameConstants_1 = require("../GameConstants");
class DevourComponent {
    constructor() {
        this.state = GameConstants_1.DevourState.IDLE;
        this.devourTimer = 0;
        this.devourTargetId = -1;
    }
    getType() { return "devour"; }
    serialize() {
        const result = {};
        result["state"] = this.state;
        result["devourTimer"] = this.devourTimer;
        result["devourTargetId"] = this.devourTargetId;
        return result;
    }
    deserialize(data) {
        this.state = data["state"];
        this.devourTimer = data["devourTimer"];
        this.devourTargetId = data["devourTargetId"];
    }
}
exports.DevourComponent = DevourComponent;
