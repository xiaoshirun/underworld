# Underground World Explorer - Expansion Design Specification

## Overview

This document specifies the design for a major expansion to the underground world exploration pixel game. The expansion is built around three core gameplay pillars:

1. **Weapon Form Transformation** — Liquid metal weapon morphs into 6 distinct forms, each with unique combat feel and 3 evolution branches
2. **Traps & Mechanisms** — Environmental hazards and puzzle mechanisms create tension, surprise, and strategic depth throughout the underground world
3. **World Diversity** — 6 biomes with unique terrain, dangers, secrets, and creatures drive endless exploration

There is **no quest/task system**. Players explore freely, discover materials, evolve weapons, and overcome challenges organically. Progression comes from curiosity and skill, not from following objectives.

**Platform:** HarmonyOS ArkTS/ArkUI with Canvas-based game rendering
**Existing Systems:** Chunk-based infinite procedural world generation (32x32 tile chunks, 5 biomes), 6 enemy slime types, player combat/movement/engulf/drill states

### New Biome: Shadow Rift

The existing BiomeType enum has 5 biomes (NORMAL, CRYSTAL, MUSHROOM, WATER, LAVA) but only 4 have bosses. The expansion adds a 6th biome — **Shadow Rift (暗影裂隙)** — to host the Void Rift boss. This biome features dark terrain, floating void particles, and shadow-themed enemies.

```typescript
// Add to existing BiomeType enum
enum BiomeType {
  NORMAL = 0,
  CRYSTAL = 1,
  MUSHROOM = 2,
  WATER = 3,
  LAVA = 4,
  SHADOW = 5    // NEW: Shadow Rift biome
}
```

Biome-Boss mapping:

| Biome | Boss | Boss Type |
|-------|------|-----------|
| NORMAL | (No boss - starting area, safer) | — |
| CRYSTAL | Crystal Guardian | Passage Guardian |
| MUSHROOM | Mushroom King | Optional Challenge |
| WATER | Abyss Siren | Passage Guardian |
| LAVA | Lava Beast | Optional Challenge |
| SHADOW | Void Rift | Passage Guardian |

Boss types: **Passage Guardians** block key passages and must be defeated to progress deeper. **Optional Challenges** roam the biome and can be fought for rare rewards or avoided entirely.

---

## 1. Character Selection System

### 1.1 Purpose

Provide players with a character choice before entering the game world. The choice is purely cosmetic with no gameplay impact.

### 1.2 Character Options

| Character | Visual Description |
|-----------|-------------------|
| Male | Broader shoulders, shorter hair, blue-toned outfit |
| Female | Narrower build, longer hair, purple-toned outfit |

### 1.3 Implementation

- New page `CharacterSelectPage` inserted between `LoginPage` and game world
- Two character previews rendered on Canvas with idle animations
- Tap to select, confirm button to proceed
- Selection stored in `PlayerState.gender: GenderType`
- Gender affects only the player rendering function (sprite proportions, hair, color palette)

### 1.4 Page Flow

```
LoginPage -> CharacterSelectPage -> GameWorld (Index)
```

---

## 2. Dual Weapon System

### 2.1 Concept

The player carries two tools:
- **Drill (Tool Slot):** Path-clearing tool for breaking walls, not used for combat
- **Liquid Metal Weapon (Weapon Slot):** Main combat weapon that morphs into different forms

### 2.2 Weapon Forms (6 Total)

| Form | Chinese | Attack Style | Range | Speed |
|------|---------|-------------|-------|-------|
| Blade (直刃剑) | 直刃剑 | Straight slash | Medium | Medium |
| Whip (链鞭) | 链鞭 | Long reach whip | Long | Fast |
| Hammer (重锤) | 重锤 | Ground slam | Short | Slow |
| Staff (法杖) | 法杖 | Ranged magic bolt | Very Long | Medium |
| Dual Blades (双刃) | 双刃 | Double slash | Short | Very Fast |
| Great Axe (巨斧) | 巨斧 | Wide arc cleave | Medium | Slow |

### 2.3 Unlock Progression

- Player starts with only **Blade (直刃剑)** unlocked
- Remaining 5 forms require **Form Core (形态核心)** to unlock
- Form Cores are found in Elite Chests and Boss Chests scattered throughout the world
- Once unlocked, forms can be freely switched at any time

### 2.4 Controls

- **Attack Button:** Uses current liquid metal weapon form
- **Tool Button (Independent):** Activates drill to break the wall tile the player is facing
- Drill has its own cooldown and hit-count mechanic (already partially implemented)

---

## 3. Weapon Evolution System

### 3.1 Structure

Each weapon form has **5 evolution branches**, each with **3 upgrade levels**:

```
Base Form (Lv0)
  ├── Branch A -> Lv1 -> Lv2 -> Lv3 (Ultimate)
  ├── Branch B -> Lv1 -> Lv2 -> Lv3 (Ultimate)
  ├── Branch C -> Lv1 -> Lv2 -> Lv3 (Ultimate)
  ├── Branch D -> Lv1 -> Lv2 -> Lv3 (Ultimate)
  └── Branch E -> Lv1 -> Lv2 -> Lv3 (Ultimate)
```

