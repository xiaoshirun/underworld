import { Component } from '@qiuyu/engine';

export class ParticleComponent implements Component {
  life: number = 1000;
  maxLife: number = 1000;
  color: string = '#ffffff';
  size: number = 2;
  vx: number = 0;
  vy: number = 0;
  gravity: number = 0;
  fadeRate: number = 1;
  shape: number = 0;

  getType(): string { return "particle"; }
}
