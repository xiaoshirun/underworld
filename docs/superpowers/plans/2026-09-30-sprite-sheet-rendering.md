# Sprite Sheet Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace per-frame procedural Canvas2D character drawing with pre-rendered sprite frames using `drawImage`, reducing draw calls from hundreds per frame to a few per character.

**Architecture:** Hybrid sprite cache — grid-based SpriteAtlas for uniform entities (enemies, bosses), key-value SpriteCache for complex state combinations (player). All frames generated at startup into OffscreenCanvas objects. Runtime renderers use `ctx.drawImage()` for cached content and keep dynamic effects (health bars, particles, lighting) real-time.

**Tech Stack:** HarmonyOS ArkTS strict mode (.ets), Canvas2D API, OffscreenCanvas, ECS architecture (`@qiuyu/engine`)

**Spec:** `docs/superpowers/specs/2026-09-30-sprite-sheet-rendering-design.md`

## Global Constraints

- HarmonyOS ArkTS strict mode: all variables, parameters, and return types must have explicit type annotations
- No `any` type — use `Object` for unknown types, cast with `as`
- All art is procedural — no external image assets
- OffscreenCanvas for pre-rendering (verify HarmonyOS support; fallback to real-time if unsupported)
- `frameCount` is the universal animation driver (incremented every tick)
- Weapon and transform form rendering stays real-time (not converted to sprites)
- Dynamic effects (particles, lighting, health bars, damage numbers) stay real-time

## File Structure

```
New files:
  entry/src/main/ets/game/sprites/SpriteAtlas.ets          — Grid-based atlas (enemies/bosses)
  entry/src/main/ets/game/sprites/SpriteCache.ets           — Key-value cache (player)
  entry/src/main/ets/game/sprites/SpriteManager.ets          — Unified coordinator
  entry/src/main/ets/game/sprites/EnemySpriteGenerator.ets   — Enemy drawing fns + atlas generation
  entry/src/main/ets/game/sprites/BossSpriteGenerator.ets    — Boss drawing fns + atlas generation
  entry/src/main/ets/game/sprites/PlayerSpriteGenerator.ets  — Player body drawing fn + cache generation

Modified files:
  entry/src/main/ets/game/GameScene.ets                      — Add SpriteManager, async init, pass to renderers
  entry/src/main/ets/game/renderers/EnemyRenderer.ets         — Use atlas drawImage, import drawing fns as fallback
  entry/src/main/ets/game/renderers/BossRenderer.ets          — Use atlas drawImage, import drawing fns as fallback
  entry/src/main/ets/game/renderers/BossFormsRenderer.ets     — Delegate to extracted fns (fallback path)
  entry/src/main/ets/game/renderers/PlayerRenderer.ets        — Use cache drawImage for body
  entry/src/main/ets/pages/Index.ets                          — Wire async sprite generation into startup
```

---

### Task 1: SpriteAtlas and SpriteCache Core Infrastructure

**Files:**
- Create: `entry/src/main/ets/game/sprites/SpriteAtlas.ets`
- Create: `entry/src/main/ets/game/sprites/SpriteCache.ets`

**Interfaces:**
- Produces: `SpriteAtlas` class (canvas, cellW, cellH, cols, getFrame), `SpriteCache` class (get, set, has, keys)
- Consumed by: Task 5 (EnemySpriteGenerator), Task 6 (BossSpriteGenerator), Task 7 (PlayerSpriteGenerator), Task 9 (EnemyRenderer), Task 10 (BossRenderer), Task 11 (PlayerRenderer)

- [ ] **Step 1: Create SpriteAtlas**

```typescript
// entry/src/main/ets/game/sprites/SpriteAtlas.ets

export class SpriteAtlas {
  readonly canvas: OffscreenCanvas;
  readonly cellW: number;
  readonly cellH: number;
  readonly cols: number;
  readonly rows: number;
  readonly frameCount: number;

  constructor(canvas: OffscreenCanvas, cellW: number, cellH: number, frameCount: number) {
    this.canvas = canvas;
    this.cellW = cellW;
    this.cellH = cellH;
    this.cols = Math.ceil(Math.sqrt(frameCount));
    this.rows = Math.ceil(frameCount / this.cols);
    this.frameCount = frameCount;
  }

  getFrame(index: number): { sx: number, sy: number } {
    const col: number = index % this.cols;
    const row: number = Math.floor(index / this.cols);
    return { sx: col * this.cellW, sy: row * this.cellH };
  }
}
```

- [ ] **Step 2: Create SpriteCache**

```typescript
// entry/src/main/ets/game/sprites/SpriteCache.ets

export class SpriteCache {
  private frames: Map<string, OffscreenCanvas> = new Map<string, OffscreenCanvas>();

  get(key: string): OffscreenCanvas | undefined {
    return this.frames.get(key);
  }

  set(key: string, canvas: OffscreenCanvas): void {
    this.frames.set(key, canvas);
  }

  has(key: string): boolean {
    return this.frames.has(key);
  }

  size(): number {
    return this.frames.size;
  }
}
```

- [ ] **Step 3: Compile and verify**

Run: Build the project to verify no type errors.
Expected: No compilation errors.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/sprites/SpriteAtlas.ets entry/src/main/ets/game/sprites/SpriteCache.ets
git commit -m "feat(sprites): add SpriteAtlas and SpriteCache core data structures"
```

---

### Task 2: Extract Enemy Drawing Functions

**Files:**
- Create: `entry/src/main/ets/game/sprites/EnemySpriteGenerator.ets` (drawing functions + generator skeleton)

**Interfaces:**
- Consumes: GameConstants (EnemyType, color constants), CanvasRenderingContext2D
- Produces: 6 pure drawing functions (`drawGraySlime`, `drawPurpleSlime`, `drawRedSlime`, `drawBlueSlime`, `drawYellowSlime`, `drawGhostSlime`) + `generateEnemyAtlas` function
- Consumed by: Task 5 (SpriteManager calls generateEnemyAtlas), Task 9 (EnemyRenderer imports drawing fns as fallback)

**Design notes:**
- Each function draws the enemy centered at (0, 0) on the canvas — no translate/scale
- Parameters: `ctx`, `bouncePhase` (radians), `size` (pixel size, scale = size/48), `flash` (boolean), `frameCount` (for secondary animations)
- For `drawRedSlime`: additional `isCharging` parameter
- All drawing code extracted verbatim from EnemyRenderer lines 47-673, replacing `cx`/`cy` with `0`
- Scale factor `sc = size / 48` computed inside each function

- [ ] **Step 1: Extract drawGraySlime function**

Extract the drawing code from EnemyRenderer lines 47-120 into a pure function. Replace `cx`/`cy` with `0`:

```typescript
// In EnemySpriteGenerator.ets

