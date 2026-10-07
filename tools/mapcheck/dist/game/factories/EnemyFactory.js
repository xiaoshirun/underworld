"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EnemyFactory = void 0;
const engine_1 = require("@qiuyu/engine");
const EnemyAIComponent_1 = require("../components/EnemyAIComponent");
const GameConstants_1 = require("../GameConstants");
class EnemyFactory {
    static createSlime(x, y, enemyType, level = 1) {
        const entity = new engine_1.Entity("enemy");
        entity.addComponent(new engine_1.PositionComponent(x, y));
        entity.addComponent(new engine_1.VelocityComponent(0, 0));
        const baseHp = EnemyFactory.getHpForType(enemyType);
        const scaledHp = Math.floor(baseHp * (1 + (level - 1) * GameConstants_1.MONSTER_HP_SCALE_PER_LEVEL));
        entity.addComponent(new engine_1.HealthComponent(scaledHp, scaledHp));
        const ai = new EnemyAIComponent_1.EnemyAIComponent();
        ai.enemyType = enemyType;
        ai.level = level;
        ai.size = GameConstants_1.SLIME_SIZE + Math.floor(level / GameConstants_1.MONSTER_SIZE_PER_4_LEVELS);
        entity.addComponent(ai);
        const size = ai.size;
        entity.addComponent(new engine_1.ColliderComponent(size, size, 0, 0, false));
        return entity;
    }
    static getHpForType(enemyType) {
        switch (enemyType) {
            case GameConstants_1.EnemyType.GRAY_SLIME: return GameConstants_1.SLIME_HP;
            case GameConstants_1.EnemyType.PURPLE_SLIME: return GameConstants_1.SLIME_HP + 1;
            case GameConstants_1.EnemyType.RED_SLIME: return GameConstants_1.SLIME_HP + 2;
            case GameConstants_1.EnemyType.BLUE_SLIME: return GameConstants_1.SLIME_HP;
            case GameConstants_1.EnemyType.YELLOW_SLIME: return GameConstants_1.SLIME_HP + 1;
            case GameConstants_1.EnemyType.GHOST_SLIME: return GameConstants_1.SLIME_HP + 1;
            case GameConstants_1.EnemyType.HUMANOID_BEAST: return GameConstants_1.HUMANOID_BEAST_HP;
            default: return GameConstants_1.SLIME_HP;
        }
    }
}
exports.EnemyFactory = EnemyFactory;
