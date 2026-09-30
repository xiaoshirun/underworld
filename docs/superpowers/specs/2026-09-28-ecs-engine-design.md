# HarmonyOS ECS Game Engine Design

**Date:** 2026-09-28
**Status:** Approved
**Scope:** Extract the game engine into a reusable ECS framework for HarmonyOS

## Overview

Transform the current monolithic GameEngine (6500 lines) into a reusable ECS (Entity-Component-System) game engine for HarmonyOS. The engine will support scene management, resource management, and a full set of built-in systems, allowing other developers to build their own games on top of it.

**Platform:** HarmonyOS only (no cross-platform abstraction)
**Architecture:** Pure ECS (Entity-Component-System)
**Rendering:** Canvas2D
**Scene Management:** Full scene manager with lifecycle, stack, transitions
**Resource Management:** Full resource manager with async loading, caching, reference counting

---

## 1. ECS Core

### Entity

Pure ID (number), no data. World maintains an entity pool using generational indices (generation + index) to prevent dangling references.

```typescript
type Entity = number; // high 16 bits = generation, low 16 bits = index
```

### Component

Pure data interfaces, no logic methods. Each component type is registered in World's component storage.

```typescript
interface ComponentTag { readonly tag: string; }

interface ComponentStorage<T> {
  get(entity: Entity): T | undefined;
  set(entity: Entity, component: T): void;
  remove(entity: Entity): void;
  has(entity: Entity): boolean;
}
```

### System

Pure logic, processes entities that have specific component combinations.

```typescript
abstract class System {
  abstract readonly name: string;
  abstract readonly dependencies: string[];
  priority: number = 0;

  abstract update(world: World, dt: number, entities: Entity[]): void;
  render?(world: World, ctx: CanvasRenderingContext2D, entities: Entity[]): void;
}
```

### World

ECS core container. Manages entity lifecycle, component storage, system scheduling.

```typescript
class World {
  createEntity(): Entity;
  destroyEntity(entity: Entity): void;

  addComponent<T>(entity: Entity, tag: string, component: T): void;
  getComponent<T>(entity: Entity, tag: string): T | undefined;
  removeComponent(entity: Entity, tag: string): void;

  query(...tags: string[]): Entity[];

  addSystem(system: System): void;
  removeSystem(name: string): void;

  update(dt: number): void;
  render(ctx: CanvasRenderingContext2D): void;
}
```

**Key design decisions:**
- Component query results are cached; cache is invalidated when components change
- Systems execute sorted by priority, with topological sort for dependencies
- Entity destruction is deferred to end-of-frame to avoid invalidation during iteration

---

## 2. Built-in Components

All components are pure data with no logic methods.

| Component | Fields | Purpose |
|---|---|---|
| Transform | x, y, rotation, scaleX, scaleY, zIndex | Spatial transform (required for all visible entities) |
| Sprite | color, width, height, visible, alpha, flipX | Sprite rendering |
| AnimatedSprite | frames[], currentFrame, frameDuration, elapsed, loop, playing | Frame animation |
| Collider | type (box/circle), width, height, radius, offsetX, offsetY, isTrigger, layer, mask | Collision body |
| RigidBody | vx, vy, mass, gravityScale, friction, isKinematic | Physics body |
| Camera | followEntity, lerpSpeed, offsetX, offsetY, shakeIntensity, shakeTimer, zoom | Camera control |
| ParticleEmitter | config, mode, emitInterval, lifetime, elapsed, active | Particle emitter |
| Health | current, max, invincibleTimer | Health tracking |
| AI | type (wander/chase/patrol/boss), speed, detectRange, targetEntity, stateTimer, data[] | AI behavior |
| PlayerInput | moveX, moveY, attackPressed, jumpPressed, dashPressed, toolPressed | Player input state |
| Light | color, radius, intensity, flicker, flickerSpeed | Light source |
| Tag | tags[] | Query grouping labels |
| AudioSource | soundId, volume, loop, spatial, playing | Audio playback |
| TilemapCollider | tileMap[][], tileSize | Terrain collision data |

---

## 3. Built-in Systems

Six core systems, each with a single responsibility.

### RenderSystem
- Traverses all entities with Sprite + Transform, sorts by zIndex, renders via SpriteBatch
- Supports AnimatedSprite frame animation driving
- Camera frustum culling: only renders sprites within camera viewport
- Does not care about sprite content, only responsible for "drawing primitives to Canvas"

### PhysicsSystem
- Wraps existing PhysicsEngine, handles RigidBody + Collider collision detection and response
- Spatial hash grid for collision query acceleration
- Supports AABB collision + terrain tile collision (via TilemapCollider component)
- Collision callback: sets Collider.onCollisionEnter flag on collision start
- Interface: `update(world, dt)` updates velocity/position, `checkCollisions(world)` detects collision pairs

