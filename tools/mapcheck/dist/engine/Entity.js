"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Entity = void 0;
let nextEntityId = 0;
class Entity {
    constructor(tag = "") {
        this.components = new Map();
        this.active = true;
        this.id = nextEntityId++;
        this.tag = tag;
    }
    addComponent(component) {
        this.components.set(component.getType(), component);
        return component;
    }
    getComponent(type) {
        return this.components.get(type) ?? null;
    }
    hasComponent(type) {
        return this.components.has(type);
    }
    removeComponent(type) {
        this.components.delete(type);
    }
    getAllComponents() {
        return Array.from(this.components.values());
    }
}
exports.Entity = Entity;
