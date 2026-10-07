"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.drawGraySlime = drawGraySlime;
exports.drawPurpleSlime = drawPurpleSlime;
exports.drawRedSlime = drawRedSlime;
exports.drawBlueSlime = drawBlueSlime;
exports.drawYellowSlime = drawYellowSlime;
exports.drawGhostSlime = drawGhostSlime;
exports.generateEnemyAtlas = generateEnemyAtlas;
const GameConstants_1 = require("../GameConstants");
const SpriteAtlas_1 = require("./SpriteAtlas");
const ColorUtils_1 = require("./ColorUtils");
const HumanoidBeastSprite_1 = require("./HumanoidBeastSprite");
function drawGraySlime(c, bouncePhase, size, flash, frameCount) {
    const sc = size / 48;
    const bounce = Math.sin(bouncePhase) * 3 * sc;
    const squash = 1 + Math.sin(bouncePhase) * 0.12;
    // Shadow
    c.globalAlpha = 0.2;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(0, bounce + 14 * sc, 13 * sc, 3 * sc, 0, 0, Math.PI * 2);
    c.fill();
    // Body (with squash/stretch applied via save/scale)
    c.save();
    c.translate(0, bounce);
    c.scale(squash, 1 / squash);
    if (flash) {
        // White damage-flash silhouette with soft volume
        c.strokeStyle = '#1a1a2e';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        const flashGrad = c.createRadialGradient(-4 * sc, -5 * sc, 2 * sc, 0, 0, 15 * sc);
        flashGrad.addColorStop(0, '#ffffff');
        flashGrad.addColorStop(0.6, '#f1f5f9');
        flashGrad.addColorStop(1, '#cbd5e1');
        c.globalAlpha = 0.95;
        c.fillStyle = flashGrad;
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    else {
        const base = GameConstants_1.COLOR_SLIME_GRAY;
        // Outline (drawn under the fill so ~1px ring stays visible)
        c.strokeStyle = '#1a1a2e';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.85;
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        // Body: radial volume gradient, light from upper-left
        const body = c.createRadialGradient(-4.5 * sc, -5.5 * sc, 1.5 * sc, 0, 0, 16 * sc);
        body.addColorStop(0, (0, ColorUtils_1.lighten)(base, 0.45));
        body.addColorStop(0.55, base);
        body.addColorStop(1, (0, ColorUtils_1.darken)(base, 0.5));
        c.globalAlpha = 0.95;
        c.fillStyle = body;
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Ground occlusion: smooth dark fade toward the bottom
        const ao = c.createLinearGradient(0, -1 * sc, 0, 12 * sc);
        ao.addColorStop(0, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.65), 0));
        ao.addColorStop(1, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.65), 0.5));
        c.globalAlpha = 1;
        c.fillStyle = ao;
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Rim light along the upper-left edge
        c.strokeStyle = GameConstants_1.COLOR_SLIME_GRAY_LIGHT;
        c.lineWidth = 1.3 * sc;
        c.globalAlpha = 0.55;
        c.beginPath();
        c.ellipse(0, 0, 13.2 * sc, 11.2 * sc, 0, Math.PI * 1.03, Math.PI * 1.5);
        c.stroke();
        // Soft top sheen
        c.fillStyle = (0, ColorUtils_1.lighten)(base, 0.55);
        c.globalAlpha = 0.2;
        c.beginPath();
        c.ellipse(-3.5 * sc, -4.5 * sc, 6.5 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
        c.fill();
        // Crisp specular + bounce glint
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.6;
        c.beginPath();
        c.ellipse(-5.5 * sc, -6 * sc, 2.6 * sc, 1.9 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 0.22;
        c.beginPath();
        c.ellipse(4 * sc, 3.5 * sc, 2.2 * sc, 1.5 * sc, 0.3, 0, Math.PI * 2);
        c.fill();
    }
    c.globalAlpha = 1.0;
    // Eyes. During the hit flash the body is white, so the sclera gets a dark
    // rim — otherwise the eyes melt into the flash and frame reads as a blank
    // white blob.
    for (let e = 0; e < 2; e++) {
        const ex = (e === 0 ? -4 : 4) * sc;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(ex, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
            c.strokeStyle = GameConstants_1.COLOR_SLIME_PUPIL;
            c.lineWidth = 0.8 * sc;
            c.globalAlpha = 0.9;
            c.stroke();
            c.globalAlpha = 1.0;
        }
    }
    // Pupils stay drawn during the flash so the hit frame keeps a face
    // (white-on-white eye shine would be invisible anyway — flash only).
    c.fillStyle = GameConstants_1.COLOR_SLIME_PUPIL;
    c.beginPath();
    c.arc(-3.5 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4.5 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        // Eye shine
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(-4 * sc, -1.2 * sc, 0.6 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(4 * sc, -1.2 * sc, 0.6 * sc, 0, Math.PI * 2);
        c.fill();
    }
    // Mouth (kept in flash frames too)
    c.strokeStyle = GameConstants_1.COLOR_SLIME_PUPIL;
    c.lineWidth = 1 * sc;
    c.beginPath();
    c.arc(0, 3.5 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
    c.stroke();
    c.restore();
}
function drawPurpleSlime(c, bouncePhase, size, flash, frameCount, isEngulfing) {
    const sc = size / 48;
    const bounce = Math.sin(bouncePhase * 1.3) * 1.5 * sc;
    c.save();
    c.translate(0, bounce);
    if (!flash) {
        c.globalAlpha = 0.12 + Math.sin(frameCount * 0.05) * 0.05;
        c.fillStyle = GameConstants_1.COLOR_SLIME_PURPLE;
        c.beginPath();
        c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    c.globalAlpha = 0.25;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(0, 14 * sc, 13 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
    c.fill();
    for (let t = 0; t < 4; t++) {
        const angle = (t / 4) * Math.PI * 2 + frameCount * 0.03;
        const tx = Math.cos(angle) * 16 * sc;
        const ty = Math.sin(angle) * 10 * sc + 4 * sc;
        if (flash) {
            c.globalAlpha = 0.9;
            c.fillStyle = '#ffffff';
        }
        else {
            c.globalAlpha = 0.9;
            c.fillStyle = GameConstants_1.COLOR_SLIME_PURPLE;
        }
        c.beginPath();
        c.ellipse(tx, ty, 3 * sc, 2 * sc, angle, 0, Math.PI * 2);
        c.fill();
    }
    if (flash) {
        c.strokeStyle = '#1a0533';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(0, 0, 16 * sc, 14 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        const flashGrad = c.createRadialGradient(-5 * sc, -6 * sc, 2 * sc, 0, 0, 17 * sc);
        flashGrad.addColorStop(0, '#ffffff');
        flashGrad.addColorStop(0.6, '#f5f3ff');
        flashGrad.addColorStop(1, '#ddd6fe');
        c.globalAlpha = 0.95;
        c.fillStyle = flashGrad;
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    else {
        const base = GameConstants_1.COLOR_SLIME_PURPLE;
        c.strokeStyle = '#1a0533';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.85;
        c.beginPath();
        c.ellipse(0, 0, 16 * sc, 14 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        // Body: deep violet volume gradient
        const body = c.createRadialGradient(-4.5 * sc, -5.5 * sc, 1.5 * sc, 0, 0, 17 * sc);
        body.addColorStop(0, (0, ColorUtils_1.lighten)(base, 0.4));
        body.addColorStop(0.55, base);
        body.addColorStop(1, (0, ColorUtils_1.darken)(base, 0.55));
        c.globalAlpha = 0.92;
        c.fillStyle = body;
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Ground occlusion fade
        const ao = c.createLinearGradient(0, -1 * sc, 0, 13 * sc);
        ao.addColorStop(0, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.6), 0));
        ao.addColorStop(1, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.6), 0.5));
        c.globalAlpha = 1;
        c.fillStyle = ao;
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Rim light
        c.strokeStyle = GameConstants_1.COLOR_SLIME_PURPLE_LIGHT;
        c.lineWidth = 1.3 * sc;
        c.globalAlpha = 0.6;
        c.beginPath();
        c.ellipse(0, 0, 14.2 * sc, 12.2 * sc, 0, Math.PI * 1.03, Math.PI * 1.5);
        c.stroke();
        // Glossy top + crisp specular
        c.fillStyle = (0, ColorUtils_1.lighten)(base, 0.5);
        c.globalAlpha = 0.22;
        c.beginPath();
        c.ellipse(-3.5 * sc, -4.5 * sc, 6.5 * sc, 4.5 * sc, -0.3, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(-5.5 * sc, -6 * sc, 2.4 * sc, 1.7 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
        const dripPhase = (frameCount * 0.03) % 1;
        for (let d = 0; d < 3; d++) {
            const dx = (-6 + d * 6) * sc;
            const dy = 10 * sc + dripPhase * 8 * sc;
            const dAlpha = 0.6 * (1 - dripPhase);
            c.globalAlpha = dAlpha;
            c.fillStyle = GameConstants_1.COLOR_SLIME_PURPLE;
            c.beginPath();
            c.ellipse(dx, dy, 1.5 * sc, (2 + dripPhase * 3) * sc, 0, 0, Math.PI * 2);
            c.fill();
        }
    }
    c.globalAlpha = 1.0;
    // Eyes — rimmed during flash so the sclera doesn't melt into the white body
    for (let e = 0; e < 2; e++) {
        const ex = (e === 0 ? -4 : 4) * sc;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(ex, -2 * sc, 3.2 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
            c.strokeStyle = '#1a0533';
            c.lineWidth = 0.8 * sc;
            c.globalAlpha = 0.9;
            c.stroke();
            c.globalAlpha = 1.0;
        }
    }
    // Iris + pupils — kept during the flash (dark colors stay readable on white)
    c.fillStyle = '#ff0040';
    c.beginPath();
    c.arc(-3.5 * sc, -1.5 * sc, 1.8 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4.5 * sc, -1.5 * sc, 1.8 * sc, 0, Math.PI * 2);
    c.fill();
    c.fillStyle = '#1a1a2e';
    c.beginPath();
    c.arc(-3.5 * sc, -1.5 * sc, 0.9 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4.5 * sc, -1.5 * sc, 0.9 * sc, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        // Eye shine (white-on-white would be invisible in flash frames)
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(-4.2 * sc, -2.2 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(3.8 * sc, -2.2 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
    }
    // Angry brows + mouth — also kept so the flash frame keeps its expression
    c.strokeStyle = '#4c1d95';
    c.lineWidth = 1.5 * sc;
    c.beginPath();
    c.moveTo(-8 * sc, -6 * sc);
    c.lineTo(-2 * sc, -4.5 * sc);
    c.stroke();
    c.beginPath();
    c.moveTo(8 * sc, -6 * sc);
    c.lineTo(2 * sc, -4.5 * sc);
    c.stroke();
    if (isEngulfing) {
        c.fillStyle = '#2d1060';
        c.beginPath();
        c.ellipse(0, 5 * sc, 6 * sc, 5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = '#1a0533';
        c.beginPath();
        c.ellipse(0, 6 * sc, 3 * sc, 2.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    else {
        c.fillStyle = '#2d1060';
        c.beginPath();
        c.ellipse(0, 5 * sc, 5 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    c.restore();
}
function drawRedSlime(c, bouncePhase, size, flash, frameCount, isCharging) {
    const sc = size / 48;
    const charge = isCharging ? Math.abs(Math.sin(frameCount * 0.08)) : Math.abs(Math.sin(frameCount * 0.04)) * 0.3;
    c.save();
    c.translate(0, 0);
    if (!flash) {
        c.globalAlpha = 0.1 + charge * 0.1;
        c.fillStyle = '#ff4444';
        c.beginPath();
        c.ellipse(0, 0, (18 + charge * 2) * sc, (16 + charge * 2) * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    c.globalAlpha = 0.25;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(0, 13 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        for (let fi = 0; fi < 7; fi++) {
            const angle = -Math.PI * 0.8 + (fi / 6) * Math.PI * 0.6;
            const flicker = Math.sin(frameCount * 0.12 + fi * 1.5) * 3;
            const len = (6 + flicker + charge * 3) * sc;
            const sx = Math.cos(angle) * 12 * sc;
            const sy = Math.sin(angle) * 10 * sc;
            const ex = sx + Math.cos(angle) * len;
            const ey = sy + Math.sin(angle) * len;
            c.fillStyle = fi % 2 === 0 ? '#ff6600' : '#ffaa00';
            c.globalAlpha = 0.7;
            c.beginPath();
            c.moveTo(sx - 2 * sc, sy);
            c.lineTo(ex, ey);
            c.lineTo(sx + 2 * sc, sy);
            c.closePath();
            c.fill();
        }
        c.strokeStyle = '#7f1d1d';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.8;
        c.beginPath();
        c.ellipse(1 * sc, 0, 15 * sc, 12 * sc, 0.1, 0, Math.PI * 2);
        c.stroke();
    }
    c.globalAlpha = 1.0;
    const base = GameConstants_1.COLOR_SLIME_RED;
    if (flash) {
        const flashGrad = c.createRadialGradient(-3 * sc, -4 * sc, 2 * sc, 1 * sc, 0, 16 * sc);
        flashGrad.addColorStop(0, '#ffffff');
        flashGrad.addColorStop(0.6, '#fee2e2');
        flashGrad.addColorStop(1, '#fecaca');
        c.fillStyle = flashGrad;
    }
    else {
        const body = c.createRadialGradient(-3 * sc, -4 * sc, 1.5 * sc, 1 * sc, 0, 16 * sc);
        body.addColorStop(0, (0, ColorUtils_1.lighten)(base, 0.4));
        body.addColorStop(0.55, base);
        body.addColorStop(1, (0, ColorUtils_1.darken)(base, 0.55));
        c.fillStyle = body;
    }
    c.globalAlpha = 1;
    c.beginPath();
    c.ellipse(1 * sc, 0, 14 * sc, 11 * sc, 0.1, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        // Inner heat glow near the bottom (ember light)
        c.fillStyle = '#ff6600';
        c.globalAlpha = 0.14 + charge * 0.12;
        c.beginPath();
        c.ellipse(1 * sc, 4 * sc, 9 * sc, 5 * sc, 0.1, 0, Math.PI * 2);
        c.fill();
        // Ground occlusion fade
        const ao = c.createLinearGradient(0, -3 * sc, 0, 11 * sc);
        ao.addColorStop(0, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.6), 0));
        ao.addColorStop(1, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.6), 0.45));
        c.globalAlpha = 1;
        c.fillStyle = ao;
        c.beginPath();
        c.ellipse(1 * sc, 0, 14 * sc, 11 * sc, 0.1, 0, Math.PI * 2);
        c.fill();
        // Rim light (matches the tilted body)
        c.strokeStyle = GameConstants_1.COLOR_SLIME_RED_LIGHT;
        c.lineWidth = 1.3 * sc;
        c.globalAlpha = 0.6;
        c.beginPath();
        c.ellipse(1 * sc, 0, 13.2 * sc, 10.2 * sc, 0.1, Math.PI * 1.03, Math.PI * 1.5);
        c.stroke();
        c.fillStyle = GameConstants_1.COLOR_SLIME_RED_LIGHT;
        c.globalAlpha = 0.3;
        c.beginPath();
        c.ellipse(-2 * sc, -3.5 * sc, 6 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
        // Crisp specular
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(-4.5 * sc, -5 * sc, 2.4 * sc, 1.7 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
    }
    c.globalAlpha = 1.0;
    // Eyes — rimmed during flash so the sclera doesn't melt into the white body
    for (let e = 0; e < 2; e++) {
        const ex = (e === 0 ? -3.5 : 4) * sc;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(ex, -1.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
            c.strokeStyle = '#7f1d1d';
            c.lineWidth = 0.8 * sc;
            c.globalAlpha = 0.9;
            c.stroke();
            c.globalAlpha = 1.0;
        }
    }
    // Amber iris + pupils — kept during the flash (high contrast on white)
    c.fillStyle = '#ffcc00';
    c.beginPath();
    c.arc(-3 * sc, -1 * sc, 1.5 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4.5 * sc, -1 * sc, 1.5 * sc, 0, Math.PI * 2);
    c.fill();
    c.fillStyle = '#1a1a2e';
    c.beginPath();
    c.arc(-3 * sc, -1 * sc, 0.7 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4.5 * sc, -1 * sc, 0.7 * sc, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        // Eye shine (white-on-white would be invisible in flash frames)
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(-3.5 * sc, -1.8 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(4 * sc, -1.8 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
    }
    // Furious brows + fanged grin — also kept so the flash frame keeps its face
    c.strokeStyle = '#7f1d1d';
    c.lineWidth = 1.5 * sc;
    c.beginPath();
    c.moveTo(-7 * sc, -5 * sc);
    c.lineTo(-2 * sc, -3.5 * sc);
    c.stroke();
    c.beginPath();
    c.moveTo(7 * sc, -5 * sc);
    c.lineTo(2 * sc, -3.5 * sc);
    c.stroke();
    c.strokeStyle = '#7f1d1d';
    c.lineWidth = 1.2 * sc;
    c.beginPath();
    c.moveTo(-4 * sc, 4 * sc);
    c.lineTo(-2 * sc, 2.5 * sc);
    c.lineTo(0, 4 * sc);
    c.lineTo(2 * sc, 2.5 * sc);
    c.lineTo(4 * sc, 4 * sc);
    c.stroke();
    c.restore();
}
function drawBlueSlime(c, bouncePhase, size, flash, frameCount) {
    const sc = size / 48;
    const bounce = Math.sin(bouncePhase * 0.8) * 1.5 * sc;
    c.save();
    c.translate(0, bounce);
    if (!flash) {
        for (let d = 0; d < 6; d++) {
            const angle = (d / 6) * Math.PI * 2 + frameCount * 0.02;
            const dist = (16 + Math.sin(frameCount * 0.03 + d * 2) * 3) * sc;
            const dx = Math.cos(angle) * dist;
            const dy = Math.sin(angle) * dist * 0.7 - 2.5 * sc;
            c.fillStyle = GameConstants_1.COLOR_SLIME_BLUE_LIGHT;
            c.globalAlpha = 0.4 + Math.sin(frameCount * 0.04 + d) * 0.2;
            c.beginPath();
            c.moveTo(dx, dy - 2 * sc);
            c.lineTo(dx + 1 * sc, dy - 0.5 * sc);
            c.lineTo(dx + 2 * sc, dy);
            c.lineTo(dx + 1 * sc, dy + 0.5 * sc);
            c.lineTo(dx, dy + 2 * sc);
            c.lineTo(dx - 1 * sc, dy + 0.5 * sc);
            c.lineTo(dx - 2 * sc, dy);
            c.lineTo(dx - 1 * sc, dy - 0.5 * sc);
            c.closePath();
            c.fill();
        }
    }
    c.globalAlpha = 0.2;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(0, 13 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
    c.fill();
    if (flash) {
        c.strokeStyle = '#0c2d5e';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        const flashGrad = c.createRadialGradient(-4 * sc, -5 * sc, 2 * sc, 0, 0, 15 * sc);
        flashGrad.addColorStop(0, '#ffffff');
        flashGrad.addColorStop(0.6, '#eff6ff');
        flashGrad.addColorStop(1, '#bfdbfe');
        c.globalAlpha = 0.95;
        c.fillStyle = flashGrad;
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    else {
        const base = GameConstants_1.COLOR_SLIME_BLUE;
        c.strokeStyle = '#0c2d5e';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.85;
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        // Watery body: deep blue volume gradient
        const body = c.createRadialGradient(-4.5 * sc, -5.5 * sc, 1.5 * sc, 0, 0, 16 * sc);
        body.addColorStop(0, (0, ColorUtils_1.lighten)(base, 0.5));
        body.addColorStop(0.55, base);
        body.addColorStop(1, (0, ColorUtils_1.darken)(base, 0.55));
        c.globalAlpha = 0.92;
        c.fillStyle = body;
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Ground occlusion fade
        const ao = c.createLinearGradient(0, -1 * sc, 0, 12 * sc);
        ao.addColorStop(0, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.6), 0));
        ao.addColorStop(1, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.65), 0.5));
        c.globalAlpha = 1;
        c.fillStyle = ao;
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Icy rim light
        c.strokeStyle = '#93c5fd';
        c.lineWidth = 1.3 * sc;
        c.globalAlpha = 0.6;
        c.beginPath();
        c.ellipse(0, 0, 13.2 * sc, 11.2 * sc, 0, Math.PI * 1.03, Math.PI * 1.5);
        c.stroke();
        // Inner ripple
        c.globalAlpha = 0.3;
        c.fillStyle = GameConstants_1.COLOR_SLIME_BLUE_LIGHT;
        const rippleOff = Math.sin(frameCount * 0.04) * 1.5 * sc;
        c.beginPath();
        c.ellipse(0, rippleOff, 10 * sc, 7 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Sheen + crisp specular
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.15;
        c.beginPath();
        c.ellipse(-4 * sc, -5 * sc, 4 * sc, 3 * sc, -0.3, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(-5.5 * sc, -6 * sc, 2.4 * sc, 1.7 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
        // Flowing wave lines
        c.strokeStyle = '#93c5fd';
        c.lineWidth = 0.8 * sc;
        c.globalAlpha = 0.45;
        for (let w = 0; w < 3; w++) {
            const wy = (-3 + w * 4) * sc;
            const woff = Math.sin(frameCount * 0.05 + w) * 2 * sc;
            c.beginPath();
            c.moveTo(-8 * sc, wy + woff);
            c.quadraticCurveTo(0, wy - woff - 1.5 * sc, 8 * sc, wy + woff);
            c.stroke();
        }
    }
    c.globalAlpha = 1.0;
    // Eyes — rimmed during flash so the sclera doesn't melt into the white body
    for (let e = 0; e < 2; e++) {
        const ex = (e === 0 ? -3.5 : 3.5) * sc;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(ex, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
            c.strokeStyle = '#1e3a5f';
            c.lineWidth = 0.8 * sc;
            c.globalAlpha = 0.9;
            c.stroke();
            c.globalAlpha = 1.0;
        }
    }
    // Deep-blue pupils — kept during the flash so the frame keeps a gaze
    c.fillStyle = '#1e40af';
    c.beginPath();
    c.arc(-3 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        // Eye shine (white-on-white would be invisible in flash frames)
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(-3.5 * sc, -1.2 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(3.5 * sc, -1.2 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
    }
    // Mouth — also kept so the flash frame keeps its expression
    c.strokeStyle = '#1e3a5f';
    c.lineWidth = 1 * sc;
    c.beginPath();
    c.arc(0, 3 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
    c.stroke();
    c.restore();
}
function drawYellowSlime(c, bouncePhase, size, flash, frameCount) {
    const sc = size / 48;
    const bounce = Math.abs(Math.sin(bouncePhase * 1.1)) * 4 * sc;
    c.save();
    c.translate(0, -bounce);
    if (!flash) {
        c.globalAlpha = 0.08 + Math.sin(frameCount * 0.04) * 0.03;
        c.fillStyle = GameConstants_1.COLOR_SLIME_YELLOW_LIGHT;
        c.beginPath();
        c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
        c.fill();
        for (let sp = 0; sp < 8; sp++) {
            const angle = (sp / 8) * Math.PI * 2 + frameCount * 0.04;
            const dist = (14 + Math.sin(frameCount * 0.06 + sp * 3) * 4) * sc;
            const sx = Math.cos(angle) * dist;
            const sy = Math.sin(angle) * dist * 0.6;
            const sparkSize = (1 + Math.sin(frameCount * 0.1 + sp * 2) * 0.6) * sc;
            c.fillStyle = sp % 2 === 0 ? GameConstants_1.COLOR_SLIME_YELLOW_LIGHT : '#ffffff';
            c.globalAlpha = 0.6 + Math.sin(frameCount * 0.08 + sp) * 0.3;
            c.beginPath();
            c.moveTo(sx, sy - sparkSize * 2);
            c.lineTo(sx + sparkSize * 0.4, sy - sparkSize * 0.4);
            c.lineTo(sx + sparkSize * 2, sy);
            c.lineTo(sx + sparkSize * 0.4, sy + sparkSize * 0.4);
            c.lineTo(sx, sy + sparkSize * 2);
            c.lineTo(sx - sparkSize * 0.4, sy + sparkSize * 0.4);
            c.lineTo(sx - sparkSize * 2, sy);
            c.lineTo(sx - sparkSize * 0.4, sy - sparkSize * 0.4);
            c.closePath();
            c.fill();
        }
        if (frameCount % 10 < 3) {
            const boltAngle = (frameCount * 7) % 628 / 100;
            const boltDist = 10 * sc;
            const bx = Math.cos(boltAngle) * boltDist;
            const by = Math.sin(boltAngle) * boltDist * 0.6;
            c.strokeStyle = '#fef08a';
            c.lineWidth = 1 * sc;
            c.globalAlpha = 0.7;
            c.beginPath();
            c.moveTo(bx, by);
            c.lineTo(bx + 3 * sc, by - 2 * sc);
            c.lineTo(bx + 1 * sc, by - 1 * sc);
            c.lineTo(bx + 4 * sc, by - 4 * sc);
            c.stroke();
        }
    }
    c.globalAlpha = 0.15;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(0, (13 + bounce / sc) * sc, 11 * sc, 2.5 * sc, 0, 0, Math.PI * 2);
    c.fill();
    if (flash) {
        c.strokeStyle = '#78350f';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(0, 0, 13 * sc, 11 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        const flashGrad = c.createRadialGradient(-3.5 * sc, -4.5 * sc, 2 * sc, 0, 0, 14 * sc);
        flashGrad.addColorStop(0, '#ffffff');
        flashGrad.addColorStop(0.6, '#fefce8');
        flashGrad.addColorStop(1, '#fef08a');
        c.globalAlpha = 0.95;
        c.fillStyle = flashGrad;
        c.beginPath();
        c.ellipse(0, 0, 12 * sc, 10 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    else {
        const base = GameConstants_1.COLOR_SLIME_YELLOW;
        c.strokeStyle = '#78350f';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.85;
        c.beginPath();
        c.ellipse(0, 0, 13 * sc, 11 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        // Body: golden volume gradient
        const body = c.createRadialGradient(-4 * sc, -5 * sc, 1.5 * sc, 0, 0, 14 * sc);
        body.addColorStop(0, (0, ColorUtils_1.lighten)(base, 0.5));
        body.addColorStop(0.55, base);
        body.addColorStop(1, (0, ColorUtils_1.darken)(base, 0.5));
        c.globalAlpha = 0.95;
        c.fillStyle = body;
        c.beginPath();
        c.ellipse(0, 0, 12 * sc, 10 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Ground occlusion fade
        const ao = c.createLinearGradient(0, -1 * sc, 0, 10 * sc);
        ao.addColorStop(0, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.55), 0));
        ao.addColorStop(1, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.55), 0.5));
        c.globalAlpha = 1;
        c.fillStyle = ao;
        c.beginPath();
        c.ellipse(0, 0, 12 * sc, 10 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Warm rim light
        c.strokeStyle = (0, ColorUtils_1.lighten)(base, 0.7);
        c.lineWidth = 1.3 * sc;
        c.globalAlpha = 0.6;
        c.beginPath();
        c.ellipse(0, 0, 11.2 * sc, 9.2 * sc, 0, Math.PI * 1.03, Math.PI * 1.5);
        c.stroke();
        // Glossy highlight
        c.fillStyle = GameConstants_1.COLOR_SLIME_YELLOW_LIGHT;
        c.globalAlpha = 0.35;
        c.beginPath();
        c.ellipse(-2.5 * sc, -3.5 * sc, 5.5 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
        // Crisp specular
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.55;
        c.beginPath();
        c.ellipse(-4 * sc, -5.5 * sc, 2.5 * sc, 1.8 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
    }
    c.globalAlpha = 1.0;
    // Eyes — rimmed during flash so the sclera doesn't melt into the white body
    for (let e = 0; e < 2; e++) {
        const ex = (e === 0 ? -3 : 3) * sc;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(ex, -0.5 * sc, 2.8 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
            c.strokeStyle = '#92400e';
            c.lineWidth = 0.8 * sc;
            c.globalAlpha = 0.9;
            c.stroke();
            c.globalAlpha = 1.0;
        }
    }
    // Amber pupils — kept during the flash so the frame keeps a gaze
    c.fillStyle = '#92400e';
    c.beginPath();
    c.arc(-2.5 * sc, 0, 1.3 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(3.5 * sc, 0, 1.3 * sc, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        // Eye shine + cheek blush (washed out on the white flash body)
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(-3 * sc, -0.8 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(3 * sc, -0.8 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = '#f59e0b';
        c.globalAlpha = 0.3;
        c.beginPath();
        c.ellipse(-6 * sc, 2 * sc, 2 * sc, 1.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(6 * sc, 2 * sc, 2 * sc, 1.2 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
    }
    // Mouth — also kept so the flash frame keeps its expression
    c.strokeStyle = '#92400e';
    c.lineWidth = 1 * sc;
    c.beginPath();
    c.arc(0, 3 * sc, 3.5 * sc, 0.1, Math.PI - 0.1);
    c.stroke();
    c.restore();
}
function drawGhostSlime(c, bouncePhase, size, flash, frameCount) {
    const sc = size / 48;
    const float = Math.sin(bouncePhase * 0.5) * 4 * sc;
    const phase = Math.sin(frameCount * 0.05) * 0.15;
    c.save();
    c.translate(0, float);
    if (!flash) {
        c.globalAlpha = 0.06 + Math.sin(frameCount * 0.04) * 0.03;
        c.fillStyle = GameConstants_1.COLOR_SLIME_GHOST;
        c.beginPath();
        c.ellipse(0, 0, 22 * sc, 20 * sc, 0, 0, Math.PI * 2);
        c.fill();
        for (let w = 0; w < 5; w++) {
            const wAngle = (w / 5) * Math.PI * 2 + frameCount * 0.02;
            const wDist = (10 + Math.sin(frameCount * 0.03 + w * 2) * 5) * sc;
            const wx = Math.cos(wAngle) * wDist;
            const wy = Math.sin(wAngle) * wDist * 0.5 + 5 * sc;
            c.fillStyle = GameConstants_1.COLOR_SLIME_GHOST_LIGHT;
            c.globalAlpha = 0.15 + Math.sin(frameCount * 0.05 + w) * 0.1;
            c.beginPath();
            c.ellipse(wx, wy, 2.5 * sc, 1.5 * sc, wAngle, 0, Math.PI * 2);
            c.fill();
        }
        for (let trail = 0; trail < 3; trail++) {
            const ty = 8 * sc + trail * 4 * sc;
            const tx = Math.sin(frameCount * 0.04 + trail * 2) * 3 * sc;
            c.fillStyle = GameConstants_1.COLOR_SLIME_GHOST;
            c.globalAlpha = 0.1 * (1 - trail * 0.3);
            c.beginPath();
            c.ellipse(tx, ty, (4 - trail) * sc, (2 - trail * 0.5) * sc, 0, 0, Math.PI * 2);
            c.fill();
        }
    }
    const bodyAlpha = flash ? 0.9 : (0.45 + phase);
    const wv1 = Math.sin(frameCount * 0.06) * 1.5 * sc;
    const wv2 = Math.sin(frameCount * 0.06 + 1) * 1.5 * sc;
    const wv3 = Math.sin(frameCount * 0.06 + 2) * 1.5 * sc;
    c.globalAlpha = bodyAlpha;
    if (flash) {
        // White damage flash: keep the wavy ghost silhouette visible
        c.globalAlpha = 0.9;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.moveTo(-12 * sc, 4 * sc);
        c.quadraticCurveTo(-13 * sc, -10 * sc, 0, -12 * sc);
        c.quadraticCurveTo(13 * sc, -10 * sc, 12 * sc, 4 * sc);
        c.quadraticCurveTo(10 * sc, 10 * sc + wv1, 6 * sc, 8 * sc);
        c.quadraticCurveTo(3 * sc, 12 * sc + wv2, 0, 9 * sc);
        c.quadraticCurveTo(-3 * sc, 12 * sc + wv3, -6 * sc, 8 * sc);
        c.quadraticCurveTo(-10 * sc, 10 * sc + wv1, -12 * sc, 4 * sc);
        c.closePath();
        c.fill();
    }
    else {
        c.strokeStyle = '#334155';
        c.lineWidth = 1.5 * sc;
        c.globalAlpha = bodyAlpha * 0.6;
        c.beginPath();
        c.moveTo(-12 * sc, 4 * sc);
        c.quadraticCurveTo(-13 * sc, -10 * sc, 0, -12 * sc);
        c.quadraticCurveTo(13 * sc, -10 * sc, 12 * sc, 4 * sc);
        c.quadraticCurveTo(10 * sc, 10 * sc + wv1, 6 * sc, 8 * sc);
        c.quadraticCurveTo(3 * sc, 12 * sc + wv2, 0, 9 * sc);
        c.quadraticCurveTo(-3 * sc, 12 * sc + wv3, -6 * sc, 8 * sc);
        c.quadraticCurveTo(-10 * sc, 10 * sc + wv1, -12 * sc, 4 * sc);
        c.closePath();
        c.stroke();
        c.globalAlpha = bodyAlpha;
        const ghostGrad = c.createRadialGradient(-4 * sc, -5 * sc, 2 * sc, 0, 0, 15 * sc);
        ghostGrad.addColorStop(0, (0, ColorUtils_1.lighten)(GameConstants_1.COLOR_SLIME_GHOST, 0.5));
        ghostGrad.addColorStop(0.55, GameConstants_1.COLOR_SLIME_GHOST);
        ghostGrad.addColorStop(1, (0, ColorUtils_1.darken)(GameConstants_1.COLOR_SLIME_GHOST, 0.35));
        c.fillStyle = ghostGrad;
        c.beginPath();
        c.moveTo(-12 * sc, 4 * sc);
        c.quadraticCurveTo(-13 * sc, -10 * sc, 0, -12 * sc);
        c.quadraticCurveTo(13 * sc, -10 * sc, 12 * sc, 4 * sc);
        c.quadraticCurveTo(10 * sc, 10 * sc + wv1, 6 * sc, 8 * sc);
        c.quadraticCurveTo(3 * sc, 12 * sc + wv2, 0, 9 * sc);
        c.quadraticCurveTo(-3 * sc, 12 * sc + wv3, -6 * sc, 8 * sc);
        c.quadraticCurveTo(-10 * sc, 10 * sc + wv1, -12 * sc, 4 * sc);
        c.closePath();
        c.fill();
        // Silvery rim along the top edge
        c.strokeStyle = GameConstants_1.COLOR_SLIME_GHOST_LIGHT;
        c.lineWidth = 1.1 * sc;
        c.globalAlpha = bodyAlpha * 0.7;
        c.beginPath();
        c.ellipse(0, 0, 11.6 * sc, 11.4 * sc, 0, Math.PI * 1.05, Math.PI * 1.5);
        c.stroke();
        // Soft inner glow
        const glow = c.createRadialGradient(0, -2 * sc, 1 * sc, 0, -2 * sc, 8 * sc);
        glow.addColorStop(0, (0, ColorUtils_1.rgba)(GameConstants_1.COLOR_SLIME_GHOST_LIGHT, 0.45));
        glow.addColorStop(1, (0, ColorUtils_1.rgba)(GameConstants_1.COLOR_SLIME_GHOST_LIGHT, 0));
        c.globalAlpha = bodyAlpha;
        c.fillStyle = glow;
        c.beginPath();
        c.ellipse(0, -2 * sc, 8 * sc, 7 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.18;
        c.beginPath();
        c.ellipse(-3 * sc, -6 * sc, 4 * sc, 2.5 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
    }
    c.globalAlpha = flash ? 0.9 : 0.85;
    c.fillStyle = flash ? '#ffffff' : '#e2e8f0';
    for (let e = 0; e < 2; e++) {
        const ex = (e === 0 ? -4 : 4) * sc;
        c.beginPath();
        c.ellipse(ex, -3 * sc, 2.8 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
            // Rim the white eyes on the white flash body
            c.strokeStyle = '#1e293b';
            c.lineWidth = 0.8 * sc;
            c.stroke();
        }
    }
    c.globalAlpha = 1.0;
    // Dark hollow eyes + mouth — kept during the flash so it keeps a face
    c.fillStyle = '#1e293b';
    c.globalAlpha = 0.9;
    c.beginPath();
    c.ellipse(-4 * sc, -2.5 * sc, 1.5 * sc, 2 * sc, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(4 * sc, -2.5 * sc, 1.5 * sc, 2 * sc, 0, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        // Eye shine (white-on-white would be invisible in flash frames)
        c.fillStyle = '#94a3b8';
        c.globalAlpha = 0.6;
        c.beginPath();
        c.arc(-4.5 * sc, -3.5 * sc, 0.6 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(3.5 * sc, -3.5 * sc, 0.6 * sc, 0, Math.PI * 2);
        c.fill();
    }
    c.fillStyle = '#1e293b';
    c.globalAlpha = 0.6;
    c.beginPath();
    c.ellipse(0, 3 * sc, 3 * sc, (2.5 + Math.sin(frameCount * 0.04)) * sc, 0, 0, Math.PI * 2);
    c.fill();
    c.restore();
}
const ENEMY_CELL_W = 64;
const ENEMY_CELL_H = 64;
const ENEMY_CANONICAL_SIZE = 48; // sc = 1.0
const ENEMY_BOUNCE_FRAMES = 8;
const ENEMY_TOTAL_FRAMES = 16; // All types get 16 frames
function generateEnemyAtlas(type) {
    const cols = 4;
    const rows = 4;
    const atlas = new OffscreenCanvas(cols * ENEMY_CELL_W, rows * ENEMY_CELL_H);
    const actx = atlas.getContext('2d');
    for (let i = 0; i < ENEMY_BOUNCE_FRAMES; i++) {
        const bp = i * Math.PI / 4;
        const col = i % cols;
        const row = Math.floor(i / cols);
        const ox = col * ENEMY_CELL_W + ENEMY_CELL_W / 2;
        const oy = row * ENEMY_CELL_H + ENEMY_CELL_H / 2;
        // Frames 0-7: normal bounce cycle
        drawEnemyFrame(actx, type, ox, oy, bp, false, i, false, false);
        // Frames 8-15: variant bounce cycle (type-dependent)
        const vcol = (i + ENEMY_BOUNCE_FRAMES) % cols;
        const vrow = Math.floor((i + ENEMY_BOUNCE_FRAMES) / cols);
        const vox = vcol * ENEMY_CELL_W + ENEMY_CELL_W / 2;
        const voy = vrow * ENEMY_CELL_H + ENEMY_CELL_H / 2;
        if (type === GameConstants_1.EnemyType.PURPLE_SLIME) {
            drawEnemyFrame(actx, type, vox, voy, bp, false, i, false, true);
        }
        else if (type === GameConstants_1.EnemyType.RED_SLIME) {
            drawEnemyFrame(actx, type, vox, voy, bp, false, i, true, false);
        }
        else {
            drawEnemyFrame(actx, type, vox, voy, bp, true, i, false, false);
        }
    }
    return new SpriteAtlas_1.SpriteAtlas(atlas, ENEMY_CELL_W, ENEMY_CELL_H, ENEMY_TOTAL_FRAMES);
}
function drawEnemyFrame(c, type, cx, cy, bouncePhase, flash, animFrame, isCharging, isEngulfing) {
    c.save();
    c.translate(cx, cy);
    switch (type) {
        case GameConstants_1.EnemyType.GRAY_SLIME:
            drawGraySlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame);
            break;
        case GameConstants_1.EnemyType.PURPLE_SLIME:
            drawPurpleSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame, isEngulfing);
            break;
        case GameConstants_1.EnemyType.RED_SLIME:
            drawRedSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame, isCharging);
            break;
        case GameConstants_1.EnemyType.BLUE_SLIME:
            drawBlueSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame);
            break;
        case GameConstants_1.EnemyType.YELLOW_SLIME:
            drawYellowSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame);
            break;
        case GameConstants_1.EnemyType.GHOST_SLIME:
            drawGhostSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame);
            break;
        case GameConstants_1.EnemyType.HUMANOID_BEAST:
            // Bake the bounce as a translate so atlas frames match runtime motion
            c.translate(0, Math.sin(bouncePhase) * 2);
            (0, HumanoidBeastSprite_1.drawHumanoidBeast)(c, flash, animFrame, 1);
            break;
    }
    c.restore();
}
