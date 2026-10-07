"use strict";
/** Shared color shading helpers for volumetric slime rendering. */
Object.defineProperty(exports, "__esModule", { value: true });
exports.lighten = lighten;
exports.darken = darken;
exports.rgba = rgba;
function clamp01(v) {
    return v < 0 ? 0 : (v > 1 ? 1 : v);
}
function parseHex(hex) {
    return [
        parseInt(hex.substring(1, 3), 16),
        parseInt(hex.substring(3, 5), 16),
        parseInt(hex.substring(5, 7), 16)
    ];
}
function toHex2(v) {
    const s = Math.round(v).toString(16);
    return s.length < 2 ? '0' + s : s;
}
/** Mix hex color a toward hex color b by t (0..1). */
function mixHex(a, b, t) {
    const k = clamp01(t);
    const ca = parseHex(a);
    const cb = parseHex(b);
    return '#' + toHex2(ca[0] + (cb[0] - ca[0]) * k)
        + toHex2(ca[1] + (cb[1] - ca[1]) * k)
        + toHex2(ca[2] + (cb[2] - ca[2]) * k);
}
/** Lighten toward white. */
function lighten(hex, t) {
    return mixHex(hex, '#ffffff', t);
}
/** Darken toward black. */
function darken(hex, t) {
    return mixHex(hex, '#000000', t);
}
/** Hex color with alpha as an rgba() string (gradient stops need it). */
function rgba(hex, a) {
    const c = parseHex(hex);
    return 'rgba(' + c[0] + ',' + c[1] + ',' + c[2] + ',' + clamp01(a) + ')';
}
