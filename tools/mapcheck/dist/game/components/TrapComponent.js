"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TrapComponent = void 0;
class TrapComponent {
    constructor() {
        this.trapType = 0;
        this.state = 0;
        this.timer = 0;
        this.triggerRadius = 48;
        this.damage = 1;
        this.size = 16;
        this.extraData = [];
    }
    getType() { return "trap"; }
}
exports.TrapComponent = TrapComponent;