Total: 6 forms x 5 branches x 3 levels = **90 evolution nodes**

### 3.2 Evolution Branches (Example: Blade)

| Branch | Theme | Visual | Required Ore |
|--------|-------|--------|-------------|
| Crystal (冰晶) | Ice/Lightning | Blue-white crystalline blade | CRYSTAL_ORE |
| Flame (火焰) | Fire/Explosion | Red-orange flaming blade | FLAME_ORE |
| Shadow (暗影) | Dark/Void | Purple-black shadow blade | VOID_ORE |
| Toxin (毒素) | Poison/Nature | Green-purple toxic blade | MUSHROOM_ORE |
| Tide (潮汐) | Water/Electric | Deep blue electric blade | ABYSS_ORE |

### 3.3 Material System

Two complementary resource types required for evolution, both obtained through exploration:

**Rare Ores (稀有矿石)** — Dropped by bosses:

| Ore | Source Boss | Biome |
|-----|------------|-------|
| CRYSTAL_ORE (蓝晶矿) | Crystal Guardian | Crystal Cave |
| MUSHROOM_ORE (菌核矿) | Mushroom King | Mushroom Forest |
| FLAME_ORE (炎心矿) | Lava Beast | Lava Abyss |
| ABYSS_ORE (渊珠矿) | Abyss Siren | Underwater Temple |
| VOID_ORE (虚空矿) | Void Rift | Shadow Rift |

**Evolution Cores (进化核心)** — Found in treasure chests:

| Core | Source | Purpose |
|------|--------|---------|
| CORE_NORMAL (普通进化核心) | Normal Chests | Lv0 -> Lv1, Lv1 -> Lv2 |
| CORE_RARE (稀有进化核心) | Elite/Boss Chests | Lv2 -> Lv3 |
| FORM_CORE (形态核心) | Elite/Boss Chests | Unlock new weapon forms |

### 3.4 Evolution Costs

| Upgrade | Normal Cores | Rare Cores | Ore |
|---------|-------------|-----------|-----|
| Base -> Lv1 | 3 | 0 | 2 |
| Lv1 -> Lv2 | 0 | 1 | 4 |
| Lv2 -> Lv3 | 0 | 2 | 6 |

### 3.5 Evolution Rules

- Player chooses one branch per weapon form (can switch branches later at 50% material refund)
- Materials are consumed on evolution
- Evolution is permanent for that form (can evolve other forms independently)
- Visual changes at each level (more elaborate weapon appearance, particle effects)
- No quest gates — evolution is available whenever the player has collected enough materials

### 3.6 Branch-to-Ore Mapping

Each evolution branch maps to a specific ore type. The branch determines which boss the player must farm:

| Branch | Ore Type | Boss |
|--------|----------|------|
| CRYSTAL | CRYSTAL_ORE | Crystal Guardian |
| FLAME | FLAME_ORE | Lava Beast |
| SHADOW | VOID_ORE | Void Rift |
| TOXIN | MUSHROOM_ORE | Mushroom King |
| TIDE | ABYSS_ORE | Abyss Siren |

(Other weapon forms follow similar thematic mapping)

---

## 4. Trap & Mechanism System

### 4.1 Design Philosophy

Traps and mechanisms are the backbone of exploration tension and strategic depth. They come in two categories:

- **Environmental Hazards (环境陷阱):** Instant-danger obstacles that test player reflexes and awareness
- **Puzzle Mechanisms (机关谜题):** Interactive elements that reward observation and creative thinking

Both types are biome-themed to reinforce world diversity. Players encounter them naturally while exploring — no quest markers or waypoints needed.

### 4.2 Environmental Hazards

Environmental hazards deal damage or apply debuffs. They follow telegraph patterns so skilled players can learn and dodge them.

#### 4.2.1 Ground Spikes (地刺)

**Biomes:** NORMAL, CRYSTAL
**Behavior:** Sharp spikes erupt from the floor in a 2-3 tile line. A 0.5s crack animation telegraphs the eruption zone before spikes appear. Spikes remain extended for 1.5s then retract for 2s before cycling.
**Damage:** 1 HP on contact with extended spikes.
**Visual:** Stone-colored spikes with biome-tinted crystal tips.

#### 4.2.2 Falling Rocks (落石)

**Biomes:** NORMAL, MUSHROOM, SHADOW
**Behavior:** When player steps on a trigger tile, 2-4 rock projectiles fall from the ceiling after a 0.3s dust warning. Rocks land in a 3x3 area around the trigger and create temporary debris (slows movement for 1s).
**Damage:** 2 HP per rock hit.
**Visual:** Gray-brown rocks with dust particle effects on impact.

#### 4.2.3 Poison Spores (毒孢子)

