"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HumanoidBeastSystem = void 0;
const engine_1 = require("@qiuyu/engine");
const GameConstants_1 = require("../GameConstants");
class HumanoidBeastSystem extends engine_1.System {
    update(entities, context) {
        // No per-frame logic — spawn check happens in ChunkLoadSystem
    }
    static shouldReplaceWithHumanoid() {
        return Math.random() < GameConstants_1.HUMANOID_SPAWN_CHANCE;
    }
    static getHumanoidType() {
        return GameConstants_1.EnemyType.HUMANOID_BEAST;
    }
}
exports.HumanoidBeastSystem = HumanoidBeastSystem;
