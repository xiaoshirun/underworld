import { PositionComponent, VelocityComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { PComp } from './PlayerRenderer';
import { ATTACK_DURATION, WEAPON_FORM_STATS, WeaponForm } from '../GameConstants';

export class WeaponRenderer {
  renderWeaponOnPlayer(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number): void {
    const form: WeaponForm = (pc.transform.currentWeaponForm as WeaponForm);
    const handX: number = sx + 5;
    const handY: number = sy + 2 + bobY;
    const fAng: number = pc.movement.facing;
    const cosF: number = Math.cos(fAng);
    const sinF: number = Math.sin(fAng);
    const perpX: number = -sinF;
    const perpY: number = cosF;

    if (!pc.combat.isAttacking) {
      const formColors: string[][] = [
        ['#60a5fa', '#2563eb'],
        ['#a78bfa', '#7c3aed'],
        ['#9ca3af', '#4b5563'],
        ['#7dd3fc', '#0284c7'],
        ['#fb923c', '#c2410c'],
        ['#ef4444', '#991b1b'],
      ];
      const colors: string[] = formColors[form];
      const t: number = pc.frameCount * 0.06;
      // Orbit: ball gently orbits around hand position
      const orbitR: number = 2.5;
      const orbitAng: number = t * 0.5;
      const orbOffX: number = Math.cos(orbitAng) * orbitR;
      const orbOffY: number = Math.sin(orbitAng) * orbitR * 0.6;
      const ballX: number = handX + cosF * 3 + orbOffX;
      const ballY: number = handY + sinF * 3 + orbOffY;
      const pulse: number = Math.sin(t) * 0.6;
      const baseR: number = 3.5;
      // Ground shadow
      c.globalAlpha = 0.12;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(ballX, ballY + baseR + 2, baseR * 0.8, 1.5, 0, 0, Math.PI * 2);
      c.fill();
      // Outer glow — breathing
      c.globalAlpha = 0.12 + Math.sin(t * 0.7) * 0.04;
      c.fillStyle = colors[0];
      c.beginPath();
      c.arc(ballX, ballY, baseR + 2.5 + pulse, 0, Math.PI * 2);
      c.fill();
      // Main chrome sphere
      c.globalAlpha = 0.88;
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(ballX, ballY, baseR + pulse * 0.3, 0, Math.PI * 2);
      c.fill();
      // Dark underside for depth
      c.fillStyle = '#6b7280';
      c.globalAlpha = 0.45;
      c.beginPath();
      c.arc(ballX + cosF * 0.6, ballY + sinF * 0.6 + 1.2, baseR * 0.65, 0, Math.PI * 2);
      c.fill();
      // Primary color swirl — orbiting inside
      c.globalAlpha = 0.4;
      c.fillStyle = colors[0];
      const swirlX: number = ballX + Math.cos(t * 1.3) * 1.4;
      const swirlY: number = ballY + Math.sin(t * 1.3) * 1.4;
      c.beginPath();
      c.arc(swirlX, swirlY, 1.8, 0, Math.PI * 2);
      c.fill();
      // Secondary swirl
      c.globalAlpha = 0.25;
      c.fillStyle = colors[1];
      const swirl2X: number = ballX + Math.cos(t * 0.9 + 2.5) * 1.6;
      const swirl2Y: number = ballY + Math.sin(t * 0.9 + 2.5) * 1.6;
      c.beginPath();
      c.arc(swirl2X, swirl2Y, 1.2, 0, Math.PI * 2);
      c.fill();
      // Third swirl — slower, larger, fainter
      c.globalAlpha = 0.15;
      c.fillStyle = colors[0];
      const swirl3X: number = ballX + Math.cos(t * 0.5 + 4.0) * 1.8;
      const swirl3Y: number = ballY + Math.sin(t * 0.5 + 4.0) * 1.0;
      c.beginPath();
      c.arc(swirl3X, swirl3Y, 2.2, 0, Math.PI * 2);
      c.fill();
      // Specular highlights
      c.globalAlpha = 0.92;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(ballX - 1.3, ballY - 1.3, 1.2, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.45;
      c.fillStyle = '#f9fafb';
      c.beginPath();
      c.arc(ballX + 0.8, ballY + 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      // Surface tension ripple
      c.globalAlpha = 0.2;
      c.strokeStyle = '#e5e7eb';
      c.lineWidth = 0.5;
      const rippleR: number = baseR * 0.55 + Math.sin(t * 2) * 0.4;
      c.beginPath();
      c.arc(ballX + Math.cos(t) * 0.4, ballY + Math.sin(t) * 0.4, rippleR, 0, Math.PI * 1.5);
      c.stroke();
      // Satellite droplets — tiny drops orbiting the ball
      for (let i: number = 0; i < 3; i++) {
        const dropAng: number = t * 0.8 + (Math.PI * 2 / 3) * i;
        const dropDist: number = baseR + 1.8 + Math.sin(t * 1.5 + i * 2) * 0.5;
        const dropX: number = ballX + Math.cos(dropAng) * dropDist;
        const dropY: number = ballY + Math.sin(dropAng) * dropDist * 0.7;
        const dropR: number = 0.5 + Math.sin(t * 2 + i) * 0.2;
        c.globalAlpha = 0.5 + Math.sin(t + i * 1.5) * 0.15;
        c.fillStyle = '#d1d5db';
        c.beginPath();
        c.arc(dropX, dropY, dropR, 0, Math.PI * 2);
        c.fill();
        // Tiny color tint on droplet
        c.globalAlpha = 0.25;
        c.fillStyle = colors[0];
        c.beginPath();
        c.arc(dropX + 0.2, dropY + 0.2, dropR * 0.6, 0, Math.PI * 2);
        c.fill();
      }
      // Ghostly weapon form hint — flickers inside the ball
      const hintAlpha: number = 0.06 + Math.sin(t * 0.3) * 0.03;
      c.globalAlpha = hintAlpha;
      c.strokeStyle = colors[0];
      c.lineWidth = 0.6;
      if (form === WeaponForm.BLADE || form === WeaponForm.DUAL_BLADES) {
        // Hint of a blade line
        c.beginPath();
        c.moveTo(ballX - 1, ballY + 1);
        c.lineTo(ballX + 2, ballY - 2);
        c.stroke();
      } else if (form === WeaponForm.WHIP) {
        c.beginPath();
        c.arc(ballX, ballY, 1.5, 0, Math.PI);
        c.stroke();
      } else if (form === WeaponForm.HAMMER) {
        c.beginPath();
        c.moveTo(ballX - 1.5, ballY - 1);
        c.lineTo(ballX + 1.5, ballY - 1);
        c.lineTo(ballX + 1.5, ballY + 1);
        c.lineTo(ballX - 1.5, ballY + 1);
        c.closePath();
        c.stroke();
      } else if (form === WeaponForm.STAFF) {
        c.beginPath();
        c.arc(ballX, ballY - 1, 1.2, 0, Math.PI * 2);
        c.stroke();
      } else if (form === WeaponForm.GREAT_AXE) {
        c.beginPath();
        c.moveTo(ballX - 1, ballY + 1.5);
        c.quadraticCurveTo(ballX + 2, ballY, ballX - 1, ballY - 1.5);
        c.stroke();
      }
      c.globalAlpha = 1.0;
      return;
    }

    // === Morphing transition: ball → weapon ===
    const atkProgress: number = 1.0 - (pc.combat.attackTimer / ATTACK_DURATION);
    if (atkProgress < 0.35) {
      const morphAlpha: number = (1.0 - atkProgress / 0.35) * 0.6;
      const formColors2: string[][] = [
        ['#60a5fa', '#2563eb'], ['#a78bfa', '#7c3aed'], ['#9ca3af', '#4b5563'],
        ['#7dd3fc', '#0284c7'], ['#fb923c', '#c2410c'], ['#ef4444', '#991b1b'],
      ];
      const mc: string[] = formColors2[form];
      const stretchLen: number = 8 + (1.0 - atkProgress / 0.35) * 6;
      // Liquid metal stretching streaks from ball to weapon direction
      c.globalAlpha = morphAlpha * 0.5;
      c.strokeStyle = '#d1d5db';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX + cosF * 2, handY + sinF * 2);
      c.lineTo(handX + cosF * stretchLen, handY + sinF * stretchLen);
      c.stroke();
      c.globalAlpha = morphAlpha * 0.35;
      c.strokeStyle = mc[0];
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX + cosF * 2 + perpX * 1, handY + sinF * 2 + perpY * 1);
      c.lineTo(handX + cosF * stretchLen * 0.8, handY + sinF * stretchLen * 0.8);
      c.stroke();
      c.beginPath();
      c.moveTo(handX + cosF * 2 - perpX * 1, handY + sinF * 2 - perpY * 1);
      c.lineTo(handX + cosF * stretchLen * 0.7, handY + sinF * stretchLen * 0.7);
      c.stroke();
      // Splash ring at materialization point
      c.globalAlpha = morphAlpha * 0.3;
      c.strokeStyle = mc[0];
      c.lineWidth = 1;
      const splashR: number = 3 + atkProgress / 0.35 * 5;
      c.beginPath();
      c.arc(handX + cosF * 5, handY + sinF * 5, splashR, 0, Math.PI * 2);
      c.stroke();
      // Tiny droplets flying outward
      for (let i: number = 0; i < 4; i++) {
        const dropAng: number = fAng + (i - 1.5) * 0.8;
        const dropDist: number = 3 + atkProgress / 0.35 * 8;
        const dx: number = handX + cosF * 4 + Math.cos(dropAng) * dropDist;
        const dy: number = handY + sinF * 4 + Math.sin(dropAng) * dropDist;
        c.globalAlpha = morphAlpha * 0.4;
        c.fillStyle = '#d1d5db';
        c.beginPath();
        c.arc(dx, dy, 0.6, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 1.0;
    }

    if (form === WeaponForm.BLADE) {
      const len: number = 16;
      const tipX: number = handX + cosF * len;
      const tipY: number = handY + sinF * len;
      const baseX: number = handX + cosF * 3;
      const baseY: number = handY + sinF * 3;
      c.strokeStyle = '#3b82f6';
      c.lineWidth = 3.5;
      c.beginPath();
      c.moveTo(baseX - perpX * 0.5, baseY - perpY * 0.5);
      c.lineTo(tipX, tipY);
      c.stroke();
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(baseX, baseY);
      c.lineTo(tipX, tipY);
      c.stroke();
      c.strokeStyle = '#bfdbfe';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(baseX + perpX * 1, baseY + perpY * 1);
      c.lineTo(tipX, tipY);
      c.stroke();
      c.strokeStyle = '#2563eb';
      c.lineWidth = 0.8;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(baseX + cosF * 2, baseY + sinF * 2);
      c.lineTo(handX + cosF * (len - 3), handY + sinF * (len - 3));
      c.stroke();
      // Chrome edge — liquid metal sheen along the blade spine
      c.globalAlpha = 0.2;
      c.strokeStyle = '#d1d5db';
      c.lineWidth = 0.6;
      c.beginPath();
      c.moveTo(baseX + perpX * 0.3, baseY + perpY * 0.3);
      c.lineTo(tipX + perpX * 0.2, tipY + perpY * 0.2);
      c.stroke();
      c.globalAlpha = 0.12;
      c.strokeStyle = '#ffffff';
      c.lineWidth = 0.4;
      c.beginPath();
      c.moveTo(baseX - perpX * 0.8, baseY - perpY * 0.8);
      c.lineTo(tipX - perpX * 0.3, tipY - perpY * 0.3);
      c.stroke();
      c.globalAlpha = 1.0;
      const guardCx: number = handX + cosF * 3;
      const guardCy: number = handY + sinF * 3;
      c.strokeStyle = '#b45309';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(guardCx + perpX * 3.5, guardCy + perpY * 3.5);
      c.lineTo(guardCx - perpX * 3.5, guardCy - perpY * 3.5);
      c.stroke();
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(guardCx + perpX * 3, guardCy + perpY * 3);
      c.lineTo(guardCx - perpX * 3, guardCy - perpY * 3);
      c.stroke();
      c.fillStyle = '#fcd34d';
      c.beginPath();
      c.arc(guardCx + perpX * 3.5, guardCy + perpY * 3.5, 1, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(guardCx - perpX * 3.5, guardCy - perpY * 3.5, 1, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#78350f';
      c.lineWidth = 0.8;
      for (let i: number = 0; i < 3; i++) {
        const t: number = 0.3 + i * 0.25;
        const gx: number = handX + cosF * 3 * t;
        const gy: number = handY + sinF * 3 * t;
        c.beginPath();
        c.moveTo(gx + perpX * 1.2, gy + perpY * 1.2);
        c.lineTo(gx - perpX * 1.2, gy - perpY * 1.2);
        c.stroke();
      }
      const pomX: number = handX - cosF * 1;
      const pomY: number = handY - sinF * 1;
      c.fillStyle = '#fbbf24';
      c.beginPath();
      c.arc(pomX, pomY, 1.5, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#fcd34d';
      c.beginPath();
      c.arc(pomX - 0.5, pomY - 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.8;
      c.beginPath();
      c.arc(tipX, tipY, 1.5, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.WHIP) {
      const len: number = 18;
      const segs: number = 6;
      c.strokeStyle = '#6d28d9';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      let prevX: number = handX;
      let prevY: number = handY;
      for (let i: number = 1; i <= segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + pc.frameCount * 0.15) * 3 * t;
        const segX: number = handX + cosF * len * t + perpX * wave;
        const segY: number = handY + sinF * len * t + perpY * wave;
        c.lineTo(segX, segY);
        prevX = segX;
        prevY = segY;
      }
      c.stroke();
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 1.8;
      c.beginPath();
      c.moveTo(handX, handY);
      for (let i: number = 1; i <= segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + pc.frameCount * 0.15) * 3 * t;
        const segX: number = handX + cosF * len * t + perpX * wave;
        const segY: number = handY + sinF * len * t + perpY * wave;
        c.lineTo(segX, segY);
      }
      c.stroke();
      c.fillStyle = '#c4b5fd';
      for (let i: number = 1; i < segs; i++) {
        const t: number = i / segs;
        const wave: number = Math.sin(t * Math.PI * 2 + pc.frameCount * 0.15) * 3 * t;
        const jx: number = handX + cosF * len * t + perpX * wave;
        const jy: number = handY + sinF * len * t + perpY * wave;
        c.beginPath();
        c.arc(jx, jy, 0.8, 0, Math.PI * 2);
        c.fill();
      }
      c.strokeStyle = '#581c87';
      c.lineWidth = 1;
      for (let i: number = 0; i < 2; i++) {
        const t: number = 0.05 + i * 0.08;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.5, wy + perpY * 1.5);
        c.lineTo(wx - perpX * 1.5, wy - perpY * 1.5);
        c.stroke();
      }
      c.fillStyle = '#c026d3';
      c.beginPath();
      c.moveTo(prevX + cosF * 4, prevY + sinF * 4);
      c.lineTo(prevX + perpX * 2.5, prevY + perpY * 2.5);
      c.lineTo(prevX - perpX * 2.5, prevY - perpY * 2.5);
      c.closePath();
      c.fill();
      c.strokeStyle = '#e879f9';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(prevX + cosF * 3.5, prevY + sinF * 3.5);
      c.lineTo(prevX + perpX * 1.5, prevY + perpY * 1.5);
      c.stroke();
      c.fillStyle = '#d946ef';
      c.beginPath();
      c.moveTo(prevX + perpX * 2.5, prevY + perpY * 2.5);
      c.lineTo(prevX + perpX * 4 + cosF * 1, prevY + perpY * 4 + sinF * 1);
      c.lineTo(prevX + perpX * 1.5, prevY + perpY * 1.5);
      c.closePath();
      c.fill();
      c.beginPath();
      c.moveTo(prevX - perpX * 2.5, prevY - perpY * 2.5);
      c.lineTo(prevX - perpX * 4 + cosF * 1, prevY - perpY * 4 + sinF * 1);
      c.lineTo(prevX - perpX * 1.5, prevY - perpY * 1.5);
      c.closePath();
      c.fill();
    } else if (form === WeaponForm.HAMMER) {
      const len: number = 10;
      const headX: number = handX + cosF * len;
      const headY: number = handY + sinF * len;
      c.strokeStyle = '#713f12';
      c.lineWidth = 3.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(headX, headY);
      c.stroke();
      c.strokeStyle = '#8b6914';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(headX, headY);
      c.stroke();
      c.strokeStyle = '#a38524';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + perpX * 0.8, handY + perpY * 0.8);
      c.lineTo(headX + perpX * 0.8, headY + perpY * 0.8);
      c.stroke();
      c.strokeStyle = '#451a03';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const t: number = 0.15 + i * 0.18;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.8, wy + perpY * 1.8);
        c.lineTo(wx - perpX * 1.8, wy - perpY * 1.8);
        c.stroke();
      }
      c.save();
      c.translate(headX, headY);
      c.rotate(fAng);
      c.fillStyle = '#374151';
      c.fillRect(-3, -6, 12, 12);
      c.fillStyle = '#6b7280';
      c.fillRect(-2, -5, 10, 10);
      c.fillStyle = '#9ca3af';
      c.fillRect(-2, -5, 10, 3);
      c.fillStyle = '#4b5563';
      c.fillRect(-2, 2, 10, 3);
      c.strokeStyle = '#374151';
      c.lineWidth = 0.5;
      c.globalAlpha = 0.4;
      for (let i: number = 0; i < 3; i++) {
        const fy: number = -3 + i * 3;
        c.beginPath();
        c.moveTo(-1, fy);
        c.lineTo(7, fy);
        c.stroke();
      }
      c.globalAlpha = 1.0;
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(6, -3, 1, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(6, 3, 1, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#f3f4f6';
      c.beginPath();
      c.arc(5.5, -3.5, 0.4, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(5.5, 2.5, 0.4, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#9ca3af';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(8, -5);
      c.lineTo(8, 5);
      c.stroke();
      // Liquid metal sheen on hammer face
      c.globalAlpha = 0.15;
      c.fillStyle = '#e5e7eb';
      c.fillRect(-1, -4, 8, 2);
      c.globalAlpha = 0.08;
      c.fillStyle = '#ffffff';
      c.fillRect(0, -3, 5, 1);
      c.globalAlpha = 1.0;
      c.restore();
    } else if (form === WeaponForm.STAFF) {
      const len: number = 18;
      const orbX: number = handX + cosF * len;
      const orbY: number = handY + sinF * len;
      c.strokeStyle = '#4c1d95';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(orbX, orbY);
      c.stroke();
      c.strokeStyle = '#7c3aed';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(orbX, orbY);
      c.stroke();
      c.strokeStyle = '#8b5cf6';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX + perpX * 0.8, handY + perpY * 0.8);
      c.lineTo(orbX + perpX * 0.8, orbY + perpY * 0.8);
      c.stroke();
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      for (let i: number = 1; i <= 4; i++) {
        const t: number = i * 0.2;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 1.8, wy + perpY * 1.8);
        c.lineTo(wx - perpX * 1.8, wy - perpY * 1.8);
        c.stroke();
      }
      c.fillStyle = '#a78bfa';
      c.globalAlpha = 0.6;
      for (let i: number = 0; i < 3; i++) {
        const t: number = 0.15 + i * 0.25;
        const rx: number = handX + cosF * len * t + perpX * 0.5;
        const ry: number = handY + sinF * len * t + perpY * 0.5;
        c.beginPath();
        c.arc(rx, ry, 0.6, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 1.0;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.2;
      for (let i: number = 0; i < 3; i++) {
        const ang: number = fAng + (i - 1) * 1.2;
        c.beginPath();
        c.moveTo(orbX - cosF * 2, orbY - sinF * 2);
        c.lineTo(orbX + Math.cos(ang) * 3, orbY + Math.sin(ang) * 3);
        c.stroke();
      }
      const pulse: number = Math.sin(pc.frameCount * 0.1) * 1.5;
      c.globalAlpha = 0.3;
      c.fillStyle = '#38bdf8';
      c.beginPath();
      c.arc(orbX, orbY, 5 + pulse, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.5;
      c.fillStyle = '#0ea5e9';
      c.beginPath();
      c.arc(orbX, orbY, 4, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.9;
      c.fillStyle = '#7dd3fc';
      c.beginPath();
      c.arc(orbX, orbY, 3, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#bae6fd';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      const swirlAng: number = pc.frameCount * 0.08;
      c.beginPath();
      c.arc(orbX + Math.cos(swirlAng) * 1, orbY + Math.sin(swirlAng) * 1, 1.5, 0, Math.PI * 1.2);
      c.stroke();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.85;
      c.beginPath();
      c.arc(orbX - 1, orbY - 1, 1.2, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.4;
      c.beginPath();
      c.arc(orbX + 1, orbY + 0.5, 0.6, 0, Math.PI * 2);
      c.fill();
      // Chrome ring — liquid metal origin hint
      c.globalAlpha = 0.15;
      c.strokeStyle = '#d1d5db';
      c.lineWidth = 0.5;
      c.beginPath();
      c.arc(orbX, orbY, 4.5, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.08;
      c.strokeStyle = '#ffffff';
      c.lineWidth = 0.3;
      c.beginPath();
      c.arc(orbX, orbY, 5.2, 0.3, Math.PI * 1.3);
      c.stroke();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.DUAL_BLADES) {
      const len: number = 11;
      const rTipX: number = handX + cosF * len + perpX * 1.5;
      const rTipY: number = handY + sinF * len + perpY * 1.5;
      c.strokeStyle = '#c2410c';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      c.strokeStyle = '#fb923c';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      c.strokeStyle = '#fdba74';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + cosF * 2 + perpX * 0.5, handY + sinF * 2 + perpY * 0.5);
      c.lineTo(rTipX, rTipY);
      c.stroke();
      c.strokeStyle = '#9a3412';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(handX + cosF * 2, handY + sinF * 2);
      c.lineTo(handX + cosF * (len - 2) + perpX * 1.5, handY + sinF * (len - 2) + perpY * 1.5);
      c.stroke();
      c.globalAlpha = 1.0;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX + perpX * 2.5, handY + perpY * 2.5);
      c.lineTo(handX - perpX * 1.5, handY - perpY * 1.5);
      c.stroke();
      c.strokeStyle = '#7c2d12';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX - cosF * 1 + perpX, handY - sinF * 1 + perpY);
      c.lineTo(handX - cosF * 1 - perpX, handY - sinF * 1 - perpY);
      c.stroke();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.7;
      c.beginPath();
      c.arc(rTipX, rTipY, 1, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      const handX2: number = sx - 5;
      const lTipX: number = handX2 + cosF * len - perpX * 1.5;
      const lTipY: number = handY + sinF * len - perpY * 1.5;
      c.strokeStyle = '#c2410c';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX2, handY);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      c.strokeStyle = '#fb923c';
      c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(handX2, handY);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      c.strokeStyle = '#fdba74';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX2 + cosF * 2 - perpX * 0.5, handY + sinF * 2 - perpY * 0.5);
      c.lineTo(lTipX, lTipY);
      c.stroke();
      c.strokeStyle = '#9a3412';
      c.lineWidth = 0.6;
      c.globalAlpha = 0.5;
      c.beginPath();
      c.moveTo(handX2 + cosF * 2, handY + sinF * 2);
      c.lineTo(handX2 + cosF * (len - 2) - perpX * 1.5, handY + sinF * (len - 2) - perpY * 1.5);
      c.stroke();
      c.globalAlpha = 1.0;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(handX2 - perpX * 2.5, handY - perpY * 2.5);
      c.lineTo(handX2 + perpX * 1.5, handY + perpY * 1.5);
      c.stroke();
      c.strokeStyle = '#7c2d12';
      c.lineWidth = 0.8;
      c.beginPath();
      c.moveTo(handX2 - cosF * 1 + perpX, handY - sinF * 1 + perpY);
      c.lineTo(handX2 - cosF * 1 - perpX, handY - sinF * 1 - perpY);
      c.stroke();
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.7;
      c.beginPath();
      c.arc(lTipX, lTipY, 1, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    } else if (form === WeaponForm.GREAT_AXE) {
      const len: number = 12;
      const axX: number = handX + cosF * len;
      const axY: number = handY + sinF * len;
      c.strokeStyle = '#451a03';
      c.lineWidth = 4;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(axX, axY);
      c.stroke();
      c.strokeStyle = '#78350f';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(handX, handY);
      c.lineTo(axX, axY);
      c.stroke();
      c.strokeStyle = '#92400e';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(handX + perpX * 1, handY + perpY * 1);
      c.lineTo(axX + perpX * 1, axY + perpY * 1);
      c.stroke();
      c.strokeStyle = '#1c0a00';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const t: number = 0.15 + i * 0.18;
        const wx: number = handX + cosF * len * t;
        const wy: number = handY + sinF * len * t;
        c.beginPath();
        c.moveTo(wx + perpX * 2, wy + perpY * 2);
        c.lineTo(wx - perpX * 2, wy - perpY * 2);
        c.stroke();
      }
      c.strokeStyle = '#6b7280';
      c.lineWidth = 2;
      const colX: number = handX + cosF * (len - 2);
      const colY: number = handY + sinF * (len - 2);
      c.beginPath();
      c.moveTo(colX + perpX * 2.5, colY + perpY * 2.5);
      c.lineTo(colX - perpX * 2.5, colY - perpY * 2.5);
      c.stroke();
      c.strokeStyle = '#9ca3af';
      c.lineWidth = 1;
      c.beginPath();
      c.moveTo(colX + perpX * 2, colY + perpY * 2);
      c.lineTo(colX - perpX * 2, colY - perpY * 2);
      c.stroke();
      c.save();
      c.translate(axX, axY);
      c.rotate(fAng);
      c.fillStyle = '#991b1b';
      c.beginPath();
      c.moveTo(-1, -8);
      c.quadraticCurveTo(9, -6, 11, 0);
      c.quadraticCurveTo(9, 6, -1, 8);
      c.lineTo(-1, -8);
      c.closePath();
      c.fill();
      c.fillStyle = '#dc2626';
      c.beginPath();
      c.moveTo(0, -7);
      c.quadraticCurveTo(8, -5, 10, 0);
      c.quadraticCurveTo(8, 5, 0, 7);
      c.lineTo(0, -7);
      c.closePath();
      c.fill();
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.moveTo(1, -5);
      c.quadraticCurveTo(6, -3, 8, 0);
      c.quadraticCurveTo(6, 1, 1, 2);
      c.lineTo(1, -5);
      c.closePath();
      c.fill();
      c.strokeStyle = '#b91c1c';
      c.lineWidth = 0.5;
      c.globalAlpha = 0.5;
      for (let i: number = 0; i < 3; i++) {
        const fy: number = -4 + i * 3;
        c.beginPath();
        c.moveTo(2, fy);
        c.quadraticCurveTo(5, fy + 0.5, 7, fy);
        c.stroke();
      }
      c.globalAlpha = 1.0;
      c.strokeStyle = '#fca5a5';
      c.lineWidth = 1.2;
      c.beginPath();
      c.moveTo(1, -6);
      c.quadraticCurveTo(7, -4, 9, 0);
      c.stroke();
      c.strokeStyle = '#fecaca';
      c.lineWidth = 0.6;
      c.beginPath();
      c.moveTo(2, -5);
      c.quadraticCurveTo(6, -3, 8, 0);
      c.stroke();
      c.strokeStyle = '#7f1d1d';
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(0, -7);
      c.lineTo(0, 7);
      c.stroke();
      c.fillStyle = '#d1d5db';
      c.beginPath();
      c.arc(2, 0, 1, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#f3f4f6';
      c.beginPath();
      c.arc(1.5, -0.5, 0.4, 0, Math.PI * 2);
      c.fill();
      // Liquid metal edge sheen
      c.globalAlpha = 0.18;
      c.strokeStyle = '#e5e7eb';
      c.lineWidth = 0.6;
      c.beginPath();
      c.moveTo(2, -6);
      c.quadraticCurveTo(8, -4, 10, 0);
      c.stroke();
      c.globalAlpha = 0.1;
      c.strokeStyle = '#ffffff';
      c.lineWidth = 0.4;
      c.beginPath();
      c.moveTo(3, -5);
      c.quadraticCurveTo(7, -3, 9, 0);
      c.stroke();
      c.globalAlpha = 1.0;
      c.restore();
    }
  }

  renderWeaponAttackEffect(c: CanvasRenderingContext2D, sx: number, sy: number, pc: PComp, bobY: number): void {
    const form: WeaponForm = (pc.transform.currentWeaponForm as WeaponForm);
    const formStats: number[] = WEAPON_FORM_STATS[form];
    const range: number = formStats[0];
    const width: number = formStats[1];
    const offX: number = Math.cos(pc.movement.facing) * range * 0.7;
    const offY: number = Math.sin(pc.movement.facing) * range * 0.7;
    const cx: number = sx + offX;
    const cy: number = sy + offY + bobY;
    const perpX: number = -Math.sin(pc.movement.facing);
    const perpY: number = Math.cos(pc.movement.facing);

    // Liquid metal flash at attack start
    const atkProg: number = 1.0 - (pc.combat.attackTimer / ATTACK_DURATION);
    if (atkProg < 0.25) {
      const flashA: number = (1.0 - atkProg / 0.25) * 0.35;
      c.globalAlpha = flashA;
      c.fillStyle = '#e5e7eb';
      c.beginPath();
      c.arc(sx + Math.cos(pc.movement.facing) * 6, sy + bobY + Math.sin(pc.movement.facing) * 6, 4 + atkProg * 12, 0, Math.PI * 2);
      c.fill();
      // Chrome splash particles
      for (let i: number = 0; i < 5; i++) {
        const pa: number = pc.movement.facing + (i - 2) * 0.6;
        const pd: number = 5 + atkProg / 0.25 * 10;
        c.globalAlpha = flashA * 0.6;
        c.fillStyle = '#d1d5db';
        c.beginPath();
        c.arc(sx + Math.cos(pa) * pd, sy + bobY + Math.sin(pa) * pd, 0.8, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 1.0;
    }

    if (form === WeaponForm.BLADE) {
      const arcStart: number = pc.movement.facing - 1.0;
      const arcEnd: number = pc.movement.facing + 1.0;
      c.globalAlpha = 0.25;
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 8;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.85, arcStart, arcEnd);
      c.stroke();
      c.globalAlpha = 0.7;
      c.strokeStyle = '#93c5fd';
      c.lineWidth = 4;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.85, arcStart, arcEnd);
      c.stroke();
      c.globalAlpha = 0.9;
      c.strokeStyle = '#dbeafe';
      c.lineWidth = 1.5;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.7, arcStart, arcEnd);
      c.stroke();
      // Chrome metallic trail
      c.globalAlpha = 0.3;
      c.strokeStyle = '#d1d5db';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.6, arcStart + 0.2, arcEnd - 0.2);
      c.stroke();
      c.globalAlpha = 0.15;
      c.strokeStyle = '#9ca3af';
      c.lineWidth = 1;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.5, arcStart + 0.4, arcEnd - 0.4);
      c.stroke();
      const sparkAng: number = pc.movement.facing + 0.8;
      const sparkX: number = sx + Math.cos(sparkAng) * range * 0.85;
      const sparkY: number = sy + bobY + Math.sin(sparkAng) * range * 0.85;
      c.fillStyle = '#ffffff';
      c.globalAlpha = 0.8;
      c.beginPath();
      c.arc(sparkX, sparkY, 2, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.WHIP) {
      const whipLen: number = range * 1.1;
      c.globalAlpha = 0.8;
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(sx + Math.cos(pc.movement.facing) * 8, sy + bobY + Math.sin(pc.movement.facing) * 8);
      const cp1x: number = sx + Math.cos(pc.movement.facing) * whipLen * 0.5 + perpX * 15;
      const cp1y: number = sy + bobY + Math.sin(pc.movement.facing) * whipLen * 0.5 + perpY * 15;
      const endX: number = sx + Math.cos(pc.movement.facing) * whipLen;
      const endY: number = sy + bobY + Math.sin(pc.movement.facing) * whipLen;
      c.quadraticCurveTo(cp1x, cp1y, endX, endY);
      c.stroke();
      c.globalAlpha = 0.6;
      c.fillStyle = '#e879f9';
      c.beginPath();
      c.arc(endX, endY, 5, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.3;
      c.fillStyle = '#f0abfc';
      c.beginPath();
      c.arc(endX, endY, 9, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.5;
      c.strokeStyle = '#d8b4fe';
      c.lineWidth = 1;
      for (let i: number = 0; i < 4; i++) {
        const a: number = pc.movement.facing + (i - 1.5) * 0.5;
        c.beginPath();
        c.moveTo(endX, endY);
        c.lineTo(endX + Math.cos(a) * 8, endY + Math.sin(a) * 8);
        c.stroke();
      }
    } else if (form === WeaponForm.HAMMER) {
      c.globalAlpha = 0.5;
      c.fillStyle = '#f97316';
      c.beginPath();
      c.arc(cx, cy, width * 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.7;
      c.strokeStyle = '#fdba74';
      c.lineWidth = 3;
      c.beginPath();
      c.arc(cx, cy, width * 0.8, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.3;
      c.strokeStyle = '#fed7aa';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(cx, cy, width * 1.2, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.6;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 1.5;
      for (let i: number = 0; i < 6; i++) {
        const a: number = (Math.PI * 2 / 6) * i;
        c.beginPath();
        c.moveTo(cx + Math.cos(a) * width * 0.3, cy + Math.sin(a) * width * 0.3);
        c.lineTo(cx + Math.cos(a) * width * 1.0, cy + Math.sin(a) * width * 1.0);
        c.stroke();
      }
    } else if (form === WeaponForm.STAFF) {
      const boltX: number = sx + Math.cos(pc.movement.facing) * range;
      const boltY: number = sy + bobY + Math.sin(pc.movement.facing) * range;
      c.globalAlpha = 0.3;
      c.strokeStyle = '#38bdf8';
      c.lineWidth = 4;
      c.beginPath();
      c.moveTo(sx + Math.cos(pc.movement.facing) * 10, sy + bobY + Math.sin(pc.movement.facing) * 10);
      c.lineTo(boltX, boltY);
      c.stroke();
      c.globalAlpha = 0.35;
      c.fillStyle = '#0ea5e9';
      c.beginPath();
      c.arc(boltX, boltY, 12, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.85;
      c.fillStyle = '#7dd3fc';
      c.beginPath();
      c.arc(boltX, boltY, 6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.9;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(boltX, boltY, 2.5, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.DUAL_BLADES) {
      for (let side: number = -1; side <= 1; side += 2) {
        const arcCx: number = sx + perpX * 8 * side;
        const arcCy: number = sy + bobY + perpY * 8 * side;
        c.globalAlpha = 0.25;
        c.strokeStyle = '#fb923c';
        c.lineWidth = 6;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.7, pc.movement.facing - 0.8, pc.movement.facing + 0.8);
        c.stroke();
        c.globalAlpha = 0.75;
        c.strokeStyle = '#fdba74';
        c.lineWidth = 3;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.7, pc.movement.facing - 0.8, pc.movement.facing + 0.8);
        c.stroke();
        c.globalAlpha = 0.9;
        c.strokeStyle = '#fff7ed';
        c.lineWidth = 1;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.55, pc.movement.facing - 0.6, pc.movement.facing + 0.6);
        c.stroke();
      }
    } else if (form === WeaponForm.GREAT_AXE) {
      c.globalAlpha = 0.35;
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.7, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 0.7;
      c.strokeStyle = '#fca5a5';
      c.lineWidth = 4;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.9, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.3;
      c.strokeStyle = '#fecaca';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 1.2, 0, Math.PI * 2);
      c.stroke();
      c.globalAlpha = 0.5;
      c.strokeStyle = '#fbbf24';
      c.lineWidth = 2;
      for (let i: number = 0; i < 8; i++) {
        const a: number = (Math.PI * 2 / 8) * i;
        c.beginPath();
        c.moveTo(sx + Math.cos(a) * range * 0.4, sy + bobY + Math.sin(a) * range * 0.4);
        c.lineTo(sx + Math.cos(a) * range * 1.1, sy + bobY + Math.sin(a) * range * 1.1);
        c.stroke();
      }
    }

    c.globalAlpha = 1.0;
  }
}
