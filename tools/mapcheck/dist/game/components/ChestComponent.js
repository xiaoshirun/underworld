"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChestComponent = void 0;
class ChestComponent {
    constructor() {
        this.chestType = 0;
        this.opened = false;
        this.openAnim = 0;
        this.lootText = "";
        this.lootTimer = 0;
    }
    getType() { return "chest"; }
}
exports.ChestComponent = ChestComponent;
