import { Component } from '@qiuyu/engine';

export class BossAIComponent implements Component {
  bossType: number = 0;
  bossRole: number = 0;
  phase: number = 0;
  attackTimer: number = 0;
  specialTimer: number = 0;
  defeated: boolean = false;
  active: boolean = true;
  aggroRadius: number = 9999;
  extraData: number[] = [];

  getType(): string { return "bossAI"; }
}
