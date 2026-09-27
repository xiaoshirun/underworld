// entry/src/main/ets/engine/systems/ParticleSimSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { Transform } from '../components/Transform';
import { ParticleEmitterComponent, ParticleEmitterConfig } from '../components/ParticleEmitterComp';

interface InternalParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  size: number;
  startSize: number;
  endSize: number;
  color: string;
  endColor: string;
  alpha: number;
  startAlpha: number;
  endAlpha: number;
  gravity: number;
  friction: number;
  rotation: number;
  rotationSpeed: number;
  shape: number;
  shrink: boolean;
  fadeOut: boolean;
}

interface EmitterState {
  particles: InternalParticle[];
  emitTimer: number;
  age: number;
}

export class ParticleSimSystem extends System {
  readonly name: string = 'particleSim';
  readonly dependencies: string[] = [];
  priority: number = 30;

  private states: Map<number, EmitterState> = new Map();

  update(world: World, dt: number, entities: Entity[]): void {
    const emitters: Entity[] = world.query('particleEmitter', 'transform');
    for (const e of emitters) {
      const comp: ParticleEmitterComponent | undefined =
        world.getComponent<ParticleEmitterComponent>(e, 'particleEmitter');
      const transform: Transform | undefined =
        world.getComponent<Transform>(e, 'transform');
      if (!comp || !transform) continue;

      const idx: number = entities.indexOf(e);
      let state: EmitterState | undefined = this.states.get(idx);
      if (!state) {
        state = { particles: [], emitTimer: 0, age: 0 };
        this.states.set(idx, state);
      }

      if (comp.active) {
        state.emitTimer += dt;
        if (state.emitTimer >= comp.emitRate) {
          state.emitTimer = 0;
          this.spawnParticles(state, comp, transform.x, transform.y);
        }
      }

      if (comp.lifetime > 0) {
        state.age += dt;
        if (state.age >= comp.lifetime) {
          comp.active = false;
        }
      }

      this.updateParticles(state, dt);

      if (state.particles.length > comp.maxParticles) {
        state.particles.splice(0, state.particles.length - comp.maxParticles);
      }
    }
  }

  render(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void {
    const emitters: Entity[] = world.query('particleEmitter', 'transform');
    for (const e of emitters) {
      const comp: ParticleEmitterComponent | undefined =
        world.getComponent<ParticleEmitterComponent>(e, 'particleEmitter');
      const transform: Transform | undefined =
        world.getComponent<Transform>(e, 'transform');
      if (!comp || !transform) continue;

      const idx: number = entities.indexOf(e);
      const state: EmitterState | undefined = this.states.get(idx);
      if (!state) continue;

      for (const p of state.particles) {
        const sx: number = p.x;
        const sy: number = p.y;
        ctx.globalAlpha = Math.max(0, Math.min(1, p.alpha));
        ctx.fillStyle = p.color;

        switch (p.shape) {
          case 0: // CIRCLE
            ctx.beginPath();
            ctx.arc(sx, sy, Math.max(0.5, p.size), 0, Math.PI * 2);
            ctx.fill();
            break;
          case 1: // SQUARE
            ctx.fillRect(sx - p.size, sy - p.size, p.size * 2, p.size * 2);
            break;
          case 2: // DIAMOND
            ctx.save();
            ctx.translate(sx, sy);
            ctx.rotate(p.rotation);
            ctx.beginPath();
            ctx.moveTo(0, -p.size);
            ctx.lineTo(p.size, 0);
            ctx.lineTo(0, p.size);
            ctx.lineTo(-p.size, 0);
            ctx.closePath();
            ctx.fill();
            ctx.restore();
            break;
          case 3: // STAR
            ctx.save();
            ctx.translate(sx, sy);
            ctx.rotate(p.rotation);
            this.drawStar(ctx, p.size);
            ctx.restore();
            break;
        }
      }
    }
    ctx.globalAlpha = 1.0;
  }

  private spawnParticles(state: EmitterState, comp: ParticleEmitterComponent, x: number, y: number): void {
    const cfg: ParticleEmitterConfig = comp.config;
    const count: number = Math.max(1, Math.floor(comp.emitRate / 10));
    for (let i: number = 0; i < count; i++) {
      const angle: number = cfg.angleMin + Math.random() * (cfg.angleMax - cfg.angleMin);
      const speed: number = cfg.speedMin + Math.random() * (cfg.speedMax - cfg.speedMin);
      const life: number = cfg.lifeMin + Math.random() * (cfg.lifeMax - cfg.lifeMin);
      const size: number = cfg.sizeMin + Math.random() * (cfg.sizeMax - cfg.sizeMin);
      const endSize: number = cfg.endSizeMin + Math.random() * (cfg.endSizeMax - cfg.endSizeMin);
      const colorIdx: number = Math.floor(Math.random() * cfg.colors.length);
      const color: string = cfg.colors[colorIdx];
      const endColor: string = cfg.endColors.length > 0
        ? cfg.endColors[colorIdx % cfg.endColors.length] : color;
      const ox: number = (Math.random() - 0.5) * cfg.spreadX;
      const oy: number = (Math.random() - 0.5) * cfg.spreadY;

      state.particles.push({
        x: x + ox, y: y + oy,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: life, maxLife: life,
        size: size, startSize: size, endSize: endSize,
        color: color, endColor: endColor,
        alpha: 1.0, startAlpha: 1.0,
        endAlpha: cfg.fadeOut ? 0.0 : 1.0,
        gravity: cfg.gravity, friction: cfg.friction,
        rotation: Math.random() * Math.PI * 2,
        rotationSpeed: (Math.random() - 0.5) * 0.2,
        shape: cfg.shape, shrink: cfg.shrink, fadeOut: cfg.fadeOut
      });
    }
  }

  private updateParticles(state: EmitterState, dt: number): void {
    for (let i: number = state.particles.length - 1; i >= 0; i--) {
      const p: InternalParticle = state.particles[i];
      p.vy += p.gravity * (dt / 16);
      p.vx *= p.friction;
      p.vy *= p.friction;
      p.x += p.vx * (dt / 16);
      p.y += p.vy * (dt / 16);
      p.rotation += p.rotationSpeed;
      p.life -= dt;

      const t: number = 1.0 - (p.life / p.maxLife);
      p.alpha = p.startAlpha + (p.endAlpha - p.startAlpha) * t;
      if (p.shrink) {
        p.size = p.startSize + (p.endSize - p.startSize) * t;
      }

      if (p.life <= 0 || p.size <= 0) {
        state.particles.splice(i, 1);
      }
    }
  }

  private drawStar(c: CanvasRenderingContext2D, size: number): void {
    const spikes: number = 4;
    const outerR: number = size;
    const innerR: number = size * 0.4;
    c.beginPath();
    for (let i: number = 0; i < spikes * 2; i++) {
      const r: number = i % 2 === 0 ? outerR : innerR;
      const angle: number = (i * Math.PI) / spikes - Math.PI / 2;
      const px: number = Math.cos(angle) * r;
      const py: number = Math.sin(angle) * r;
      if (i === 0) c.moveTo(px, py);
      else c.lineTo(px, py);
    }
    c.closePath();
    c.fill();
  }
}