export function drawGraySlime(
  c: CanvasRenderingContext2D,
  bouncePhase: number,
  size: number,
  flash: boolean,
  frameCount: number
): void {
  const sc: number = size / 48;
  const bounce: number = Math.sin(bouncePhase) * 3 * sc;
  const squash: number = 1 + Math.sin(bouncePhase) * 0.12;

  // Shadow
  c.globalAlpha = 0.2;
  c.fillStyle = '#000000';
  c.beginPath();
  c.ellipse(0, bounce + 14 * sc, 13 * sc, 3 * sc, 0, 0, Math.PI * 2);
  c.fill();

  // Body (with squash/stretch applied via save/scale)
  c.save();
  c.translate(0, bounce);
  c.scale(squash, 1 / squash);

  if (flash) {
    c.globalAlpha = 0.9;
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
    c.fill();
  } else {
    // Outline
    c.strokeStyle = '#1a1a2e';
    c.lineWidth = 2 * sc;
    c.globalAlpha = 0.8;
    c.beginPath();
    c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
    c.stroke();
    // Body fill
    c.globalAlpha = 0.9;
    c.fillStyle = COLOR_SLIME_GRAY;
    c.beginPath();
    c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
    c.fill();
    // Highlight
    c.fillStyle = COLOR_SLIME_GRAY_LIGHT;
    c.beginPath();
    c.ellipse(-3 * sc, -4 * sc, 6 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
    c.fill();
    // Specular highlight
    c.fillStyle = '#ffffff';
    c.globalAlpha = 0.45;
    c.beginPath();
    c.ellipse(-5 * sc, -6 * sc, 2.5 * sc, 1.8 * sc, -0.2, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 0.2;
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(4 * sc, 3 * sc, 2 * sc, 1.5 * sc, 0.3, 0, Math.PI * 2);
    c.fill();
  }

  c.globalAlpha = 1.0;

  // Eyes (always visible)
  c.fillStyle = '#ffffff';
  c.beginPath();
  c.ellipse(-4 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
  c.fill();
  c.beginPath();
  c.ellipse(4 * sc, -1 * sc, 3 * sc, 3.2 * sc, 0, 0, Math.PI * 2);
  c.fill();

  if (!flash) {
    // Pupils
    c.fillStyle = COLOR_SLIME_PUPIL;
    c.beginPath();
    c.arc(-3.5 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4.5 * sc, -0.5 * sc, 1.5 * sc, 0, Math.PI * 2);
    c.fill();
    // Eye shine
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.arc(-4 * sc, -1.2 * sc, 0.6 * sc, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4 * sc, -1.2 * sc, 0.6 * sc, 0, Math.PI * 2);
    c.fill();
    // Mouth
    c.strokeStyle = COLOR_SLIME_PUPIL;
    c.lineWidth = 1 * sc;
    c.beginPath();
    c.arc(0, 3.5 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
    c.stroke();
  }

  c.restore();
}
```

- [ ] **Step 2: Extract drawPurpleSlime function**

Extract from EnemyRenderer lines 121-239. Same pattern — replace `cx`/`cy` with `0`. Key differences from gray: glow effect, 4 tentacles, drip animation, engulfing mouth. All use `frameCount` for animation timing.

The purple slime has an `ai.isEngulfing` branch (line 223). Add `isEngulfing: boolean` as a parameter so the drawing function is pure. This parameter determines whether the engulfing mouth variant is drawn.

```typescript
export function drawPurpleSlime(
  c: CanvasRenderingContext2D,
  bouncePhase: number,
  size: number,
  flash: boolean,
  frameCount: number,
  isEngulfing: boolean
): void {
  const sc: number = size / 48;
  const bounce: number = Math.sin(bouncePhase * 1.3) * 1.5 * sc;

  c.save();
  c.translate(0, bounce);

  // ... (copy lines 125-238 from EnemyRenderer, replacing cx→0, cy→0)
  // Replace `ai.isEngulfing` with the `isEngulfing` parameter

  c.restore();
}
```

- [ ] **Step 3: Extract drawRedSlime function**

Extract from EnemyRenderer lines 240-346. Add `isCharging: boolean` parameter. Replace `cx`/`cy` with `0`. The charge value is computed from `frameCount` and `isCharging`.

```typescript
export function drawRedSlime(
  c: CanvasRenderingContext2D,
  bouncePhase: number,
  size: number,
  flash: boolean,
  frameCount: number,
  isCharging: boolean
): void {
  // ... (copy lines 241-345 from EnemyRenderer, replacing cx→0, cy→0)
}
```

- [ ] **Step 4: Extract drawBlueSlime function**

Extract from EnemyRenderer lines 347-447. Replace `cx`/`cy` with `0`.

```typescript
export function drawBlueSlime(
  c: CanvasRenderingContext2D,
  bouncePhase: number,
  size: number,
  flash: boolean,
  frameCount: number
): void {
  // ... (copy lines 348-447 from EnemyRenderer, replacing cx→0, cy→0)
}
```

- [ ] **Step 5: Extract drawYellowSlime function**

Extract from EnemyRenderer lines 448-564. Replace `cx`/`cy` with `0`. Note: contains `Math.random()` for lightning (line 478) — for pre-rendering, use `frameCount` as deterministic seed: `const doLightning: boolean = (frameCount % 10 < 3)`.

```typescript
export function drawYellowSlime(
  c: CanvasRenderingContext2D,
  bouncePhase: number,
  size: number,
  flash: boolean,
  frameCount: number
): void {
  // ... (copy lines 449-563 from EnemyRenderer, replacing cx→0, cy→0)
  // Replace: if (Math.random() < 0.3) → if (frameCount % 10 < 3)
}
```

- [ ] **Step 6: Extract drawGhostSlime function**

Extract from EnemyRenderer lines 565-672. Replace `cx`/`cy` with `0`.

```typescript
export function drawGhostSlime(
  c: CanvasRenderingContext2D,
  bouncePhase: number,
  size: number,
  flash: boolean,
  frameCount: number
): void {
  // ... (copy lines 566-672 from EnemyRenderer, replacing cx→0, cy→0)
}
```

- [ ] **Step 7: Compile and verify extraction**

Run: Build the project. The drawing functions are not yet called but must compile.
Expected: No type errors.

- [ ] **Step 8: Commit**

```bash
git add entry/src/main/ets/game/sprites/EnemySpriteGenerator.ets
git commit -m "feat(sprites): extract enemy drawing functions into pure functions"
```

---

### Task 3: Extract Boss Drawing Functions

**Files:**
- Create: `entry/src/main/ets/game/sprites/BossSpriteGenerator.ets` (drawing functions + generator skeleton)

**Interfaces:**
- Consumes: GameConstants (BossType, BossPhase, BOSS_SIZE, color constants), BossAIComponent, CanvasRenderingContext2D
- Produces: 5 pure drawing functions (`drawCrystalGuardian`, `drawMushroomKing`, `drawLavaBeast`, `drawAbyssSiren`, `drawVoidRift`) + `generateBossAtlas` function
- Consumed by: Task 5 (SpriteManager), Task 10 (BossRenderer fallback)

**Design notes:**
- Extract from BossFormsRenderer.ets methods (lines 10-571)
- Each function draws boss centered at (0, 0) — replace `sx`/`sy` with `0`
- Parameters: `ctx`, `halfSize`, `pulse`, `color`, `ai` (BossAIComponent), `t` (frameCount)
- Boss animation is purely time-driven (frameCount), no player-dependent state
- Bosses have 2 phases — generate separate frames for each phase

- [ ] **Step 1: Extract drawCrystalGuardian**

Extract from BossFormsRenderer.renderCrystalGuardian (lines 10-100ish). Replace `sx`→`0`, `sy`→`0`.

```typescript
// In BossSpriteGenerator.ets

import { BossAIComponent } from '../components/BossAIComponent';

export function drawCrystalGuardian(
  c: CanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Copy body of BossFormsRenderer.renderCrystalGuardian,
  // replacing sx→0, sy→0 throughout
}
```

- [ ] **Step 2: Extract drawMushroomKing**

Extract from BossFormsRenderer.renderMushroomKing. Same pattern.

```typescript
export function drawMushroomKing(
  c: CanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Copy body, replacing sx→0, sy→0
}
```

- [ ] **Step 3: Extract drawLavaBeast**

```typescript
export function drawLavaBeast(
  c: CanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Copy body, replacing sx→0, sy→0
}
```

- [ ] **Step 4: Extract drawAbyssSiren**

```typescript
export function drawAbyssSiren(
  c: CanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Copy body, replacing sx→0, sy→0
}
```

- [ ] **Step 5: Extract drawVoidRift**

```typescript
export function drawVoidRift(
  c: CanvasRenderingContext2D,
  halfSize: number,
  pulse: number,
  color: string,
  ai: BossAIComponent,
  t: number
): void {
  // Copy body, replacing sx→0, sy→0
}
```

- [ ] **Step 6: Compile and verify**

Run: Build the project.
Expected: No type errors.

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/game/sprites/BossSpriteGenerator.ets
git commit -m "feat(sprites): extract boss drawing functions into pure functions"
```

---

### Task 4: Extract Player Body Drawing Function

**Files:**
- Create: `entry/src/main/ets/game/sprites/PlayerSpriteGenerator.ets` (drawing function + generator skeleton)

**Interfaces:**
- Consumes: GameConstants (GenderType, color constants, PLAYER_SIZE), CanvasRenderingContext2D
- Produces: `drawPlayerBody` function + `generatePlayerCache` function
- Consumed by: Task 5 (SpriteManager), Task 11 (PlayerRenderer fallback)

**Design notes:**
- Extract from PlayerRenderer.renderPlayer lines ~110-254 (body drawing code)
- Does NOT include: shadow (drawn separately at runtime), drill (real-time), weapon (real-time), evolution effects (real-time)
- Parameters: `ctx`, `walkPhase` (0-3 discrete), `facingRight` (boolean), `isMoving` (boolean)
- `bobY` is derived from walkPhase: `bobY = Math.sin(walkPhase * Math.PI / 2) * 1.5`
- Gender hardcoded to 0 (MALE) — matches current behavior (PlayerRenderer line 115)
- All pixel coordinates are relative to (screenX, screenY + bobY) — translate to draw at canvas center

- [ ] **Step 1: Create drawPlayerBody function**

```typescript
// In PlayerSpriteGenerator.ets

export function drawPlayerBody(
  c: CanvasRenderingContext2D,
  centerX: number,
  centerY: number,
  walkPhase: number,
  facingRight: boolean,
  isMoving: boolean
): void {
  const bobY: number = Math.sin(walkPhase * Math.PI / 2) * 1.5;
  const walkPhaseSin: number = Math.sin(walkPhase * Math.PI / 2);
  const legSwing: number = isMoving ? walkPhaseSin * 3 : 0;
  const armSwing: number = isMoving ? walkPhaseSin * 2 : 0;
  const screenX: number = centerX;
  const screenY: number = centerY;

  // Gender hardcoded to MALE (matches current PlayerRenderer line 115)
  const bodyColor: string = COLOR_PLAYER_BODY;
  const bodyDarkColor: string = COLOR_PLAYER_BODY_DARK;
  const hairColor: string = COLOR_PLAYER_HAIR;

  // --- Copy body drawing code from PlayerRenderer lines 134-254 ---
  // Replace all (screenX, screenY + bobY) references with the
  // computed screenX/screenY variables above.

  // Legs (lines 134-143)
  // ... (copy verbatim from PlayerRenderer)

  // Torso (lines 145-157)
  // ... (copy verbatim)

  // Arms (lines 159-176)
  // ... (copy verbatim, using armSwing)

  // Head (lines 178-195)
  // ... (copy verbatim)

  // Hair (lines 197-224)
  // ... (copy verbatim)

  // Eyes (lines 226-249, using facingRight for eyeOffX)
  // ... (copy verbatim)

  // Mouth (lines 251-253)
  // ... (copy verbatim)
}
```

**Key mapping from current code:**
- `pc.combat.animFrame` → derive `bobY`, `walkPhase`, `legSwing`, `armSwing` from `walkPhase` parameter
- `isMoving` → from parameter
- `facingRight` → from parameter (currently `Math.cos(pc.movement.facing) >= 0`)
- `gender` → hardcoded to 0 (MALE)

- [ ] **Step 2: Compile and verify**

Run: Build the project.
Expected: No type errors.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/sprites/PlayerSpriteGenerator.ets
git commit -m "feat(sprites): extract player body drawing function"
```

---

### Task 5: Enemy Sprite Atlas Generation

**Files:**
- Modify: `entry/src/main/ets/game/sprites/EnemySpriteGenerator.ets` (add `generateEnemyAtlas` function)

**Interfaces:**
- Consumes: drawing functions from Task 2, SpriteAtlas from Task 1
- Produces: `generateEnemyAtlas(type: EnemyType): SpriteAtlas` function
- Consumed by: Task 8 (SpriteManager.generateAll)

**Frame layout per enemy type:**

| Type | Normal frames | Special frames | Total |
|------|--------------|----------------|-------|
| GRAY_SLIME | 8 (bounce) | — | 8 |
| PURPLE_SLIME | 8 (bounce) | 8 (engulfing) | 16 |
| RED_SLIME | 8 (bounce) | 8 (charging) | 16 |
| BLUE_SLIME | 8 (bounce) | — | 8 |
| YELLOW_SLIME | 8 (bounce) | — | 8 |
| GHOST_SLIME | 8 (bounce) | — | 8 |

Frame index convention:
- Frames 0-7: normal bounce cycle (bouncePhase = i * Math.PI / 4)
- Frames 8-15: flash variant of same bounce phases (for GRAY/BLUE/YELLOW/GHOST) or special state (PURPLE=engulfing, RED=charging)
- At runtime: `frameIndex = (flash ? 8 : 0) + Math.floor(bouncePhase / (Math.PI / 4)) % 8`

Cell size: 64×64 pixels (enough for ~30px slime body + effects + padding)

- [ ] **Step 1: Implement generateEnemyAtlas function**

```typescript
// In EnemySpriteGenerator.ets — add after the drawing functions

import { SpriteAtlas } from './SpriteAtlas';
import { EnemyType } from '../GameConstants';

const ENEMY_CELL_W: number = 64;
const ENEMY_CELL_H: number = 64;
const ENEMY_CANONICAL_SIZE: number = 48; // sc = 1.0
const ENEMY_BOUNCE_FRAMES: number = 8;
const ENEMY_TOTAL_FRAMES: number = 16; // All types get 16 frames

export function generateEnemyAtlas(type: EnemyType): SpriteAtlas {
  const cols: number = 4; // 4 columns → 4 rows for 16 frames
  const rows: number = 4;
  const atlas: OffscreenCanvas = new OffscreenCanvas(cols * ENEMY_CELL_W, rows * ENEMY_CELL_H);
  const actx: CanvasRenderingContext2D = atlas.getContext('2d') as CanvasRenderingContext2D;

  for (let i: number = 0; i < ENEMY_BOUNCE_FRAMES; i++) {
    const bp: number = i * Math.PI / 4;
    const col: number = i % cols;
    const row: number = Math.floor(i / cols);
    const ox: number = col * ENEMY_CELL_W + ENEMY_CELL_W / 2;
    const oy: number = row * ENEMY_CELL_H + ENEMY_CELL_H / 2;

    // Frames 0-7: normal bounce cycle
    drawEnemyFrame(actx, type, ox, oy, bp, false, i, false, false);

    // Frames 8-15: variant bounce cycle (type-dependent)
    const vcol: number = (i + ENEMY_BOUNCE_FRAMES) % cols;
    const vrow: number = Math.floor((i + ENEMY_BOUNCE_FRAMES) / cols);
    const vox: number = vcol * ENEMY_CELL_W + ENEMY_CELL_W / 2;
    const voy: number = vrow * ENEMY_CELL_H + ENEMY_CELL_H / 2;

    if (type === EnemyType.PURPLE_SLIME) {
      // Frames 8-15: engulfing variant (no flash frames; flash via overlay at runtime)
      drawEnemyFrame(actx, type, vox, voy, bp, false, i, false, true);
    } else if (type === EnemyType.RED_SLIME) {
      // Frames 8-15: charging variant (no flash frames; flash via overlay at runtime)
      drawEnemyFrame(actx, type, vox, voy, bp, false, i, true, false);
    } else {
      // GRAY/BLUE/YELLOW/GHOST: frames 8-15 = flash variant
      drawEnemyFrame(actx, type, vox, voy, bp, true, i, false, false);
    }
  }

  return new SpriteAtlas(atlas, ENEMY_CELL_W, ENEMY_CELL_H, ENEMY_TOTAL_FRAMES);
}

function drawEnemyFrame(
  c: CanvasRenderingContext2D,
  type: EnemyType,
  cx: number,
  cy: number,
  bouncePhase: number,
  flash: boolean,
  animFrame: number,
  isCharging: boolean,
  isEngulfing: boolean
): void {
  c.save();
  c.translate(cx, cy);

  switch (type) {
    case EnemyType.GRAY_SLIME:
      drawGraySlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame);
      break;
    case EnemyType.PURPLE_SLIME:
      drawPurpleSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame, isEngulfing);
      break;
    case EnemyType.RED_SLIME:
      drawRedSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame, isCharging);
      break;
    case EnemyType.BLUE_SLIME:
      drawBlueSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame);
      break;
    case EnemyType.YELLOW_SLIME:
      drawYellowSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame);
      break;
    case EnemyType.GHOST_SLIME:
      drawGhostSlime(c, bouncePhase, ENEMY_CANONICAL_SIZE, flash, animFrame);
      break;
  }

  c.restore();
}
```

**Frame layout summary:**
- PURPLE_SLIME: frames 0-7 = normal bounce, frames 8-15 = engulfing bounce. Flash handled via white overlay at runtime (Task 9).
- RED_SLIME: frames 0-7 = normal bounce, frames 8-15 = charging bounce. Flash handled via white overlay at runtime.
- GRAY/BLUE/YELLOW/GHOST: frames 0-7 = normal bounce, frames 8-15 = flash bounce.

Runtime frame index computation:

```
// For GRAY/BLUE/YELLOW/GHOST:
frameIndex = (flash ? 8 : 0) + (bounceFrame % 8)

