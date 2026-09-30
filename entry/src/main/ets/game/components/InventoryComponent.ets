import { Component, Serializable } from '@qiuyu/engine';

export class InventoryComponent implements Component, Serializable {
  crystalOre: number = 0;
  mushroomOre: number = 0;
  flameOre: number = 0;
  abyssOre: number = 0;
  voidOre: number = 0;
  coreNormal: number = 0;
  coreRare: number = 0;
  formCore: number = 0;
  hpPotions: number = 0;
  gold: number = 0;
  transformCoreSlime: number = 0;
  transformCoreArmor: number = 0;
  transformCoreIronMan: number = 0;
  transformCoreGhost: number = 0;
  maskFragments: number = 0;
  hasHumanMask: boolean = false;

  getType(): string { return "inventory"; }

  serialize(): Record<string, Object> {
    const result: Record<string, Object> = {} as Record<string, Object>;
    result["crystalOre"] = this.crystalOre as Object;
    result["mushroomOre"] = this.mushroomOre as Object;
    result["flameOre"] = this.flameOre as Object;
    result["abyssOre"] = this.abyssOre as Object;
    result["voidOre"] = this.voidOre as Object;
    result["coreNormal"] = this.coreNormal as Object;
    result["coreRare"] = this.coreRare as Object;
    result["formCore"] = this.formCore as Object;
    result["hpPotions"] = this.hpPotions as Object;
    result["gold"] = this.gold as Object;
    result["transformCoreSlime"] = this.transformCoreSlime as Object;
    result["transformCoreArmor"] = this.transformCoreArmor as Object;
    result["transformCoreIronMan"] = this.transformCoreIronMan as Object;
    result["transformCoreGhost"] = this.transformCoreGhost as Object;
    result["maskFragments"] = this.maskFragments as Object;
    result["hasHumanMask"] = this.hasHumanMask as Object;
    return result;
  }

  deserialize(data: Record<string, Object>): void {
    this.crystalOre = data["crystalOre"] as number;
    this.mushroomOre = data["mushroomOre"] as number;
    this.flameOre = data["flameOre"] as number;
    this.abyssOre = data["abyssOre"] as number;
    this.voidOre = data["voidOre"] as number;
    this.coreNormal = data["coreNormal"] as number;
    this.coreRare = data["coreRare"] as number;
    this.formCore = data["formCore"] as number;
    this.hpPotions = data["hpPotions"] as number;
    this.gold = data["gold"] as number;
    this.transformCoreSlime = data["transformCoreSlime"] as number;
    this.transformCoreArmor = data["transformCoreArmor"] as number;
    this.transformCoreIronMan = data["transformCoreIronMan"] as number;
    this.transformCoreGhost = data["transformCoreGhost"] as number;
    this.maskFragments = (data["maskFragments"] as number) || 0;
    this.hasHumanMask = (data["hasHumanMask"] as boolean) || false;
  }
}
