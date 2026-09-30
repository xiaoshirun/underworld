import { Component } from '@qiuyu/engine';

export class TransformCorePickupComponent implements Component {
  form: number = 0;
  rarity: number = 0;

  getType(): string { return "transformCorePickup"; }
}
