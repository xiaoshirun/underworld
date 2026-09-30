# Slime Devour Gameplay Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the game from a humanoid warrior with weapons/transformation/evolution into a slime-based devour-and-evolve gameplay loop with numerical levels, skill families, and human form evolution.

**Architecture:** Add new ECS components (LevelComponent, SkillComponent, DevourComponent, HumanFormComponent) and systems (DevourSystem, SkillSystem, MonsterLevelSystem, HumanoidBeastSystem, HumanFormSystem, PassiveTreeSystem) alongside existing ones. Existing systems (PlayerCombatSystem, XpLevelSystem, TransformSystem, EvolutionSystem) are refactored incrementally. Old components (TransformComponent, EvolutionComponent) are deprecated but kept until replacements are fully wired.

**Tech Stack:** HarmonyOS ArkTS strict mode (.ets), ECS engine (@qiuyu/engine), Canvas2D procedural rendering, OffscreenCanvas sprite cache

**Spec:** `docs/superpowers/specs/2026-09-30-slime-devour-gameplay-design.md`

## Global Constraints

- All files are `.ets` (ArkTS strict mode) — every variable needs explicit type annotation
- Engine imports from `@qiuyu/engine`: `System`, `SystemContext`, `Entity`, `World`, `PositionComponent`, `VelocityComponent`, `HealthComponent`, `ColliderComponent`, `Component`, `Serializable`
- All components implement `Component` interface (getType(): string) and `Serializable` (serialize/deserialize)
- Systems extend `System` base class with `update(entities: Entity[], context: SystemContext): void`
- Entity lookup: `context.world.findEntityByTag("player")`, component access: `entity.getComponent<T>("type")`
- Spatial grid: `context.world.getSpatialGrid().queryRadius(x, y, range)`
- Audio: `context.audio as IAudioService` — use existing audio methods, add new ones as needed
- All new constants go in `GameConstants.ets` with explicit `number`/`string` types
- No external image assets — all art is procedural Canvas2D or OffscreenCanvas pre-rendered

---

### Task 1: Add new enums, constants, and interfaces to GameConstants.ets

**Files:**
- Modify: `entry/src/main/ets/game/GameConstants.ets`

**Interfaces:**
- Consumes: existing enums (EnemyType, BossType, TransformForm, EvolutionBranch)
- Produces: new enums (SkillFamily, SkillTier, DevourState, HumanFormStage), new constants (devour thresholds, level scaling, skill XP), new interfaces (SkillSlot, PassiveSlot, SkillData)

- [ ] **Step 1: Add new enums after existing GameState enum (around line 667)**

Add these enums after the `GameState` enum:

```typescript
// ==================== Slime Devour Gameplay ====================

export enum SkillFamily {
  BOUNCE = 0,     // GRAY_SLIME
  CORROSION = 1,  // PURPLE_SLIME
  FIRE = 2,       // RED_SLIME
  ICE = 3,        // BLUE_SLIME
  LIGHTNING = 4,  // YELLOW_SLIME
  VOID = 5        // GHOST_SLIME
}

export enum SkillTier {
  NONE = 0,
  TIER_1 = 1,
  TIER_2 = 2,
  TIER_3 = 3
}

export enum DevourState {
  IDLE = 0,
  DEVOURING = 1,
  COOLDOWN = 2
}

export enum HumanFormStage {
  NONE = -1,
  PROTO = 0,
  PHANTOM = 1,
  ARMORED = 2,
  COMPLETE = 3
}
```

- [ ] **Step 2: Add devour constants after the new enums**

```typescript
// Devour mechanics
export const DEVOUR_RANGE: number = 20;
export const DEVOUR_ANIM_DURATION: number = 200;
export const DEVOUR_BASE_SKILL_CHANCE: number = 0.3;
export const DEVOUR_SKILL_CHANCE_PER_LEVEL: number = 0.02;
export const DEVOUR_SKILL_CHANCE_CAP: number = 0.6;
export const DEVOUR_ENERGY_GAIN: number = 5;
export const DEVOUR_THRESHOLD_SAME_LEVEL: number = 0.15;
export const DEVOUR_THRESHOLD_HIGHER_LEVEL: number = 0.10;
export const DEVOUR_THRESHOLD_BOSS: number = 0.05;
export const DEVOUR_THRESHOLD_HUMANOID: number = 0.08;

// Monster level scaling
export const MONSTER_MIN_LEVEL: number = 1;
export const MONSTER_MAX_LEVEL: number = 10;
export const MONSTER_HP_SCALE_PER_LEVEL: number = 0.3;
export const MONSTER_SPEED_SCALE_PER_LEVEL: number = 0.05;
export const MONSTER_DAMAGE_PER_3_LEVELS: number = 1;
export const MONSTER_SIZE_PER_4_LEVELS: number = 1;

// Player level scaling
export const PLAYER_LEVEL_BASE_XP: number = 10;
export const PLAYER_LEVEL_XP_INCREMENT: number = 5;
export const PLAYER_HP_PER_LEVEL: number = 2;
export const PLAYER_SPEED_PER_LEVEL: number = 0.3;
export const PLAYER_DAMAGE_PER_LEVEL: number = 1;

// Skill system
export const SKILL_FAMILY_COUNT: number = 6;
export const SKILL_TIER_COUNT: number = 3;
export const SKILL_XP_PER_DEVOUR_SAME: number = 2;
export const SKILL_XP_PER_DEVOUR_OTHER: number = 1;
export const SKILL_TIER_2_XP: number = 10;
export const SKILL_TIER_3_XP: number = 25;
export const PLAYER_ACTIVE_SLOTS_BASE: number = 1;
export const PLAYER_PASSIVE_SLOTS_BASE: number = 1;

// Human form
export const HUMANOID_SPAWN_CHANCE: number = 0.02;
export const MASK_FRAGMENTS_NEEDED: number = 3;
export const MASK_FRAGMENT_DROP_CHANCE: number = 1.0;

// Human form stage bonuses (indexed by HumanFormStage value 0-3)
export const HUMAN_FORM_HP_BONUS: number[] = [0.3, 0.4, 0.5, 0.6];
export const HUMAN_FORM_SPEED_BONUS: number[] = [0.2, 0.3, 0.3, 0.4];
export const HUMAN_FORM_DAMAGE_BONUS: number[] = [0.0, 0.0, 0.0, 0.4];
export const HUMAN_FORM_ACTIVE_SLOTS: number[] = [2, 3, 3, 3];
export const HUMAN_FORM_PASSIVE_SLOTS: number[] = [1, 1, 2, 3];
```

- [ ] **Step 3: Add skill data interfaces after existing interfaces (around line 444)**

```typescript
export interface SkillSlot {
  family: number;   // SkillFamily value
  tier: number;     // SkillTier value
  skillXp: number;  // progress toward next tier
}

export interface PassiveSlot {
  branch: number;   // EvolutionBranch value
  level: number;    // 0-3
}

// Maps EnemyType to SkillFamily (same numeric values)
export const ENEMY_TYPE_TO_SKILL_FAMILY: number[] = [
  SkillFamily.BOUNCE,     // GRAY_SLIME = 0
  SkillFamily.CORROSION,  // PURPLE_SLIME = 1
  SkillFamily.FIRE,       // RED_SLIME = 2
  SkillFamily.ICE,        // BLUE_SLIME = 3
  SkillFamily.LIGHTNING,  // YELLOW_SLIME = 4
  SkillFamily.VOID        // GHOST_SLIME = 5
];

// Skill stats per family per tier: [damage, range, cooldown, aoeRadius]
export const SKILL_STATS: number[][][] = [
  // BOUNCE: [damage, range, cooldown(ms), aoeRadius]
  [[2, 60, 800, 0], [4, 80, 700, 20], [6, 100, 600, 40]],
  // CORROSION
  [[3, 50, 1000, 0], [2, 60, 900, 60], [3, 80, 800, 80]],
  // FIRE
  [[4, 70, 900, 30], [3, 60, 800, 60], [5, 100, 700, 100]],
  // ICE
  [[2, 55, 850, 0], [2, 50, 800, 50], [1, 120, 700, 120]],
  // LIGHTNING
  [[3, 40, 700, 0], [4, 50, 650, 30], [5, 60, 600, 50]],
  // VOID
  [[2, 30, 900, 30], [3, 80, 800, 0], [4, 100, 700, 100]]
];
```

- [ ] **Step 4: Add Inventory field for mask fragments**

Add to the `Inventory` interface (around line 429):

```typescript
  maskFragments: number;
  hasHumanMask: boolean;
```

- [ ] **Step 5: Add SaveData fields for new systems**

Add to the `SaveData` interface (around line 683):