**Biomes:** MUSHROOM
**Behavior:** Mushroom patches on walls periodically (every 4s) release a cloud of spore particles that drift across a 5-tile radius. Spore clouds persist for 3s. Player inside cloud takes 1 HP every 1s and gets a green tint overlay.
**Damage:** 1 HP/tick while inside cloud.
**Visual:** Purple-green floating particles with fading opacity.

#### 4.2.4 Lava Geysers (熔岩喷泉)

**Biomes:** LAVA
**Behavior:** Random floor tiles show a bubbling animation for 0.8s (warning), then erupt a column of lava 3 tiles high lasting 1.5s. Eruption positions are random within the chunk but avoid player's exact tile.
**Damage:** 2 HP on contact.
**Visual:** Orange-red lava column with splash particles.

#### 4.2.5 Void Cracks (虚空裂缝)

**Biomes:** SHADOW
**Behavior:** Invisible until activated. Player walking over a hidden tile triggers a crack animation — the floor splits open revealing a void rift that pulls the player toward its center for 2s. Player takes 1 HP/s while being pulled. Can escape by dashing away.
**Damage:** 1 HP/s + forced movement toward center.
**Visual:** Dark purple crack lines spreading from center, then a glowing void pit.

#### 4.2.6 Water Vortex (水漩涡)

**Biomes:** WATER
**Behavior:** Whirlpool tiles that appear in water areas. When player enters a vortex tile, they are pulled to the center and teleported to a connected vortex elsewhere (can be helpful or harmful — some lead to secret areas, some to danger zones).
**Damage:** None (teleportation mechanic).
**Visual:** Spinning blue-white water animation.

### 4.3 Puzzle Mechanisms

Puzzle mechanisms are interactive elements the player must activate in the right order or use creatively to unlock paths, reveal secrets, or obtain rewards.

#### 4.3.1 Pressure Plate (压力板)

**Behavior:** Floor tile that activates when player stands on it. Deactivates when player leaves. Can be weighted (stays active permanently after first step) or spring-loaded (deactivates on leave).
**Usage:** Opens connected doors, triggers spike traps, activates platforms.
**Visual:** Slightly raised floor tile with biome-colored markings. Glows when pressed.

#### 4.3.2 Lever (拉杆)

**Behavior:** Wall-mounted switch. Toggle on/off. Each lever controls one connected mechanism (door, bridge, trap). Some levers are paired — pulling one extends the other's connected element.
**Usage:** Open secret passages, disable trap corridors, raise bridges over gaps.
**Visual:** Stone pillar with a glowing crystal handle. Handle rotates on toggle.

#### 4.3.3 Push Block (推箱)

**Behavior:** Movable stone block. Player pushes it by walking into it. Block slides in the push direction until hitting a wall or another block. Can be placed on pressure plates to keep them active.
**Usage:** Weight pressure plates, block spike paths, build stairs to reach higher areas.
**Visual:** Carved stone block with rune markings. Scrapes dust particles when pushed.

#### 4.3.4 Crystal Reflector (水晶反射镜)

**Behavior:** Rotatable crystal that redirects a beam of light. Light sources are fixed. When a beam hits a receptor (another crystal or door mechanism), it activates the connected element. Multiple crystals can chain to create light paths.
**Usage:** Unlock crystal biome secrets, power door mechanisms, reveal hidden platforms.
**Visual:** Hexagonal crystal that glows when hit by beam. Beam is a colored light line.

#### 4.3.5 Breakable Wall (可破坏墙壁)

**Behavior:** Wall tiles that look slightly different (cracks, different color). Can be destroyed by drill tool or hammer weapon. Often hides secret rooms with chests or shortcuts.
**Usage:** Hidden exploration rewards, shortcuts between areas.
**Visual:** Wall tile with visible crack lines. Subtle color difference from normal walls.
**Note:** Drill tool destroys in 3 hits (existing mechanic). Hammer weapon destroys in 1 hit but uses durability.

#### 4.3.6 Teleport Rune (传送符文)

**Behavior:** Floor rune that teleports player to a paired rune when stepped on. Pairs are always within the same biome. One rune in a pair has blue glow (entry), the other has green glow (exit).
**Usage:** Fast travel within biomes, access hidden areas, escape dangerous situations.
**Visual:** Circular rune pattern on floor with rotating glyph animation.

### 4.4 Biome Trap Distribution

Each biome has a unique trap/mechanism identity that reinforces its theme:

| Biome | Primary Hazards | Primary Mechanisms | Theme |
|-------|----------------|-------------------|-------|
| NORMAL | Ground Spikes, Falling Rocks | Pressure Plates, Push Blocks, Breakable Walls | Tutorial — simple patterns |
| CRYSTAL | Ground Spikes (crystal) | Crystal Reflectors, Pressure Plates | Light puzzles |
| MUSHROOM | Poison Spores, Falling Rocks | Levers, Push Blocks | Navigation through hazards |
| WATER | Water Vortexes | Levers, Teleport Runes | Flow control, teleportation |
| LAVA | Lava Geysers, Falling Rocks | Pressure Plates, Levers | Timing challenges |
| SHADOW | Void Cracks | Teleport Runes, Crystal Reflectors | Disorientation, hidden paths |

