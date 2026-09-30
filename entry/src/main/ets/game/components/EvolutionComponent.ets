import { Component, Serializable } from '@qiuyu/engine';

export class EvolutionComponent implements Component, Serializable {
  evolutionLevel: number = 0;
  unlockedForms: number[] = [0];
  evolutionBranch: number = 0;

  getType(): string { return "evolution"; }

  serialize(): Record<string, Object> {
    const result: Record<string, Object> = {} as Record<string, Object>;
    result["evolutionLevel"] = this.evolutionLevel as Object;
    result["unlockedForms"] = this.unlockedForms as Object;
    result["evolutionBranch"] = this.evolutionBranch as Object;
    return result;
  }

  deserialize(data: Record<string, Object>): void {
    this.evolutionLevel = data["evolutionLevel"] as number;
    this.unlockedForms = data["unlockedForms"] as number[];
    this.evolutionBranch = data["evolutionBranch"] as number;
  }
}
