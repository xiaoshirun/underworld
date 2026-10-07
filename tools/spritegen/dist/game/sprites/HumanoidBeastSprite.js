"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.drawHumanoidBeast = drawHumanoidBeast;
const GameConstants_1 = require("../GameConstants");
const ColorUtils_1 = require("./ColorUtils");
/**
 * HUMANOID_BEAST body drawn at the current origin (caller translates position
 * and bounce). Shared by EnemyRenderer's procedural fallback path and by
 * tools/spritegen, which bakes enemy_6_humanoid_beast.png (frames 0-7 bounce,
 * 8-15 damage flash) — the sprite path consumes that atlas directly.
 *
 * @param flash white damage-flash silhouette when true
 * @param frameCount drives the aura pulse
 * @param sc size scale (ai.size / 48), 1.0 at atlas bake time
 */
function drawHumanoidBeast(c, flash, frameCount, sc) {
    const base = GameConstants_1.COLOR_HUMANOID_BEAST;
    if (!flash) {
        // Golden aura pulse
        c.globalAlpha = 0.12 + Math.sin(frameCount * 0.04) * 0.05;
        c.fillStyle = GameConstants_1.COLOR_HUMANOID_BEAST_GLOW;
        c.beginPath();
        c.ellipse(0, 0, 20 * sc, 22 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    // Ground shadow
    c.globalAlpha = 0.2;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(0, 14 * sc, 10 * sc, 3 * sc, 0, 0, Math.PI * 2);
    c.fill();
    if (flash) {
        // White damage-flash silhouette with soft volume
        c.strokeStyle = '#8b6914';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(0, 0, 12 * sc, 18 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        const flashGrad = c.createRadialGradient(-3 * sc, -6 * sc, 2 * sc, 0, 0, 20 * sc);
        flashGrad.addColorStop(0, '#ffffff');
        flashGrad.addColorStop(0.6, '#fef9ec');
        flashGrad.addColorStop(1, '#fde68a');
        c.globalAlpha = 0.95;
        c.fillStyle = flashGrad;
        c.beginPath();
        c.ellipse(0, 0, 11 * sc, 17 * sc, 0, 0, Math.PI * 2);
        c.fill();
    }
    else {
        // Outline (under the fill so ~1px ring stays visible)
        c.strokeStyle = '#8b6914';
        c.lineWidth = 2 * sc;
        c.globalAlpha = 0.85;
        c.beginPath();
        c.ellipse(0, 0, 12 * sc, 18 * sc, 0, 0, Math.PI * 2);
        c.stroke();
        // Body: tall golden volume gradient, light from upper-left
        const body = c.createRadialGradient(-3.5 * sc, -7 * sc, 2 * sc, 0, 0, 20 * sc);
        body.addColorStop(0, (0, ColorUtils_1.lighten)(base, 0.5));
        body.addColorStop(0.55, base);
        body.addColorStop(1, (0, ColorUtils_1.darken)(base, 0.55));
        c.globalAlpha = 0.95;
        c.fillStyle = body;
        c.beginPath();
        c.ellipse(0, 0, 11 * sc, 17 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Ground occlusion: dark fade toward the bottom
        const ao = c.createLinearGradient(0, -2 * sc, 0, 17 * sc);
        ao.addColorStop(0, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.6), 0));
        ao.addColorStop(1, (0, ColorUtils_1.rgba)((0, ColorUtils_1.darken)(base, 0.6), 0.5));
        c.globalAlpha = 1;
        c.fillStyle = ao;
        c.beginPath();
        c.ellipse(0, 0, 11 * sc, 17 * sc, 0, 0, Math.PI * 2);
        c.fill();
        // Rim light along the upper-left edge
        c.strokeStyle = (0, ColorUtils_1.lighten)(base, 0.75);
        c.lineWidth = 1.3 * sc;
        c.globalAlpha = 0.6;
        c.beginPath();
        c.ellipse(0, 0, 10.3 * sc, 16.3 * sc, 0, Math.PI * 1.03, Math.PI * 1.5);
        c.stroke();
        // Inner glow core (soft radial, replaces the flat highlight ellipse)
        const glow = c.createRadialGradient(-2 * sc, -5 * sc, 1 * sc, -2 * sc, -5 * sc, 9 * sc);
        glow.addColorStop(0, (0, ColorUtils_1.rgba)(GameConstants_1.COLOR_HUMANOID_BEAST_GLOW, 0.55));
        glow.addColorStop(1, (0, ColorUtils_1.rgba)(GameConstants_1.COLOR_HUMANOID_BEAST_GLOW, 0));
        c.globalAlpha = 1;
        c.fillStyle = glow;
        c.beginPath();
        c.ellipse(-1.5 * sc, -4 * sc, 7 * sc, 9 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
        // Crisp specular near the top
        c.fillStyle = '#ffffff';
        c.globalAlpha = 0.5;
        c.beginPath();
        c.ellipse(-4 * sc, -11 * sc, 2.6 * sc, 3.4 * sc, -0.2, 0, Math.PI * 2);
        c.fill();
    }
    // Eyes — rimmed during flash so the sclera doesn't melt into the white body
    c.globalAlpha = 1.0;
    for (let e = 0; e < 2; e++) {
        const ex = (e === 0 ? -3 : 3) * sc;
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.ellipse(ex, -6 * sc, 2.5 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
            c.strokeStyle = '#1a1a2e';
            c.lineWidth = 0.8 * sc;
            c.globalAlpha = 0.9;
            c.stroke();
            c.globalAlpha = 1.0;
        }
    }
    // Pupils — kept during the flash so the frame keeps a gaze
    c.fillStyle = '#1a1a2e';
    c.beginPath();
    c.arc(-3 * sc, -5.5 * sc, 1.3 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(3 * sc, -5.5 * sc, 1.3 * sc, 0, Math.PI * 2);
    c.fill();
    if (!flash) {
        // Eye shine (white-on-white would be invisible in flash frames)
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(-3.5 * sc, -6.2 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(2.5 * sc, -6.2 * sc, 0.5 * sc, 0, Math.PI * 2);
        c.fill();
    }
    // Mouth — also kept so the flash frame keeps its expression
    c.strokeStyle = '#8b6914';
    c.lineWidth = 1 * sc;
    c.beginPath();
    c.arc(0, -1 * sc, 3 * sc, 0.2, Math.PI - 0.2);
    c.stroke();
    c.globalAlpha = 1.0;
}
