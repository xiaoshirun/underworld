"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MonsterLevelSystem = void 0;
const engine_1 = require("@qiuyu/engine");
const GameConstants_1 = require("../GameConstants");
class MonsterLevelSystem extends engine_1.System {
    update(entities, context) {
        // No per-frame logic — level assignment happens at spawn time in ChunkLoadSystem
    }
    static calculateLevel(chunkDistance) {
        // chunkDistance = max(|dx|, |dy|) from spawn chunk
        let minLevel = GameConstants_1.MONSTER_MIN_LEVEL;
        let maxLevel = GameConstants_1.MONSTER_MIN_LEVEL;
        if (chunkDistance <= 2) {
            minLevel = 1;
            maxLevel = 2;
        }
        else if (chunkDistance <= 5) {
            minLevel = 2;
            maxLevel = 4;
        }
        else if (chunkDistance <= 8) {
            minLevel = 3;
            maxLevel = 6;
        }
        else {
            minLevel = 5;
            maxLevel = GameConstants_1.MONSTER_MAX_LEVEL;
        }
        return minLevel + Math.floor(Math.random() * (maxLevel - minLevel + 1));
    }
}
exports.MonsterLevelSystem = MonsterLevelSystem;
