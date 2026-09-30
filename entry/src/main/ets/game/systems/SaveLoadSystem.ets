import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { XpComponent } from '../components/XpComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { LevelComponent } from '../components/LevelComponent';
import { SkillComponent } from '../components/SkillComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { SAVE_VERSION, AUTO_SAVE_INTERVAL, TILE_SIZE, SaveData, Inventory, SkillSlot, PassiveSlot } from '../GameConstants';
import { SaveManager } from '../SaveManager';
import { common } from '@kit.AbilityKit';

export class SaveLoadSystem extends System {
  private saveTimer: number = 0;
  harmonyContext: Object | null = null;

  update(entities: Entity[], context: SystemContext): void {
    this.saveTimer += context.dt;
    if (this.saveTimer >= AUTO_SAVE_INTERVAL) {
      this.saveTimer = 0;
      this.autoSave(context);
    }
  }

  getSaveData(player: Entity, context: SystemContext): SaveData {
    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const health: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const transform: TransformComponent = player.getComponent<TransformComponent>("transform")!;
    const inventory: InventoryComponent = player.getComponent<InventoryComponent>("inventory")!;
    const xp: XpComponent = player.getComponent<XpComponent>("xp")!;
    const evo: EvolutionComponent = player.getComponent<EvolutionComponent>("evolution")!;
    const level: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");

    const inv: Inventory = {
      crystalOre: inventory.crystalOre,
      mushroomOre: inventory.mushroomOre,
      flameOre: inventory.flameOre,
      abyssOre: inventory.abyssOre,
      voidOre: inventory.voidOre,
      coreNormal: inventory.coreNormal,
      coreRare: inventory.coreRare,
      formCore: inventory.formCore,
      hpPotions: inventory.hpPotions,
      gold: inventory.gold,
      transformCoreSlime: inventory.transformCoreSlime,
      transformCoreArmor: inventory.transformCoreArmor,
      transformCoreIronMan: inventory.transformCoreIronMan,
      transformCoreGhost: inventory.transformCoreGhost,
      maskFragments: inventory.maskFragments,
      hasHumanMask: inventory.hasHumanMask
    };

    const exploredChunks: string[] = [];
    context.world.chunks.forEach((_: Object, key: string) => {
      exploredChunks.push(key);
    });

    const saveData: SaveData = {
      version: SAVE_VERSION,
      timestamp: Date.now(),
      playerX: pos.x,
      playerY: pos.y,
      hp: health.current,
      xp: level !== null ? level.xp : xp.xp,
      level: level !== null ? level.level : xp.level,
      currentWeaponForm: transform.currentWeaponForm,
      unlockedForms: evo.unlockedForms.slice(),
      evolutionBranch: evo.evolutionBranch,
      evolutionLevel: evo.evolutionLevel,
      inventory: inv,
      isTransformed: transform.isTransformed,
      transformForm: transform.transformForm,
      transformEnergy: humanForm !== null ? humanForm.formEnergy : transform.transformEnergy,
      transformMaxEnergy: humanForm !== null ? humanForm.formMaxEnergy : transform.transformMaxEnergy,
      unlockedTransforms: [],
      exploredChunks: exploredChunks,
      skills: skill !== null ? skill.activeSkills : [],
      passives: skill !== null ? skill.passiveSkills : [],
      activeSlotCount: skill !== null ? skill.activeSlotCount : 1,
      passiveSlotCount: skill !== null ? skill.passiveSlotCount : 1,
      selectedActiveIndex: skill !== null ? skill.selectedActiveIndex : 0,
      humanFormStage: humanForm !== null ? humanForm.humanFormStage : -1,
      hasHumanMask: humanForm !== null ? humanForm.hasMask : false,
      maskFragments: humanForm !== null ? humanForm.maskFragments : 0,
      humanFormEnergy: humanForm !== null ? humanForm.formEnergy : 0,
      unlockedHumanForms: humanForm !== null ? [humanForm.humanFormStage] : [],
    };
    return saveData;
  }

