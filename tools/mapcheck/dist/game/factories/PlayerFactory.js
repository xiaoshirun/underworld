"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlayerFactory = void 0;
const engine_1 = require("@qiuyu/engine");
const MovementComponent_1 = require("../components/MovementComponent");
const CombatComponent_1 = require("../components/CombatComponent");
const TransformComponent_1 = require("../components/TransformComponent");
const InventoryComponent_1 = require("../components/InventoryComponent");
const XpComponent_1 = require("../components/XpComponent");
const EvolutionComponent_1 = require("../components/EvolutionComponent");
const LevelComponent_1 = require("../components/LevelComponent");
const SkillComponent_1 = require("../components/SkillComponent");
const DevourComponent_1 = require("../components/DevourComponent");
const HumanFormComponent_1 = require("../components/HumanFormComponent");
const GameConstants_1 = require("../GameConstants");
class PlayerFactory {
    static create(startX, startY) {
        const entity = new engine_1.Entity("player");
        entity.addComponent(new engine_1.PositionComponent(startX, startY));
        entity.addComponent(new engine_1.VelocityComponent(0, 0));
        entity.addComponent(new engine_1.HealthComponent(GameConstants_1.PLAYER_MAX_HP, GameConstants_1.PLAYER_MAX_HP));
        entity.addComponent(new MovementComponent_1.MovementComponent());
        entity.addComponent(new CombatComponent_1.CombatComponent());
        entity.addComponent(new TransformComponent_1.TransformComponent()); // Kept for backward compat during transition
        entity.addComponent(new InventoryComponent_1.InventoryComponent());
        entity.addComponent(new XpComponent_1.XpComponent()); // Kept for backward compat during transition
        entity.addComponent(new EvolutionComponent_1.EvolutionComponent()); // Kept for backward compat during transition
        entity.addComponent(new engine_1.ColliderComponent(20, 20, 0, 0));
        // New gameplay components
        entity.addComponent(new LevelComponent_1.LevelComponent());
        entity.addComponent(new SkillComponent_1.SkillComponent());
        entity.addComponent(new DevourComponent_1.DevourComponent());
        entity.addComponent(new HumanFormComponent_1.HumanFormComponent());
        return entity;
    }
}
exports.PlayerFactory = PlayerFactory;
