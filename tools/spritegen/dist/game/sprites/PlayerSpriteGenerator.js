"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.drawPlayerBody = drawPlayerBody;
exports.generatePlayerCache = generatePlayerCache;
const GameConstants_1 = require("../GameConstants");
const SpriteCache_1 = require("./SpriteCache");
function drawPlayerBody(c, centerX, centerY, walkPhase, facingRight, isMoving) {
    const bobY = Math.sin(walkPhase * Math.PI / 2) * 1.5;
    const walkPhaseSin = Math.sin(walkPhase * Math.PI / 2);
    const legSwing = isMoving ? walkPhaseSin * 3 : 0;
    const armSwing = isMoving ? walkPhaseSin * 2 : 0;
    const bodyColor = GameConstants_1.COLOR_PLAYER_BODY;
    const bodyDarkColor = GameConstants_1.COLOR_PLAYER_BODY_DARK;
    const hairColor = GameConstants_1.COLOR_PLAYER_HAIR;
    // Legs
    c.fillStyle = '#4a3728';
    c.fillRect(centerX - 4, centerY + 5 + bobY, 3, 7);
    c.fillStyle = '#3d2b1a';
    c.fillRect(centerX - 3, centerY + 6 + bobY, 1, 5);
    c.fillStyle = '#4a3728';
    c.fillRect(centerX + 1, centerY + 5 + bobY, 3, 7);
    c.fillStyle = '#3d2b1a';
    c.fillRect(centerX + 2, centerY + 6 + bobY, 1, 5);
    c.fillStyle = '#3d2b1a';
    c.fillRect(centerX - 5, centerY + 10 + bobY + legSwing, 4, 3);
    c.fillRect(centerX + 1, centerY + 10 + bobY + (-legSwing), 4, 3);
    c.fillStyle = '#5a4530';
    c.fillRect(centerX - 5, centerY + 10 + bobY + legSwing, 4, 1);
    c.fillRect(centerX + 1, centerY + 10 + bobY + (-legSwing), 4, 1);
    c.fillStyle = '#2a1a0a';
    c.fillRect(centerX - 5, centerY + 12 + bobY + legSwing, 4, 1);
    c.fillRect(centerX + 1, centerY + 12 + bobY + (-legSwing), 4, 1);
    // Torso
    c.fillStyle = bodyColor;
    c.fillRect(centerX - 5, centerY - 3 + bobY, 10, 9);
    c.fillStyle = bodyDarkColor;
    c.fillRect(centerX - 5, centerY + 3 + bobY, 10, 3);
    c.fillStyle = bodyDarkColor;
    c.globalAlpha = 0.4;
    c.fillRect(centerX - 3, centerY - 1 + bobY, 1, 5);
    c.fillRect(centerX + 2, centerY + 0 + bobY, 1, 4);
    c.globalAlpha = 1.0;
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.1;
    c.fillRect(centerX - 2, centerY - 2 + bobY, 4, 2);
    c.globalAlpha = 1.0;
    c.fillStyle = '#8b6914';
    c.fillRect(centerX - 5, centerY + 4 + bobY, 10, 2);
    c.fillStyle = '#6b4f0e';
    c.fillRect(centerX - 5, centerY + 4 + bobY, 10, 1);
    c.fillStyle = '#ffd700';
    c.fillRect(centerX - 1, centerY + 4 + bobY, 2, 2);
    c.fillStyle = '#fff8dc';
    c.fillRect(centerX - 1, centerY + 4 + bobY, 1, 1);
    // Arms
    c.fillStyle = bodyColor;
    c.fillRect(centerX - 7, centerY - 2 + bobY + (-armSwing), 3, 7);
    c.fillStyle = bodyDarkColor;
    c.fillRect(centerX - 7, centerY - 2 + bobY + (-armSwing), 3, 1);
    c.fillStyle = bodyColor;
    c.fillRect(centerX + 4, centerY - 2 + bobY + armSwing, 3, 7);
    c.fillStyle = bodyDarkColor;
    c.fillRect(centerX + 4, centerY - 2 + bobY + armSwing, 3, 1);
    c.fillStyle = GameConstants_1.COLOR_PLAYER_SKIN;
    c.fillRect(centerX - 7, centerY + 4 + bobY + (-armSwing), 3, 2);
    c.fillRect(centerX + 4, centerY + 4 + bobY + armSwing, 3, 2);
    c.fillStyle = '#e0b090';
    c.fillRect(centerX - 7, centerY + 5 + bobY + (-armSwing), 3, 1);
    c.fillRect(centerX + 4, centerY + 5 + bobY + armSwing, 3, 1);
    // Head
    c.fillStyle = GameConstants_1.COLOR_PLAYER_SKIN;
    c.fillRect(centerX - 4, centerY - 10 + bobY, 8, 7);
    c.fillStyle = '#e8c0a0';
    c.globalAlpha = 0.5;
    c.fillRect(centerX - 3, centerY - 5 + bobY, 2, 1);
    c.fillRect(centerX + 1, centerY - 5 + bobY, 2, 1);
    c.globalAlpha = 1.0;
    c.fillStyle = '#e0b090';
    c.fillRect(centerX - 3, centerY - 4 + bobY, 6, 1);
    c.fillStyle = '#d4a882';
    c.fillRect(centerX, centerY - 6 + bobY, 1, 2);
    // Hair
    c.fillStyle = hairColor;
    c.fillRect(centerX - 5, centerY - 12 + bobY, 10, 4);
    c.fillRect(centerX - 6, centerY - 10 + bobY, 2, 5);
    c.fillRect(centerX + 4, centerY - 10 + bobY, 2, 5);
    // Hair highlight (male)
    c.fillStyle = '#9a5a3a';
    c.fillRect(centerX - 4, centerY - 11 + bobY, 2, 1);
    c.fillRect(centerX + 1, centerY - 12 + bobY, 3, 1);
    c.fillRect(centerX - 2, centerY - 10 + bobY, 1, 2);
    // Hair shadow (male)
    c.fillStyle = '#4a2a10';
    c.fillRect(centerX - 3, centerY - 9 + bobY, 1, 3);
    c.fillRect(centerX + 3, centerY - 10 + bobY, 1, 2);
    c.fillRect(centerX, centerY - 11 + bobY, 1, 1);
    // Eyes
    const eyeOffX = facingRight ? 0 : -1;
    c.fillStyle = '#ffffff';
    c.fillRect(centerX - 2 + eyeOffX, centerY - 8 + bobY, 3, 3);
    c.fillRect(centerX + 1 + eyeOffX, centerY - 8 + bobY, 3, 3);
    c.fillStyle = '#4a90d9';
    c.fillRect(centerX - 1 + eyeOffX, centerY - 7 + bobY, 2, 2);
    c.fillRect(centerX + 2 + eyeOffX, centerY - 7 + bobY, 2, 2);
    c.fillStyle = '#1a1a2e';
    c.fillRect(centerX - 1 + eyeOffX, centerY - 7 + bobY, 1, 1);
    c.fillRect(centerX + 2 + eyeOffX, centerY - 7 + bobY, 1, 1);
    c.fillStyle = '#ffffff';
    c.fillRect(centerX - 1 + eyeOffX, centerY - 8 + bobY, 1, 1);
    c.fillRect(centerX + 2 + eyeOffX, centerY - 8 + bobY, 1, 1);
    c.globalAlpha = 0.6;
    c.fillRect(centerX + eyeOffX, centerY - 6 + bobY, 1, 1);
    c.fillRect(centerX + 3 + eyeOffX, centerY - 6 + bobY, 1, 1);
    c.globalAlpha = 1.0;
    // Eyebrows (hair colored)
    c.fillStyle = hairColor;
    c.fillRect(centerX - 2 + eyeOffX, centerY - 9 + bobY, 3, 1);
    c.fillRect(centerX + 1 + eyeOffX, centerY - 9 + bobY, 3, 1);
    // Mouth
    c.fillStyle = '#c0846a';
    c.fillRect(centerX, centerY - 4 + bobY, 2, 1);
    c.fillStyle = '#a06850';
    c.fillRect(centerX, centerY - 4 + bobY, 2, 1);
}
const PLAYER_CELL_W = 64;
const PLAYER_CELL_H = 64;
function generatePlayerCache() {
    const cache = new SpriteCache_1.SpriteCache();
    const centerX = PLAYER_CELL_W / 2;
    const centerY = PLAYER_CELL_H / 2 + 4; // Slight offset downward to center body
    // Idle frames (walkPhase=0, isMoving=false)
    for (let f = 0; f < 2; f++) {
        const facingRight = f === 0;
        const canvas = new OffscreenCanvas(PLAYER_CELL_W, PLAYER_CELL_H);
        const ctx = canvas.getContext('2d');
        drawPlayerBody(ctx, centerX, centerY, 0, facingRight, false);
        const key = facingRight ? 'body_idle_R' : 'body_idle_L';
        cache.set(key, canvas);
    }
    // Walk frames (4 phases x 2 directions)
    for (let phase = 0; phase < 4; phase++) {
        for (let f = 0; f < 2; f++) {
            const facingRight = f === 0;
            const canvas = new OffscreenCanvas(PLAYER_CELL_W, PLAYER_CELL_H);
            const ctx = canvas.getContext('2d');
            drawPlayerBody(ctx, centerX, centerY, phase, facingRight, true);
            const dir = facingRight ? 'R' : 'L';
            const key = `body_walk_${dir}_${phase}`;
            cache.set(key, canvas);
        }
    }
    return cache;
}
