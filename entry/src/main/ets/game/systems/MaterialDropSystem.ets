import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { MaterialPickupComponent } from '../components/MaterialPickupComponent';
import { TransformCorePickupComponent } from '../components/TransformCorePickupComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import { MaterialType, TransformForm } from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';

const PICKUP_RANGE: number = 30;

export class MaterialDropSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const inventory: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (playerPos === null || inventory === null) return;

    const audio: IAudioService = context.audio as IAudioService;

    // Material pickup pass
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "materialDrop") continue;

      const pos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const mat: MaterialPickupComponent | null = e.getComponent<MaterialPickupComponent>("materialPickup");
      if (pos === null || mat === null) continue;

      const dx: number = playerPos.x - pos.x;
      const dy: number = playerPos.y - pos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < PICKUP_RANGE) {
        this.addMaterialToInventory(inventory, mat.materialType, mat.amount);
        e.active = false;
        audio.playXpCollect();
      }
    }

    // Transform core pickup pass
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "transformCore") continue;

      const pos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const core: TransformCorePickupComponent | null = e.getComponent<TransformCorePickupComponent>("transformCorePickup");
      if (pos === null || core === null) continue;

      const dx: number = playerPos.x - pos.x;
      const dy: number = playerPos.y - pos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < PICKUP_RANGE) {
        // Add transform core to inventory
        this.addTransformCoreToInventory(inventory, core.form);

        // Write unlock notification state for UI
        const gsEntity: Entity | null = context.world.findEntityByTag("gameState");
        if (gsEntity !== null) {
          const gs: GameStateComponent | null = gsEntity.getComponent<GameStateComponent>("gameState");
          if (gs !== null) {
            gs.transformUnlockNotifyTimer = 3000;
            gs.transformUnlockNotifyForm = core.form;
          }
        }

        e.active = false;
        audio.playXpCollect();
      }
    }
  }

  private addMaterialToInventory(inventory: InventoryComponent, materialType: number, amount: number): void {
    switch (materialType) {
      case MaterialType.CRYSTAL_ORE:
        inventory.crystalOre += amount;
        break;
      case MaterialType.MUSHROOM_ORE:
        inventory.mushroomOre += amount;
        break;
      case MaterialType.FLAME_ORE:
        inventory.flameOre += amount;
        break;
      case MaterialType.ABYSS_ORE:
        inventory.abyssOre += amount;
        break;
      case MaterialType.VOID_ORE:
        inventory.voidOre += amount;
        break;
      case MaterialType.CORE_NORMAL:
        inventory.coreNormal += amount;
        break;
      case MaterialType.CORE_RARE:
        inventory.coreRare += amount;
        break;
      case MaterialType.FORM_CORE:
        inventory.formCore += amount;
        break;
    }
  }

  private addTransformCoreToInventory(inventory: InventoryComponent, form: number): void {
    if (form === TransformForm.SLIME) {
      inventory.transformCoreSlime += 1;
    } else if (form === TransformForm.GHOST) {
      inventory.transformCoreGhost += 1;
    } else if (form === TransformForm.ARMOR) {
      inventory.transformCoreArmor += 1;
    } else if (form === TransformForm.IRON_MAN) {
      inventory.transformCoreIronMan += 1;
    }
  }
}
