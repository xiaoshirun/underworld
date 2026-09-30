import { Component, Serializable } from '@qiuyu/engine';

export class XpComponent implements Component, Serializable {
  xp: number = 0;
  level: number = 1;

  getType(): string { return "xp"; }

  serialize(): Record<string, Object> {
    const result: Record<string, Object> = {} as Record<string, Object>;
    result["xp"] = this.xp as Object;
    result["level"] = this.level as Object;
    return result;
  }

  deserialize(data: Record<string, Object>): void {
    this.xp = data["xp"] as number;
    this.level = data["level"] as number;
  }
}
