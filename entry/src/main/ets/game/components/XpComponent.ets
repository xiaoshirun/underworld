import { Component, Serializable } from '@qiuyu/engine';

export class XpComponent implements Component, Serializable {
  xp: number = 0;
  level: number = 1;

  getType(): string { return "xp"; }

  serialize(): Record<string, Object> {
    return { xp: this.xp, level: this.level };
  }

  deserialize(data: Record<string, Object>): void {
    this.xp = data["xp"] as number;
    this.level = data["level"] as number;
  }
}
