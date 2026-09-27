export interface ParticleData {
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
  shape: ParticleShape;
  shrink: boolean;
  fadeOut: boolean;
}

export enum ParticleShape {
  CIRCLE = 0,
  SQUARE = 1,
  DIAMOND = 2,
  STAR = 3,
  RING = 4
}

export interface EmitterConfig {
  x: number;
  y: number;
  count: number;
  speedMin: number;
  speedMax: number;
  angleMin: number;
  angleMax: number;
  lifeMin: number;
  lifeMax: number;
  sizeMin: number;
  sizeMax: number;
  endSizeMin: number;
  endSizeMax: number;
  colors: string[];
  endColors: string[];
  gravity: number;
  friction: number;
  shape: ParticleShape;
  shrink: boolean;
  fadeOut: boolean;
  spreadX: number;
  spreadY: number;
}

export enum EmitterMode {
  BURST = 0,
  CONTINUOUS = 1,
  TRAIL = 2
}

export class ParticleEmitter {
  particles: ParticleData[] = [];
  config: EmitterConfig;
  mode: EmitterMode;
  active: boolean = true;
  private emitTimer: number = 0;
  private emitInterval: number = 50;
  private lifetime: number = -1;
  private age: number = 0;
  private followX: number = 0;
  private followY: number = 0;
  private following: boolean = false;

  constructor(config: EmitterConfig, mode: EmitterMode) {
    this.config = config;
    this.mode = mode;
    if (mode === EmitterMode.BURST) {
      this.emitBurst();
      this.active = false;
    }
  }

  setFollowPosition(x: number, y: number): void {
    this.followX = x;
    this.followY = y;
    this.following = true;
  }

  stopFollow(): void {
    this.following = false;
  }

  setLifetime(ms: number): void {
    this.lifetime = ms;
  }

  setEmitInterval(ms: number): void {
    this.emitInterval = ms;
  }

  private emitBurst(): void {
    for (let i: number = 0; i < this.config.count; i++) {
      this.spawnOne();
    }
  }

  private spawnOne(): void {
    const cfg: EmitterConfig = this.config;
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

    this.particles.push({
      x: cfg.x + ox,
      y: cfg.y + oy,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      life: life,
      maxLife: life,
      size: size,
      startSize: size,
      endSize: endSize,
      color: color,
      endColor: endColor,
      alpha: 1.0,
      startAlpha: 1.0,
      endAlpha: cfg.fadeOut ? 0.0 : 1.0,
      gravity: cfg.gravity,
      friction: cfg.friction,
      rotation: Math.random() * Math.PI * 2,
      rotationSpeed: (Math.random() - 0.5) * 0.2,
      shape: cfg.shape,
      shrink: cfg.shrink,
      fadeOut: cfg.fadeOut
    });
  }

  update(dt: number): void {
    if (this.following) {
      this.config.x = this.followX;
      this.config.y = this.followY;
    }

    if (this.active && this.mode !== EmitterMode.BURST) {
      this.emitTimer += dt;
      if (this.emitTimer >= this.emitInterval) {
        this.emitTimer = 0;
        const spawnCount: number = this.mode === EmitterMode.TRAIL ? 1 : Math.max(1, Math.floor(this.config.count / 4));
        for (let i: number = 0; i < spawnCount; i++) {
          this.spawnOne();
        }
      }
    }

    if (this.lifetime > 0) {
      this.age += dt;
      if (this.age >= this.lifetime) {
        this.active = false;
      }
    }

    for (let i: number = this.particles.length - 1; i >= 0; i--) {
      const p: ParticleData = this.particles[i];
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
        this.particles.splice(i, 1);
      }
    }
  }

  isDead(): boolean {
    return !this.active && this.particles.length === 0;
  }
}

export function createExplosionConfig(x: number, y: number, color: string, count: number): EmitterConfig {
  return {
    x: x, y: y,
    count: count,
    speedMin: 1.0, speedMax: 4.0,
    angleMin: 0, angleMax: Math.PI * 2,
    lifeMin: 200, lifeMax: 500,
    sizeMin: 2, sizeMax: 5,
    endSizeMin: 0, endSizeMax: 1,
    colors: [color],
    endColors: ['#000000'],
    gravity: 0.05,
    friction: 0.96,
    shape: ParticleShape.CIRCLE,
    shrink: true,
    fadeOut: true,
    spreadX: 4, spreadY: 4
  };
}