```typescript
  skills: SkillSlot[];
  passives: PassiveSlot[];
  activeSlotCount: number;
  passiveSlotCount: number;
  selectedActiveIndex: number;
  humanFormStage: number;
  hasHumanMask: boolean;
  maskFragments: number;
  humanFormEnergy: number;
  unlockedHumanForms: number[];
```

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameConstants.ets
git commit -m "feat(gameplay): add devour/skill/level enums, constants, and interfaces"
```

---

### Task 2: Create new components (LevelComponent, SkillComponent, DevourComponent, HumanFormComponent)

**Files:**
- Create: `entry/src/main/ets/game/components/LevelComponent.ets`
- Create: `entry/src/main/ets/game/components/SkillComponent.ets`
- Create: `entry/src/main/ets/game/components/DevourComponent.ets`
- Create: `entry/src/main/ets/game/components/HumanFormComponent.ets`

**Interfaces:**
- Consumes: `Component`, `Serializable` from `@qiuyu/engine`; `SkillSlot`, `PassiveSlot` from GameConstants
- Produces: 4 new component classes for use by systems in later tasks

- [ ] **Step 1: Create LevelComponent.ets**

```typescript
import { Component, Serializable } from '@qiuyu/engine';

export class LevelComponent implements Component, Serializable {
  level: number = 1;
  xp: number = 0;

  getType(): string { return "level"; }

  getXpNeeded(): number {
    return 10 + (this.level - 1) * 5;
  }

  serialize(): Record<string, Object> {
    return { level: this.level, xp: this.xp };
  }

  deserialize(data: Record<string, Object>): void {
    this.level = data["level"] as number;
    this.xp = data["xp"] as number;
  }
}
```

- [ ] **Step 2: Create SkillComponent.ets**

```typescript
import { Component, Serializable } from '@qiuyu/engine';
import { SkillSlot, PassiveSlot, PLAYER_ACTIVE_SLOTS_BASE, PLAYER_PASSIVE_SLOTS_BASE } from '../GameConstants';

export class SkillComponent implements Component, Serializable {
  activeSkills: SkillSlot[] = [];
  passiveSkills: PassiveSlot[] = [];
  activeSlotCount: number = PLAYER_ACTIVE_SLOTS_BASE;
  passiveSlotCount: number = PLAYER_PASSIVE_SLOTS_BASE;
  selectedActiveIndex: number = 0;
  skillCooldown: number = 0;

  getType(): string { return "skill"; }

  getSelectedSkill(): SkillSlot | null {
    if (this.selectedActiveIndex < 0 || this.selectedActiveIndex >= this.activeSkills.length) {
      return null;
    }
    return this.activeSkills[this.selectedActiveIndex];
  }

  getSkillByFamily(family: number): SkillSlot | null {
    for (let i: number = 0; i < this.activeSkills.length; i++) {
      if (this.activeSkills[i].family === family) {
        return this.activeSkills[i];
      }
    }
    return null;
  }

  hasFamily(family: number): boolean {
    return this.getSkillByFamily(family) !== null;
  }

  serialize(): Record<string, Object> {
    const activeData: Object[] = [];
    for (let i: number = 0; i < this.activeSkills.length; i++) {
      const s: SkillSlot = this.activeSkills[i];
      activeData.push({ family: s.family, tier: s.tier, skillXp: s.skillXp } as Object);
    }
    const passiveData: Object[] = [];
    for (let i: number = 0; i < this.passiveSkills.length; i++) {
      const p: PassiveSlot = this.passiveSkills[i];
      passiveData.push({ branch: p.branch, level: p.level } as Object);
    }
    return {
      activeSkills: activeData,
      passiveSkills: passiveData,
      activeSlotCount: this.activeSlotCount,
      passiveSlotCount: this.passiveSlotCount,
      selectedActiveIndex: this.selectedActiveIndex,
      skillCooldown: this.skillCooldown
    };
  }

  deserialize(data: Record<string, Object>): void {
    const activeData: Object[] = data["activeSkills"] as Object[];
    this.activeSkills = [];
    if (activeData !== null && activeData !== undefined) {
      for (let i: number = 0; i < activeData.length; i++) {
        const s: Record<string, Object> = activeData[i] as Record<string, Object>;
        const slot: SkillSlot = { family: s["family"] as number, tier: s["tier"] as number, skillXp: s["skillXp"] as number };
        this.activeSkills.push(slot);
      }
    }
    const passiveData: Object[] = data["passiveSkills"] as Object[];
    this.passiveSkills = [];
    if (passiveData !== null && passiveData !== undefined) {
      for (let i: number = 0; i < passiveData.length; i++) {
        const p: Record<string, Object> = passiveData[i] as Record<string, Object>;
        const slot: PassiveSlot = { branch: p["branch"] as number, level: p["level"] as number };
        this.passiveSkills.push(slot);
      }
    }
    this.activeSlotCount = data["activeSlotCount"] as number;
    this.passiveSlotCount = data["passiveSlotCount"] as number;
    this.selectedActiveIndex = data["selectedActiveIndex"] as number;
    this.skillCooldown = data["skillCooldown"] as number;
  }
}
```

- [ ] **Step 3: Create DevourComponent.ets**

```typescript
import { Component, Serializable } from '@qiuyu/engine';
import { DevourState } from '../GameConstants';

export class DevourComponent implements Component, Serializable {
  state: number = DevourState.IDLE;
  devourTimer: number = 0;
  devourTargetId: number = -1;

  getType(): string { return "devour"; }

  serialize(): Record<string, Object> {
    return { state: this.state, devourTimer: this.devourTimer, devourTargetId: this.devourTargetId };
  }

  deserialize(data: Record<string, Object>): void {
    this.state = data["state"] as number;
    this.devourTimer = data["devourTimer"] as number;
    this.devourTargetId = data["devourTargetId"] as number;
  }
}
```

- [ ] **Step 4: Create HumanFormComponent.ets**

```typescript
import { Component, Serializable } from '@qiuyu/engine';
import { HumanFormStage, TRANSFORM_MAX_ENERGY, TRANSFORM_COOLDOWN } from '../GameConstants';

export class HumanFormComponent implements Component, Serializable {
  isHumanForm: boolean = false;
  humanFormStage: number = HumanFormStage.NONE;
  hasMask: boolean = false;
  maskFragments: number = 0;
  formEnergy: number = 0;
  formMaxEnergy: number = TRANSFORM_MAX_ENERGY;
  formCooldown: number = 0;
  animTimer: number = 0;

  getType(): string { return "humanForm"; }

