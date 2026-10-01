/** Shared color shading helpers for volumetric slime rendering. */

function clamp01(v: number): number {
  return v < 0 ? 0 : (v > 1 ? 1 : v);
}

function parseHex(hex: string): number[] {
  return [
    parseInt(hex.substring(1, 3), 16),
    parseInt(hex.substring(3, 5), 16),
    parseInt(hex.substring(5, 7), 16)
  ];
}

function toHex2(v: number): string {
  const s: string = Math.round(v).toString(16);
  return s.length < 2 ? '0' + s : s;
}

/** Mix hex color a toward hex color b by t (0..1). */
function mixHex(a: string, b: string, t: number): string {
  const k: number = clamp01(t);
  const ca: number[] = parseHex(a);
  const cb: number[] = parseHex(b);
  return '#' + toHex2(ca[0] + (cb[0] - ca[0]) * k)
    + toHex2(ca[1] + (cb[1] - ca[1]) * k)
    + toHex2(ca[2] + (cb[2] - ca[2]) * k);
}

/** Lighten toward white. */
export function lighten(hex: string, t: number): string {
  return mixHex(hex, '#ffffff', t);
}

/** Darken toward black. */
export function darken(hex: string, t: number): string {
  return mixHex(hex, '#000000', t);
}

/** Hex color with alpha as an rgba() string (gradient stops need it). */
export function rgba(hex: string, a: number): string {
  const c: number[] = parseHex(hex);
  return 'rgba(' + c[0] + ',' + c[1] + ',' + c[2] + ',' + clamp01(a) + ')';
}
