import { Component } from '@qiuyu/engine';

export class MechanismComponent implements Component {
  mechanismType: number = 0;
  active: boolean = false;
  linkedIndex: number = -1;
  rotation: number = 0;
  pushable: boolean = false;
  posX: number = 0;
  posY: number = 0;
  extraData: number[] = [];

  getType(): string { return "mechanism"; }
}
