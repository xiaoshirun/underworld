# ECS Game Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the monolithic GameEngine (6500 lines) into a reusable ECS (Entity-Component-System) game engine framework for HarmonyOS, with scene management, resource management, and 6 built-in systems.

**Architecture:** Pure ECS with generational entity indices, cached component queries, deferred entity destruction. Scene stack with lifecycle hooks and transitions. Resource manager with async loading and reference counting. Platform layer isolates HarmonyOS APIs from engine core.

**Tech Stack:** HarmonyOS ArkTS (.ets), Canvas2D API, Web Audio (AudioKit), Preferences API for persistence

**Spec:** `docs/superpowers/specs/2026-09-28-ecs-engine-design.md`

## Global Constraints

- Platform: HarmonyOS only, no cross-platform abstraction
- File extension: `.ets` (ArkTS convention, matches existing codebase)
- Engine directory: `entry/src/main/ets/engine/`
- No engine file may import from `game/` (engine must be self-contained)
- All engine APIs use explicit types (ArkTS strict mode, no `any`)
- Existing game functionality must not regress during migration
- Each task ends with a successful compilation check (`hvigorw assembleHap` or DevEco Studio build)

---

## File Structure

### Phase 1: Engine Skeleton (new files)

```
entry/src/main/ets/engine/
  core/
    Entity.ets          — Entity type (number), generational index helpers
    World.ets           — ECS World: entity pool, component storage, system scheduling
    System.ets          — System abstract base class
    Engine.ets          — Engine entry point, main loop, config
  scene/
    Scene.ets           — Scene abstract base class
    SceneManager.ets    — Scene stack, transitions, lifecycle dispatch
  resource/
    ResourceManager.ets — Async loading, caching, reference counting
  systems/
    RenderSystem.ets    — SpriteBatch-based rendering (Phase 2 fills implementation)
    PhysicsSystem.ets   — Physics (Phase 2 fills implementation)
    ParticleSimSystem.ets — Particle simulation (Phase 2 fills implementation)
    InputSystem.ets     — Input consumption (Phase 2 fills implementation)
    AudioSystem.ets     — Audio playback control (Phase 2 fills implementation)
    CameraSystem.ets    — Camera follow, shake, bounds (Phase 2 fills implementation)
  components/
    Transform.ets       — Position, rotation, scale, zIndex
    Sprite.ets          — Color, dimensions, visibility, alpha
    AnimatedSprite.ets  — Frame animation data
    Collider.ets        — Collision body (box/circle), trigger, layers
    RigidBody.ets       — Velocity, mass, gravity, friction
    Camera.ets          — Follow target, lerp, shake, zoom
    ParticleEmitter.ets — Emitter config, mode, lifetime
    Health.ets          — Current/max HP, invincibility timer
    AI.ets              — AI type, speed, detect range, state
    PlayerInput.ets     — Movement, button flags
    Light.ets           — Color, radius, intensity, flicker
    Tag.ets             — String tags for query grouping
    AudioSource.ets     — Sound ID, volume, loop, spatial
    TilemapCollider.ets — Tile map data for terrain collision
  platform/
    HarmonyOSPlatform.ets — Static bridge to HarmonyOS system APIs
```

### Phase 2: Migrated modules

```
engine/systems/PhysicsSystem.ets      ← game/PhysicsEngine.ets (wrapped as System)
engine/systems/ParticleSimSystem.ets  ← game/ParticleSystem.ets (wrapped as System)
engine/systems/RenderSystem.ets       ← game/SpriteBatch.ets (used as rendering backend)
engine/platform/HarmonyOSPlatform.ets ← game/AudioManager.ets synthesis (extracted)
```

### Phase 3: Game logic split (new game-level systems + renderers)

```
entry/src/main/ets/game/systems/
  PlayerMovementSystem.ets
  PlayerCombatSystem.ets
  TransformSystem.ets
  EnemyAISystem.ets
  BossSystem.ets
  TrapSystem.ets
  MechanismSystem.ets
  ChunkLoadSystem.ets
  DamageSystem.ets
  XpLevelSystem.ets
  ChestSystem.ets
  MaterialDropSystem.ets
  EvolutionSystem.ets
  SaveLoadSystem.ets

entry/src/main/ets/game/renderers/
  TileRenderer.ets
  PlayerRenderer.ets
  EnemyRenderer.ets
  BossRenderer.ets
  EffectRenderer.ets
  UIRenderer.ets
  TransformRenderer.ets

entry/src/main/ets/game/
  GameScene.ets       — Registers all game systems, creates entities
  MainMenuScene.ets   — Main menu scene
```

### Phase 4: UI adaptation

```
entry/src/main/ets/pages/Index.ets  — Modified to use Engine entry point
```

---

## Phase 1: Engine Skeleton

### Task 1: Entity Type and Generational Index

**Files:**
- Create: `entry/src/main/ets/engine/core/Entity.ets`

**Interfaces:**
- Produces: `Entity` type alias, `EntityPool` class with `acquire()`, `release(entity)`, `isValid(entity)`, `getGeneration(entity)`, `getIndex(entity)`

- [ ] **Step 1: Create Entity.ets with type and helpers**

```typescript
// entry/src/main/ets/engine/core/Entity.ets

export type Entity = number;

const INDEX_MASK: number = 0xFFFF;
const GENERATION_SHIFT: number = 16;

export function makeEntity(index: number, generation: number): Entity {
  return (generation << GENERATION_SHIFT) | index;
}

export function getIndex(entity: Entity): number {
  return entity & INDEX_MASK;
}

export function getGeneration(entity: Entity): number {
  return entity >> GENERATION_SHIFT;
}

export class EntityPool {
  private generations: number[] = [];
  private available: number[] = [];
  private alive: boolean[] = [];
  private nextIndex: number = 0;

  acquire(): Entity {
    if (this.available.length > 0) {
      const index: number = this.available.pop()!;
      this.alive[index] = true;
      return makeEntity(index, this.generations[index]);
    }
    const index: number = this.nextIndex;
    this.nextIndex++;
    this.generations[index] = 0;
    this.alive[index] = true;
    return makeEntity(index, 0);
  }

  release(entity: Entity): void {
    const index: number = getIndex(entity);
    if (!this.alive[index]) return;
    this.alive[index] = false;
    this.generations[index]++;
    this.available.push(index);
  }

  isValid(entity: Entity): boolean {
    const index: number = getIndex(entity);
    const generation: number = getGeneration(entity);
    return index < this.nextIndex &&
      this.alive[index] === true &&
      this.generations[index] === generation;
  }

  isAlive(index: number): boolean {
    return index < this.nextIndex && this.alive[index] === true;
  }
}
```

- [ ] **Step 2: Compile verify**

Run: DevEco Studio Build > Build Hap(s)/App(s) or `hvigorw assembleHap --no-daemon`
Expected: BUILD SUCCESSFUL, no errors in Entity.ets

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/core/Entity.ets
git commit -m "feat(engine): add Entity type with generational index pool"
```

---

### Task 2: System Base Class

**Files:**
- Create: `entry/src/main/ets/engine/core/System.ets`

**Interfaces:**
- Consumes: `World` (forward reference, imported as type)
- Produces: `System` abstract class

- [ ] **Step 1: Create System.ets**

```typescript
// entry/src/main/ets/engine/core/System.ets

import { World } from './World';

export abstract class System {
  abstract readonly name: string;
  abstract readonly dependencies: string[];
  priority: number = 0;
  enabled: boolean = true;

  abstract update(world: World, dt: number, entities: Entity[]): void;

  render?(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void;

  onAdd?(world: World): void;
  onRemove?(world: World): void;
}

import { Entity } from './Entity';
```

Note: ArkTS requires imports at top. Reorder:

```typescript
// entry/src/main/ets/engine/core/System.ets

import { Entity } from './Entity';
import { World } from './World';

export abstract class System {
  abstract readonly name: string;
  abstract readonly dependencies: string[];
  priority: number = 0;
  enabled: boolean = true;

  abstract update(world: World, dt: number, entities: Entity[]): void;