export function createSparkConfig(x: number, y: number, color: string, count: number): EmitterConfig {
  return {
    x: x, y: y,
    count: count,
    speedMin: 3.0, speedMax: 8.0,
    angleMin: 0, angleMax: Math.PI * 2,
    lifeMin: 100, lifeMax: 300,
    sizeMin: 1, sizeMax: 3,
    endSizeMin: 0, endSizeMax: 0,
    colors: [color, '#ffffff'],
    endColors: [],
    gravity: 0.15,
    friction: 0.92,
    shape: ParticleShape.DIAMOND,
    shrink: true,
    fadeOut: true,
    spreadX: 2, spreadY: 2
  };
}

export function createDustConfig(x: number, y: number): EmitterConfig {
  return {
    x: x, y: y,
    count: 6,
    speedMin: 0.3, speedMax: 1.2,
    angleMin: -Math.PI * 0.8, angleMax: -Math.PI * 0.2,
    lifeMin: 300, lifeMax: 600,
    sizeMin: 2, sizeMax: 4,
    endSizeMin: 0, endSizeMax: 1,
    colors: ['#a8a29e', '#78716c', '#d6d3d1'],
    endColors: [],
    gravity: -0.02,
    friction: 0.97,
    shape: ParticleShape.CIRCLE,
    shrink: true,
    fadeOut: true,
    spreadX: 8, spreadY: 2
  };
}

export function createTrailConfig(x: number, y: number, color: string): EmitterConfig {
  return {
    x: x, y: y,
    count: 2,
    speedMin: 0.1, speedMax: 0.5,
    angleMin: 0, angleMax: Math.PI * 2,
    lifeMin: 200, lifeMax: 400,
    sizeMin: 2, sizeMax: 4,
    endSizeMin: 0, endSizeMax: 1,
    colors: [color],
    endColors: [],
    gravity: 0,
    friction: 0.98,
    shape: ParticleShape.CIRCLE,
    shrink: true,
    fadeOut: true,
    spreadX: 4, spreadY: 4
  };
}

export function createBloodConfig(x: number, y: number, dirX: number, dirY: number): EmitterConfig {
  const angle: number = Math.atan2(dirY, dirX);
  return {
    x: x, y: y,
    count: 8,
    speedMin: 2.0, speedMax: 5.0,
    angleMin: angle - 0.5, angleMax: angle + 0.5,
    lifeMin: 200, lifeMax: 500,
    sizeMin: 2, sizeMax: 4,
    endSizeMin: 1, endSizeMax: 2,
    colors: ['#ef4444', '#dc2626', '#b91c1c'],
    endColors: ['#7f1d1d'],
    gravity: 0.2,
    friction: 0.94,
    shape: ParticleShape.CIRCLE,
    shrink: true,
    fadeOut: true,
    spreadX: 2, spreadY: 2
  };
}

export function createMagicConfig(x: number, y: number, color: string): EmitterConfig {
  return {
    x: x, y: y,
    count: 12,
    speedMin: 0.5, speedMax: 2.0,
    angleMin: 0, angleMax: Math.PI * 2,
    lifeMin: 400, lifeMax: 800,
    sizeMin: 2, sizeMax: 5,
    endSizeMin: 0, endSizeMax: 2,
    colors: [color, '#ffffff'],
    endColors: [],
    gravity: -0.05,
    friction: 0.97,
    shape: ParticleShape.STAR,
    shrink: true,
    fadeOut: true,
    spreadX: 10, spreadY: 10
  };
}

export function createSmokeConfig(x: number, y: number): EmitterConfig {
  return {
    x: x, y: y,
    count: 4,
    speedMin: 0.2, speedMax: 0.8,
    angleMin: -Math.PI * 0.8, angleMax: -Math.PI * 0.2,
    lifeMin: 500, lifeMax: 1000,
    sizeMin: 4, sizeMax: 8,
    endSizeMin: 8, endSizeMax: 14,
    colors: ['#374151', '#4b5563', '#6b7280'],
    endColors: ['#1f2937'],
    gravity: -0.03,
    friction: 0.99,
    shape: ParticleShape.CIRCLE,
    shrink: false,
    fadeOut: true,
    spreadX: 6, spreadY: 2
  };
}