// For PURPLE:
frameIndex = (isEngulfing ? 8 : 0) + (bounceFrame % 8)
// Flash handled via white overlay at runtime

// For RED:
frameIndex = (isCharging ? 8 : 0) + (bounceFrame % 8)
// Flash handled via white overlay at runtime
```

- [ ] **Step 2: Compile and verify generation**

Run: Build the project.
Expected: No type errors.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/sprites/EnemySpriteGenerator.ets
git commit -m "feat(sprites): implement enemy sprite atlas generation"
```

---

### Task 6: Boss Sprite Atlas Generation

**Files:**
- Modify: `entry/src/main/ets/game/sprites/BossSpriteGenerator.ets` (add `generateBossAtlas` function)

**Interfaces:**
- Consumes: drawing functions from Task 3, SpriteAtlas from Task 1, BossAIComponent
- Produces: `generateBossAtlas(type: BossType): SpriteAtlas` function
- Consumed by: Task 8 (SpriteManager.generateAll)

**Frame layout per boss type:**
- 12 frames per boss: animation cycle sampled at 12 points
- `frameCount` values: `i * 60` for i in 0..11 (covers a full animation cycle at ~720 frames ≈ 12 seconds at 60fps, but since most boss animations use `sin(t * 0.05)` etc., the cycle is `2π/0.05 ≈ 126` frames, so 12 samples is sufficient)
- Phase 1 and Phase 2 share the same atlas (phase effects like aura stay real-time)
- Cell size: 128×128 pixels

