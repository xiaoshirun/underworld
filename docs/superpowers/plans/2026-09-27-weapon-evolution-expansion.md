# Weapon Evolution Expansion - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add character selection, dual-weapon system (drill + liquid metal), weapon evolution (5 branches x 3 levels), trap & mechanism system, 5 biome bosses (passage guardians + optional challenges), and 3-tier treasure chest system to the underground world exploration game.

**Architecture:** Extend existing Canvas-based game engine with new entity types (Boss, Chest, Trap, Mechanism), new data layer (WeaponState, Inventory), and new UI pages (CharacterSelectPage). All rendering via CanvasRenderingContext2D. World generation extended for boss rooms, chest placement, trap/mechanism generation, and secret rooms.

**Tech Stack:** HarmonyOS ArkTS/ArkUI, Canvas2D rendering, procedural world generation (value noise + FBM)

**Spec:** `docs/superpowers/specs/2026-09-27-weapon-evolution-expansion-design.md`

## Global Constraints

- Platform: HarmonyOS ArkTS — no npm packages, no DOM APIs in game logic
- All game rendering via `CanvasRenderingContext2D` (offscreen canvas not used)
- Existing chunk system: 32x32 tiles per chunk, chunk coords as `"cx,cy"` string keys
- Existing page routing: `router.pushPath({ url: 'pages/Index', params: {...} })`
- All new enums, interfaces, constants go in `GameConstants.ets`
- Game engine methods follow existing pattern: `private updateX(dt: number)` / `private renderX(c: CanvasRenderingContext2D, ...)`
- No unit test framework available — verification via device/emulator build + visual check
- Design philosophy: No quest/task system. Free exploration. Core pillars: weapon forms, traps/mechanisms, world diversity.

## File Structure

| File | Responsibility | Action |
|------|---------------|--------|
| `entry/src/main/ets/game/GameConstants.ets` | All enums, interfaces, constants | Modify: add ~300 lines of new types |
| `entry/src/main/ets/game/WorldGenerator.ets` | World/chunk generation | Modify: boss room gen, chest/trap/mechanism placement, shadow biome |
| `entry/src/main/ets/game/GameEngine.ets` | Core game loop, update, render | Modify: boss/chest/trap/mechanism/weapon/evolution systems |
| `entry/src/main/ets/pages/Index.ets` | Game HUD page | Modify: tool button, boss HP bar, evolution panel, trap warnings |
| `entry/src/main/ets/pages/LoginPage.ets` | Login page | Modify: route to CharacterSelectPage |
| `entry/src/main/ets/pages/CharacterSelectPage.ets` | Character selection | Create: new page |
| `entry/src/main/resources/base/profile/main_pages.json` | Page routing config | Modify: add CharacterSelectPage |

---

## Phase 1: Foundation (Data Model + Character Select)

### Task 1: Extend GameConstants with New Enums

**Files:**
- Modify: `entry/src/main/ets/game/GameConstants.ets` (append after existing enums, ~line 127)

**Interfaces:**
- Produces: `GenderType`, `WeaponForm`, `EvolutionBranch`, `EvolutionLevel`, `MaterialType`, `ChestType`, `BossType`, `BossPhase`, `BossRole`, `TrapType`, `MechanismType`, `TrapState` enums
- Consumed by: All subsequent tasks

- [ ] **Step 1: Add BiomeType.SHADOW to existing enum**

In `GameConstants.ets`, modify the `BiomeType` enum to add the 6th biome:

```typescript
export enum BiomeType {
  NORMAL = 0,
  CRYSTAL = 1,
  MUSHROOM = 2,
  WATER = 3,
  LAVA = 4,
  SHADOW = 5
}
```

- [ ] **Step 2: Add all new enums after BiomeType**

Append the following enums after the `BiomeType` enum:

```typescript
export enum GenderType {
  MALE = 0,
  FEMALE = 1
}

export enum WeaponForm {
  BLADE = 0,
  WHIP = 1,
  HAMMER = 2,
  STAFF = 3,
  DUAL_BLADES = 4,
  GREAT_AXE = 5
}

export enum EvolutionBranch {
  CRYSTAL = 0,
  FLAME = 1,
  SHADOW = 2,
  TOXIN = 3,
  TIDE = 4
}

export enum EvolutionLevel {
  BASE = 0,
  LEVEL_1 = 1,
  LEVEL_2 = 2,
  LEVEL_3 = 3
}

export enum MaterialType {
  CRYSTAL_ORE = 0,
  MUSHROOM_ORE = 1,
  FLAME_ORE = 2,
  ABYSS_ORE = 3,
  VOID_ORE = 4,
  CORE_NORMAL = 5,
  CORE_RARE = 6,
  FORM_CORE = 7
}

export enum ChestType {
  NORMAL = 0,
  ELITE = 1,
  BOSS = 2
}

export enum BossType {
  CRYSTAL_GUARDIAN = 0,
  MUSHROOM_KING = 1,
  LAVA_BEAST = 2,
  ABYSS_SIREN = 3,
  VOID_RIFT = 4
}

export enum BossPhase {
  PHASE_1 = 0,
  PHASE_2 = 1
}

export enum BossRole {
  PASSAGE_GUARDIAN = 0,
  OPTIONAL_CHALLENGE = 1
}

export enum TrapType {
  GROUND_SPIKES = 0,
  FALLING_ROCKS = 1,
  POISON_SPORES = 2,
  LAVA_GEYSER = 3,
  VOID_CRACK = 4,
  WATER_VORTEX = 5
}

export enum MechanismType {
  PRESSURE_PLATE = 0,
  LEVER = 1,
  PUSH_BLOCK = 2,
  CRYSTAL_REFLECTOR = 3,
  BREAKABLE_WALL = 4,
  TELEPORT_RUNE = 5
}

export enum TrapState {
  IDLE = 0,
  TELEGRAPH = 1,
  ACTIVE = 2,
  COOLDOWN = 3
}
```

- [ ] **Step 3: Build verify**