  serialize(): Record<string, Object> {
    return {
      isHumanForm: this.isHumanForm,
      humanFormStage: this.humanFormStage,
      hasMask: this.hasMask,
      maskFragments: this.maskFragments,
      formEnergy: this.formEnergy,
      formMaxEnergy: this.formMaxEnergy,
      formCooldown: this.formCooldown
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.isHumanForm = data["isHumanForm"] as boolean;
    this.humanFormStage = data["humanFormStage"] as number;
    this.hasMask = data["hasMask"] as boolean;
    this.maskFragments = data["maskFragments"] as number;
    this.formEnergy = data["formEnergy"] as number;
    this.formMaxEnergy = data["formMaxEnergy"] as number;
    this.formCooldown = data["formCooldown"] as number;
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/components/LevelComponent.ets \
       entry/src/main/ets/game/components/SkillComponent.ets \
       entry/src/main/ets/game/components/DevourComponent.ets \
       entry/src/main/ets/game/components/HumanFormComponent.ets
git commit -m "feat(gameplay): add LevelComponent, SkillComponent, DevourComponent, HumanFormComponent"
```

---

### Task 3: Add enemy level support to EnemyFactory and EnemyAIComponent

**Files:**
- Modify: `entry/src/main/ets/game/components/EnemyAIComponent.ets`
- Modify: `entry/src/main/ets/game/factories/EnemyFactory.ets`

**Interfaces:**
- Consumes: `MONSTER_HP_SCALE_PER_LEVEL`, `MONSTER_SPEED_SCALE_PER_LEVEL`, `MONSTER_DAMAGE_PER_3_LEVELS`, `MONSTER_SIZE_PER_4_LEVELS`, `SLIME_SIZE`, `SLIME_HP`
- Produces: EnemyAIComponent gains `level` field; EnemyFactory.createSlime accepts `level` parameter and scales stats

- [ ] **Step 1: Add level field to EnemyAIComponent**

Add after the existing `size` field in `EnemyAIComponent`:

```typescript
  level: number = 1;
```

Add to serialize():
```typescript
      level: this.level,
```

Add to deserialize():
```typescript
    this.level = data["level"] as number;
```

- [ ] **Step 2: Update EnemyFactory.createSlime to accept level and scale stats**

Replace the `createSlime` method:

```typescript
  static createSlime(x: number, y: number, enemyType: number, level: number = 1): Entity {
    const entity: Entity = new Entity("enemy");
    entity.addComponent(new PositionComponent(x, y));
    entity.addComponent(new VelocityComponent(0, 0));

    const baseHp: number = EnemyFactory.getHpForType(enemyType);
    const scaledHp: number = Math.floor(baseHp * (1 + (level - 1) * MONSTER_HP_SCALE_PER_LEVEL));
    entity.addComponent(new HealthComponent(scaledHp, scaledHp));

    const ai: EnemyAIComponent = new EnemyAIComponent();
    ai.enemyType = enemyType;
    ai.level = level;
    ai.size = SLIME_SIZE + Math.floor(level / MONSTER_SIZE_PER_4_LEVELS);
    entity.addComponent(ai);

    const size: number = ai.size;
    entity.addComponent(new ColliderComponent(size, size, 0, 0, false));
    return entity;
  }
```

Add the import for the new constants at the top:

```typescript
import { EnemyType, SLIME_SIZE, SLIME_HP, MONSTER_HP_SCALE_PER_LEVEL, MONSTER_SIZE_PER_4_LEVELS } from '../GameConstants';
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/components/EnemyAIComponent.ets \
       entry/src/main/ets/game/factories/EnemyFactory.ets
git commit -m "feat(gameplay): add enemy level support with stat scaling"
```

---

### Task 4: Create MonsterLevelSystem and integrate with ChunkLoadSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/MonsterLevelSystem.ets`
- Modify: `entry/src/main/ets/game/systems/ChunkLoadSystem.ets`

**Interfaces:**
- Consumes: `MONSTER_MIN_LEVEL`, `MONSTER_MAX_LEVEL`, `CHUNK_SIZE`, `TILE_SIZE`
- Produces: MonsterLevelSystem assigns levels to enemies based on chunk distance; ChunkLoadSystem passes level when creating enemies

- [ ] **Step 1: Create MonsterLevelSystem.ets**

This system provides a utility function for calculating monster level based on chunk distance. It has no per-frame logic (similar to EvolutionSystem pattern).

```typescript
import { System, SystemContext, Entity } from '@qiuyu/engine';
import { MONSTER_MIN_LEVEL, MONSTER_MAX_LEVEL } from '../GameConstants';

export class MonsterLevelSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    // No per-frame logic — level assignment happens at spawn time in ChunkLoadSystem
  }

  static calculateLevel(chunkDistance: number): number {
    // chunkDistance = max(|dx|, |dy|) from spawn chunk
    let minLevel: number = MONSTER_MIN_LEVEL;
    let maxLevel: number = MONSTER_MIN_LEVEL;

    if (chunkDistance <= 2) {
      minLevel = 1; maxLevel = 2;
    } else if (chunkDistance <= 5) {
      minLevel = 2; maxLevel = 4;
    } else if (chunkDistance <= 8) {
      minLevel = 3; maxLevel = 6;
    } else {
      minLevel = 5; maxLevel = MONSTER_MAX_LEVEL;
    }

    return minLevel + Math.floor(Math.random() * (maxLevel - minLevel + 1));
  }
}
```

- [ ] **Step 2: Update ChunkLoadSystem to assign levels when spawning enemies**

In ChunkLoadSystem, modify the enemy spawning section (around line 38-43). Replace:

```typescript
          const enemies: SlimeState[] = chunk.enemies;
          for (let i: number = 0; i < enemies.length; i++) {
            const e: SlimeState = enemies[i];
            const enemy: Entity = EnemyFactory.createSlime(e.x, e.y, e.enemyType as number);
            context.world.addEntity(enemy);
          }
```

With:

```typescript
          const enemies: SlimeState[] = chunk.enemies;
          const chunkDist: number = Math.max(Math.abs(cx), Math.abs(cy));
          for (let i: number = 0; i < enemies.length; i++) {
            const e: SlimeState = enemies[i];
            const level: number = MonsterLevelSystem.calculateLevel(chunkDist);
            const enemy: Entity = EnemyFactory.createSlime(e.x, e.y, e.enemyType as number, level);
            context.world.addEntity(enemy);
          }
```

Add import at top:
```typescript
import { MonsterLevelSystem } from './MonsterLevelSystem';
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/systems/MonsterLevelSystem.ets \
       entry/src/main/ets/game/systems/ChunkLoadSystem.ets
git commit -m "feat(gameplay): add MonsterLevelSystem with chunk-distance level scaling"
```

---

### Task 5: Create DevourSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/DevourSystem.ets`

**Interfaces:**
- Consumes: `LevelComponent`, `SkillComponent`, `DevourComponent`, `HealthComponent`, `EnemyAIComponent`, `PositionComponent`; devour constants from GameConstants
- Produces: DevourSystem handles devour condition checking, monster consumption, XP/skill granting

- [ ] **Step 1: Create DevourSystem.ets**

```typescript
import { System, SystemContext, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { LevelComponent } from '../components/LevelComponent';
import { SkillComponent } from '../components/SkillComponent';
import { DevourComponent } from '../components/DevourComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import {
  DEVOUR_RANGE, DEVOUR_ANIM_DURATION,
  DEVOUR_BASE_SKILL_CHANCE, DEVOUR_SKILL_CHANCE_PER_LEVEL, DEVOUR_SKILL_CHANCE_CAP,
  DEVOUR_ENERGY_GAIN, DEVOUR_THRESHOLD_SAME_LEVEL, DEVOUR_THRESHOLD_HIGHER_LEVEL,
  DEVOUR_THRESHOLD_BOSS, DEVOUR_THRESHOLD_HUMANOID,
  SKILL_XP_PER_DEVOUR_SAME, SKILL_XP_PER_DEVOUR_OTHER,
  SKILL_TIER_2_XP, SKILL_TIER_3_XP,
  ENEMY_TYPE_TO_SKILL_FAMILY, SkillFamily, SkillTier, DevourState,
  HUMANOID_SPAWN_CHANCE, MASK_FRAGMENTS_NEEDED,
} from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';

export class DevourSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const playerLevel: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const playerSkill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const devour: DevourComponent | null = player.getComponent<DevourComponent>("devour");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    if (playerPos === null || playerLevel === null || playerSkill === null || devour === null) return;

    const audio: IAudioService = context.audio as IAudioService;
    const dt: number = context.dt;

    // Update devour animation timer
    if (devour.state === DevourState.DEVOURING) {
      devour.devourTimer -= dt;
      if (devour.devourTimer <= 0) {
        devour.state = DevourState.IDLE;
        devour.devourTargetId = -1;
      }
      return; // Can't initiate new devour during animation
    }

    if (devour.state === DevourState.COOLDOWN) {
      devour.devourTimer -= dt;
      if (devour.devourTimer <= 0) {
        devour.state = DevourState.IDLE;
      }
      return;
    }

    // Check for devour input (attack pressed near weakened enemy)
    if (!context.input.attackPressed) return;

    // Find nearest enemy within devour range that meets HP threshold
    const nearby: Entity[] = context.world.getSpatialGrid().queryRadius(playerPos.x, playerPos.y, DEVOUR_RANGE + 30);
    let bestTarget: Entity | null = null;
    let bestDist: number = DEVOUR_RANGE + 1;

    for (let i: number = 0; i < nearby.length; i++) {
      const e: Entity = nearby[i];
      if (!e.active || (e.tag !== "enemy" && e.tag !== "boss")) continue;

      const ePos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const eHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
      if (ePos === null || eHealth === null) continue;

      const dx: number = ePos.x - playerPos.x;
      const dy: number = ePos.y - playerPos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist > DEVOUR_RANGE) continue;

      // Check HP threshold
      const hpFraction: number = eHealth.current / eHealth.max;
      let canDevour: boolean = false;

      if (e.tag === "enemy") {
        const ai: EnemyAIComponent | null = e.getComponent<EnemyAIComponent>("enemyAI");
        if (ai === null) continue;
        const enemyLevel: number = ai.level;

        if (enemyLevel <= playerLevel.level) {
          canDevour = hpFraction < DEVOUR_THRESHOLD_SAME_LEVEL;
        } else {
          canDevour = hpFraction < DEVOUR_THRESHOLD_HIGHER_LEVEL;
        }
      } else if (e.tag === "boss") {
        canDevour = hpFraction < DEVOUR_THRESHOLD_BOSS;
      }

      if (canDevour && dist < bestDist) {
        bestTarget = e;
        bestDist = dist;
      }
    }

    if (bestTarget === null) return; // No valid devour target — let normal attack proceed

    // Consume the attack input so PlayerCombatSystem doesn't also fire
    context.input.attackPressed = false;

    // Execute devour
    const targetHealth: HealthComponent = bestTarget.getComponent<HealthComponent>("Health")!;
    const targetPos: PositionComponent = bestTarget.getComponent<PositionComponent>("Position")!;

    bestTarget.active = false;

    // Start devour animation
    devour.state = DevourState.DEVOURING;
    devour.devourTimer = DEVOUR_ANIM_DURATION;

    // Grant XP
    let monsterLevel: number = 1;
    let isBoss: boolean = false;
    let isHumanoid: boolean = false;
    let skillFamily: number = SkillFamily.BOUNCE;

    if (bestTarget.tag === "enemy") {
      const ai: EnemyAIComponent | null = bestTarget.getComponent<EnemyAIComponent>("enemyAI");
      if (ai !== null) {
        monsterLevel = ai.level;
        skillFamily = ENEMY_TYPE_TO_SKILL_FAMILY[ai.enemyType] as number;
        isHumanoid = ai.enemyType === 6; // HUMANOID_BEAST type
      }
    } else {
      isBoss = true;
      monsterLevel = 5; // Boss minimum level
    }

    const xpGained: number = 3 + monsterLevel * 2;
    playerLevel.xp += xpGained;

    // Human form: mask fragment drop
    if (isHumanoid && humanForm !== null && !humanForm.hasMask) {
      humanForm.maskFragments++;
      if (humanForm.maskFragments >= MASK_FRAGMENTS_NEEDED) {
        humanForm.hasMask = true;
      }
    }

    // Skill acquisition chance
    const skillChance: number = Math.min(
      DEVOUR_BASE_SKILL_CHANCE + monsterLevel * DEVOUR_SKILL_CHANCE_PER_LEVEL,
      DEVOUR_SKILL_CHANCE_CAP
    );

    if (Math.random() < skillChance) {
      this.grantSkill(playerSkill, skillFamily);
    } else {
      // Even on failed skill acquisition, grant skill XP for the family
      this.addSkillXp(playerSkill, skillFamily, SKILL_XP_PER_DEVOUR_OTHER);
    }

    // Human form energy
    if (humanForm !== null && humanForm.isHumanForm) {
      humanForm.formEnergy += DEVOUR_ENERGY_GAIN;
      if (humanForm.formEnergy > humanForm.formMaxEnergy) {
        humanForm.formEnergy = humanForm.formMaxEnergy;
      }
    }

    audio.playEnemyDeath();
  }

  private grantSkill(skillComp: SkillComponent, family: number): void {
    const existing: SkillSlot | null = skillComp.getSkillByFamily(family);
    if (existing !== null) {
      // Already have this family — add skill XP toward next tier
      this.addSkillXp(skillComp, family, SKILL_XP_PER_DEVOUR_SAME);
    } else {
      // New skill — add as tier 1 if slot available
      if (skillComp.activeSkills.length < skillComp.activeSlotCount) {
        const slot: SkillSlot = { family: family, tier: SkillTier.TIER_1, skillXp: 0 };
        skillComp.activeSkills.push(slot);
      } else {
        // No slot available — add XP to closest family skill instead
        if (skillComp.activeSkills.length > 0) {
          this.addSkillXp(skillComp, skillComp.activeSkills[0].family, SKILL_XP_PER_DEVOUR_SAME);
        }
      }
    }
  }

  private addSkillXp(skillComp: SkillComponent, family: number, amount: number): void {
    const slot: SkillSlot | null = skillComp.getSkillByFamily(family);
    if (slot === null) return;

    slot.skillXp += amount;

    // Check tier progression
    if (slot.tier === SkillTier.TIER_1 && slot.skillXp >= SKILL_TIER_2_XP) {
      slot.tier = SkillTier.TIER_2;
      slot.skillXp -= SKILL_TIER_2_XP;
    } else if (slot.tier === SkillTier.TIER_2 && slot.skillXp >= SKILL_TIER_3_XP) {
      slot.tier = SkillTier.TIER_3;
      slot.skillXp -= SKILL_TIER_3_XP;
    }
  }
}
```

Note: This system imports `SkillSlot` from GameConstants. Add the import.

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/game/systems/DevourSystem.ets
git commit -m "feat(gameplay): add DevourSystem with HP threshold checks and skill granting"
```

---

### Task 6: Create SkillSystem for skill activation and damage

**Files:**
- Create: `entry/src/main/ets/game/systems/SkillSystem.ets`

**Interfaces:**
- Consumes: `SkillComponent`, `SKILL_STATS`, `PLAYER_DAMAGE_PER_LEVEL`, `LevelComponent`
- Produces: SkillSystem provides `getSkillDamage()`, `getSkillRange()`, etc. query methods; handles cooldown ticking

- [ ] **Step 1: Create SkillSystem.ets**

```typescript
import { System, SystemContext, Entity } from '@qiuyu/engine';
import { SkillComponent } from '../components/SkillComponent';
import { LevelComponent } from '../components/LevelComponent';
import { SKILL_STATS, PLAYER_DAMAGE_PER_LEVEL, SkillTier } from '../GameConstants';

export class SkillSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    if (skill === null) return;

    // Tick cooldown
    if (skill.skillCooldown > 0) {
      skill.skillCooldown -= context.dt;
      if (skill.skillCooldown < 0) {
        skill.skillCooldown = 0;
      }
    }
  }

  static getSkillDamage(family: number, tier: number, playerLevel: number): number {
    const tierIndex: number = tier - 1; // SkillTier.TIER_1 = 1 → index 0
    if (tierIndex < 0 || tierIndex >= SKILL_STATS[family].length) return 1;
    const baseDamage: number = SKILL_STATS[family][tierIndex][0];
    return baseDamage + Math.floor(playerLevel * PLAYER_DAMAGE_PER_LEVEL / 3);
  }

  static getSkillRange(family: number, tier: number): number {
    const tierIndex: number = tier - 1;
    if (tierIndex < 0 || tierIndex >= SKILL_STATS[family].length) return 30;
    return SKILL_STATS[family][tierIndex][1];
  }

  static getSkillCooldown(family: number, tier: number): number {
    const tierIndex: number = tier - 1;
    if (tierIndex < 0 || tierIndex >= SKILL_STATS[family].length) return 800;
    return SKILL_STATS[family][tierIndex][2];
  }

  static getSkillAoeRadius(family: number, tier: number): number {
    const tierIndex: number = tier - 1;
    if (tierIndex < 0 || tierIndex >= SKILL_STATS[family].length) return 0;
    return SKILL_STATS[family][tierIndex][3];
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/game/systems/SkillSystem.ets
git commit -m "feat(gameplay): add SkillSystem with damage/range/cooldown queries"
```

---

### Task 7: Create HumanoidBeastSystem and enemy type

**Files:**
- Modify: `entry/src/main/ets/game/GameConstants.ets` (add HUMANOID_BEAST to EnemyType)
- Create: `entry/src/main/ets/game/systems/HumanoidBeastSystem.ets`

**Interfaces:**
- Consumes: `HUMANOID_SPAWN_CHANCE`, `EnemyType`, `MonsterLevelSystem`
- Produces: HumanoidBeastSystem manages 拟人兽 spawn replacement; new enemy type 6 (HUMANOID_BEAST)

- [ ] **Step 1: Add HUMANOID_BEAST to EnemyType enum in GameConstants.ets**

Add to the EnemyType enum:

```typescript
export enum EnemyType {
  GRAY_SLIME = 0,
  PURPLE_SLIME = 1,
  RED_SLIME = 2,
  BLUE_SLIME = 3,
  YELLOW_SLIME = 4,
  GHOST_SLIME = 5,
  HUMANOID_BEAST = 6  // 拟人兽 — rare elite
}
```

Also add to ENEMY_TYPE_TO_SKILL_FAMILY array:

```typescript
export const ENEMY_TYPE_TO_SKILL_FAMILY: number[] = [
  SkillFamily.BOUNCE,     // GRAY_SLIME = 0
  SkillFamily.CORROSION,  // PURPLE_SLIME = 1
  SkillFamily.FIRE,       // RED_SLIME = 2
  SkillFamily.ICE,        // BLUE_SLIME = 3
  SkillFamily.LIGHTNING,  // YELLOW_SLIME = 4
  SkillFamily.VOID,       // GHOST_SLIME = 5
  SkillFamily.VOID        // HUMANOID_BEAST = 6 (uses VOID family)
];
```

Add humanoid beast constants:

```typescript
// Humanoid Beast (拟人兽)
export const HUMANOID_BEAST_HP: number = 15;
export const HUMANOID_BEAST_SIZE: number = 16;
export const HUMANOID_BEAST_SPEED: number = 2.5;
export const HUMANOID_BEAST_DAMAGE: number = 2;
export const COLOR_HUMANOID_BEAST: string = '#d4af37';
export const COLOR_HUMANOID_BEAST_GLOW: string = '#ffd700';
```

Add HUMANOID_BEAST case to EnemyFactory.getHpForType:

```typescript
      case EnemyType.HUMANOID_BEAST: return HUMANOID_BEAST_HP;
```

- [ ] **Step 2: Create HumanoidBeastSystem.ets**

This system replaces normal enemy spawns with 拟人兽 based on spawn chance. It runs as part of chunk loading (called from ChunkLoadSystem).

```typescript
import { System, SystemContext, Entity } from '@qiuyu/engine';
import { HUMANOID_SPAWN_CHANCE, EnemyType } from '../GameConstants';

export class HumanoidBeastSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    // No per-frame logic — spawn check happens in ChunkLoadSystem
  }

  static shouldReplaceWithHumanoid(): boolean {
    return Math.random() < HUMANOID_SPAWN_CHANCE;
  }

  static getHumanoidType(): number {
    return EnemyType.HUMANOID_BEAST;
  }
}
```

- [ ] **Step 3: Integrate into ChunkLoadSystem**

In ChunkLoadSystem, modify the enemy spawning loop to occasionally replace enemies with 拟人兽:

```typescript
          for (let i: number = 0; i < enemies.length; i++) {
            const e: SlimeState = enemies[i];
            const level: number = MonsterLevelSystem.calculateLevel(chunkDist);
            let enemyType: number = e.enemyType as number;

            // 2% chance to replace with 拟人兽 (not in first 2 chunks)
            if (chunkDist > 2 && HumanoidBeastSystem.shouldReplaceWithHumanoid()) {
              enemyType = HumanoidBeastSystem.getHumanoidType();
            }

            const enemy: Entity = EnemyFactory.createSlime(e.x, e.y, enemyType, level);
            context.world.addEntity(enemy);
          }
```

Add import:
```typescript
import { HumanoidBeastSystem } from './HumanoidBeastSystem';
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/GameConstants.ets \
       entry/src/main/ets/game/systems/HumanoidBeastSystem.ets \
       entry/src/main/ets/game/systems/ChunkLoadSystem.ets \
       entry/src/main/ets/game/factories/EnemyFactory.ets
git commit -m "feat(gameplay): add HUMANOID_BEAST enemy type and spawn system"
```

---

### Task 8: Refactor PlayerCombatSystem for skill-based combat

**Files:**
- Modify: `entry/src/main/ets/game/systems/PlayerCombatSystem.ets`

**Interfaces:**
- Consumes: `SkillSystem`, `SkillComponent`, `LevelComponent`, `DevourComponent`
- Produces: Combat uses equipped skill for damage/range instead of weapon form stats; devour takes priority over attack

- [ ] **Step 1: Update imports**

Replace existing imports with:

```typescript
import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { LevelComponent } from '../components/LevelComponent';
import { SkillComponent } from '../components/SkillComponent';
import { DevourComponent } from '../components/DevourComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { SkillSystem } from './SkillSystem';
import { DropFactory } from '../factories/DropFactory';
import { shakeCamera } from '../helpers/SystemHelpers';
import {
  SLIME_KNOCKBACK, ATTACK_RANGE, ATTACK_WIDTH, ATTACK_DURATION, ATTACK_COOLDOWN,
  TRANSFORM_ENERGY_KILL_SLIME, DevourState, SkillSlot,
} from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';
```

- [ ] **Step 2: Update the update() method**

Replace the body of `update()`:

```typescript
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const pos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const movement: MovementComponent | null = player.getComponent<MovementComponent>("movement");
    const combat: CombatComponent | null = player.getComponent<CombatComponent>("combat");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const playerLevel: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const devour: DevourComponent | null = player.getComponent<DevourComponent>("devour");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    if (pos === null || movement === null || combat === null || health === null) return;
    if (playerLevel === null || skill === null) return;

