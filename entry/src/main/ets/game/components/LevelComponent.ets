import { Component, Serializable } from '@qiuyu/engine';

export class LevelComponent implements Component, Serializable {
  level: number = 1;
  xp: number = 0;

  getType(): string { return "level"; }

  getXpNeeded(): number {
    return 10 + (this.level - 1) * 5;
  }

  serialize(): Record<string, Object> {
    return { level: this.level, xp: this.xp };
  }

  deserialize(data: Record<string, Object>): void {
    this.level = data["level"] as number;
    this.xp = data["xp"] as number;
  }
}
