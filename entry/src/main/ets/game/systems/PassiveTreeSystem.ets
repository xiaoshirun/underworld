import { System, SystemContext, Entity } from '@qiuyu/engine';
import { SkillComponent } from '../components/SkillComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import {
  EVOLUTION_COST_ORE, EVOLUTION_COST_NORMAL, EVOLUTION_COST_RARE,
  EvolutionBranch, MaterialType, PassiveSlot,
} from '../GameConstants';

export class PassiveTreeSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    // No per-frame logic — passive upgrades are player-initiated
  }

  static getOreTypeForBranch(branch: number): number {
    switch (branch) {
      case EvolutionBranch.CRYSTAL: return MaterialType.CRYSTAL_ORE;
      case EvolutionBranch.FLAME: return MaterialType.FLAME_ORE;
      case EvolutionBranch.SHADOW: return MaterialType.VOID_ORE;
      case EvolutionBranch.TOXIN: return MaterialType.MUSHROOM_ORE;
      case EvolutionBranch.TIDE: return MaterialType.ABYSS_ORE;
      default: return MaterialType.CRYSTAL_ORE;
    }
  }

  static getOreCost(targetLevel: number): number {
    if (targetLevel < 0 || targetLevel >= EVOLUTION_COST_ORE.length) return 999;
    return EVOLUTION_COST_ORE[targetLevel];
  }

  static getNormalCost(targetLevel: number): number {
    if (targetLevel < 0 || targetLevel >= EVOLUTION_COST_NORMAL.length) return 999;
    return EVOLUTION_COST_NORMAL[targetLevel];
  }

  static getRareCost(targetLevel: number): number {
    if (targetLevel < 0 || targetLevel >= EVOLUTION_COST_RARE.length) return 999;
    return EVOLUTION_COST_RARE[targetLevel];
  }

  static canUpgrade(skillComp: SkillComponent, inventory: InventoryComponent, branch: number): boolean {
    // Find existing passive for this branch
    let currentLevel: number = 0;
    for (let i: number = 0; i < skillComp.passiveSkills.length; i++) {
      if (skillComp.passiveSkills[i].branch === branch) {
        currentLevel = skillComp.passiveSkills[i].level;
        break;
      }
    }

    const targetLevel: number = currentLevel + 1;
    if (targetLevel > 3) return false; // Max level

    const oreType: number = PassiveTreeSystem.getOreTypeForBranch(branch);
    const oreCost: number = PassiveTreeSystem.getOreCost(targetLevel);
    const normalCost: number = PassiveTreeSystem.getNormalCost(targetLevel);
    const rareCost: number = PassiveTreeSystem.getRareCost(targetLevel);

    const oreHave: number = PassiveTreeSystem.getOreAmount(inventory, oreType);
    if (oreHave < oreCost) return false;
    if (inventory.coreNormal < normalCost) return false;
    if (inventory.coreRare < rareCost) return false;

    return true;
  }

  static tryUpgrade(skillComp: SkillComponent, inventory: InventoryComponent, branch: number): boolean {
    if (!PassiveTreeSystem.canUpgrade(skillComp, inventory, branch)) return false;

    let existingSlot: PassiveSlot | null = null;
    for (let i: number = 0; i < skillComp.passiveSkills.length; i++) {
      if (skillComp.passiveSkills[i].branch === branch) {
        existingSlot = skillComp.passiveSkills[i];
        break;
      }
    }

    const currentLevel: number = existingSlot !== null ? existingSlot.level : 0;
    const targetLevel: number = currentLevel + 1;

    // Deduct materials
    const oreType: number = PassiveTreeSystem.getOreTypeForBranch(branch);
    const oreCost: number = PassiveTreeSystem.getOreCost(targetLevel);
    const normalCost: number = PassiveTreeSystem.getNormalCost(targetLevel);
    const rareCost: number = PassiveTreeSystem.getRareCost(targetLevel);

    PassiveTreeSystem.deductOre(inventory, oreType, oreCost);
    inventory.coreNormal -= normalCost;
    inventory.coreRare -= rareCost;

    if (existingSlot !== null) {
      existingSlot.level = targetLevel;
    } else {
      if (skillComp.passiveSkills.length < skillComp.passiveSlotCount) {
        const slot: PassiveSlot = { branch: branch, level: 1 };
        skillComp.passiveSkills.push(slot);
      } else {
        return false; // No passive slot available
      }
    }

    return true;
  }

  private static getOreAmount(inventory: InventoryComponent, oreType: number): number {
    switch (oreType) {
      case MaterialType.CRYSTAL_ORE: return inventory.crystalOre;
      case MaterialType.MUSHROOM_ORE: return inventory.mushroomOre;
      case MaterialType.FLAME_ORE: return inventory.flameOre;
      case MaterialType.ABYSS_ORE: return inventory.abyssOre;
      case MaterialType.VOID_ORE: return inventory.voidOre;
      default: return 0;
    }
  }

  private static deductOre(inventory: InventoryComponent, oreType: number, amount: number): void {
    switch (oreType) {
      case MaterialType.CRYSTAL_ORE: inventory.crystalOre -= amount; break;
      case MaterialType.MUSHROOM_ORE: inventory.mushroomOre -= amount; break;
      case MaterialType.FLAME_ORE: inventory.flameOre -= amount; break;
      case MaterialType.ABYSS_ORE: inventory.abyssOre -= amount; break;
      case MaterialType.VOID_ORE: inventory.voidOre -= amount; break;
    }
  }
}