### 4.5 Trap/Room Generation

Traps and mechanisms are generated as part of chunk decoration in `WorldGenerator`:

- **Hazard density** increases with distance from spawn (deeper = more dangerous)
- **Puzzle rooms** are pre-designed small layouts (5x5 to 8x8 tiles) placed randomly in chunks
- **Trap corridors** are 1-wide passages with timed hazards — reward careful timing
- **Secret rooms** are always behind breakable walls, containing Elite Chests or rare materials
- **Trigger zones** are stored per-chunk and checked against player position each frame

### 4.6 Trap State Data

```typescript
enum TrapType {
  GROUND_SPIKES = 0,
  FALLING_ROCKS = 1,
  POISON_SPORES = 2,
  LAVA_GEYSER = 3,
  VOID_CRACK = 4,
  WATER_VORTEX = 5
}

enum MechanismType {
  PRESSURE_PLATE = 0,
  LEVER = 1,
  PUSH_BLOCK = 2,
  CRYSTAL_REFLECTOR = 3,
  BREAKABLE_WALL = 4,
  TELEPORT_RUNE = 5
}

enum TrapState {
  IDLE = 0,       // Waiting for trigger
  TELEGRAPH = 1,  // Warning animation before activation
  ACTIVE = 2,     // Dealing damage/effect
  COOLDOWN = 3    // Resetting before next cycle
}

interface TrapInstance {
  x: number;
  y: number;
  trapType: TrapType;
  state: TrapState;
  timer: number;
  triggerRadius: number;
  damage: number;
  size: number;
  extraData: number[];  // Type-specific: direction, pair index, etc.
}

interface MechanismInstance {
  x: number;
  y: number;
  mechanismType: MechanismType;
  active: boolean;       // Current on/off state
  linkedIndex: number;   // Index of connected trap/door/element
  rotation: number;      // For crystal reflectors (angle in degrees)
  pushable: boolean;     // For push blocks
  posX: number;          // Current position (for push blocks)
  posY: number;
}

interface SecretRoom {
  chunkX: number;
  chunkY: number;
  wallTileX: number;     // Breakable wall position
  wallTileY: number;
  revealed: boolean;     // Whether wall has been destroyed
  chestType: ChestType;  // What's inside
}
```

---

## 5. Boss System

### 5.1 Overview

5 bosses distributed across the 5 special biomes. Bosses serve two roles:

- **Passage Guardians (守卫者):** Block critical passages that lead deeper into the world. Player MUST defeat them to progress. These are encountered in sealed Boss Rooms.
- **Optional Challenges (挑战者):** Roam the biome as powerful enemies. Player can fight them for rare rewards or avoid them entirely. These are encountered in the open world.

### 5.2 Boss Classification

| Boss | Biome | Type | Role |
|------|-------|------|------|
| Crystal Guardian | CRYSTAL | Passage Guardian | Blocks path to deeper Crystal Caves |
| Mushroom King | MUSHROOM | Optional Challenge | Roams Mushroom Forest, drops rare spore materials |
| Lava Beast | LAVA | Optional Challenge | Roams Lava Abyss, drops rare flame materials |
| Abyss Siren | WATER | Passage Guardian | Blocks path to Underwater Temple depths |
| Void Rift | SHADOW | Passage Guardian | Blocks path to Shadow Rift core |

### 5.3 Passage Guardian Boss Rooms

- Triggered when player enters a sealed chamber in the biome
- Room is ~15x15 tiles with a clear entrance
- Upon entry, the entrance seals (wall tiles close behind player)
- Boss must be defeated to open the exit
- After defeat, a Boss Chest spawns at the boss's death location
- The passage beyond leads to deeper, more dangerous terrain with better loot

### 5.4 Optional Challenge Bosses

- Spawn as large enemies in the open biome
- Have a visible aura/glow that distinguishes them from regular enemies
- Player can walk past them — they are not aggressive unless player enters their aggro radius (120 pixels)
- If player dies to them, they can retry later (boss respawns after leaving and re-entering the chunk)
- Drop the same rare ore as Passage Guardians, plus a chance for rare evolution cores

### 5.5 Boss Designs

#### Boss 1: Crystal Guardian (晶岩守卫) - Crystal Cave [Passage Guardian]

**Appearance:** Humanoid figure made of crystal clusters, with a pulsing core crystal embedded in the chest. Core glows bright blue during attacks.

**Combat Mechanics:**
- **Phase 1 (HP > 50%):** Slow movement. Every 3s fires "Crystal Barrage" - 5 crystal projectiles in a fan pattern from the core.
- **Phase 2 (HP <= 50%):** Core exposed, movement speed increases. New ability "Crystal Spikes" - random positions on the ground spawn crystal spikes, requiring dodge.
- **Drops:** CRYSTAL_ORE x2-3

