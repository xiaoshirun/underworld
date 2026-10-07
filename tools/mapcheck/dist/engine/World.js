"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.World = void 0;
const SpatialGrid_1 = require("./SpatialGrid");
class World {
    constructor() {
        this.entities = [];
        this.systems = [];
        this.spatialGrid = new SpatialGrid_1.SpatialGrid(128);
        this.chunks = new Map();
        this.worldGen = null;
        this.cameraX = 0;
        this.cameraY = 0;
        this.updateFrameCount = 0;
    }
    addEntity(entity) {
        this.entities.push(entity);
        return entity;
    }
    removeEntity(entity) {
        entity.active = false;
    }
    addSystem(system) {
        this.systems.push(system);
    }
    query(componentType) {
        const result = [];
        for (let i = 0; i < this.entities.length; i++) {
            const e = this.entities[i];
            if (e.active && e.hasComponent(componentType)) {
                result.push(e);
            }
        }
        return result;
    }
    queryWithTag(tag) {
        const result = [];
        for (let i = 0; i < this.entities.length; i++) {
            const e = this.entities[i];
            if (e.active && e.tag === tag) {
                result.push(e);
            }
        }
        return result;
    }
    findEntityByTag(tag) {
        for (let i = 0; i < this.entities.length; i++) {
            if (this.entities[i].active && this.entities[i].tag === tag) {
                return this.entities[i];
            }
        }
        return null;
    }
    rebuildSpatialGrid() {
        this.spatialGrid.clear();
        for (let i = 0; i < this.entities.length; i++) {
            const e = this.entities[i];
            if (e.active && e.hasComponent("Position")) {
                const pos = e.getComponent("Position");
                this.spatialGrid.insert(pos.x, pos.y, e);
            }
        }
    }
    getSpatialGrid() {
        return this.spatialGrid;
    }
    getEntities() {
        return this.entities;
    }
    update(context, dt) {
        const fc = this.updateFrameCount;
        if (fc < 5) {
            console.log('[World] update frame=' + fc + ' systems=' + this.systems.length + ' entities=' + this.entities.length + ' chunks=' + this.chunks.size + ' worldGen=' + (this.worldGen !== null));
        }
        for (let i = 0; i < this.systems.length; i++) {
            const sys = this.systems[i];
            if (sys.isEnabled()) {
                try {
                    sys.update(this.entities, context);
                }
                catch (e) {
                    console.error('[World] System #' + i + ' error: ' + String(e));
                }
            }
        }
        this.entities = this.entities.filter((e) => e.active);
        this.updateFrameCount++;
    }
}
exports.World = World;