  applySaveData(player: Entity, data: SaveData, context: SystemContext): void {
    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const vel: VelocityComponent = player.getComponent<VelocityComponent>("Velocity")!;
    const health: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const movement: MovementComponent = player.getComponent<MovementComponent>("movement")!;
    const combat: CombatComponent = player.getComponent<CombatComponent>("combat")!;
    const transform: TransformComponent = player.getComponent<TransformComponent>("transform")!;
    const inventory: InventoryComponent = player.getComponent<InventoryComponent>("inventory")!;
    const xp: XpComponent = player.getComponent<XpComponent>("xp")!;
    const evo: EvolutionComponent = player.getComponent<EvolutionComponent>("evolution")!;
    const level: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");

    // Migration: old saves may not have new fields
    if (data.skills === undefined) data.skills = [];
    if (data.passives === undefined) data.passives = [];
    if (data.humanFormStage === undefined) data.humanFormStage = -1;
    if (data.hasHumanMask === undefined) data.hasHumanMask = false;
    if (data.maskFragments === undefined) data.maskFragments = 0;

    // Write persistent state to components
    pos.x = data.playerX;
    pos.y = data.playerY;
    health.current = data.hp;
    xp.xp = data.xp;
    xp.level = data.level;
    transform.currentWeaponForm = data.currentWeaponForm;
    evo.unlockedForms = data.unlockedForms.slice();
    evo.evolutionBranch = data.evolutionBranch;
    evo.evolutionLevel = data.evolutionLevel;

    // Restore new level component
    if (level !== null) {
      level.level = data.level;
      level.xp = data.xp;
    }

    // Restore new skill component
    if (skill !== null) {
      skill.activeSkills = data.skills;
      skill.passiveSkills = data.passives;
      skill.activeSlotCount = data.activeSlotCount || 1;
      skill.passiveSlotCount = data.passiveSlotCount || 1;
      skill.selectedActiveIndex = data.selectedActiveIndex || 0;
    }

    // Restore new human form component
    if (humanForm !== null) {
      humanForm.humanFormStage = data.humanFormStage;
      humanForm.hasMask = data.hasHumanMask;
      humanForm.maskFragments = data.maskFragments;
      humanForm.formEnergy = data.humanFormEnergy || 0;
    }

    inventory.crystalOre = data.inventory.crystalOre;
    inventory.mushroomOre = data.inventory.mushroomOre;
    inventory.flameOre = data.inventory.flameOre;
    inventory.abyssOre = data.inventory.abyssOre;
    inventory.voidOre = data.inventory.voidOre;
    inventory.coreNormal = data.inventory.coreNormal;
    inventory.coreRare = data.inventory.coreRare;
    inventory.formCore = data.inventory.formCore;
    inventory.hpPotions = data.inventory.hpPotions;
    inventory.gold = data.inventory.gold;
    inventory.transformCoreSlime = data.inventory.transformCoreSlime;
    inventory.transformCoreArmor = data.inventory.transformCoreArmor;
    inventory.transformCoreIronMan = data.inventory.transformCoreIronMan;
    inventory.transformCoreGhost = data.inventory.transformCoreGhost;
    inventory.maskFragments = data.inventory.maskFragments || 0;
    inventory.hasHumanMask = data.inventory.hasHumanMask || false;

    transform.isTransformed = data.isTransformed;
    transform.transformForm = data.transformForm;
    transform.transformEnergy = data.transformEnergy;
    transform.transformMaxEnergy = data.transformMaxEnergy;

    // Reset transient state
    vel.vx = 0;
    vel.vy = 0;
    combat.isAttacking = false;
    movement.isDashing = false;
    movement.isJumping = false;
    movement.isDrilling = false;
    movement.isEngulfed = false;
    combat.invincibleTimer = 1000;

    // Reset camera to player position
    context.world.cameraX = pos.x - context.screenW / 2;
    context.world.cameraY = pos.y - context.screenH / 2;

    // Clear chunks; ChunkLoadSystem will regenerate on next update
    context.world.chunks.clear();
  }

  private autoSave(context: SystemContext): void {
    if (this.harmonyContext === null) {
      return;
    }
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) {
      return;
    }
    const data: SaveData = this.getSaveData(player, context);
    SaveManager.save(this.harmonyContext as common.UIAbilityContext, data);
  }
}
