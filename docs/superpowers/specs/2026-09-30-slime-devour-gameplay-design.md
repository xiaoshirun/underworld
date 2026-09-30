# Slime Devour Gameplay Redesign

## Overview

Transform the game from a humanoid warrior with weapons/transformation/evolution into a slime-based devour-and-evolve gameplay loop. The player starts as a basic slime whose primary mechanic is devouring other monsters to gain their skills and grow stronger. A rare elite enemy type (拟人兽) gates access to the human form evolution path.

## Core Loop

1. **Explore** procedurally generated dungeon chunks
2. **Fight** monsters using basic slime bump attack + acquired skills
3. **Weaken** monsters (reduce HP below threshold)
4. **Devour** weakened monsters to gain XP, level up, and acquire skills
5. **Evolve** skills through repeated devouring of same-family monsters
6. **Seek** 拟人兽 to obtain 拟人面具 and unlock human form

## Design Decisions

- **Numerical level system** for both player and monsters (not tier-based)
- **Skill families + evolution** — each monster type maps to a skill family; devouring same-family monsters levels up that skill through 3 tiers
- **Human form as evolved form** — unlocked via 拟人面具, provides stat boosts and extra skill slots; existing transform forms become human evolution stages
- **Repackage existing systems** — weapons become skill visual skins, transforms become human evolution stages, evolution branches become passive skill trees

---

## 1. Level System

### Player Level

- Start at level 1, no max cap (soft cap at 50 for balancing)
- XP curve: `xpNeeded = 10 + (level - 1) * 5` (level 1→2 = 10 XP, 2→3 = 15 XP, etc.)
- On level up: +2 max HP (heal 2), +0.3 speed, +1 base damage
- Devouring grants XP based on monster level: `xp = 3 + monsterLevel * 2`

### Monster Level

- All enemies spawn with a level (1-10 scale)
- Level distribution by chunk distance from spawn:
  - Chunks 0-2: level 1-2
  - Chunks 3-5: level 2-4
  - Chunks 6-8: level 3-6
  - Chunks 9+: level 5-10
- Boss level = chunk difficulty + 3 (minimum 5)
- Stat scaling per level:
  - HP: `baseHP * (1 + (level - 1) * 0.3)` — level 5 monster has 2.2x base HP
  - Damage: `baseDamage + floor(level / 3)` — +1 damage per 3 levels
  - Speed: `baseSpeed * (1 + (level - 1) * 0.05)` — +5% speed per level
  - Size: `baseSize + floor(level / 4)` — +1 size per 4 levels (visual only)
- Level displayed as number overlay above enemy (color-coded: white=same, red=higher, green=lower)

---

## 2. Devour Mechanic

### Devour Conditions

| Target | HP Threshold | Notes |
|--------|-------------|-------|
| Same or lower level monster | < 15% HP | Standard devour |
| Higher level monster | < 10% HP | Harder to devour stronger foes |
| Boss | < 5% HP | Very hard, high reward |
| 拟人兽 | < 8% HP | Special: drops mask fragment |

### Devour Execution

- Player moves within 20px of weakened monster and presses attack button
- If conditions met: monster is consumed (entity deactivated), devour animation plays (200ms absorb effect)
- If conditions not met: normal attack executes instead
- Cannot devour while engulfed by another enemy

### Devour Rewards

- **XP**: `3 + monsterLevel * 2`
- **Skill chance**: 30% base chance to acquire a skill from the monster's skill family
  - If player already has this family's skill: +2 skill XP (toward next tier)
  - If player doesn't have this family's skill: grants tier 1 of that family
  - Higher-level monsters increase skill chance: `30% + monsterLevel * 2%` (cap 60%)
- **Material drops**: Still drop based on biome/boss type (existing loot system preserved)
- **Transform energy**: +5 per devour (if in human form)

---

## 3. Skill System

### Skill Families

Each monster type maps to one skill family:

| Monster Type | Skill Family | Tier 1 (Basic) | Tier 2 (Enhanced) | Tier 3 (Ultimate) |
|-------------|-------------|----------------|--------------------|--------------------|
| GRAY_SLIME | Bounce (弹跳) | Bounce Shot: fire a bouncing projectile (3 bounces, 2 dmg) | Super Bounce: 5 bounces, 4 dmg, splits on last bounce | Mega Bounce: 8 bounces, 6 dmg, each bounce creates shockwave |
| PURPLE_SLIME | Corrosion (腐蚀) | Acid Spit: ranged acid projectile (3 dmg + 2 DoT 3s) | Corrosive Cloud: AoE cloud 60px radius, 2 dmg/s 5s | Melting Aura: passive aura 80px, 3 dmg/s, reduces enemy armor |
| RED_SLIME | Fire (火焰) | Fireball: straight projectile (4 dmg, explodes 30px) | Flame Wave: cone attack 60px, 3 dmg + burn 2s | Inferno: large AoE 100px, 5 dmg, 3s burn |
| BLUE_SLIME | Ice (冰霜) | Ice Shard: slow projectile (2 dmg, slows 30% 3s) | Frost Nova: AoE freeze 50px, 2 dmg, slow 50% 4s | Blizzard:持续 AoE 120px, 1 dmg/s, slow 70%, 6s |
| YELLOW_SLIME | Lightning (雷电) | Spark: instant hit 40px range (3 dmg, chain to 1 nearby) | Chain Lightning: 3 targets, 4 dmg each | Thunder Storm: 5 targets, 5 dmg, stun 0.5s |
| GHOST_SLIME | Void (虚空) | Void Pulse: short range AoE 30px (2 dmg, teleport behind target) | Shadow Step: blink 80px + 3 dmg at destination | Void Collapse: pull enemies 100px toward center, 4 dmg |

### Skill Progression

- Each family has 3 tiers, requiring skill XP to level up
- Skill XP gained: +2 per devour of same-family monster, +1 per devour of any monster
- Tier thresholds: Tier 1→2 = 10 skill XP, Tier 2→3 = 25 skill XP
- Skill tier affects damage, range, AoE size per the table above

### Skill Slots

- **Base slime form**: 1 active skill + 1 passive skill
- **Human form**: 3 active skills + 2 passive skills
- Active skills: player cycles through with skill button, uses with attack button
- Passive skills: always active, modify stats/behavior

### Passive Skills (from Evolution Branches)

Existing evolution branches become passive skill trees:

| Branch | Passive Effect |
|--------|---------------|
| Crystal (水晶) | +10% skill damage per level, reflect 5% melee damage |
| Flame (烈焰) | +15% fire skill damage, burn lasts +1s |
| Shadow (暗影) | +10% crit chance (2x damage), +15% dash distance |
| Toxin (毒素) | +20% DoT damage, poison heals player for 10% of damage dealt |
| Tide (潮汐) | +10% HP regen, +15% slow effect duration |

Passive levels: 0-3, each level requires evolution materials (same cost structure as current system).

---

## 4. Human Form (拟人形态)

### 拟人兽 (Humanoid Beast)

- Rare elite enemy, 2% spawn chance in place of normal enemies
- Level = chunk difficulty + 2, stats scaled per monster level system
- Visual: slime with humanoid features (upright posture, face-like markings)
- Behavior: actively hunts player, uses basic attack skills
- On death: drops 1 拟人面具碎片 (Mask Fragment)
- 3 fragments required to craft 拟人面具 (Humanoid Mask)

### 拟人面具

- Crafted automatically when 3 fragments collected
- Appears in inventory as a usable item
- Using the mask: unlocks human form transformation (replaces current transform system)

### Human Form Stages

Existing transform forms become human evolution stages:

| Current Form | New Name | Unlock | Stat Bonus | Special |
|-------------|----------|--------|------------|---------|
| SLIME | 初拟态 (Proto-Human) | Mask obtained | +30% HP, +20% speed | 2 active slots, 1 passive slot |
| GHOST | 幽灵态 (Phantom) | + 5 void cores | +40% HP, +30% speed, phase through walls | 3 active slots, 1 passive slot |
| ARMOR | 铠甲态 (Armored) | + 5 crystal cores | +50% HP, +30% speed, +20% damage reduction | 3 active slots, 2 passive slots |
| IRON_MAN | 完全体 (Complete) | + 5 flame cores + 5 abyss cores | +60% HP, +40% speed, +40% attack | 3 active slots, 3 passive slots |

### Human Form Mechanics

- Transform uses energy system (same as current: max 100, drains per second in form)
- Energy regen: +1/sec passive, +5 per devour, +1 per XP orb
- Cooldown: 10s after energy depletion
- Visual: humanoid character (reuse existing gender-less humanoid sprite)
- Each stage has unique movement/attack behavior (preserved from current transform system)

---

## 5. System Mapping (Old → New)

### Weapons → Skill Visual Skins

- WeaponForm enum becomes SkillVisual enum
- Each skill family has a default visual; evolution changes the visual
- Weapon form stats (range, width, duration, cooldown) now derived from active skill tier
- Unlocking weapon forms = unlocking skill visual variants (cosmetic)

