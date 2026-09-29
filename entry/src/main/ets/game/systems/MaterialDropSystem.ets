import {
  MaterialType, PlayerState, MaterialDrop, TransformForm,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export class MaterialDropSystem {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  update(p: PlayerState): void {
    const collectRange: number = 30;
    for (let i: number = this.g.materialDrops.length - 1; i >= 0; i--) {
      const drop: MaterialDrop = this.g.materialDrops[i];
      if (!drop.active) continue;

      const dx: number = p.x - drop.x;
      const dy: number = p.y - drop.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < collectRange) {
        drop.active = false;
        if (drop.type === MaterialType.CRYSTAL_ORE) p.inventory.crystalOre += drop.count;
        else if (drop.type === MaterialType.MUSHROOM_ORE) p.inventory.mushroomOre += drop.count;
        else if (drop.type === MaterialType.FLAME_ORE) p.inventory.flameOre += drop.count;
        else if (drop.type === MaterialType.ABYSS_ORE) p.inventory.abyssOre += drop.count;
        else if (drop.type === MaterialType.VOID_ORE) p.inventory.voidOre += drop.count;
        else if (drop.type === MaterialType.CORE_NORMAL) p.inventory.coreNormal += drop.count;
        else if (drop.type === MaterialType.CORE_RARE) p.inventory.coreRare += drop.count;
        else if (drop.type === MaterialType.FORM_CORE) p.inventory.formCore += drop.count;

        for (let t: number = 0; t < this.g.transformCoreDrops.length; t++) {
          if (this.g.transformCoreDrops[t].dropIndex === i) {
            const form: TransformForm = this.g.transformCoreDrops[t].form;
            if (p.unlockedTransforms.indexOf(form) === -1) {
              p.unlockedTransforms.push(form);
              this.g.transformUnlockNotifyTimer = 3000;
              this.g.transformUnlockNotifyForm = form;
            }
            this.g.transformCoreDrops.splice(t, 1);
            break;
          }
        }

        this.g.audio.playXpCollect();
        if (this.g.settings.effectsEnabled) {
          this.g.particleMgr.sparks(drop.x, drop.y, '#ffd700', 6);
        }
      }
    }

    if (this.g.materialDrops.length > 50) {
      const active: MaterialDrop[] = [];
      const indexMap: Map<number, number> = new Map();
      for (let i: number = 0; i < this.g.materialDrops.length; i++) {
        if (this.g.materialDrops[i].active) {
          indexMap.set(i, active.length);
          active.push(this.g.materialDrops[i]);
        }
      }
      this.g.materialDrops = active;
      for (let t: number = this.g.transformCoreDrops.length - 1; t >= 0; t--) {
        const newIdx: number | undefined = indexMap.get(this.g.transformCoreDrops[t].dropIndex);
        if (newIdx !== undefined) {
          this.g.transformCoreDrops[t].dropIndex = newIdx;
        } else {
          this.g.transformCoreDrops.splice(t, 1);
        }
      }
    }
  }
}