- [ ] **Step 1: Implement generateBossAtlas function**

```typescript
// In BossSpriteGenerator.ets — add after the drawing functions

import { SpriteAtlas } from './SpriteAtlas';
import { BossType, BOSS_SIZE, getBossColor } from '../GameConstants';
import { BossAIComponent } from '../components/BossAIComponent';

const BOSS_CELL_W: number = 128;
const BOSS_CELL_H: number = 128;
const BOSS_FRAMES: number = 12;

export function generateBossAtlas(type: BossType): SpriteAtlas {
  const cols: number = Math.ceil(Math.sqrt(BOSS_FRAMES));
  const rows: number = Math.ceil(BOSS_FRAMES / cols);
  const atlas: OffscreenCanvas = new OffscreenCanvas(cols * BOSS_CELL_W, rows * BOSS_CELL_H);
  const actx: CanvasRenderingContext2D = atlas.getContext('2d') as CanvasRenderingContext2D;

  const halfSize: number = BOSS_SIZE / 2;
  const bossColor: string = getBossColor(type);

  // Create a minimal BossAIComponent for generation
  const genAI: BossAIComponent = new BossAIComponent();
  genAI.bossType = type;
  genAI.phase = 0; // PHASE_1

  for (let i: number = 0; i < BOSS_FRAMES; i++) {
    const t: number = i * 11; // Sample at intervals that cover animation cycle
    const pulse: number = Math.sin(t * 0.05) * 2;
    const col: number = i % cols;
    const row: number = Math.floor(i / cols);
    const cx: number = col * BOSS_CELL_W + BOSS_CELL_W / 2;
    const cy: number = row * BOSS_CELL_H + BOSS_CELL_H / 2;

    actx.save();
    actx.translate(cx, cy);

    switch (type) {
      case BossType.CRYSTAL_GUARDIAN:
        drawCrystalGuardian(actx, halfSize, pulse, bossColor, genAI, t);
        break;
      case BossType.MUSHROOM_KING:
        drawMushroomKing(actx, halfSize, pulse, bossColor, genAI, t);
        break;
      case BossType.LAVA_BEAST:
        drawLavaBeast(actx, halfSize, pulse, bossColor, genAI, t);
        break;
      case BossType.ABYSS_SIREN:
        drawAbyssSiren(actx, halfSize, pulse, bossColor, genAI, t);
        break;
      case BossType.VOID_RIFT:
        drawVoidRift(actx, halfSize, pulse, bossColor, genAI, t);
        break;
    }

    actx.restore();
  }

  return new SpriteAtlas(atlas, BOSS_CELL_W, BOSS_CELL_H, BOSS_FRAMES);
}
```

