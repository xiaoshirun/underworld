"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shakeCamera = shakeCamera;
exports.triggerDamageFlash = triggerDamageFlash;
exports.getTile = getTile;
exports.setTile = setTile;
exports.isWalkable = isWalkable;
const GameConstants_1 = require("../GameConstants");
function shakeCamera(context, duration) {
    const cameraEntity = context.world.findEntityByTag("camera");
    if (cameraEntity !== null) {
        const cam = cameraEntity.getComponent("camera");
        if (cam !== null) {
            cam.shakeTimer = duration;
        }
    }
}
function triggerDamageFlash(context) {
    const gsEntity = context.world.findEntityByTag("gameState");
    if (gsEntity !== null) {
        const gs = gsEntity.getComponent("gameState");
        if (gs !== null) {
            gs.damageFlashTimer = 200;
        }
    }
}
function getTile(chunks, worldX, worldY) {
    const tx = Math.floor(worldX / GameConstants_1.TILE_SIZE);
    const ty = Math.floor(worldY / GameConstants_1.TILE_SIZE);
    const cx = Math.floor(tx / GameConstants_1.CHUNK_SIZE);
    const cy = Math.floor(ty / GameConstants_1.CHUNK_SIZE);
    const key = cx + ',' + cy;
    const chunk = chunks.get(key);
    if (chunk === undefined)
        return GameConstants_1.TileType.WALL;
    const lx = tx - cx * GameConstants_1.CHUNK_SIZE;
    const ly = ty - cy * GameConstants_1.CHUNK_SIZE;
    return chunk.tiles[ly][lx];
}
function setTile(chunks, worldX, worldY, tileType) {
    const tx = Math.floor(worldX / GameConstants_1.TILE_SIZE);
    const ty = Math.floor(worldY / GameConstants_1.TILE_SIZE);
    const cx = Math.floor(tx / GameConstants_1.CHUNK_SIZE);
    const cy = Math.floor(ty / GameConstants_1.CHUNK_SIZE);
    const key = cx + ',' + cy;
    const chunk = chunks.get(key);
    if (chunk === undefined)
        return;
    const lx = tx - cx * GameConstants_1.CHUNK_SIZE;
    const ly = ty - cy * GameConstants_1.CHUNK_SIZE;
    chunk.tiles[ly][lx] = tileType;
}
function isWalkable(tile) {
    return tile !== GameConstants_1.TileType.WALL && tile !== GameConstants_1.TileType.VOID;
}
