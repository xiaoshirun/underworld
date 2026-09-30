import { Component } from '@qiuyu/engine';

export class MaterialPickupComponent implements Component {
  materialType: number = 0;
  amount: number = 1;
  bobPhase: number = 0;

  getType(): string { return "materialPickup"; }
}
