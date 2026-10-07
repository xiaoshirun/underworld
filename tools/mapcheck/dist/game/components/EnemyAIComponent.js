"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EnemyAIComponent = void 0;
class EnemyAIComponent {
    constructor() {
        this.enemyType = 0;
        this.bouncePhase = 0;
        this.hitFlash = 0;
        this.moveTimer = 0;
        this.targetX = 0;
        this.targetY = 0;
        this.isCharging = false;
        this.chargeTimer = 0;
        this.isEngulfing = false;
        this.engulfedPlayer = false;
        this.splitCount = 0;
        this.size = 12;
        this.level = 1;
        this.chargeDirX = 0;
        this.chargeDirY = 0;
    }
    getType() { return "enemyAI"; }
}
exports.EnemyAIComponent = EnemyAIComponent;