    const audio: IAudioService = context.audio as IAudioService;

    // Skip if devour is in progress
    if (devour !== null && devour.state !== DevourState.IDLE) return;

    // Handle attack trigger (engulf escape or normal attack initiation)
    if (context.input.attackPressed) {
      context.input.attackPressed = false;
      if (movement.isEngulfed) {
        movement.engulfEscapeCount++;
        audio.playEnemyHit();
        shakeCamera(context, 80);
        return;
      }

      // Check if we have a skill equipped and cooldown is ready
      const selectedSkill: SkillSlot | null = skill.getSelectedSkill();
      if (selectedSkill !== null && skill.skillCooldown <= 0) {
        combat.isAttacking = true;
        const cooldown: number = SkillSystem.getSkillCooldown(selectedSkill.family, selectedSkill.tier);
        combat.attackTimer = cooldown;
        skill.skillCooldown = cooldown;
      } else if (selectedSkill === null) {
        // Basic bump attack (no skill equipped)
        combat.isAttacking = true;
        combat.attackTimer = ATTACK_COOLDOWN;
      }
    }

    // Process active attack
    if (combat.isAttacking) {
      combat.attackTimer -= context.dt;
      if (combat.attackTimer <= 0) {
        combat.isAttacking = false;
      } else {
        this.performSkillAttack(entities, pos, movement, combat, playerLevel, skill, humanForm, audio, context);
      }
    }
  }
