"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SpriteCache = void 0;
class SpriteCache {
    constructor() {
        this.frames = new Map();
    }
    get(key) {
        return this.frames.get(key);
    }
    set(key, canvas) {
        this.frames.set(key, canvas);
    }
    has(key) {
        return this.frames.has(key);
    }
    size() {
        return this.frames.size;
    }
}
exports.SpriteCache = SpriteCache;
