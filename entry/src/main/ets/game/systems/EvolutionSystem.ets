import {
  EVOLUTION_COST_ORE, EVOLUTION_COST_NORMAL, EVOLUTION_COST_RARE, FORM_UNLOCK_COST,
  EvolutionBranch, EvolutionLevel, WeaponForm, MaterialType, PlayerState, Inventory,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export class EvolutionSystem {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  canEvolve(): boolean {
    if (this.g.player === null) return false;
    const p: PlayerState = this.g.player;
    const level: number = p.evolutionLevel;
    if (level >= EvolutionLevel.LEVEL_3) return false;
    const nextLevel: number = level + 1;
    const branch: EvolutionBranch = p.evolutionBranch;
    const oreNeeded: number = EVOLUTION_COST_ORE[nextLevel];
    const normalNeeded: number = EVOLUTION_COST_NORMAL[nextLevel];
    const rareNeeded: number = EVOLUTION_COST_RARE[nextLevel];
    if (this.getOreCount(p.inventory, branch) < oreNeeded) return false;
    if (p.inventory.coreNormal < normalNeeded) return false;
    if (p.inventory.coreRare < rareNeeded) return false;
    return true;
  }

  tryEvolveWeapon(): boolean {
    if (!this.canEvolve()) return false;
    const p: PlayerState = this.g.player!;
    const nextLevel: number = p.evolutionLevel + 1;
    const branch: EvolutionBranch = p.evolutionBranch;
    const oreNeeded: number = EVOLUTION_COST_ORE[nextLevel];
    const normalNeeded: number = EVOLUTION_COST_NORMAL[nextLevel];
    const rareNeeded: number = EVOLUTION_COST_RARE[nextLevel];

    this.deductOre(p.inventory, branch, oreNeeded);
    p.inventory.coreNormal -= normalNeeded;
    p.inventory.coreRare -= rareNeeded;
    p.evolutionLevel = nextLevel as EvolutionLevel;

    if (this.g.settings.effectsEnabled) {
      this.g.particleMgr.explosion(p.x, p.y, this.getBranchColor(branch), 20);
      this.g.particleMgr.magic(p.x, p.y, '#ffffff');
    }
    this.g.shakeTimer = 300;
    return true;
  }

  unlockWeaponForm(form: WeaponForm): boolean {
    if (this.g.player === null) return false;
    const p: PlayerState = this.g.player;
    if (p.unlockedForms.indexOf(form) >= 0) return false;
    if (p.inventory.formCore < FORM_UNLOCK_COST) return false;
    p.inventory.formCore -= FORM_UNLOCK_COST;
    p.unlockedForms.push(form);
    return true;
  }

  getEvolutionInfo(): string[] {
    if (this.g.player === null) return ['No player'];
    const p: PlayerState = this.g.player;
    const branchNames: string[] = ['Crystal', 'Flame', 'Shadow', 'Toxin', 'Tide'];
    const branch: string = branchNames[p.evolutionBranch] || 'Unknown';
    const level: number = p.evolutionLevel;
    const info: string[] = [];
    info.push('Branch: ' + branch);
    info.push('Level: ' + level + '/3');
    if (level < 3) {
      const next: number = level + 1;
      const oreNeeded: number = EVOLUTION_COST_ORE[next];
      const normalNeeded: number = EVOLUTION_COST_NORMAL[next];
      const rareNeeded: number = EVOLUTION_COST_RARE[next];
      const oreHave: number = this.getOreCount(p.inventory, p.evolutionBranch);
      info.push('Ore: ' + oreHave + '/' + oreNeeded);
      info.push('Core: ' + p.inventory.coreNormal + '/' + normalNeeded);
      info.push('Rare: ' + p.inventory.coreRare + '/' + rareNeeded);
    } else {
      info.push('MAX LEVEL');
    }
    return info;
  }

  getEvoBranch(): number {
    if (this.g.player === null) return 0;
    return this.g.player.evolutionBranch as number;
  }

  getEvoLevel(): number {
    if (this.g.player === null) return 0;
    return this.g.player.evolutionLevel as number;
  }

  getEvoOreHave(): number {
    if (this.g.player === null) return 0;
    return this.getOreCount(this.g.player.inventory, this.g.player.evolutionBranch);
  }

  getEvoOreHaveForBranch(branch: number): number {
    if (this.g.player === null) return 0;
    return this.getOreCount(this.g.player.inventory, branch as EvolutionBranch);
  }

  private getBranchOreType(branch: EvolutionBranch): MaterialType {
    if (branch === EvolutionBranch.CRYSTAL) return MaterialType.CRYSTAL_ORE;
    if (branch === EvolutionBranch.FLAME) return MaterialType.FLAME_ORE;
    if (branch === EvolutionBranch.SHADOW) return MaterialType.VOID_ORE;
    if (branch === EvolutionBranch.TOXIN) return MaterialType.MUSHROOM_ORE;
    if (branch === EvolutionBranch.TIDE) return MaterialType.ABYSS_ORE;
    return MaterialType.CRYSTAL_ORE;
  }

  private getOreCount(inventory: Inventory, branch: EvolutionBranch): number {
    const oreType: MaterialType = this.getBranchOreType(branch);
    if (oreType === MaterialType.CRYSTAL_ORE) return inventory.crystalOre;
    if (oreType === MaterialType.FLAME_ORE) return inventory.flameOre;
    if (oreType === MaterialType.VOID_ORE) return inventory.voidOre;
    if (oreType === MaterialType.MUSHROOM_ORE) return inventory.mushroomOre;
    if (oreType === MaterialType.ABYSS_ORE) return inventory.abyssOre;
    return 0;
  }

  private deductOre(inventory: Inventory, branch: EvolutionBranch, count: number): void {
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
