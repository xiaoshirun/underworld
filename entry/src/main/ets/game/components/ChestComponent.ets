import { Component } from '@qiuyu/engine';

export class ChestComponent implements Component {
  chestType: number = 0;
  opened: boolean = false;
  openAnim: number = 0;
  lootText: string = "";
  lootTimer: number = 0;

  getType(): string { return "chest"; }
}
