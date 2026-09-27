import {
  CHEST_SIZE, CHEST_INTERACT_RANGE,
  ChestState, ChestType, PlayerState, BiomeType,
  COLOR_CHEST_GLOW,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export interface ChestBridge {
  autoSave(): void;
}

export class ChestSystem {
  private g: GameContext;
  private bridge: ChestBridge;

  constructor(g: GameContext, bridge: ChestBridge) {
    this.g = g;
    this.bridge = bridge;
  }

  updateAnims(dt: number): void {
    for (let i: number = 0; i < this.g.chests.length; i++) {
      const chest: ChestState = this.g.chests[i];
      if (chest.openAnim > 0) {
        chest.openAnim -= dt;
        if (chest.openAnim < 0) chest.openAnim = 0;
      }
    }
  }

  checkInteraction(): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;

    for (let i: number = 0; i < this.g.chests.length; i++) {
      const chest: ChestState = this.g.chests[i];
      if (!chest.active || chest.opened) continue;

      const dx: number = chest.x - p.x;
      const dy: number = chest.y - p.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < CHEST_INTERACT_RANGE) {
        if (chest.chestType === ChestType.ELITE && !chest.guardianDefeated) continue;
        this.openChest(chest, p);
      }
    }
  }

  private openChest(chest: ChestState, p: PlayerState): void {
    chest.opened = true;
    chest.openAnim = 500;

    if (this.g.settings.effectsEnabled) {
      this.g.particleMgr.magic(chest.x, chest.y, COLOR_CHEST_GLOW);
    }

    if (chest.chestType === ChestType.NORMAL) {
      const coreCount: number = 1 + Math.floor(Math.random() * 2);
      const potionCount: number = 1 + Math.floor(Math.random() * 2);
      const goldCount: number = 5 + Math.floor(Math.random() * 10);
      p.inventory.coreNormal += coreCount;
      p.inventory.hpPotions += potionCount;
      p.inventory.gold += goldCount;
      this.spawnLootText(chest.x, chest.y, '+' + coreCount + ' Core');
    } else if (chest.chestType === ChestType.ELITE) {
      const potionCount: number = 2 + Math.floor(Math.random() * 2);
      p.inventory.coreRare += 1;
      p.inventory.formCore += 1;
      p.inventory.hpPotions += potionCount;
      p.inventory.gold += 20;
      this.spawnLootText(chest.x, chest.y, '+Rare Core +Form Core');
    } else if (chest.chestType === ChestType.BOSS) {
      const oreCount: number = 2 + Math.floor(Math.random() * 2);
      const rareCount: number = 1 + Math.floor(Math.random() * 2);
      this.addBossOre(p, oreCount);
      p.inventory.coreRare += rareCount;
      if (Math.random() < 0.5) {
        p.inventory.formCore += 1;
      }
      p.inventory.gold += 50;
      this.spawnLootText(chest.x, chest.y, '+Boss Loot!');
    }

    this.bridge.autoSave();
  }

  private addBossOre(p: PlayerState, count: number): void {
    const biome: BiomeType = this.g.worldGen.getBiome(p.x, p.y);
    if (biome === BiomeType.CRYSTAL) {
      p.inventory.crystalOre += count;
    } else if (biome === BiomeType.MUSHROOM) {
      p.inventory.mushroomOre += count;
    } else if (biome === BiomeType.LAVA) {
      p.inventory.flameOre += count;
    } else if (biome === BiomeType.WATER) {
      p.inventory.abyssOre += count;
    } else if (biome === BiomeType.SHADOW) {
      p.inventory.voidOre += count;
    } else {
      p.inventory.crystalOre += count;
    }
  }

  private spawnLootText(x: number, y: number, text: string): void {
    if (this.g.settings.effectsEnabled) {
      this.g.particleMgr.sparks(x, y - 10, '#ffd700', 5);
    }
  }
}