#### Boss 2: Mushroom King (菌王) - Mushroom Forest [Optional Challenge]

**Appearance:** Giant mushroom creature with a cap that releases spore smoke. Multiple tendril-like mycelia extend from the stem.

**Combat Mechanics:**
- **Passive:** "Spore Fog" - persistent poison area around boss. Players inside take 1 HP every 2s, forcing movement.
- **Every 4s:** "Mycelium Bind" - 3 mycelia extend from ground toward player. Contact causes 50% slow for 2s.
- **Phase 2:** Summons 2-3 mini mushroom creatures (HP=2 each) as distractions.
- **Drops:** MUSHROOM_ORE x2-3

#### Boss 3: Lava Beast (熔岩巨兽) - Lava Abyss [Optional Challenge]

**Appearance:** Massive creature made of flowing lava. Molten rock drips from its body. Core is white-hot energy.

**Combat Mechanics:**
- **Phase 1:** Slow but large attack range. Each melee hit leaves "Lava Ground" (damaging area lasting 3s).
- **Phase 2 (HP <= 40%):** "Explosive Mode" - Every 5s body explodes, shooting 8 lava projectiles in all directions. Boss temporarily splits into 2 smaller entities (each 50% HP). Must kill quickly or they merge back.
- **Environmental:** Random lava eruption points on room floor.
- **Drops:** FLAME_ORE x2-3

#### Boss 4: Abyss Siren (深渊海妖) - Underwater Temple [Passage Guardian]

**Appearance:** Translucent jellyfish form with extremely long tentacles carrying electric sparks. A rotating deep-sea pearl visible inside the body.

**Combat Mechanics:**
- Floats above ground, ranged attacks only.
- **"Lightning Chain":** Lightning bolt that jumps to a second target. If no second target, damage is doubled.
- **"Tidal Surge":** Every 6s, ring-shaped shockwave pushes player back (knockback effect).
- **Phase 2:** Summons water bubbles that trap player on contact (2s immobilize). Must attack bubble to break free.
- **Drops:** ABYSS_ORE x2-3

#### Boss 5: Void Rift (虚空裂隙) - Shadow Rift [Passage Guardian]

**Appearance:** Constantly shifting mass of dark matter with a glowing rift at the center. Surrounded by debris of consumed objects.

**Combat Mechanics:**
- **Phase 1:** "Blink" every 3s - teleports to random position in room. Leaves void zones (damaging on contact).
- **"Void Pull":** Every 4s, gravity field pulls player toward boss. Combined with void zones for positioning challenge.
- **Phase 2 (HP <= 30%):** "Devour Mode" - Boss size increases 50%, attack range doubles, but blink interval increases to 5s. New ability "Shadow Clone" - summons a mirror image that takes 3 hits to destroy.
- **Drops:** VOID_ORE x2-3

### 5.6 Boss State Data

```typescript
interface BossState {
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  bossType: BossType;
  bossRole: BossRole;      // PASSAGE_GUARDIAN or OPTIONAL_CHALLENGE
  phase: BossPhase;
  active: boolean;
  defeated: boolean;
  attackTimer: number;
  specialTimer: number;
  hitFlash: number;
  size: number;
  aggroRadius: number;     // Only used by optional challenge bosses
  extraData: number[];     // Boss-specific state
}

enum BossRole {
  PASSAGE_GUARDIAN = 0,
  OPTIONAL_CHALLENGE = 1
}
```

### 5.7 Boss HP Display

- Large HP bar at the top of the screen during boss fight
- Shows boss name and current phase indicator
- Bar color matches boss theme color
- For Passage Guardians: shows "守卫者" tag
- For Optional Challenges: shows "挑战" tag with option to flee

---

## 6. Treasure Chest System

### 6.1 Chest Types

| Type | Chinese | Appearance | Spawn Rate |
|------|---------|-----------|-----------|
| Normal | 木箱 | Wooden box with faint particle glow | ~1 per 2-3 chunks |
| Elite | 铁箱 | Iron box with rune patterns, strong glow | ~1 per 5-8 chunks |
| Boss | 金箱 | Golden ornate chest | 1 per boss (guaranteed drop) |

### 6.2 Normal Chest (木箱)

**Spawn:** Randomly placed in generated chunks across all biomes. Sometimes hidden behind breakable walls.
**Interaction:** Walk up and press interact button. Opens with lid animation + light pillar.
**Loot Table:**
- Evolution Core (Normal) x1-2
- HP Potion x1-2
- Small chance of gold coins

### 6.3 Elite Chest (铁箱)

**Spawn:** Placed in secret rooms behind breakable walls, or in puzzle room reward areas. Surrounded by elite guardian enemies (enhanced slimes with 3x HP).
**Interaction:** Cannot open until all guardians are defeated. Then opens with elaborate animation.
**Loot Table:**
- Evolution Core (Rare) x1
- **Form Core x1** (key item for unlocking new weapon forms)
- Better equipment/potions

