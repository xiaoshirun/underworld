"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WorldEntityFactory = void 0;
const engine_1 = require("@qiuyu/engine");
const TrapComponent_1 = require("../components/TrapComponent");
const MechanismComponent_1 = require("../components/MechanismComponent");
const ChestComponent_1 = require("../components/ChestComponent");
class WorldEntityFactory {
    static createTrap(x, y, trapType) {
        const entity = new engine_1.Entity("trap");
        entity.addComponent(new engine_1.PositionComponent(x, y));
        const trap = new TrapComponent_1.TrapComponent();
        trap.trapType = trapType;
        entity.addComponent(trap);
        entity.addComponent(new engine_1.ColliderComponent(16, 16, 0, 0, false));
        return entity;
    }
    static createMechanism(x, y, mechanismType) {
        const entity = new engine_1.Entity("mechanism");
        entity.addComponent(new engine_1.PositionComponent(x, y));
        const mech = new MechanismComponent_1.MechanismComponent();
        mech.mechanismType = mechanismType;
        mech.posX = x;
        mech.posY = y;
        entity.addComponent(mech);
        entity.addComponent(new engine_1.ColliderComponent(16, 16, 0, 0, true));
        return entity;
    }
    static createChest(x, y, chestType) {
        const entity = new engine_1.Entity("chest");
        entity.addComponent(new engine_1.PositionComponent(x, y));
        const chest = new ChestComponent_1.ChestComponent();
        chest.chestType = chestType;
        entity.addComponent(chest);
        entity.addComponent(new engine_1.ColliderComponent(16, 16, 0, 0, true));
        return entity;
    }
}
exports.WorldEntityFactory = WorldEntityFactory;