  render?(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void;

  onAdd?(world: World): void;
  onRemove?(world: World): void;
}
```

- [ ] **Step 2: Compile verify**

Expected: May fail due to circular import with World. This is resolved by the next task. If World.ets doesn't exist yet, create a minimal stub first.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/core/System.ets
git commit -m "feat(engine): add System abstract base class"
```

---

### Task 3: World — ECS Core Container

**Files:**
- Create: `entry/src/main/ets/engine/core/World.ets`

**Interfaces:**
- Consumes: `Entity`, `EntityPool` from Entity.ets; `System` from System.ets
- Produces: `World` class with full entity/component/system management

- [ ] **Step 1: Create World.ets**

```typescript
// entry/src/main/ets/engine/core/World.ets

import { Entity, EntityPool, getIndex } from './Entity';
import { System } from './System';

interface ComponentEntry {
  data: Map<number, Object>;
}

export class World {
  private pool: EntityPool = new EntityPool();
  private components: Map<string, ComponentEntry> = new Map();
  private systems: System[] = [];
  private systemsByName: Map<string, System> = new Map();
  private pendingDestroy: Entity[] = [];
  private queryCache: Map<string, Entity[]> = new Map();
  private cacheDirty: Set<string> = new Set();

  createEntity(): Entity {
    const entity: Entity = this.pool.acquire();
    this.invalidateAllQueries();
    return entity;
  }

  destroyEntity(entity: Entity): void {
    this.pendingDestroy.push(entity);
  }

  private processPendingDestroys(): void {
    if (this.pendingDestroy.length === 0) return;
    for (const entity of this.pendingDestroy) {
      if (!this.pool.isValid(entity)) continue;
      const index: number = getIndex(entity);
      this.components.forEach((entry: ComponentEntry) => {
        entry.data.delete(index);
      });
      this.pool.release(entity);
    }
    this.pendingDestroy = [];
    this.invalidateAllQueries();
  }

  addComponent<T extends Object>(entity: Entity, tag: string, component: T): void {
    const index: number = getIndex(entity);
    let entry: ComponentEntry | undefined = this.components.get(tag);
    if (!entry) {
      entry = { data: new Map<number, Object>() };
      this.components.set(tag, entry);
    }
    entry.data.set(index, component);
    this.invalidateQueriesFor(tag);
  }

  getComponent<T>(entity: Entity, tag: string): T | undefined {
    const index: number = getIndex(entity);
    const entry: ComponentEntry | undefined = this.components.get(tag);
    if (!entry) return undefined;
    return entry.data.get(index) as T | undefined;
  }

  removeComponent(entity: Entity, tag: string): void {
    const index: number = getIndex(entity);
    const entry: ComponentEntry | undefined = this.components.get(tag);
    if (!entry) return;
    entry.data.delete(index);
    this.invalidateQueriesFor(tag);
  }

  hasComponent(entity: Entity, tag: string): boolean {
    const index: number = getIndex(entity);
    const entry: ComponentEntry | undefined = this.components.get(tag);
    if (!entry) return false;
    return entry.data.has(index);
  }

  query(...tags: string[]): Entity[] {
    const cacheKey: string = tags.sort().join(',');
    const cached: Entity[] | undefined = this.queryCache.get(cacheKey);
    if (cached && !this.cacheDirty.has(cacheKey)) {
      return cached;
    }

    const result: Entity[] = [];
    const entries: ComponentEntry[] = [];
    for (const tag of tags) {
      const entry: ComponentEntry | undefined = this.components.get(tag);
      if (!entry) {
        this.queryCache.set(cacheKey, []);
        return [];
      }
      entries.push(entry);
    }

    entries.sort((a: ComponentEntry, b: ComponentEntry): number => a.data.size - b.data.size);
    const smallest: Map<number, Object> = entries[0].data;

    smallest.forEach((_value: Object, index: number) => {
      let match: boolean = true;
      for (let i: number = 1; i < entries.length; i++) {
        if (!entries[i].data.has(index)) {
          match = false;
          break;
        }
      }
      if (match) {
        result.push(makeEntityFromIndex(index));
      }
    });

    this.queryCache.set(cacheKey, result);
    this.cacheDirty.delete(cacheKey);
    return result;
  }

  addSystem(system: System): void {
    this.systems.push(system);
    this.systemsByName.set(system.name, system);
    this.sortSystems();
    if (system.onAdd) {
      system.onAdd(this);
    }
  }

  removeSystem(name: string): void {
    const system: System | undefined = this.systemsByName.get(name);
    if (!system) return;
    if (system.onRemove) {
      system.onRemove(this);
    }
    const idx: number = this.systems.indexOf(system);
    if (idx >= 0) this.systems.splice(idx, 1);
    this.systemsByName.delete(name);
  }

  getSystem(name: string): System | undefined {
    return this.systemsByName.get(name);
  }

  update(dt: number): void {
    for (const system of this.systems) {
      if (!system.enabled) continue;
      const entities: Entity[] = this.query();
      system.update(this, dt, entities);
    }
    this.processPendingDestroys();
  }

  render(ctx: CanvasRenderingContext2D): void {
    for (const system of this.systems) {
      if (!system.enabled || !system.render) continue;
      const entities: Entity[] = this.query();
      system.render(this, ctx, entities);
    }
  }

  isEntityAlive(entity: Entity): boolean {
    return this.pool.isValid(entity);
  }

  getEntityCount(): number {
    let count: number = 0;
    this.components.forEach((entry: ComponentEntry) => {
      if (entry.data.size > count) count = entry.data.size;
    });
    return count;
  }

  private sortSystems(): void {
    this.systems.sort((a: System, b: System): number => {
      if (a.priority !== b.priority) return a.priority - b.priority;
      if (a.dependencies.indexOf(b.name) >= 0) return 1;
      if (b.dependencies.indexOf(a.name) >= 0) return -1;
      return 0;
    });
  }

  private invalidateQueriesFor(tag: string): void {
    this.queryCache.forEach((_value: Entity[], key: string) => {
      if (key.indexOf(tag) >= 0) {
        this.cacheDirty.add(key);
      }
    });
  }

  private invalidateAllQueries(): void {
    this.queryCache.forEach((_value: Entity[], key: string) => {
      this.cacheDirty.add(key);
    });
  }
}

function makeEntityFromIndex(index: number): Entity {
  return index;
}
```

Note: The `query()` method returns all entities when called with no tags. Systems that need specific component combinations should pass tags. The `makeEntityFromIndex` helper creates an Entity from just an index (generation is looked up during component access). For Phase 1, this is sufficient; Phase 2 will refine generation tracking in queries.

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL. World.ets + Entity.ets + System.ets should compile together.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/core/World.ets
git commit -m "feat(engine): add World class with entity pool, component storage, query cache"
```

---

### Task 4: All 14 Built-in Components

**Files:**
- Create: `entry/src/main/ets/engine/components/Transform.ets`
- Create: `entry/src/main/ets/engine/components/Sprite.ets`
- Create: `entry/src/main/ets/engine/components/AnimatedSprite.ets`
- Create: `entry/src/main/ets/engine/components/Collider.ets`
- Create: `entry/src/main/ets/engine/components/RigidBody.ets`
- Create: `entry/src/main/ets/engine/components/Camera.ets`
- Create: `entry/src/main/ets/engine/components/ParticleEmitterComp.ets`
- Create: `entry/src/main/ets/engine/components/Health.ets`
- Create: `entry/src/main/ets/engine/components/AI.ets`
- Create: `entry/src/main/ets/engine/components/PlayerInput.ets`
- Create: `entry/src/main/ets/engine/components/Light.ets`
- Create: `entry/src/main/ets/engine/components/Tag.ets`
- Create: `entry/src/main/ets/engine/components/AudioSource.ets`
- Create: `entry/src/main/ets/engine/components/TilemapCollider.ets`

**Interfaces:**
- Produces: 14 pure data interfaces, no logic methods

- [ ] **Step 1: Create all component files**

Each component is a pure data interface with a factory function:

```typescript
// entry/src/main/ets/engine/components/Transform.ets
export interface Transform {
  x: number;
  y: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
  zIndex: number;
}

export function createTransform(x: number, y: number): Transform {
  return { x: x, y: y, rotation: 0, scaleX: 1, scaleY: 1, zIndex: 0 };
}
```

```typescript
// entry/src/main/ets/engine/components/Sprite.ets
export interface Sprite {
  color: string;
  width: number;
  height: number;
  visible: boolean;
  alpha: number;
  flipX: boolean;
}

export function createSprite(color: string, width: number, height: number): Sprite {
  return { color: color, width: width, height: height, visible: true, alpha: 1.0, flipX: false };
}
```

```typescript
// entry/src/main/ets/engine/components/AnimatedSprite.ets
export interface AnimatedSprite {
  frames: string[];
  currentFrame: number;
  frameDuration: number;
  elapsed: number;
  loop: boolean;
  playing: boolean;
}

export function createAnimatedSprite(frames: string[], frameDuration: number): AnimatedSprite {
  return { frames: frames, currentFrame: 0, frameDuration: frameDuration, elapsed: 0, loop: true, playing: true };
}
```

```typescript
// entry/src/main/ets/engine/components/Collider.ets
export type ColliderType = 'box' | 'circle';

export interface Collider {
  type: ColliderType;
  width: number;
  height: number;
  radius: number;
  offsetX: number;
  offsetY: number;
  isTrigger: boolean;
  layer: number;
  mask: number;
  onCollisionEnter: boolean;
}

export function createBoxCollider(w: number, h: number): Collider {
  return { type: 'box', width: w, height: h, radius: 0, offsetX: 0, offsetY: 0, isTrigger: false, layer: 0, mask: 0xFFFF, onCollisionEnter: false };
}

export function createCircleCollider(radius: number): Collider {
  return { type: 'circle', width: 0, height: 0, radius: radius, offsetX: 0, offsetY: 0, isTrigger: false, layer: 0, mask: 0xFFFF, onCollisionEnter: false };
}
```

```typescript
// entry/src/main/ets/engine/components/RigidBody.ets
export interface RigidBody {
  vx: number;
  vy: number;
  mass: number;
  gravityScale: number;
  friction: number;
  bounciness: number;
  isKinematic: boolean;
  onGround: boolean;
  onWall: boolean;
}

export function createRigidBody(): RigidBody {
  return { vx: 0, vy: 0, mass: 1.0, gravityScale: 1.0, friction: 0.85, bounciness: 0.0, isKinematic: false, onGround: false, onWall: false };
}
```

```typescript
// entry/src/main/ets/engine/components/Camera.ets
export interface CameraComponent {
  followEntity: number;
  lerpSpeed: number;
  offsetX: number;
  offsetY: number;
  shakeIntensity: number;
  shakeTimer: number;
  shakeDecay: number;
  zoom: number;
  worldMinX: number;
  worldMinY: number;
  worldMaxX: number;
  worldMaxY: number;
}

export function createCamera(): CameraComponent {
  return { followEntity: -1, lerpSpeed: 0.1, offsetX: 0, offsetY: 0, shakeIntensity: 0, shakeTimer: 0, shakeDecay: 0.9, zoom: 1.0, worldMinX: -99999, worldMinY: -99999, worldMaxX: 99999, worldMaxY: 99999 };
}
```

```typescript
// entry/src/main/ets/engine/components/ParticleEmitterComp.ets
export interface ParticleEmitterComponent {
  emitRate: number;
  lifetime: number;
  elapsed: number;
  active: boolean;
  maxParticles: number;
  config: ParticleEmitterConfig;
}

export interface ParticleEmitterConfig {
  speedMin: number;
  speedMax: number;
  angleMin: number;
  angleMax: number;
  lifeMin: number;
  lifeMax: number;
  sizeMin: number;
  sizeMax: number;
  endSizeMin: number;
  endSizeMax: number;
  colors: string[];
  endColors: string[];
  gravity: number;
  friction: number;
  shape: number;
  shrink: boolean;
  fadeOut: boolean;
  spreadX: number;
  spreadY: number;
}

export function createParticleEmitter(config: ParticleEmitterConfig): ParticleEmitterComponent {
  return { emitRate: 50, lifetime: -1, elapsed: 0, active: true, maxParticles: 200, config: config };
}
```

```typescript
// entry/src/main/ets/engine/components/Health.ets
export interface Health {
  current: number;
  max: number;
  invincibleTimer: number;
}

export function createHealth(max: number): Health {
  return { current: max, max: max, invincibleTimer: 0 };
}
```

```typescript
// entry/src/main/ets/engine/components/AI.ets
export type AIType = 'wander' | 'chase' | 'patrol' | 'boss';

export interface AIComponent {
  type: AIType;
  speed: number;
  detectRange: number;
  targetEntity: number;
  stateTimer: number;
  patrolPoints: number[];
  patrolIndex: number;
  data: number[];
}

export function createAI(type: AIType, speed: number, detectRange: number): AIComponent {
  return { type: type, speed: speed, detectRange: detectRange, targetEntity: -1, stateTimer: 0, patrolPoints: [], patrolIndex: 0, data: [] };
}
```

```typescript
// entry/src/main/ets/engine/components/PlayerInput.ets
export interface PlayerInput {
  moveX: number;
  moveY: number;
  attackPressed: boolean;
  jumpPressed: boolean;
  dashPressed: boolean;
  toolPressed: boolean;
  interactPressed: boolean;
}

export function createPlayerInput(): PlayerInput {
  return { moveX: 0, moveY: 0, attackPressed: false, jumpPressed: false, dashPressed: false, toolPressed: false, interactPressed: false };
}
```

```typescript
// entry/src/main/ets/engine/components/Light.ets
export interface Light {
  color: string;
  radius: number;
  intensity: number;
  flicker: boolean;
  flickerSpeed: number;
  flickerPhase: number;
}

export function createLight(color: string, radius: number, intensity: number): Light {
  return { color: color, radius: radius, intensity: intensity, flicker: false, flickerSpeed: 0, flickerPhase: 0 };
}
```

```typescript
// entry/src/main/ets/engine/components/Tag.ets
export interface TagComponent {
  tags: string[];
}

export function createTag(...tags: string[]): TagComponent {
  return { tags: tags };
}
```

```typescript
// entry/src/main/ets/engine/components/AudioSource.ets
export interface AudioSource {
  soundId: string;
  volume: number;
  loop: boolean;
  spatial: boolean;
  playing: boolean;
}

export function createAudioSource(soundId: string): AudioSource {
  return { soundId: soundId, volume: 1.0, loop: false, spatial: false, playing: false };
}
```

```typescript
// entry/src/main/ets/engine/components/TilemapCollider.ets
export interface TilemapCollider {
  tileMap: number[][];
  tileSize: number;
  isSolid: (tile: number) => boolean;
}

export function createTilemapCollider(tileMap: number[][], tileSize: number, isSolid: (tile: number) => boolean): TilemapCollider {
  return { tileMap: tileMap, tileSize: tileSize, isSolid: isSolid };
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL, 14 new files all compile.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/components/
git commit -m "feat(engine): add 14 built-in component interfaces"
```

---

### Task 5: Six Built-in System Shells

**Files:**
- Create: `entry/src/main/ets/engine/systems/RenderSystem.ets`
- Create: `entry/src/main/ets/engine/systems/PhysicsSystem.ets`
- Create: `entry/src/main/ets/engine/systems/ParticleSimSystem.ets`
- Create: `entry/src/main/ets/engine/systems/InputSystem.ets`
- Create: `entry/src/main/ets/engine/systems/AudioSystem.ets`
- Create: `entry/src/main/ets/engine/systems/CameraSystem.ets`

**Interfaces:**
- Consumes: `System` base class, `World`, component interfaces
- Produces: 6 concrete System subclasses with no-op implementations (filled in Phase 2)

- [ ] **Step 1: Create all 6 system shells**

Each system extends System with empty update/render:

```typescript
// entry/src/main/ets/engine/systems/RenderSystem.ets
import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class RenderSystem extends System {
  readonly name: string = 'render';
  readonly dependencies: string[] = [];
  priority: number = 100;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: integrate SpriteBatch rendering
  }

  render(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void {
    // Phase 2: draw all Sprite+Transform entities sorted by zIndex
  }
}
```

```typescript
// entry/src/main/ets/engine/systems/PhysicsSystem.ets
import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class PhysicsSystem extends System {
  readonly name: string = 'physics';
  readonly dependencies: string[] = [];
  priority: number = 10;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: wrap PhysicsEngine, handle RigidBody+Collider
  }
}
```

```typescript
// entry/src/main/ets/engine/systems/ParticleSimSystem.ets
import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class ParticleSimSystem extends System {
  readonly name: string = 'particleSim';
  readonly dependencies: string[] = [];
  priority: number = 30;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: wrap ParticleManager algorithms
  }

