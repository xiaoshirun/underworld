import {
  BossType,
  BOSS_SIZE,
  COLOR_MUSHROOM_STEM, COLOR_WATER_LIGHT,
} from '../GameConstants';
import { BossAIComponent } from '../components/BossAIComponent';
import { DrawCmdBuffer } from '../../native/DrawCmd';

function hexToRgb(hex: string): number[] {
  const r: number = parseInt(hex.slice(1, 3), 16) / 255;
  const g: number = parseInt(hex.slice(3, 5), 16) / 255;
  const b: number = parseInt(hex.slice(5, 7), 16) / 255;
  return [r, g, b];
}

export class BossFormsRenderer {

  renderCrystalGuardian(c: CanvasRenderingContext2D, sx: number, sy: number,
    hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    // Outer refraction glow
    c.globalAlpha = 0.12 + Math.sin(t * 0.04) * 0.05;
    c.fillStyle = '#67e8f9';
    c.beginPath();
    c.moveTo(sx, sy - hs - pulse - 6);
    c.lineTo(sx + hs + pulse + 6, sy);
    c.lineTo(sx, sy + hs + pulse + 6);
    c.lineTo(sx - hs - pulse - 6, sy);
    c.closePath();
    c.fill();

    // Main crystal body
    c.globalAlpha = 0.9;
    c.fillStyle = color;
    c.beginPath();
    c.moveTo(sx, sy - hs - pulse);
    c.lineTo(sx + hs + pulse, sy);
    c.lineTo(sx, sy + hs + pulse);
    c.lineTo(sx - hs - pulse, sy);
    c.closePath();
    c.fill();

    // Crystal facet lines
    c.strokeStyle = '#a5f3fc';
    c.lineWidth = 1;
    c.globalAlpha = 0.4;
    c.beginPath();
    c.moveTo(sx, sy - hs - pulse);
    c.lineTo(sx + 4, sy + 2);
    c.lineTo(sx, sy + hs + pulse);
    c.moveTo(sx, sy - hs - pulse);
    c.lineTo(sx - 4, sy + 2);
    c.lineTo(sx, sy + hs + pulse);
    c.moveTo(sx - hs - pulse, sy);
    c.lineTo(sx, sy + 3);
    c.lineTo(sx + hs + pulse, sy);
    c.stroke();

    // Left facet highlight
    c.fillStyle = '#67e8f9';
    c.globalAlpha = 0.25;
    c.beginPath();
    c.moveTo(sx - 2, sy - hs * 0.6);
    c.lineTo(sx - hs * 0.7, sy);
    c.lineTo(sx - 2, sy + 2);
    c.closePath();
    c.fill();

    // Right facet shadow
    c.fillStyle = '#0e4a5c';
    c.globalAlpha = 0.2;
    c.beginPath();
    c.moveTo(sx + 2, sy - hs * 0.6);
    c.lineTo(sx + hs * 0.7, sy);
    c.lineTo(sx + 2, sy + 2);
    c.closePath();
    c.fill();

    // Top crystal spike crown
    c.globalAlpha = 0.7;
    c.fillStyle = '#22d3ee';
    c.beginPath();
    c.moveTo(sx - 4, sy - hs * 0.5);
    c.lineTo(sx - 2, sy - hs * 0.9 - pulse);
    c.lineTo(sx, sy - hs * 0.5);
    c.closePath();
    c.fill();
    c.beginPath();
    c.moveTo(sx + 1, sy - hs * 0.5);
    c.lineTo(sx + 3, sy - hs * 0.85 - pulse);
    c.lineTo(sx + 5, sy - hs * 0.5);
    c.closePath();
    c.fill();

    // Inner core glow
    c.fillStyle = '#67e8f9';
    c.globalAlpha = 0.5 + 0.3 * Math.sin(t * 0.08);
    c.beginPath();
    c.arc(sx, sy, hs * 0.35, 0, Math.PI * 2);
    c.fill();

    // Shimmer particles orbiting
    for (let p: number = 0; p < 5; p++) {
      const ang: number = (p / 5) * Math.PI * 2 + t * 0.03;
      const dist: number = hs * 0.7 + Math.sin(t * 0.06 + p * 2) * 3;
      const px: number = sx + Math.cos(ang) * dist;
      const py: number = sy + Math.sin(ang) * dist * 0.6;
      c.fillStyle = '#a5f3fc';
      c.globalAlpha = 0.4 + Math.sin(t * 0.1 + p) * 0.2;
      c.fillRect(px - 1, py - 1, 2, 2);
    }

    // Eyes - crystal blue with glow
    c.globalAlpha = 1.0;
    c.fillStyle = '#ffffff';
    c.fillRect(sx - 7, sy - 5, 5, 7);
    c.fillRect(sx + 3, sy - 5, 5, 7);
    c.fillStyle = '#0891b2';
    c.fillRect(sx - 6, sy - 3, 3, 4);
    c.fillRect(sx + 4, sy - 3, 3, 4);
    c.fillStyle = '#ffffff';
    c.fillRect(sx - 6, sy - 4, 1.5, 1.5);
    c.fillRect(sx + 4, sy - 4, 1.5, 1.5);

    c.globalAlpha = 1.0;
  }