**Note:** `getBossColor` must be imported from GameConstants. If it doesn't exist as an exported function, extract it from BossRenderer's local `getBossColor` function.

- [ ] **Step 2: Verify getBossColor is exported**

Check if `getBossColor` exists in GameConstants.ets or BossRenderer.ets. If it's local to BossRenderer, move it to GameConstants or re-export it.

- [ ] **Step 3: Compile and verify**

Run: Build the project.
Expected: No type errors.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/sprites/BossSpriteGenerator.ets
git commit -m "feat(sprites): implement boss sprite atlas generation"
```

---

### Task 7: Player Sprite Cache Generation

**Files:**
- Modify: `entry/src/main/ets/game/sprites/PlayerSpriteGenerator.ets` (add `generatePlayerCache` function)

**Interfaces:**
- Consumes: `drawPlayerBody` from Task 4, SpriteCache from Task 1
- Produces: `generatePlayerCache(): SpriteCache` function
- Consumed by: Task 8 (SpriteManager.generateAll)

**Frame layout:**

| Key | Description |
|-----|-------------|
| `body_idle_R` | Idle, facing right |
| `body_idle_L` | Idle, facing left |
| `body_walk_R_0` | Walk phase 0, facing right |
| `body_walk_R_1` | Walk phase 1, facing right |
| `body_walk_R_2` | Walk phase 2, facing right |
| `body_walk_R_3` | Walk phase 3, facing right |
| `body_walk_L_0` | Walk phase 0, facing left |
| `body_walk_L_1` | Walk phase 1, facing left |
| `body_walk_L_2` | Walk phase 2, facing left |
| `body_walk_L_3` | Walk phase 3, facing left |

Total: 10 frames. Cell size: 64×64 pixels.

- [ ] **Step 1: Implement generatePlayerCache function**

```typescript
// In PlayerSpriteGenerator.ets — add after drawPlayerBody

import { SpriteCache } from './SpriteCache';

const PLAYER_CELL_W: number = 64;
const PLAYER_CELL_H: number = 64;

export function generatePlayerCache(): SpriteCache {
  const cache: SpriteCache = new SpriteCache();
  const centerX: number = PLAYER_CELL_W / 2;
  const centerY: number = PLAYER_CELL_H / 2 + 4; // Slight offset downward to center body

  // Idle frames (walkPhase=0, isMoving=false)
  for (let f: number = 0; f < 2; f++) {
    const facingRight: boolean = f === 0;
    const canvas: OffscreenCanvas = new OffscreenCanvas(PLAYER_CELL_W, PLAYER_CELL_H);
    const ctx: CanvasRenderingContext2D = canvas.getContext('2d') as CanvasRenderingContext2D;
    drawPlayerBody(ctx, centerX, centerY, 0, facingRight, false);
    const key: string = facingRight ? 'body_idle_R' : 'body_idle_L';
    cache.set(key, canvas);
  }

  // Walk frames (4 phases × 2 directions)
  for (let phase: number = 0; phase < 4; phase++) {
    for (let f: number = 0; f < 2; f++) {
      const facingRight: boolean = f === 0;
      const canvas: OffscreenCanvas = new OffscreenCanvas(PLAYER_CELL_W, PLAYER_CELL_H);
      const ctx: CanvasRenderingContext2D = canvas.getContext('2d') as CanvasRenderingContext2D;
      drawPlayerBody(ctx, centerX, centerY, phase, facingRight, true);
      const dir: string = facingRight ? 'R' : 'L';
      const key: string = `body_walk_${dir}_${phase}`;
      cache.set(key, canvas);
    }
  }

  return cache;
}
```

- [ ] **Step 2: Compile and verify**

Run: Build the project.
Expected: No type errors.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/sprites/PlayerSpriteGenerator.ets
git commit -m "feat(sprites): implement player sprite cache generation"
```

---

### Task 8: SpriteManager and GameScene Integration

**Files:**
- Create: `entry/src/main/ets/game/sprites/SpriteManager.ets`
- Modify: `entry/src/main/ets/game/GameScene.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: generators from Tasks 5-7, SpriteAtlas, SpriteCache
- Produces: `SpriteManager` class with `generateAll()`, getters for atlases/cache
- Consumed by: Task 9 (EnemyRenderer), Task 10 (BossRenderer), Task 11 (PlayerRenderer)

- [ ] **Step 1: Create SpriteManager**

```typescript
// entry/src/main/ets/game/sprites/SpriteManager.ets

import { SpriteAtlas } from './SpriteAtlas';
import { SpriteCache } from './SpriteCache';
import { generateEnemyAtlas } from './EnemySpriteGenerator';
import { generateBossAtlas } from './BossSpriteGenerator';
import { generatePlayerCache } from './PlayerSpriteGenerator';
import { EnemyType, BossType } from '../GameConstants';

export class SpriteManager {
  private enemyAtlases: Map<number, SpriteAtlas> = new Map<number, SpriteAtlas>();
  private bossAtlases: Map<number, SpriteAtlas> = new Map<number, SpriteAtlas>();
  private playerCache: SpriteCache = new SpriteCache();
  private ready: boolean = false;

  async generateAll(): Promise<void> {
    const startTime: number = Date.now();

    // Generate enemy atlases
    const enemyTypes: number[] = [0, 1, 2, 3, 4, 5]; // EnemyType values
    for (const t of enemyTypes) {
      this.enemyAtlases.set(t, generateEnemyAtlas(t as EnemyType));
    }

    // Yield to main thread between batches
    await new Promise<void>((resolve: (v: void) => void) => setTimeout(resolve, 0));

    // Generate boss atlases
    const bossTypes: number[] = [0, 1, 2, 3, 4]; // BossType values
    for (const t of bossTypes) {
      this.bossAtlases.set(t, generateBossAtlas(t as BossType));
    }

    await new Promise<void>((resolve: (v: void) => void) => setTimeout(resolve, 0));

    // Generate player cache
    this.playerCache = generatePlayerCache();

    this.ready = true;
    const elapsed: number = Date.now() - startTime;
    console.info(`[SpriteManager] Generated all sprites in ${elapsed}ms`);
  }

  isReady(): boolean {
    return this.ready;
  }

  getEnemyAtlas(type: EnemyType): SpriteAtlas {
    return this.enemyAtlases.get(type as number) as SpriteAtlas;
  }

  getBossAtlas(type: BossType): SpriteAtlas {
    return this.bossAtlases.get(type as number) as SpriteAtlas;
  }

