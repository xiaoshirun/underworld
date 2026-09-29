import { Component } from '@qiuyu/engine';

export class GameStateComponent implements Component {
  state: number = 1;
  damageFlashTimer: number = 0;
  bossRoomLocked: boolean = false;

  getType(): string { return "gameState"; }
}