```

- [ ] **Step 3: Replace performAttack with performSkillAttack**

```typescript
  private performSkillAttack(
    entities: Entity[],
    pos: PositionComponent,
    movement: MovementComponent,
    combat: CombatComponent,
    playerLevel: LevelComponent,
    skill: SkillComponent,
    humanForm: HumanFormComponent | null,
    audio: IAudioService,
    context: SystemContext
  ): void {
    const selectedSkill: SkillSlot | null = skill.getSelectedSkill();
    let attackRange: number = ATTACK_RANGE;
    let attackWidth: number = ATTACK_WIDTH;
    let damage: number = 1;

    if (selectedSkill !== null) {
      attackRange = SkillSystem.getSkillRange(selectedSkill.family, selectedSkill.tier);
      damage = SkillSystem.getSkillDamage(selectedSkill.family, selectedSkill.tier, playerLevel.level);
      attackWidth = SkillSystem.getSkillAoeRadius(selectedSkill.family, selectedSkill.tier);
      if (attackWidth === 0) attackWidth = 20; // Single target skills have small hitbox
    }

    const attackX: number = pos.x + Math.cos(movement.facing) * attackRange;
    const attackY: number = pos.y + Math.sin(movement.facing) * attackRange;

    const nearby: Entity[] = context.world.getSpatialGrid().queryRadius(attackX, attackY, attackWidth + 60);

    for (let i: number = 0; i < nearby.length; i++) {
      const e: Entity = nearby[i];
      if (!e.active) continue;

      if (e.tag === "enemy") {
        const enemyPos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
        const enemyVel: VelocityComponent | null = e.getComponent<VelocityComponent>("Velocity");
        const enemyHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
        const ai: EnemyAIComponent | null = e.getComponent<EnemyAIComponent>("enemyAI");
        if (enemyPos === null || enemyVel === null || enemyHealth === null || ai === null) continue;

        const dx: number = enemyPos.x - attackX;
        const dy: number = enemyPos.y - attackY;
        const dist: number = Math.sqrt(dx * dx + dy * dy);
        if (dist < attackWidth + ai.size) {
          enemyHealth.damage(damage);
          ai.hitFlash = 150;
          const knockAngle: number = Math.atan2(dy, dx);
          enemyVel.vx = Math.cos(knockAngle) * SLIME_KNOCKBACK;
          enemyVel.vy = Math.sin(knockAngle) * SLIME_KNOCKBACK;
          shakeCamera(context, 100);
          audio.playEnemyHit();

          if (enemyHealth.isDead()) {
            this.onEnemyDeath(e, enemyPos, ai, humanForm, audio, context);
          }
        }
      } else if (e.tag === "boss") {
        const bossPos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
        const bossHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
        if (bossPos === null || bossHealth === null) continue;

        const dx: number = bossPos.x - attackX;
        const dy: number = bossPos.y - attackY;
        const dist: number = Math.sqrt(dx * dx + dy * dy);
        if (dist < attackWidth + 60) {
          bossHealth.damage(damage);
          shakeCamera(context, 120);
          audio.playEnemyHit();
        }
      }
    }
  }
```

- [ ] **Step 4: Update onEnemyDeath signature**

Change the `transform: TransformComponent` parameter to `humanForm: HumanFormComponent | null`:

```typescript
  private onEnemyDeath(
    enemy: Entity,
    enemyPos: PositionComponent,
    ai: EnemyAIComponent,
    humanForm: HumanFormComponent | null,
    audio: IAudioService,
    context: SystemContext
  ): void {
    enemy.active = false;

    // Human form energy gain
    if (humanForm !== null && humanForm.isHumanForm) {
      humanForm.formEnergy += TRANSFORM_ENERGY_KILL_SLIME;
      if (humanForm.formEnergy > humanForm.formMaxEnergy) {
        humanForm.formEnergy = humanForm.formMaxEnergy;
      }
    }

    audio.playEnemyDeath();

    // Create XP orb drops
    const orbCount: number = 1 + Math.floor(Math.random() * 3);
    for (let k: number = 0; k < orbCount; k++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 5 + Math.random() * 15;
      const orb: Entity = DropFactory.createXpOrb(
        enemyPos.x + Math.cos(angle) * dist,
        enemyPos.y + Math.sin(angle) * dist,
        1
      );
      context.world.addEntity(orb);
    }
  }