### 6.4 Boss Chest (金箱)

**Spawn:** Dropped by boss on death at boss's position.
**Interaction:** Auto-opens with cinematic animation.
**Loot Table:**
- Boss-specific Rare Ore x2-3
- Evolution Core (Rare) x1-2
- Chance for additional Form Core

### 6.5 Chest State Data

```typescript
interface ChestState {
  x: number;
  y: number;
  chestType: ChestType;
  opened: boolean;
  active: boolean;
  guardianDefeated: boolean;
  guardianCount: number;
}
```

---

## 7. Data Model

### 7.1 New Enums

```typescript
enum GenderType {
  MALE = 0,
  FEMALE = 1
}

enum WeaponForm {
  BLADE = 0,       // 直刃剑 (initial unlock)
  WHIP = 1,        // 链鞭
  HAMMER = 2,      // 重锤
  STAFF = 3,       // 法杖
  DUAL_BLADES = 4, // 双刃
  GREAT_AXE = 5    // 巨斧
}

enum EvolutionBranch {
  CRYSTAL = 0,     // 冰晶 - requires CRYSTAL_ORE
  FLAME = 1,       // 火焰 - requires FLAME_ORE
  SHADOW = 2,      // 暗影 - requires VOID_ORE
  TOXIN = 3,       // 毒素 - requires MUSHROOM_ORE
  TIDE = 4         // 潮汐 - requires ABYSS_ORE
}

enum EvolutionLevel {
  BASE = 0,
  LEVEL_1 = 1,
  LEVEL_2 = 2,
  LEVEL_3 = 3
}

enum MaterialType {
  // Boss ores
  CRYSTAL_ORE = 0,
  MUSHROOM_ORE = 1,
  FLAME_ORE = 2,
  ABYSS_ORE = 3,
  VOID_ORE = 4,
  // Evolution cores
  CORE_NORMAL = 5,
  CORE_RARE = 6,
  // Form cores
  FORM_CORE = 7
}

enum ChestType {
  NORMAL = 0,
  ELITE = 1,
  BOSS = 2
}

enum BossType {
  CRYSTAL_GUARDIAN = 0,
  MUSHROOM_KING = 1,
  LAVA_BEAST = 2,
  ABYSS_SIREN = 3,
  VOID_RIFT = 4
}

enum BossPhase {
  PHASE_1 = 0,
  PHASE_2 = 1
}

enum BossRole {
  PASSAGE_GUARDIAN = 0,
  OPTIONAL_CHALLENGE = 1
}

enum TrapType {
  GROUND_SPIKES = 0,
  FALLING_ROCKS = 1,
  POISON_SPORES = 2,
  LAVA_GEYSER = 3,
  VOID_CRACK = 4,
  WATER_VORTEX = 5
}

enum MechanismType {
  PRESSURE_PLATE = 0,
  LEVER = 1,
  PUSH_BLOCK = 2,
  CRYSTAL_REFLECTOR = 3,
  BREAKABLE_WALL = 4,
  TELEPORT_RUNE = 5
}

enum TrapState {
  IDLE = 0,
  TELEGRAPH = 1,
  ACTIVE = 2,
  COOLDOWN = 3
}
```

### 7.2 New Interfaces

```typescript
interface WeaponState {
  currentForm: WeaponForm;
  unlockedForms: WeaponForm[];
  evolutionData: FormEvolutionData[];  // Indexed by WeaponForm enum value
}

interface FormEvolutionData {
  branch: EvolutionBranch;
  level: EvolutionLevel;
  oreCount: number;
  coreNormalCount: number;
  coreRareCount: number;
}

interface Inventory {
  materialOres: number[];      // Indexed by MaterialType (0-4 for ores)
  materialCores: number[];     // Indexed by MaterialType (5-7 for cores)
  hpPotions: number;
  gold: number;
}

interface BossRoom {
  chunkX: number;
  chunkY: number;
  bossType: BossType;
  entered: boolean;
  defeated: boolean;
  chestSpawned: boolean;
}

interface BossState {
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  bossType: BossType;
  bossRole: BossRole;
  phase: BossPhase;
  active: boolean;
  defeated: boolean;
  attackTimer: number;
  specialTimer: number;
  hitFlash: number;
  size: number;
  aggroRadius: number;
  extraData: number[];
}

interface ChestState {
  x: number;
  y: number;
  chestType: ChestType;
  opened: boolean;
  active: boolean;
  guardianDefeated: boolean;
  guardianCount: number;
}

interface TrapInstance {
  x: number;
  y: number;
  trapType: TrapType;
  state: TrapState;
  timer: number;
  triggerRadius: number;
  damage: number;
  size: number;
  extraData: number[];
}

interface MechanismInstance {
  x: number;
  y: number;
  mechanismType: MechanismType;
  active: boolean;
  linkedIndex: number;
  rotation: number;
  pushable: boolean;
  posX: number;
  posY: number;
}

interface SecretRoom {
  chunkX: number;
  chunkY: number;
  wallTileX: number;
  wallTileY: number;
  revealed: boolean;
  chestType: ChestType;
}
```

