"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BossFactory = void 0;
const engine_1 = require("@qiuyu/engine");
const BossAIComponent_1 = require("../components/BossAIComponent");
const GameConstants_1 = require("../GameConstants");
class BossFactory {
    static create(x, y, bossType, bossRole) {
        const entity = new engine_1.Entity("boss");
        entity.addComponent(new engine_1.PositionComponent(x, y));
        entity.addComponent(new engine_1.VelocityComponent(0, 0));
        entity.addComponent(new engine_1.HealthComponent(GameConstants_1.BOSS_HP, GameConstants_1.BOSS_HP));
        const ai = new BossAIComponent_1.BossAIComponent();
        ai.bossType = bossType;
        ai.bossRole = bossRole;
        entity.addComponent(ai);
        entity.addComponent(new engine_1.ColliderComponent(GameConstants_1.BOSS_SIZE, GameConstants_1.BOSS_SIZE, 0, 0, false));
        return entity;
    }
}
exports.BossFactory = BossFactory;
