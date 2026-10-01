import { COLOR_SLIME_BLUE, COLOR_SLIME_BLUE_LIGHT, COLOR_SLIME_EYE, COLOR_SLIME_PUPIL } from '../GameConstants';
import { lighten, darken, rgba } from './ColorUtils';

/**
 * The player's default blue-slime body (shading + face), centered at (cx, cy).
 *
 * Shared by PlayerRenderer (drawn every frame) and tools/spritegen (PNG baking),
 * so the baked player_slime.png always matches the in-game look.
 * The ground shadow stays with the caller (it depends on jump state).
 */
export function drawPlayerSlimeBody(
  c: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  bodyW: number,
  bodyH: number,
  facingRight: boolean
): void {
  // Outline (drawn under the fill so a thin ring stays visible)
  c.strokeStyle = '#0c2d5e';
  c.lineWidth = 1.6;
  c.globalAlpha = 0.75;
  c.beginPath();
  c.ellipse(cx, cy, bodyW + 0.8, bodyH + 0.8, 0, 0, Math.PI * 2);
  c.stroke();

  // Main body: radial volume gradient, light from upper-left
  const bodyGrad: CanvasGradient = c.createRadialGradient(
    cx - bodyW * 0.35, cy - bodyH * 0.45, 1.5,
    cx, cy, bodyW * 1.15);
  bodyGrad.addColorStop(0, lighten(COLOR_SLIME_BLUE, 0.5));
  bodyGrad.addColorStop(0.55, COLOR_SLIME_BLUE);
  bodyGrad.addColorStop(1, darken(COLOR_SLIME_BLUE, 0.5));
  c.globalAlpha = 1.0;
  c.fillStyle = bodyGrad;
  c.beginPath();
  c.ellipse(cx, cy, bodyW, bodyH, 0, 0, Math.PI * 2);
  c.fill();

  // Ground occlusion: smooth dark fade toward the bottom
  const ao: CanvasGradient = c.createLinearGradient(0, cy - 1, 0, cy + bodyH);
  ao.addColorStop(0, rgba(darken(COLOR_SLIME_BLUE, 0.6), 0));
  ao.addColorStop(1, rgba(darken(COLOR_SLIME_BLUE, 0.6), 0.5));
  c.fillStyle = ao;
  c.beginPath();
  c.ellipse(cx, cy, bodyW, bodyH, 0, 0, Math.PI * 2);
  c.fill();

  // Rim light on the upper-left edge
  c.strokeStyle = COLOR_SLIME_BLUE_LIGHT;
  c.lineWidth = 1.2;
  c.globalAlpha = 0.6;
  c.beginPath();
  c.ellipse(cx, cy, bodyW - 0.8, bodyH - 0.8, 0, Math.PI * 1.03, Math.PI * 1.5);
  c.stroke();

  // Top sheen + crisp specular
  c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
  c.globalAlpha = 0.3;
  c.beginPath();
  c.ellipse(cx - 2, cy - 3, bodyW * 0.5, bodyH * 0.4, -0.3, 0, Math.PI * 2);
  c.fill();
  c.fillStyle = '#ffffff';
  c.globalAlpha = 0.55;
  c.beginPath();
  c.ellipse(cx - 3.5, cy - 4.5, 2.4, 1.7, -0.4, 0, Math.PI * 2);
  c.fill();
  c.globalAlpha = 1.0;

  // Eyes
  const eyeSpacing: number = 4;
  const eyeY: number = cy - 2;
  const eyeOffX: number = facingRight ? 1 : -1;

  // Eye whites
  c.fillStyle = COLOR_SLIME_EYE;
  c.beginPath();
  c.ellipse(cx - eyeSpacing + eyeOffX, eyeY, 2.5, 3, 0, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.ellipse(cx + eyeSpacing + eyeOffX, eyeY, 2.5, 3, 0, 0, Math.PI * 2);
  c.fill();

  // Pupils
  c.fillStyle = COLOR_SLIME_PUPIL;
  const pupilOff: number = facingRight ? 0.8 : -0.8;
  c.beginPath();
  c.arc(cx - eyeSpacing + eyeOffX + pupilOff, eyeY + 0.5, 1.2, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(cx + eyeSpacing + eyeOffX + pupilOff, eyeY + 0.5, 1.2, 0, Math.PI * 2);
  c.fill();

  // Eye shine
  c.fillStyle = '#ffffff';
  c.beginPath();
  c.arc(cx - eyeSpacing + eyeOffX + pupilOff - 0.5, eyeY - 0.8, 0.6, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(cx + eyeSpacing + eyeOffX + pupilOff - 0.5, eyeY - 0.8, 0.6, 0, Math.PI * 2);
  c.fill();

  // Mouth (small smile)
  c.strokeStyle = '#1e3a5f';
  c.lineWidth = 0.8;
  c.beginPath();
  c.arc(cx + eyeOffX, cy + 2, 2, 0.1, Math.PI - 0.1);
  c.stroke();
}
