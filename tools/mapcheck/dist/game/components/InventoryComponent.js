"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InventoryComponent = void 0;
class InventoryComponent {
    constructor() {
        this.crystalOre = 0;
        this.mushroomOre = 0;
        this.flameOre = 0;
        this.abyssOre = 0;
        this.voidOre = 0;
        this.coreNormal = 0;
        this.coreRare = 0;
        this.formCore = 0;
        this.hpPotions = 0;
        this.gold = 0;
        this.transformCoreSlime = 0;
        this.transformCoreArmor = 0;
        this.transformCoreIronMan = 0;
        this.transformCoreGhost = 0;
        this.maskFragments = 0;
        this.hasHumanMask = false;
    }
    getType() { return "inventory"; }
    serialize() {
        const result = {};
        result["crystalOre"] = this.crystalOre;
        result["mushroomOre"] = this.mushroomOre;
        result["flameOre"] = this.flameOre;
        result["abyssOre"] = this.abyssOre;
        result["voidOre"] = this.voidOre;
        result["coreNormal"] = this.coreNormal;
        result["coreRare"] = this.coreRare;
        result["formCore"] = this.formCore;
        result["hpPotions"] = this.hpPotions;
        result["gold"] = this.gold;
        result["transformCoreSlime"] = this.transformCoreSlime;
        result["transformCoreArmor"] = this.transformCoreArmor;
        result["transformCoreIronMan"] = this.transformCoreIronMan;
        result["transformCoreGhost"] = this.transformCoreGhost;
        result["maskFragments"] = this.maskFragments;
        result["hasHumanMask"] = this.hasHumanMask;
        return result;
    }
    deserialize(data) {
        this.crystalOre = data["crystalOre"];
        this.mushroomOre = data["mushroomOre"];
        this.flameOre = data["flameOre"];
        this.abyssOre = data["abyssOre"];
        this.voidOre = data["voidOre"];
        this.coreNormal = data["coreNormal"];
        this.coreRare = data["coreRare"];
        this.formCore = data["formCore"];
        this.hpPotions = data["hpPotions"];
        this.gold = data["gold"];
        this.transformCoreSlime = data["transformCoreSlime"];
        this.transformCoreArmor = data["transformCoreArmor"];
        this.transformCoreIronMan = data["transformCoreIronMan"];
        this.transformCoreGhost = data["transformCoreGhost"];
        this.maskFragments = data["maskFragments"] || 0;
        this.hasHumanMask = data["hasHumanMask"] || false;
    }
}
exports.InventoryComponent = InventoryComponent;
