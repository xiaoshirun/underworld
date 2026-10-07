"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.drawWeaponIcon = drawWeaponIcon;
const GameConstants_1 = require("../GameConstants");
const ColorUtils_1 = require("./ColorUtils");
/**
 * Polished static weapon icons for all 6 WeaponForm values, drawn centered at
 * (cx, cy) upright (blade/axe head pointing up). Baked by tools/spritegen into
 * rawfile/sprites/weapons.png (6 frames, 64px cells, 3x2 grid — row-major by
 * WeaponForm value), consumed through SpriteManager.getWeaponAtlas().
 */
function drawWeaponIcon(c, form, cx, cy, scale) {
    c.save();
    c.translate(cx, cy);
    c.scale(scale, scale);
    // Dark contour so icons read at small sizes
    c.strokeStyle = '#141428';
    c.lineWidth = 1.2;
    c.globalAlpha = 0.7;
    if (form === GameConstants_1.WeaponForm.BLADE) {
        drawBladeIcon(c, 1.0);
    }
    else if (form === GameConstants_1.WeaponForm.WHIP) {
        drawWhipIcon(c);
    }
    else if (form === GameConstants_1.WeaponForm.HAMMER) {
        drawHammerIcon(c);
    }
    else if (form === GameConstants_1.WeaponForm.STAFF) {
        drawStaffIcon(c);
    }
    else if (form === GameConstants_1.WeaponForm.DUAL_BLADES) {
        drawDagger(c, -0.5);
        drawDagger(c, 0.5);
    }
    else if (form === GameConstants_1.WeaponForm.GREAT_AXE) {
        drawGreatAxeIcon(c);
    }
    c.globalAlpha = 1.0;
    c.restore();
}
/** Single-edged blade, tip up. len scales blade length (dagger reuses it). */
function drawBladeIcon(c, lenScale) {
    const tipY = -16 * lenScale;
    const baseY = 0;
    // Blade body with left-lit gradient
    const blade = c.createLinearGradient(-2.6, 0, 2.6, 0);
    blade.addColorStop(0, '#dbeafe');
    blade.addColorStop(0.35, '#60a5fa');
    blade.addColorStop(1, '#1d4ed8');
    c.fillStyle = blade;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.moveTo(0, tipY);
    c.lineTo(2.6, tipY + 3.5 * lenScale);
    c.lineTo(2.2, baseY);
    c.lineTo(-2.2, baseY);
    c.lineTo(-2.6, tipY + 3.5 * lenScale);
    c.closePath();
    c.fill();
    c.globalAlpha = 0.7;
    c.stroke();
    // Fuller (center groove) + chrome edge
    c.strokeStyle = '#1e40af';
    c.lineWidth = 0.7;
    c.globalAlpha = 0.6;
    c.beginPath();
    c.moveTo(0, tipY + 2.5);
    c.lineTo(0, baseY - 1);
    c.stroke();
    c.strokeStyle = '#ffffff';
    c.lineWidth = 0.8;
    c.globalAlpha = 0.55;
    c.beginPath();
    c.moveTo(-1.7, tipY + 4 * lenScale);
    c.lineTo(-1.5, baseY - 1);
    c.stroke();
    // Crossguard
    const guard = c.createLinearGradient(0, -1, 0, 2.5);
    guard.addColorStop(0, '#fde68a');
    guard.addColorStop(1, '#b45309');
    c.fillStyle = guard;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.rect(-6.5, -0.5, 13, 3);
    c.fill();
    c.globalAlpha = 0.7;
    c.stroke();
    // Grip
    const grip = c.createLinearGradient(-1.6, 0, 1.6, 0);
    grip.addColorStop(0, '#8b5a2b');
    grip.addColorStop(1, '#4a2c14');
    c.fillStyle = grip;
    c.globalAlpha = 1.0;
    c.fillRect(-1.6, 2.5, 3.2, 6);
    c.strokeStyle = '#2a1a0a';
    c.lineWidth = 0.5;
    c.globalAlpha = 0.5;
    for (let i = 0; i < 3; i++) {
        c.beginPath();
        c.moveTo(-1.6, 3.6 + i * 1.8);
        c.lineTo(1.6, 4.4 + i * 1.8);
        c.stroke();
    }
    // Pommel
    c.fillStyle = '#fbbf24';
    c.globalAlpha = 1.0;
    c.beginPath();
    c.arc(0, 9.6, 1.8, 0, Math.PI * 2);
    c.fill();
    c.fillStyle = '#fffbeb';
    c.globalAlpha = 0.7;
    c.beginPath();
    c.arc(-0.6, 9, 0.7, 0, Math.PI * 2);
    c.fill();
}
/** Coiled whip with a gold-capped handle. */
function drawWhipIcon(c) {
    // Coil: two concentric spiral strokes
    const turns = 2.4;
    const steps = 40;
    for (let pass = 0; pass < 2; pass++) {
        c.beginPath();
        for (let i = 0; i <= steps; i++) {
            const t = i / steps;
            const ang = t * turns * Math.PI * 2 - Math.PI * 0.5;
            const rad = (11.5 - t * 5.5) + pass * 0.9;
            const px = Math.cos(ang) * rad;
            const py = Math.sin(ang) * rad * 0.92 + 1;
            if (i === 0)
                c.moveTo(px, py);
            else
                c.lineTo(px, py);
        }
        if (pass === 0) {
            c.strokeStyle = '#5b21b6';
            c.lineWidth = 3.4;
            c.globalAlpha = 0.95;
        }
        else {
            c.strokeStyle = '#a78bfa';
            c.lineWidth = 1.4;
            c.globalAlpha = 0.8;
        }
        c.stroke();
    }
    // Handle (bottom-right grip)
    c.save();
    c.translate(7.5, 9.5);
    c.rotate(0.7);
    const handle = c.createLinearGradient(0, -1.8, 0, 1.8);
    handle.addColorStop(0, '#d6b28c');
    handle.addColorStop(1, '#7c5433');
    c.fillStyle = handle;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.rect(-1.8, -6, 3.6, 8);
    c.fill();
    c.strokeStyle = '#141428';
    c.lineWidth = 1.2;
    c.globalAlpha = 0.7;
    c.stroke();
    // Gold cap
    c.fillStyle = '#fbbf24';
    c.globalAlpha = 1.0;
    c.beginPath();
    c.arc(0, -7, 1.6, 0, Math.PI * 2);
    c.fill();
    c.restore();
    // Flicking tip
    c.strokeStyle = '#c4b5fd';
    c.lineWidth = 1.4;
    c.globalAlpha = 0.9;
    c.beginPath();
    c.moveTo(0.5, -10.5);
    c.quadraticCurveTo(4, -15, 8, -13.5);
    c.stroke();
}
/** War hammer: heavy steel head on a wood haft. */
function drawHammerIcon(c) {
    // Haft (behind the head)
    const haft = c.createLinearGradient(-2, 0, 2, 0);
    haft.addColorStop(0, '#a1703f');
    haft.addColorStop(1, '#5b3a1e');
    c.fillStyle = haft;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.rect(-2, -8, 4, 25);
    c.fill();
    c.strokeStyle = '#141428';
    c.lineWidth = 1.2;
    c.globalAlpha = 0.7;
    c.stroke();
    // Head
    const head = c.createLinearGradient(0, -15, 0, -5);
    head.addColorStop(0, '#f3f4f6');
    head.addColorStop(0.45, '#c7cdd6');
    head.addColorStop(1, '#6b7280');
    c.fillStyle = head;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.rect(-10, -15, 20, 9.5);
    c.fill();
    c.stroke();
    // Bevel band + rivets
    c.fillStyle = '#9ca3af';
    c.globalAlpha = 0.8;
    c.fillRect(-10, -7.4, 20, 1.8);
    c.fillStyle = '#fde68a';
    c.globalAlpha = 1.0;
    c.beginPath();
    c.arc(-7, -10.5, 1.1, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(7, -10.5, 1.1, 0, Math.PI * 2);
    c.fill();
    // Top highlight
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.6;
    c.fillRect(-8.5, -14.2, 17, 1.4);
}
/** Channeling staff: wood shaft topped by a glowing orb. */
function drawStaffIcon(c) {
    // Shaft
    const shaft = c.createLinearGradient(-1.8, 0, 1.8, 0);
    shaft.addColorStop(0, '#9a6b42');
    shaft.addColorStop(1, '#4d3320');
    c.fillStyle = shaft;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.rect(-1.8, -8, 3.6, 25);
    c.fill();
    c.strokeStyle = '#141428';
    c.lineWidth = 1.2;
    c.globalAlpha = 0.7;
    c.stroke();
    // Prongs holding the orb
    c.strokeStyle = '#b45309';
    c.lineWidth = 1.6;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.moveTo(-3, -6);
    c.quadraticCurveTo(-5.5, -11, -2.5, -13.5);
    c.stroke();
    c.beginPath();
    c.moveTo(3, -6);
    c.quadraticCurveTo(5.5, -11, 2.5, -13.5);
    c.stroke();
    // Orb aura
    const aura = c.createRadialGradient(0, -14, 1, 0, -14, 8);
    aura.addColorStop(0, (0, ColorUtils_1.rgba)('#7dd3fc', 0.55));
    aura.addColorStop(1, (0, ColorUtils_1.rgba)('#7dd3fc', 0));
    c.fillStyle = aura;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.arc(0, -14, 8, 0, Math.PI * 2);
    c.fill();
    // Orb core
    const orb = c.createRadialGradient(-1.5, -15.5, 0.5, 0, -14, 4.5);
    orb.addColorStop(0, '#ffffff');
    orb.addColorStop(0.4, '#bae6fd');
    orb.addColorStop(1, '#0284c7');
    c.fillStyle = orb;
    c.beginPath();
    c.arc(0, -14, 4.2, 0, Math.PI * 2);
    c.fill();
    c.strokeStyle = '#141428';
    c.lineWidth = 1.2;
    c.globalAlpha = 0.7;
    c.stroke();
    // Glint
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.85;
    c.beginPath();
    c.arc(-1.4, -15.4, 1, 0, Math.PI * 2);
    c.fill();
}
/** One dagger of the dual-blades pair, rotated around center. */
function drawDagger(c, rot) {
    c.save();
    c.rotate(rot);
    c.translate(0, -1);
    drawBladeIcon(c, 0.72);
    c.restore();
}
/** Great axe: wide crescent bit on a long haft. */
function drawGreatAxeIcon(c) {
    // Haft
    const haft = c.createLinearGradient(-2, 0, 2, 0);
    haft.addColorStop(0, '#a1703f');
    haft.addColorStop(1, '#5b3a1e');
    c.fillStyle = haft;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.rect(-2, -13, 4, 30);
    c.fill();
    c.strokeStyle = '#141428';
    c.lineWidth = 1.2;
    c.globalAlpha = 0.7;
    c.stroke();
    // Bit (crescent blade on the right side)
    const bit = c.createLinearGradient(0, -16, 14, 0);
    bit.addColorStop(0, '#f3f4f6');
    bit.addColorStop(0.55, '#b0b7c3');
    bit.addColorStop(1, '#6b7280');
    c.fillStyle = bit;
    c.globalAlpha = 1.0;
    c.beginPath();
    c.moveTo(1, -15);
    c.quadraticCurveTo(13, -13, 13.5, -3.5);
    c.quadraticCurveTo(13, 6, 1, 7);
    c.lineTo(1, 3);
    c.quadraticCurveTo(8, 2, 8.5, -4);
    c.quadraticCurveTo(8, -10, 1, -11);
    c.closePath();
    c.fill();
    c.stroke();
    // Red inlay + edge highlight
    c.strokeStyle = '#ef4444';
    c.lineWidth = 1.4;
    c.globalAlpha = 0.9;
    c.beginPath();
    c.moveTo(2.5, -13);
    c.quadraticCurveTo(11, -11, 11.5, -4);
    c.quadraticCurveTo(11, 3.5, 2.5, 5.5);
    c.stroke();
    c.strokeStyle = '#ffffff';
    c.lineWidth = 0.9;
    c.globalAlpha = 0.6;
    c.beginPath();
    c.moveTo(12.6, -11.5);
    c.quadraticCurveTo(14.2, -3.5, 12.4, 5.5);
    c.stroke();
    // Poll (back counterweight) + gold band
    c.fillStyle = '#6b7280';
    c.globalAlpha = 1.0;
    c.beginPath();
    c.rect(-6.5, -11, 5, 8);
    c.fill();
    c.strokeStyle = '#141428';
    c.lineWidth = 1.2;
    c.globalAlpha = 0.7;
    c.stroke();
    c.fillStyle = '#fbbf24';
    c.globalAlpha = 1.0;
    c.fillRect(-2.6, -9, 5.2, 2.2);
}