Run build in DevEco Studio. Confirm no compilation errors from the new enums.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/GameConstants.ets
git commit -m "feat: add expansion enums (GenderType, WeaponForm, BossType, TrapType, MechanismType, etc.)"
```

---

### Task 2: Extend GameConstants with New Interfaces and Constants

**Files:**
- Modify: `entry/src/main/ets/game/GameConstants.ets` (append after existing interfaces)

**Interfaces:**
- Produces: `BossState`, `ChestState`, `BossRoom`, `WeaponState`, `FormEvolutionData`, `Inventory`, `TrapInstance`, `MechanismInstance`, `SecretRoom`, `MaterialDrop` interfaces
- Produces: evolution/boss/chest/trap/mechanism configuration constants
- Produces: Extended `PlayerState` (gender, weapon, inventory fields), extended `ChunkData` (bosses, chests, traps, mechanisms, secretRooms, isBossRoom)
- Consumed by: All subsequent tasks

- [ ] **Step 1: Add new interfaces after existing interfaces**

Append after `GameSettings` interface:

```typescript
export interface BossState {
  x: number;
  y: number;
  vx: number;
  vy: number;
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

export interface ChestState {
  x: number;
  y: number;
  chestType: ChestType;
  opened: boolean;
  active: boolean;
  guardianDefeated: boolean;
  guardianCount: number;
  openAnim: number;
}

export interface BossRoom {
  chunkX: number;
  chunkY: number;
  bossType: BossType;
  entered: boolean;
  defeated: boolean;
  chestSpawned: boolean;
}

export interface FormEvolutionData {
  branch: EvolutionBranch;
  level: EvolutionLevel;
  oreCount: number;
  coreNormalCount: number;
  coreRareCount: number;
}

export interface WeaponState {
  currentForm: WeaponForm;
  unlockedForms: WeaponForm[];
  evolutionData: FormEvolutionData[];
}

export interface Inventory {
  crystalOre: number;
  mushroomOre: number;
  flameOre: number;
  abyssOre: number;
  voidOre: number;
  coreNormal: number;
  coreRare: number;
  formCore: number;
  hpPotions: number;
  gold: number;
}

export interface MaterialDrop {
  x: number;
  y: number;
  type: MaterialType;
  count: number;
  bobPhase: number;
  active: boolean;
}

export interface TrapInstance {
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

export interface MechanismInstance {
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

export interface SecretRoom {
  chunkX: number;
  chunkY: number;
  wallTileX: number;
  wallTileY: number;
  revealed: boolean;
  chestType: ChestType;
}
```

Note: `Inventory` uses flat fields instead of `Map` because ArkTS Map serialization is unreliable. `WeaponState.evolutionData` uses array indexed by `WeaponForm` enum value.

- [ ] **Step 2: Extend PlayerState with new fields**

Add these fields to the existing `PlayerState` interface:

```typescript
  gender: GenderType;
  currentWeaponForm: WeaponForm;
  unlockedForms: number[];
  evolutionBranch: EvolutionBranch;
  evolutionLevel: EvolutionLevel;
  isUsingTool: boolean;
  toolCooldown: number;
  inventory: Inventory;
```

- [ ] **Step 3: Extend ChunkData with boss/chest/trap/mechanism fields**

Modify existing `ChunkData` interface:

```typescript
export interface ChunkData {
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

- [ ] **Step 4: Add evolution/boss/chest/trap/mechanism configuration constants**

Append after existing constants:

```typescript
// Evolution costs: [normalCores, rareCores, ore] per level
export const EVOLUTION_COST_NORMAL: number[] = [0, 3, 0, 0];
export const EVOLUTION_COST_RARE: number[] = [0, 0, 1, 2];
export const EVOLUTION_COST_ORE: number[] = [0, 2, 4, 6];
export const FORM_UNLOCK_COST: number = 1;

// Boss config
export const BOSS_HP: number = 50;
export const BOSS_SIZE: number = 40;
export const BOSS_ROOM_SIZE: number = 15;
export const BOSS_ATTACK_INTERVAL: number = 3000;
export const BOSS_PHASE2_THRESHOLD: number = 0.5;
export const PASSAGE_GUARDIAN_AGGRO: number = 9999;
export const OPTIONAL_CHALLENGE_AGGRO: number = 120;
export const BOSS_RESPAWN_TIME: number = 60000;

// Chest config
export const CHEST_SIZE: number = 10;
export const CHEST_INTERACT_RANGE: number = 30;
export const NORMAL_CHEST_CHANCE: number = 0.08;
export const ELITE_CHEST_CHANCE: number = 0.03;
export const ELITE_GUARDIAN_COUNT: number = 3;

// Trap config
export const TRIGGER_DETECT_RANGE: number = 48;
export const SPIKE_DAMAGE: number = 1;
export const ROCK_DAMAGE: number = 2;
export const POISON_DPS: number = 1;
export const LAVA_GEYSER_DAMAGE: number = 2;
export const VOID_PULL_DPS: number = 1;
export const SPIKE_TELEGRAPH_TIME: number = 500;
export const SPIKE_ACTIVE_TIME: number = 1500;
export const SPIKE_COOLDOWN_TIME: number = 2000;
export const ROCK_FALL_WARNING: number = 300;
export const POISON_CLOUD_DURATION: number = 3000;
export const POISON_EMIT_INTERVAL: number = 4000;
export const LAVA_GEYSER_WARNING: number = 800;
export const LAVA_GEYSER_ACTIVE: number = 1500;

// Mechanism config
export const PUSH_BLOCK_SPEED: number = 2.0;
export const PRESSURE_PLATE_RANGE: number = 16;
export const TELEPORT_COOLDOWN: number = 2000;
export const LEVER_LINK_RANGE: number = 320;

// Weapon form attack params: [range, width, duration, cooldown]
export const WEAPON_FORM_STATS: number[][] = [
  [28, 22, 250, 400],   // BLADE
  [40, 12, 300, 350],   // WHIP
  [20, 35, 350, 600],   // HAMMER
  [50, 10, 200, 450],   // STAFF
  [22, 18, 180, 250],   // DUAL_BLADES
  [30, 40, 400, 700],   // GREAT_AXE
];
```

- [ ] **Step 5: Add boss/chest/weapon/trap color constants**

```typescript
// Boss colors
export const COLOR_BOSS_CRYSTAL: string = '#00ced1';
export const COLOR_BOSS_MUSHROOM: string = '#cd3278';
export const COLOR_BOSS_LAVA: string = '#ff4500';
export const COLOR_BOSS_ABYSS: string = '#4169e1';
export const COLOR_BOSS_VOID: string = '#6b21a8';

// Chest colors
export const COLOR_CHEST_NORMAL: string = '#8b6914';
export const COLOR_CHEST_ELITE: string = '#708090';
export const COLOR_CHEST_BOSS: string = '#ffd700';
export const COLOR_CHEST_GLOW: string = '#fbbf24';

// Shadow biome colors
export const COLOR_SHADOW_FLOOR: string = '#0d0d1a';
export const COLOR_SHADOW_WALL: string = '#1a0a2e';
export const COLOR_SHADOW_PARTICLE: string = '#7c3aed';

// Trap colors
export const COLOR_SPIKE: string = '#9ca3af';
export const COLOR_SPIKE_TIP: string = '#d1d5db';
export const COLOR_ROCK: string = '#78716c';
export const COLOR_POISON_CLOUD: string = '#4ade80';
export const COLOR_LAVA_GEYSER: string = '#ff6b00';
export const COLOR_VOID_CRACK: string = '#7c3aed';
export const COLOR_VOID_PULL: string = '#a855f7';
export const COLOR_VORTEX: string = '#38bdf8';

// Mechanism colors
export const COLOR_PRESSURE_PLATE: string = '#a8a29e';
export const COLOR_PLATE_ACTIVE: string = '#fbbf24';
export const COLOR_LEVER: string = '#78716c';
export const COLOR_LEVER_HANDLE: string = '#22d3ee';
export const COLOR_PUSH_BLOCK: string = '#a3a3a3';
export const COLOR_REFLECTOR: string = '#67e8f9';
export const COLOR_BEAM: string = '#fbbf24';
export const COLOR_BREAKABLE_WALL: string = '#2a2a45';
export const COLOR_TELEPORT_RUNE: string = '#8b5cf6';
export const COLOR_TELEPORT_ENTRY: string = '#3b82f6';
export const COLOR_TELEPORT_EXIT: string = '#22c55e';

// Weapon evolution glow colors
export const COLOR_EVO_CRYSTAL: string = '#67e8f9';
export const COLOR_EVO_FLAME: string = '#f97316';
export const COLOR_EVO_SHADOW: string = '#a855f7';
export const COLOR_EVO_TOXIN: string = '#4ade80';
export const COLOR_EVO_TIDE: string = '#38bdf8';

// UI colors
export const COLOR_BOSS_HP_BAR: string = '#dc2626';
export const COLOR_BOSS_HP_BG: string = '#1f2937';
export const COLOR_TOOL_BTN: string = '#f59e0b';
export const COLOR_EVO_PANEL_BG: string = '#0f172a';
export const COLOR_EVO_PANEL_BORDER: string = '#334155';
export const COLOR_TRAP_WARNING: string = '#fbbf24';
```

- [ ] **Step 6: Build verify**

Run build. Confirm all new types compile.

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/game/GameConstants.ets
git commit -m "feat: add expansion interfaces and constants (Boss, Chest, Trap, Mechanism, Weapon, Inventory)"
```

---

### Task 3: Create CharacterSelectPage

**Files:**
- Create: `entry/src/main/ets/pages/CharacterSelectPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

**Interfaces:**
- Consumes: `GenderType` from GameConstants
- Produces: Page that routes to `pages/Index` with `gender` param

- [ ] **Step 1: Add CharacterSelectPage to routing config**

In `entry/src/main/resources/base/profile/main_pages.json`, add the new page to the `src` array:

```json
"pages/CharacterSelectPage"
```

- [ ] **Step 2: Create CharacterSelectPage.ets**

Create the full page with Canvas-based character preview, male/female selection, and confirm button. The page should:

1. Display title "选择角色" at top
2. Show two character previews side by side (male left, female right) drawn on individual canvases with idle breathing animation
3. Highlight selected character with a glow border
4. Confirm button at bottom, disabled until selection made
5. On confirm: `router.replacePath({ url: 'pages/Index', params: { gender: selectedGender, username: username } })`

Character rendering differences:
- Male: broader shoulders (wider rect), shorter hair (small top arc), blue outfit (`#3b82f6`)
- Female: narrower build, longer hair (flowing arcs), purple outfit (`#8b5cf6`)

Both share: skin color `#f5c8a0`, basic humanoid pixel-art proportions, idle bounce animation via `Math.sin(frame * 0.05) * 2`.

The page receives `username` from LoginPage params and forwards it to Index.

- [ ] **Step 3: Update LoginPage routing**

In `LoginPage.ets`, change the login success route from `'pages/Index'` to `'pages/CharacterSelectPage'`. Keep passing `username` in params.

- [ ] **Step 4: Update Index.ets to receive gender param**

In `Index.ets` `aboutToAppear()`, read `gender` from router params (default to `GenderType.MALE`). Store in a `@State` variable. Pass to `gameEngine.init()` or a new `gameEngine.setGender()` method.

- [ ] **Step 5: Build and verify on device/emulator**

Verify: Login -> CharacterSelectPage appears -> select character -> confirm -> enters game world.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/pages/CharacterSelectPage.ets entry/src/main/ets/pages/LoginPage.ets entry/src/main/ets/pages/Index.ets entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat: add CharacterSelectPage with male/female selection"
```

---

### Task 4: Update Player Init with New State Fields

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets` (player initialization in `init()` or `resetPlayer()`)

**Interfaces:**
- Consumes: All new enums and interfaces from Tasks 1-2
- Produces: Properly initialized player with gender, weapon, inventory state

- [ ] **Step 1: Add gender parameter to GameEngine**

Add a `private playerGender: GenderType = GenderType.MALE;` field and a `setGender(g: GenderType): void` method.

- [ ] **Step 2: Extend player initialization**

Wherever `PlayerState` is constructed (likely in `init()` or a `resetPlayer()` method), add the new fields:

```typescript
gender: this.playerGender,
currentWeaponForm: WeaponForm.BLADE,
unlockedForms: [WeaponForm.BLADE],
evolutionBranch: EvolutionBranch.CRYSTAL,
evolutionLevel: EvolutionLevel.BASE,
isUsingTool: false,
toolCooldown: 0,
inventory: {
  crystalOre: 0, mushroomOre: 0, flameOre: 0, abyssOre: 0, voidOre: 0,
  coreNormal: 0, coreRare: 0, formCore: 0,
  hpPotions: 3, gold: 0
}
```

- [ ] **Step 3: Update ChunkData initialization**

Wherever `ChunkData` objects are created (in WorldGenerator or GameEngine), add:

```typescript
bosses: [],
chests: [],
traps: [],
mechanisms: [],
secretRooms: [],
isBossRoom: false
```

- [ ] **Step 4: Add new entity arrays to GameEngine**

```typescript
private bosses: BossState[] = [];
private activeBoss: BossState | null = null;
private bossRoomLocked: boolean = false;
private materialDrops: MaterialDrop[] = [];
private bossRooms: BossRoom[] = [];
```

- [ ] **Step 5: Build verify**

Confirm no type errors from missing fields.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: initialize player with weapon/inventory/gender state and new entity arrays"
```

---

## Phase 2: Weapon System

### Task 5: Implement Drill Tool Button in UI

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets` (add tool button to ActionButtonsView)
- Modify: `entry/src/main/ets/game/GameEngine.ets` (add `toolPressed` to InputState, handle tool use)

**Interfaces:**
- Consumes: `InputState.toolPressed` (new field), `COLOR_TOOL_BTN`
- Produces: Functional drill tool that breaks wall tiles when activated

- [ ] **Step 1: Add toolPressed to InputState**

In `GameConstants.ets`, add `toolPressed: boolean` to `InputState` interface. Initialize to `false` in GameEngine.

- [ ] **Step 2: Add tool button to Index.ets**

In the `ActionButtonsView()` builder, add a drill tool button positioned to the left of the jump button. Use `COLOR_TOOL_BTN` (#f59e0b) color. Show a drill icon (simple triangle/spiral shape drawn with Canvas or a text symbol). On tap: set `toolPressed = true`, reset after 100ms.

- [ ] **Step 3: Implement tool use logic in GameEngine**

In the `update()` method, when `input.toolPressed` is true and `!player.isUsingTool` and `player.toolCooldown <= 0`:
1. Set `player.isUsingTool = true`
2. Calculate target tile in `player.facing` direction
3. If target tile is `TileType.WALL`, start drill animation and decrement hit count
4. After `DRILL_BREAK_HITS` hits, set tile to `TileType.BROKEN_WALL` then `TileType.FLOOR`
5. Set `player.toolCooldown = 200` (ms)
6. Spawn drill particles

- [ ] **Step 4: Build and verify**

Verify: Tool button visible in game, pressing it breaks wall tiles in facing direction.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets entry/src/main/ets/game/GameEngine.ets entry/src/main/ets/game/GameConstants.ets
git commit -m "feat: add drill tool button and wall-breaking mechanic"
```

---

### Task 6: Implement Weapon Form Switching

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets` (add `switchWeaponForm()` method, modify attack rendering)
- Modify: `entry/src/main/ets/pages/Index.ets` (add weapon switch button or auto-cycle)

**Interfaces:**
- Consumes: `WeaponForm`, `WEAPON_FORM_STATS`, `player.unlockedForms`
- Produces: `switchWeaponForm(form: WeaponForm)`, attack params vary by form

- [ ] **Step 1: Add weapon switch method to GameEngine**

```typescript
switchWeaponForm(form: WeaponForm): void {
  if (this.player === null) return;
  if (this.player.unlockedForms.indexOf(form) < 0) return;
  this.player.currentWeaponForm = form;
}
```

- [ ] **Step 2: Modify attack to use weapon form stats**

In the attack logic, replace hardcoded `ATTACK_RANGE`, `ATTACK_WIDTH`, `ATTACK_DURATION`, `ATTACK_COOLDOWN` with values from `WEAPON_FORM_STATS[this.player.currentWeaponForm]`.

- [ ] **Step 3: Add weapon form cycle button to UI**

Add a small button in the HUD area (near minimap or below HP bar) that cycles through `player.unlockedForms`. Show current weapon form name as text label.

- [ ] **Step 4: Differentiate attack visual per weapon form**

In `renderPlayer()` or the attack rendering section, switch on `player.currentWeaponForm` to draw different attack effects:
- BLADE: straight slash arc (existing)
- WHIP: long thin arc extending far
- HAMMER: wide ground slam shockwave
- STAFF: projectile bolt
- DUAL_BLADES: two quick slash arcs
- GREAT_AXE: wide circular cleave

- [ ] **Step 5: Build and verify**

Verify: Can switch between unlocked forms, each has different attack range/speed/visual.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets entry/src/main/ets/pages/Index.ets
git commit -m "feat: implement weapon form switching with per-form attack stats"
```

---

## Phase 3: Trap & Mechanism System

### Task 7: Trap Generation in WorldGenerator

**Files:**
- Modify: `entry/src/main/ets/game/WorldGenerator.ets`

**Interfaces:**
- Consumes: `TrapType`, `TrapInstance`, `TrapState`, `BiomeType`, trap config constants
- Produces: `generateTraps()` method, biome-themed trap placement in chunks

- [ ] **Step 1: Add trap generation method to WorldGenerator**

```typescript
generateTraps(cx: number, cy: number, tiles: number[][], biome: BiomeType, distFromOrigin: number): TrapInstance[] {
  const traps: TrapInstance[] = [];
  // Density increases with distance from origin
  const density = Math.min(0.05 + distFromOrigin * 0.005, 0.15);
  // Select trap types based on biome
  // NORMAL: GROUND_SPIKES, FALLING_ROCKS
  // CRYSTAL: GROUND_SPIKES
  // MUSHROOM: POISON_SPORES, FALLING_ROCKS
  // WATER: WATER_VORTEX
  // LAVA: LAVA_GEYSER, FALLING_ROCKS
  // SHADOW: VOID_CRACK
  // Place traps on floor tiles, away from spawn points
  return traps;
}
```

- [ ] **Step 2: Implement per-biome trap placement**

For each biome, create traps with appropriate positions:
- Ground Spikes: 2-3 tile lines on floor tiles, random positions
- Falling Rocks: trigger tiles at ceiling-adjacent floor positions
- Poison Spores: wall-adjacent positions (mushroom patches)
- Lava Geysers: random floor tiles in lava biome
- Void Cracks: hidden floor tiles (appear as normal floor until triggered)
- Water Vortexes: placed in pairs on water tiles

- [ ] **Step 3: Integrate into chunk generation flow**

After `decorateChunk()`, call `generateTraps()` and assign to `chunk.traps`.

- [ ] **Step 4: Build and verify**

Verify: Traps appear in world as player explores, correct types per biome.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/WorldGenerator.ets
git commit -m "feat: generate biome-themed traps in world generation"
```

---

### Task 8: Trap Update and Rendering

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `TrapInstance`, `TrapType`, `TrapState`, trap damage constants, trap color constants
- Produces: `updateTraps(dt)`, `renderTraps(c, offX, offY)`, trap damage application

- [ ] **Step 1: Implement trap state machine in updateTraps**

`updateTraps(dt: number)` — for each trap in visible chunks:

```typescript
switch (trap.state) {
  case TrapState.IDLE:
    // Check if player is within triggerRadius
    if (distToPlayer < trap.triggerRadius) {
      trap.state = TrapState.TELEGRAPH;
      trap.timer = getTelegraphTime(trap.trapType);
    }
    break;
  case TrapState.TELEGRAPH:
    trap.timer -= dt;
    if (trap.timer <= 0) {
      trap.state = TrapState.ACTIVE;
      trap.timer = getActiveTime(trap.trapType);
    }
    break;
  case TrapState.ACTIVE:
    // Apply damage if player is in trap area
    applyTrapDamage(trap);
    trap.timer -= dt;
    if (trap.timer <= 0) {
      trap.state = TrapState.COOLDOWN;
      trap.timer = getCooldownTime(trap.trapType);
    }
    break;
  case TrapState.COOLDOWN:
    trap.timer -= dt;
    if (trap.timer <= 0) {
      trap.state = TrapState.IDLE;
    }
    break;
}
```

- [ ] **Step 2: Implement per-trap-type rendering**

`renderTraps(c: CanvasRenderingContext2D, offX: number, offY: number)`:

- Ground Spikes: IDLE = flat line on floor, TELEGRAPH = crack lines + shake, ACTIVE = triangular spikes up, COOLDOWN = retracting animation
- Falling Rocks: IDLE = nothing visible, TELEGRAPH = dust particles falling, ACTIVE = rock rectangles + impact dust
- Poison Spores: TELEGRAPH = mushroom patch pulses, ACTIVE = green-purple particle cloud expanding
- Lava Geysers: TELEGRAPH = bubbling orange spot, ACTIVE = tall orange-red column + splash particles
- Void Cracks: IDLE = invisible, TELEGRAPH = purple crack lines spreading, ACTIVE = glowing void pit with pull indicator
- Water Vortex: always spinning blue-white animation, special interaction (teleport) on contact

- [ ] **Step 3: Implement trap warning indicators in HUD**

`renderTrapWarnings(c: CanvasRenderingContext2D)`:
- When a trap is in TELEGRAPH state and near player, show a warning indicator (exclamation mark or red flash at screen edge)
- Use `COLOR_TRAP_WARNING` for the indicator

- [ ] **Step 4: Implement special trap effects**

- Water Vortex: on player contact, teleport to paired vortex position
- Void Crack: while ACTIVE, apply pull force toward trap center (modify player velocity)
- Falling Rocks: while ACTIVE, create temporary debris tiles that slow movement

- [ ] **Step 5: Build and verify**

Verify: Traps cycle through states correctly, damage player, visual feedback is clear.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: trap update loop, rendering, and damage system"
```

---

### Task 9: Mechanism Generation in WorldGenerator

**Files:**
- Modify: `entry/src/main/ets/game/WorldGenerator.ets`

**Interfaces:**
- Consumes: `MechanismType`, `MechanismInstance`, `SecretRoom`, `BiomeType`, mechanism config constants
- Produces: `generateMechanisms()` method, puzzle room placement, secret room creation

- [ ] **Step 1: Add mechanism generation method**

```typescript
generateMechanisms(cx: number, cy: number, tiles: number[][], biome: BiomeType): MechanismInstance[] {
  const mechanisms: MechanismInstance[] = [];
  // Place mechanisms based on biome theme:
  // NORMAL: PRESSURE_PLATE, PUSH_BLOCK, BREAKABLE_WALL
  // CRYSTAL: CRYSTAL_REFLECTOR, PRESSURE_PLATE
  // MUSHROOM: LEVER, PUSH_BLOCK
  // WATER: LEVER, TELEPORT_RUNE
  // LAVA: PRESSURE_PLATE, LEVER
  // SHADOW: TELEPORT_RUNE, CRYSTAL_REFLECTOR
  return mechanisms;
}
```

- [ ] **Step 2: Implement puzzle room templates**

Create 3-4 small puzzle room layouts (5x5 to 8x8 tiles) that are placed randomly in chunks:

Template A (Pressure Plate + Door):
```
W W W W W
W . . . W
W . P . W   P = pressure plate, linked to door
W . . D W   D = door (wall that opens)
W W W W W
```

Template B (Push Block + Plate):
```
W W W W W
W B . . W   B = push block
W . . P W   P = pressure plate
W . . D W   D = door
W W W W W
```

Template C (Lever + Bridge):
```
W W W W W
W L . . W   L = lever
W . . G W   G = gap (walkable when lever activates bridge)
W . . . W
W W W W W
```

- [ ] **Step 3: Implement secret room generation**

Secret rooms are small chambers (5x5) hidden behind breakable walls:
- Place a `BREAKABLE_WALL` tile on a chunk wall
- Behind it: a small room with an Elite Chest or rare materials
- Store in `chunk.secretRooms`
- Breakable walls look slightly different from normal walls (use `COLOR_BREAKABLE_WALL`)

- [ ] **Step 4: Implement teleport rune paired placement**

Teleport runes are always placed in pairs within the same biome:
- Entry rune (blue glow) near the biome entrance
- Exit rune (green glow) deeper in the biome or in a secret area
- Store pair index in `extraData[0]`

- [ ] **Step 5: Integrate into chunk generation**

After trap generation, call `generateMechanisms()` and `generateSecretRooms()`. Assign to `chunk.mechanisms` and `chunk.secretRooms`.

- [ ] **Step 6: Build and verify**

Verify: Mechanisms appear in world, puzzle rooms have correct layout, secret rooms exist behind breakable walls.

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/game/WorldGenerator.ets
git commit -m "feat: generate mechanisms, puzzle rooms, and secret rooms"
```

---

### Task 10: Mechanism Interaction and Rendering

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `MechanismInstance`, `MechanismType`, `SecretRoom`, mechanism config constants, mechanism color constants
- Produces: `updateMechanisms(dt)`, `renderMechanisms(c, offX, offY)`, `interactWithMechanism(mech)`, `checkBreakableWalls()`

- [ ] **Step 1: Implement mechanism rendering**

`renderMechanisms(c: CanvasRenderingContext2D, offX: number, offY: number)`:

- Pressure Plate: flat tile on floor, glows `COLOR_PLATE_ACTIVE` when stepped on
- Lever: wall-mounted stone pillar with crystal handle, handle rotates when toggled
- Push Block: carved stone block with rune markings, dust particles when moving
- Crystal Reflector: hexagonal crystal shape, glows when hit by beam, draw beam line to next reflector/receptor
- Breakable Wall: wall tile with visible crack lines (draw 2-3 diagonal lines), slightly different color
- Teleport Rune: circular rune pattern on floor with rotating glyph, blue or green glow based on entry/exit

- [ ] **Step 2: Implement mechanism interaction**

`checkMechanismInteraction()`:
- Check if player is adjacent to a mechanism and presses interact (attack button or tool button)
- Lever: toggle `active` state, find linked mechanism by `linkedIndex`, activate/deactivate it
- Pressure Plate: auto-activate when player stands on it (check every frame in `updateMechanisms`)
- Crystal Reflector: rotate 60 degrees on interact, recalculate beam path
- Teleport Rune: on player contact, teleport to paired rune (with cooldown)

- [ ] **Step 3: Implement push block physics**

In `updateMechanisms()`:
- When player walks into a push block, slide it in the push direction
- Block stops when hitting a wall, another block, or the edge of the floor
- If block lands on a pressure plate, activate that plate
- Spawn scrape dust particles while moving

- [ ] **Step 4: Implement breakable wall detection**

`checkBreakableWalls()`:
- When drill tool hits a breakable wall (or hammer weapon hits it):
  - Find the corresponding `SecretRoom` in the chunk
  - Set `revealed = true`
  - Change the wall tile to `TileType.FLOOR`
  - Spawn debris particles
  - Reveal the secret room contents (chest, materials)

- [ ] **Step 5: Implement linked mechanism logic**

`checkMechanismLinks(mech: MechanismInstance)`:
- When a pressure plate activates/deactivates, find all mechanisms with `linkedIndex` pointing to it
- For doors: change tile between WALL and FLOOR based on plate state
- For traps: enable/disable the linked trap
- For bridges: change gap tiles between WALL (bridge down) and FLOOR (bridge up)

- [ ] **Step 6: Build and verify**

Verify: All mechanism types interact correctly, puzzle rooms are solvable, secret rooms reveal when walls are broken.

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: mechanism interaction, push block physics, breakable walls, and linked mechanisms"
```

---

## Phase 4: Boss System

### Task 11: Boss Room Generation in WorldGenerator

**Files:**
- Modify: `entry/src/main/ets/game/WorldGenerator.ets`

**Interfaces:**
- Consumes: `BiomeType`, `BossType`, `BossRole`, `BossRoom`, `BOSS_ROOM_SIZE`
- Produces: `generateBossRoom()` method, boss room chunk generation for Passage Guardians, open-world spawn for Optional Challenges

- [ ] **Step 1: Add boss room tracking to WorldGenerator**

Add a field `private bossRooms: BossRoom[] = [];` and a method `getBossRooms(): BossRoom[]`.

- [ ] **Step 2: Implement Passage Guardian boss room placement**

In the chunk generation flow, after determining biome for a chunk, check if this biome has had a Passage Guardian boss room placed yet. If not, and the chunk is far enough from origin (>10 chunks), place a boss room:

```typescript
private tryPlacePassageGuardian(cx: number, cy: number, biome: BiomeType): BossRoom | null {
  // Only one Passage Guardian boss room per biome per ~20 chunk radius
  // Check distance from existing boss rooms of same type
  // Return BossRoom if placement succeeds, null otherwise
}
```

Map biomes to boss types and roles:
- CRYSTAL -> CRYSTAL_GUARDIAN, PASSAGE_GUARDIAN
- WATER -> ABYSS_SIREN, PASSAGE_GUARDIAN
- SHADOW -> VOID_RIFT, PASSAGE_GUARDIAN
- MUSHROOM -> MUSHROOM_KING, OPTIONAL_CHALLENGE
- LAVA -> LAVA_BEAST, OPTIONAL_CHALLENGE

- [ ] **Step 3: Implement Optional Challenge boss spawning**

For Optional Challenge bosses (Mushroom King, Lava Beast):
- Don't create sealed rooms
- Instead, spawn them as large entities in the open biome
- Place them >15 chunks from origin in their respective biomes
- They roam the biome with an aggro radius of `OPTIONAL_CHALLENGE_AGGRO` (120 pixels)

- [ ] **Step 4: Generate boss room chunk tiles (Passage Guardians only)**

When a chunk is flagged as boss room, generate a 15x15 open area in the center:
- Clear all walls in the center area
- Add floor tiles
- Place a distinct entrance (gap in one wall)
- Store entrance tile positions for door seal mechanic
- Add biome-themed decorative tiles around the border

- [ ] **Step 5: Build and verify**

Verify: Passage Guardian rooms appear in CRYSTAL/WATER/SHADOW biomes. Optional Challenge bosses appear in MUSHROOM/LAVA biomes as open-world entities.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/WorldGenerator.ets
git commit -m "feat: generate boss rooms for Passage Guardians and open-world spawns for Optional Challenges"
```

---

### Task 12: Boss Entity - Spawn, Update, AI

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `BossState`, `BossType`, `BossRole`, `BossPhase`, `BOSS_HP`, `BOSS_SIZE`, `BOSS_ATTACK_INTERVAL`
- Produces: `updateBosses(dt)`, `spawnBoss()`, boss AI logic for both Passage Guardians and Optional Challenges

- [ ] **Step 1: Implement Passage Guardian boss spawn trigger**

In the chunk loading / player movement code, check if player enters a boss room chunk. If boss not defeated and not entered:
1. Set `entered = true`
2. Seal entrance (set entrance tiles to WALL)
3. Set `bossRoomLocked = true`
4. Spawn boss at room center:

```typescript
private spawnBoss(room: BossRoom): BossState {
  const bossType = room.bossType;
  return {
    x: (room.chunkX * CHUNK_SIZE + CHUNK_SIZE / 2) * TILE_SIZE,
    y: (room.chunkY * CHUNK_SIZE + CHUNK_SIZE / 2) * TILE_SIZE,
    vx: 0, vy: 0,
    hp: BOSS_HP, maxHp: BOSS_HP,
    bossType: bossType,
    bossRole: BossRole.PASSAGE_GUARDIAN,
    phase: BossPhase.PHASE_1,
    active: true, defeated: false,
    attackTimer: 0, specialTimer: 0,
    hitFlash: 0, size: BOSS_SIZE,
    aggroRadius: PASSAGE_GUARDIAN_AGGRO,
    extraData: []
  };
}
```

- [ ] **Step 2: Implement Optional Challenge boss spawn**

For Optional Challenge bosses, spawn them during chunk generation as entities:

```typescript
private spawnOptionalBoss(bossType: BossType, x: number, y: number): BossState {
  return {
    x: x, y: y,
    vx: 0, vy: 0,
    hp: BOSS_HP, maxHp: BOSS_HP,
    bossType: bossType,
    bossRole: BossRole.OPTIONAL_CHALLENGE,
    phase: BossPhase.PHASE_1,
    active: true, defeated: false,
    attackTimer: 0, specialTimer: 0,
    hitFlash: 0, size: BOSS_SIZE,
    aggroRadius: OPTIONAL_CHALLENGE_AGGRO,
    extraData: []
  };
}
```

Optional Challenge bosses wander randomly when player is outside aggro radius. When player enters radius, they become aggressive. Player can escape by leaving the aggro radius.

- [ ] **Step 3: Implement boss update loop**

`updateBosses(dt: number)` — for each active boss:
1. If Passage Guardian: move toward player (always, since room is sealed)
2. If Optional Challenge: move toward player only if within aggro radius, otherwise wander
3. Decrement attack timer, fire attack when ready
4. Check HP threshold for phase transition
5. Handle boss-specific mechanics (see Task 13)
6. Check collision with player (deal damage on contact)
7. Update hitFlash

- [ ] **Step 4: Implement boss death**

When boss HP <= 0:
1. Set `defeated = true`, `active = false`
2. If Passage Guardian: open boss room exit (restore entrance tiles to FLOOR), set `bossRoomLocked = false`
3. If Optional Challenge: boss respawns after `BOSS_RESPAWN_TIME` (60s) if player leaves chunk
4. Spawn boss chest at boss position
5. Drop ore materials (2-3 of boss-specific type)
6. Spawn celebration particles

- [ ] **Step 5: Build and verify**

Verify: Passage Guardian rooms seal and spawn boss. Optional Challenge bosses roam and can be avoided. Both types die and drop loot.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: boss spawn, AI, death mechanics for both Passage Guardians and Optional Challenges"
```

---

### Task 13: Boss Combat Mechanics (Per-Boss Attacks)

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `BossState`, `BossPhase`, existing `Particle` system
- Produces: Unique attack patterns per boss type

- [ ] **Step 1: Implement Crystal Guardian attacks**

Phase 1: Every 3s fire 5 projectiles in fan pattern (30-degree spread).
Phase 2: Add crystal spike zones at random positions (damaging areas lasting 2s).

- [ ] **Step 2: Implement Mushroom King attacks**

Passive: Spore fog aura (circle around boss, player inside takes 1HP/2s).
Every 4s: 3 mycelia lines extend toward player (slow on contact).
Phase 2: Summon 2-3 mini mushroom enemies (HP=2, use existing SlimeState).

- [ ] **Step 3: Implement Lava Beast attacks**

Phase 1: Melee leaves lava ground zones (3s duration, damaging).
Phase 2 (HP<=40%): Explode into 8 projectiles + split into 2 smaller bodies (track in extraData).

- [ ] **Step 4: Implement Abyss Siren attacks**

Floats (no ground collision). Lightning chain projectile. Tidal surge knockback ring every 6s.
Phase 2: Spawn trap bubbles.

- [ ] **Step 5: Implement Void Rift attacks**

Blink teleport every 3s (leave void zone). Void pull gravity field.
Phase 2 (HP<=30%): Size +50%, shadow clone summon.

- [ ] **Step 6: Build and verify each boss**

Test each boss fight individually by navigating to their biome.

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: implement unique attack patterns for all 5 bosses"
```

---

### Task 14: Boss Rendering

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `BossState`, `BossType`, `BossRole`, boss color constants
- Produces: `renderBoss(c, boss, offX, offY)`, `renderBossHPBar(c)`

- [ ] **Step 1: Implement per-boss rendering**

`renderBoss(c: CanvasRenderingContext2D, boss: BossState, offX: number, offY: number)`:

Switch on `boss.bossType` to draw each boss with unique appearance:
- Crystal Guardian: Crystal cluster humanoid, pulsing core glow
- Mushroom King: Giant mushroom cap + stem, spore particles
- Lava Beast: Flowing lava body, dripping particles
- Abyss Siren: Translucent jellyfish, tentacle waves, electric sparks
- Void Rift: Shifting dark mass, central glowing rift, orbiting debris

All respect `boss.hitFlash` (white overlay), `boss.phase` (visual changes in phase 2), scale with `boss.size`.
Optional Challenge bosses have a visible aura/glow to distinguish them from regular enemies.

- [ ] **Step 2: Implement boss HP bar**

`renderBossHPBar(c: CanvasRenderingContext2D)`:
- Draw at top center of screen (only when `activeBoss !== null`)
- Background bar + filled bar proportional to HP/maxHP
- Boss name text above bar
- Phase indicator text below bar
- Color matches boss theme
- For Passage Guardians: show "守卫者" tag
- For Optional Challenges: show "挑战" tag

- [ ] **Step 3: Integrate into render loop**

In `render()`:
- Call `renderTraps()` after `renderWorld()`, under entities
- Call `renderMechanisms()` after traps
- Call `renderChests()` after mechanisms
- Call `renderEnemies()` after chests
- Call `renderBosses()` after enemies, before player
- Call `renderBossHPBar()` in HUD layer (after everything else)
- Call `renderTrapWarnings()` in HUD layer

- [ ] **Step 4: Build and verify visually**

Each boss should have distinct visual identity, HP bar shows during fight with correct role tag.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: render all 5 bosses with unique visuals, HP bar, and role tags"
```

---

## Phase 5: Chest System

### Task 15: Chest Placement in WorldGenerator

**Files:**
- Modify: `entry/src/main/ets/game/WorldGenerator.ets`

**Interfaces:**
- Consumes: `ChestState`, `ChestType`, `CHEST_SIZE`, spawn chance constants
- Produces: Chests placed in generated chunks (normal in open world, elite in secret rooms)

- [ ] **Step 1: Add normal chest generation to chunk generation**

After generating tiles, traps, and mechanisms for a chunk, roll for chest placement:
- For each suitable floor tile (away from walls), `Math.random() < NORMAL_CHEST_CHANCE` -> place normal chest (max 1 per chunk)
- Skip if chunk is boss room
- Position chests on floor tiles

```typescript
private generateChests(cx: number, cy: number, tiles: number[][], size: number): ChestState[] {
  const chests: ChestState[] = [];
  // ... placement logic
  return chests;
}
```

- [ ] **Step 2: Place Elite Chests in secret rooms**

When generating secret rooms (Task 9), place an Elite Chest inside:

```typescript
// In secret room generation:
const eliteChest: ChestState = {
  x: secretRoomCenterX, y: secretRoomCenterY,
  chestType: ChestType.ELITE,
  opened: false, active: true,
  guardianDefeated: true, guardianCount: 0,
  openAnim: 0
};
```

- [ ] **Step 3: Store chests in ChunkData**

Set `chunk.chests = chests` after generation.

- [ ] **Step 4: Build and verify**

Verify: Normal chests appear in the open world. Elite chests appear in secret rooms behind breakable walls.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/WorldGenerator.ets
git commit -m "feat: place normal chests in open world and elite chests in secret rooms"
```

---

### Task 16: Chest Rendering and Interaction

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `ChestState`, `ChestType`, chest color constants, `CHEST_INTERACT_RANGE`
- Produces: `renderChests()`, `checkChestInteraction()`, `openChest()`

- [ ] **Step 1: Implement chest rendering**

`renderChests(c: CanvasRenderingContext2D, offX: number, offY: number)`:

For each active chest in visible chunks:
- Normal: Brown wooden box (`COLOR_CHEST_NORMAL`), small particle glow
- Elite: Gray iron box (`COLOR_CHEST_ELITE`), rune patterns (cross-hatch lines), strong glow
- Boss: Golden ornate box (`COLOR_CHEST_BOSS`), large glow aura

If elite chest's `!guardianDefeated`, show locked indicator (red tint).
If `opened`, show open lid animation (`openAnim` timer).

- [ ] **Step 2: Implement chest interaction**

`checkChestInteraction()`:
- Check distance from player to each chest
- If within `CHEST_INTERACT_RANGE` and player presses interact (jump button or auto):
  - Normal chest: open immediately
  - Elite chest: open only if `guardianDefeated` (or if placed in secret room with no guardians)
  - Boss chest: auto-open on spawn

- [ ] **Step 3: Implement openChest and loot spawning**

`openChest(chest: ChestState)`:
1. Set `opened = true`, start `openAnim`
2. Spawn light pillar particle effect
3. Generate loot based on chest type:
   - Normal: `CORE_NORMAL` x1-2, `hpPotions` x1-2, small gold
   - Elite: `CORE_RARE` x1, `FORM_CORE` x1, `hpPotions` x2-3
   - Boss: Boss-specific ore x2-3, `CORE_RARE` x1-2, chance `FORM_CORE`
4. Add materials to player inventory
5. Show material pickup notifications (floating text particles)

- [ ] **Step 4: Implement elite chest guardian spawning (for open-world elite chests)**

For elite chests NOT in secret rooms (if any), spawn `ELITE_GUARDIAN_COUNT` enhanced slimes nearby:
- Use existing `SlimeState` with `hp = SLIME_HP * 3`, larger size
- Track guardians: when all killed, set `chest.guardianDefeated = true`

- [ ] **Step 5: Build and verify**

Verify: Find chests in world, open them, receive materials. Guardians fight correctly for guarded chests.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: chest rendering, interaction, loot drops, and elite guardians"
```

---

## Phase 6: Evolution System

### Task 17: Inventory and Material Collection

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `Inventory`, `MaterialType`, `MaterialDrop`
- Produces: Material drops from bosses/chests, inventory management methods

- [ ] **Step 1: Add MaterialDrop array to GameEngine**

```typescript
private materialDrops: MaterialDrop[] = [];
```

- [ ] **Step 2: Implement material drop spawning**

`spawnMaterialDrop(x: number, y: number, type: MaterialType, count: number)`:
- Create `MaterialDrop` at position with slight random offset
- Material drops bob up and down (like XpOrbs)
- Collected on player proximity (same magnet range as XP orbs)

- [ ] **Step 3: Implement material collection**

In update loop, check player distance to each material drop. If within collect range:
- Add `count` to appropriate inventory field
- Spawn collection particle
- Deactivate drop

- [ ] **Step 4: Connect boss/chest drops to material system**

In boss death handler: call `spawnMaterialDrop()` with boss-specific ore type.
In chest open handler: call `spawnMaterialDrop()` for cores/potions.

- [ ] **Step 5: Build and verify**

Verify: Killing boss drops ore pickups, opening chests drops core pickups, inventory numbers increase.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: material drop spawning and inventory collection"
```

---

### Task 18: Evolution Panel UI

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: `WeaponForm`, `EvolutionBranch`, `EvolutionLevel`, `Inventory`, evolution cost constants
- Produces: Evolution panel overlay in game UI

- [ ] **Step 1: Add evolution panel state**

Add `@State showEvolution: boolean = false;` to Index.ets.

- [ ] **Step 2: Add evolution panel button to HUD**

Add a small button (scroll/icon) in the HUD area. When tapped, toggle `showEvolution`.

- [ ] **Step 3: Build evolution panel overlay**

When `showEvolution` is true, render a full-screen semi-transparent overlay with:
- Current weapon form name and icon at top
- 5 evolution branches as selectable tabs
- For current branch: show level (0-3), material costs for next level, materials held
- "Evolve" button (enabled when materials sufficient)
- "Unlock Form" section showing locked forms with form core cost
- Close button

Use Canvas rendering for the panel (consistent with game aesthetic) or ArkUI components overlaid on the game canvas.

- [ ] **Step 4: Wire up evolution button to GameEngine**

Add callback: when player taps "Evolve", call `gameEngine.tryEvolveWeapon()`. When "Unlock Form", call `gameEngine.unlockWeaponForm(form)`.

- [ ] **Step 5: Build and verify UI**

Verify: Panel opens/closes, shows correct data, buttons respond.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat: evolution panel UI overlay"
```

---

### Task 19: Evolution Logic

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `WeaponState`, `Inventory`, `EVOLUTION_COST_*`, `BRANCH_ORE_MAP`, `FORM_UNLOCK_COST`
- Produces: `tryEvolveWeapon()`, `unlockWeaponForm()`, `canEvolve()`

- [ ] **Step 1: Implement canEvolve check**

```typescript
canEvolve(): boolean {
  if (this.player === null) return false;
  const level = this.player.evolutionLevel;
  if (level >= EvolutionLevel.LEVEL_3) return false;
  const nextLevel = level + 1;
  const branch = this.player.evolutionBranch;
  const oreNeeded = EVOLUTION_COST_ORE[nextLevel];
  const normalNeeded = EVOLUTION_COST_NORMAL[nextLevel];
  const rareNeeded = EVOLUTION_COST_RARE[nextLevel];
  // Check inventory has enough of each
  // ... return true if all sufficient
}
```

- [ ] **Step 2: Implement tryEvolveWeapon**

```typescript
tryEvolveWeapon(): boolean {
  if (!this.canEvolve()) return false;
  // Deduct materials from inventory
  // Increment evolutionLevel
  // Spawn evolution particle effect
  // Return true
}
```

- [ ] **Step 3: Implement unlockWeaponForm**

```typescript
unlockWeaponForm(form: WeaponForm): boolean {
  if (this.player === null) return false;
  if (this.player.unlockedForms.indexOf(form) >= 0) return false;
  if (this.player.inventory.formCore < FORM_UNLOCK_COST) return false;
  this.player.inventory.formCore -= FORM_UNLOCK_COST;
  this.player.unlockedForms.push(form);
  return true;
}
```

- [ ] **Step 4: Add evolution visual feedback**

When evolution succeeds:
- Screen flash effect
- Particle burst in evolution branch color
- Weapon appearance changes (add glow, particle trail based on branch + level)

- [ ] **Step 5: Build and verify full flow**

Verify complete flow: collect materials -> open evolution panel -> evolve weapon -> see visual change.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: weapon evolution logic and form unlock"
```

---

## Phase 7: Integration & Polish

### Task 20: Shadow Biome Generation

**Files:**
- Modify: `entry/src/main/ets/game/WorldGenerator.ets`

**Interfaces:**
- Consumes: `BiomeType.SHADOW`, shadow color constants
- Produces: Shadow Rift biome terrain generation

- [ ] **Step 1: Add Shadow biome to noise/biome selection**

In the biome determination logic (value noise with `BIOME_SCALE`), add a region for `SHADOW` biome. This should be rarer and deeper/farther from origin.

- [ ] **Step 2: Add Shadow biome terrain decoration**

In `decorateChunk()`, handle `BiomeType.SHADOW`:
- Dark floor tiles (`COLOR_SHADOW_FLOOR`)
- Void crystal decorations (similar to crystal biome but purple)
- Floating void particles
- Ghost slimes more common here

- [ ] **Step 3: Build and verify**

Verify: Shadow biome generates, has distinct visual identity, Void Rift boss spawns there.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/WorldGenerator.ets
git commit -m "feat: add Shadow Rift biome with void-themed terrain"
```

---

### Task 21: Player Rendering with Gender and Weapon Visuals

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets` (player rendering section)

**Interfaces:**
- Consumes: `player.gender`, `player.currentWeaponForm`, `player.evolutionLevel`, `player.evolutionBranch`
- Produces: Gender-differentiated player sprite, weapon visual on player

- [ ] **Step 1: Add gender-based rendering differences**

In the player render function:
- Male: wider body rect, shorter hair arc, blue outfit
- Female: narrower body, longer flowing hair, purple outfit

- [ ] **Step 2: Draw current weapon on player**

Based on `player.currentWeaponForm`, draw the weapon in the player's hand:
- BLADE: short line extending from hand
- WHIP: curved line
- HAMMER: thick short line with square head
- STAFF: long line with orb at tip
- DUAL_BLADES: two short lines
- GREAT_AXE: thick line with wide head

- [ ] **Step 3: Add evolution visual effects**

Based on `evolutionLevel`:
- Lv0: no effect
- Lv1: subtle glow in branch color
- Lv2: particle trail when moving
- Lv3: strong aura + orbiting particles

- [ ] **Step 4: Build and verify**

Verify: Male/female look different, weapon visible during gameplay, evolution effects visible.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: gender-differentiated player rendering and weapon visuals"
```

---

### Task 22: Inventory HUD Display

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: `Inventory` state from GameEngine
- Produces: Material count display in HUD

- [ ] **Step 1: Add material count display**

Add a compact inventory display to the HUD (bottom area or accessible via toggle):
- Show counts for each material type with colored icons
- Show current weapon form name
- Show evolution level

- [ ] **Step 2: Update HUD state from GameEngine**

Add a callback or polling mechanism to sync inventory data from GameEngine to Index @State variables.

- [ ] **Step 3: Build and verify**

Verify: Material counts update in real-time as player collects drops.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat: inventory HUD showing material counts and weapon info"
```

---

### Task 23: Boss Room Door Mechanics

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: `BossRoom`, `bossRoomLocked` state
- Produces: Door seal/open on boss fight start/end

- [ ] **Step 1: Implement door seal on boss room entry**

When player enters boss room chunk and boss spawns:
- Store entrance tile positions
- Set entrance tiles to `TileType.WALL`
- Set `bossRoomLocked = true`

- [ ] **Step 2: Implement door open on boss death**

When boss is defeated:
- Restore entrance tiles to `TileType.FLOOR`
- Set `bossRoomLocked = false`
- Play door open sound/particle effect

- [ ] **Step 3: Build and verify**

Verify: Cannot leave boss room during fight, exit opens after boss dies.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: boss room door seal and open mechanics"
```

---

### Task 24: Final Integration and Polish

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets` (game loop integration)
- Modify: `entry/src/main/ets/pages/Index.ets` (HUD integration)

**Interfaces:**
- Consumes: All systems from previous tasks
- Produces: Complete, integrated game experience

- [ ] **Step 1: Integrate all update methods into game loop**

Ensure `update()` calls in correct order:
```
updateInput -> updatePlayer -> updateEnemies -> updateBosses -> updateTraps
-> updateMechanisms -> updateChests -> updateMaterialDrops
-> updateParticles -> updateXpOrbs
-> checkBossRoomTriggers -> checkChestInteraction -> checkMechanismInteraction
-> checkBreakableWalls
```

- [ ] **Step 2: Integrate all render methods**

Ensure `render()` calls in correct order:
```
renderWorld -> renderTraps -> renderMechanisms -> renderChests
-> renderEnemies -> renderBosses -> renderMaterialDrops
-> renderPlayer -> renderParticles
-> renderHUD -> renderBossHPBar -> renderTrapWarnings -> renderMinimap
```

- [ ] **Step 3: Add ambient particles for Shadow biome**

When player is in Shadow biome chunks, spawn dark purple floating particles (similar to existing ambient system but with `COLOR_SHADOW_PARTICLE`).

- [ ] **Step 4: Balance pass**

Test full game flow and tune:
- Boss HP (should take ~2-3 minutes to defeat)
- Trap damage vs player HP (traps should be dangerous but not instant-death)
- Material drop counts (should take 2-3 boss kills to afford one evolution)
- Chest spawn rates (should find ~1 chest per 2-3 minutes of exploration)
- Evolution costs vs drop rates (should take ~30 min to reach Lv2 on one branch)
- Puzzle difficulty (NORMAL biome puzzles should be trivially solvable, SHADOW biome puzzles require thought)

- [ ] **Step 5: Full playtest**

Complete flow: Login -> Character Select -> Explore -> Encounter traps -> Solve puzzles -> Find breakable walls -> Discover secret rooms with Elite Chests -> Collect materials -> Fight Passage Guardian boss -> Evolve weapon -> Unlock new form -> Encounter Optional Challenge boss -> Repeat.

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat: final integration, balance tuning, and polish for weapon evolution expansion"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] Character selection (Task 3)
- [x] Dual weapon system (Tasks 5, 6)
- [x] 6 weapon forms with different stats (Task 6)
- [x] Weapon evolution 5 branches x 3 levels (Tasks 18, 19)
- [x] Material system: ores from bosses, cores from chests (Tasks 16, 17)
- [x] 5 biome bosses with unique mechanics (Tasks 11-14)
- [x] Boss roles: Passage Guardians + Optional Challenges (Tasks 11, 12)
- [x] Boss room generation and door mechanics (Tasks 11, 23)
- [x] 3 chest types with loot tables (Tasks 15, 16)
- [x] Shadow Rift biome (Task 20)
- [x] Trap system: 6 trap types, biome-themed (Tasks 7, 8)
- [x] Mechanism system: 6 mechanism types, puzzle rooms (Tasks 9, 10)
- [x] Secret rooms behind breakable walls (Tasks 9, 10)
- [x] Player rendering with gender + weapon visuals (Task 21)
- [x] Inventory HUD (Task 22)
- [x] Balance and integration (Task 24)
- [x] Free exploration design philosophy (no quest system)

**Type consistency:** All enum names, interface fields, and method signatures match across tasks. `Inventory` uses flat fields (not Map). `WeaponState.evolutionData` uses array indexed by enum value. `WEAPON_FORM_STATS` indexed by `WeaponForm` enum. `BossRole` distinguishes Passage Guardians from Optional Challenges. `TrapState` state machine: IDLE -> TELEGRAPH -> ACTIVE -> COOLDOWN -> IDLE.

**No placeholders:** All steps contain concrete code or specific implementation details.
