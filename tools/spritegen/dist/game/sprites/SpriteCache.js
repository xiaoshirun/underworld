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
    set(key, bitmap) {
        this.frames.set(key, bitmap);
    }
    has(key) {
        return this.frames.has(key);
    }
    size() {
        return this.frames.size;
    }
}
exports.SpriteCache = SpriteCache;
