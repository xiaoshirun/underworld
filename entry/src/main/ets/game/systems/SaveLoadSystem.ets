import {
  TILE_SIZE, SAVE_VERSION,
  PlayerState, ChunkData, SaveData,
} from '../GameConstants';
import { GameContext } from '../GameContext';
import { SaveManager } from '../SaveManager';
import { common } from '@kit.AbilityKit';

export interface SaveLoadBridge {
  onSave: (() => void) | null;
}

export class SaveLoadSystem {
  private g: GameContext;
  private bridge: SaveLoadBridge;

  constructor(g: GameContext, bridge: SaveLoadBridge) {
    this.g = g;
    this.bridge = bridge;
  }

  getSaveData(): SaveData {
    const p: PlayerState = this.g.player!;
    return {
      version: SAVE_VERSION,
      timestamp: Date.now(),
      playerX: p.x,
      playerY: p.y,
      hp: p.hp,
      xp: p.xp,
      level: p.level,
      gender: p.gender,
      currentWeaponForm: p.currentWeaponForm,
      unlockedForms: p.unlockedForms.slice(),
      evolutionBranch: p.evolutionBranch,
      evolutionLevel: p.evolutionLevel,
      inventory: {
        crystalOre: p.inventory.crystalOre,
        mushroomOre: p.inventory.mushroomOre,
        flameOre: p.inventory.flameOre,
        abyssOre: p.inventory.abyssOre,
        voidOre: p.inventory.voidOre,
        coreNormal: p.inventory.coreNormal,
        coreRare: p.inventory.coreRare,
        formCore: p.inventory.formCore,
        hpPotions: p.inventory.hpPotions,
        gold: p.inventory.gold,
        transformCoreSlime: p.inventory.transformCoreSlime,
        transformCoreArmor: p.inventory.transformCoreArmor,
        transformCoreIronMan: p.inventory.transformCoreIronMan,
        transformCoreGhost: p.inventory.transformCoreGhost
      },
      isTransformed: p.isTransformed,
      transformForm: p.transformForm,
      transformEnergy: p.transformEnergy,
      transformMaxEnergy: p.transformMaxEnergy,
      unlockedTransforms: p.unlockedTransforms.slice(),
      exploredChunks: this.getExploredChunks()
    };
  }

  applySaveData(data: SaveData): void {
    if (!this.g.player) return;
    const p: PlayerState = this.g.player;
    p.x = data.playerX;
    p.y = data.playerY;
    p.hp = data.hp;
    p.xp = data.xp;
    p.level = data.level;
    p.gender = data.gender;
    p.currentWeaponForm = data.currentWeaponForm;
    p.unlockedForms = data.unlockedForms.slice();
    p.evolutionBranch = data.evolutionBranch;
    p.evolutionLevel = data.evolutionLevel;
    p.inventory = {
      crystalOre: data.inventory.crystalOre,
      mushroomOre: data.inventory.mushroomOre,
      flameOre: data.inventory.flameOre,
      abyssOre: data.inventory.abyssOre,
      voidOre: data.inventory.voidOre,
      coreNormal: data.inventory.coreNormal,
      coreRare: data.inventory.coreRare,
      formCore: data.inventory.formCore,
      hpPotions: data.inventory.hpPotions,
      gold: data.inventory.gold,
      transformCoreSlime: data.inventory.transformCoreSlime,
      transformCoreArmor: data.inventory.transformCoreArmor,
      transformCoreIronMan: data.inventory.transformCoreIronMan,
      transformCoreGhost: data.inventory.transformCoreGhost
    };
    p.isTransformed = data.isTransformed;
    p.transformForm = data.transformForm;
    p.transformEnergy = data.transformEnergy;
    p.transformMaxEnergy = data.transformMaxEnergy;
    p.unlockedTransforms = data.unlockedTransforms.slice();
    p.vx = 0;
    p.vy = 0;
    p.isAttacking = false;
    p.isDashing = false;
    p.isJumping = false;
    p.isDrilling = false;
    p.isEngulfed = false;
    p.invincibleTimer = 1000;

    this.g.cameraX = p.x - this.g.screenW / 2;
    this.g.cameraY = p.y - this.g.screenH / 2;

    this.g.chunks.clear();
    this.g.enemies = [];
    this.g.xpOrbs = [];
    this.g.bosses = [];
    this.g.chests = [];
    this.g.traps = [];
    this.g.mechanisms = [];
    this.g.materialDrops = [];
    this.g.bossRooms = [];
    this.g.secretRooms = [];
    this.g.transformCoreDrops = [];
    this.g.particles = [];
    this.g.particleMgr.clear();

    const ptx: number = Math.floor(p.x / TILE_SIZE);
    const pty: number = Math.floor(p.y / TILE_SIZE);
    this.g.loadChunksAround(ptx, pty);
  }

  getExploredChunks(): string[] {
    const keys: string[] = [];
    this.g.chunks.forEach((_: ChunkData, key: string) => {
      keys.push(key);
    });
    return keys;
  }

  async autoSave(): Promise<void> {
    if (!this.g.context || !this.g.player) return;
    try {
      const data: SaveData = this.getSaveData();
      await SaveManager.save(this.g.context as common.UIAbilityContext, data);
      if (this.bridge.onSave) {
        this.bridge.onSave();
      }
    } catch (e) {
      console.error('autoSave failed: ' + JSON.stringify(e));
    }
  }
}
