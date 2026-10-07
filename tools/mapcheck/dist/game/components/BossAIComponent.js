"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BossAIComponent = void 0;
class BossAIComponent {
    constructor() {
        this.bossType = 0;
        this.bossRole = 0;
        this.phase = 0;
        this.attackTimer = 0;
        this.specialTimer = 0;
        this.defeated = false;
        this.active = true;
        this.aggroRadius = 9999;
        this.extraData = [];
    }
    getType() { return "bossAI"; }
}
exports.BossAIComponent = BossAIComponent;