```

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/systems/PlayerCombatSystem.ets
git commit -m "feat(gameplay): refactor PlayerCombatSystem to use skill-based damage"
```

---

### Task 9: Refactor XpLevelSystem for new XP curve and level-up rewards

**Files:**
- Modify: `entry/src/main/ets/game/systems/XpLevelSystem.ets`

**Interfaces:**
- Consumes: `LevelComponent` (replaces XpComponent for level tracking), `PLAYER_LEVEL_BASE_XP`, `PLAYER_LEVEL_XP_INCREMENT`, `PLAYER_HP_PER_LEVEL`, `PLAYER_SPEED_PER_LEVEL`
- Produces: New XP curve `10 + (level-1)*5`, level-up grants +2 HP, +0.3 speed

- [ ] **Step 1: Rewrite XpLevelSystem to use LevelComponent**

Replace the full file content:

```typescript
import { System, SystemContext, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { LevelComponent } from '../components/LevelComponent';
import { XpPickupComponent } from '../components/XpPickupComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import {
  XP_COLLECT_RANGE, XP_MAGNET_RANGE,
  PLAYER_HP_PER_LEVEL,
  TRANSFORM_ENERGY_XP_ORB,
} from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';

export class XpLevelSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const level: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    if (playerPos === null || level === null || health === null) return;

    const audio: IAudioService = context.audio as IAudioService;

    for (let i: number = 0; i < entities.length; i++) {
      const orb: Entity = entities[i];
      if (!orb.active || orb.tag !== "xpOrb") continue;

      const orbPos: PositionComponent | null = orb.getComponent<PositionComponent>("Position");
      const pickup: XpPickupComponent | null = orb.getComponent<XpPickupComponent>("xpPickup");
      if (orbPos === null || pickup === null) continue;

      const dx: number = playerPos.x - orbPos.x;
      const dy: number = playerPos.y - orbPos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      // Magnet effect
      if (dist < XP_MAGNET_RANGE && dist > 1) {
        const pullSpeed: number = 3.0 * (1.0 - dist / XP_MAGNET_RANGE);
        orbPos.x += (dx / dist) * pullSpeed;
        orbPos.y += (dy / dist) * pullSpeed;
      }

      // Collect XP
      if (dist < XP_COLLECT_RANGE) {
        orb.active = false;
        level.xp += pickup.xpValue;

        // Human form energy bonus
        if (humanForm !== null && humanForm.isHumanForm) {
          humanForm.formEnergy += TRANSFORM_ENERGY_XP_ORB;
          if (humanForm.formEnergy > humanForm.formMaxEnergy) {
            humanForm.formEnergy = humanForm.formMaxEnergy;
          }
        }

        audio.playXpCollect();

        // Level up check (scaling XP curve)
        const xpNeeded: number = level.getXpNeeded();
        if (level.xp >= xpNeeded) {
          level.xp -= xpNeeded;
          level.level++;
          health.heal(PLAYER_HP_PER_LEVEL);
          if (health.current > health.max) {
            health.current = health.max;
          }
          // Increase max HP on level up
          health.max += PLAYER_HP_PER_LEVEL;
          audio.playLevelUp();
        }
      }
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/game/systems/XpLevelSystem.ets
git commit -m "feat(gameplay): refactor XpLevelSystem with scaling XP curve and level-up HP"
```

---

### Task 10: Create HumanFormSystem (replaces TransformSystem semantics)

**Files:**
- Create: `entry/src/main/ets/game/systems/HumanFormSystem.ets`

**Interfaces:**
- Consumes: `HumanFormComponent`, `SkillComponent`, `HUMAN_FORM_*` constants, `TRANSFORM_DRAIN_RATES`, `TRANSFORM_SPEEDS`, `TRANSFORM_ATTACK_COSTS`
- Produces: HumanFormSystem manages activation/deactivation, energy drain, form stage bonuses

- [ ] **Step 1: Create HumanFormSystem.ets**

```typescript
import { System, SystemContext, Entity, HealthComponent } from '@qiuyu/engine';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { SkillComponent } from '../components/SkillComponent';
import {
  TRANSFORM_PASSIVE_REGEN, TRANSFORM_COOLDOWN, TRANSFORM_MAX_ENERGY,
  TRANSFORM_DRAIN_RATES, TRANSFORM_ATTACK_COSTS, TRANSFORM_ATTACK_COOLDOWNS,
  HUMAN_FORM_HP_BONUS, HUMAN_FORM_ACTIVE_SLOTS, HUMAN_FORM_PASSIVE_SLOTS,
  HumanFormStage, DEVOUR_ENERGY_GAIN,
} from '../GameConstants';

export class HumanFormSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const hf: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    if (hf === null) return;

    const dtSec: number = context.dt / 1000;

    if (!hf.isHumanForm) {
      // Passive regen when not in human form
      if (hf.hasMask && hf.formCooldown > 0) {
        hf.formCooldown -= context.dt;
        if (hf.formCooldown < 0) hf.formCooldown = 0;
      }

      // Auto-regen energy
      if (hf.hasMask && hf.formCooldown <= 0) {
        hf.formEnergy += TRANSFORM_PASSIVE_REGEN * dtSec;
        if (hf.formEnergy > hf.formMaxEnergy) hf.formEnergy = hf.formMaxEnergy;
      }

      // Check for transform activation (tool pressed + has mask + energy sufficient + cooldown ready)
      if (context.input.toolPressed && hf.hasMask && hf.formCooldown <= 0 && hf.formEnergy >= 20) {
        this.activateHumanForm(hf, skill, health);
        context.input.toolPressed = false;
      }
      return;
    }

    // In human form — drain energy
    const stageIndex: number = hf.humanFormStage >= 0 ? hf.humanFormStage : 0;
    const drainRate: number = TRANSFORM_DRAIN_RATES[stageIndex];
    hf.formEnergy -= drainRate * dtSec;

    // Animation timer
    if (hf.animTimer > 0) {
      hf.animTimer -= context.dt;
    }

    // Energy depleted — revert
    if (hf.formEnergy <= 0) {
      this.deactivateHumanForm(hf, skill, health);
    }
  }

  private activateHumanForm(hf: HumanFormComponent, skill: SkillComponent | null, health: HealthComponent | null): void {
    hf.isHumanForm = true;
    if (hf.humanFormStage < 0) hf.humanFormStage = HumanFormStage.PROTO;
    hf.formEnergy = hf.formMaxEnergy;
    hf.animTimer = 800; // Activation animation

    // Apply stage bonuses to skill slots
    if (skill !== null) {
      const stageIndex: number = hf.humanFormStage;
      skill.activeSlotCount = HUMAN_FORM_ACTIVE_SLOTS[stageIndex];
      skill.passiveSlotCount = HUMAN_FORM_PASSIVE_SLOTS[stageIndex];
    }

    // Apply HP bonus
    if (health !== null) {
      const bonus: number = HUMAN_FORM_HP_BONUS[hf.humanFormStage];
      const baseMax: number = health.max;
      health.max = Math.floor(baseMax * (1 + bonus));
      if (health.current > health.max) health.current = health.max;
    }
  }

  private deactivateHumanForm(hf: HumanFormComponent, skill: SkillComponent | null, health: HealthComponent | null): void {
    hf.isHumanForm = false;
    hf.formEnergy = 0;
    hf.formCooldown = TRANSFORM_COOLDOWN;
    hf.animTimer = 500; // Revert animation

    // Restore base skill slots
    if (skill !== null) {
      skill.activeSlotCount = 1; // PLAYER_ACTIVE_SLOTS_BASE
      skill.passiveSlotCount = 1; // PLAYER_PASSIVE_SLOTS_BASE
      if (skill.selectedActiveIndex >= skill.activeSkills.length) {
        skill.selectedActiveIndex = 0;
      }
    }

    // Restore base HP (remove bonus)
    if (health !== null) {
      const bonus: number = HUMAN_FORM_HP_BONUS[hf.humanFormStage >= 0 ? hf.humanFormStage : 0];
      health.max = Math.floor(health.max / (1 + bonus));
      if (health.current > health.max) health.current = health.max;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/game/systems/HumanFormSystem.ets
git commit -m "feat(gameplay): add HumanFormSystem with energy drain and stage bonuses"
```

---

### Task 11: Create PassiveTreeSystem (replaces EvolutionSystem semantics)

