import { System, SystemContext, Entity } from '@qiuyu/engine';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import {
  EVOLUTION_COST_ORE, EVOLUTION_COST_NORMAL, EVOLUTION_COST_RARE, FORM_UNLOCK_COST,
  EvolutionBranch, EvolutionLevel, WeaponForm, MaterialType,
} from '../GameConstants';

export class EvolutionSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    // Utility/query system — no per-frame logic needed
  }

  canEvolve(player: Entity): boolean {
    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    const inv: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (evo === null || inv === null) return false;

    const level: number = evo.evolutionLevel;
    if (level >= (EvolutionLevel.LEVEL_3 as number)) return false;

    const nextLevel: number = level + 1;
    const branch: EvolutionBranch = evo.evolutionBranch as EvolutionBranch;
    const oreNeeded: number = EVOLUTION_COST_ORE[nextLevel];
    const normalNeeded: number = EVOLUTION_COST_NORMAL[nextLevel];
    const rareNeeded: number = EVOLUTION_COST_RARE[nextLevel];

    if (this.getOreCount(inv, branch) < oreNeeded) return false;
    if (inv.coreNormal < normalNeeded) return false;
    if (inv.coreRare < rareNeeded) return false;
    return true;
  }

  tryEvolveWeapon(player: Entity): boolean {
    if (!this.canEvolve(player)) return false;

    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    const inv: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (evo === null || inv === null) return false;

    const nextLevel: number = evo.evolutionLevel + 1;
    const branch: EvolutionBranch = evo.evolutionBranch as EvolutionBranch;
    const oreNeeded: number = EVOLUTION_COST_ORE[nextLevel];
    const normalNeeded: number = EVOLUTION_COST_NORMAL[nextLevel];
    const rareNeeded: number = EVOLUTION_COST_RARE[nextLevel];

    this.deductOre(inv, branch, oreNeeded);
    inv.coreNormal -= normalNeeded;
    inv.coreRare -= rareNeeded;
    evo.evolutionLevel = nextLevel;

    return true;
  }

  unlockWeaponForm(player: Entity, form: WeaponForm): boolean {
    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    const inv: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (evo === null || inv === null) return false;

    const formNum: number = form as number;
    if (evo.unlockedForms.indexOf(formNum) >= 0) return false;
    if (inv.formCore < FORM_UNLOCK_COST) return false;

    inv.formCore -= FORM_UNLOCK_COST;
    evo.unlockedForms.push(formNum);
    return true;
  }

  getEvolutionInfo(player: Entity): string[] {
    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    const inv: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (evo === null || inv === null) return ['No player'];

    const branchNames: string[] = ['Crystal', 'Flame', 'Shadow', 'Toxin', 'Tide'];
    const branch: string = branchNames[evo.evolutionBranch] || 'Unknown';
    const level: number = evo.evolutionLevel;
    const info: string[] = [];

    info.push('Branch: ' + branch);
    info.push('Level: ' + level + '/3');

    if (level < 3) {
      const next: number = level + 1;
      const oreNeeded: number = EVOLUTION_COST_ORE[next];
      const normalNeeded: number = EVOLUTION_COST_NORMAL[next];
      const rareNeeded: number = EVOLUTION_COST_RARE[next];
      const oreHave: number = this.getOreCount(inv, evo.evolutionBranch as EvolutionBranch);
      info.push('Ore: ' + oreHave + '/' + oreNeeded);
      info.push('Core: ' + inv.coreNormal + '/' + normalNeeded);
      info.push('Rare: ' + inv.coreRare + '/' + rareNeeded);
    } else {
      info.push('MAX LEVEL');
    }

    return info;
  }

  getEvoBranch(player: Entity): number {
    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    if (evo === null) return 0;
    return evo.evolutionBranch;
  }

  getEvoLevel(player: Entity): number {
    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    if (evo === null) return 0;
    return evo.evolutionLevel;
  }

  getEvoOreHave(player: Entity): number {
    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    const inv: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (evo === null || inv === null) return 0;
    return this.getOreCount(inv, evo.evolutionBranch as EvolutionBranch);
  }

  getEvoOreHaveForBranch(player: Entity, branch: number): number {
    const inv: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (inv === null) return 0;
    return this.getOreCount(inv, branch as EvolutionBranch);
  }

  private getBranchOreType(branch: EvolutionBranch): MaterialType {
    if (branch === EvolutionBranch.CRYSTAL) return MaterialType.CRYSTAL_ORE;
    if (branch === EvolutionBranch.FLAME) return MaterialType.FLAME_ORE;
    if (branch === EvolutionBranch.SHADOW) return MaterialType.VOID_ORE;
    if (branch === EvolutionBranch.TOXIN) return MaterialType.MUSHROOM_ORE;
    if (branch === EvolutionBranch.TIDE) return MaterialType.ABYSS_ORE;
    return MaterialType.CRYSTAL_ORE;
  }

  private getOreCount(inventory: InventoryComponent, branch: EvolutionBranch): number {
    const oreType: MaterialType = this.getBranchOreType(branch);
    if (oreType === MaterialType.CRYSTAL_ORE) return inventory.crystalOre;
    if (oreType === MaterialType.FLAME_ORE) return inventory.flameOre;
    if (oreType === MaterialType.VOID_ORE) return inventory.voidOre;
    if (oreType === MaterialType.MUSHROOM_ORE) return inventory.mushroomOre;
    if (oreType === MaterialType.ABYSS_ORE) return inventory.abyssOre;
    return 0;
  }

  private deductOre(inventory: InventoryComponent, branch: EvolutionBranch, count: number): void {
    const oreType: MaterialType = this.getBranchOreType(branch);
    if (oreType === MaterialType.CRYSTAL_ORE) inventory.crystalOre -= count;
    else if (oreType === MaterialType.FLAME_ORE) inventory.flameOre -= count;
    else if (oreType === MaterialType.VOID_ORE) inventory.voidOre -= count;
    else if (oreType === MaterialType.MUSHROOM_ORE) inventory.mushroomOre -= count;
    else if (oreType === MaterialType.ABYSS_ORE) inventory.abyssOre -= count;
  }

  private getBranchColor(branch: EvolutionBranch): string {
    if (branch === EvolutionBranch.CRYSTAL) return '#00ced1';
    if (branch === EvolutionBranch.FLAME) return '#ff4500';
    if (branch === EvolutionBranch.SHADOW) return '#6b21a8';
    if (branch === EvolutionBranch.TOXIN) return '#32cd32';
    if (branch === EvolutionBranch.TIDE) return '#4169e1';
    return '#ffffff';
  }
}