### Transform → Human Form Evolution

- TransformComponent fields preserved, semantics renamed
- transformForm: NONE → SLIME(初拟态) → GHOST(幽灵态) → ARMOR(铠甲态) → IRON_MAN(完全体)
- Transform cores → evolution cores (drop from specific bosses)
- Transform energy → human form energy (same mechanic)

### Evolution → Passive Skill Tree

- EvolutionComponent fields preserved, semantics renamed
- evolutionBranch → passiveTree (Crystal/Flame/Shadow/Toxin/Tide)
- evolutionLevel → passiveLevel (0-3)
- Material costs preserved (ore + cores)
- Effects applied as stat modifiers in relevant systems

---

## 6. Removed/Deprecated Systems

### Gender System

- Remove GenderType enum usage
- Remove CharacterSelectPage gender selection
- Player is always a slime (no gender)
- Human form uses a single default humanoid sprite
- SaveData.gender field deprecated (kept for save compat, ignored on load)

### Direct Combat System

- PlayerCombatSystem's weapon-based damage replaced by skill-based damage
- Attack button triggers equipped active skill (or basic bump if no skill)
- Weapon form selection replaced by skill slot selection

---

## 7. New Constants

```
// Devour
DEVOUR_RANGE = 20
DEVOUR_ANIM_DURATION = 200
DEVOUR_BASE_SKILL_CHANCE = 0.3
DEVOUR_SKILL_CHANCE_PER_LEVEL = 0.02
DEVOUR_SKILL_CHANCE_CAP = 0.6
DEVOUR_ENERGY_GAIN = 5

// Monster Level
MONSTER_MIN_LEVEL = 1
MONSTER_MAX_LEVEL = 10
MONSTER_HP_SCALE_PER_LEVEL = 0.3
MONSTER_SPEED_SCALE_PER_LEVEL = 0.05
MONSTER_DAMAGE_PER_3_LEVELS = 1
MONSTER_SIZE_PER_4_LEVELS = 1

// Player Level
PLAYER_LEVEL_BASE_XP = 10
PLAYER_LEVEL_XP_INCREMENT = 5
PLAYER_HP_PER_LEVEL = 2
PLAYER_SPEED_PER_LEVEL = 0.3
PLAYER_DAMAGE_PER_LEVEL = 1

// Skill
SKILL_FAMILY_COUNT = 6
SKILL_TIER_COUNT = 3
SKILL_XP_PER_DEVOUR_SAME = 2
SKILL_XP_PER_DEVOUR_OTHER = 1
SKILL_TIER_2_XP = 10
SKILL_TIER_3_XP = 25
PLAYER_ACTIVE_SLOTS_BASE = 1
PLAYER_PASSIVE_SLOTS_BASE = 1

// Human Form
HUMANOID_SPAWN_CHANCE = 0.02
MASK_FRAGMENTS_NEEDED = 3
MASK_FRAGMENT_DROP_CHANCE = 1.0  // 拟人兽 always drops

// Devour HP Thresholds
DEVOUR_THRESHOLD_SAME_LEVEL = 0.15
DEVOUR_THRESHOLD_HIGHER_LEVEL = 0.10
DEVOUR_THRESHOLD_BOSS = 0.05
DEVOUR_THRESHOLD_HUMANOID = 0.08
```

---

## 8. New Enums

```
// Skill family (maps to monster type)
SkillFamily: BOUNCE(0), CORROSION(1), FIRE(2), ICE(3), LIGHTNING(4), VOID(5)

// Skill tier
SkillTier: NONE(0), TIER_1(1), TIER_2(2), TIER_3(3)

// Devour state
DevourState: IDLE(0), DEVOURING(1), COOLDOWN(2)

// Human form stage (replaces TransformForm semantics)
HumanFormStage: NONE(-1), PROTO(0), PHANTOM(1), ARMORED(2), COMPLETE(3)

// Skill visual (replaces WeaponForm)
SkillVisual: DEFAULT(0), CRYSTAL(1), FLAME(2), SHADOW(3), TOXIN(4), TIDE(5)
```

---

## 9. New Components

### LevelComponent
```
level: number = 1
xp: number = 0
```

### SkillComponent
```
activeSkills: SkillSlot[] = []    // { family, tier, visual }
passiveSkills: PassiveSlot[] = [] // { branch, level }
activeSlotCount: number = 1
passiveSlotCount: number = 1
selectedActiveIndex: number = 0
skillCooldown: number = 0
```

