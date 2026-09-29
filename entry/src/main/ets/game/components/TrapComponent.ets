import { Component } from '@qiuyu/engine';

export class TrapComponent implements Component {
  trapType: number = 0;
  state: number = 0;
  timer: number = 0;
  triggerRadius: number = 48;
  damage: number = 1;
  size: number = 16;
  extraData: number[] = [];

  getType(): string { return "trap"; }
}