### ParticleSimSystem
- Manages lifecycle and particle updates for all ParticleEmitter components
- Reuses existing ParticleManager algorithms, but data stored in components
- Supports 5 particle shapes (circle, square, triangle, star, line)
- Per-emitter config: emit rate, lifetime, velocity range, color gradient
- Particle count limit with oldest-first eviction

### InputSystem
- Converts platform-layer raw touch/key events into PlayerInput component data
- Virtual joystick input -> moveX/moveY (-1 to 1 float values)
- Button input -> attackPressed, dashPressed, interactPressed boolean flags
- Input buffering: short press within 150ms still valid
- Virtual joystick implementation lives in platform layer; InputSystem only consumes standardized input data

### AudioSystem
- Manages AudioSource component playback control
- Reuses existing AudioManager Web Audio synthesis engine
- Spatial audio: calculates left/right channel volume based on entity position vs camera distance
- Sound pool: max N simultaneous instances per soundId to prevent stacking
- System only handles play/stop; waveform synthesis stays in platform layer

### CameraSystem
- Manages Camera components: follow, boundary clamping, screen shake
- Smooth lerp follow with adjustable factor
- Boundary clamping: camera stays within world bounds
- Screen shake: `shake(intensity, duration)` with decay
- Camera zoom: 0.5x ~ 3.0x for cutscenes or special effects

### System Execution Order

```
InputSystem.update()     -> read input, write PlayerInput components
PhysicsSystem.update()   -> physics simulation, update Transform
CameraSystem.update()    -> camera follow, update viewport
ParticleSimSystem.update() -> particle simulation
AudioSystem.update()     -> audio triggers
RenderSystem.render()    -> final draw (after all updates)
```

World maintains a `systems[]` array, executes in registration order. Default registration order matches above; users can customize.

---

## 4. Scene Manager

### Scene Base Class

```typescript
abstract class Scene {
  readonly name: string;

  onLoad(): void;              // Called on first load (resource loading)
  onEnter(): void;             // Called when scene becomes active
  onPause(): void;             // Called when pushed below another scene
  onResume(): void;            // Called when restored to top of stack
  onExit(): void;              // Called when scene is removed
  update(dt: number): void;    // Per-frame update
  render(ctx: CanvasRenderingContext2D): void;  // Per-frame render
}
```

### SceneManager

```typescript
class SceneManager {
  register(name: string, sceneFactory: () => Scene): void;
  switchTo(name: string, transition?: Transition): void;
  push(name: string, transition?: Transition): void;
  pop(transition?: Transition): void;
  current(): Scene;
  update(dt: number): void;
  render(ctx: CanvasRenderingContext2D): void;
}
```

### Scene Stack Example

```
[GameScene]                              -> normal gameplay
[GameScene, PauseScene]                  -> pause menu opened
[GameScene, PauseScene, SettingsScene]   -> settings opened from pause
[GameScene, PauseScene]                  -> settings closed (pop)
[GameScene]                              -> pause closed (pop)
[MainMenuScene]                          -> quit game (switchTo replaces stack)
```

### Transitions

```typescript
interface Transition {
  type: 'fade' | 'slide-left' | 'slide-right' | 'slide-up' | 'dissolve';
  duration: number; // ms
}
```

- `switchTo` plays exit transition then enter transition
- `push/pop` only plays transition for top scene
- `update()` continues during transitions (for cutscenes); game logic can choose to pause

### Resource Preloading

SceneManager calls `onLoad()` and waits for the returned Promise to resolve before calling `onEnter()`. During loading, a LoadingScene with progress bar is displayed.

---

## 5. Resource Manager

```typescript
enum ResourceType { TEXTURE, AUDIO, DATA, FONT }

interface ResourceEntry {
  key: string;
  type: ResourceType;
  data: any;
  state: 'loading' | 'loaded' | 'error';
  refCount: number;
}

class ResourceManager {
  async load(key: string, type: ResourceType, loader: () => Promise<any>): Promise<any>;
  async loadAll(entries: { key: string; type: ResourceType; loader: () => Promise<any> }[]): Promise<void>;
  get<T>(key: string): T | null;
  acquire(key: string): void;    // refCount +1
  release(key: string): void;    // refCount -1, auto-unload at zero
  unload(key: string): void;
  unloadUnused(): void;
  isLoaded(key: string): boolean;
  getLoadProgress(): number;     // 0.0 ~ 1.0
}
```

### Reference Counting Flow

```
Scene.onLoad()   -> resources.loadAll([...])     // load, refCount = 1
Scene.onEnter()  -> resources.acquire('player')   // extra reference
Entity.destroy() -> resources.release('player')   // refCount -1
Scene.onExit()   -> resources.unloadUnused()      // clean up unreferenced
```