  getPlayerCache(): SpriteCache {
    return this.playerCache;
  }
}
```

- [ ] **Step 2: Integrate into GameScene**

Add SpriteManager field and modify constructor/render:

```typescript
// In GameScene.ets

import { SpriteManager } from './sprites/SpriteManager';

export class GameScene extends Scene {
  // ... existing fields ...
  private spriteManager: SpriteManager = new SpriteManager();

  // Add async init method
  async initSprites(): Promise<void> {
    await this.spriteManager.generateAll();
  }

  getSpriteManager(): SpriteManager {
    return this.spriteManager;
  }

  // Modify render to pass spriteManager to renderers
  render(baseCtx: BaseContext): void {
    // ... existing setup ...
    const sm: SpriteManager = this.spriteManager;

    // Pass sm to renderers (their render signatures will be updated in Tasks 9-11)
    this.tileRenderer.render(w, ctx, camX, camY, sw, sh, s, fc);
    this.effectRenderer.renderLighting(w, ctx, camX, camY, sw, sh, s, fc);
    this.enemyRenderer.render(w, ctx, camX, camY, sw, sh, s, fc, sm);
    this.effectRenderer.render(w, ctx, camX, camY, sw, sh, s, fc);
    this.bossRenderer.render(w, ctx, camX, camY, sw, sh, s, fc, sm);
    this.playerRenderer.render(w, ctx, camX, camY, sw, sh, s, fc, sm);
    this.effectRenderer.renderVignetteAndDamage(w, ctx, camX, camY, sw, sh, s, fc);
    this.uiRenderer.renderMinimap(w, baseCtx.minimapCtx, camX, camY, sw, sh, fc);
  }
}
```

- [ ] **Step 3: Wire async init in Index.ets**

In `Index.ets`, after creating GameScene and before starting the game loop:

```typescript
// After: this.gameScene = new GameScene(this.audio, this.settings, harmonyCtx);
// Add:
await this.gameScene.initSprites();
// Then start the game loop as before
```

Add a loading state variable to show "Generating sprites..." during generation:

```typescript
@State spriteLoading: boolean = true;

// In aboutToAppear or init:
this.spriteLoading = true;
await this.gameScene.initSprites();
this.spriteLoading = false;
```

- [ ] **Step 4: Compile and verify**

Run: Build the project.
Expected: No type errors. Sprite generation runs at startup.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/sprites/SpriteManager.ets entry/src/main/ets/game/GameScene.ets entry/src/main/ets/pages/Index.ets
git commit -m "feat(sprites): add SpriteManager with async generation and GameScene integration"
```

---

### Task 9: Refactor EnemyRenderer to Use Atlas

**Files:**
- Modify: `entry/src/main/ets/game/renderers/EnemyRenderer.ets`

**Interfaces:**
- Consumes: SpriteManager, SpriteAtlas (from Task 1), drawing functions (from Task 2, as fallback)
- Produces: Modified `render` method using `drawImage` for enemy bodies

**Runtime frame index computation:**

```typescript
// For GRAY/BLUE/YELLOW/GHOST (frames 0-7 normal, 8-15 flash):
const bounceFrame: number = Math.floor((bp / (Math.PI * 2)) * 8) % 8;
const frameIndex: number = (flash ? 8 : 0) + bounceFrame;

// For PURPLE (frames 0-7 normal, 8-15 engulfing):
const frameIndex: number = (ai.isEngulfing ? 8 : 0) + bounceFrame;
// Flash: overlay white ellipse at runtime

// For RED (frames 0-7 normal, 8-15 charging):
const frameIndex: number = (ai.isCharging ? 8 : 0) + bounceFrame;
// Flash: overlay white ellipse at runtime
```

- [ ] **Step 1: Update render method signature**

Add `spriteManager` parameter:

```typescript
import { SpriteManager } from '../sprites/SpriteManager';
import { SpriteAtlas } from '../sprites/SpriteAtlas';

render(world: World, ctx: CanvasRenderingContext2D, cameraX: number, cameraY: number,
       screenW: number, screenH: number, settings: GameSettings, frameCount: number,
       spriteManager: SpriteManager | null = null): void {
  // If spriteManager is null or not ready, fall back to procedural rendering
  if (spriteManager === null || !spriteManager.isReady()) {
    this.renderEnemiesProcedural(world, ctx, -cameraX, -cameraY, screenW, screenH, frameCount);
    this.renderXpOrbs(world, ctx, -cameraX, -cameraY, screenW, screenH, frameCount);
    return;
  }
  this.renderEnemiesSprite(world, ctx, -cameraX, -cameraY, screenW, screenH, frameCount, spriteManager);
  this.renderXpOrbs(world, ctx, -cameraX, -cameraY, screenW, screenH, frameCount);
}
```

- [ ] **Step 2: Implement sprite-based rendering**

```typescript
private renderEnemiesSprite(world: World, c: CanvasRenderingContext2D, offX: number, offY: number,
    screenW: number, screenH: number, frameCount: number, sm: SpriteManager): void {
  const enemies: Entity[] = world.queryWithTag('enemy');
  for (let i: number = 0; i < enemies.length; i++) {
    const entity: Entity = enemies[i];
    if (!entity.active) continue;

    const pos: PositionComponent | null = entity.getComponent<PositionComponent>('Position');
    const health: HealthComponent | null = entity.getComponent<HealthComponent>('Health');
    const ai: EnemyAIComponent | null = entity.getComponent<EnemyAIComponent>('enemyAI');
    if (pos === null || health === null || ai === null) continue;

    const screenX: number = pos.x + offX;
    const screenY: number = pos.y + offY;
    if (screenX < -50 || screenX > screenW + 50 || screenY < -50 || screenY > screenH + 50) continue;

    const atlas: SpriteAtlas = sm.getEnemyAtlas(ai.enemyType);
    const bounceFrame: number = Math.floor(((ai.bouncePhase % (Math.PI * 2)) / (Math.PI * 2)) * 8) % 8;
    const flash: boolean = ai.hitFlash > 0;

    let frameIndex: number;
    if (ai.enemyType === EnemyType.PURPLE_SLIME) {
      frameIndex = (ai.isEngulfing ? 8 : 0) + bounceFrame;
    } else if (ai.enemyType === EnemyType.RED_SLIME) {
      frameIndex = (ai.isCharging ? 8 : 0) + bounceFrame;
    } else {
      frameIndex = (flash ? 8 : 0) + bounceFrame;
    }

    const frame: { sx: number, sy: number } = atlas.getFrame(frameIndex);
    const sc: number = ai.size / 48;
    const destW: number = atlas.cellW * sc;
    const destH: number = atlas.cellH * sc;
    const destX: number = screenX - destW / 2;
    const destY: number = screenY - destH / 2;

    c.drawImage(atlas.canvas, frame.sx, frame.sy, atlas.cellW, atlas.cellH,
                destX, destY, destW, destH);

    // Flash overlay for PURPLE/RED (their flash frames aren't in atlas)
    if (flash && (ai.enemyType === EnemyType.PURPLE_SLIME || ai.enemyType === EnemyType.RED_SLIME)) {
      c.globalAlpha = 0.6;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.ellipse(screenX, screenY, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Charging indicator (stays real-time)
    c.globalAlpha = 1.0;
    if (ai.isCharging && ai.enemyType !== EnemyType.RED_SLIME) {
      const halfSize: number = ai.size / 2;
      c.globalAlpha = 0.4;
      c.fillStyle = COLOR_SLIME_RED;
      c.beginPath();
      c.arc(screenX, screenY, halfSize + 6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Health bar (stays real-time)
    if (health.current < health.max) {
      const barW: number = ai.size;
      const barH: number = 3;
      const barY: number = screenY - ai.size / 2 - 6;
      c.fillStyle = '#374151';
      c.fillRect(screenX - barW / 2, barY, barW, barH);
      c.fillStyle = '#ef4444';
      c.fillRect(screenX - barW / 2, barY, barW * (health.current / health.max), barH);
    }
  }
}
```