  render(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void {
    // Phase 2: render particles
  }
}
```

```typescript
// entry/src/main/ets/engine/systems/InputSystem.ets
import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class InputSystem extends System {
  readonly name: string = 'input';
  readonly dependencies: string[] = [];
  priority: number = 0;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: consume platform input, write PlayerInput components
  }
}
```

```typescript
// entry/src/main/ets/engine/systems/AudioSystem.ets
import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';

export class AudioSystem extends System {
  readonly name: string = 'audio';
  readonly dependencies: string[] = [];
  priority: number = 40;

  update(world: World, dt: number, entities: Entity[]): void {
    // Phase 2: manage AudioSource component playback
  }
}
```

```typescript
// entry/src/main/ets/engine/systems/CameraSystem.ets
import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { CameraComponent } from '../components/Camera';
import { Transform } from '../components/Transform';

export class CameraSystem extends System {
  readonly name: string = 'camera';
  readonly dependencies: string[] = [];
  priority: number = 20;

  private cameraX: number = 0;
  private cameraY: number = 0;
  private shakeOffsetX: number = 0;
  private shakeOffsetY: number = 0;

  update(world: World, dt: number, entities: Entity[]): void {
    const cameras: Entity[] = world.query('camera', 'transform');
    for (const e of cameras) {
      const cam: CameraComponent | undefined = world.getComponent<CameraComponent>(e, 'camera');
      const transform: Transform | undefined = world.getComponent<Transform>(e, 'transform');
      if (!cam || !transform) continue;

      if (cam.followEntity >= 0 && world.isEntityAlive(cam.followEntity)) {
        const target: Transform | undefined = world.getComponent<Transform>(cam.followEntity, 'transform');
        if (target) {
          const targetX: number = target.x + cam.offsetX;
          const targetY: number = target.y + cam.offsetY;
          transform.x += (targetX - transform.x) * cam.lerpSpeed;
          transform.y += (targetY - transform.y) * cam.lerpSpeed;
        }
      }

      if (transform.x < cam.worldMinX) transform.x = cam.worldMinX;
      if (transform.y < cam.worldMinY) transform.y = cam.worldMinY;
      if (transform.x > cam.worldMaxX) transform.x = cam.worldMaxX;
      if (transform.y > cam.worldMaxY) transform.y = cam.worldMaxY;

      if (cam.shakeTimer > 0) {
        cam.shakeTimer -= dt;
        const intensity: number = cam.shakeIntensity * (cam.shakeTimer / 1000);
        this.shakeOffsetX = (Math.random() * 2 - 1) * intensity;
        this.shakeOffsetY = (Math.random() * 2 - 1) * intensity;
      } else {
        this.shakeOffsetX = 0;
        this.shakeOffsetY = 0;
      }

      this.cameraX = transform.x + this.shakeOffsetX;
      this.cameraY = transform.y + this.shakeOffsetY;
    }
  }

  getCameraX(): number { return this.cameraX; }
  getCameraY(): number { return this.cameraY; }
  getShakeOffsetX(): number { return this.shakeOffsetX; }
  getShakeOffsetY(): number { return this.shakeOffsetY; }
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL, all 6 system shells compile.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/systems/
git commit -m "feat(engine): add 6 built-in system shells"
```

---

### Task 6: Scene Base Class and SceneManager

**Files:**
- Create: `entry/src/main/ets/engine/scene/Scene.ets`
- Create: `entry/src/main/ets/engine/scene/SceneManager.ets`

**Interfaces:**
- Consumes: `CanvasRenderingContext2D`
- Produces: `Scene` abstract class, `SceneManager` class with stack, transitions, lifecycle

- [ ] **Step 1: Create Scene.ets**

```typescript
// entry/src/main/ets/engine/scene/Scene.ets

export abstract class Scene {
  readonly name: string;

  constructor(name: string) {
    this.name = name;
  }

  onLoad(): void | Promise<void> {
    // Override for resource loading
  }

  onEnter(): void {
    // Override when scene becomes active
  }

  onPause(): void {
    // Override when pushed below another scene
  }

  onResume(): void {
    // Override when restored to top of stack
  }

  onExit(): void {
    // Override when scene is removed
  }

  abstract update(dt: number): void;
  abstract render(ctx: CanvasRenderingContext2D): void;
}
```

- [ ] **Step 2: Create SceneManager.ets**

```typescript
// entry/src/main/ets/engine/scene/SceneManager.ets

import { Scene } from './Scene';

export interface Transition {
  type: 'fade' | 'slide-left' | 'slide-right' | 'slide-up' | 'dissolve';
  duration: number;
}

interface SceneEntry {
  factory: () => Scene;
  instance: Scene | null;
  loaded: boolean;
}

export class SceneManager {
  private registry: Map<string, SceneEntry> = new Map();
  private stack: Scene[] = [];
  private transitioning: boolean = false;
  private transitionProgress: number = 0;
  private transitionDuration: number = 0;
  private transitionType: string = 'fade';
  private pendingAction: (() => void) | null = null;
  private pendingTransition: Transition | null = null;

  register(name: string, factory: () => Scene): void {
    this.registry.set(name, { factory: factory, instance: null, loaded: false });
  }

  switchTo(name: string, transition?: Transition): void {
    const entry: SceneEntry | undefined = this.registry.get(name);
    if (!entry) {
      console.error('[SceneManager] Scene not registered: ' + name);
      return;
    }

    if (transition) {
      this.startTransition(transition, (): void => {
        while (this.stack.length > 0) {
          const old: Scene = this.stack.pop()!;
          old.onExit();
        }
        this.pushSceneInstance(entry);
      });
    } else {
      while (this.stack.length > 0) {
        const old: Scene = this.stack.pop()!;
        old.onExit();
      }
      this.pushSceneInstance(entry);
    }
  }

  push(name: string, transition?: Transition): void {
    const entry: SceneEntry | undefined = this.registry.get(name);
    if (!entry) {
      console.error('[SceneManager] Scene not registered: ' + name);
      return;
    }

    if (this.stack.length > 0) {
      this.stack[this.stack.length - 1].onPause();
    }

    if (transition) {
      this.startTransition(transition, (): void => {
        this.pushSceneInstance(entry);
      });
    } else {
      this.pushSceneInstance(entry);
    }
  }

  pop(transition?: Transition): void {
    if (this.stack.length <= 1) return;

    if (transition) {
      this.startTransition(transition, (): void => {
        const old: Scene = this.stack.pop()!;
        old.onExit();
        if (this.stack.length > 0) {
          this.stack[this.stack.length - 1].onResume();
        }
      });
    } else {
      const old: Scene = this.stack.pop()!;
      old.onExit();
      if (this.stack.length > 0) {
        this.stack[this.stack.length - 1].onResume();
      }
    }
  }

  current(): Scene | null {
    return this.stack.length > 0 ? this.stack[this.stack.length - 1] : null;
  }

  isTransitioning(): boolean {
    return this.transitioning;
  }

  update(dt: number): void {
    if (this.transitioning) {
      this.transitionProgress += dt;
      if (this.transitionProgress >= this.transitionDuration) {
        this.transitioning = false;
        if (this.pendingAction) {
          this.pendingAction();
          this.pendingAction = null;
        }
      }
      return;
    }

    const scene: Scene | null = this.current();
    if (scene) {
      scene.update(dt);
    }
  }

  render(ctx: CanvasRenderingContext2D): void {
    const scene: Scene | null = this.current();
    if (scene) {
      scene.render(ctx);
    }

    if (this.transitioning) {
      this.renderTransition(ctx);
    }
  }

  private pushSceneInstance(entry: SceneEntry): void {
    if (!entry.instance) {
      entry.instance = entry.factory();
    }
    const scene: Scene = entry.instance;
    if (!entry.loaded) {
      const result: void | Promise<void> = scene.onLoad();
      if (result instanceof Promise) {
        result.then((): void => {
          entry.loaded = true;
          scene.onEnter();
        });
        return;
      }
      entry.loaded = true;
    }
    scene.onEnter();
    this.stack.push(scene);
  }

  private startTransition(transition: Transition, action: () => void): void {
    this.transitioning = true;
    this.transitionProgress = 0;
    this.transitionDuration = transition.duration;
    this.transitionType = transition.type;
    this.pendingAction = action;
  }

