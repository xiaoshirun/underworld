import { Component, Serializable } from '@qiuyu/engine';

export class EvolutionComponent implements Component, Serializable {
  evolutionLevel: number = 0;
  unlockedForms: number[] = [0];
  evolutionBranch: number = 0;

  getType(): string { return "evolution"; }

  serialize(): Record<string, Object> {
    return {
      evolutionLevel: this.evolutionLevel,
      unlockedForms: this.unlockedForms as Object[],
      evolutionBranch: this.evolutionBranch
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.evolutionLevel = data["evolutionLevel"] as number;
    this.unlockedForms = data["unlockedForms"] as number[];
    this.evolutionBranch = data["evolutionBranch"] as number;
  }
}
