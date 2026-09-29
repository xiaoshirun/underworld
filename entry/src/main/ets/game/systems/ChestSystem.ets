import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { ChestComponent } from '../components/ChestComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import {
  TILE_SIZE, CHUNK_SIZE,
  CHEST_INTERACT_RANGE,
  ChestType, MaterialType, TileType,
  ChunkData,
} from '../GameConstants';

export class ChestSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const inventory: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (playerPos === null || inventory === null) return;

    const dt: number = context.dt;

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "chest") continue;

      const pos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const chest: ChestComponent | null = e.getComponent<ChestComponent>("chest");
      if (pos === null || chest === null) continue;

      // Update open animation
      if (chest.openAnim > 0) {
        chest.openAnim -= dt;
        if (chest.openAnim < 0) chest.openAnim = 0;
      }

      // Update loot text timer
      if (chest.lootTimer > 0) {
        chest.lootTimer -= dt;
        if (chest.lootTimer < 0) chest.lootTimer = 0;
      }

      // Skip already opened chests
      if (chest.opened) continue;

      // Check player distance for interaction
      const dx: number = pos.x - playerPos.x;
      const dy: number = pos.y - playerPos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < CHEST_INTERACT_RANGE) {
        // Elite chests require guardian defeat — check for active bosses
        if (chest.chestType === ChestType.ELITE) {
          let bossActive: boolean = false;
          for (let j: number = 0; j < entities.length; j++) {
            if (entities[j].active && entities[j].tag === "boss") {
              bossActive = true;
              break;
            }
          }
          if (bossActive) continue;
        }

        this.openChest(chest, pos, inventory, context);
      }
    }
  }

  private openChest(
    chest: ChestComponent,
    pos: PositionComponent,
    inventory: InventoryComponent,
    context: SystemContext
  ): void {
    chest.opened = true;
    chest.openAnim = 500;

    if (chest.chestType === ChestType.NORMAL) {
      const coreCount: number = 1 + Math.floor(Math.random() * 2);
      const potionCount: number = 1 + Math.floor(Math.random() * 2);
      const goldCount: number = 5 + Math.floor(Math.random() * 10);
      inventory.coreNormal += coreCount;
      inventory.hpPotions += potionCount;
      inventory.gold += goldCount;
      chest.lootText = '+' + coreCount + ' Core';
      chest.lootTimer = 2000;

    } else if (chest.chestType === ChestType.ELITE) {
      const potionCount: number = 2 + Math.floor(Math.random() * 2);
      inventory.coreRare += 1;
      inventory.formCore += 1;
      inventory.hpPotions += potionCount;
      inventory.gold += 20;
      chest.lootText = '+Rare Core +Form Core';
      chest.lootTimer = 2000;

    } else if (chest.chestType === ChestType.BOSS) {
      const oreCount: number = 2 + Math.floor(Math.random() * 2);
      const rareCount: number = 1 + Math.floor(Math.random() * 2);
      const oreType: number = this.getBiomeOreType(pos.x, pos.y, context);
      this.addOreToInventory(inventory, oreType, oreCount);
      inventory.coreRare += rareCount;
      if (Math.random() < 0.5) {
        inventory.formCore += 1;
      }
      inventory.gold += 50;
      chest.lootText = '+Boss Loot!';
      chest.lootTimer = 2000;
    }
  }

  private getBiomeOreType(worldX: number, worldY: number, context: SystemContext): number {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = cx + ',' + cy;
    const chunks: Map<string, Object> = context.world.chunks;
    const chunk: ChunkData | undefined = chunks.get(key) as ChunkData | undefined;
    if (chunk !== undefined) {
      // Determine biome from dominant tile type in chunk
      let crystalCount: number = 0;
      let mushroomCount: number = 0;
      let lavaCount: number = 0;
      let waterCount: number = 0;
      const sampleSize: number = Math.min(chunk.tiles.length, 8);
      for (let y: number = 0; y < sampleSize; y++) {
        for (let x: number = 0; x < sampleSize; x++) {
          const tile: number = chunk.tiles[y][x];
          if (tile === TileType.CRYSTAL) crystalCount++;
          else if (tile === TileType.MUSHROOM) mushroomCount++;
          else if (tile === TileType.LAVA) lavaCount++;
          else if (tile === TileType.WATER) waterCount++;
        }
      }
      if (crystalCount >= mushroomCount && crystalCount >= lavaCount && crystalCount >= waterCount) {
        return MaterialType.CRYSTAL_ORE;
      } else if (mushroomCount >= crystalCount && mushroomCount >= lavaCount && mushroomCount >= waterCount) {
        return MaterialType.MUSHROOM_ORE;
      } else if (lavaCount >= crystalCount && lavaCount >= mushroomCount && lavaCount >= waterCount) {
        return MaterialType.FLAME_ORE;
      } else if (waterCount >= crystalCount && waterCount >= mushroomCount && waterCount >= lavaCount) {
        return MaterialType.ABYSS_ORE;
      }
    }
    // Default fallback: use position hash to deterministically pick an ore type
    const hash: number = Math.abs(Math.floor(worldX * 7 + worldY * 13)) % 5;
    if (hash === 0) return MaterialType.CRYSTAL_ORE;
    if (hash === 1) return MaterialType.MUSHROOM_ORE;
    if (hash === 2) return MaterialType.FLAME_ORE;
    if (hash === 3) return MaterialType.ABYSS_ORE;
    return MaterialType.VOID_ORE;
  }

  private addOreToInventory(inventory: InventoryComponent, oreType: number, count: number): void {
    if (oreType === MaterialType.CRYSTAL_ORE) inventory.crystalOre += count;
    else if (oreType === MaterialType.MUSHROOM_ORE) inventory.mushroomOre += count;
    else if (oreType === MaterialType.FLAME_ORE) inventory.flameOre += count;
    else if (oreType === MaterialType.ABYSS_ORE) inventory.abyssOre += count;
    else if (oreType === MaterialType.VOID_ORE) inventory.voidOre += count;
    else inventory.crystalOre += count;
  }
}