### Loading Strategy

- **Texture:** HarmonyOS `resourceManager.getRawFile()` -> decode to PixelMap -> cache
- **Audio:** Store synthesis parameter configs (waveform, frequency, duration); synthesize on demand via AudioManager
- **Data:** JSON parse and cache directly
- All loading is async, non-blocking

### Error Handling

- Single resource failure does not block other resources
- Failed resources marked `state: 'error'`, `get()` returns null
- Console error logging; game layer can show placeholder or skip

---

## 6. Platform Layer + Engine Entry Point

### HarmonyOSPlatform

Static utility class bridging engine to HarmonyOS system APIs. Engine core never calls system APIs directly.

```typescript
class HarmonyOSPlatform {
  static createCanvas(width: number, height: number): CanvasRenderingContext2D;
  static createOffscreenCanvas(width: number, height: number): CanvasRenderingContext2D;
  static createAudioRenderer(sampleRate: number): AudioRendererAdapter;
  static async saveData(key: string, value: string): Promise<void>;
  static async loadData(key: string): Promise<string | null>;
  static async loadRawFile(path: string): Promise<ArrayBuffer>;
  static getScreenSize(): { width: number; height: number };
  static now(): number;
}

interface AudioRendererAdapter {
  write(pcmData: ArrayBuffer): void;
  start(): void;
  stop(): void;
  release(): void;
}
```

### Engine Entry Point

```typescript
class Engine {
  readonly world: World;
  readonly scenes: SceneManager;
  readonly resources: ResourceManager;

  static async init(config: EngineConfig): Promise<Engine>;
  start(): void;
  stop(): void;
  pause(): void;
  resume(): void;
}

interface EngineConfig {
  canvas: CanvasRenderingContext2D;
  screenWidth: number;
  screenHeight: number;
  targetFPS?: number;            // default 60
  scenes: { name: string; factory: () => Scene }[];
  entryScene: string;
  appContext?: Object;           // HarmonyOS UIAbilityContext
}
```

### Main Loop

```
tick() {
  const now = platform.now();
  const dt = now - lastTime;
  lastTime = now;

  scenes.current().update(dt);

  ctx.clearRect(0, 0, w, h);
  scenes.current().render(ctx);

  if (scenes.isTransitioning()) {
    scenes.renderTransition(ctx);
  }
}
```

### Startup Example

```typescript
const engine = await Engine.init({
  canvas: gameCtx,
  screenWidth: 960,
  screenHeight: 540,
  scenes: [
    { name: 'loading', factory: () => new LoadingScene() },
    { name: 'main-menu', factory: () => new MainMenuScene() },
    { name: 'game', factory: () => new GameScene() },
  ],
  entryScene: 'loading',
  appContext: context,
});

engine.scenes.switchTo('main-menu');
engine.start();
```

### Directory Structure

```
engine/
  core/
    Engine.ts              # Engine entry + main loop
    World.ts               # ECS World
    Entity.ts              # Entity ID (number)
    System.ts              # System base class
  scene/
    SceneManager.ts        # Scene stack + transitions
    Scene.ts               # Scene base class
  resource/
    ResourceManager.ts     # Loading + caching + reference counting
  systems/
    RenderSystem.ts
    PhysicsSystem.ts
    ParticleSimSystem.ts
    InputSystem.ts
    AudioSystem.ts
    CameraSystem.ts
  components/
    Transform.ts
    Sprite.ts
    AnimatedSprite.ts
    Collider.ts
    RigidBody.ts
    Camera.ts
    ParticleEmitter.ts
    Health.ts
    AI.ts
    PlayerInput.ts
    Light.ts
    Tag.ts
    AudioSource.ts
    TilemapCollider.ts
  platform/
    HarmonyOSPlatform.ts
```

---

## 7. Migration Strategy

4-phase progressive migration. Each phase ends with a compilable, runnable state.

### Phase 1: Engine Skeleton (no changes to existing code)

Create `engine/` directory with all core files:
- `core/Engine.ts`, `core/World.ts`, `core/System.ts`
- `scene/Scene.ts`, `scene/SceneManager.ts`
- `resource/ResourceManager.ts`
- `platform/HarmonyOSPlatform.ts`
- All `components/*.ts` (pure data interfaces, no logic)
- All `systems/*.ts` (empty shells, update/render methods are no-ops)

**Verification:** Engine initializes, creates World, registers empty Systems, main loop runs. Existing game completely unaffected.

### Phase 2: Reusable Modules Move to Engine

Migrate existing standalone modules to `engine/`, only changing import paths:

| Original | Destination | Changes |
|---|---|---|
| `game/PhysicsEngine.ets` | `engine/systems/PhysicsSystem.ets` | Wrap as System, remove TILE_SIZE hardcoding, read from TilemapCollider |
| `game/ParticleSystem.ets` | `engine/systems/ParticleSimSystem.ets` | Wrap as System, particle data from ParticleEmitter component |
| `game/SpriteBatch.ets` | `engine/systems/RenderSystem.ts` internal | Use as RenderSystem rendering backend |
| `game/AudioManager.ets` synthesis | `engine/platform/HarmonyOSPlatform.ts` | Keep synthesis algorithms; SoundId enum stays in game layer |

**Verification:** Existing GameEngine imports engine modules, functionality unchanged.

### Phase 3: Game Logic Split into ECS Systems

The largest phase. Split GameEngine logic by responsibility into independent Systems:

```
GameEngine.ets (6500 lines) splits into:

game/systems/
  PlayerMovementSystem.ts    <- movement, jumping, dashing (~400 lines)
  PlayerCombatSystem.ts      <- attack, weapon forms, evolution (~600 lines)
  TransformSystem.ts         <- transformation system (~300 lines)
  EnemyAISystem.ts           <- 6 slime AI types (~500 lines)
  BossSystem.ts              <- boss behavior + phase switching (~400 lines)
  TrapSystem.ts              <- trap state machine (~300 lines)
  MechanismSystem.ts         <- mechanism interaction (~350 lines)
  ChunkLoadSystem.ts         <- chunk load/unload (~200 lines)
  DamageSystem.ts            <- damage calculation + invincibility (~200 lines)
  XpLevelSystem.ts           <- experience/leveling (~150 lines)
  ChestSystem.ts             <- chest interaction (~150 lines)
  MaterialDropSystem.ts      <- material drops (~100 lines)
  EvolutionSystem.ts         <- weapon evolution (~200 lines)
  SaveLoadSystem.ts          <- save/load logic (~150 lines)

game/renderers/
  TileRenderer.ts            <- terrain rendering (~300 lines)
  PlayerRenderer.ts          <- player rendering (~400 lines)
  EnemyRenderer.ts           <- enemy rendering (~200 lines)
  BossRenderer.ts            <- boss rendering (~200 lines)
  EffectRenderer.ts          <- effects rendering (~300 lines)
  UIRenderer.ts              <- HUD/minimap (~400 lines)
  TransformRenderer.ts       <- transform rendering (~200 lines)

game/
  GameScene.ts               <- scene entry, registers all Systems
  MainMenuScene.ts           <- main menu scene
  GameConstants.ets          <- kept, pure game data
```

**Each System migration step:**
1. Cut corresponding methods from GameEngine
2. Create System class, move logic into `update()` / `render()`
3. Replace direct `this.player` / `this.enemies[]` access with `world.query()`
4. Register System in GameScene
5. Compile and verify

**Key conversion example:**

```typescript
// Old: GameEngine direct manipulation
updatePlayer(dt) {
  const p = this.player;
  p.x += p.vx * dt;
  // ... 200 lines of logic
}

// New: ECS System
class PlayerMovementSystem extends System {
  update(world: World, dt: number) {
    const entities = world.query('playerInput', 'transform', 'rigidBody');
    for (const e of entities) {
      const input = world.getComponent(e, 'playerInput');
      const transform = world.getComponent(e, 'transform');
      const body = world.getComponent(e, 'rigidBody');
      transform.x += body.vx * dt;
      // ... same logic, but data comes from components
    }
  }
}
```

### Phase 4: UI Layer Adaptation

Convert `Index.ets` to engine invocation pattern:

```typescript
// Old: Index.ets creates GameEngine directly
this.gameEngine = new GameEngine();
this.gameEngine.init(ctx, ...);

// New: Index.ets starts Engine
this.engine = await Engine.init({
  canvas: gameCtx,
  screenWidth: this.screenW,
  screenHeight: this.screenH,
  scenes: [
    { name: 'main-menu', factory: () => new MainMenuScene() },
    { name: 'game', factory: () => new GameScene(this.saveData) },
  ],
  entryScene: 'main-menu',
  appContext: getContext(this),
});
this.engine.start();
```

### Effort Estimates

| Phase | Work | Risk |
|---|---|---|
| Phase 1: Engine skeleton | ~2000 lines new code | Low (no impact on existing) |
| Phase 2: Module migration | ~500 lines changes | Medium (import path changes) |
| Phase 3: Logic split | 6500 lines refactor | High (verify per-System) |
| Phase 4: UI adaptation | ~300 lines changes | Medium |

Phase 3 is the core risk point. Each System should be compiled + run-verified immediately after migration; do not batch-migrate.
