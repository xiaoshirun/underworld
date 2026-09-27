export interface ParticleEmitterComponent {
  emitRate: number;
  lifetime: number;
  elapsed: number;
  active: boolean;
  maxParticles: number;
  config: ParticleEmitterConfig;
}

export interface ParticleEmitterConfig {
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
  shape: number;
  shrink: boolean;
  fadeOut: boolean;
  spreadX: number;
  spreadY: number;
}

export function createParticleEmitter(config: ParticleEmitterConfig): ParticleEmitterComponent {
  return { emitRate: 50, lifetime: -1, elapsed: 0, active: true, maxParticles: 200, config: config };
}
