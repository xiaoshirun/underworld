import { Component } from '@qiuyu/engine';

export class XpPickupComponent implements Component {
  xpValue: number = 1;
  magnetPhase: number = 0;

  getType(): string { return "xpPickup"; }
}