### 7.3 Extended Existing Interfaces

```typescript
// PlayerState additions
interface PlayerState {
  // ... existing fields preserved ...
  gender: GenderType;
  weapon: WeaponState;
  inventory: Inventory;
  isUsingTool: boolean;
  toolTargetX: number;
  toolTargetY: number;
}

// ChunkData additions
interface ChunkData {
  tiles: number[][];
  enemies: SlimeState[];
  generated: boolean;
  bosses: BossState[];
  chests: ChestState[];
  traps: TrapInstance[];
  mechanisms: MechanismInstance[];
  secretRooms: SecretRoom[];
  isBossRoom: boolean;
}
```

### 7.4 Configuration Constants

```typescript
// Evolution costs by level: [normalCores, rareCores, ore]
const EVOLUTION_COST: number[][] = [
  [0, 0, 0],  // BASE (no cost)
  [3, 0, 2],  // Lv1
  [0, 1, 4],  // Lv2
  [0, 2, 6],  // Lv3 (ultimate)
];

const FORM_UNLOCK_COST: number = 1; // 1 form core per new form

// Boss drop mapping
const BOSS_DROP_TABLE: number[][] = [
  [BossType.CRYSTAL_GUARDIAN, MaterialType.CRYSTAL_ORE],
  [BossType.MUSHROOM_KING, MaterialType.MUSHROOM_ORE],
  [BossType.LAVA_BEAST, MaterialType.FLAME_ORE],
  [BossType.ABYSS_SIREN, MaterialType.ABYSS_ORE],
  [BossType.VOID_RIFT, MaterialType.VOID_ORE],
];

// Branch-to-ore mapping
const BRANCH_ORE_MAP: number[][] = [
  [EvolutionBranch.CRYSTAL, MaterialType.CRYSTAL_ORE],
  [EvolutionBranch.FLAME, MaterialType.FLAME_ORE],
  [EvolutionBranch.SHADOW, MaterialType.VOID_ORE],
  [EvolutionBranch.TOXIN, MaterialType.MUSHROOM_ORE],
  [EvolutionBranch.TIDE, MaterialType.ABYSS_ORE],
];

// Trap configuration
const TRIGGER_DETECT_RANGE: number = 48;
const SPIKE_DAMAGE: number = 1;
const ROCK_DAMAGE: number = 2;
const POISON_DPS: number = 1;
const LAVA_GEYSER_DAMAGE: number = 2;
const VOID_PULL_DPS: number = 1;

// Mechanism configuration
const PUSH_BLOCK_SPEED: number = 2.0;
const PRESSURE_PLATE_RANGE: number = 16;
const TELEPORT_COOLDOWN: number = 2000;
const LEVER_LINK_RANGE: number = 320;

// Boss configuration
const PASSAGE_GUARDIAN_AGGRO: number = 9999;  // Always aggro in room
const OPTIONAL_CHALLENGE_AGGRO: number = 120;
const BOSS_RESPAWN_TIME: number = 60000;  // 60s after leaving chunk
```

---

## 8. System Integration

### 8.1 File Modification Map

| File | Changes |
|------|---------|
| `GameConstants.ets` | Add all new enums, interfaces, constants (trap, mechanism, boss role, etc.) |
| `WorldGenerator.ets` | Boss room generation, chest placement, trap/mechanism generation, secret room placement, Shadow biome terrain |
| `GameEngine.ets` | Boss update/render, chest update/render, trap update/render, mechanism interaction, evolution logic, material drops |
| `Index.ets` | Tool button, evolution panel UI, boss HP bar, trap warning indicators |
| `LoginPage.ets` | Route to CharacterSelectPage instead of game |
| New: `CharacterSelectPage.ets` | Character selection UI |

### 8.2 New Game Engine Methods

```
// Boss system
updateBosses(dt)
renderBoss(c, boss, offX, offY)
renderBossRoom(c, room, offX, offY)
checkBossPhaseTransition(boss)
spawnBossProjectiles(boss)

// Chest system
updateChests(dt)
renderChest(c, chest, offX, offY)
openChest(chest)
spawnChestLoot(chest)

// Trap system
updateTraps(dt)
renderTrap(c, trap, offX, offY)
checkTrapTrigger(trap, playerX, playerY)
applyTrapDamage(trap)

// Mechanism system
updateMechanisms(dt)
renderMechanism(c, mech, offX, offY)
interactWithMechanism(mech)
checkMechanismLinks(mech)
pushBlock(mech, dx, dy)
activateTeleportRune(mech)

// Secret room system
checkBreakableWalls()
revealSecretRoom(room)

// Evolution system
tryEvolveWeapon(form, branch)
canEvolve(form, branch): boolean
unlockWeaponForm(form): boolean
renderEvolutionPanel(c)

// Weapon system
switchWeaponForm(form)
renderWeaponEffect(c, form, level)
```

