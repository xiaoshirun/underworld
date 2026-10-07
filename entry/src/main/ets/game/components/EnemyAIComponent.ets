import { Component } from '@qiuyu/engine';

export class EnemyAIComponent implements Component {
  enemyType: number = 0;
  bouncePhase: number = 0;
  hitFlash: number = 0;
  moveTimer: number = 0;
  targetX: number = 0;
  targetY: number = 0;
  isCharging: boolean = false;
  chargeTimer: number = 0;
  isEngulfing: boolean = false;
  engulfedPlayer: boolean = false;
  splitCount: number = 0;
  size: number = 12;
  level: number = 1;
  chargeDirX: number = 0;
  chargeDirY: number = 0;

  getType(): string { return "enemyAI"; }
}