  renderMushroomKing(c: CanvasRenderingContext2D, sx: number, sy: number,
    hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    // Spore particles floating upward
    for (let sp: number = 0; sp < 4; sp++) {
      const spY: number = sy - hs - 8 - ((t * 0.4 + sp * 12) % 30);
      const spX: number = sx + Math.sin(t * 0.03 + sp * 3) * 10;
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
    c.fillRect(sx - 9, sy - 4, 18, hs + 4);
    // Stem shading
    c.fillStyle = '#d4a574';
    c.globalAlpha = 0.2;
    c.fillRect(sx - 9, sy - 4, 4, hs + 4);
    c.fillStyle = '#8b6040';
    c.globalAlpha = 0.15;
    c.fillRect(sx + 5, sy - 4, 4, hs + 4);
    // Stem texture lines
    c.strokeStyle = '#a07850';
    c.lineWidth = 0.8;
    c.globalAlpha = 0.2;
    c.beginPath();
    c.moveTo(sx - 4, sy);
    c.lineTo(sx - 4, sy + hs);
    c.moveTo(sx + 3, sy + 2);
    c.lineTo(sx + 3, sy + hs - 2);
    c.stroke();

    // Cap (dome)
    c.globalAlpha = 0.9;
    c.fillStyle = color;
    c.beginPath();
    c.arc(sx, sy - 4, hs + pulse, Math.PI, 0);
    c.closePath();
    c.fill();

    // Cap underside (gills)
    c.fillStyle = '#cc4488';
    c.globalAlpha = 0.3;
    c.fillRect(sx - hs + 2, sy - 5, (hs - 2) * 2, 3);
    // Gill lines
    c.strokeStyle = '#aa3366';
    c.lineWidth = 0.6;
    c.globalAlpha = 0.25;
    for (let gl: number = 0; gl < 7; gl++) {
      const glX: number = sx - hs + 4 + gl * ((hs * 2 - 8) / 6);
      c.beginPath();
      c.moveTo(glX, sy - 5);
      c.lineTo(glX, sy - 2);
      c.stroke();
    }

    // Cap spots with depth
    c.globalAlpha = 0.9;
    c.fillStyle = '#ff9ec4';
    c.beginPath();
    c.arc(sx - 10, sy - 14, 5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx + 7, sy - 18, 3.5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx - 2, sy - 20, 2.5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx + 14, sy - 10, 2, 0, Math.PI * 2);
    c.fill();
    // Spot highlights
    c.fillStyle = '#ffc0e0';
    c.globalAlpha = 0.5;
    c.beginPath();
    c.arc(sx - 11, sy - 15, 2, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx + 6, sy - 19, 1.5, 0, Math.PI * 2);
    c.fill();

    // Cap highlight
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.15;
    c.beginPath();
    c.arc(sx - 5, sy - hs * 0.6, hs * 0.35, 0, Math.PI * 2);
    c.fill();

    // Eyes
    c.globalAlpha = 1.0;
    c.fillStyle = '#ffffff';
    c.fillRect(sx - 6, sy + 2, 5, 6);
    c.fillRect(sx + 2, sy + 2, 5, 6);
    c.fillStyle = '#4a2040';
    c.fillRect(sx - 5, sy + 3, 3, 4);
    c.fillRect(sx + 3, sy + 3, 3, 4);
    c.fillStyle = '#ffffff';
    c.fillRect(sx - 5, sy + 2, 1.5, 1.5);
    c.fillRect(sx + 3, sy + 2, 1.5, 1.5);

    // Mouth
    c.fillStyle = '#6b3050';
    c.beginPath();
    c.arc(sx, sy + 12, 3, 0, Math.PI);
    c.fill();

    c.globalAlpha = 1.0;
  }

  renderLavaBeast(c: CanvasRenderingContext2D, sx: number, sy: number,
    hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    const bSize: number = BOSS_SIZE;
    // Heat distortion aura
    c.globalAlpha = 0.08 + Math.sin(t * 0.06) * 0.04;
    c.fillStyle = '#ff4400';
    c.beginPath();
    c.arc(sx, sy, hs + 10 + pulse, 0, Math.PI * 2);
    c.fill();

    // Main body - dark rock
    c.globalAlpha = 1.0;
    c.fillStyle = '#3a1500';
    c.fillRect(sx - hs, sy - hs, bSize, bSize);

    // Rock texture overlay
    c.fillStyle = '#2a0e00';
    c.globalAlpha = 0.4;
    c.fillRect(sx - hs + 2, sy - hs + 2, hs, hs * 0.6);
    c.fillRect(sx + 2, sy + 2, hs - 2, hs * 0.8);
    c.fillStyle = '#4a2010';
    c.globalAlpha = 0.3;
    c.fillRect(sx - hs + 4, sy - hs + 4, hs * 0.5, hs * 0.3);
    c.fillRect(sx + 4, sy - 4, hs * 0.4, hs * 0.4);

    // Magma cracks - animated glow
    const crackGlow: number = 0.6 + 0.4 * Math.sin(t * 0.1);
    c.strokeStyle = '#ff6600';
    c.lineWidth = 2.5;
    c.globalAlpha = crackGlow * 0.4;
    c.beginPath();
    c.moveTo(sx - 12, sy - 14);
    c.lineTo(sx - 4, sy - 2);
    c.lineTo(sx + 6, sy - 8);
    c.moveTo(sx + 4, sy + 2);
    c.lineTo(sx - 6, sy + 14);
    c.moveTo(sx - 10, sy + 6);
    c.lineTo(sx - 2, sy + 10);
    c.lineTo(sx + 8, sy + 6);
    c.stroke();

    // Inner magma glow lines
    c.strokeStyle = '#ffd700';
    c.lineWidth = 1.5;
    c.globalAlpha = crackGlow * 0.7;
    c.beginPath();
    c.moveTo(sx - 11, sy - 13);
    c.lineTo(sx - 3, sy - 1);
    c.lineTo(sx + 7, sy - 7);
    c.moveTo(sx + 5, sy + 3);
    c.lineTo(sx - 5, sy + 15);
    c.stroke();

    // Hot core spots
    c.fillStyle = '#ffaa00';
    c.globalAlpha = 0.3 + Math.sin(t * 0.08) * 0.15;
    c.beginPath();
    c.arc(sx - 3, sy, 5, 0, Math.PI * 2);
    c.fill();
    c.fillStyle = '#ffd700';
    c.globalAlpha = 0.2;
    c.beginPath();
    c.arc(sx + 6, sy + 8, 3, 0, Math.PI * 2);
    c.fill();

    // Ember particles rising
    for (let em: number = 0; em < 4; em++) {
      const emY: number = sy - hs - ((t * 0.6 + em * 10) % 20);
      const emX: number = sx - 8 + em * 6 + Math.sin(t * 0.05 + em * 2) * 3;
      const emAlpha: number = 0.6 * (1 - ((t * 0.6 + em * 10) % 20) / 20);
      c.fillStyle = em % 2 === 0 ? '#ffaa00' : '#ff6600';
      c.globalAlpha = emAlpha;
      c.fillRect(emX, emY, 2, 2);
    }

    // Top edge glow
    c.fillStyle = '#ff4400';
    c.globalAlpha = 0.3 + Math.sin(t * 0.07) * 0.1;
    c.fillRect(sx - hs, sy - hs, bSize, 2);
    c.fillRect(sx - hs, sy - hs, 2, bSize);

    // Eyes - glowing yellow
    c.globalAlpha = 1.0;
    c.fillStyle = '#ffd700';
    c.fillRect(sx - 8, sy - 7, 6, 6);
    c.fillRect(sx + 3, sy - 7, 6, 6);
    // Pupils
    c.fillStyle = '#ff4400';
    c.fillRect(sx - 6, sy - 5, 3, 3);
    c.fillRect(sx + 4, sy - 5, 3, 3);
    // Eye glow
    c.fillStyle = '#ffffff';
    c.fillRect(sx - 7, sy - 6, 1.5, 1.5);
    c.fillRect(sx + 4, sy - 6, 1.5, 1.5);

    // Mouth - jagged
    c.fillStyle = '#ff4400';
    c.globalAlpha = 0.7;
    c.beginPath();
    c.moveTo(sx - 6, sy + 6);
    c.lineTo(sx - 3, sy + 9);
    c.lineTo(sx, sy + 6);
    c.lineTo(sx + 3, sy + 9);
    c.lineTo(sx + 6, sy + 6);
    c.stroke();

    c.globalAlpha = 1.0;
    c.lineWidth = 1;
  }

  renderAbyssSiren(c: CanvasRenderingContext2D, sx: number, sy: number,
    hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    // Deep water aura
    c.globalAlpha = 0.1;
    c.fillStyle = COLOR_WATER_LIGHT;
    c.beginPath();
    c.arc(sx, sy, hs + 14 + pulse, 0, Math.PI * 2);
    c.fill();

    // Bubble particles
    for (let b: number = 0; b < 5; b++) {
      const bY: number = sy + hs - ((t * 0.3 + b * 8) % (hs * 2 + 16));
      const bX: number = sx - 10 + b * 5 + Math.sin(t * 0.04 + b * 1.5) * 4;
      const bSize: number = 1 + (b % 3) * 0.5;
      const bAlpha: number = 0.3 * (1 - ((t * 0.3 + b * 8) % (hs * 2 + 16)) / (hs * 2 + 16));
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
    c.arc(sx, sy, hs + pulse, 0, Math.PI * 2);
    c.fill();

    // Scale texture pattern
    c.fillStyle = '#1a5a8a';
    c.globalAlpha = 0.2;
    for (let row: number = 0; row < 4; row++) {
      for (let col: number = 0; col < 4; col++) {
        const scX: number = sx - hs + 6 + col * 7 + (row % 2) * 3;
        const scY: number = sy - hs + 6 + row * 6;
        const dist: number = Math.sqrt((scX - sx) * (scX - sx) + (scY - sy) * (scY - sy));
        if (dist < hs - 2) {
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
      const blDist: number = hs * 0.5 + Math.sin(t * 0.03 + bl) * 2;
      const blX: number = sx + Math.cos(blAng) * blDist;
      const blY: number = sy + Math.sin(blAng) * blDist;
      c.globalAlpha = 0.3 + Math.sin(t * 0.06 + bl * 2) * 0.2;
      c.beginPath();
      c.arc(blX, blY, 1.5, 0, Math.PI * 2);
      c.fill();
    }

    // Body highlight
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.1;
    c.beginPath();
    c.ellipse(sx - hs * 0.2, sy - hs * 0.3, hs * 0.4, hs * 0.3, -0.3, 0, Math.PI * 2);
    c.fill();

    // Flowing tentacles with taper
    c.strokeStyle = COLOR_WATER_LIGHT;
    c.lineWidth = 3;
    for (let tn: number = 0; tn < 6; tn++) {
      const baseAngle: number = (tn / 6) * Math.PI * 2 + t * 0.02;
      const wave1: number = Math.sin(t * 0.04 + tn * 1.5) * 6;
      const wave2: number = Math.sin(t * 0.06 + tn * 2) * 4;
      const startR: number = hs * 0.7;
      const endR: number = hs + 14;
      const startX: number = sx + Math.cos(baseAngle) * startR;
      const startY: number = sy + Math.sin(baseAngle) * startR;
      const midX: number = sx + Math.cos(baseAngle + 0.3) * (startR + endR) * 0.5 + wave1;
      const midY: number = sy + Math.sin(baseAngle + 0.3) * (startR + endR) * 0.5 + wave2;
      const endX: number = sx + Math.cos(baseAngle + 0.5) * endR + wave1 * 0.5;
      const endY: number = sy + Math.sin(baseAngle + 0.5) * endR + wave2 * 0.5;

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
    c.arc(sx, sy, hs * 0.6, 0, Math.PI * 2);
    c.stroke();

    // Eyes - large, deep
    c.globalAlpha = 1.0;
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(sx - 7, sy - 4, 5, 5.5, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(sx + 7, sy - 4, 5, 5.5, 0, 0, Math.PI * 2);
    c.fill();
    // Iris
    c.fillStyle = '#0369a1';
    c.beginPath();
    c.arc(sx - 6, sy - 3, 2.5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx + 8, sy - 3, 2.5, 0, Math.PI * 2);
    c.fill();
    // Pupil
    c.fillStyle = '#0c2d5e';
    c.beginPath();
    c.arc(sx - 6, sy - 3, 1.2, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx + 8, sy - 3, 1.2, 0, Math.PI * 2);
    c.fill();
    // Eye highlight
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.arc(sx - 7, sy - 4.5, 1, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(sx + 7, sy - 4.5, 1, 0, Math.PI * 2);
    c.fill();

    c.globalAlpha = 1.0;
    c.lineWidth = 1;
  }

  renderVoidRift(c: CanvasRenderingContext2D, sx: number, sy: number,
    hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    // Outer distortion field
    c.globalAlpha = 0.06;
    c.fillStyle = '#7c3aed';
    c.beginPath();
    c.arc(sx, sy, hs + 20 + pulse, 0, Math.PI * 2);
    c.fill();

    // Orbiting debris particles
    for (let d: number = 0; d < 8; d++) {
      const dAng: number = (d / 8) * Math.PI * 2 + t * 0.025;
      const dDist: number = hs + 6 + Math.sin(t * 0.04 + d * 1.7) * 5;
      const dx: number = sx + Math.cos(dAng) * dDist;
      const dy: number = sy + Math.sin(dAng) * dDist;
      const dSize: number = 1 + (d % 3);
      c.fillStyle = d % 2 === 0 ? '#a855f7' : '#6d28d9';
      c.globalAlpha = 0.5 + Math.sin(t * 0.08 + d) * 0.2;
      c.fillRect(dx - dSize / 2, dy - dSize / 2, dSize, dSize);
    }

    // Outer ring - dark energy
    c.fillStyle = color;
    c.globalAlpha = 0.7;
    c.beginPath();
    c.arc(sx, sy, hs + pulse + 4, 0, Math.PI * 2);
    c.fill();

    // Mid ring gradient
    c.fillStyle = '#2d1060';
    c.globalAlpha = 0.8;
    c.beginPath();
    c.arc(sx, sy, hs * 0.75, 0, Math.PI * 2);
    c.fill();

    // Event horizon (center void)
    c.fillStyle = '#0d0d1a';
    c.beginPath();
    c.arc(sx, sy, hs * 0.45, 0, Math.PI * 2);
    c.fill();

    // Absolute black core
    c.fillStyle = '#000000';
    c.beginPath();
    c.arc(sx, sy, hs * 0.25, 0, Math.PI * 2);
    c.fill();

    // Spinning energy arcs
    const spin: number = t * 0.04;
    c.strokeStyle = '#a855f7';
    c.lineWidth = 2;
    c.globalAlpha = 0.5;
    c.beginPath();
    c.arc(sx, sy, hs * 0.65, spin, spin + Math.PI * 1.2);
    c.stroke();
    c.beginPath();
    c.arc(sx, sy, hs * 0.85, spin + Math.PI, spin + Math.PI * 2.2);
    c.stroke();

    // Inner crackling
    c.strokeStyle = '#c084fc';
    c.lineWidth = 1;
    c.globalAlpha = 0.3;
    for (let cr: number = 0; cr < 3; cr++) {
      const crAng: number = (cr / 3) * Math.PI * 2 + t * 0.06;
      const crR: number = hs * 0.5;
      c.beginPath();
      c.moveTo(sx + Math.cos(crAng) * hs * 0.25, sy + Math.sin(crAng) * hs * 0.25);
      c.lineTo(sx + Math.cos(crAng + 0.2) * crR * 0.6, sy + Math.sin(crAng + 0.2) * crR * 0.6);
      c.lineTo(sx + Math.cos(crAng + 0.1) * crR, sy + Math.sin(crAng + 0.1) * crR);
      c.stroke();
    }

    // Void eye (center)
    c.fillStyle = '#7c3aed';
    c.globalAlpha = 0.4 + Math.sin(t * 0.05) * 0.2;
    c.beginPath();
    c.ellipse(sx, sy, hs * 0.15, hs * 0.08, 0, 0, Math.PI * 2);
    c.fill();
    c.fillStyle = '#e9d5ff';
    c.globalAlpha = 0.6;
    c.beginPath();
    c.arc(sx, sy, hs * 0.05, 0, Math.PI * 2);
    c.fill();

    c.globalAlpha = 1.0;
    c.lineWidth = 1;
  }

  collectCrystalGuardianCommands(buf: DrawCmdBuffer, sx: number, sy: number,
      hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    const cRgb: number[] = hexToRgb(color);
    const s6: number[] = hexToRgb('#67e8f9');
    const af: number[] = hexToRgb('#a5f3fc');
    const oe: number[] = hexToRgb('#0e4a5c');
    const td: number[] = hexToRgb('#22d3ee');
    const ob: number[] = hexToRgb('#0891b2');

    const ohs: number = hs + pulse + 6;
    const oAlpha: number = 0.12 + Math.sin(t * 0.04) * 0.05;
    buf.pushTriangle(sx, sy - ohs, sx + ohs, sy, sx, sy + ohs, s6[0], s6[1], s6[2], oAlpha, 0);
    buf.pushTriangle(sx, sy - ohs, sx, sy + ohs, sx - ohs, sy, s6[0], s6[1], s6[2], oAlpha, 0);

    const mhs: number = hs + pulse;
    buf.pushTriangle(sx, sy - mhs, sx + mhs, sy, sx, sy + mhs, cRgb[0], cRgb[1], cRgb[2], 0.9, 0);
    buf.pushTriangle(sx, sy - mhs, sx, sy + mhs, sx - mhs, sy, cRgb[0], cRgb[1], cRgb[2], 0.9, 0);

    buf.pushLine(sx, sy - mhs, sx + 4, sy + 2, 1, af[0], af[1], af[2], 0.4, 0);
    buf.pushLine(sx + 4, sy + 2, sx, sy + mhs, 1, af[0], af[1], af[2], 0.4, 0);
    buf.pushLine(sx, sy - mhs, sx - 4, sy + 2, 1, af[0], af[1], af[2], 0.4, 0);
    buf.pushLine(sx - 4, sy + 2, sx, sy + mhs, 1, af[0], af[1], af[2], 0.4, 0);
    buf.pushLine(sx - mhs, sy, sx, sy + 3, 1, af[0], af[1], af[2], 0.4, 0);
    buf.pushLine(sx, sy + 3, sx + mhs, sy, 1, af[0], af[1], af[2], 0.4, 0);

    buf.pushTriangle(sx - 2, sy - hs * 0.6, sx - hs * 0.7, sy, sx - 2, sy + 2, s6[0], s6[1], s6[2], 0.25, 0);
    buf.pushTriangle(sx + 2, sy - hs * 0.6, sx + hs * 0.7, sy, sx + 2, sy + 2, oe[0], oe[1], oe[2], 0.2, 0);

    buf.pushTriangle(sx - 4, sy - hs * 0.5, sx - 2, sy - hs * 0.9 - pulse, sx, sy - hs * 0.5, td[0], td[1], td[2], 0.7, 0);
    buf.pushTriangle(sx + 1, sy - hs * 0.5, sx + 3, sy - hs * 0.85 - pulse, sx + 5, sy - hs * 0.5, td[0], td[1], td[2], 0.7, 0);

    const coreA: number = 0.5 + 0.3 * Math.sin(t * 0.08);
    buf.pushCircle(sx, sy, hs * 0.35, s6[0], s6[1], s6[2], coreA, 0, 0);

    for (let p: number = 0; p < 5; p++) {
      const ang: number = (p / 5) * Math.PI * 2 + t * 0.03;
      const dist: number = hs * 0.7 + Math.sin(t * 0.06 + p * 2) * 3;
      const px: number = sx + Math.cos(ang) * dist;
      const py: number = sy + Math.sin(ang) * dist * 0.6;
      const pA: number = 0.4 + Math.sin(t * 0.1 + p) * 0.2;
      buf.pushRect(px - 1, py - 1, 2, 2, af[0], af[1], af[2], pA, 0, 0);
    }

    buf.pushRect(sx - 7, sy - 5, 5, 7, 1, 1, 1, 1, 0, 0);
    buf.pushRect(sx + 3, sy - 5, 5, 7, 1, 1, 1, 1, 0, 0);
    buf.pushRect(sx - 6, sy - 3, 3, 4, ob[0], ob[1], ob[2], 1, 0, 0);
    buf.pushRect(sx + 4, sy - 3, 3, 4, ob[0], ob[1], ob[2], 1, 0, 0);
    buf.pushRect(sx - 6, sy - 4, 1.5, 1.5, 1, 1, 1, 1, 0, 0);
    buf.pushRect(sx + 4, sy - 4, 1.5, 1.5, 1, 1, 1, 1, 0, 0);
  }

  collectMushroomKingCommands(buf: DrawCmdBuffer, sx: number, sy: number,
      hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    const cRgb: number[] = hexToRgb(color);
    const stemRgb: number[] = hexToRgb(COLOR_MUSHROOM_STEM);
    const spRgb: number[] = hexToRgb('#ff9ec4');
    const sdRgb: number[] = hexToRgb('#d4a574');
    const ssRgb: number[] = hexToRgb('#8b6040');
    const tlRgb: number[] = hexToRgb('#a07850');
    const giRgb: number[] = hexToRgb('#cc4488');
    const glRgb: number[] = hexToRgb('#aa3366');
    const hlRgb: number[] = hexToRgb('#ffc0e0');
    const eyRgb: number[] = hexToRgb('#4a2040');
    const mtRgb: number[] = hexToRgb('#6b3050');

    for (let sp: number = 0; sp < 4; sp++) {
      const spY: number = sy - hs - 8 - ((t * 0.4 + sp * 12) % 30);
      const spX: number = sx + Math.sin(t * 0.03 + sp * 3) * 10;
      const spAlpha: number = 0.3 * (1 - ((t * 0.4 + sp * 12) % 30) / 30);
      buf.pushCircle(spX, spY, 1.5, spRgb[0], spRgb[1], spRgb[2], spAlpha, 0, 0);
    }

    buf.pushRect(sx - 9, sy - 4, 18, hs + 4, stemRgb[0], stemRgb[1], stemRgb[2], 1, 0, 0);
    buf.pushRect(sx - 9, sy - 4, 4, hs + 4, sdRgb[0], sdRgb[1], sdRgb[2], 0.2, 0, 0);
    buf.pushRect(sx + 5, sy - 4, 4, hs + 4, ssRgb[0], ssRgb[1], ssRgb[2], 0.15, 0, 0);
    buf.pushLine(sx - 4, sy, sx - 4, sy + hs, 0.8, tlRgb[0], tlRgb[1], tlRgb[2], 0.2, 0);
    buf.pushLine(sx + 3, sy + 2, sx + 3, sy + hs - 2, 0.8, tlRgb[0], tlRgb[1], tlRgb[2], 0.2, 0);

    buf.pushCircle(sx, sy - 4, hs + pulse, cRgb[0], cRgb[1], cRgb[2], 0.9, 0, 0);

    buf.pushRect(sx - hs + 2, sy - 5, (hs - 2) * 2, 3, giRgb[0], giRgb[1], giRgb[2], 0.3, 0, 0);
    for (let gl: number = 0; gl < 7; gl++) {
      const glX: number = sx - hs + 4 + gl * ((hs * 2 - 8) / 6);
      buf.pushLine(glX, sy - 5, glX, sy - 2, 0.6, glRgb[0], glRgb[1], glRgb[2], 0.25, 0);
    }

    buf.pushCircle(sx - 10, sy - 14, 5, spRgb[0], spRgb[1], spRgb[2], 0.9, 0, 0);
    buf.pushCircle(sx + 7, sy - 18, 3.5, spRgb[0], spRgb[1], spRgb[2], 0.9, 0, 0);
    buf.pushCircle(sx - 2, sy - 20, 2.5, spRgb[0], spRgb[1], spRgb[2], 0.9, 0, 0);
    buf.pushCircle(sx + 14, sy - 10, 2, spRgb[0], spRgb[1], spRgb[2], 0.9, 0, 0);
    buf.pushCircle(sx - 11, sy - 15, 2, hlRgb[0], hlRgb[1], hlRgb[2], 0.5, 0, 0);
    buf.pushCircle(sx + 6, sy - 19, 1.5, hlRgb[0], hlRgb[1], hlRgb[2], 0.5, 0, 0);

    buf.pushCircle(sx - 5, sy - hs * 0.6, hs * 0.35, 1, 1, 1, 0.15, 0, 0);

    buf.pushRect(sx - 6, sy + 2, 5, 6, 1, 1, 1, 1, 0, 0);
    buf.pushRect(sx + 2, sy + 2, 5, 6, 1, 1, 1, 1, 0, 0);
    buf.pushRect(sx - 5, sy + 3, 3, 4, eyRgb[0], eyRgb[1], eyRgb[2], 1, 0, 0);
    buf.pushRect(sx + 3, sy + 3, 3, 4, eyRgb[0], eyRgb[1], eyRgb[2], 1, 0, 0);
    buf.pushRect(sx - 5, sy + 2, 1.5, 1.5, 1, 1, 1, 1, 0, 0);
    buf.pushRect(sx + 3, sy + 2, 1.5, 1.5, 1, 1, 1, 1, 0, 0);

    buf.pushRect(sx - 3, sy + 12, 6, 3, mtRgb[0], mtRgb[1], mtRgb[2], 1, 0, 0);
  }

  collectLavaBeastCommands(buf: DrawCmdBuffer, sx: number, sy: number,
      hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    const bSize: number = BOSS_SIZE;
    const hRgb: number[] = hexToRgb('#ff4400');
    const dkRgb: number[] = hexToRgb('#3a1500');
    const r1Rgb: number[] = hexToRgb('#2a0e00');
    const r2Rgb: number[] = hexToRgb('#4a2010');
    const mcRgb: number[] = hexToRgb('#ff6600');
    const mgRgb: number[] = hexToRgb('#ffd700');
    const coRgb: number[] = hexToRgb('#ffaa00');
    const gdRgb: number[] = hexToRgb('#ffd700');
    const fpRgb: number[] = hexToRgb('#ff4400');

    const hA: number = 0.08 + Math.sin(t * 0.06) * 0.04;
    buf.pushCircle(sx, sy, hs + 10 + pulse, hRgb[0], hRgb[1], hRgb[2], hA, 0, 0);

    buf.pushRect(sx - hs, sy - hs, bSize, bSize, dkRgb[0], dkRgb[1], dkRgb[2], 1, 0, 0);
    buf.pushRect(sx - hs + 2, sy - hs + 2, hs, hs * 0.6, r1Rgb[0], r1Rgb[1], r1Rgb[2], 0.4, 0, 0);
    buf.pushRect(sx + 2, sy + 2, hs - 2, hs * 0.8, r1Rgb[0], r1Rgb[1], r1Rgb[2], 0.4, 0, 0);
    buf.pushRect(sx - hs + 4, sy - hs + 4, hs * 0.5, hs * 0.3, r2Rgb[0], r2Rgb[1], r2Rgb[2], 0.3, 0, 0);
    buf.pushRect(sx + 4, sy - 4, hs * 0.4, hs * 0.4, r2Rgb[0], r2Rgb[1], r2Rgb[2], 0.3, 0, 0);

    const crackGlow: number = 0.6 + 0.4 * Math.sin(t * 0.1);
    buf.pushLine(sx - 12, sy - 14, sx - 4, sy - 2, 2.5, mcRgb[0], mcRgb[1], mcRgb[2], crackGlow * 0.4, 0);
    buf.pushLine(sx - 4, sy - 2, sx + 6, sy - 8, 2.5, mcRgb[0], mcRgb[1], mcRgb[2], crackGlow * 0.4, 0);
    buf.pushLine(sx + 4, sy + 2, sx - 6, sy + 14, 2.5, mcRgb[0], mcRgb[1], mcRgb[2], crackGlow * 0.4, 0);
    buf.pushLine(sx - 10, sy + 6, sx - 2, sy + 10, 2.5, mcRgb[0], mcRgb[1], mcRgb[2], crackGlow * 0.4, 0);
    buf.pushLine(sx - 2, sy + 10, sx + 8, sy + 6, 2.5, mcRgb[0], mcRgb[1], mcRgb[2], crackGlow * 0.4, 0);

    buf.pushLine(sx - 11, sy - 13, sx - 3, sy - 1, 1.5, mgRgb[0], mgRgb[1], mgRgb[2], crackGlow * 0.7, 0);
    buf.pushLine(sx - 3, sy - 1, sx + 7, sy - 7, 1.5, mgRgb[0], mgRgb[1], mgRgb[2], crackGlow * 0.7, 0);
    buf.pushLine(sx + 5, sy + 3, sx - 5, sy + 15, 1.5, mgRgb[0], mgRgb[1], mgRgb[2], crackGlow * 0.7, 0);

    const coreA: number = 0.3 + Math.sin(t * 0.08) * 0.15;
    buf.pushCircle(sx - 3, sy, 5, coRgb[0], coRgb[1], coRgb[2], coreA, 0, 0);
    buf.pushCircle(sx + 6, sy + 8, 3, gdRgb[0], gdRgb[1], gdRgb[2], 0.2, 0, 0);

    for (let em: number = 0; em < 4; em++) {
      const emY: number = sy - hs - ((t * 0.6 + em * 10) % 20);
      const emX: number = sx - 8 + em * 6 + Math.sin(t * 0.05 + em * 2) * 3;
      const emAlpha: number = 0.6 * (1 - ((t * 0.6 + em * 10) % 20) / 20);
      const eRgb: number[] = em % 2 === 0 ? coRgb : hRgb;
      buf.pushRect(emX, emY, 2, 2, eRgb[0], eRgb[1], eRgb[2], emAlpha, 0, 0);
    }

    const edgeA: number = 0.3 + Math.sin(t * 0.07) * 0.1;
    buf.pushRect(sx - hs, sy - hs, bSize, 2, hRgb[0], hRgb[1], hRgb[2], edgeA, 0, 0);
    buf.pushRect(sx - hs, sy - hs, 2, bSize, hRgb[0], hRgb[1], hRgb[2], edgeA, 0, 0);

    buf.pushRect(sx - 8, sy - 7, 6, 6, gdRgb[0], gdRgb[1], gdRgb[2], 1, 0, 0);
    buf.pushRect(sx + 3, sy - 7, 6, 6, gdRgb[0], gdRgb[1], gdRgb[2], 1, 0, 0);
    buf.pushRect(sx - 6, sy - 5, 3, 3, fpRgb[0], fpRgb[1], fpRgb[2], 1, 0, 0);
    buf.pushRect(sx + 4, sy - 5, 3, 3, fpRgb[0], fpRgb[1], fpRgb[2], 1, 0, 0);
    buf.pushRect(sx - 7, sy - 6, 1.5, 1.5, 1, 1, 1, 1, 0, 0);
    buf.pushRect(sx + 4, sy - 6, 1.5, 1.5, 1, 1, 1, 1, 0, 0);

    buf.pushLine(sx - 6, sy + 6, sx - 3, sy + 9, 1, fpRgb[0], fpRgb[1], fpRgb[2], 0.7, 0);
    buf.pushLine(sx - 3, sy + 9, sx, sy + 6, 1, fpRgb[0], fpRgb[1], fpRgb[2], 0.7, 0);
    buf.pushLine(sx, sy + 6, sx + 3, sy + 9, 1, fpRgb[0], fpRgb[1], fpRgb[2], 0.7, 0);
    buf.pushLine(sx + 3, sy + 9, sx + 6, sy + 6, 1, fpRgb[0], fpRgb[1], fpRgb[2], 0.7, 0);
  }

  collectAbyssSirenCommands(buf: DrawCmdBuffer, sx: number, sy: number,
      hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    const cRgb: number[] = hexToRgb(color);
    const wlRgb: number[] = hexToRgb(COLOR_WATER_LIGHT);
    const bbRgb: number[] = hexToRgb('#93c5fd');
    const scRgb: number[] = hexToRgb('#1a5a8a');
    const blRgb: number[] = hexToRgb('#67e8f9');
    const irRgb: number[] = hexToRgb('#0369a1');
    const ppRgb: number[] = hexToRgb('#0c2d5e');
    const rnRgb: number[] = hexToRgb('#38bdf8');

    buf.pushCircle(sx, sy, hs + 14 + pulse, wlRgb[0], wlRgb[1], wlRgb[2], 0.1, 0, 0);

    for (let b: number = 0; b < 5; b++) {
      const bY: number = sy + hs - ((t * 0.3 + b * 8) % (hs * 2 + 16));
      const bX: number = sx - 10 + b * 5 + Math.sin(t * 0.04 + b * 1.5) * 4;
      const bSz: number = 1 + (b % 3) * 0.5;
      const bAlpha: number = 0.3 * (1 - ((t * 0.3 + b * 8) % (hs * 2 + 16)) / (hs * 2 + 16));
      buf.pushCircle(bX, bY, bSz, bbRgb[0], bbRgb[1], bbRgb[2], bAlpha, 0, 0);
    }

    buf.pushCircle(sx, sy, hs + pulse, cRgb[0], cRgb[1], cRgb[2], 0.9, 0, 0);

    for (let row: number = 0; row < 4; row++) {
      for (let col: number = 0; col < 4; col++) {
        const scX: number = sx - hs + 6 + col * 7 + (row % 2) * 3;
        const scY: number = sy - hs + 6 + row * 6;
        const dist: number = Math.sqrt((scX - sx) * (scX - sx) + (scY - sy) * (scY - sy));
        if (dist < hs - 2) {
          buf.pushCircle(scX, scY, 2.5, scRgb[0], scRgb[1], scRgb[2], 0.2, 0, 0);
        }
      }
    }

    for (let bl: number = 0; bl < 6; bl++) {
      const blAng: number = (bl / 6) * Math.PI * 2 + t * 0.01;
      const blDist: number = hs * 0.5 + Math.sin(t * 0.03 + bl) * 2;
      const blX: number = sx + Math.cos(blAng) * blDist;
      const blY: number = sy + Math.sin(blAng) * blDist;
      const blA: number = 0.3 + Math.sin(t * 0.06 + bl * 2) * 0.2;
      buf.pushCircle(blX, blY, 1.5, blRgb[0], blRgb[1], blRgb[2], blA, 0, 0);
    }

    buf.pushCircle(sx - hs * 0.2, sy - hs * 0.3, hs * 0.35, 1, 1, 1, 0.1, 0, 0);

    for (let tn: number = 0; tn < 6; tn++) {
      const baseAngle: number = (tn / 6) * Math.PI * 2 + t * 0.02;
      const wave1: number = Math.sin(t * 0.04 + tn * 1.5) * 6;
      const wave2: number = Math.sin(t * 0.06 + tn * 2) * 4;
      const startR: number = hs * 0.7;
      const endR: number = hs + 14;
      const startX: number = sx + Math.cos(baseAngle) * startR;
      const startY: number = sy + Math.sin(baseAngle) * startR;
      const midX: number = sx + Math.cos(baseAngle + 0.3) * (startR + endR) * 0.5 + wave1;
      const midY: number = sy + Math.sin(baseAngle + 0.3) * (startR + endR) * 0.5 + wave2;
      const endX: number = sx + Math.cos(baseAngle + 0.5) * endR + wave1 * 0.5;
      const endY: number = sy + Math.sin(baseAngle + 0.5) * endR + wave2 * 0.5;

      buf.pushLine(startX, startY, midX, midY, 3, wlRgb[0], wlRgb[1], wlRgb[2], 0.5, 0);
      buf.pushLine(midX, midY, endX, endY, 3, wlRgb[0], wlRgb[1], wlRgb[2], 0.5, 0);
      buf.pushCircle(endX, endY, 1.5, bbRgb[0], bbRgb[1], bbRgb[2], 0.4, 0, 0);
    }

    buf.pushCircle(sx, sy, hs * 0.6, rnRgb[0], rnRgb[1], rnRgb[2], 0.3, 0, 0);

    buf.pushCircle(sx - 7, sy - 4, 5, 1, 1, 1, 1, 0, 0);
    buf.pushCircle(sx + 7, sy - 4, 5, 1, 1, 1, 1, 0, 0);
    buf.pushCircle(sx - 6, sy - 3, 2.5, irRgb[0], irRgb[1], irRgb[2], 1, 0, 0);
    buf.pushCircle(sx + 8, sy - 3, 2.5, irRgb[0], irRgb[1], irRgb[2], 1, 0, 0);
    buf.pushCircle(sx - 6, sy - 3, 1.2, ppRgb[0], ppRgb[1], ppRgb[2], 1, 0, 0);
    buf.pushCircle(sx + 8, sy - 3, 1.2, ppRgb[0], ppRgb[1], ppRgb[2], 1, 0, 0);
    buf.pushCircle(sx - 7, sy - 4.5, 1, 1, 1, 1, 1, 0, 0);
    buf.pushCircle(sx + 7, sy - 4.5, 1, 1, 1, 1, 1, 0, 0);
  }

  collectVoidRiftCommands(buf: DrawCmdBuffer, sx: number, sy: number,
      hs: number, pulse: number, color: string, ai: BossAIComponent, t: number): void {
    const cRgb: number[] = hexToRgb(color);
    const odRgb: number[] = hexToRgb('#7c3aed');
    const mrRgb: number[] = hexToRgb('#2d1060');
    const ehRgb: number[] = hexToRgb('#0d0d1a');
    const arRgb: number[] = hexToRgb('#a855f7');
    const icRgb: number[] = hexToRgb('#c084fc');
    const veRgb: number[] = hexToRgb('#e9d5ff');

    buf.pushCircle(sx, sy, hs + 20 + pulse, odRgb[0], odRgb[1], odRgb[2], 0.06, 0, 0);

    for (let d: number = 0; d < 8; d++) {
      const dAng: number = (d / 8) * Math.PI * 2 + t * 0.025;
      const dDist: number = hs + 6 + Math.sin(t * 0.04 + d * 1.7) * 5;
      const dx: number = sx + Math.cos(dAng) * dDist;
      const dy: number = sy + Math.sin(dAng) * dDist;
      const dSize: number = 1 + (d % 3);
      const dA: number = 0.5 + Math.sin(t * 0.08 + d) * 0.2;
      const dRgb: number[] = d % 2 === 0 ? arRgb : hexToRgb('#6d28d9');
      buf.pushRect(dx - dSize / 2, dy - dSize / 2, dSize, dSize, dRgb[0], dRgb[1], dRgb[2], dA, 0, 0);
    }

    buf.pushCircle(sx, sy, hs + pulse + 4, cRgb[0], cRgb[1], cRgb[2], 0.7, 0, 0);
    buf.pushCircle(sx, sy, hs * 0.75, mrRgb[0], mrRgb[1], mrRgb[2], 0.8, 0, 0);
    buf.pushCircle(sx, sy, hs * 0.45, ehRgb[0], ehRgb[1], ehRgb[2], 1, 0, 0);
    buf.pushCircle(sx, sy, hs * 0.25, 0, 0, 0, 1, 0, 0);

    for (let cr: number = 0; cr < 3; cr++) {
      const crAng: number = (cr / 3) * Math.PI * 2 + t * 0.06;
      const crR: number = hs * 0.5;
      const cx1: number = sx + Math.cos(crAng) * hs * 0.25;
      const cy1: number = sy + Math.sin(crAng) * hs * 0.25;
      const cx2: number = sx + Math.cos(crAng + 0.2) * crR * 0.6;
      const cy2: number = sy + Math.sin(crAng + 0.2) * crR * 0.6;
      const cx3: number = sx + Math.cos(crAng + 0.1) * crR;
      const cy3: number = sy + Math.sin(crAng + 0.1) * crR;
      buf.pushLine(cx1, cy1, cx2, cy2, 1, icRgb[0], icRgb[1], icRgb[2], 0.3, 0);
      buf.pushLine(cx2, cy2, cx3, cy3, 1, icRgb[0], icRgb[1], icRgb[2], 0.3, 0);
    }

    const veA: number = 0.4 + Math.sin(t * 0.05) * 0.2;
    buf.pushCircle(sx, sy, hs * 0.12, odRgb[0], odRgb[1], odRgb[2], veA, 0, 0);
    buf.pushCircle(sx, sy, hs * 0.05, veRgb[0], veRgb[1], veRgb[2], 0.6, 0, 0);
  }
}
