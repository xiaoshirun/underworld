import { Component } from '@qiuyu/engine';

export class GameStateComponent implements Component {
  state: number = 1;
  damageFlashTimer: number = 0;
  bossRoomLocked: boolean = false;
  transformUnlockNotifyTimer: number = 0;
  transformUnlockNotifyForm: number = 0;

  getType(): string { return "gameState"; }
}