### 8.3 Game Loop Integration

```
gameLoop() {
  // Existing
  updateInput()
  updatePlayer(dt)
  updateEnemies(dt)
  updateParticles(dt)
  updateXpOrbs(dt)

  // New
  updateBosses(dt)
  updateChests(dt)
  updateTraps(dt)
  updateMechanisms(dt)
  checkBossRoomTriggers()
  checkChestInteraction()
  checkMechanismInteraction()

  // Render
  renderWorld()
  renderTraps()          // Under layer
  renderMechanisms()     // Under layer
  renderChests()
  renderEnemies()
  renderBosses()
  renderPlayer()
  renderParticles()
  renderHUD()
  renderBossHPBar()      // During boss fight
  renderTrapWarnings()   // Telegraph indicators
}
```

### 8.4 Player Flow (Free Exploration)

```
1. Login -> Character Select -> Enter World
2. Explore freely with Blade (only unlocked form)
3. Encounter traps and mechanisms — learn their patterns, solve puzzles
4. Find Normal Chests in the open world -> collect Normal Cores + potions
5. Discover breakable walls -> find secret rooms with Elite Chests -> collect Form Cores
6. Unlock new weapon form (e.g., Whip) — different combat feel for different situations
7. Encounter Passage Guardian boss room -> must defeat to access deeper terrain
8. Encounter Optional Challenge boss in the wild -> fight for rare ores or avoid
9. Collect ores + cores -> open Evolution Panel -> choose branch -> evolve weapon
10. Deeper biomes have harder traps, better chests, stronger bosses
11. Repeat — each biome offers unique traps, mechanisms, and weapon evolution materials
```

---

## 9. Implementation Phases

### Phase 1: Foundation
- Add all new enums and interfaces to GameConstants.ets (including trap/mechanism types)
- Extend PlayerState, ChunkData with trap/mechanism fields
- Create CharacterSelectPage
- Update page routing

### Phase 2: Weapon System
- Implement dual weapon slot logic
- Add tool button to UI
- Implement weapon form switching
- Add visual differences per weapon form (attack animations)

### Phase 3: Trap & Mechanism System
- Environmental hazard generation in WorldGenerator (per-biome themed)
- Trap update/render in GameEngine (state machine: idle -> telegraph -> active -> cooldown)
- Puzzle mechanism generation and interaction
- Push block physics, pressure plate linking, lever connections
- Crystal reflector beam redirection logic
- Teleport rune paired teleportation
- Breakable wall detection and secret room reveal

### Phase 4: Boss System
- Boss room generation for Passage Guardians
- Optional Challenge boss spawning in open biome
- Boss AI and combat mechanics (all 5 bosses)
- Boss rendering (per-boss visual design)
- Boss HP bar UI
- Boss death and loot drop
- Boss respawn after leaving chunk

### Phase 5: Chest System
- Chest placement in WorldGenerator (normal in open, elite in secret rooms)
- Chest rendering (3 types)
- Chest opening interaction and animation
- Loot table logic
- Elite guardian spawning for Elite Chests

### Phase 6: Evolution System
- Inventory management (flat array-based for ArkTS compatibility)
- Evolution panel UI
- Evolution logic and material consumption
- Visual evolution effects per level
- Form unlock flow

### Phase 7: Shadow Biome & Polish
- Shadow Rift biome terrain generation
- Shadow-specific traps (Void Cracks) and mechanisms
- Full game loop integration
- Balance tuning (trap damage, boss difficulty, drop rates)
- Particle effects for traps, mechanisms, evolution, boss attacks, chest opening
- Sound effect hooks

---

## 10. Balance Considerations

- **Trap damage** scales with biome depth — early game traps are forgiving, deep game traps are lethal
- **Puzzle complexity** increases with biome — NORMAL biome has single-step puzzles, SHADOW has multi-step chains
- **Boss difficulty** matches biome danger level; Optional Challenge bosses are harder than Passage Guardians
- Normal chests provide enough cores for steady progression through exploration
- Elite chests in secret rooms are the primary source of Form Cores (intentional gate rewarding thorough exploration)
- Evolution costs increase significantly at higher levels to prevent rush
- Players can re-spec evolution branch at 50% material cost refund
- Boss ores are farmable (boss respawns 60s after leaving chunk)
- Breakable walls are subtly marked — observant players find more secrets
- Water Vortexes can lead to both danger and treasure — risk/reward teleportation

---

## 11. Open Questions

- Boss respawn mechanic: Boss respawns 60s after player leaves the chunk (confirmed)
- Evolution re-spec: 50% material refund (confirmed)
- Multiplayer: Not in scope for this expansion
- Save/Load: Player gender, weapon state, inventory, trap/mechanism states must persist across sessions
- Trap difficulty scaling: Linear with distance from spawn, or per-biome fixed difficulty? (Recommended: per-biome fixed, with depth affecting density not individual trap damage)
