"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.drawAttackSlash = drawAttackSlash;
const ColorUtils_1 = require("./ColorUtils");
/**
 * Reusable weapon slash effect: a crescent arc band that sweeps from the left,
 * over the top, to the right while growing then fading — one continuous
 * animation parameterised by progress (0..1).
 *
 * Baked by tools/spritegen into rawfile/sprites/attack_fx.png:
 * 36 frames = 6 weapon forms x 6 progress steps, row-major
 * (frameIndex = form * 6 + step), 64px cells, 6x6 grid — matching the
 * SpriteAtlas grid formula, consumed through SpriteManager.getAttackFxAtlas().
 */
const SLASH_COLORS = ['#60a5fa', '#a78bfa', '#9ca3af', '#7dd3fc', '#fb923c', '#ef4444'];
function drawAttackSlash(c, form, progress, cx, cy, scale) {
    const p = progress < 0 ? 0 : (progress > 1 ? 1 : progress);
    const energy = Math.sin(p * Math.PI); // fade in → peak → fade out
    if (energy <= 0.05) {
        return;
    }
    const base = (form >= 0 && form < SLASH_COLORS.length) ? SLASH_COLORS[form] : '#ffffff';
    // Leading edge sweeps PI (left) → 1.5PI (top) → 2PI (right)
    const centerAngle = Math.PI + p * Math.PI;
    const trail = 0.25 + Math.PI * 0.5 * energy;
    const a0 = centerAngle - trail / 2;
    const a1 = centerAngle + trail / 2;
    const rOuter = 20;
    const w = 2 + 8 * energy;
    const rInner = rOuter - w;
    const rMid = (rInner + rOuter) / 2;
    c.save();
    c.translate(cx, cy);
    c.scale(scale, scale);
    // Soft outer glow band
    c.strokeStyle = (0, ColorUtils_1.rgba)(base, 0.4);
    c.lineWidth = w * 1.9;
    c.globalAlpha = energy * 0.35;
    c.beginPath();
    c.arc(0, 0, rMid, a0 + 0.04, a1);
    c.stroke();
    // Main band: bright at the inner edge, fading outward
    const gx = Math.cos(centerAngle);
    const gy = Math.sin(centerAngle);
    const band = c.createLinearGradient(gx * rInner, gy * rInner, gx * rOuter, gy * rOuter);
    band.addColorStop(0, (0, ColorUtils_1.rgba)((0, ColorUtils_1.lighten)(base, 0.55), 0.95));
    band.addColorStop(0.45, (0, ColorUtils_1.rgba)(base, 0.85));
    band.addColorStop(1, (0, ColorUtils_1.rgba)(base, 0.05));
    c.fillStyle = band;
    c.globalAlpha = energy;
    c.beginPath();
    c.arc(0, 0, rOuter, a0, a1);
    c.arc(0, 0, rInner, a1, a0, true);
    c.closePath();
    c.fill();
    // Bright inner edge line
    c.strokeStyle = (0, ColorUtils_1.rgba)((0, ColorUtils_1.lighten)(base, 0.75), 0.9);
    c.lineWidth = 1.4;
    c.globalAlpha = energy * 0.9;
    c.beginPath();
    c.arc(0, 0, rInner + 0.9, a0, a1);
    c.stroke();
    // Leading tip glow
    const tipX = Math.cos(a1) * rMid;
    const tipY = Math.sin(a1) * rMid;
    const tipGlow = c.createRadialGradient(tipX, tipY, 0.5, tipX, tipY, 4.5);
    tipGlow.addColorStop(0, (0, ColorUtils_1.rgba)('#ffffff', 0.95));
    tipGlow.addColorStop(0.4, (0, ColorUtils_1.rgba)((0, ColorUtils_1.lighten)(base, 0.6), 0.8));
    tipGlow.addColorStop(1, (0, ColorUtils_1.rgba)(base, 0));
    c.fillStyle = tipGlow;
    c.globalAlpha = energy;
    c.beginPath();
    c.arc(tipX, tipY, 4.5, 0, Math.PI * 2);
    c.fill();
    // Deterministic sparks trailing the tip
    for (let i = 0; i < 3; i++) {
        const sa = a1 - 0.12 * (i + 1) - p * 0.08;
        const sr = rOuter + 1.5 + i * 2.4;
        const sx = Math.cos(sa) * sr;
        const sy = Math.sin(sa) * sr;
        const size = 1.6 - i * 0.4;
        c.fillStyle = i === 0 ? '#ffffff' : (0, ColorUtils_1.lighten)(base, 0.5);
        c.globalAlpha = energy * (0.85 - i * 0.25);
        c.fillRect(sx - size / 2, sy - size / 2, size, size);
    }
    c.globalAlpha = 1.0;
    c.restore();
}
