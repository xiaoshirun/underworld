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

  getType(): string { return "inventory"; }

  serialize(): Record<string, Object> {
    return {
      crystalOre: this.crystalOre, mushroomOre: this.mushroomOre,
      flameOre: this.flameOre, abyssOre: this.abyssOre,
      voidOre: this.voidOre, coreNormal: this.coreNormal,
      coreRare: this.coreRare, formCore: this.formCore,
      hpPotions: this.hpPotions, gold: this.gold,
      transformCoreSlime: this.transformCoreSlime,
      transformCoreArmor: this.transformCoreArmor,
      transformCoreIronMan: this.transformCoreIronMan,
      transformCoreGhost: this.transformCoreGhost
    };
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
  }
}