### DevourComponent
```
state: number = 0  // DevourState
devourTimer: number = 0
devourTarget: number = -1  // entity id
```

### HumanFormComponent (replaces TransformComponent semantics)
```
isHumanForm: boolean = false
humanFormStage: number = -1  // HumanFormStage
hasMask: boolean = false
maskFragments: number = 0
formEnergy: number = 0
formMaxEnergy: number = 100
formCooldown: number = 0
```

---

## 10. New Systems

### DevourSystem
- Checks devour conditions when player attacks near weakened monster
- Consumes monster entity, grants XP/skill chance
- Manages devour animation state

### SkillSystem
- Manages skill activation, cooldowns, damage calculation
- Handles skill tier progression
- Applies passive skill modifiers to other systems

### MonsterLevelSystem
- Scales enemy stats based on level at spawn time
- Sets initial level based on chunk distance
- Applies level-based HP/damage/speed/size modifiers

### HumanoidBeastSystem
- Manages 拟人兽 spawn chance (2% replacement)
- Handles mask fragment drops
- Auto-crafts mask when 3 fragments collected

---

## 11. Modified Systems

### PlayerCombatSystem
- Attack button triggers equipped active skill (or basic bump)
- Damage calculated from skill tier + player level + passive modifiers
- Devour check takes priority over attack when conditions met

### EnemyAISystem
- Reads level from LevelComponent for behavior scaling
- Higher-level monsters are more aggressive
- 拟人兽 has unique AI (hunt player, use basic skills)

### XpLevelSystem
- XP curve changed to `10 + (level-1) * 5`
- Level up grants +2 HP, +0.3 speed, +1 damage
- Integrates with new LevelComponent

### TransformSystem → HumanFormSystem
- Same energy/cooldown mechanics
- Forms renamed to human evolution stages
- Stage unlock requires mask + evolution cores

### EvolutionSystem → PassiveTreeSystem
- Same material cost structure
- Effects applied as passive modifiers
- Query methods updated for new semantics

### ChunkLoadSystem
- Enemy spawn includes level assignment based on chunk distance
- 2% chance to spawn 拟人兽 instead of normal enemy

### SaveLoadSystem
- Serialize new components (Level, Skill, Devour, HumanForm)
- Handle migration from old save format (gender field deprecated)

---

## 12. UI Changes

### HUD
- Player level displayed next to HP bar
- Active skill icon + cooldown indicator
- Skill slot selector (tap to cycle active skills)
- Devour progress bar (shows when monster is in devour range)

### Enemy Display
- Level number above enemy head (color-coded)
- 拟人兽 has distinct visual (golden glow, upright posture)

### Character Select
- Remove gender selection
- Replace with "New Game" / "Continue" options
- Show slime character preview

---

## 13. File Changes Summary

### New Files
- `components/LevelComponent.ets`
- `components/SkillComponent.ets`
- `components/DevourComponent.ets`
- `components/HumanFormComponent.ets`
- `systems/DevourSystem.ets`
- `systems/SkillSystem.ets`
- `systems/MonsterLevelSystem.ets`
- `systems/HumanoidBeastSystem.ets`
- `systems/HumanFormSystem.ets` (replaces TransformSystem)
- `systems/PassiveTreeSystem.ets` (replaces EvolutionSystem)
- `factories/HumanoidBeastFactory.ets`

### Modified Files
- `GameConstants.ets` — new enums, constants, interfaces
- `GameScene.ets` — register new systems, update render pipeline
- `factories/PlayerFactory.ets` — add new components
- `factories/EnemyFactory.ets` — add level parameter
- `systems/PlayerCombatSystem.ets` — skill-based combat
- `systems/XpLevelSystem.ets` — new XP curve
- `systems/ChunkLoadSystem.ets` — level assignment, 拟人兽 spawn
- `systems/SaveLoadSystem.ets` — new component serialization
- `renderers/PlayerRenderer.ets` — slime + human form rendering
- `renderers/EnemyRenderer.ets` — level display, 拟人兽 visual
- `renderers/UIRenderer.ets` — level display, skill HUD
- `pages/CharacterSelectPage.ets` — remove gender, simplify

### Deprecated Files (keep for reference, remove imports)
- `systems/TransformSystem.ets` → replaced by HumanFormSystem
- `systems/EvolutionSystem.ets` → replaced by PassiveTreeSystem
- `components/TransformComponent.ets` → replaced by HumanFormComponent
- `components/EvolutionComponent.ets` → replaced by PassiveTreeComponent (if needed)
