import {
  BOSS_SIZE,
  COLOR_MUSHROOM_STEM,
  COLOR_WATER_LIGHT,
  BossType,
  getBossColor,
} from '../GameConstants';
import { BossAIComponent } from '../components/BossAIComponent';
import { SpriteAtlas } from './SpriteAtlas';

export function drawCrystalGuardian(
  c: OffscreenCanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Outer refraction glow
  c.globalAlpha = 0.12 + Math.sin(t * 0.04) * 0.05;
  c.fillStyle = '#67e8f9';
  c.beginPath();
  c.moveTo(0, -halfSize - pulse - 6);
  c.lineTo(halfSize + pulse + 6, 0);
  c.lineTo(0, halfSize + pulse + 6);
  c.lineTo(-halfSize - pulse - 6, 0);
  c.closePath();
  c.fill();

  // Main crystal body
  c.globalAlpha = 0.9;
  c.fillStyle = color;
  c.beginPath();
  c.moveTo(0, -halfSize - pulse);
  c.lineTo(halfSize + pulse, 0);
  c.lineTo(0, halfSize + pulse);
  c.lineTo(-halfSize - pulse, 0);
  c.closePath();
  c.fill();

  // Crystal facet lines
  c.strokeStyle = '#a5f3fc';
  c.lineWidth = 1;
  c.globalAlpha = 0.4;
  c.beginPath();
  c.moveTo(0, -halfSize - pulse);
  c.lineTo(4, 2);
  c.lineTo(0, halfSize + pulse);
  c.moveTo(0, -halfSize - pulse);
  c.lineTo(-4, 2);
  c.lineTo(0, halfSize + pulse);
  c.moveTo(-halfSize - pulse, 0);
  c.lineTo(0, 3);
  c.lineTo(halfSize + pulse, 0);
  c.stroke();

  // Left facet highlight
  c.fillStyle = '#67e8f9';
  c.globalAlpha = 0.25;
  c.beginPath();
  c.moveTo(-2, -halfSize * 0.6);
  c.lineTo(-halfSize * 0.7, 0);
  c.lineTo(-2, 2);
  c.closePath();
  c.fill();

  // Right facet shadow
  c.fillStyle = '#0e4a5c';
  c.globalAlpha = 0.2;
  c.beginPath();
  c.moveTo(2, -halfSize * 0.6);
  c.lineTo(halfSize * 0.7, 0);
  c.lineTo(2, 2);
  c.closePath();
  c.fill();

  // Top crystal spike crown
  c.globalAlpha = 0.7;
  c.fillStyle = '#22d3ee';
  c.beginPath();
  c.moveTo(-4, -halfSize * 0.5);
  c.lineTo(-2, -halfSize * 0.9 - pulse);
  c.lineTo(0, -halfSize * 0.5);
  c.closePath();
  c.fill();
  c.beginPath();
  c.moveTo(1, -halfSize * 0.5);
  c.lineTo(3, -halfSize * 0.85 - pulse);
  c.lineTo(5, -halfSize * 0.5);
  c.closePath();
  c.fill();

  // Inner core glow
  c.fillStyle = '#67e8f9';
  c.globalAlpha = 0.5 + 0.3 * Math.sin(t * 0.08);
  c.beginPath();
  c.arc(0, 0, halfSize * 0.35, 0, Math.PI * 2);
  c.fill();

  // Shimmer particles orbiting
  for (let p: number = 0; p < 5; p++) {
    const ang: number = (p / 5) * Math.PI * 2 + t * 0.03;
    const dist: number = halfSize * 0.7 + Math.sin(t * 0.06 + p * 2) * 3;
    const px: number = Math.cos(ang) * dist;
    const py: number = Math.sin(ang) * dist * 0.6;
    c.fillStyle = '#a5f3fc';
    c.globalAlpha = 0.4 + Math.sin(t * 0.1 + p) * 0.2;
    c.fillRect(px - 1, py - 1, 2, 2);
  }

  // Eyes - crystal blue with glow
  c.globalAlpha = 1.0;
  c.fillStyle = '#ffffff';
  c.fillRect(-7, -5, 5, 7);
  c.fillRect(3, -5, 5, 7);
  c.fillStyle = '#0891b2';
  c.fillRect(-6, -3, 3, 4);
  c.fillRect(4, -3, 3, 4);
  c.fillStyle = '#ffffff';
  c.fillRect(-6, -4, 1.5, 1.5);
  c.fillRect(4, -4, 1.5, 1.5);

  c.globalAlpha = 1.0;
}