  private renderTransition(ctx: CanvasRenderingContext2D): void {
    const progress: number = Math.min(1.0, this.transitionProgress / this.transitionDuration);
    const canvasWidth: number = ctx.canvas.width;
    const canvasHeight: number = ctx.canvas.height;

    switch (this.transitionType) {
      case 'fade':
        ctx.fillStyle = '#000000';
        ctx.globalAlpha = progress < 0.5 ? progress * 2 : (1.0 - progress) * 2;
        ctx.fillRect(0, 0, canvasWidth, canvasHeight);
        ctx.globalAlpha = 1.0;
        break;
      case 'slide-left':
        ctx.fillStyle = '#000000';
        ctx.fillRect(0, 0, canvasWidth * (1.0 - progress), canvasHeight);
        break;
      case 'slide-right':
        ctx.fillStyle = '#000000';
        const slideRightX: number = canvasWidth * progress;
        ctx.fillRect(slideRightX, 0, canvasWidth - slideRightX, canvasHeight);
        break;
      case 'slide-up':
        ctx.fillStyle = '#000000';
        ctx.fillRect(0, 0, canvasWidth, canvasHeight * (1.0 - progress));
        break;
      case 'dissolve':
        ctx.fillStyle = '#000000';
        ctx.globalAlpha = progress < 0.5 ? progress * 2 : (1.0 - progress) * 2;
        ctx.fillRect(0, 0, canvasWidth, canvasHeight);
        ctx.globalAlpha = 1.0;
        break;
    }
  }
}
```

- [ ] **Step 3: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/engine/scene/
git commit -m "feat(engine): add Scene base class and SceneManager with stack + transitions"
```

---

### Task 7: ResourceManager

**Files:**
- Create: `entry/src/main/ets/engine/resource/ResourceManager.ets`

**Interfaces:**
- Produces: `ResourceManager` class with async loading, caching, reference counting

- [ ] **Step 1: Create ResourceManager.ets**

```typescript
// entry/src/main/ets/engine/resource/ResourceManager.ets

export enum ResourceType {
  TEXTURE = 'texture',
  AUDIO = 'audio',
  DATA = 'data',
  FONT = 'font'
}

interface ResourceEntry {
  key: string;
  type: ResourceType;
  data: Object | null;
  state: 'loading' | 'loaded' | 'error';
  refCount: number;
}

export class ResourceManager {
  private resources: Map<string, ResourceEntry> = new Map();
  private totalLoadCount: number = 0;
  private completedLoadCount: number = 0;

  async load(key: string, type: ResourceType, loader: () => Promise<Object>): Promise<Object | null> {
    const existing: ResourceEntry | undefined = this.resources.get(key);
    if (existing) {
      if (existing.state === 'loaded') return existing.data;
      if (existing.state === 'loading') return null;
    }

    const entry: ResourceEntry = {
      key: key,
      type: type,
      data: null,
      state: 'loading',
      refCount: 1
    };
    this.resources.set(key, entry);
    this.totalLoadCount++;

    try {
      const data: Object = await loader();
      entry.data = data;
      entry.state = 'loaded';
      this.completedLoadCount++;
      return data;
    } catch (e) {
      entry.state = 'error';
      this.completedLoadCount++;
      console.error('[ResourceManager] Failed to load: ' + key);
      return null;
    }
  }

  async loadAll(entries: { key: string; type: ResourceType; loader: () => Promise<Object> }[]): Promise<void> {
    const promises: Promise<Object | null>[] = [];
    for (const entry of entries) {
      promises.push(this.load(entry.key, entry.type, entry.loader));
    }
    await Promise.all(promises);
  }

  get<T>(key: string): T | null {
    const entry: ResourceEntry | undefined = this.resources.get(key);
    if (!entry || entry.state !== 'loaded' || !entry.data) return null;
    return entry.data as T;
  }

  acquire(key: string): void {
    const entry: ResourceEntry | undefined = this.resources.get(key);
    if (entry) {
      entry.refCount++;
    }
  }

  release(key: string): void {
    const entry: ResourceEntry | undefined = this.resources.get(key);
    if (entry) {
      entry.refCount--;
      if (entry.refCount <= 0) {
        this.unload(key);
      }
    }
  }

  unload(key: string): void {
    this.resources.delete(key);
  }

  unloadUnused(): void {
    const toRemove: string[] = [];
    this.resources.forEach((entry: ResourceEntry, key: string) => {
      if (entry.refCount <= 0 && entry.state !== 'loading') {
        toRemove.push(key);
      }
    });
    for (const key of toRemove) {
      this.resources.delete(key);
    }
  }

  isLoaded(key: string): boolean {
    const entry: ResourceEntry | undefined = this.resources.get(key);
    return entry !== undefined && entry.state === 'loaded';
  }

  getLoadProgress(): number {
    if (this.totalLoadCount === 0) return 1.0;
    return this.completedLoadCount / this.totalLoadCount;
  }

  resetProgress(): void {
    this.totalLoadCount = 0;
    this.completedLoadCount = 0;
  }
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/resource/ResourceManager.ets
git commit -m "feat(engine): add ResourceManager with async loading and reference counting"
```

---

### Task 8: HarmonyOSPlatform Layer

**Files:**
- Create: `entry/src/main/ets/engine/platform/HarmonyOSPlatform.ets`

**Interfaces:**
- Consumes: HarmonyOS `@kit.AudioKit`, `@kit.ArkData`, `@kit.AbilityKit`
- Produces: `HarmonyOSPlatform` static class, `AudioRendererAdapter` interface

- [ ] **Step 1: Create HarmonyOSPlatform.ets**

```typescript
// entry/src/main/ets/engine/platform/HarmonyOSPlatform.ets

import { audio } from '@kit.AudioKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

export interface AudioRendererAdapter {
  write(pcmData: ArrayBuffer): void;
  start(): void;
  stop(): void;
  release(): void;
}

export class HarmonyOSPlatform {
  private static appContext: common.UIAbilityContext | null = null;

  static setContext(context: common.UIAbilityContext): void {
    this.appContext = context;
  }

  static getContext(): common.UIAbilityContext | null {
    return this.appContext;
  }

  static now(): number {
    return Date.now();
  }

  static getScreenSize(): { width: number; height: number } {
    return { width: 960, height: 540 };
  }

  static async saveData(key: string, value: string): Promise<void> {
    if (!this.appContext) return;
    try {
      const pref = await preferences.getPreferences(this.appContext, 'engine_prefs');
      await pref.put(key, value);
      await pref.flush();
    } catch (e) {
      console.error('[Platform] saveData failed: ' + JSON.stringify(e));
    }
  }

  static async loadData(key: string): Promise<string | null> {
    if (!this.appContext) return null;
    try {
      const pref = await preferences.getPreferences(this.appContext, 'engine_prefs');
      const value: string = await pref.get(key, '') as string;
      return value.length > 0 ? value : null;
    } catch (e) {
      return null;
    }
  }

  static async loadRawFile(path: string): Promise<ArrayBuffer> {
    if (!this.appContext) return new ArrayBuffer(0);
    try {
      const mgr: resourceManager.ResourceManager = this.appContext.resourceManager;
      const buffer: ArrayBuffer = await mgr.getRawFileContent(path);
      return buffer;
    } catch (e) {
      console.error('[Platform] loadRawFile failed: ' + path);
      return new ArrayBuffer(0);
    }
  }

  static async createAudioRenderer(sampleRate: number): Promise<AudioRendererAdapter | null> {
    try {
      const renderer: audio.AudioRenderer = await audio.createAudioRenderer({
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        rendererInfo: {
          usage: audio.StreamUsage.STREAM_USAGE_GAME,
          rendererFlags: 0
        }
      });
      return {
        write(pcmData: ArrayBuffer): void {
          // AudioRenderer uses callback model; write is handled via on('writeData')
        },
        start(): void {
          renderer.start().catch((): void => {});
        },
        stop(): void {
          renderer.stop().catch((): void => {});
        },
        release(): void {
          renderer.release().catch((): void => {});
        }
      };
    } catch (e) {
      console.error('[Platform] createAudioRenderer failed');
      return null;
    }
  }
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/platform/HarmonyOSPlatform.ets
git commit -m "feat(engine): add HarmonyOSPlatform bridge layer"
```

---

### Task 9: Engine Entry Point and Main Loop

**Files:**
- Create: `entry/src/main/ets/engine/core/Engine.ets`

**Interfaces:**
- Consumes: `World`, `SceneManager`, `ResourceManager`, `HarmonyOSPlatform`
- Produces: `Engine` class with `init()`, `start()`, `stop()`, `pause()`, `resume()`

- [ ] **Step 1: Create Engine.ets**

```typescript
// entry/src/main/ets/engine/core/Engine.ets

import { World } from './World';
import { Scene } from '../scene/Scene';
import { SceneManager } from '../scene/SceneManager';
import { ResourceManager } from '../resource/ResourceManager';
import { HarmonyOSPlatform } from '../platform/HarmonyOSPlatform';
import { common } from '@kit.AbilityKit';

export interface EngineConfig {
  canvas: CanvasRenderingContext2D;
  screenWidth: number;
  screenHeight: number;
  targetFPS?: number;
  scenes: { name: string; factory: () => Scene }[];
  entryScene: string;
  appContext?: common.UIAbilityContext;
}

export class Engine {
  readonly world: World = new World();
  readonly scenes: SceneManager = new SceneManager();
  readonly resources: ResourceManager = new ResourceManager();

  private canvas: CanvasRenderingContext2D | null = null;
  private screenWidth: number = 960;
  private screenHeight: number = 540;
  private targetFPS: number = 60;
  private running: boolean = false;
  private paused: boolean = false;
  private timerId: number = -1;
  private lastTime: number = 0;

  static async init(config: EngineConfig): Promise<Engine> {
    const engine: Engine = new Engine();
    engine.canvas = config.canvas;
    engine.screenWidth = config.screenWidth;
    engine.screenHeight = config.screenHeight;
    engine.targetFPS = config.targetFPS ?? 60;

    if (config.appContext) {
      HarmonyOSPlatform.setContext(config.appContext);
    }

    for (const sceneDef of config.scenes) {
      engine.scenes.register(sceneDef.name, sceneDef.factory);
    }

    return engine;
  }

  start(): void {
    if (this.running) return;
    this.running = true;
    this.paused = false;
    this.lastTime = HarmonyOSPlatform.now();

    const interval: number = Math.floor(1000 / this.targetFPS);
    this.timerId = setInterval((): void => {
      this.tick();
    }, interval);
  }

  stop(): void {
    this.running = false;
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  pause(): void {
    this.paused = true;
  }

  resume(): void {
    this.paused = false;
    this.lastTime = HarmonyOSPlatform.now();
  }

  isRunning(): boolean {
    return this.running;
  }

  isPaused(): boolean {
    return this.paused;
  }

  private tick(): void {
    if (this.paused || !this.canvas) return;

    const now: number = HarmonyOSPlatform.now();
    const dt: number = now - this.lastTime;
    this.lastTime = now;

    const clampedDt: number = Math.min(dt, 50);

    this.scenes.update(clampedDt);

    this.canvas.clearRect(0, 0, this.screenWidth, this.screenHeight);
    this.scenes.render(this.canvas);
  }
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL. All engine core files compile together.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/core/Engine.ets
git commit -m "feat(engine): add Engine entry point with main loop"
```

---

### Task 10: Engine Barrel Export

**Files:**
- Create: `entry/src/main/ets/engine/index.ets`

**Interfaces:**
- Produces: Single import point for all engine public API

- [ ] **Step 1: Create index.ets**

```typescript
// entry/src/main/ets/engine/index.ets

export { Entity, EntityPool, getIndex, getGeneration, makeEntity } from './core/Entity';
export { World } from './core/World';
export { System } from './core/System';
export { Engine, EngineConfig } from './core/Engine';
export { Scene } from './scene/Scene';
export { SceneManager, Transition } from './scene/SceneManager';
export { ResourceManager, ResourceType } from './resource/ResourceManager';
export { HarmonyOSPlatform, AudioRendererAdapter } from './platform/HarmonyOSPlatform';

export { Transform, createTransform } from './components/Transform';
export { Sprite, createSprite } from './components/Sprite';
export { AnimatedSprite, createAnimatedSprite } from './components/AnimatedSprite';
export { Collider, ColliderType, createBoxCollider, createCircleCollider } from './components/Collider';
export { RigidBody, createRigidBody } from './components/RigidBody';
export { CameraComponent, createCamera } from './components/Camera';
export { ParticleEmitterComponent, ParticleEmitterConfig, createParticleEmitter } from './components/ParticleEmitterComp';
export { Health, createHealth } from './components/Health';
export { AIComponent, AIType, createAI } from './components/AI';
export { PlayerInput, createPlayerInput } from './components/PlayerInput';
export { Light, createLight } from './components/Light';
export { TagComponent, createTag } from './components/Tag';
export { AudioSource, createAudioSource } from './components/AudioSource';
export { TilemapCollider, createTilemapCollider } from './components/TilemapCollider';

export { RenderSystem } from './systems/RenderSystem';
export { PhysicsSystem } from './systems/PhysicsSystem';
export { ParticleSimSystem } from './systems/ParticleSimSystem';
export { InputSystem } from './systems/InputSystem';
export { AudioSystem } from './systems/AudioSystem';
export { CameraSystem } from './systems/CameraSystem';
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL. Full engine compiles as a unit.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/index.ets
git commit -m "feat(engine): add barrel export for engine public API"
```

---

### Task 11: Phase 1 Integration Smoke Test

**Files:**
- Create: `entry/src/main/ets/engine/__tests__/EngineSmokeTest.ets` (temporary test scene)

**Interfaces:**
- Consumes: Full engine API
- Produces: Verification that Engine init, World, SceneManager, and main loop work

- [ ] **Step 1: Create a minimal test scene**

```typescript
// entry/src/main/ets/engine/__tests__/EngineSmokeTest.ets

import { Engine, EngineConfig } from '../core/Engine';
import { Scene } from '../scene/Scene';
import { createTransform, Transform } from '../components/Transform';
import { createSprite, Sprite } from '../components/Sprite';

class TestScene extends Scene {
  constructor() {
    super('test');
  }

  onLoad(): void {
    console.info('[TestScene] onLoad');
  }

  onEnter(): void {
    console.info('[TestScene] onEnter');
  }

  update(dt: number): void {
    // Verify World works
  }

  render(ctx: CanvasRenderingContext2D): void {
    ctx.fillStyle = '#ff0000';
    ctx.fillRect(100, 100, 50, 50);
  }
}

export async function runEngineSmokeTest(
  canvas: CanvasRenderingContext2D,
  context: Object
): Promise<void> {
  const engine: Engine = await Engine.init({
    canvas: canvas,
    screenWidth: 960,
    screenHeight: 540,
    scenes: [
      { name: 'test', factory: (): Scene => new TestScene() }
    ],
    entryScene: 'test',
    appContext: context as any
  });

  engine.scenes.switchTo('test');

  const world = engine.world;
  const e1 = world.createEntity();
  world.addComponent<Transform>(e1, 'transform', createTransform(100, 200));
  world.addComponent<Sprite>(e1, 'sprite', createSprite('#00ff00', 32, 32));

  const results = world.query('transform', 'sprite');
  console.info('[SmokeTest] Entity count: ' + results.length);
  console.info('[SmokeTest] Expected: 1, Got: ' + results.length);

  engine.start();
  console.info('[SmokeTest] Engine started');

  setTimeout((): void => {
    engine.stop();
    console.info('[SmokeTest] Engine stopped - PASS');
  }, 1000);
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL. If any engine API is broken, it surfaces here.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/__tests__/EngineSmokeTest.ets
git commit -m "feat(engine): add Phase 1 smoke test"
```

---

## Phase 2: Module Migration

### Task 12: Migrate PhysicsEngine → PhysicsSystem

**Files:**
- Modify: `entry/src/main/ets/engine/systems/PhysicsSystem.ets`
- Source: `entry/src/main/ets/game/PhysicsEngine.ets` (read-only reference)

**Interfaces:**
- Consumes: `RigidBody`, `Transform`, `Collider`, `TilemapCollider` components
- Produces: Full physics simulation as a System

- [ ] **Step 1: Rewrite PhysicsSystem.ets wrapping PhysicsEngine logic**

Port the PhysicsEngine class into PhysicsSystem, removing the `TILE_SIZE` import dependency. Instead, read tile size from the `TilemapCollider` component:

```typescript
// entry/src/main/ets/engine/systems/PhysicsSystem.ets

import { Entity, getIndex } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { Transform } from '../components/Transform';
import { RigidBody } from '../components/RigidBody';
import { Collider } from '../components/Collider';
import { TilemapCollider } from '../components/TilemapCollider';

const DEFAULT_GRAVITY: number = 0.5;
const MAX_FALL_SPEED: number = 12.0;
const MAX_MOVE_SPEED: number = 20.0;

export class PhysicsSystem extends System {
  readonly name: string = 'physics';
  readonly dependencies: string[] = [];
  priority: number = 10;

  private gravity: number = DEFAULT_GRAVITY;
  private maxFallSpeed: number = MAX_FALL_SPEED;

  setGravity(g: number): void { this.gravity = g; }
  setMaxFallSpeed(s: number): void { this.maxFallSpeed = s; }

  update(world: World, dt: number, entities: Entity[]): void {
    const bodies: Entity[] = world.query('rigidBody', 'transform');
    const tilemapEntities: Entity[] = world.query('tilemapCollider');
    let tilemap: TilemapCollider | undefined = undefined;
    if (tilemapEntities.length > 0) {
      tilemap = world.getComponent<TilemapCollider>(tilemapEntities[0], 'tilemapCollider');
    }

    for (const e of bodies) {
      const body: RigidBody | undefined = world.getComponent<RigidBody>(e, 'rigidBody');
      const transform: Transform | undefined = world.getComponent<Transform>(e, 'transform');
      const collider: Collider | undefined = world.getComponent<Collider>(e, 'collider');
      if (!body || !transform) continue;
      if (body.isKinematic) continue;

      body.vy += this.gravity * body.gravityScale * (dt / 16);
      if (body.vy > this.maxFallSpeed) body.vy = this.maxFallSpeed;

      if (body.onGround) {
        body.vx *= body.friction;
      }
      if (Math.abs(body.vx) < 0.1) body.vx = 0;
      if (body.vx > MAX_MOVE_SPEED) body.vx = MAX_MOVE_SPEED;
      if (body.vx < -MAX_MOVE_SPEED) body.vx = -MAX_MOVE_SPEED;

      const stepX: number = body.vx * (dt / 16);
      const stepY: number = body.vy * (dt / 16);

      const w: number = collider ? collider.width : 16;
      const h: number = collider ? collider.height : 16;

      transform.x += stepX;
      if (tilemap) {
        this.resolveTileCollisionX(world, transform, body, w, h, tilemap);
      }

      transform.y += stepY;
      if (tilemap) {
        this.resolveTileCollisionY(world, transform, body, w, h, tilemap);
      }

      if (collider) {
        collider.onCollisionEnter = false;
      }
    }
  }

  private resolveTileCollisionX(
    world: World, transform: Transform, body: RigidBody,
    w: number, h: number, tilemap: TilemapCollider
  ): void {
    const tileSize: number = tilemap.tileSize;
    const top: number = Math.floor(transform.y / tileSize);
    const bottom: number = Math.floor((transform.y + h - 1) / tileSize);
    const margin: number = 1;

    if (body.vx < 0) {
      const tileX: number = Math.floor(transform.x / tileSize);
      for (let ty: number = top; ty <= bottom; ty++) {
        if (tileX >= 0 && ty >= 0 && ty < tilemap.tileMap.length &&
          tileX < tilemap.tileMap[ty].length) {
          const tile: number = tilemap.tileMap[ty][tileX];
          if (tilemap.isSolid(tile)) {
            transform.x = (tileX + 1) * tileSize + margin;
            body.vx = body.bounciness > 0 ? -body.vx * body.bounciness : 0;
            body.onWall = true;
            return;
          }
        }
      }
    } else if (body.vx > 0) {
      const tileX: number = Math.floor((transform.x + w) / tileSize);
      for (let ty: number = top; ty <= bottom; ty++) {
        if (tileX >= 0 && ty >= 0 && ty < tilemap.tileMap.length &&
          tileX < tilemap.tileMap[ty].length) {
          const tile: number = tilemap.tileMap[ty][tileX];
          if (tilemap.isSolid(tile)) {
            transform.x = tileX * tileSize - w - margin;
            body.vx = body.bounciness > 0 ? -body.vx * body.bounciness : 0;
            body.onWall = true;
            return;
          }
        }
      }
    }
    body.onWall = false;
  }

  private resolveTileCollisionY(
    world: World, transform: Transform, body: RigidBody,
    w: number, h: number, tilemap: TilemapCollider
  ): void {
    const tileSize: number = tilemap.tileSize;
    const left: number = Math.floor(transform.x / tileSize);
    const right: number = Math.floor((transform.x + w - 1) / tileSize);

    if (body.vy < 0) {
      const tileY: number = Math.floor(transform.y / tileSize);
      for (let tx: number = left; tx <= right; tx++) {
        if (tileY >= 0 && tileY < tilemap.tileMap.length &&
          tx >= 0 && tx < tilemap.tileMap[tileY].length) {
          const tile: number = tilemap.tileMap[tileY][tx];
          if (tilemap.isSolid(tile)) {
            transform.y = (tileY + 1) * tileSize + 1;
            body.vy = body.bounciness > 0 ? -body.vy * body.bounciness : 0;
            body.onGround = false;
            return;
          }
        }
      }
    } else if (body.vy > 0) {
      const tileY: number = Math.floor((transform.y + h) / tileSize);
      for (let tx: number = left; tx <= right; tx++) {
        if (tileY >= 0 && tileY < tilemap.tileMap.length &&
          tx >= 0 && tx < tilemap.tileMap[tileY].length) {
          const tile: number = tilemap.tileMap[tileY][tx];
          if (tilemap.isSolid(tile)) {
            transform.y = tileY * tileSize - h - 1;
            body.vy = 0;
            body.onGround = true;
            return;
          }
        }
      }
      body.onGround = false;
    }
  }

  checkEntityCollision(
    ax: number, ay: number, aw: number, ah: number,
    bx: number, by: number, bw: number, bh: number
  ): boolean {
    return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
  }
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/systems/PhysicsSystem.ets
git commit -m "feat(engine): migrate PhysicsEngine into PhysicsSystem, remove TILE_SIZE coupling"
```

---

### Task 13: Migrate ParticleSystem → ParticleSimSystem

**Files:**
- Modify: `entry/src/main/ets/engine/systems/ParticleSimSystem.ets`
- Source: `entry/src/main/ets/game/ParticleSystem.ets` (read-only reference)

**Interfaces:**
- Consumes: `ParticleEmitterComponent`, `Transform` components
- Produces: Particle simulation and rendering as a System

- [ ] **Step 1: Rewrite ParticleSimSystem.ets**

Port ParticleEmitter + ParticleManager logic. Particle data stored per-emitter-component, not in a separate manager:

```typescript
// entry/src/main/ets/engine/systems/ParticleSimSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { Transform } from '../components/Transform';
import { ParticleEmitterComponent, ParticleEmitterConfig } from '../components/ParticleEmitterComp';

interface InternalParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  size: number;
  startSize: number;
  endSize: number;
  color: string;
  endColor: string;
  alpha: number;
  startAlpha: number;
  endAlpha: number;
  gravity: number;
  friction: number;
  rotation: number;
  rotationSpeed: number;
  shape: number;
  shrink: boolean;
  fadeOut: boolean;
}

interface EmitterState {
  particles: InternalParticle[];
  emitTimer: number;
  age: number;
}

export class ParticleSimSystem extends System {
  readonly name: string = 'particleSim';
  readonly dependencies: string[] = [];
  priority: number = 30;

  private states: Map<number, EmitterState> = new Map();

  update(world: World, dt: number, entities: Entity[]): void {
    const emitters: Entity[] = world.query('particleEmitter', 'transform');
    for (const e of emitters) {
      const comp: ParticleEmitterComponent | undefined =
        world.getComponent<ParticleEmitterComponent>(e, 'particleEmitter');
      const transform: Transform | undefined =
        world.getComponent<Transform>(e, 'transform');
      if (!comp || !transform) continue;

      const idx: number = entities.indexOf(e);
      let state: EmitterState | undefined = this.states.get(idx);
      if (!state) {
        state = { particles: [], emitTimer: 0, age: 0 };
        this.states.set(idx, state);
      }

      if (comp.active) {
        state.emitTimer += dt;
        if (state.emitTimer >= comp.emitRate) {
          state.emitTimer = 0;
          this.spawnParticles(state, comp, transform.x, transform.y);
        }
      }

      if (comp.lifetime > 0) {
        state.age += dt;
        if (state.age >= comp.lifetime) {
          comp.active = false;
        }
      }

      this.updateParticles(state, dt);

      if (state.particles.length > comp.maxParticles) {
        state.particles.splice(0, state.particles.length - comp.maxParticles);
      }
    }
  }

  render(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void {
    const emitters: Entity[] = world.query('particleEmitter', 'transform');
    for (const e of emitters) {
      const comp: ParticleEmitterComponent | undefined =
        world.getComponent<ParticleEmitterComponent>(e, 'particleEmitter');
      const transform: Transform | undefined =
        world.getComponent<Transform>(e, 'transform');
      if (!comp || !transform) continue;

      const idx: number = entities.indexOf(e);
      const state: EmitterState | undefined = this.states.get(idx);
      if (!state) continue;

      for (const p of state.particles) {
        const sx: number = p.x;
        const sy: number = p.y;
        ctx.globalAlpha = Math.max(0, Math.min(1, p.alpha));
        ctx.fillStyle = p.color;

        switch (p.shape) {
          case 0: // CIRCLE
            ctx.beginPath();
            ctx.arc(sx, sy, Math.max(0.5, p.size), 0, Math.PI * 2);
            ctx.fill();
            break;
          case 1: // SQUARE
            ctx.fillRect(sx - p.size, sy - p.size, p.size * 2, p.size * 2);
            break;
          case 2: // DIAMOND
            ctx.save();
            ctx.translate(sx, sy);
            ctx.rotate(p.rotation);
            ctx.beginPath();
            ctx.moveTo(0, -p.size);
            ctx.lineTo(p.size, 0);
            ctx.lineTo(0, p.size);
            ctx.lineTo(-p.size, 0);
            ctx.closePath();
            ctx.fill();
            ctx.restore();
            break;
          case 3: // STAR
            ctx.save();
            ctx.translate(sx, sy);
            ctx.rotate(p.rotation);
            this.drawStar(ctx, p.size);
            ctx.restore();
            break;
        }
      }
    }
    ctx.globalAlpha = 1.0;
  }

  private spawnParticles(state: EmitterState, comp: ParticleEmitterComponent, x: number, y: number): void {
    const cfg: ParticleEmitterConfig = comp.config;
    const count: number = Math.max(1, Math.floor(comp.emitRate / 10));
    for (let i: number = 0; i < count; i++) {
      const angle: number = cfg.angleMin + Math.random() * (cfg.angleMax - cfg.angleMin);
      const speed: number = cfg.speedMin + Math.random() * (cfg.speedMax - cfg.speedMin);
      const life: number = cfg.lifeMin + Math.random() * (cfg.lifeMax - cfg.lifeMin);
      const size: number = cfg.sizeMin + Math.random() * (cfg.sizeMax - cfg.sizeMin);
      const endSize: number = cfg.endSizeMin + Math.random() * (cfg.endSizeMax - cfg.endSizeMin);
      const colorIdx: number = Math.floor(Math.random() * cfg.colors.length);
      const color: string = cfg.colors[colorIdx];
      const endColor: string = cfg.endColors.length > 0
        ? cfg.endColors[colorIdx % cfg.endColors.length] : color;
      const ox: number = (Math.random() - 0.5) * cfg.spreadX;
      const oy: number = (Math.random() - 0.5) * cfg.spreadY;

      state.particles.push({
        x: x + ox, y: y + oy,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: life, maxLife: life,
        size: size, startSize: size, endSize: endSize,
        color: color, endColor: endColor,
        alpha: 1.0, startAlpha: 1.0,
        endAlpha: cfg.fadeOut ? 0.0 : 1.0,
        gravity: cfg.gravity, friction: cfg.friction,
        rotation: Math.random() * Math.PI * 2,
        rotationSpeed: (Math.random() - 0.5) * 0.2,
        shape: cfg.shape, shrink: cfg.shrink, fadeOut: cfg.fadeOut
      });
    }
  }

  private updateParticles(state: EmitterState, dt: number): void {
    for (let i: number = state.particles.length - 1; i >= 0; i--) {
      const p: InternalParticle = state.particles[i];
      p.vy += p.gravity * (dt / 16);
      p.vx *= p.friction;
      p.vy *= p.friction;
      p.x += p.vx * (dt / 16);
      p.y += p.vy * (dt / 16);
      p.rotation += p.rotationSpeed;
      p.life -= dt;

      const t: number = 1.0 - (p.life / p.maxLife);
      p.alpha = p.startAlpha + (p.endAlpha - p.startAlpha) * t;
      if (p.shrink) {
        p.size = p.startSize + (p.endSize - p.startSize) * t;
      }

      if (p.life <= 0 || p.size <= 0) {
        state.particles.splice(i, 1);
      }
    }
  }

  private drawStar(c: CanvasRenderingContext2D, size: number): void {
    const spikes: number = 4;
    const outerR: number = size;
    const innerR: number = size * 0.4;
    c.beginPath();
    for (let i: number = 0; i < spikes * 2; i++) {
      const r: number = i % 2 === 0 ? outerR : innerR;
      const angle: number = (i * Math.PI) / spikes - Math.PI / 2;
      const px: number = Math.cos(angle) * r;
      const py: number = Math.sin(angle) * r;
      if (i === 0) c.moveTo(px, py);
      else c.lineTo(px, py);
    }
    c.closePath();
    c.fill();
  }
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/systems/ParticleSimSystem.ets
git commit -m "feat(engine): migrate ParticleSystem into ParticleSimSystem"
```

---

### Task 14: Integrate SpriteBatch into RenderSystem

**Files:**
- Modify: `entry/src/main/ets/engine/systems/RenderSystem.ets`
- Source: `entry/src/main/ets/game/SpriteBatch.ets` (copy into engine)

**Interfaces:**
- Consumes: `Sprite`, `Transform` components
- Produces: Batched rendering via internal SpriteBatch

- [ ] **Step 1: Copy SpriteBatch.ets into engine internals**

Create `entry/src/main/ets/engine/internal/SpriteBatch.ets` as an exact copy of `game/SpriteBatch.ets` (the file has zero game dependencies — just copy it).

```bash
cp entry/src/main/ets/game/SpriteBatch.ets entry/src/main/ets/engine/internal/SpriteBatch.ets
```

- [ ] **Step 2: Implement RenderSystem using SpriteBatch**

```typescript
// entry/src/main/ets/engine/systems/RenderSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { Transform } from '../components/Transform';
import { Sprite } from '../components/Sprite';
import { SpriteBatch } from '../internal/SpriteBatch';

interface RenderItem {
  zIndex: number;
  entity: Entity;
}

export class RenderSystem extends System {
  readonly name: string = 'render';
  readonly dependencies: string[] = [];
  priority: number = 100;

  private batch: SpriteBatch = new SpriteBatch();
  private screenWidth: number = 960;
  private screenHeight: number = 540;

  setScreenSize(w: number, h: number): void {
    this.screenWidth = w;
    this.screenHeight = h;
  }

  update(world: World, dt: number, entities: Entity[]): void {
    // No update logic needed; all work is in render()
  }

  render(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void {
    this.batch.clear();

    const items: RenderItem[] = [];
    const sprites: Entity[] = world.query('sprite', 'transform');

    for (const e of sprites) {
      const sprite: Sprite | undefined = world.getComponent<Sprite>(e, 'sprite');
      const transform: Transform | undefined = world.getComponent<Transform>(e, 'transform');
      if (!sprite || !transform || !sprite.visible) continue;

      if (transform.x + sprite.width < 0 || transform.x > this.screenWidth ||
        transform.y + sprite.height < 0 || transform.y > this.screenHeight) {
        continue;
      }

      items.push({ zIndex: transform.zIndex, entity: e });
    }

    items.sort((a: RenderItem, b: RenderItem): number => a.zIndex - b.zIndex);

    for (const item of items) {
      const sprite: Sprite | undefined = world.getComponent<Sprite>(item.entity, 'sprite');
      const transform: Transform | undefined = world.getComponent<Transform>(item.entity, 'transform');
      if (!sprite || !transform) continue;

      this.batch.addRect(
        transform.x, transform.y,
        sprite.width * transform.scaleX,
        sprite.height * transform.scaleY,
        sprite.color, sprite.alpha
      );
    }

    this.batch.flush(ctx);
  }

  getBatch(): SpriteBatch {
    return this.batch;
  }
}
```

- [ ] **Step 3: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/engine/internal/SpriteBatch.ets
git add entry/src/main/ets/engine/systems/RenderSystem.ets
git commit -m "feat(engine): integrate SpriteBatch into RenderSystem with zIndex sorting and culling"
```

---

### Task 15: Extract Audio Synthesis into Platform Layer

**Files:**
- Modify: `entry/src/main/ets/engine/platform/HarmonyOSPlatform.ets`
- Create: `entry/src/main/ets/engine/platform/AudioSynth.ets`

**Interfaces:**
- Consumes: HarmonyOS AudioKit
- Produces: `AudioSynth` class with PCM generation methods (extracted from AudioManager)

- [ ] **Step 1: Create AudioSynth.ets with synthesis methods**

Extract the pure synthesis functions from `game/AudioManager.ets` (genToneSweep, genDualTone, genArpeggio, genNoiseBurst, genFilteredNoise) into a standalone class:

```typescript
// entry/src/main/ets/engine/platform/AudioSynth.ets

const SAMPLE_RATE: number = 44100;
const TWO_PI: number = Math.PI * 2;
const BYTES_PER_SAMPLE: number = 2;

export class AudioSynth {
  static genToneSweep(durationSec: number, startFreq: number, endFreq: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    let phase: number = 0;
    for (let i: number = 0; i < numSamples; i++) {
      const progress: number = i / numSamples;
      const freq: number = startFreq + (endFreq - startFreq) * progress;
      phase += TWO_PI * freq / SAMPLE_RATE;
      const envelope: number = Math.min(1.0, (numSamples - i) / (SAMPLE_RATE * 0.02));
      const sample: number = Math.sin(phase) * vol * envelope;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  static genDualTone(durationSec: number, freq1: number, freq2: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    let phase1: number = 0;
    let phase2: number = 0;
    for (let i: number = 0; i < numSamples; i++) {
      phase1 += TWO_PI * freq1 / SAMPLE_RATE;
      phase2 += TWO_PI * freq2 / SAMPLE_RATE;
      const envelope: number = Math.min(1.0, (numSamples - i) / (SAMPLE_RATE * 0.015));
      const sample: number = (Math.sin(phase1) + Math.sin(phase2)) * 0.5 * vol * envelope;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  static genArpeggio(durationSec: number, freqs: number[], vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    const noteSamples: number = Math.floor(numSamples / freqs.length);
    for (let i: number = 0; i < numSamples; i++) {
      const noteIdx: number = Math.min(Math.floor(i / noteSamples), freqs.length - 1);
      const freq: number = freqs[noteIdx];
      const t: number = (i % noteSamples) / SAMPLE_RATE;
      const noteProgress: number = (i % noteSamples) / noteSamples;
      const envelope: number = Math.max(0, 1.0 - noteProgress * 0.6);
      const sample: number = Math.sin(TWO_PI * freq * t) * vol * envelope;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  static genNoiseBurst(durationSec: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    for (let i: number = 0; i < numSamples; i++) {
      const decay: number = 1.0 - (i / numSamples);
      const noise: number = Math.random() * 2 - 1;
      const sample: number = noise * vol * decay * decay;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }

  static genFilteredNoise(durationSec: number, vol: number): ArrayBuffer {
    const numSamples: number = Math.floor(SAMPLE_RATE * durationSec);
    const buf: ArrayBuffer = new ArrayBuffer(numSamples * BYTES_PER_SAMPLE);
    const view: DataView = new DataView(buf);
    const coeff: number = 0.3;
    let prev: number = 0;
    for (let i: number = 0; i < numSamples; i++) {
      const decay: number = 1.0 - (i / numSamples);
      const noise: number = Math.random() * 2 - 1;
      prev = prev * (1.0 - coeff) + noise * coeff;
      const sample: number = prev * vol * decay;
      view.setInt16(i * BYTES_PER_SAMPLE, Math.floor(sample * 32767), true);
    }
    return buf;
  }
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/platform/AudioSynth.ets
git commit -m "feat(engine): extract audio synthesis into platform AudioSynth"
```

---

### Task 16: Implement InputSystem and AudioSystem shells

**Files:**
- Modify: `entry/src/main/ets/engine/systems/InputSystem.ets`
- Modify: `entry/src/main/ets/engine/systems/AudioSystem.ets`

**Interfaces:**
- Consumes: `PlayerInput`, `AudioSource` components
- Produces: Input consumption framework, audio playback control

- [ ] **Step 1: Implement InputSystem with external input registration**

```typescript
// entry/src/main/ets/engine/systems/InputSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { PlayerInput } from '../components/PlayerInput';

export class InputSystem extends System {
  readonly name: string = 'input';
  readonly dependencies: string[] = [];
  priority: number = 0;

  private pendingMoveX: number = 0;
  private pendingMoveY: number = 0;
  private pendingAttack: boolean = false;
  private pendingJump: boolean = false;
  private pendingDash: boolean = false;
  private pendingTool: boolean = false;
  private pendingInteract: boolean = false;

  private attackBufferTimer: number = 0;
  private jumpBufferTimer: number = 0;
  private dashBufferTimer: number = 0;
  private readonly BUFFER_WINDOW: number = 150;

  setInput(moveX: number, moveY: number, attack: boolean, jump: boolean, dash: boolean, tool: boolean, interact: boolean): void {
    this.pendingMoveX = moveX;
    this.pendingMoveY = moveY;
    if (attack) this.attackBufferTimer = this.BUFFER_WINDOW;
    if (jump) this.jumpBufferTimer = this.BUFFER_WINDOW;
    if (dash) this.dashBufferTimer = this.BUFFER_WINDOW;
    this.pendingAttack = attack;
    this.pendingJump = jump;
    this.pendingDash = dash;
    this.pendingTool = tool;
    this.pendingInteract = interact;
  }

  update(world: World, dt: number, entities: Entity[]): void {
    if (this.attackBufferTimer > 0) this.attackBufferTimer -= dt;
    if (this.jumpBufferTimer > 0) this.jumpBufferTimer -= dt;
    if (this.dashBufferTimer > 0) this.dashBufferTimer -= dt;

    const inputs: Entity[] = world.query('playerInput');
    for (const e of inputs) {
      const input: PlayerInput | undefined = world.getComponent<PlayerInput>(e, 'playerInput');
      if (!input) continue;

      input.moveX = this.pendingMoveX;
      input.moveY = this.pendingMoveY;
      input.attackPressed = this.attackBufferTimer > 0;
      input.jumpPressed = this.jumpBufferTimer > 0;
      input.dashPressed = this.dashBufferTimer > 0;
      input.toolPressed = this.pendingTool;
      input.interactPressed = this.pendingInteract;
    }
  }
}
```

- [ ] **Step 2: Implement AudioSystem**

```typescript
// entry/src/main/ets/engine/systems/AudioSystem.ets

import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { AudioSource } from '../components/AudioSource';
import { Transform } from '../components/Transform';

export class AudioSystem extends System {
  readonly name: string = 'audio';
  readonly dependencies: string[] = [];
  priority: number = 40;

  private soundCallbacks: Map<string, (soundId: string, volume: number) => void> = new Map();
  private maxSimultaneous: number = 6;
  private activeSounds: Map<string, number> = new Map();

  setSoundCallback(callback: (soundId: string, volume: number) => void): void {
    this.soundCallbacks.set('default', callback);
  }

  update(world: World, dt: number, entities: Entity[]): void {
    const sources: Entity[] = world.query('audioSource');
    for (const e of sources) {
      const source: AudioSource | undefined = world.getComponent<AudioSource>(e, 'audioSource');
      if (!source || !source.playing) continue;

      const current: number = this.activeSounds.get(source.soundId) ?? 0;
      if (current >= this.maxSimultaneous) {
        source.playing = false;
        continue;
      }

      let volume: number = source.volume;
      if (source.spatial) {
        const transform: Transform | undefined = world.getComponent<Transform>(e, 'transform');
        if (transform) {
          const cameraEntities: Entity[] = world.query('camera', 'transform');
          if (cameraEntities.length > 0) {
            const camTransform: Transform | undefined =
              world.getComponent<Transform>(cameraEntities[0], 'transform');
            if (camTransform) {
              const dx: number = transform.x - camTransform.x;
              const pan: number = Math.max(-1, Math.min(1, dx / 480));
              volume = volume * (1.0 - Math.abs(pan) * 0.5);
            }
          }
        }
      }

      const cb: ((soundId: string, volume: number) => void) | undefined =
        this.soundCallbacks.get('default');
      if (cb) {
        cb(source.soundId, volume);
      }

      this.activeSounds.set(source.soundId, current + 1);
      source.playing = false;
    }

    this.activeSounds.clear();
  }
}
```

- [ ] **Step 3: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/engine/systems/InputSystem.ets
git add entry/src/main/ets/engine/systems/AudioSystem.ets
git commit -m "feat(engine): implement InputSystem with buffering and AudioSystem with spatial audio"
```

---

### Task 17: Phase 2 Integration Verification

**Files:**
- Modify: `entry/src/main/ets/engine/__tests__/EngineSmokeTest.ets`

**Interfaces:**
- Consumes: All engine systems
- Produces: Verification that all systems work together

- [ ] **Step 1: Update smoke test to exercise all systems**

Add system registration and a test entity with physics:

```typescript
// Add to the test scene:
import { RenderSystem } from '../systems/RenderSystem';
import { PhysicsSystem } from '../systems/PhysicsSystem';
import { CameraSystem } from '../systems/CameraSystem';
import { InputSystem } from '../systems/InputSystem';
import { ParticleSimSystem } from '../systems/ParticleSimSystem';
import { AudioSystem } from '../systems/AudioSystem';
import { createRigidBody, RigidBody } from '../components/RigidBody';
import { createCamera, CameraComponent } from '../components/Camera';

// In TestScene.onEnter():
// Register all systems
// Create test entities with Transform + Sprite + RigidBody
// Verify physics moves entities
// Verify camera follows
// Verify render draws
```

- [ ] **Step 2: Compile and run smoke test**

Expected: All systems initialize, entity with RigidBody falls due to gravity, RenderSystem draws it.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/engine/__tests__/EngineSmokeTest.ets
git commit -m "feat(engine): Phase 2 integration verification - all systems operational"
```

---

## Phase 3: Game Logic Split

> **Note:** Phase 3 is the highest-risk phase. Each System migration must be compiled and run-verified immediately after migration. Do NOT batch-migrate.

### Task 18: Create GameScene and Register Systems

**Files:**
- Create: `entry/src/main/ets/game/GameScene.ets`

**Interfaces:**
- Consumes: Engine API, all game systems (created in subsequent tasks)
- Produces: `GameScene` that registers all game-specific systems

- [ ] **Step 1: Create GameScene skeleton**

```typescript
// entry/src/main/ets/game/GameScene.ets

import { Scene } from '../engine/scene/Scene';
import { World } from '../engine/core/World';
import { RenderSystem } from '../engine/systems/RenderSystem';
import { PhysicsSystem } from '../engine/systems/PhysicsSystem';
import { CameraSystem } from '../engine/systems/CameraSystem';
import { InputSystem } from '../engine/systems/InputSystem';
import { ParticleSimSystem } from '../engine/systems/ParticleSimSystem';
import { AudioSystem } from '../engine/systems/AudioSystem';

export class GameScene extends Scene {
  private world: World;

  constructor(world: World) {
    super('game');
    this.world = world;
  }

  onLoad(): void {
    this.world.addSystem(new InputSystem());
    this.world.addSystem(new PhysicsSystem());
    this.world.addSystem(new CameraSystem());
    this.world.addSystem(new ParticleSimSystem());
    this.world.addSystem(new AudioSystem());
    this.world.addSystem(new RenderSystem());
  }

  onEnter(): void {
    // Phase 3 tasks will add game-specific systems here
  }

  update(dt: number): void {
    this.world.update(dt);
  }

  render(ctx: CanvasRenderingContext2D): void {
    this.world.render(ctx);
  }
}
```

- [ ] **Step 2: Compile verify**

Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/GameScene.ets
git commit -m "feat(game): add GameScene with engine system registration"
```

---

### Task 19–32: Game Logic System Migration (14 systems)

Each of the following tasks follows the same pattern:
1. Cut corresponding methods from `GameEngine.ets`
2. Create System class, move logic into `update()` / `render()`
3. Replace direct `this.player` / `this.enemies[]` access with `world.query()`
4. Register System in GameScene
5. Compile and verify

Due to the repetitive structure, each task is documented with the specific methods to extract and the target file.

#### Task 19: PlayerMovementSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/PlayerMovementSystem.ets`
- Modify: `entry/src/main/ets/game/GameEngine.ets` (cut movement methods)
- Modify: `entry/src/main/ets/game/GameScene.ets` (register system)

**Extract from GameEngine:** `updatePlayer()`, `handlePlayerMovement()`, jump/dash logic (~400 lines)

- [ ] **Step 1: Create PlayerMovementSystem.ets**
- [ ] **Step 2: Cut movement methods from GameEngine**
- [ ] **Step 3: Register in GameScene**
- [ ] **Step 4: Compile verify**
- [ ] **Step 5: Commit**

```bash
git commit -m "refactor(game): extract PlayerMovementSystem from GameEngine"
```

#### Task 20: PlayerCombatSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/PlayerCombatSystem.ets`

**Extract:** Attack logic, weapon forms, combo system (~600 lines)

- [ ] **Step 1–5: Same pattern as Task 19**

```bash
git commit -m "refactor(game): extract PlayerCombatSystem from GameEngine"
```

#### Task 21: TransformSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/TransformSystem.ets`

**Extract:** Transformation system (4 forms, energy, boss core drops) (~300 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract TransformSystem from GameEngine"
```

#### Task 22: EnemyAISystem

**Files:**
- Create: `entry/src/main/ets/game/systems/EnemyAISystem.ets`

**Extract:** 6 slime AI types, movement patterns (~500 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract EnemyAISystem from GameEngine"
```

#### Task 23: BossSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/BossSystem.ets`

**Extract:** Boss behavior, phase switching (~400 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract BossSystem from GameEngine"
```

#### Task 24: TrapSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/TrapSystem.ets`

**Extract:** Trap state machine (~300 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract TrapSystem from GameEngine"
```

#### Task 25: MechanismSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/MechanismSystem.ets`

**Extract:** Mechanism interaction logic (~350 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract MechanismSystem from GameEngine"
```

#### Task 26: ChunkLoadSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/ChunkLoadSystem.ets`

**Extract:** Chunk load/unload logic (~200 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract ChunkLoadSystem from GameEngine"
```

#### Task 27: DamageSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/DamageSystem.ets`

**Extract:** Damage calculation, invincibility frames (~200 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract DamageSystem from GameEngine"
```

#### Task 28: XpLevelSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/XpLevelSystem.ets`

**Extract:** Experience collection, leveling (~150 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract XpLevelSystem from GameEngine"
```

#### Task 29: ChestSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/ChestSystem.ets`

**Extract:** Chest interaction (~150 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract ChestSystem from GameEngine"
```

#### Task 30: MaterialDropSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/MaterialDropSystem.ets`

**Extract:** Material drop logic (~100 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract MaterialDropSystem from GameEngine"
```

#### Task 31: EvolutionSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/EvolutionSystem.ets`

**Extract:** Weapon evolution (~200 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract EvolutionSystem from GameEngine"
```

#### Task 32: SaveLoadSystem

**Files:**
- Create: `entry/src/main/ets/game/systems/SaveLoadSystem.ets`

**Extract:** Save/load logic (~150 lines)

- [ ] **Step 1–5**

```bash
git commit -m "refactor(game): extract SaveLoadSystem from GameEngine"
```

---

### Task 33–39: Game Renderers (7 renderers)

Each renderer extracts rendering code from GameEngine into a dedicated class that uses the SpriteBatch from RenderSystem.

#### Task 33: TileRenderer

**Files:**
- Create: `entry/src/main/ets/game/renderers/TileRenderer.ets`

**Extract:** Terrain rendering (~300 lines)

- [ ] **Step 1: Create TileRenderer.ets**
- [ ] **Step 2: Cut terrain rendering from GameEngine**
- [ ] **Step 3: Compile verify**
- [ ] **Step 4: Commit**

```bash
git commit -m "refactor(game): extract TileRenderer from GameEngine"
```

#### Task 34: PlayerRenderer

**Files:**
- Create: `entry/src/main/ets/game/renderers/PlayerRenderer.ets`

**Extract:** Player rendering (~400 lines)

- [ ] **Step 1–4**

```bash
git commit -m "refactor(game): extract PlayerRenderer from GameEngine"
```

#### Task 35: EnemyRenderer

**Files:**
- Create: `entry/src/main/ets/game/renderers/EnemyRenderer.ets`

**Extract:** Enemy rendering (~200 lines)

- [ ] **Step 1–4**

```bash
git commit -m "refactor(game): extract EnemyRenderer from GameEngine"
```

#### Task 36: BossRenderer

**Files:**
- Create: `entry/src/main/ets/game/renderers/BossRenderer.ets`

**Extract:** Boss rendering (~200 lines)

- [ ] **Step 1–4**

```bash
git commit -m "refactor(game): extract BossRenderer from GameEngine"
```

#### Task 37: EffectRenderer

**Files:**
- Create: `entry/src/main/ets/game/renderers/EffectRenderer.ets`

**Extract:** Effects rendering (~300 lines)

- [ ] **Step 1–4**

```bash
git commit -m "refactor(game): extract EffectRenderer from GameEngine"
```

#### Task 38: UIRenderer

**Files:**
- Create: `entry/src/main/ets/game/renderers/UIRenderer.ets`

**Extract:** HUD, minimap rendering (~400 lines)

- [ ] **Step 1–4**

```bash
git commit -m "refactor(game): extract UIRenderer from GameEngine"
```

#### Task 39: TransformRenderer

**Files:**
- Create: `entry/src/main/ets/game/renderers/TransformRenderer.ets`

**Extract:** Transform visual effects (~200 lines)

- [ ] **Step 1–4**

```bash
git commit -m "refactor(game): extract TransformRenderer from GameEngine"
```

---

### Task 40: Create MainMenuScene

**Files:**
- Create: `entry/src/main/ets/game/MainMenuScene.ets`

- [ ] **Step 1: Create MainMenuScene.ets**

```typescript
// entry/src/main/ets/game/MainMenuScene.ets

import { Scene } from '../engine/scene/Scene';

export class MainMenuScene extends Scene {
  private selectedOption: number = 0;
  private options: string[] = ['New Game', 'Continue', 'Settings'];

  constructor() {
    super('main-menu');
  }

  onLoad(): void {
    // Load menu resources
  }

  onEnter(): void {
    this.selectedOption = 0;
  }

  update(dt: number): void {
    // Handle menu input
  }

  render(ctx: CanvasRenderingContext2D): void {
    const w: number = ctx.canvas.width;
    const h: number = ctx.canvas.height;

    ctx.fillStyle = '#08080f';
    ctx.fillRect(0, 0, w, h);

    ctx.fillStyle = '#ffffff';
    ctx.font = '32px monospace';
    ctx.textAlign = 'center';
    ctx.fillText('Underground Explorer', w / 2, h / 3);

    ctx.font = '20px monospace';
    for (let i: number = 0; i < this.options.length; i++) {
      const y: number = h / 2 + i * 40;
      ctx.fillStyle = i === this.selectedOption ? '#ffd700' : '#aaaaaa';
      ctx.fillText(this.options[i], w / 2, y);
    }
  }
}
```

- [ ] **Step 2: Compile verify**
- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/MainMenuScene.ets
git commit -m "feat(game): add MainMenuScene"
```

---

### Task 41: Phase 3 Final Verification

- [ ] **Step 1: Verify GameEngine.ets is reduced to <500 lines** (only entity creation, system wiring, and glue code remains)
- [ ] **Step 2: Full game playtest — verify no regressions**
- [ ] **Step 3: Commit**

```bash
git commit -m "refactor(game): Phase 3 complete - GameEngine split into ECS systems"
```

---

## Phase 4: UI Layer Adaptation

### Task 42: Adapt Index.ets to Engine Entry Point

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: `Engine`, `GameScene`, `MainMenuScene`
- Produces: Updated Index.ets using Engine.init() pattern

- [ ] **Step 1: Replace GameEngine instantiation with Engine.init()**

```typescript
// In Index.ets, replace:
//   this.gameEngine = new GameEngine();
//   this.gameEngine.init(ctx, ...);
// With:

import { Engine } from '../engine/core/Engine';
import { GameScene } from '../game/GameScene';
import { MainMenuScene } from '../game/MainMenuScene';

// In aboutToAppear or onCanvasCreated:
this.engine = await Engine.init({
  canvas: gameCtx,
  screenWidth: this.screenW,
  screenHeight: this.screenH,
  scenes: [
    { name: 'main-menu', factory: (): Scene => new MainMenuScene() },
    { name: 'game', factory: (): Scene => new GameScene(this.engine.world) },
  ],
  entryScene: 'main-menu',
  appContext: getContext(this),
});
this.engine.scenes.switchTo('main-menu');
this.engine.start();
```

- [ ] **Step 2: Update pause/resume handlers**

```typescript
// Replace gameEngine.pause()/resume() with:
this.engine.pause();
this.engine.resume();
```

- [ ] **Step 3: Update save handlers**

```typescript
// Save system now goes through SaveLoadSystem in the World
// Index.ets calls: engine.world.getSystem('saveLoad') to trigger saves
```

- [ ] **Step 4: Compile and full playtest**

Expected: Game launches with main menu, enters game scene, all gameplay works identically to pre-migration.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat(game): adapt Index.ets to Engine entry point pattern"
```

---

### Task 43: Cleanup and Final Verification

- [ ] **Step 1: Remove old game module files that have been fully migrated**

Files to potentially remove or archive:
- `game/PhysicsEngine.ets` → now in `engine/systems/PhysicsSystem.ets`
- `game/ParticleSystem.ets` → now in `engine/systems/ParticleSimSystem.ets`
- `game/SpriteBatch.ets` → now in `engine/internal/SpriteBatch.ets`

Keep `game/AudioManager.ets` until game layer is refactored to use AudioSystem callbacks.
Keep `game/GameConstants.ets` as pure game data.
Keep `game/WorldGenerator.ets` as game-specific.
Keep `game/SaveManager.ets` until SaveLoadSystem fully replaces it.

- [ ] **Step 2: Update all import paths across the project**
- [ ] **Step 3: Full compilation check**
- [ ] **Step 4: Full playtest**
- [ ] **Step 5: Final commit**

```bash
git commit -m "chore: cleanup after ECS migration - remove migrated files, update imports"
```

---

## Effort Summary

| Phase | Tasks | Estimated Lines | Risk |
|---|---|---|---|
| Phase 1: Engine skeleton | 1–11 | ~2000 new | Low |
| Phase 2: Module migration | 12–17 | ~500 changes | Medium |
| Phase 3: Logic split | 18–41 | 6500 refactor | High |
| Phase 4: UI adaptation | 42–43 | ~300 changes | Medium |

**Total: 43 tasks across 4 phases. Each task is independently compilable and committable.**
