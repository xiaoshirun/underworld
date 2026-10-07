"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ColliderComponent = exports.SpriteComponent = exports.HealthComponent = exports.VelocityComponent = exports.PositionComponent = void 0;
class PositionComponent {
    constructor(x = 0, y = 0) {
        this.x = 0;
        this.y = 0;
        this.x = x;
        this.y = y;
    }
    getType() {
        return 'Position';
    }
}
exports.PositionComponent = PositionComponent;
class VelocityComponent {
    constructor(vx = 0, vy = 0) {
        this.vx = 0;
        this.vy = 0;
        this.vx = vx;
        this.vy = vy;
    }
    getType() {
        return 'Velocity';
    }
}
exports.VelocityComponent = VelocityComponent;
class HealthComponent {
    constructor(current = 100, max = 100) {
        this.current = 100;
        this.max = 100;
        this.current = current;
        this.max = max;
    }
    getType() {
        return 'Health';
    }
    isDead() {
        return this.current <= 0;
    }
    damage(amount) {
        this.current = Math.max(0, this.current - amount);
    }
    heal(amount) {
        this.current = Math.min(this.max, this.current + amount);
    }
}
exports.HealthComponent = HealthComponent;
class SpriteComponent {
    constructor() {
        this.color = '#ffffff';
        this.width = 16;
        this.height = 16;
        this.visible = true;
    }
    getType() {
        return 'Sprite';
    }
}
exports.SpriteComponent = SpriteComponent;
class ColliderComponent {
    constructor(width = 16, height = 16, offsetX = 0, offsetY = 0, isSolid = true) {
        this.width = 16;
        this.height = 16;
        this.offsetX = 0;
        this.offsetY = 0;
        this.isSolid = true;
        this.width = width;
        this.height = height;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
        this.isSolid = isSolid;
    }
    getType() {
        return 'Collider';
    }
}
exports.ColliderComponent = ColliderComponent;