export function drawMushroomKing(
  c: OffscreenCanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Spore particles floating upward
  for (let sp: number = 0; sp < 4; sp++) {
    const spY: number = -halfSize - 8 - ((t * 0.4 + sp * 12) % 30);
    const spX: number = Math.sin(t * 0.03 + sp * 3) * 10;
    const spAlpha: number = 0.3 * (1 - ((t * 0.4 + sp * 12) % 30) / 30);
    c.fillStyle = '#ff9ec4';
    c.globalAlpha = spAlpha;
    c.beginPath();
    c.arc(spX, spY, 1.5, 0, Math.PI * 2);
    c.fill();
  }

  // Stem body
  c.globalAlpha = 1.0;
  c.fillStyle = COLOR_MUSHROOM_STEM;
  c.fillRect(-9, -4, 18, halfSize + 4);
  // Stem shading
  c.fillStyle = '#d4a574';
  c.globalAlpha = 0.2;
  c.fillRect(-9, -4, 4, halfSize + 4);
  c.fillStyle = '#8b6040';
  c.globalAlpha = 0.15;
  c.fillRect(5, -4, 4, halfSize + 4);
  // Stem texture lines
  c.strokeStyle = '#a07850';
  c.lineWidth = 0.8;
  c.globalAlpha = 0.2;
  c.beginPath();
  c.moveTo(-4, 0);
  c.lineTo(-4, halfSize);
  c.moveTo(3, 2);
  c.lineTo(3, halfSize - 2);
  c.stroke();

  // Cap (dome)
  c.globalAlpha = 0.9;
  c.fillStyle = color;
  c.beginPath();
  c.arc(0, -4, halfSize + pulse, Math.PI, 0);
  c.closePath();
  c.fill();

  // Cap underside (gills)
  c.fillStyle = '#cc4488';
  c.globalAlpha = 0.3;
  c.fillRect(-halfSize + 2, -5, (halfSize - 2) * 2, 3);
  // Gill lines
  c.strokeStyle = '#aa3366';
  c.lineWidth = 0.6;
  c.globalAlpha = 0.25;
  for (let gl: number = 0; gl < 7; gl++) {
    const glX: number = -halfSize + 4 + gl * ((halfSize * 2 - 8) / 6);
    c.beginPath();
    c.moveTo(glX, -5);
    c.lineTo(glX, -2);
    c.stroke();
  }

  // Cap spots with depth
  c.globalAlpha = 0.9;
  c.fillStyle = '#ff9ec4';
  c.beginPath();
  c.arc(-10, -14, 5, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(7, -18, 3.5, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(-2, -20, 2.5, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(14, -10, 2, 0, Math.PI * 2);
  c.fill();
  // Spot highlights
  c.fillStyle = '#ffc0e0';
  c.globalAlpha = 0.5;
  c.beginPath();
  c.arc(-11, -15, 2, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(6, -19, 1.5, 0, Math.PI * 2);
  c.fill();

  // Cap highlight
  c.fillStyle = '#ffffff';
  c.globalAlpha = 0.15;
  c.beginPath();
  c.arc(-5, -halfSize * 0.6, halfSize * 0.35, 0, Math.PI * 2);
  c.fill();

  // Eyes
  c.globalAlpha = 1.0;
  c.fillStyle = '#ffffff';
  c.fillRect(-6, 2, 5, 6);
  c.fillRect(2, 2, 5, 6);
  c.fillStyle = '#4a2040';
  c.fillRect(-5, 3, 3, 4);
  c.fillRect(3, 3, 3, 4);
  c.fillStyle = '#ffffff';
  c.fillRect(-5, 2, 1.5, 1.5);
  c.fillRect(3, 2, 1.5, 1.5);

  // Mouth
  c.fillStyle = '#6b3050';
  c.beginPath();
  c.arc(0, 12, 3, 0, Math.PI);
  c.fill();

  c.globalAlpha = 1.0;
}

export function drawLavaBeast(
  c: OffscreenCanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  const bSize: number = BOSS_SIZE;
  // Heat distortion aura
  c.globalAlpha = 0.08 + Math.sin(t * 0.06) * 0.04;
  c.fillStyle = '#ff4400';
  c.beginPath();
  c.arc(0, 0, halfSize + 10 + pulse, 0, Math.PI * 2);
  c.fill();

  // Main body - dark rock
  c.globalAlpha = 1.0;
  c.fillStyle = '#3a1500';
  c.fillRect(-halfSize, -halfSize, bSize, bSize);

  // Rock texture overlay
  c.fillStyle = '#2a0e00';
  c.globalAlpha = 0.4;
  c.fillRect(-halfSize + 2, -halfSize + 2, halfSize, halfSize * 0.6);
  c.fillRect(2, 2, halfSize - 2, halfSize * 0.8);
  c.fillStyle = '#4a2010';
  c.globalAlpha = 0.3;
  c.fillRect(-halfSize + 4, -halfSize + 4, halfSize * 0.5, halfSize * 0.3);
  c.fillRect(4, -4, halfSize * 0.4, halfSize * 0.4);

  // Magma cracks - animated glow
  const crackGlow: number = 0.6 + 0.4 * Math.sin(t * 0.1);
  c.strokeStyle = '#ff6600';
  c.lineWidth = 2.5;
  c.globalAlpha = crackGlow * 0.4;
  c.beginPath();
  c.moveTo(-12, -14);
  c.lineTo(-4, -2);
  c.lineTo(6, -8);
  c.moveTo(4, 2);
  c.lineTo(-6, 14);
  c.moveTo(-10, 6);
  c.lineTo(-2, 10);
  c.lineTo(8, 6);
  c.stroke();

  // Inner magma glow lines
  c.strokeStyle = '#ffd700';
  c.lineWidth = 1.5;
  c.globalAlpha = crackGlow * 0.7;
  c.beginPath();
  c.moveTo(-11, -13);
  c.lineTo(-3, -1);
  c.lineTo(7, -7);
  c.moveTo(5, 3);
  c.lineTo(-5, 15);
  c.stroke();

  // Hot core spots
  c.fillStyle = '#ffaa00';
  c.globalAlpha = 0.3 + Math.sin(t * 0.08) * 0.15;
  c.beginPath();
  c.arc(-3, 0, 5, 0, Math.PI * 2);
  c.fill();
  c.fillStyle = '#ffd700';
  c.globalAlpha = 0.2;
  c.beginPath();
  c.arc(6, 8, 3, 0, Math.PI * 2);
  c.fill();

  // Ember particles rising
  for (let em: number = 0; em < 4; em++) {
    const emY: number = -halfSize - ((t * 0.6 + em * 10) % 20);
    const emX: number = -8 + em * 6 + Math.sin(t * 0.05 + em * 2) * 3;
    const emAlpha: number = 0.6 * (1 - ((t * 0.6 + em * 10) % 20) / 20);
    c.fillStyle = em % 2 === 0 ? '#ffaa00' : '#ff6600';
    c.globalAlpha = emAlpha;
    c.fillRect(emX, emY, 2, 2);
  }

  // Top edge glow
  c.fillStyle = '#ff4400';
  c.globalAlpha = 0.3 + Math.sin(t * 0.07) * 0.1;
  c.fillRect(-halfSize, -halfSize, bSize, 2);
  c.fillRect(-halfSize, -halfSize, 2, bSize);

  // Eyes - glowing yellow
  c.globalAlpha = 1.0;
  c.fillStyle = '#ffd700';
  c.fillRect(-8, -7, 6, 6);
  c.fillRect(3, -7, 6, 6);
  // Pupils
  c.fillStyle = '#ff4400';
  c.fillRect(-6, -5, 3, 3);
  c.fillRect(4, -5, 3, 3);
  // Eye glow
  c.fillStyle = '#ffffff';
  c.fillRect(-7, -6, 1.5, 1.5);
  c.fillRect(4, -6, 1.5, 1.5);

  // Mouth - jagged
  c.fillStyle = '#ff4400';
  c.globalAlpha = 0.7;
  c.beginPath();
  c.moveTo(-6, 6);
  c.lineTo(-3, 9);
  c.lineTo(0, 6);
  c.lineTo(3, 9);
  c.lineTo(6, 6);
  c.stroke();

  c.globalAlpha = 1.0;
  c.lineWidth = 1;
}

export function drawAbyssSiren(
  c: OffscreenCanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Deep water aura
  c.globalAlpha = 0.1;
  c.fillStyle = COLOR_WATER_LIGHT;
  c.beginPath();
  c.arc(0, 0, halfSize + 14 + pulse, 0, Math.PI * 2);
  c.fill();

  // Bubble particles
  for (let b: number = 0; b < 5; b++) {
    const bY: number = halfSize - ((t * 0.3 + b * 8) % (halfSize * 2 + 16));
    const bX: number = -10 + b * 5 + Math.sin(t * 0.04 + b * 1.5) * 4;
    const bSize: number = 1 + (b % 3) * 0.5;
    const bAlpha: number = 0.3 * (1 - ((t * 0.3 + b * 8) % (halfSize * 2 + 16)) / (halfSize * 2 + 16));
    c.strokeStyle = '#93c5fd';
    c.lineWidth = 0.8;
    c.globalAlpha = bAlpha;
    c.beginPath();
    c.arc(bX, bY, bSize, 0, Math.PI * 2);
    c.stroke();
  }

  // Main body
  c.globalAlpha = 0.9;
  c.fillStyle = color;
  c.beginPath();
  c.arc(0, 0, halfSize + pulse, 0, Math.PI * 2);
  c.fill();

  // Scale texture pattern
  c.fillStyle = '#1a5a8a';
  c.globalAlpha = 0.2;
  for (let row: number = 0; row < 4; row++) {
    for (let col: number = 0; col < 4; col++) {
      const scX: number = -halfSize + 6 + col * 7 + (row % 2) * 3;
      const scY: number = -halfSize + 6 + row * 6;
      const dist: number = Math.sqrt(scX * scX + scY * scY);
      if (dist < halfSize - 2) {
        c.beginPath();
        c.arc(scX, scY, 2.5, 0, Math.PI);
        c.fill();
      }
    }
  }

  // Bioluminescent spots
  c.fillStyle = '#67e8f9';
  for (let bl: number = 0; bl < 6; bl++) {
    const blAng: number = (bl / 6) * Math.PI * 2 + t * 0.01;
    const blDist: number = halfSize * 0.5 + Math.sin(t * 0.03 + bl) * 2;
    const blX: number = Math.cos(blAng) * blDist;
    const blY: number = Math.sin(blAng) * blDist;
    c.globalAlpha = 0.3 + Math.sin(t * 0.06 + bl * 2) * 0.2;
    c.beginPath();
    c.arc(blX, blY, 1.5, 0, Math.PI * 2);
    c.fill();
  }

  // Body highlight
  c.fillStyle = '#ffffff';
  c.globalAlpha = 0.1;
  c.beginPath();
  c.ellipse(-halfSize * 0.2, -halfSize * 0.3, halfSize * 0.4, halfSize * 0.3, -0.3, 0, Math.PI * 2);
  c.fill();

  // Flowing tentacles with taper
  c.strokeStyle = COLOR_WATER_LIGHT;
  c.lineWidth = 3;
  for (let tn: number = 0; tn < 6; tn++) {
    const baseAngle: number = (tn / 6) * Math.PI * 2 + t * 0.02;
    const wave1: number = Math.sin(t * 0.04 + tn * 1.5) * 6;
    const wave2: number = Math.sin(t * 0.06 + tn * 2) * 4;
    const startR: number = halfSize * 0.7;
    const endR: number = halfSize + 14;
    const startX: number = Math.cos(baseAngle) * startR;
    const startY: number = Math.sin(baseAngle) * startR;
    const midX: number = Math.cos(baseAngle + 0.3) * (startR + endR) * 0.5 + wave1;
    const midY: number = Math.sin(baseAngle + 0.3) * (startR + endR) * 0.5 + wave2;
    const endX: number = Math.cos(baseAngle + 0.5) * endR + wave1 * 0.5;
    const endY: number = Math.sin(baseAngle + 0.5) * endR + wave2 * 0.5;

    c.globalAlpha = 0.5;
    c.beginPath();
    c.moveTo(startX, startY);
    c.quadraticCurveTo(midX, midY, endX, endY);
    c.stroke();

    // Tentacle tip glow
    c.fillStyle = '#93c5fd';
    c.globalAlpha = 0.4;
    c.beginPath();
    c.arc(endX, endY, 1.5, 0, Math.PI * 2);
    c.fill();
  }

  // Inner ring
  c.strokeStyle = '#38bdf8';
  c.lineWidth = 1.5;
  c.globalAlpha = 0.3;
  c.beginPath();
  c.arc(0, 0, halfSize * 0.6, 0, Math.PI * 2);
  c.stroke();

  // Eyes - large, deep
  c.globalAlpha = 1.0;
  c.fillStyle = '#ffffff';
  c.beginPath();
  c.ellipse(-7, -4, 5, 5.5, 0, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.ellipse(7, -4, 5, 5.5, 0, 0, Math.PI * 2);
  c.fill();
  // Iris
  c.fillStyle = '#0369a1';
  c.beginPath();
  c.arc(-6, -3, 2.5, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(8, -3, 2.5, 0, Math.PI * 2);
  c.fill();
  // Pupil
  c.fillStyle = '#0c2d5e';
  c.beginPath();
  c.arc(-6, -3, 1.2, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(8, -3, 1.2, 0, Math.PI * 2);
  c.fill();
  // Eye highlight
  c.fillStyle = '#ffffff';
  c.beginPath();
  c.arc(-7, -4.5, 1, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.arc(7, -4.5, 1, 0, Math.PI * 2);
  c.fill();

  c.globalAlpha = 1.0;
  c.lineWidth = 1;
}

export function drawVoidRift(
  c: OffscreenCanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Outer distortion field
  c.globalAlpha = 0.06;
  c.fillStyle = '#7c3aed';
  c.beginPath();
  c.arc(0, 0, halfSize + 20 + pulse, 0, Math.PI * 2);
  c.fill();

  // Orbiting debris particles
  for (let d: number = 0; d < 8; d++) {
    const dAng: number = (d / 8) * Math.PI * 2 + t * 0.025;
    const dDist: number = halfSize + 6 + Math.sin(t * 0.04 + d * 1.7) * 5;
    const dx: number = Math.cos(dAng) * dDist;
    const dy: number = Math.sin(dAng) * dDist;
    const dSize: number = 1 + (d % 3);
    c.fillStyle = d % 2 === 0 ? '#a855f7' : '#6d28d9';
    c.globalAlpha = 0.5 + Math.sin(t * 0.08 + d) * 0.2;
    c.fillRect(dx - dSize / 2, dy - dSize / 2, dSize, dSize);
  }

  // Outer ring - dark energy
  c.fillStyle = color;
  c.globalAlpha = 0.7;
  c.beginPath();
  c.arc(0, 0, halfSize + pulse + 4, 0, Math.PI * 2);
  c.fill();

  // Mid ring gradient
  c.fillStyle = '#2d1060';
  c.globalAlpha = 0.8;
  c.beginPath();
  c.arc(0, 0, halfSize * 0.75, 0, Math.PI * 2);
  c.fill();

  // Event horizon (center void)
  c.fillStyle = '#0d0d1a';
  c.beginPath();
  c.arc(0, 0, halfSize * 0.45, 0, Math.PI * 2);
  c.fill();

  // Absolute black core
  c.fillStyle = '#000000';
  c.beginPath();
  c.arc(0, 0, halfSize * 0.25, 0, Math.PI * 2);
  c.fill();

  // Spinning energy arcs
  const spin: number = t * 0.04;
  c.strokeStyle = '#a855f7';
  c.lineWidth = 2;
  c.globalAlpha = 0.5;
  c.beginPath();
  c.arc(0, 0, halfSize * 0.65, spin, spin + Math.PI * 1.2);
  c.stroke();
  c.beginPath();
  c.arc(0, 0, halfSize * 0.85, spin + Math.PI, spin + Math.PI * 2.2);
  c.stroke();

  // Inner crackling
  c.strokeStyle = '#c084fc';
  c.lineWidth = 1;
  c.globalAlpha = 0.3;
  for (let cr: number = 0; cr < 3; cr++) {
    const crAng: number = (cr / 3) * Math.PI * 2 + t * 0.06;
    const crR: number = halfSize * 0.5;
    c.beginPath();
    c.moveTo(Math.cos(crAng) * halfSize * 0.25, Math.sin(crAng) * halfSize * 0.25);
    c.lineTo(Math.cos(crAng + 0.2) * crR * 0.6, Math.sin(crAng + 0.2) * crR * 0.6);
    c.lineTo(Math.cos(crAng + 0.1) * crR, Math.sin(crAng + 0.1) * crR);
    c.stroke();
  }

  // Void eye (center)
  c.fillStyle = '#7c3aed';
  c.globalAlpha = 0.4 + Math.sin(t * 0.05) * 0.2;
  c.beginPath();
  c.ellipse(0, 0, halfSize * 0.15, halfSize * 0.08, 0, 0, Math.PI * 2);
  c.fill();
  c.fillStyle = '#e9d5ff';
  c.globalAlpha = 0.6;
  c.beginPath();
  c.arc(0, 0, halfSize * 0.05, 0, Math.PI * 2);
  c.fill();

  c.globalAlpha = 1.0;
  c.lineWidth = 1;
}

const BOSS_CELL_W: number = 128;
const BOSS_CELL_H: number = 128;
const BOSS_FRAMES: number = 12;

export function generateBossAtlas(type: BossType): SpriteAtlas {
  const cols: number = Math.ceil(Math.sqrt(BOSS_FRAMES));
  const rows: number = Math.ceil(BOSS_FRAMES / cols);
  const atlas: OffscreenCanvas = new OffscreenCanvas(cols * BOSS_CELL_W, rows * BOSS_CELL_H);
  const actx: OffscreenCanvasRenderingContext2D = atlas.getContext('2d') as OffscreenCanvasRenderingContext2D;

  const halfSize: number = BOSS_SIZE / 2;
  const bossColor: string = getBossColor(type);

  // Create a minimal BossAIComponent for generation
  const genAI: BossAIComponent = new BossAIComponent();
  genAI.bossType = type;
  genAI.phase = 0; // PHASE_1

  for (let i: number = 0; i < BOSS_FRAMES; i++) {
    const t: number = i * 11;
    const pulse: number = Math.sin(t * 0.05) * 2;
    const col: number = i % cols;
    const row: number = Math.floor(i / cols);
    const cx: number = col * BOSS_CELL_W + BOSS_CELL_W / 2;
    const cy: number = row * BOSS_CELL_H + BOSS_CELL_H / 2;

    actx.save();
    actx.translate(cx, cy);

    switch (type) {
      case BossType.CRYSTAL_GUARDIAN:
        drawCrystalGuardian(actx, halfSize, pulse, bossColor, genAI, t);
        break;
      case BossType.MUSHROOM_KING:
        drawMushroomKing(actx, halfSize, pulse, bossColor, genAI, t);
        break;
      case BossType.LAVA_BEAST:
        drawLavaBeast(actx, halfSize, pulse, bossColor, genAI, t);
        break;
      case BossType.ABYSS_SIREN:
        drawAbyssSiren(actx, halfSize, pulse, bossColor, genAI, t);
        break;
      case BossType.VOID_RIFT:
        drawVoidRift(actx, halfSize, pulse, bossColor, genAI, t);
        break;
    }

    actx.restore();
  }

  return new SpriteAtlas(atlas, BOSS_CELL_W, BOSS_CELL_H, BOSS_FRAMES);
}
