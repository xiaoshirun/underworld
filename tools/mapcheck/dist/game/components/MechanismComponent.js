"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MechanismComponent = void 0;
class MechanismComponent {
    constructor() {
        this.mechanismType = 0;
        this.active = false;
        this.linkedIndex = -1;
        this.rotation = 0;
        this.pushable = false;
        this.posX = 0;
        this.posY = 0;
        this.extraData = [];
    }
    getType() { return "mechanism"; }
}
exports.MechanismComponent = MechanismComponent;