- [ ] **Step 3: Rename existing renderEnemies to renderEnemiesProcedural**

Rename the current `renderEnemies` method to `renderEnemiesProcedural` for the fallback path.

- [ ] **Step 4: Compile and verify visually**

Run: Build and run. Verify enemies look identical to before. Check:
- All 6 enemy types render correctly
- Bounce animation plays smoothly
- Hit flash works
- Charging indicator shows
- Health bars render
- PURPLE engulfing state shows correctly
- RED charging state shows correctly

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/renderers/EnemyRenderer.ets
git commit -m "feat(sprites): refactor EnemyRenderer to use sprite atlas with procedural fallback"
```

---

### Task 10: Refactor BossRenderer to Use Atlas

**Files:**
- Modify: `entry/src/main/ets/game/renderers/BossRenderer.ets`
- Modify: `entry/src/main/ets/game/renderers/BossFormsRenderer.ets` (fallback delegation)

**Interfaces:**
- Consumes: SpriteManager, SpriteAtlas, drawing functions (from Task 3)
- Produces: Modified `render` method using `drawImage` for boss bodies

**Runtime frame index computation:**

```typescript
// Boss animation is purely time-driven
// 12 frames per boss, cycle length = 12 * 11 = 132 frameCounts
const frameIndex: number = Math.floor((frameCount % 132) / 11);
```

- [ ] **Step 1: Update BossRenderer.render signature**

Add `spriteManager` parameter:

```typescript
import { SpriteManager } from '../sprites/SpriteManager';
import { SpriteAtlas } from '../sprites/SpriteAtlas';

render(world: World, ctx: CanvasRenderingContext2D, cameraX: number, cameraY: number,
       screenW: number, screenH: number, settings: GameSettings, frameCount: number,
       spriteManager: SpriteManager | null = null): void {
  // ... existing material drops and HP bar code unchanged ...
  // For boss body rendering:
  if (spriteManager !== null && spriteManager.isReady()) {
    this.renderBossSprite(c, screenX, screenY, ai, frameCount, spriteManager);
  } else {
    this.renderBossProcedural(c, screenX, screenY, ai, frameCount);
  }
  // Phase 2 aura stays real-time
  if (ai.phase === BossPhase.PHASE_2) {
    this.renderPhase2Aura(c, screenX, screenY, halfSize, pulse, bossColor, frameCount);
  }
}
```

- [ ] **Step 2: Implement renderBossSprite**

```typescript
private renderBossSprite(c: CanvasRenderingContext2D, screenX: number, screenY: number,
    ai: BossAIComponent, frameCount: number, sm: SpriteManager): void {
  const atlas: SpriteAtlas = sm.getBossAtlas(ai.bossType);
  const frameIndex: number = Math.floor((frameCount % (atlas.frameCount * 11)) / 11);
  const frame: { sx: number, sy: number } = atlas.getFrame(frameIndex);

  const halfSize: number = BOSS_SIZE / 2;
  const pulse: number = Math.sin(frameCount * 0.05) * 2;

  // Hit flash: overlay white rectangle
  if (ai.hitFlash > 0) {
    c.globalAlpha = 0.5;
    c.fillStyle = '#ffffff';
    c.fillRect(screenX - halfSize, screenY - halfSize, BOSS_SIZE, BOSS_SIZE);
    c.globalAlpha = 1.0;
  }

  c.drawImage(atlas.canvas, frame.sx, frame.sy, atlas.cellW, atlas.cellH,
              screenX - atlas.cellW / 2, screenY - atlas.cellH / 2,
              atlas.cellW, atlas.cellH);
}
```

- [ ] **Step 3: Extract renderBossProcedural from existing code**

Move existing boss body rendering into `renderBossProcedural` method.

- [ ] **Step 4: Compile and verify visually**

Run: Build and run. Verify:
- All 5 boss types render correctly
- Animation plays smoothly
- Phase 2 aura still renders (real-time)
- Hit flash visible
- Boss HP bar renders correctly
- Material drops render correctly

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/renderers/BossRenderer.ets entry/src/main/ets/game/renderers/BossFormsRenderer.ets
git commit -m "feat(sprites): refactor BossRenderer to use sprite atlas with procedural fallback"
```

---

### Task 11: Refactor PlayerRenderer to Use Cache

**Files:**
- Modify: `entry/src/main/ets/game/renderers/PlayerRenderer.ets`

**Interfaces:**
- Consumes: SpriteManager, SpriteCache, `drawPlayerBody` (from Task 4, as fallback)
- Produces: Modified `renderPlayer` method using `drawImage` for base body

**Runtime cache key computation:**

```typescript
// Determine state
const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;
const dir: string = facingRight ? 'R' : 'L';

let key: string;
if (!isMoving) {
  key = `body_idle_${dir}`;
} else {
  // Map continuous animFrame to discrete walk phase (0-3)
  const walkFrame: number = Math.floor(((pc.combat.animFrame % (Math.PI * 2)) / (Math.PI * 2)) * 4) % 4;
  key = `body_walk_${dir}_${walkFrame}`;
}
```

- [ ] **Step 1: Update render method signature**

Add `spriteManager` parameter:

```typescript
import { SpriteManager } from '../sprites/SpriteManager';
import { SpriteCache } from '../sprites/SpriteCache';

render(world: World, ctx: CanvasRenderingContext2D, cameraX: number, cameraY: number,
       screenW: number, screenH: number, settings: GameSettings, frameCount: number,
       spriteManager: SpriteManager | null = null): void {
  // ... existing component extraction ...
  // Pass spriteManager to renderPlayer
  this.renderPlayer(ctx, offX, offY, pc, spriteManager);
}
```

- [ ] **Step 2: Modify renderPlayer to use cached body**

In the normal (non-transformed, non-engulfed, non-blinking) rendering path:

```typescript
private renderPlayer(c: CanvasRenderingContext2D, offX: number, offY: number,
    pc: PComp, spriteManager: SpriteManager | null = null): void {
  const screenX: number = pc.pos.x + offX;
  const screenY: number = pc.pos.y + offY - pc.movement.jumpHeight;
  const half: number = PLAYER_SIZE / 2;

  // Engulfed state — unchanged (simple real-time draw)
  if (pc.movement.isEngulfed) { /* ... unchanged ... */ return; }

  // Invincibility blink — unchanged
  if (pc.combat.invincibleTimer > 0 && Math.floor(pc.frameCount / 3) % 2 === 0) { return; }

  // Transformed — delegate to TransformFormRenderer (unchanged)
  if (pc.transform.isTransformed) { /* ... unchanged ... */ return; }

  // --- Normal rendering path ---

  // Jump shadow (stays real-time, position-dependent)
  if (pc.movement.isJumping) {
    c.globalAlpha = 0.3;
    c.fillStyle = '#000000';
    c.beginPath();
    c.ellipse(screenX, pc.pos.y + offY + half, half * 0.8, half * 0.3, 0, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;
  }

  // Walking shadow (stays real-time)
  const isMoving: boolean = Math.abs(pc.vel.vx) > 0.1 || Math.abs(pc.vel.vy) > 0.1;
  if (!pc.movement.isJumping) {
    // ... existing shadow code ...
  }

  // Determine cache key
  const facingRight: boolean = Math.cos(pc.movement.facing) >= 0;
  const dir: string = facingRight ? 'R' : 'L';
  let cacheKey: string;
  let cachedBobY: number;

  if (spriteManager !== null && spriteManager.isReady()) {
    const playerCache: SpriteCache = spriteManager.getPlayerCache();
    if (!isMoving) {
      cacheKey = `body_idle_${dir}`;
      cachedBobY = 0;
    } else {
      const walkFrame: number = Math.floor(((pc.combat.animFrame % (Math.PI * 2)) / (Math.PI * 2)) * 4) % 4;
      cacheKey = `body_walk_${dir}_${walkFrame}`;
      cachedBobY = Math.sin(walkFrame * Math.PI / 2) * 1.5;
    }

    const cachedFrame: OffscreenCanvas | undefined = playerCache.get(cacheKey);
    if (cachedFrame !== undefined) {
      // Draw cached body
      c.drawImage(cachedFrame, screenX - 32, screenY - 32);
    } else {
      // Fallback: draw procedurally
      this.drawPlayerBodyProcedural(c, screenX, screenY, pc);
      cachedBobY = Math.sin(pc.combat.animFrame) * 1.5;
    }
  } else {
    // No sprite manager: full procedural fallback
    this.drawPlayerBodyProcedural(c, screenX, screenY, pc);
    cachedBobY = Math.sin(pc.combat.animFrame) * 1.5;
  }

  // Real-time overlays use cachedBobY for consistency with cached body
  this.renderDrill(c, screenX, screenY, pc, cachedBobY);
  this.weaponRenderer.renderWeaponOnPlayer(c, screenX, screenY, pc, cachedBobY);
  this.renderEvolutionEffects(c, screenX, screenY, pc, cachedBobY);
}
```

- [ ] **Step 3: Extract drawPlayerBodyProcedural from existing code**

Move existing body drawing code (lines ~134-254) into a `drawPlayerBodyProcedural` method on PlayerRenderer. This serves as the fallback when sprites aren't available.

- [ ] **Step 4: Compile and verify visually**

Run: Build and run. Verify:
- Player body renders correctly in all states (idle, walking, jumping)
- Facing direction works (left/right)
- Walk animation cycles through frames smoothly
- Weapon and drill overlays align with body (same bobY)
- Evolution effects render correctly
- Transformed states unchanged
- Engulfed state unchanged

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/renderers/PlayerRenderer.ets
git commit -m "feat(sprites): refactor PlayerRenderer to use sprite cache for body with procedural fallback"
```

---

### Task 12: Fallback and Error Handling

**Files:**
- Modify: `entry/src/main/ets/game/sprites/SpriteManager.ets`
- Modify: `entry/src/main/ets/game/GameScene.ets`

**Interfaces:**
- Consumes: all generators
- Produces: Graceful degradation when OffscreenCanvas unavailable or generation fails

- [ ] **Step 1: Wrap generateAll in try-catch**

```typescript
async generateAll(): Promise<void> {
  try {
    // Test OffscreenCanvas support
    const testCanvas: OffscreenCanvas = new OffscreenCanvas(1, 1);
    const testCtx: CanvasRenderingContext2D | null = testCanvas.getContext('2d');
    if (testCtx === null) {
      console.warn('[SpriteManager] OffscreenCanvas 2D context not available, using procedural fallback');
      return;
    }

    const startTime: number = Date.now();
    // ... existing generation code ...
    this.ready = true;
    console.info(`[SpriteManager] Generated all sprites in ${Date.now() - startTime}ms`);
  } catch (e) {
    console.warn(`[SpriteManager] Sprite generation failed: ${e}, using procedural fallback`);
    this.ready = false;
  }
}
```

- [ ] **Step 2: Verify all renderers handle null/unready SpriteManager**

Check that EnemyRenderer, BossRenderer, and PlayerRenderer all:
- Accept `spriteManager: SpriteManager | null = null` parameter
- Check `spriteManager === null || !spriteManager.isReady()` before using sprites
- Fall back to procedural rendering when sprites unavailable

- [ ] **Step 3: Compile and verify fallback**

Test by temporarily disabling sprite generation (set `this.ready = false` in generateAll). Verify:
- Game runs normally with procedural rendering
- No crashes or visual glitches
- Console shows fallback warning

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/sprites/SpriteManager.ets entry/src/main/ets/game/GameScene.ets
git commit -m "feat(sprites): add fallback to procedural rendering when sprites unavailable"
```

---

### Task 13: Visual Verification and Performance Testing

**Files:**
- No file changes (verification only)

- [ ] **Step 1: Visual parity check — Enemies**

Compare each enemy type before/after sprite refactor:
- GRAY_SLIME: bounce animation, eyes, mouth, shadow
- PURPLE_SLIME: glow, tentacles, drip, engulfing mouth
- RED_SLIME: flames, charge glow, angry expression
- BLUE_SLIME: sparkles, ripple, wave lines
- YELLOW_SLIME: star sparks, lightning, cheek blush
- GHOST_SLIME: transparency, wavy body, trail

- [ ] **Step 2: Visual parity check — Bosses**

Compare each boss type:
- CrystalGuardian: diamond facets, spike crown, shimmer
- MushroomKing: cap dome, spore particles, gill lines
- LavaBeast: magma cracks, heat aura, ember particles
- AbyssSiren: scales, tentacles, bubbles
- VoidRift: concentric rings, debris, void eye

- [ ] **Step 3: Visual parity check — Player**

- Idle stance (facing left and right)
- Walk cycle (4 phases, smooth transition)
- Jump (body + shadow separation)
- Weapon overlay alignment during walk
- Drill overlay alignment
- Evolution effects positioning

- [ ] **Step 4: Performance measurement**

Add temporary FPS counter if not already present. Compare:
- FPS before sprite refactor (procedural)
- FPS after sprite refactor (drawImage)
- Startup time for sprite generation (should be < 2 seconds)
- Memory usage (should be ~3MB for sprites)

- [ ] **Step 5: Edge case testing**

- Rapid enemy spawn (many enemies on screen)
- Boss phase transition (phase 1 → phase 2 aura appears)
- Player transform/revert during walk
- Enemy hit flash during animation
- Sprite generation failure (test fallback path)

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat(sprites): complete sprite sheet rendering system — verified visual parity and performance"
```