export class ParticleManager {
  emitters: ParticleEmitter[] = [];
  private maxParticles: number = 500;

  setMaxParticles(max: number): void {
    this.maxParticles = max;
  }

  addEmitter(emitter: ParticleEmitter): ParticleEmitter {
    this.emitters.push(emitter);
    return emitter;
  }

  burst(config: EmitterConfig): ParticleEmitter {
    const emitter: ParticleEmitter = new ParticleEmitter(config, EmitterMode.BURST);
    this.emitters.push(emitter);
    return emitter;
  }

  continuous(config: EmitterConfig, intervalMs: number, lifetimeMs: number): ParticleEmitter {
    const emitter: ParticleEmitter = new ParticleEmitter(config, EmitterMode.CONTINUOUS);
    emitter.setEmitInterval(intervalMs);
    if (lifetimeMs > 0) emitter.setLifetime(lifetimeMs);
    this.emitters.push(emitter);
    return emitter;
  }

  trail(config: EmitterConfig, lifetimeMs: number): ParticleEmitter {
    const emitter: ParticleEmitter = new ParticleEmitter(config, EmitterMode.TRAIL);
    emitter.setEmitInterval(30);
    if (lifetimeMs > 0) emitter.setLifetime(lifetimeMs);
    this.emitters.push(emitter);
    return emitter;
  }

  explosion(x: number, y: number, color: string, count: number): void {
    this.burst(createExplosionConfig(x, y, color, count));
  }

  sparks(x: number, y: number, color: string, count: number): void {
    this.burst(createSparkConfig(x, y, color, count));
  }

  dust(x: number, y: number): void {
    this.burst(createDustConfig(x, y));
  }

  blood(x: number, y: number, dirX: number, dirY: number): void {
    this.burst(createBloodConfig(x, y, dirX, dirY));
  }

  magic(x: number, y: number, color: string): void {
    this.burst(createMagicConfig(x, y, color));
  }

  smoke(x: number, y: number): void {
    this.burst(createSmokeConfig(x, y));
  }

  update(dt: number): void {
    for (let i: number = this.emitters.length - 1; i >= 0; i--) {
      const em: ParticleEmitter = this.emitters[i];
      em.update(dt);
      if (em.isDead()) {
        this.emitters.splice(i, 1);
      }
    }
  }

  getTotalCount(): number {
    let total: number = 0;
    for (let i: number = 0; i < this.emitters.length; i++) {
      total += this.emitters[i].particles.length;
    }
    return total;
  }

  render(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.emitters.length; i++) {
      const em: ParticleEmitter = this.emitters[i];
      for (let j: number = 0; j < em.particles.length; j++) {
        const p: ParticleData = em.particles[j];
        const sx: number = p.x + offX;
        const sy: number = p.y + offY;

        c.globalAlpha = Math.max(0, Math.min(1, p.alpha));
        c.fillStyle = p.color;

        switch (p.shape) {
          case ParticleShape.CIRCLE:
            c.beginPath();
            c.arc(sx, sy, Math.max(0.5, p.size), 0, Math.PI * 2);
            c.fill();
            break;
          case ParticleShape.SQUARE:
            c.fillRect(sx - p.size, sy - p.size, p.size * 2, p.size * 2);
            break;
          case ParticleShape.DIAMOND:
            c.save();
            c.translate(sx, sy);
            c.rotate(p.rotation);
            c.beginPath();
            c.moveTo(0, -p.size);
            c.lineTo(p.size, 0);
            c.lineTo(0, p.size);
            c.lineTo(-p.size, 0);
            c.closePath();
            c.fill();
            c.restore();
            break;
          case ParticleShape.STAR:
            c.save();
            c.translate(sx, sy);
            c.rotate(p.rotation);
            this.drawStar(c, p.size);
            c.restore();
            break;
          case ParticleShape.RING:
            c.beginPath();
            c.arc(sx, sy, Math.max(0.5, p.size), 0, Math.PI * 2);
            c.lineWidth = 1;
            c.strokeStyle = p.color;
            c.stroke();
            break;
        }
      }
    }
    c.globalAlpha = 1.0;
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
      if (i === 0) {
        c.moveTo(px, py);
      } else {
        c.lineTo(px, py);
      }
    }
    c.closePath();
    c.fill();
  }

  clear(): void {
    this.emitters = [];
  }
}