**Files:**
- Create: `entry/src/main/ets/game/systems/PassiveTreeSystem.ets`

**Interfaces:**
- Consumes: `SkillComponent`, `InventoryComponent`, `EVOLUTION_COST_*`, `EvolutionBranch`, `MaterialType`
- Produces: PassiveTreeSystem provides canUpgrade/query/tryUpgrade methods for passive skill tree

- [ ] **Step 1: Create PassiveTreeSystem.ets**

```typescript
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
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/game/systems/PassiveTreeSystem.ets
git commit -m "feat(gameplay): add PassiveTreeSystem replacing EvolutionSystem semantics"
```

---

### Task 12: Update PlayerFactory with new components

**Files:**
- Modify: `entry/src/main/ets/game/factories/PlayerFactory.ets`

**Interfaces:**
- Consumes: `LevelComponent`, `SkillComponent`, `DevourComponent`, `HumanFormComponent`
- Produces: Player entity now has 14 components (was 10)

- [ ] **Step 1: Update PlayerFactory.create()**

Replace the full file:

```typescript
import { Entity, PositionComponent, VelocityComponent, HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { XpComponent } from '../components/XpComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { LevelComponent } from '../components/LevelComponent';
import { SkillComponent } from '../components/SkillComponent';
import { DevourComponent } from '../components/DevourComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { PLAYER_MAX_HP } from '../GameConstants';

export class PlayerFactory {
  static create(startX: number, startY: number): Entity {
    const entity: Entity = new Entity("player");
    entity.addComponent(new PositionComponent(startX, startY));
    entity.addComponent(new VelocityComponent(0, 0));
    entity.addComponent(new HealthComponent(PLAYER_MAX_HP, PLAYER_MAX_HP));
    entity.addComponent(new MovementComponent());
    entity.addComponent(new CombatComponent());
    entity.addComponent(new TransformComponent()); // Kept for backward compat during transition
    entity.addComponent(new InventoryComponent());
    entity.addComponent(new XpComponent()); // Kept for backward compat during transition
    entity.addComponent(new EvolutionComponent()); // Kept for backward compat during transition
    entity.addComponent(new ColliderComponent(20, 20, 0, 0));

    // New gameplay components
    entity.addComponent(new LevelComponent());
    entity.addComponent(new SkillComponent());
    entity.addComponent(new DevourComponent());
    entity.addComponent(new HumanFormComponent());

    return entity;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/game/factories/PlayerFactory.ets
git commit -m "feat(gameplay): add new components to PlayerFactory"
```

---

### Task 13: Wire new systems into GameScene

**Files:**
- Modify: `entry/src/main/ets/game/GameScene.ets`

**Interfaces:**
- Consumes: All new systems (DevourSystem, SkillSystem, MonsterLevelSystem, HumanoidBeastSystem, HumanFormSystem, PassiveTreeSystem)
- Produces: Systems registered in correct execution order

- [ ] **Step 1: Add imports for new systems**

Add after existing system imports:

```typescript
import { DevourSystem } from './systems/DevourSystem';
import { SkillSystem } from './systems/SkillSystem';
import { MonsterLevelSystem } from './systems/MonsterLevelSystem';
import { HumanoidBeastSystem } from './systems/HumanoidBeastSystem';
import { HumanFormSystem } from './systems/HumanFormSystem';
import { PassiveTreeSystem } from './systems/PassiveTreeSystem';
```

- [ ] **Step 2: Register new systems in execution order**

In the constructor, after the existing system registrations, add the new systems. The order should be:

After `ChunkLoadSystem` (line 81), add:
```typescript
    this.world.addSystem(new MonsterLevelSystem());
    this.world.addSystem(new HumanoidBeastSystem());
```

After `PlayerCombatSystem` (line 83), add:
```typescript
    this.world.addSystem(new DevourSystem());
    this.world.addSystem(new SkillSystem());
```

After `TransformSystem` (line 86), add:
```typescript
    this.world.addSystem(new HumanFormSystem());
```

After `EvolutionSystem` (line 94), add:
```typescript
    this.world.addSystem(new PassiveTreeSystem());
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/GameScene.ets
git commit -m "feat(gameplay): wire new systems into GameScene"
```

---

### Task 14: Update EnemyRenderer for level display and 拟人兽 visual

**Files:**
- Modify: `entry/src/main/ets/game/renderers/EnemyRenderer.ets`

**Interfaces:**
- Consumes: `EnemyAIComponent.level`, `EnemyType.HUMANOID_BEAST`, `COLOR_HUMANOID_BEAST`
- Produces: Level number above enemy head, 拟人兽 golden visual

- [ ] **Step 1: Add level display above enemy**

In the enemy rendering method, after drawing the enemy body, add level text:

```typescript
    // Draw level indicator
    const level: number = ai.level;
    const levelColor: string = level > playerLevel ? '#ef4444' : (level < playerLevel ? '#22c55e' : '#ffffff');
    ctx.font = '8px monospace';
    ctx.fillStyle = levelColor;
    ctx.textAlign = 'center';
    ctx.fillText('Lv' + level.toString(), screenX, screenY - ai.size - 6);
```

This requires getting the player's level from LevelComponent — pass it as a parameter or look it up once per frame.

- [ ] **Step 2: Add 拟人兽 rendering**

Add a special case for `EnemyType.HUMANOID_BEAST` in the sprite/procedural rendering:

```typescript
    if (ai.enemyType === EnemyType.HUMANOID_BEAST) {
      // Golden humanoid slime with upright posture
      ctx.fillStyle = COLOR_HUMANOID_BEAST;
      ctx.beginPath();
      // Taller body (upright)
      ctx.ellipse(screenX, screenY, size * 0.6, size * 0.9, 0, 0, Math.PI * 2);
      ctx.fill();
      // Golden glow
      ctx.strokeStyle = COLOR_HUMANOID_BEAST_GLOW;
      ctx.lineWidth = 2;
      ctx.stroke();
      // Face markings
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(screenX - 3, screenY - 4, 2, 2);
      ctx.fillRect(screenX + 1, screenY - 4, 2, 2);
      return;
    }
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/renderers/EnemyRenderer.ets
git commit -m "feat(gameplay): add level display and 拟人兽 rendering to EnemyRenderer"
```

---

### Task 15: Update SaveLoadSystem for new components

**Files:**
- Modify: `entry/src/main/ets/game/systems/SaveLoadSystem.ets`

**Interfaces:**
- Consumes: `LevelComponent`, `SkillComponent`, `DevourComponent`, `HumanFormComponent`, new `SaveData` fields
- Produces: Save/load handles all new component data

- [ ] **Step 1: Update serialization to include new components**

In the save method, add reading from new components:

```typescript
    const level: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    const inventory: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");

    // Add to save data:
    const saveData: SaveData = {
      // ... existing fields ...
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
```

- [ ] **Step 2: Update deserialization to restore new components**

In the load method, add writing to new components:

```typescript
    // Restore new components
    if (level !== null) {
      level.level = saveData.level;
      level.xp = saveData.xp;
    }
    if (skill !== null) {
      skill.activeSkills = saveData.skills || [];
      skill.passiveSkills = saveData.passives || [];
      skill.activeSlotCount = saveData.activeSlotCount || 1;
      skill.passiveSlotCount = saveData.passiveSlotCount || 1;
      skill.selectedActiveIndex = saveData.selectedActiveIndex || 0;
    }
    if (humanForm !== null) {
      humanForm.humanFormStage = saveData.humanFormStage ?? -1;
      humanForm.hasMask = saveData.hasHumanMask || false;
      humanForm.maskFragments = saveData.maskFragments || 0;
      humanForm.formEnergy = saveData.humanFormEnergy || 0;
    }
```

- [ ] **Step 3: Handle save migration (old saves without new fields)**

Add null checks for new fields when loading old saves:

```typescript
    // Migration: old saves may not have skill/humanForm fields
    if (saveData.skills === undefined) saveData.skills = [];
    if (saveData.passives === undefined) saveData.passives = [];
    if (saveData.humanFormStage === undefined) saveData.humanFormStage = -1;
    if (saveData.hasHumanMask === undefined) saveData.hasHumanMask = false;
    if (saveData.maskFragments === undefined) saveData.maskFragments = 0;
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/systems/SaveLoadSystem.ets
git commit -m "feat(gameplay): update SaveLoadSystem for new components with migration"
```

---

### Task 16: Update Inventory interface and InventoryComponent for mask fragments

**Files:**
- Modify: `entry/src/main/ets/game/components/InventoryComponent.ets`

**Interfaces:**
- Consumes: `Inventory` interface (with new `maskFragments`, `hasHumanMask` fields from Task 1)
- Produces: InventoryComponent stores mask fragment count and mask status

- [ ] **Step 1: Add mask fragment fields to InventoryComponent**

Add fields:

```typescript
  maskFragments: number = 0;
  hasHumanMask: boolean = false;
```

Update serialize():
```typescript
      maskFragments: this.maskFragments,
      hasHumanMask: this.hasHumanMask,
```

Update deserialize():
```typescript
    this.maskFragments = data["maskFragments"] as number;
    this.hasHumanMask = data["hasHumanMask"] as boolean;
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/game/components/InventoryComponent.ets
git commit -m "feat(gameplay): add mask fragment fields to InventoryComponent"
```

---

### Task 17: Remove gender system from CharacterSelectPage

**Files:**
- Modify: `entry/src/main/ets/pages/CharacterSelectPage.ets`

**Interfaces:**
- Consumes: existing CharacterSelectPage
- Produces: Simplified character select with "New Game" / "Continue" only, no gender selection

- [ ] **Step 1: Simplify CharacterSelectPage**

Remove gender selection UI elements. Replace with a simple start menu:
- Game title
- "New Game" button
- "Continue" button (if save exists)
- Settings button

Remove all references to `GenderType`, `playerGender`, gender-related state.

- [ ] **Step 2: Remove gender from GameScene**

In `GameScene.ets`, remove:
- `private playerGender: number = 0;` field
- `setPlayerGender()` method (if exists)
- Any gender-related logic in renderers

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/pages/CharacterSelectPage.ets \
       entry/src/main/ets/game/GameScene.ets
git commit -m "refactor(gameplay): remove gender system from character select"
```

---

### Task 18: Update PlayerRenderer for slime-only and human form visuals

**Files:**
- Modify: `entry/src/main/ets/game/renderers/PlayerRenderer.ets`

**Interfaces:**
- Consumes: `HumanFormComponent`, `SkillComponent`
- Produces: Player renders as slime by default, humanoid when in human form

- [ ] **Step 1: Add human form rendering path**

In the render method, check `HumanFormComponent.isHumanForm`:

```typescript
    if (humanForm !== null && humanForm.isHumanForm) {
      this.renderHumanForm(ctx, screenX, screenY, humanForm, combat);
      return;
    }
    // Otherwise render as slime (existing procedural slime rendering)
```

Add `renderHumanForm` method that draws a humanoid figure based on `humanFormStage`:
- PROTO: basic humanoid outline
- PHANTOM: translucent ghost-like humanoid
- ARMORED: armored humanoid with metallic colors
- COMPLETE: fully armored with glowing effects

- [ ] **Step 2: Remove gender-specific rendering**

Remove the `gender` variable and any female rendering paths. Player is always a slime (or genderless humanoid in human form).

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/renderers/PlayerRenderer.ets
git commit -m "feat(gameplay): update PlayerRenderer for slime default and human form"
```

---

### Task 19: Update UIRenderer for skill HUD and level display

**Files:**
- Modify: `entry/src/main/ets/game/renderers/UIRenderer.ets`

**Interfaces:**
- Consumes: `LevelComponent`, `SkillComponent`, `HumanFormComponent`, `DEVOUR_RANGE`
- Produces: HUD shows player level, active skill icon/cooldown, devour indicator, human form energy bar

- [ ] **Step 1: Add player level display next to HP bar**

```typescript
    // Player level
    ctx.font = 'bold 12px monospace';
    ctx.fillStyle = '#22d3ee';
    ctx.textAlign = 'left';
    ctx.fillText('Lv.' + level.level.toString(), 10, hpBarY - 8);
```

- [ ] **Step 2: Add active skill icon and cooldown**

```typescript
    // Active skill indicator
    const selectedSkill: SkillSlot | null = skill.getSelectedSkill();
    if (selectedSkill !== null) {
      const skillX: number = 60;
      const skillY: number = screenH - 40;
      // Draw skill icon (colored circle by family)
      ctx.fillStyle = this.getSkillFamilyColor(selectedSkill.family);
      ctx.beginPath();
      ctx.arc(skillX, skillY, 12, 0, Math.PI * 2);
      ctx.fill();
      // Tier indicator
      ctx.fillStyle = '#ffffff';
      ctx.font = '10px monospace';
      ctx.textAlign = 'center';
      ctx.fillText('T' + selectedSkill.tier.toString(), skillX, skillY + 4);
      // Cooldown overlay
      if (skill.skillCooldown > 0) {
        const maxCd: number = SkillSystem.getSkillCooldown(selectedSkill.family, selectedSkill.tier);
        const cdFraction: number = skill.skillCooldown / maxCd;
        ctx.fillStyle = 'rgba(0,0,0,0.6)';
        ctx.beginPath();
        ctx.moveTo(skillX, skillY);
        ctx.arc(skillX, skillY, 12, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * cdFraction);
        ctx.fill();
      }
    }
```

- [ ] **Step 3: Add devour range indicator**

When player is near a weakened enemy, show a devour indicator (green pulsing ring around the enemy).

- [ ] **Step 4: Add human form energy bar**

When player has mask, show energy bar below HP bar:

```typescript
    if (humanForm.hasMask) {
      const energyBarX: number = 10;
      const energyBarY: number = hpBarY + 20;
      const energyBarW: number = 80;
      const energyBarH: number = 6;
      const energyFraction: number = humanForm.formEnergy / humanForm.formMaxEnergy;
      // Background
      ctx.fillStyle = '#1f2937';
      ctx.fillRect(energyBarX, energyBarY, energyBarW, energyBarH);
      // Fill
      ctx.fillStyle = humanForm.isHumanForm ? '#22d3ee' : '#4b5563';
      ctx.fillRect(energyBarX, energyBarY, energyBarW * energyFraction, energyBarH);
    }
```

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/renderers/UIRenderer.ets
git commit -m "feat(gameplay): update UIRenderer with level, skill, devour, and human form HUD"
```

---

### Task 20: Clean up deprecated code and verify integration

**Files:**
- Modify: various files to remove/update deprecated references
- Verify: full game integration test

**Interfaces:**
- Consumes: all previous tasks
- Produces: clean codebase with no broken references, game runs end-to-end

- [ ] **Step 1: Verify all imports resolve**

Run a build check to ensure no broken imports. Fix any issues.

- [ ] **Step 2: Remove dead code from TransformSystem and EvolutionSystem**

These systems are still registered but their old semantics are deprecated. Add comments marking them as deprecated:

```typescript
// @deprecated — Use HumanFormSystem instead
export class TransformSystem extends System { ... }
```

```typescript
// @deprecated — Use PassiveTreeSystem instead
export class EvolutionSystem extends System { ... }
```

- [ ] **Step 3: Update PlayerMovementSystem to not skip when transformed**

The current PlayerMovementSystem skips movement when `transform.isTransformed`. Update to also check `humanForm.isHumanForm` and apply human form speed bonus.

- [ ] **Step 4: Final integration commit**

```bash
git add -A
git commit -m "feat(gameplay): complete slime devour gameplay redesign integration"
```

- [ ] **Step 5: Test the game end-to-end**

Verify:
1. Player spawns as slime with LevelComponent, SkillComponent, DevourComponent, HumanFormComponent
2. Enemies spawn with levels based on chunk distance
3. Devour works: approach weakened enemy, press attack, enemy consumed, XP/skill granted
4. Skills appear in skill slots, can be used for attacks
5. 拟人兽 spawns rarely, drops mask fragments
6. Human form activates with mask, provides stat bonuses
7. Save/load preserves all new state
8. Level display shows above enemies
9. HUD shows level, skill, energy bar

---

## Task Dependency Graph

```
Task 1 (Constants) ──┬── Task 2 (Components) ──── Task 12 (PlayerFactory)
                     │                                    │
                     ├── Task 3 (Enemy level) ──── Task 4 (MonsterLevelSystem)
                     │                                    │
                     ├── Task 5 (DevourSystem) ───────────┤
                     │                                    │
                     ├── Task 6 (SkillSystem) ────────────┤
                     │                                    │
                     ├── Task 7 (HumanoidBeast) ──── Task 4
                     │                                    │
                     ├── Task 8 (Combat refactor) ← Task 5, 6
                     │
                     ├── Task 9 (XP refactor)
                     │
                     ├── Task 10 (HumanFormSystem)
                     │
                     ├── Task 11 (PassiveTreeSystem)
                     │
                     └── Task 16 (Inventory update)
                                                   │
Task 13 (GameScene wiring) ← Tasks 5,6,7,10,11 ───┤
                                                   │
Task 14 (EnemyRenderer) ← Task 3 ──────────────────┤
Task 15 (SaveLoad) ← Task 2,12,16 ────────────────┤
Task 17 (Remove gender) ──────────────────────────┤
Task 18 (PlayerRenderer) ← Task 10 ───────────────┤
Task 19 (UIRenderer) ← Task 13 ───────────────────┤
Task 20 (Cleanup) ← ALL ──────────────────────────┘
```
