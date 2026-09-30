# ECS 实际化 — 全面重写实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将游戏从 GameContext 上帝对象架构全面迁移到 ECS 架构，消除 GameContext/EngineBase/GameEngine 及 7 个 Bridge 接口，所有状态变为 Entity+Component，所有系统继承 Engine.System。

**Architecture:** Engine HAR 提供 World/Entity/System/Component 基础设施和 BaseContext→SystemContext 两层上下文。GameScene 持有 World 实例，注册 19 个系统，组装 SystemContext（含 audio/settings 以 Object 类型传入避免 Engine HAR 依赖游戏类型）。渲染器从 World 查询实体数据。

**Tech Stack:** HarmonyOS ArkTS strict mode, Canvas 2D rendering, Engine HAR module

**Spec:** `docs/superpowers/specs/2026-09-30-ecs-actualization-design.md`

## Global Constraints

- ArkTS strict mode：所有变量必须有显式类型注解，不允许 `any` 类型
- Engine HAR 不导入游戏专用类型（AudioManager、GameSettings、ChunkData、WorldGenerator），使用 `Object` 类型替代，在游戏代码中转型
- 游戏专用组件放在 `entry/src/main/ets/game/components/`，不污染 Engine HAR
- 区块数据（chunks）保留为 World 的环境数据，不做实体化
- 渲染器保持独立类，不继承 System
- 无单元测试可用——每个 Task 完成后通过 `hvigorw assembleHap` 编译验证
- 组件 getType() 返回小写字符串（如 "movement"、"combat"），与类名解耦
- 系统通过组件通信，禁止直接调用其他系统方法

---

## File Structure

### Engine HAR（修改/新增）

| 文件 | 操作 | 职责 |
|------|------|------|
| `Engine/src/main/ets/World.ets` | 新增 | 实体管理器 + 系统调度 + 空间索引 |
| `Engine/src/main/ets/Entity.ets` | 增强 | 添加 tag 字段 |
| `Engine/src/main/ets/Component.ets` | 扩展 | 添加 Serializable 接口 |
| `Engine/src/main/ets/System.ets` | 增强 | SystemContext 增加 world/audio/settings/frameCount |
| `Engine/src/main/ets/Scene.ets` | 改造 | SceneContext → BaseContext |
| `Engine/src/main/ets/Engine.ets` | 简化 | 移除 entities/systems/delegate，tick 只走 Scene 路径 |
| `Engine/src/main/ets/SceneManager.ets` | 微调 | 适配 BaseContext |
| `Engine/src/main/ets/index.ets` | 更新 | 导出 World, BaseContext, Serializable |

### Entry（新增）

| 文件 | 职责 |
|------|------|
| `entry/.../game/components/MovementComponent.ets` | 玩家移动状态 |
| `entry/.../game/components/CombatComponent.ets` | 玩家战斗状态 |
| `entry/.../game/components/TransformComponent.ets` | 变身状态 |
| `entry/.../game/components/InventoryComponent.ets` | 背包 |
| `entry/.../game/components/XpComponent.ets` | 经验等级 |
| `entry/.../game/components/EvolutionComponent.ets` | 进化状态 |
| `entry/.../game/components/EnemyAIComponent.ets` | 敌人 AI |
| `entry/.../game/components/BossAIComponent.ets` | Boss AI |
| `entry/.../game/components/XpPickupComponent.ets` | 经验球 |
| `entry/.../game/components/MaterialPickupComponent.ets` | 材料掉落 |
| `entry/.../game/components/TransformCorePickupComponent.ets` | 变身核心 |
| `entry/.../game/components/TrapComponent.ets` | 陷阱 |
| `entry/.../game/components/MechanismComponent.ets` | 机关 |
| `entry/.../game/components/ChestComponent.ets` | 宝箱 |
| `entry/.../game/components/ParticleComponent.ets` | 粒子 |
| `entry/.../game/components/CameraComponent.ets` | 相机 |
| `entry/.../game/components/GameStateComponent.ets` | 游戏状态 |
| `entry/.../game/factories/PlayerFactory.ets` | 玩家实体创建 |
| `entry/.../game/factories/EnemyFactory.ets` | 敌人实体创建 |
| `entry/.../game/factories/BossFactory.ets` | Boss 实体创建 |
| `entry/.../game/factories/DropFactory.ets` | 掉落物创建 |
| `entry/.../game/factories/WorldEntityFactory.ets` | 世界实体创建 |
| `entry/.../game/GameScene.ets` | 游戏场景（World + 系统 + 渲染器） |

### Entry（重写）

| 文件 | 职责 |
|------|------|
| `entry/.../game/systems/SpatialRebuildSystem.ets` | 重建空间索引 |
| `entry/.../game/systems/ChunkLoadSystem.ets` | 区块加载 |
| `entry/.../game/systems/PlayerMovementSystem.ets` | 玩家移动 |
| `entry/.../game/systems/PlayerCombatSystem.ets` | 玩家战斗 |
| `entry/.../game/systems/EnemyAISystem.ets` | 敌人 AI |
| `entry/.../game/systems/BossSystem.ets` | Boss AI |
| `entry/.../game/systems/TransformSystem.ets` | 变身系统 |
| `entry/.../game/systems/TrapSystem.ets` | 陷阱 |
| `entry/.../game/systems/MechanismSystem.ets` | 机关 |
| `entry/.../game/systems/ChestSystem.ets` | 宝箱 |
| `entry/.../game/systems/MaterialDropSystem.ets` | 材料拾取 |
| `entry/.../game/systems/XpLevelSystem.ets` | 经验升级 |
| `entry/.../game/systems/DamageSystem.ets` | 伤害/死亡 |
| `entry/.../game/systems/EvolutionSystem.ets` | 武器进化 |
| `entry/.../game/systems/CameraSystem.ets` | 相机跟随 |
| `entry/.../game/systems/ParticleSystem.ets` | 粒子实体 |
| `entry/.../game/systems/AmbientParticleSystem.ets` | 环境粒子 |
| `entry/.../game/systems/SaveLoadSystem.ets` | 存档 |
| `entry/.../game/systems/CleanupSystem.ets` | 清理死亡实体 |
| `entry/.../game/renderers/TileRenderer.ets` | 地形渲染 |
| `entry/.../game/renderers/PlayerRenderer.ets` | 玩家渲染 |
| `entry/.../game/renderers/EnemyRenderer.ets` | 敌人渲染 |
| `entry/.../game/renderers/BossRenderer.ets` | Boss 渲染 |
| `entry/.../game/renderers/EffectRenderer.ets` | 特效渲染 |
| `entry/.../game/renderers/UIRenderer.ets` | UI/小地图 |
| `entry/.../pages/Index.ets` | 入口页面 |

### Entry（删除）

| 文件 | 原因 |
|------|------|
| `entry/.../engine/EngineBase.ets` | GameContext 不存在，无意义 |
| `entry/.../game/GameContext.ets` | 被 World + 组件替代 |
| `entry/.../game/GameEngine.ets` | 被 World + GameScene 替代 |

---

### Task 1: Engine HAR Foundation

**Files:**
- Create: `Engine/src/main/ets/World.ets`
- Modify: `Engine/src/main/ets/Entity.ets`
- Modify: `Engine/src/main/ets/Component.ets`
- Modify: `Engine/src/main/ets/System.ets`
- Modify: `Engine/src/main/ets/Scene.ets`
- Modify: `Engine/src/main/ets/Engine.ets`
- Modify: `Engine/src/main/ets/SceneManager.ets`
- Modify: `Engine/src/main/ets/index.ets`

**Interfaces:**
- Produces: `World` class (addEntity, removeEntity, addSystem, query, queryWithTag, findEntityByTag, rebuildSpatialGrid, getSpatialGrid, update, getEntities)
- Produces: `BaseContext` interface (ctx, minimapCtx, screenW, screenH, input, resources, frameCount)
- Produces: `Serializable` interface (serialize, deserialize)
- Produces: Enhanced `SystemContext` (world, ctx, minimapCtx, screenW, screenH, cameraX, cameraY, input, resources, audio: Object, settings: Object, frameCount, dt)
- Produces: Enhanced `Entity` (tag field, constructor with tag)
- Consumed by: All game components (Task 2-4), all systems (Task 7-15), GameScene (Task 16)

- [ ] **Step 1: Add Serializable interface to Component.ets**

在 `Engine/src/main/ets/Component.ets` 末尾添加：

```typescript
export interface Serializable {
  serialize(): Record<string, Object>;
  deserialize(data: Record<string, Object>): void;
}
```

- [ ] **Step 2: Add tag to Entity.ets**

修改 `Engine/src/main/ets/Entity.ets`，添加 tag 字段：

```typescript
import { Component } from './Component';

let nextEntityId: number = 0;

export class Entity {
  readonly id: number;
  tag: string;
  private components: Map<string, Component> = new Map();
  active: boolean = true;

  constructor(tag: string = "") {
    this.id = nextEntityId++;
    this.tag = tag;
  }

  addComponent<T extends Component>(component: T): T {
    this.components.set(component.getType(), component);
    return component;
  }

  getComponent<T extends Component>(type: string): T | null {
    return (this.components.get(type) as T) ?? null;
  }

  hasComponent(type: string): boolean {
    return this.components.has(type);
  }

  removeComponent(type: string): void {
    this.components.delete(type);
  }

  getAllComponents(): Component[] {
    return Array.from(this.components.values());
  }
}
```

- [ ] **Step 3: Create World.ets**

创建 `Engine/src/main/ets/World.ets`：

```typescript
import { Entity } from './Entity';
import { System, SystemContext } from './System';
import { Component, PositionComponent } from './Component';
import { SpatialGrid } from './SpatialGrid';

export class World {
  private entities: Entity[] = [];
  private systems: System[] = [];
  private spatialGrid: SpatialGrid<Entity> = new SpatialGrid<Entity>(128);
  chunks: Map<string, Object> = new Map<string, Object>();
  worldGen: Object | null = null;
  cameraX: number = 0;
  cameraY: number = 0;

  addEntity(entity: Entity): Entity {
    this.entities.push(entity);
    return entity;
  }

  removeEntity(entity: Entity): void {
    entity.active = false;
  }

  addSystem(system: System): void {
    this.systems.push(system);
  }

  query(componentType: string): Entity[] {
    const result: Entity[] = [];
    for (let i: number = 0; i < this.entities.length; i++) {
      const e: Entity = this.entities[i];
      if (e.active && e.hasComponent(componentType)) {
        result.push(e);
      }
    }
    return result;
  }

  queryWithTag(tag: string): Entity[] {
    const result: Entity[] = [];
    for (let i: number = 0; i < this.entities.length; i++) {
      const e: Entity = this.entities[i];
      if (e.active && e.tag === tag) {
        result.push(e);
      }
    }
    return result;
  }

  findEntityByTag(tag: string): Entity | null {
    for (let i: number = 0; i < this.entities.length; i++) {
      if (this.entities[i].active && this.entities[i].tag === tag) {
        return this.entities[i];
      }
    }
    return null;
  }

  rebuildSpatialGrid(): void {
    this.spatialGrid.clear();
    for (let i: number = 0; i < this.entities.length; i++) {
      const e: Entity = this.entities[i];
      if (e.active && e.hasComponent("Position")) {
        const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
        this.spatialGrid.insert(pos.x, pos.y, e);
      }
    }
  }

  getSpatialGrid(): SpatialGrid<Entity> {
    return this.spatialGrid;
  }

  getEntities(): Entity[] {
    return this.entities;
  }

  update(context: SystemContext, dt: number): void {
    for (let i: number = 0; i < this.systems.length; i++) {
      const sys: System = this.systems[i];
      if (sys.isEnabled()) {
        sys.update(this.entities, context);
      }
    }
    this.entities = this.entities.filter((e: Entity) => e.active);
  }
}
```

注意：`chunks` 使用 `Map<string, Object>` 类型，游戏代码中转型为 `Map<string, ChunkData>`。`worldGen` 使用 `Object | null`，游戏代码中转型为 `WorldGenerator`。这避免了 Engine HAR 导入游戏专用类型。

- [ ] **Step 4: Enhance System.ets**

重写 `Engine/src/main/ets/System.ets`：

```typescript
import { Entity } from './Entity';
import { World } from './World';
import { InputState } from './Scene';
import { ResourceManager } from './ResourceManager';

export interface SystemContext {
  world: World;
  ctx: CanvasRenderingContext2D;
  minimapCtx: CanvasRenderingContext2D;
  screenW: number;
  screenH: number;
  cameraX: number;
  cameraY: number;
  input: InputState;
  resources: ResourceManager;
  audio: Object;
  settings: Object;
  frameCount: number;
  dt: number;
}

export abstract class System {
  protected enabled: boolean = true;

  isEnabled(): boolean {
    return this.enabled;
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  abstract update(entities: Entity[], context: SystemContext): void;
}
```

注意：`audio` 和 `settings` 使用 `Object` 类型。游戏系统中通过 `context.audio as AudioManager` 和 `context.settings as GameSettings` 转型。

- [ ] **Step 5: Transform Scene.ets (BaseContext)**

重写 `Engine/src/main/ets/Scene.ets`：

```typescript
import { ResourceManager } from './ResourceManager';

export interface InputState {
  joyActive: boolean;
  joyDx: number;
  joyDy: number;
  jumpPressed: boolean;
  attackPressed: boolean;
  dashPressed: boolean;
  attackHeld: boolean;
  toolPressed: boolean;
}

export interface BaseContext {
  ctx: CanvasRenderingContext2D;
  minimapCtx: CanvasRenderingContext2D;
  screenW: number;
  screenH: number;
  input: InputState;
  resources: ResourceManager;
  frameCount: number;
}

export abstract class Scene {
  protected onEnter(): void {}
  protected onExit(): void {}
  protected onPause(): void {}
  protected onResume(): void {}

  abstract update(baseCtx: BaseContext, dt: number): void;
  abstract render(baseCtx: BaseContext): void;
}
```

- [ ] **Step 6: Simplify Engine.ets**

重写 `Engine/src/main/ets/Engine.ets`，移除 entities/systems/delegate 及回退路径：

```typescript
import { ResourceManager } from './ResourceManager';
import { SceneManager } from './SceneManager';
import { InputState, BaseContext } from './Scene';

export { InputState } from './Scene';

export class Engine {
  private gameLoopId: number = -1;
  private frameCount: number = 0;
  private externalLoop: boolean = false;
  resources: ResourceManager = new ResourceManager();
  sceneManager: SceneManager = new SceneManager();

  ctx: CanvasRenderingContext2D | null = null;
  minimapCtx: CanvasRenderingContext2D | null = null;
  screenW: number = 0;
  screenH: number = 0;
  cameraX: number = 0;
  cameraY: number = 0;

  tickInterval: number = 33;

  input: InputState = {
    joyActive: false, joyDx: 0, joyDy: 0,
    jumpPressed: false, attackPressed: false,
    dashPressed: false, attackHeld: false,
    toolPressed: false
  };

  init(ctx: CanvasRenderingContext2D, minimapCtx: CanvasRenderingContext2D,
    screenW: number, screenH: number): void {
    this.ctx = ctx;
    this.minimapCtx = minimapCtx;
    this.screenW = screenW;
    this.screenH = screenH;
    this.startLoop();
  }

  startLoop(): void {
    if (this.externalLoop) return;
    this.gameLoopId = setInterval(() => {
      this.tick(this.tickInterval);
    }, this.tickInterval);
  }

  setExternalLoop(enabled: boolean): void {
    this.externalLoop = enabled;
  }

  tick(dt: number): void {
    const activeScene = this.sceneManager.getActiveScene();
    if (activeScene !== null && this.ctx !== null && this.minimapCtx !== null) {
      const baseCtx: BaseContext = {
        ctx: this.ctx,
        minimapCtx: this.minimapCtx,
        screenW: this.screenW,
        screenH: this.screenH,
        input: this.input,
        resources: this.resources,
        frameCount: this.frameCount
      };
      this.sceneManager.update(baseCtx, dt);
      this.sceneManager.render(baseCtx);
    }
    this.frameCount++;
  }

  stop(): void {
    if (this.gameLoopId !== -1) {
      clearInterval(this.gameLoopId);
      this.gameLoopId = -1;
    }
  }

  getFrameCount(): number {
    return this.frameCount;
  }

  setInputJoy(active: boolean, dx: number, dy: number): void {
    this.input.joyActive = active;
    this.input.joyDx = dx;
    this.input.joyDy = dy;
  }

  setInputJump(pressed: boolean): void {
    this.input.jumpPressed = pressed;
  }

  setInputAttack(pressed: boolean): void {
    this.input.attackPressed = pressed;
  }

  setInputDash(pressed: boolean): void {
    this.input.dashPressed = pressed;
  }

  setInputTool(pressed: boolean): void {
    this.input.toolPressed = pressed;
  }
}
```

关键变化：移除 `EngineDelegate` 接口、`delegate` 字段、`entities`/`systems` 数组、所有 addEntity/removeEntity/addSystem 方法、delegate 回退路径。tick() 只走 Scene 路径。

- [ ] **Step 7: Update SceneManager.ets**

修改 `Engine/src/main/ets/SceneManager.ets`，将 `SceneContext` 替换为 `BaseContext`：

```typescript
import { Scene, BaseContext } from './Scene';

export class SceneManager {
  private stack: Scene[] = [];
  private active: Scene | null = null;

  update(context: BaseContext, dt: number): void {
    if (this.active !== null) {
      this.active.update(context, dt);
    }
  }

  render(context: BaseContext): void {
    if (this.active !== null) {
      this.active.render(context);
    }
  }

  pushScene(scene: Scene): void {
    if (this.active !== null) {
      this.active.onPause();
      this.stack.push(this.active);
    }
    this.active = scene;
    scene.onEnter();
  }

  popScene(): Scene | null {
    if (this.active === null) {
      return null;
    }
    const leaving: Scene = this.active;
    leaving.onExit();
    this.active = this.stack.length > 0 ? this.stack.pop()! : null;
    if (this.active !== null) {
      this.active.onResume();
    }
    return leaving;
  }

  replaceScene(scene: Scene): void {
    if (this.active !== null) {
      this.active.onExit();
    }
    this.active = scene;
    scene.onEnter();
  }

  getActiveScene(): Scene | null {
    return this.active;
  }

  getStackSize(): number {
    return this.stack.length;
  }
}
```

- [ ] **Step 8: Update index.ets exports**

重写 `Engine/src/main/ets/index.ets`：

```typescript
export { Engine } from './Engine';
export { InputState, BaseContext, Scene } from './Scene';
export { SceneManager } from './SceneManager';
export { Entity } from './Entity';
export { System, SystemContext } from './System';
export {
  Component,
  Serializable,
  PositionComponent,
  VelocityComponent,
  HealthComponent,
  SpriteComponent,
  ColliderComponent
} from './Component';
export { World } from './World';
export { SpatialGrid } from './SpatialGrid';
export { ResourceManager, SpriteSheet, RawFileProvider } from './ResourceManager';
```

注意：移除 `EngineDelegate` 导出，新增 `World`、`BaseContext`、`Serializable`。

- [ ] **Step 9: Build verification**

Run: `hvigorw assembleHar --no-daemon` (in Engine directory)
Expected: BUILD SUCCESSFUL，无编译错误

- [ ] **Step 10: Commit**

```bash
git add Engine/src/main/ets/
git commit -m "feat: ECS foundation - World, BaseContext, Serializable, enhanced SystemContext"
```

---

### Task 2: Game Components — Player

**Files:**
- Create: `entry/src/main/ets/game/components/MovementComponent.ets`
- Create: `entry/src/main/ets/game/components/CombatComponent.ets`
- Create: `entry/src/main/ets/game/components/TransformComponent.ets`
- Create: `entry/src/main/ets/game/components/InventoryComponent.ets`
- Create: `entry/src/main/ets/game/components/XpComponent.ets`
- Create: `entry/src/main/ets/game/components/EvolutionComponent.ets`

**Interfaces:**
- Consumes: `Component`, `Serializable` from Engine HAR
- Produces: 6 个玩家组件类，每个实现 `Component` + `Serializable`
- Consumed by: PlayerFactory (Task 5), 所有读写玩家状态的系统 (Task 7-15)

字段来源：`GameConstants.ets` 中的 `PlayerState` 接口。每个组件负责 PlayerState 的一个子集。

- [ ] **Step 1: Create MovementComponent**

创建 `entry/src/main/ets/game/components/MovementComponent.ets`：

```typescript
import { Component, Serializable } from '@qiuyu/engine';

export class MovementComponent implements Component, Serializable {
  facing: number = 1;
  isJumping: boolean = false;
  jumpTimer: number = 0;
  jumpHeight: number = 0;
  isDashing: boolean = false;
  dashTimer: number = 0;
  dashCooldown: number = 0;
  dashDirX: number = 0;
  dashDirY: number = 0;
  isDrilling: boolean = false;
  drillTargetX: number = 0;
  drillTargetY: number = 0;
  drillHitCount: number = 0;
  isUsingTool: boolean = false;
  toolCooldown: number = 0;
  isEngulfed: boolean = false;
  engulfEscapeCount: number = 0;
  engulfDamageTimer: number = 0;

  getType(): string { return "movement"; }

  serialize(): Record<string, Object> {
    return {
      facing: this.facing, isJumping: this.isJumping,
      jumpTimer: this.jumpTimer, jumpHeight: this.jumpHeight,
      isDashing: this.isDashing, dashTimer: this.dashTimer,
      dashCooldown: this.dashCooldown
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.facing = data["facing"] as number;
    this.isJumping = data["isJumping"] as boolean;
    this.jumpTimer = data["jumpTimer"] as number;
    this.jumpHeight = data["jumpHeight"] as number;
    this.isDashing = data["isDashing"] as boolean;
    this.dashTimer = data["dashTimer"] as number;
    this.dashCooldown = data["dashCooldown"] as number;
  }
}
```

- [ ] **Step 2: Create CombatComponent**

创建 `entry/src/main/ets/game/components/CombatComponent.ets`：

```typescript
import { Component, Serializable } from '@qiuyu/engine';

export class CombatComponent implements Component, Serializable {
  isAttacking: boolean = false;
  attackTimer: number = 0;
  invincibleTimer: number = 0;
  animFrame: number = 0;

  getType(): string { return "combat"; }

  serialize(): Record<string, Object> {
    return {
      attackTimer: this.attackTimer,
      invincibleTimer: this.invincibleTimer
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.attackTimer = data["attackTimer"] as number;
    this.invincibleTimer = data["invincibleTimer"] as number;
  }
}
```

- [ ] **Step 3: Create TransformComponent**

创建 `entry/src/main/ets/game/components/TransformComponent.ets`：

```typescript
import { Component, Serializable } from '@qiuyu/engine';

export class TransformComponent implements Component, Serializable {
  isTransformed: boolean = false;
  transformForm: number = -1;
  savedWeaponForm: number = 0;
  currentWeaponForm: number = 0;
  transformEnergy: number = 0;
  transformMaxEnergy: number = 100;
  transformCooldown: number = 0;
  transformAnimTimer: number = 0;
  transformFormAttackCooldown: number = 0;

  getType(): string { return "transform"; }

  serialize(): Record<string, Object> {
    return {
      isTransformed: this.isTransformed,
      transformForm: this.transformForm,
      savedWeaponForm: this.savedWeaponForm,
      currentWeaponForm: this.currentWeaponForm,
      transformEnergy: this.transformEnergy,
      transformMaxEnergy: this.transformMaxEnergy,
      transformCooldown: this.transformCooldown
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.isTransformed = data["isTransformed"] as boolean;
    this.transformForm = data["transformForm"] as number;
    this.savedWeaponForm = data["savedWeaponForm"] as number;
    this.currentWeaponForm = data["currentWeaponForm"] as number;
    this.transformEnergy = data["transformEnergy"] as number;
    this.transformMaxEnergy = data["transformMaxEnergy"] as number;
    this.transformCooldown = data["transformCooldown"] as number;
  }
}
```

- [ ] **Step 4: Create InventoryComponent**

创建 `entry/src/main/ets/game/components/InventoryComponent.ets`：

```typescript
import { Component, Serializable } from '@qiuyu/engine';

export class InventoryComponent implements Component, Serializable {
  crystalOre: number = 0;
  mushroomOre: number = 0;
  flameOre: number = 0;
  abyssOre: number = 0;
  voidOre: number = 0;
  coreNormal: number = 0;
  coreRare: number = 0;
  formCore: number = 0;
  hpPotions: number = 0;
  gold: number = 0;
  transformCoreSlime: number = 0;
  transformCoreArmor: number = 0;
  transformCoreIronMan: number = 0;
  transformCoreGhost: number = 0;

  getType(): string { return "inventory"; }

  serialize(): Record<string, Object> {
    return {
      crystalOre: this.crystalOre, mushroomOre: this.mushroomOre,
      flameOre: this.flameOre, abyssOre: this.abyssOre,
      voidOre: this.voidOre, coreNormal: this.coreNormal,
      coreRare: this.coreRare, formCore: this.formCore,
      hpPotions: this.hpPotions, gold: this.gold,
      transformCoreSlime: this.transformCoreSlime,
      transformCoreArmor: this.transformCoreArmor,
      transformCoreIronMan: this.transformCoreIronMan,
      transformCoreGhost: this.transformCoreGhost
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.crystalOre = data["crystalOre"] as number;
    this.mushroomOre = data["mushroomOre"] as number;
    this.flameOre = data["flameOre"] as number;
    this.abyssOre = data["abyssOre"] as number;
    this.voidOre = data["voidOre"] as number;
    this.coreNormal = data["coreNormal"] as number;
    this.coreRare = data["coreRare"] as number;
    this.formCore = data["formCore"] as number;
    this.hpPotions = data["hpPotions"] as number;
    this.gold = data["gold"] as number;
    this.transformCoreSlime = data["transformCoreSlime"] as number;
    this.transformCoreArmor = data["transformCoreArmor"] as number;
    this.transformCoreIronMan = data["transformCoreIronMan"] as number;
    this.transformCoreGhost = data["transformCoreGhost"] as number;
  }
}
```

- [ ] **Step 5: Create XpComponent**

创建 `entry/src/main/ets/game/components/XpComponent.ets`：

```typescript
import { Component, Serializable } from '@qiuyu/engine';

export class XpComponent implements Component, Serializable {
  xp: number = 0;
  level: number = 1;

  getType(): string { return "xp"; }

  serialize(): Record<string, Object> {
    return { xp: this.xp, level: this.level };
  }

  deserialize(data: Record<string, Object>): void {
    this.xp = data["xp"] as number;
    this.level = data["level"] as number;
  }
}
```

- [ ] **Step 6: Create EvolutionComponent**

创建 `entry/src/main/ets/game/components/EvolutionComponent.ets`：

```typescript
import { Component, Serializable } from '@qiuyu/engine';

export class EvolutionComponent implements Component, Serializable {
  evolutionLevel: number = 0;
  unlockedForms: number[] = [0];
  evolutionBranch: number = 0;

  getType(): string { return "evolution"; }

  serialize(): Record<string, Object> {
    return {
      evolutionLevel: this.evolutionLevel,
      unlockedForms: this.unlockedForms as Object[],
      evolutionBranch: this.evolutionBranch
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.evolutionLevel = data["evolutionLevel"] as number;
    this.unlockedForms = data["unlockedForms"] as number[];
    this.evolutionBranch = data["evolutionBranch"] as number;
  }
}
```

- [ ] **Step 7: Build verification**

Run: `hvigorw assembleHap --no-daemon`
Expected: BUILD SUCCESSFUL

- [ ] **Step 8: Commit**

```bash
git add entry/src/main/ets/game/components/MovementComponent.ets \
       entry/src/main/ets/game/components/CombatComponent.ets \
       entry/src/main/ets/game/components/TransformComponent.ets \
       entry/src/main/ets/game/components/InventoryComponent.ets \
       entry/src/main/ets/game/components/XpComponent.ets \
       entry/src/main/ets/game/components/EvolutionComponent.ets
git commit -m "feat: add 6 player ECS components"
```

---

### Task 3: Game Components — Enemy, Pickup, World, Global

**Files:**
- Create: `entry/src/main/ets/game/components/EnemyAIComponent.ets`
- Create: `entry/src/main/ets/game/components/BossAIComponent.ets`
- Create: `entry/src/main/ets/game/components/XpPickupComponent.ets`
- Create: `entry/src/main/ets/game/components/MaterialPickupComponent.ets`
- Create: `entry/src/main/ets/game/components/TransformCorePickupComponent.ets`
- Create: `entry/src/main/ets/game/components/TrapComponent.ets`
- Create: `entry/src/main/ets/game/components/MechanismComponent.ets`
- Create: `entry/src/main/ets/game/components/ChestComponent.ets`
- Create: `entry/src/main/ets/game/components/ParticleComponent.ets`
- Create: `entry/src/main/ets/game/components/CameraComponent.ets`
- Create: `entry/src/main/ets/game/components/GameStateComponent.ets`

**Interfaces:**
- Consumes: `Component`, `Serializable` from Engine HAR
- Produces: 11 个组件类
- Consumed by: Factories (Task 4-5), Systems (Task 7-15), Renderers (Task 12-14)

字段来源：`GameConstants.ets` 中的 `SlimeState`、`BossState`、`XpOrb`、`MaterialDrop`、`TransformCoreDrop`、`TrapInstance`、`MechanismInstance`、`ChestState`、`Particle`、`SaveData`。

- [ ] **Step 1: Create EnemyAIComponent**

```typescript
import { Component } from '@qiuyu/engine';

export class EnemyAIComponent implements Component {
  enemyType: number = 0;
  bouncePhase: number = 0;
  hitFlash: number = 0;
  moveTimer: number = 0;
  targetX: number = 0;
  targetY: number = 0;
  isCharging: boolean = false;
  chargeTimer: number = 0;
  isEngulfing: boolean = false;
  engulfedPlayer: boolean = false;
  splitCount: number = 0;
  size: number = 12;
  chargeDirX: number = 0;
  chargeDirY: number = 0;

  getType(): string { return "enemyAI"; }
}
```

- [ ] **Step 2: Create BossAIComponent**

```typescript
import { Component } from '@qiuyu/engine';

export class BossAIComponent implements Component {
  bossType: number = 0;
  bossRole: number = 0;
  phase: number = 0;
  attackTimer: number = 0;
  specialTimer: number = 0;
  defeated: boolean = false;
  active: boolean = true;
  aggroRadius: number = 9999;
  extraData: number[] = [];

  getType(): string { return "bossAI"; }
}
```

- [ ] **Step 3: Create pickup components (3 files)**

XpPickupComponent:
```typescript
import { Component } from '@qiuyu/engine';

export class XpPickupComponent implements Component {
  xpValue: number = 1;
  magnetPhase: number = 0;

  getType(): string { return "xpPickup"; }
}
```

MaterialPickupComponent:
```typescript
import { Component } from '@qiuyu/engine';

export class MaterialPickupComponent implements Component {
  materialType: number = 0;
  amount: number = 1;
  bobPhase: number = 0;

  getType(): string { return "materialPickup"; }
}
```

TransformCorePickupComponent:
```typescript
import { Component } from '@qiuyu/engine';

export class TransformCorePickupComponent implements Component {
  form: number = 0;
  rarity: number = 0;

  getType(): string { return "transformCorePickup"; }
}
```

- [ ] **Step 4: Create TrapComponent**

```typescript
import { Component } from '@qiuyu/engine';

export class TrapComponent implements Component {
  trapType: number = 0;
  state: number = 0;
  timer: number = 0;
  triggerRadius: number = 48;
  damage: number = 1;
  size: number = 16;
  extraData: number[] = [];

  getType(): string { return "trap"; }
}
```

- [ ] **Step 5: Create MechanismComponent**

```typescript
import { Component } from '@qiuyu/engine';

export class MechanismComponent implements Component {
  mechanismType: number = 0;
  active: boolean = false;
  linkedIndex: number = -1;
  rotation: number = 0;
  pushable: boolean = false;
  posX: number = 0;
  posY: number = 0;

  getType(): string { return "mechanism"; }
}
```

- [ ] **Step 6: Create ChestComponent**

```typescript
import { Component } from '@qiuyu/engine';

export class ChestComponent implements Component {
  chestType: number = 0;
  opened: boolean = false;
  openAnim: number = 0;
  lootText: string = "";
  lootTimer: number = 0;

  getType(): string { return "chest"; }
}
```

- [ ] **Step 7: Create ParticleComponent**

```typescript
import { Component } from '@qiuyu/engine';

export class ParticleComponent implements Component {
  life: number = 1000;
  maxLife: number = 1000;
  color: string = '#ffffff';
  size: number = 2;
  vx: number = 0;
  vy: number = 0;
  gravity: number = 0;
  fadeRate: number = 1;
  shape: number = 0;

  getType(): string { return "particle"; }
}
```

- [ ] **Step 8: Create CameraComponent**

```typescript
import { Component } from '@qiuyu/engine';

export class CameraComponent implements Component {
  shakeX: number = 0;
  shakeY: number = 0;
  shakeTimer: number = 0;

  getType(): string { return "camera"; }
}
```

- [ ] **Step 9: Create GameStateComponent**

```typescript
import { Component } from '@qiuyu/engine';

export class GameStateComponent implements Component {
  state: number = 1;
  damageFlashTimer: number = 0;
  bossRoomLocked: boolean = false;

  getType(): string { return "gameState"; }
}
```

- [ ] **Step 10: Build verification**

Run: `hvigorw assembleHap --no-daemon`
Expected: BUILD SUCCESSFUL

- [ ] **Step 11: Commit**

```bash
git add entry/src/main/ets/game/components/
git commit -m "feat: add 11 game ECS components (enemy, pickup, world, global)"
```

---

### Task 4: Entity Factories

**Files:**
- Create: `entry/src/main/ets/game/factories/PlayerFactory.ets`
- Create: `entry/src/main/ets/game/factories/EnemyFactory.ets`
- Create: `entry/src/main/ets/game/factories/BossFactory.ets`
- Create: `entry/src/main/ets/game/factories/DropFactory.ets`
- Create: `entry/src/main/ets/game/factories/WorldEntityFactory.ets`

**Interfaces:**
- Consumes: All 17 game components (Task 2-3), Engine base components
- Produces: 5 个工厂类，每个有 static create 方法
- Consumed by: GameScene (Task 16), ChunkLoadSystem (Task 8), BossSystem (Task 9), CombatSystem (Task 9)

- [ ] **Step 1: Create PlayerFactory**

```typescript
import { Entity, PositionComponent, VelocityComponent, HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { XpComponent } from '../components/XpComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { PLAYER_MAX_HP } from '../GameConstants';

export class PlayerFactory {
  static create(startX: number, startY: number): Entity {
    const entity: Entity = new Entity("player");
    entity.addComponent(new PositionComponent(startX, startY));
    entity.addComponent(new VelocityComponent(0, 0));
    entity.addComponent(new HealthComponent(PLAYER_MAX_HP, PLAYER_MAX_HP));
    entity.addComponent(new MovementComponent());
    entity.addComponent(new CombatComponent());
    entity.addComponent(new TransformComponent());
    entity.addComponent(new InventoryComponent());
    entity.addComponent(new XpComponent());
    entity.addComponent(new EvolutionComponent());
    entity.addComponent(new ColliderComponent(20, 20, 0, 0));
    return entity;
  }
}
```

注意：PositionComponent 需要支持构造函数参数。检查 Engine HAR 的 PositionComponent——如果没有构造函数参数，需要添加 `constructor(x: number = 0, y: number = 0)` 并设置 `this.x = x; this.y = y;`。同样为 VelocityComponent 和 HealthComponent 添加带参构造函数。

- [ ] **Step 2: Add constructor parameters to base Engine components**

修改 `Engine/src/main/ets/Component.ets`：

PositionComponent — 添加构造函数：
```typescript
export class PositionComponent implements Component {
  x: number = 0;
  y: number = 0;

  constructor(x: number = 0, y: number = 0) {
    this.x = x;
    this.y = y;
  }

  getType(): string { return 'Position'; }
}
```

VelocityComponent — 添加构造函数：
```typescript
export class VelocityComponent implements Component {
  vx: number = 0;
  vy: number = 0;

  constructor(vx: number = 0, vy: number = 0) {
    this.vx = vx;
    this.vy = vy;
  }

  getType(): string { return 'Velocity'; }
}
```

HealthComponent — 添加构造函数：
```typescript
export class HealthComponent implements Component {
  current: number = 100;
  max: number = 100;

  constructor(current: number = 100, max: number = 100) {
    this.current = current;
    this.max = max;
  }

  getType(): string { return 'Health'; }
  // ... isDead, damage, heal unchanged
}
```

ColliderComponent — 添加构造函数：
```typescript
export class ColliderComponent implements Component {
  width: number = 16;
  height: number = 16;
  offsetX: number = 0;
  offsetY: number = 0;
  isSolid: boolean = true;

  constructor(width: number = 16, height: number = 16, offsetX: number = 0,
              offsetY: number = 0, isSolid: boolean = true) {
    this.width = width;
    this.height = height;
    this.offsetX = offsetX;
    this.offsetY = offsetY;
    this.isSolid = isSolid;
  }

  getType(): string { return 'Collider'; }
}
```

- [ ] **Step 3: Create EnemyFactory**

```typescript
import { Entity, PositionComponent, VelocityComponent, HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { EnemyType, SLIME_SIZE, SLIME_HP } from '../GameConstants';

export class EnemyFactory {
  static createSlime(x: number, y: number, enemyType: number): Entity {
    const entity: Entity = new Entity("enemy");
    entity.addComponent(new PositionComponent(x, y));
    entity.addComponent(new VelocityComponent(0, 0));

    const hp: number = EnemyFactory.getHpForType(enemyType);
    entity.addComponent(new HealthComponent(hp, hp));

    const ai: EnemyAIComponent = new EnemyAIComponent();
    ai.enemyType = enemyType;
    ai.size = EnemyFactory.getSizeForType(enemyType);
    entity.addComponent(ai);

    const size: number = ai.size;
    entity.addComponent(new ColliderComponent(size, size, 0, 0, false));
    return entity;
  }

  private static getHpForType(enemyType: number): number {
    // 根据 EnemyType 返回不同 HP，参考现有 SlimeState 初始化逻辑
    switch (enemyType) {
      case EnemyType.CRYSTAL: return SLIME_HP;
      case EnemyType.MUSHROOM: return SLIME_HP + 1;
      case EnemyType.FLAME: return SLIME_HP;
      case EnemyType.ABYSS: return SLIME_HP + 2;
      case EnemyType.VOID: return SLIME_HP + 1;
      case EnemyType.TOXIC: return SLIME_HP;
      default: return SLIME_HP;
    }
  }

  private static getSizeForType(enemyType: number): number {
    return SLIME_SIZE;
  }
}
```

- [ ] **Step 4: Create BossFactory**

```typescript
import { Entity, PositionComponent, VelocityComponent, HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { BossAIComponent } from '../components/BossAIComponent';
import { BOSS_HP, BOSS_SIZE } from '../GameConstants';

export class BossFactory {
  static create(x: number, y: number, bossType: number, bossRole: number): Entity {
    const entity: Entity = new Entity("boss");
    entity.addComponent(new PositionComponent(x, y));
    entity.addComponent(new VelocityComponent(0, 0));
    entity.addComponent(new HealthComponent(BOSS_HP, BOSS_HP));

    const ai: BossAIComponent = new BossAIComponent();
    ai.bossType = bossType;
    ai.bossRole = bossRole;
    entity.addComponent(ai);

    entity.addComponent(new ColliderComponent(BOSS_SIZE, BOSS_SIZE, 0, 0, false));
    return entity;
  }
}
```

- [ ] **Step 5: Create DropFactory**

```typescript
import { Entity, PositionComponent } from '@qiuyu/engine';
import { XpPickupComponent } from '../components/XpPickupComponent';
import { MaterialPickupComponent } from '../components/MaterialPickupComponent';
import { TransformCorePickupComponent } from '../components/TransformCorePickupComponent';

export class DropFactory {
  static createXpOrb(x: number, y: number, value: number): Entity {
    const entity: Entity = new Entity("xpOrb");
    entity.addComponent(new PositionComponent(x, y));
    const pickup: XpPickupComponent = new XpPickupComponent();
    pickup.xpValue = value;
    entity.addComponent(pickup);
    return entity;
  }

  static createMaterialDrop(x: number, y: number, materialType: number, amount: number): Entity {
    const entity: Entity = new Entity("materialDrop");
    entity.addComponent(new PositionComponent(x, y));
    const pickup: MaterialPickupComponent = new MaterialPickupComponent();
    pickup.materialType = materialType;
    pickup.amount = amount;
    pickup.bobPhase = Math.random() * Math.PI * 2;
    entity.addComponent(pickup);
    return entity;
  }

  static createTransformCore(x: number, y: number, form: number, rarity: number): Entity {
    const entity: Entity = new Entity("transformCore");
    entity.addComponent(new PositionComponent(x, y));
    const pickup: TransformCorePickupComponent = new TransformCorePickupComponent();
    pickup.form = form;
    pickup.rarity = rarity;
    entity.addComponent(pickup);
    return entity;
  }
}
```

- [ ] **Step 6: Create WorldEntityFactory**

```typescript
import { Entity, PositionComponent, ColliderComponent } from '@qiuyu/engine';
import { TrapComponent } from '../components/TrapComponent';
import { MechanismComponent } from '../components/MechanismComponent';
import { ChestComponent } from '../components/ChestComponent';

export class WorldEntityFactory {
  static createTrap(x: number, y: number, trapType: number): Entity {
    const entity: Entity = new Entity("trap");
    entity.addComponent(new PositionComponent(x, y));
    const trap: TrapComponent = new TrapComponent();
    trap.trapType = trapType;
    entity.addComponent(trap);
    entity.addComponent(new ColliderComponent(16, 16, 0, 0, false));
    return entity;
  }

  static createMechanism(x: number, y: number, mechanismType: number): Entity {
    const entity: Entity = new Entity("mechanism");
    entity.addComponent(new PositionComponent(x, y));
    const mech: MechanismComponent = new MechanismComponent();
    mech.mechanismType = mechanismType;
    mech.posX = x;
    mech.posY = y;
    entity.addComponent(mech);
    entity.addComponent(new ColliderComponent(16, 16, 0, 0, true));
    return entity;
  }

  static createChest(x: number, y: number, chestType: number): Entity {
    const entity: Entity = new Entity("chest");
    entity.addComponent(new PositionComponent(x, y));
    const chest: ChestComponent = new ChestComponent();
    chest.chestType = chestType;
    entity.addComponent(chest);
    entity.addComponent(new ColliderComponent(16, 16, 0, 0, true));
    return entity;
  }
}
```

- [ ] **Step 7: Build verification**

Run: `hvigorw assembleHap --no-daemon`
Expected: BUILD SUCCESSFUL

- [ ] **Step 8: Commit**

```bash
git add entry/src/main/ets/game/factories/ Engine/src/main/ets/Component.ets
git commit -m "feat: add 5 entity factories and component constructors"
```

---

### Task 5: New Engine Systems (SpatialRebuild + Cleanup)

**Files:**
- Create: `entry/src/main/ets/game/systems/SpatialRebuildSystem.ets`
- Create: `entry/src/main/ets/game/systems/CleanupSystem.ets`

**Interfaces:**
- Consumes: `System`, `SystemContext`, `Entity`, `PositionComponent` from Engine HAR
- Produces: 2 个新系统
- Consumed by: GameScene (Task 16) 注册到 World

- [ ] **Step 1: Create SpatialRebuildSystem**

每帧第一执行，重建空间索引。

```typescript
import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';

export class SpatialRebuildSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const grid = context.world.getSpatialGrid();
    grid.clear();
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (e.active && e.hasComponent("Position")) {
        const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
        grid.insert(pos.x, pos.y, e);
      }
    }
  }
}
```

- [ ] **Step 2: Create CleanupSystem**

帧末清理 active=false 的实体。注意：World.update() 已经在系统执行后 filter，此系统作为显式的最后一步确保清理。实际上 World.update() 中的 filter 已经足够，CleanupSystem 是可选的安全网。

```typescript
import { System, SystemContext, Entity } from '@qiuyu/engine';

export class CleanupSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    // World.update() 在系统循环后已执行 filter
    // 此系统作为显式清理步骤，处理需要额外清理逻辑的情况
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active) {
        // 移除所有组件引用，帮助 GC
        const components = e.getAllComponents();
        for (let j: number = 0; j < components.length; j++) {
          e.removeComponent(components[j].getType());
        }
      }
    }
  }
}
```

- [ ] **Step 3: Build and commit**

```bash
git add entry/src/main/ets/game/systems/SpatialRebuildSystem.ets \
       entry/src/main/ets/game/systems/CleanupSystem.ets
git commit -m "feat: add SpatialRebuildSystem and CleanupSystem"
```

---

### Task 6: Camera + Particle Systems

**Files:**
- Create: `entry/src/main/ets/game/systems/CameraSystem.ets`
- Create: `entry/src/main/ets/game/systems/ParticleSystem.ets`
- Create: `entry/src/main/ets/game/systems/AmbientParticleSystem.ets`

**Interfaces:**
- Consumes: Engine HAR types, CameraComponent, ParticleComponent, GameSettings
- Produces: 3 个新系统
- Consumed by: GameScene (Task 16)

- [ ] **Step 1: Create CameraSystem**

从 GameEngine 的 `updateCamera()` 和 `updateShake()` 提取。读取 player.Position，更新 CameraComponent 和 World.cameraX/Y。

```typescript
import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { CameraComponent } from '../components/CameraComponent';
import { GameSettings } from '../GameConstants';

export class CameraSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    const cameraEntity: Entity | null = context.world.findEntityByTag("camera");
    if (!player || !cameraEntity) return;

    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const cam: CameraComponent = cameraEntity.getComponent<CameraComponent>("camera")!;

    // 相机跟随（平滑插值）
    const targetX: number = pos.x - context.screenW / 2;
    const targetY: number = pos.y - context.screenH / 2;
    context.world.cameraX += (targetX - context.world.cameraX) * 0.1;
    context.world.cameraY += (targetY - context.world.cameraY) * 0.1;

    // 震动衰减
    if (cam.shakeTimer > 0) {
      cam.shakeTimer -= context.dt;
      const intensity: number = Math.min(1, cam.shakeTimer / 200);
      cam.shakeX = (Math.random() * 2 - 1) * 4 * intensity;
      cam.shakeY = (Math.random() * 2 - 1) * 4 * intensity;
      if (cam.shakeTimer <= 0) {
        cam.shakeX = 0;
        cam.shakeY = 0;
      }
    }

    // 同步到 SystemContext 供后续系统使用
    context.cameraX = context.world.cameraX + cam.shakeX;
    context.cameraY = context.world.cameraY + cam.shakeY;
  }
}
```

注意：实际跟随逻辑参考现有 `GameEngine.ets` 中的相机代码。上面的 0.1 插值系数是示例值——从现有代码中取实际值。

- [ ] **Step 2: Create ParticleSystem**

从 GameContext.updateParticles() 提取。遍历所有带 ParticleComponent 的实体，更新位置和生命值。

```typescript
import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { ParticleComponent } from '../components/ParticleComponent';

export class ParticleSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const dt: number = context.dt;
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || !e.hasComponent("particle")) continue;

      const p: ParticleComponent = e.getComponent<ParticleComponent>("particle")!;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;

      p.life -= dt;
      if (p.life <= 0) {
        e.active = false;
        continue;
      }

      pos.x += p.vx * dt / 16;
      pos.y += p.vy * dt / 16;
      p.vy += p.gravity * dt / 16;
    }
  }
}
```

- [ ] **Step 3: Create AmbientParticleSystem**

从 GameEngine.updateAmbientParticles() 提取。管理环境粒子（非实体，保留内部数组）。

```typescript
import { System, SystemContext, Entity } from '@qiuyu/engine';
import { AmbientParticle, BiomeType } from '../GameConstants';

export class AmbientParticleSystem extends System {
  private particles: AmbientParticle[] = [];
  private maxParticles: number = 30;

  update(entities: Entity[], context: SystemContext): void {
    // 参考现有 GameEngine.updateAmbientParticles() 逻辑
    // 根据相机位置和当前生物群系生成环境粒子
    // 更新粒子位置，移除超出生命周期的粒子
    // 此系统不使用实体，直接管理内部粒子数组
    const dt: number = context.dt;
    // ... 迁移现有环境粒子更新逻辑
  }
}
```

实现细节：从 `GameEngine.ets` 的 `updateAmbientParticles()` 方法复制核心逻辑。该方法管理 `ambientParticles: AmbientParticle[]` 数组，根据 `cameraX/cameraY` 和生物群系类型生成粒子。将此逻辑搬到本系统的 `update()` 中，用 `context.world.cameraX/Y` 替代 `c.cameraX/Y`。

- [ ] **Step 4: Build and commit**

```bash
git add entry/src/main/ets/game/systems/CameraSystem.ets \
       entry/src/main/ets/game/systems/ParticleSystem.ets \
       entry/src/main/ets/game/systems/AmbientParticleSystem.ets
git commit -m "feat: add CameraSystem, ParticleSystem, AmbientParticleSystem"
```

---

### Task 7: Core Gameplay Systems (Movement + Combat + EnemyAI)

**Files:**
- Rewrite: `entry/src/main/ets/game/systems/PlayerMovementSystem.ets` (326 lines)
- Rewrite: `entry/src/main/ets/game/systems/PlayerCombatSystem.ets` (122 lines)
- Rewrite: `entry/src/main/ets/game/systems/EnemyAISystem.ets` (192 lines)

**Interfaces:**
- Consumes: Engine HAR types, 玩家组件 (Movement, Combat, Transform, Inventory, Xp, Evolution), EnemyAIComponent, GameConstants
- Produces: 3 个重写系统
- Consumed by: GameScene (Task 16)

**迁移模式：** 每个系统从 `class XxxSystem` 改为 `class XxxSystem extends System`。`update(c: GameContext)` 改为 `update(entities: Entity[], context: SystemContext)`。所有 `c.player.xxx` 改为从 player 实体读取组件。所有 `c.enemies[i].xxx` 改为从 enemy 实体读取组件。

- [ ] **Step 1: Rewrite PlayerMovementSystem**

核心变化：
- 继承 `System` 而非独立类
- `c: GameContext` → `entities: Entity[], context: SystemContext`
- `c.player` → `context.world.findEntityByTag("player")` + 读取组件
- `c.player.x/y` → `pos.x/y`（PositionComponent）
- `c.player.vx/vy` → `vel.vx/vy`（VelocityComponent）
- `c.player.facing/isJumping/...` → `movement.facing/isJumping/...`（MovementComponent）
- `c.player.isAttacking/attackTimer/...` → `combat.isAttacking/...`（CombatComponent）
- `c.player.isTransformed/transformForm/...` → `transform.isTransformed/...`（TransformComponent）
- `c.player.isInvincible/invincibleTimer` → `combat.invincibleTimer`
- `bridge.performAttack()` → 设 `combat.isAttacking = true`（由 PlayerCombatSystem 处理）
- `c.isWalkable(x, y)` → 从 `context.world.chunks` 读取 tile 数据判断
- `c.screenW/screenH` → `context.screenW/screenH`
- `c.input` → `context.input`

```typescript
import { System, SystemContext, Entity, PositionComponent, VelocityComponent,
         HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { GameSettings, PLAYER_SPEED, DASH_SPEED, DASH_DURATION, DASH_COOLDOWN,
         TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE, DRILL_BREAK_HITS } from '../GameConstants';

export class PlayerMovementSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;

    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const vel: VelocityComponent = player.getComponent<VelocityComponent>("Velocity")!;
    const movement: MovementComponent = player.getComponent<MovementComponent>("movement")!;
    const combat: CombatComponent = player.getComponent<CombatComponent>("combat")!;
    const transform: TransformComponent = player.getComponent<TransformComponent>("transform")!;
    const input = context.input;
    const dt: number = context.dt;
    const settings: GameSettings = context.settings as GameSettings;
    const chunks: Map<string, Object> = context.world.chunks;

    // 迁移现有 PlayerMovementSystem 的全部逻辑：
    // 1. 处理摇杆输入 → 设置 vel.vx/vy
    // 2. 处理跳跃（movement.isJumping, jumpTimer, jumpHeight）
    // 3. 处理冲刺（movement.isDashing, dashTimer, dashCooldown, dashDirX/Y）
    // 4. 处理钻地（movement.isDrilling, drillTargetX/Y, drillHitCount）
    // 5. 处理被吞噬（movement.isEngulfed, engulfEscapeCount, engulfDamageTimer）
    // 6. 碰撞检测 → 从 chunks 读取 tiles 判断 isWalkable
    // 7. 更新 pos.x/y
    // 8. 攻击触发 → combat.isAttacking = true（不再调 bridge.performAttack()）
    // 9. 工具使用（movement.isUsingTool, toolCooldown）
  }
}
```

**实现指令：** 打开现有 `entry/src/main/ets/game/systems/PlayerMovementSystem.ets`，逐方法迁移。保留所有游戏逻辑（移动计算、碰撞检测、跳跃物理、冲刺逻辑、钻地逻辑、被吞噬处理），只改变数据访问方式。每个 `c.player.FIELD` 替换为对应组件字段。每个 `c.isWalkable(x, y)` 替换为从 chunks 读取 tile 的本地方法。每个 `bridge.performAttack()` 替换为 `combat.isAttacking = true`。

- [ ] **Step 2: Rewrite PlayerCombatSystem**

核心变化：
- `c.enemies` → 空间查询获取附近敌人实体
- `c.player.attackTimer` → `combat.attackTimer`
- `bridge.onEnemyDeath(enemy)` → 直接标记 enemy.active = false + 创建掉落物
- 攻击范围检测 → 从 SpatialGrid 查询

```typescript
import { System, SystemContext, Entity, PositionComponent, HealthComponent,
         ColliderComponent } from '@qiuyu/engine';
import { CombatComponent } from '../components/CombatComponent';
import { MovementComponent } from '../components/MovementComponent';
import { TransformComponent } from '../components/TransformComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { DropFactory } from '../factories/DropFactory';
import { ATTACK_DURATION, ATTACK_RANGE, ATTACK_WIDTH, ATTACK_COOLDOWN,
         SLIME_DAMAGE, SLIME_KNOCKBACK } from '../GameConstants';

export class PlayerCombatSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;

    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const combat: CombatComponent = player.getComponent<CombatComponent>("combat")!;
    const movement: MovementComponent = player.getComponent<MovementComponent>("movement")!;
    const transform: TransformComponent = player.getComponent<TransformComponent>("transform")!;
    const dt: number = context.dt;

    // 迁移现有 PlayerCombatSystem 逻辑：
    // 1. 更新 attackTimer（递减）
    // 2. 如果 combat.isAttacking 且 attackTimer <= 0，执行攻击
    // 3. 攻击范围检测：用 SpatialGrid.queryRect 获取范围内敌人
    // 4. 对每个敌人：HealthComponent.damage(amount)
    // 5. 击退：设置敌人 VelocityComponent
    // 6. 如果敌人 HealthComponent.isDead()：
    //    - 标记 enemy.active = false
    //    - 创建 XP 掉落实体：DropFactory.createXpOrb()
    //    - 变身能量恢复（如果 transform.isTransformed）
    // 7. 更新 invincibleTimer（递减）
    // 8. 更新 animFrame
  }
}
```

**实现指令：** 从现有 `PlayerCombatSystem.ets` 迁移。`performAttack()` 逻辑保留，但 `c.enemies` 改为空间查询。`c.enemyGrid.queryRect()` 改为 `context.world.getSpatialGrid().queryRect()`。敌人死亡处理直接标记 `enemy.active = false` 并用 `DropFactory` 创建掉落物。

- [ ] **Step 3: Rewrite EnemyAISystem**

核心变化：
- `c.enemies` → `context.world.query("enemyAI")` 或遍历 entities
- `c.player.x/y` → player 实体的 PositionComponent
- `c.player.hp` → player 的 HealthComponent
- 碰撞伤害 → 直接 `playerHealth.damage()`

```typescript
import { System, SystemContext, Entity, PositionComponent, VelocityComponent,
         HealthComponent } from '@qiuyu/engine';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { SLIME_SIZE, SLIME_SPEED, SLIME_DETECT_RANGE, SLIME_DAMAGE,
         SLIME_KNOCKBACK, ENGULF_DETECT_RANGE, ENGULF_ESCAPE_HITS } from '../GameConstants';

export class EnemyAISystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;

    const playerPos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const playerHealth: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const playerMovement: MovementComponent = player.getComponent<MovementComponent>("movement")!;
    const playerCombat: CombatComponent = player.getComponent<CombatComponent>("combat")!;
    const dt: number = context.dt;

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "enemy") continue;

      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const vel: VelocityComponent = e.getComponent<VelocityComponent>("Velocity")!;
      const health: HealthComponent = e.getComponent<HealthComponent>("Health")!;
      const ai: EnemyAIComponent = e.getComponent<EnemyAIComponent>("enemyAI")!;

      if (health.isDead()) {
        e.active = false;
        continue;
      }

      // 迁移现有 EnemyAISystem 逻辑：
      // 1. 根据 enemyType 执行不同 AI 行为（6 种敌人类型）
      // 2. 更新 bouncePhase, moveTimer, hitFlash
      // 3. 追踪/冲锋/远程等 AI 逻辑
      // 4. 碰撞检测 → 与 player 距离判断
      // 5. 接触伤害 → playerHealth.damage(SLIME_DAMAGE)
      // 6. 吞噬逻辑 → playerMovement.isEngulfed
      // 7. 击退处理
    }
  }
}
```

**实现指令：** 从现有 `EnemyAISystem.ets` 迁移。保留 6 种敌人类型的 AI 行为逻辑。`c.enemies[i]` 改为遍历 entities 找 tag="enemy"。`c.player` 改为 player 实体组件。碰撞检测保留现有逻辑，只改数据源。

- [ ] **Step 4: Build and commit**

```bash
git add entry/src/main/ets/game/systems/PlayerMovementSystem.ets \
       entry/src/main/ets/game/systems/PlayerCombatSystem.ets \
       entry/src/main/ets/game/systems/EnemyAISystem.ets
git commit -m "feat: rewrite core gameplay systems (Movement, Combat, EnemyAI) for ECS"
```

---

### Task 8: Boss + Transform Systems

**Files:**
- Rewrite: `entry/src/main/ets/game/systems/BossSystem.ets` (207 lines)
- Rewrite: `entry/src/main/ets/game/systems/TransformSystem.ets` (371 lines)

**Interfaces:**
- Consumes: Engine HAR types, BossAIComponent, TransformComponent, 全部玩家组件, GameConstants, DropFactory
- Produces: 2 个重写系统
- Consumed by: GameScene (Task 16)

- [ ] **Step 1: Rewrite BossSystem**

核心变化：
- `c.bosses` → 遍历 entities 找 tag="boss"
- `c.activeBoss` → `context.world.findEntityByTag("boss")`（或遍历 boss 实体）
- `c.player` → player 实体组件
- `bridge.getCoreForBoss()` → 直接在系统内处理 Boss 核心掉落（用 DropFactory）
- `c.bossRoomLocked` → GameStateComponent.bossRoomLocked

```typescript
import { System, SystemContext, Entity, PositionComponent, VelocityComponent,
         HealthComponent } from '@qiuyu/engine';
import { BossAIComponent } from '../components/BossAIComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import { DropFactory } from '../factories/DropFactory';
import { BOSS_HP, BOSS_SIZE, BOSS_ATTACK_INTERVAL, BOSS_PHASE2_THRESHOLD,
         BOSS_ROOM_SIZE, PASSAGE_GUARDIAN_AGGRO, OPTIONAL_CHALLENGE_AGGRO } from '../GameConstants';

export class BossSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    const gameState: Entity | null = context.world.findEntityByTag("gameState");
    if (!player) return;

    const playerPos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const playerHealth: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const dt: number = context.dt;

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "boss") continue;

      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const vel: VelocityComponent = e.getComponent<VelocityComponent>("Velocity")!;
      const health: HealthComponent = e.getComponent<HealthComponent>("Health")!;
      const ai: BossAIComponent = e.getComponent<BossAIComponent>("bossAI")!;

      // 迁移现有 BossSystem 逻辑：
      // 1. Boss AI 行为（根据 bossType 执行不同攻击模式）
      // 2. Phase 切换（HP < threshold → phase 2）
      // 3. 攻击计时器（attackTimer, specialTimer）
      // 4. Boss 投影/冲锋/远程攻击 → playerHealth.damage()
      // 5. 死亡处理：
      //    - ai.defeated = true
      //    - 创建核心掉落：DropFactory.createTransformCore()
      //    - 创建矿石掉落：DropFactory.createMaterialDrop()
      //    - 解锁 GameStateComponent.bossRoomLocked = false
      // 6. hitFlash 衰减
    }
  }
}
```

**实现指令：** 从现有 `BossSystem.ets` 迁移。`c.bosses` 遍历改为 entities 过滤 tag="boss"。`bridge.getCoreForBoss(bossType)` 改为内联逻辑（参考 GameEngine 中的实现）。Boss 死亡掉落直接用 DropFactory 创建实体。

- [ ] **Step 2: Rewrite TransformSystem**

核心变化：
- `c.player` → player 实体组件
- `c.enemies` → entities 过滤
- `bridge.activateTransform()/deactivateTransform()` → 直接操作 TransformComponent
- `bridge.getCoreForBoss()` → 不再需要（BossSystem 直接处理）
- 变身形态的特殊行为（Slime/Ghost/Armor/IronMan）→ 读写组件

```typescript
import { System, SystemContext, Entity, PositionComponent, VelocityComponent,
         HealthComponent, ColliderComponent } from '@qiuyu/engine';
import { TransformComponent } from '../components/TransformComponent';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TRANSFORM_MAX_ENERGY, TRANSFORM_COOLDOWN, TRANSFORM_PASSIVE_REGEN,
         TRANSFORM_ACTIVATE_ANIM, TRANSFORM_REVERT_ANIM, TRANSFORM_DRAIN_RATES,
         TRANSFORM_SPEEDS, TRANSFORM_ATTACK_COSTS, TRANSFORM_ATTACK_COOLDOWNS,
         TRANSFORM_DAMAGE_REDUCTION, TRANSFORM_ENERGY_KILL_SLIME,
         TRANSFORM_ENERGY_KILL_ELITE, TRANSFORM_ENERGY_KILL_BOSS,
         TRANSFORM_ENERGY_XP_ORB, TransformForm } from '../GameConstants';

export class TransformSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;

    const transform: TransformComponent = player.getComponent<TransformComponent>("transform")!;
    const movement: MovementComponent = player.getComponent<MovementComponent>("movement")!;
    const combat: CombatComponent = player.getComponent<CombatComponent>("combat")!;
    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const vel: VelocityComponent = player.getComponent<VelocityComponent>("Velocity")!;
    const health: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const dt: number = context.dt;

    // 迁移现有 TransformSystem 逻辑：
    // 1. 能量被动恢复（TRANSFORM_PASSIVE_REGEN）
    // 2. 变身激活/解除动画（transformAnimTimer）
    // 3. 变身状态下的移动速度修改（TRANSFORM_SPEEDS）
    // 4. 变身状态下的攻击处理（TRANSFORM_ATTACK_COSTS）
    // 5. 各形态特殊行为：
    //    - Slime: 弹跳移动，吞噬能力
    //    - Ghost: 穿墙，隐形
    //    - Armor: 高防御，慢速
    //    - IronMan: 飞行，远程攻击
    // 6. 能量消耗（TRANSFORM_DRAIN_RATES）
    // 7. 能量耗尽自动解除变身
    // 8. 击杀恢复能量（查询最近死亡的敌人）
  }
}
```

**实现指令：** 从现有 `TransformSystem.ets`（371 行）迁移。这是最复杂的系统之一。保留所有形态的特殊行为逻辑。`c.player.xxx` 改为组件字段。`bridge.activate/deactivate` 改为直接操作 TransformComponent。击杀能量恢复改为查询最近帧内 active 变为 false 的敌人实体（或直接在 PlayerCombatSystem 中设置标记）。

- [ ] **Step 3: Build and commit**

```bash
git add entry/src/main/ets/game/systems/BossSystem.ets \
       entry/src/main/ets/game/systems/TransformSystem.ets
git commit -m "feat: rewrite BossSystem and TransformSystem for ECS"
```

---

### Task 9: World Interaction Systems (Trap + Mechanism + Chest + Material)

**Files:**
- Rewrite: `entry/src/main/ets/game/systems/TrapSystem.ets` (84 lines)
- Rewrite: `entry/src/main/ets/game/systems/MechanismSystem.ets` (123 lines)
- Rewrite: `entry/src/main/ets/game/systems/ChestSystem.ets` (110 lines)
- Rewrite: `entry/src/main/ets/game/systems/MaterialDropSystem.ets` (78 lines)

**Interfaces:**
- Consumes: Engine HAR types, TrapComponent, MechanismComponent, ChestComponent, MaterialPickupComponent, InventoryComponent, GameConstants
- Produces: 4 个重写系统
- Consumed by: GameScene (Task 16)

- [ ] **Step 1: Rewrite TrapSystem**

核心变化：
- `c.traps` → 遍历 entities 找 tag="trap"
- `c.player` → player 实体
- 陷阱状态机保留（IDLE→TELEGRAPH→ACTIVE→COOLDOWN）
- 伤害 → `playerHealth.damage()`

```typescript
import { System, SystemContext, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { TrapComponent } from '../components/TrapComponent';
import { TRIGGER_DETECT_RANGE, SPIKE_DAMAGE, ROCK_DAMAGE, POISON_DPS,
         LAVA_GEYSER_DAMAGE, VOID_PULL_DPS, SPIKE_TELEGRAPH_TIME,
         SPIKE_ACTIVE_TIME, SPIKE_COOLDOWN_TIME } from '../GameConstants';

export class TrapSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;
    const playerPos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const playerHealth: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const dt: number = context.dt;

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "trap") continue;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const trap: TrapComponent = e.getComponent<TrapComponent>("trap")!;
      // 迁移现有 TrapSystem 状态机逻辑
    }
  }
}
```

**实现指令：** 从现有 `TrapSystem.ets` 迁移。保留状态机逻辑。`c.traps[i]` → entities 过滤 tag="trap"。`c.player` → player 实体组件。

- [ ] **Step 2: Rewrite MechanismSystem**

核心变化：
- `c.mechanisms` → entities 过滤 tag="mechanism"
- `bridge.checkBreakableWalls()` → 直接操作 `context.world.chunks`
- 机关交互逻辑保留

```typescript
import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { MechanismComponent } from '../components/MechanismComponent';
import { PUSH_BLOCK_SPEED, PRESSURE_PLATE_RANGE, TELEPORT_COOLDOWN,
         LEVER_LINK_RANGE } from '../GameConstants';

export class MechanismSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;
    const playerPos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const dt: number = context.dt;
    const chunks: Map<string, Object> = context.world.chunks;

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "mechanism") continue;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const mech: MechanismComponent = e.getComponent<MechanismComponent>("mechanism")!;
      // 迁移现有 MechanismSystem 逻辑：
      // 压力板、推块、传送符文、拉杆、水晶反射器、可破碎墙壁
    }
  }
}
```

**实现指令：** 从现有 `MechanismSystem.ets` 迁移。`c.mechanisms` → entities 过滤。`bridge.checkBreakableWalls()` → 直接操作 chunks 中的 tile 数据。

- [ ] **Step 3: Rewrite ChestSystem**

核心变化：
- `c.chests` → entities 过滤 tag="chest"
- `bridge.addLoot()` → 直接写 player 的 InventoryComponent
- 开箱动画保留

```typescript
import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { ChestComponent } from '../components/ChestComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { CHEST_INTERACT_RANGE, CHEST_SIZE } from '../GameConstants';

export class ChestSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;
    const playerPos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const inventory: InventoryComponent = player.getComponent<InventoryComponent>("inventory")!;
    const dt: number = context.dt;

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "chest") continue;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const chest: ChestComponent = e.getComponent<ChestComponent>("chest")!;
      // 迁移现有 ChestSystem 逻辑：
      // 1. 更新开箱动画（openAnim）
      // 2. 检测玩家交互（距离 < CHEST_INTERACT_RANGE + input.toolPressed）
      // 3. 开箱 → 根据 chestType 生成战利品 → 写入 inventory
      // 4. 显示战利品文字（lootText, lootTimer）
    }
  }
}
```

**实现指令：** 从现有 `ChestSystem.ets` 迁移。`bridge.addLoot()` 改为直接写 InventoryComponent 字段。

- [ ] **Step 4: Rewrite MaterialDropSystem**

核心变化：
- `c.materialDrops` → entities 过滤 tag="materialDrop"
- `c.transformCoreDrops` → entities 过滤 tag="transformCore"
- `c.player.inventory` → InventoryComponent
- `c.transformUnlockNotifyTimer` → 需要存储在某处（玩家实体或 GameStateComponent）

```typescript
import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { MaterialPickupComponent } from '../components/MaterialPickupComponent';
import { TransformCorePickupComponent } from '../components/TransformCorePickupComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { TransformComponent } from '../components/TransformComponent';

export class MaterialDropSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;
    const playerPos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const inventory: InventoryComponent = player.getComponent<InventoryComponent>("inventory")!;
    const transform: TransformComponent = player.getComponent<TransformComponent>("transform")!;
    const dt: number = context.dt;

    // 材料拾取
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "materialDrop") continue;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const mat: MaterialPickupComponent = e.getComponent<MaterialPickupComponent>("materialPickup")!;
      // 距离检测 → 写入 inventory 对应矿石字段 → e.active = false
    }

    // 变身核心拾取
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "transformCore") continue;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const core: TransformCorePickupComponent = e.getComponent<TransformCorePickupComponent>("transformCorePickup")!;
      // 距离检测 → 写入 inventory.transformCoreXxx → 设置 transform 解锁 → e.active = false
    }
  }
}
```

**实现指令：** 从现有 `MaterialDropSystem.ets` 迁移。`c.materialDrops` 和 `c.transformCoreDrops` 改为 entities 过滤。

- [ ] **Step 5: Build and commit**

```bash
git add entry/src/main/ets/game/systems/TrapSystem.ets \
       entry/src/main/ets/game/systems/MechanismSystem.ets \
       entry/src/main/ets/game/systems/ChestSystem.ets \
       entry/src/main/ets/game/systems/MaterialDropSystem.ets
git commit -m "feat: rewrite world interaction systems (Trap, Mechanism, Chest, Material) for ECS"
```

---

### Task 10: Progression Systems (ChunkLoad + XpLevel + Damage + Evolution)

**Files:**
- Rewrite: `entry/src/main/ets/game/systems/ChunkLoadSystem.ets` (19 lines)
- Rewrite: `entry/src/main/ets/game/systems/XpLevelSystem.ets` (64 lines)
- Rewrite: `entry/src/main/ets/game/systems/DamageSystem.ets` (45 lines)
- Rewrite: `entry/src/main/ets/game/systems/EvolutionSystem.ets` (142 lines)

**Interfaces:**
- Consumes: Engine HAR types, 玩家组件, XpPickupComponent, GameStateComponent, WorldGenerator, GameConstants, DropFactory, EnemyFactory, WorldEntityFactory
- Produces: 4 个重写系统
- Consumed by: GameScene (Task 16)

- [ ] **Step 1: Rewrite ChunkLoadSystem**

核心变化：
- `c.loadChunksAround()` → 直接调用 worldGen.generateChunk() + 创建实体
- `c.worldGen` → `context.world.worldGen as WorldGenerator`
- `c.chunks` → `context.world.chunks`
- 生成的敌人/陷阱/机关/宝箱 → 用 Factory 创建实体

```typescript
import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { EnemyFactory } from '../factories/EnemyFactory';
import { WorldEntityFactory } from '../factories/WorldEntityFactory';
import { CHUNK_SIZE, TILE_SIZE, CHUNK_LOAD_RADIUS } from '../GameConstants';
import { WorldGenerator, ChunkData } from '../WorldGenerator';

export class ChunkLoadSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;
    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const worldGen: WorldGenerator = context.world.worldGen as WorldGenerator;
    const chunks: Map<string, Object> = context.world.chunks;

    // 迁移现有 ChunkLoadSystem 逻辑：
    // 1. 计算玩家所在 chunk 坐标
    // 2. 遍历加载半径内的 chunk
    // 3. 对未生成的 chunk 调用 worldGen.generateChunk()
    // 4. 将 chunk 数据存入 chunks Map
    // 5. 为 chunk 中的敌人/陷阱/机关/宝箱/Boss 创建实体：
    //    - EnemyFactory.createSlime()
    //    - WorldEntityFactory.createTrap()
    //    - WorldEntityFactory.createMechanism()
    //    - WorldEntityFactory.createChest()
    //    - BossFactory.create()
  }
}
```

**实现指令：** 从现有 `ChunkLoadSystem.ets` 迁移。关键是 `c.loadChunksAround()` 中的区块生成和实体创建逻辑。现有代码中 `c.worldGen.generateChunk()` 返回 `ChunkData`，其中包含 enemies/traps/mechanisms/chests/bosses 等数组。将这些数组元素转为实体。

- [ ] **Step 2: Rewrite XpLevelSystem**

核心变化：
- `c.xpOrbs` → entities 过滤 tag="xpOrb"
- `c.player.xp/level` → XpComponent
- 磁铁效果 → 空间查询

```typescript
import { System, SystemContext, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { XpComponent } from '../components/XpComponent';
import { XpPickupComponent } from '../components/XpPickupComponent';
import { XP_MAGNET_RANGE, XP_BASE, XP_GROWTH } from '../GameConstants';

export class XpLevelSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;
    const playerPos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const xp: XpComponent = player.getComponent<XpComponent>("xp")!;
    const health: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const dt: number = context.dt;

    // 迁移现有 XpLevelSystem 逻辑：
    // 1. 遍历 xpOrb 实体
    // 2. 距离检测：小于拾取范围 → 增加 xp.xp → orb.active = false
    // 3. 磁铁效果：小于 XP_MAGNET_RANGE → 吸引 orb 向 player 移动
    // 4. 升级检测：xp.xp >= XP_BASE + XP_GROWTH * xp.level → 升级
    // 5. 升级奖励：health.heal()
  }
}
```

**实现指令：** 从现有 `XpLevelSystem.ets` 迁移。`c.xpOrbs` → entities 过滤 tag="xpOrb"。

- [ ] **Step 3: Rewrite DamageSystem**

核心变化：
- `c.player.hp <= 0` → player HealthComponent.isDead()
- `bridge.setState(GameState.GAME_OVER)` → GameStateComponent.state = GameState.GAME_OVER
- `c.damageFlashTimer` → GameStateComponent.damageFlashTimer

```typescript
import { System, SystemContext, Entity, HealthComponent } from '@qiuyu/engine';
import { GameStateComponent } from '../components/GameStateComponent';
import { GameState } from '../GameConstants';

export class DamageSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    const gameStateEntity: Entity | null = context.world.findEntityByTag("gameState");
    if (!player || !gameStateEntity) return;

    const health: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const gs: GameStateComponent = gameStateEntity.getComponent<GameStateComponent>("gameState")!;
    const dt: number = context.dt;

    // 迁移现有 DamageSystem 逻辑：
    // 1. damageFlashTimer 衰减
    // 2. 检测 player health.isDead() → gs.state = GameState.GAME_OVER
  }
}
```

- [ ] **Step 4: Rewrite EvolutionSystem**

核心变化：
- `c.player.evolutionBranch/Level/inventory` → EvolutionComponent + InventoryComponent
- 进化逻辑保留（5 分支，3 等级，矿石消耗）

```typescript
import { System, SystemContext, Entity } from '@qiuyu/engine';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { EVOLUTION_COST_NORMAL, EVOLUTION_COST_RARE, EVOLUTION_COST_ORE,
         FORM_UNLOCK_COST, EvolutionBranch, EvolutionLevel } from '../GameConstants';

export class EvolutionSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;
    const evo: EvolutionComponent = player.getComponent<EvolutionComponent>("evolution")!;
    const inv: InventoryComponent = player.getComponent<InventoryComponent>("inventory")!;

    // 迁移现有 EvolutionSystem 逻辑：
    // 1. canEvolve() 检查
    // 2. tryEvolveWeapon() — 消耗矿石升级武器
    // 3. unlockWeaponForm() — 解锁新武器形态
    // 4. 进化分支和等级的具体逻辑
  }
}
```

**实现指令：** 从现有 `EvolutionSystem.ets` 迁移。保留所有进化逻辑（5 分支、3 等级、矿石消耗公式）。

- [ ] **Step 5: Build and commit**

```bash
git add entry/src/main/ets/game/systems/ChunkLoadSystem.ets \
       entry/src/main/ets/game/systems/XpLevelSystem.ets \
       entry/src/main/ets/game/systems/DamageSystem.ets \
       entry/src/main/ets/game/systems/EvolutionSystem.ets
git commit -m "feat: rewrite progression systems (ChunkLoad, XpLevel, Damage, Evolution) for ECS"
```

---

### Task 11: SaveLoadSystem

**Files:**
- Rewrite: `entry/src/main/ets/game/systems/SaveLoadSystem.ets` (147 lines)

**Interfaces:**
- Consumes: 所有可序列化组件, World, SaveData, SaveManager
- Produces: 重写后的 SaveLoadSystem
- Consumed by: GameScene (Task 16)

- [ ] **Step 1: Rewrite SaveLoadSystem**

核心变化：
- `c.player` → player 实体组件序列化
- `c.chunks` → 序列化已探索 chunk 坐标列表
- `c.enemies/bosses/etc` → 不需要序列化（加载时从 chunk 数据重建）
- 每个组件的 serialize()/deserialize() 用于存档

```typescript
import { System, SystemContext, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { InventoryComponent } from '../components/InventoryComponent';
import { XpComponent } from '../components/XpComponent';
import { EvolutionComponent } from '../components/EvolutionComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import { SaveData, GameState, AUTO_SAVE_INTERVAL, SAVE_KEY } from '../GameConstants';
import { SaveManager } from '../SaveManager';

export class SaveLoadSystem extends System {
  private saveTimer: number = 0;

  update(entities: Entity[], context: SystemContext): void {
    const dt: number = context.dt;
    this.saveTimer += dt;

    if (this.saveTimer >= AUTO_SAVE_INTERVAL) {
      this.saveTimer = 0;
      this.autoSave(entities, context);
    }
  }

  private autoSave(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (!player) return;

    const data: SaveData = this.getSaveData(player, context);
    // SaveManager.save(context context, data) — 需要 HarmonyOS context
    // 通过 context 中的某种方式获取，或 GameScene 注入
  }

  getSaveData(player: Entity, context: SystemContext): SaveData {
    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const health: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    const movement: MovementComponent = player.getComponent<MovementComponent>("movement")!;
    const combat: CombatComponent = player.getComponent<CombatComponent>("combat")!;
    const transform: TransformComponent = player.getComponent<TransformComponent>("transform")!;
    const inventory: InventoryComponent = player.getComponent<InventoryComponent>("inventory")!;
    const xp: XpComponent = player.getComponent<XpComponent>("xp")!;
    const evo: EvolutionComponent = player.getComponent<EvolutionComponent>("evolution")!;

    // 组装 SaveData（参考现有 SaveLoadSystem.getSaveData()）
    const saveData: SaveData = {
      version: 1,
      timestamp: Date.now(),
      playerX: pos.x,
      playerY: pos.y,
      hp: health.current,
      xp: xp.xp,
      level: xp.level,
      gender: 0,
      currentWeaponForm: transform.currentWeaponForm,
      unlockedForms: evo.unlockedForms,
      evolutionBranch: evo.evolutionBranch,
      evolutionLevel: evo.evolutionLevel,
      inventory: {
        crystalOre: inventory.crystalOre,
        mushroomOre: inventory.mushroomOre,
        // ... 全部字段
      },
      isTransformed: transform.isTransformed,
      transformForm: transform.transformForm,
      transformEnergy: transform.transformEnergy,
      transformMaxEnergy: transform.transformMaxEnergy,
      unlockedTransforms: [],
      exploredChunks: []
    };
    return saveData;
  }

  applySaveData(player: Entity, data: SaveData): void {
    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const health: HealthComponent = player.getComponent<HealthComponent>("Health")!;
    // ... 反序列化所有组件
    pos.x = data.playerX;
    pos.y = data.playerY;
    health.current = data.hp;
    // ...
  }
}
```

**实现指令：** 从现有 `SaveLoadSystem.ets` 迁移。保留完整的序列化/反序列化逻辑。`c.player.xxx` 改为从实体组件读取。`c.getExploredChunks()` 改为从 world.chunks 获取 key 列表。

- [ ] **Step 2: Build and commit**

```bash
git add entry/src/main/ets/game/systems/SaveLoadSystem.ets
git commit -m "feat: rewrite SaveLoadSystem for ECS with component serialization"
```

---

### Task 12: Renderers — Tile + Effect

**Files:**
- Rewrite: `entry/src/main/ets/game/renderers/TileRenderer.ets` (519 lines)
- Rewrite: `entry/src/main/ets/game/renderers/EffectRenderer.ets` (1063 lines)

**Interfaces:**
- Consumes: World, 组件类型, GameConstants
- Produces: 2 个改造后的渲染器
- Consumed by: GameScene (Task 16)

**渲染器改造模式：** 所有渲染器从 `render(c: GameContext)` 改为 `render(world: World, ctx: CanvasRenderingContext2D, cameraX: number, cameraY: number, settings: GameSettings, frameCount: number)`。数据从 World 查询获取。

- [ ] **Step 1: Rewrite TileRenderer**

核心变化：
- `c.chunks` → `world.chunks as Map<string, ChunkData>`
- `c.cameraX/Y` → 参数传入
- 渲染逻辑保留（tile 绘制、背景视差、生物群系装饰）

```typescript
import { World } from '@qiuyu/engine';
import { GameSettings, TILE_SIZE, CHUNK_SIZE } from '../GameConstants';

export class TileRenderer {
  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
         cameraY: number, settings: GameSettings, frameCount: number): void {
    const chunks: Map<string, Object> = world.chunks;
    // 迁移现有 TileRenderer 逻辑：
    // 1. 计算可见 chunk 范围
    // 2. 遍历可见 chunk 的 tiles
    // 3. 根据 TileType 绘制不同颜色/纹理
    // 4. 背景视差效果
    // 5. 生物群系装饰
  }
}
```

**实现指令：** 从现有 `TileRenderer.ets` 迁移。保留所有渲染逻辑（519 行），只改数据源。`c.chunks` → `world.chunks`。`c.cameraX/Y` → 参数。

- [ ] **Step 2: Rewrite EffectRenderer**

核心变化：
- `c.traps` → entities 过滤 tag="trap"
- `c.mechanisms` → entities 过滤 tag="mechanism"
- `c.chests` → entities 过滤 tag="chest"
- `c.particles` → entities 过滤 tag="particle"（或 ParticleManager.render()）
- `c.ambientParticles` → AmbientParticleSystem 内部数据（需要传递或保留引用）
- `c.damageFlashTimer` → GameStateComponent.damageFlashTimer

```typescript
import { World, Entity } from '@qiuyu/engine';
import { TrapComponent } from '../components/TrapComponent';
import { MechanismComponent } from '../components/MechanismComponent';
import { ChestComponent } from '../components/ChestComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import { GameSettings } from '../GameConstants';

export class EffectRenderer {
  private phase: string = "under"; // "under" 或 "over"，控制渲染层级

  constructor(phase: string = "under") {
    this.phase = phase;
  }

  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
         cameraY: number, settings: GameSettings, frameCount: number): void {
    if (this.phase === "under") {
      this.renderUnder(world, ctx, cameraX, cameraY, settings, frameCount);
    } else {
      this.renderOver(world, ctx, cameraX, cameraY, settings, frameCount);
    }
  }

  private renderUnder(world: World, ctx: CanvasRenderingContext2D,
                      cameraX: number, cameraY: number,
                      settings: GameSettings, frameCount: number): void {
    // 陷阱渲染（entities tag="trap"）
    // 机关渲染（entities tag="mechanism"）
    // 宝箱渲染（entities tag="chest"）
  }

  private renderOver(world: World, ctx: CanvasRenderingContext2D,
                     cameraX: number, cameraY: number,
                     settings: GameSettings, frameCount: number): void {
    // 粒子渲染
    // 光照效果
    // 伤害闪屏（GameStateComponent.damageFlashTimer）
    // 暗角效果
  }
}
```

注意：现有 EffectRenderer 是单个 `render(c)` 方法。需要拆分为 under/over 两个阶段，或者在 GameScene 中通过参数控制。参考现有代码中的渲染顺序决定如何拆分。

**实现指令：** 从现有 `EffectRenderer.ets`（1063 行）迁移。保留所有渲染逻辑。数据源从 `c.traps/mechanisms/chests/particles` 改为 World 实体查询。环境粒子需要从 AmbientParticleSystem 获取数据（可通过 World 上的额外字段或传递引用）。

- [ ] **Step 3: Build and commit**

```bash
git add entry/src/main/ets/game/renderers/TileRenderer.ets \
       entry/src/main/ets/game/renderers/EffectRenderer.ets
git commit -m "feat: rewrite TileRenderer and EffectRenderer for ECS data sources"
```

---

### Task 13: Renderers — Player + Enemy + Boss + UI

**Files:**
- Rewrite: `entry/src/main/ets/game/renderers/PlayerRenderer.ets` (1565 lines)
- Rewrite: `entry/src/main/ets/game/renderers/EnemyRenderer.ets` (727 lines)
- Rewrite: `entry/src/main/ets/game/renderers/BossRenderer.ets` (913 lines)
- Rewrite: `entry/src/main/ets/game/renderers/UIRenderer.ets` (258 lines)

**Interfaces:**
- Consumes: World, 组件类型, GameConstants
- Produces: 4 个改造后的渲染器
- Consumed by: GameScene (Task 16)

- [ ] **Step 1: Rewrite PlayerRenderer**

核心变化：
- `c.player` → `world.findEntityByTag("player")` + 组件
- 所有渲染逻辑保留（1565 行，像素画玩家，性别变体，4 种变身形态，6 种武器形态，进化效果）

```typescript
import { World, Entity, PositionComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { TransformComponent } from '../components/TransformComponent';
import { GameSettings } from '../GameConstants';

export class PlayerRenderer {
  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
         cameraY: number, settings: GameSettings, frameCount: number): void {
    const player: Entity | null = world.findEntityByTag("player");
    if (!player) return;
    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const movement: MovementComponent = player.getComponent<MovementComponent>("movement")!;
    const combat: CombatComponent = player.getComponent<CombatComponent>("combat")!;
    const transform: TransformComponent = player.getComponent<TransformComponent>("transform")!;

    // 迁移现有 PlayerRenderer 全部渲染逻辑（1565 行）
    // 只改数据访问：c.player.FIELD → 对应组件.FIELD
  }
}
```

**实现指令：** 这是最大的渲染器（1565 行）。保留所有渲染代码，只改数据源。`c.player.x` → `pos.x`，`c.player.facing` → `movement.facing`，`c.player.isAttacking` → `combat.isAttacking`，`c.player.isTransformed` → `transform.isTransformed`，等等。

- [ ] **Step 2: Rewrite EnemyRenderer**

核心变化：
- `c.enemies` → entities 过滤 tag="enemy"
- `c.xpOrbs` → entities 过滤 tag="xpOrb"

```typescript
import { World, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { XpPickupComponent } from '../components/XpPickupComponent';
import { GameSettings } from '../GameConstants';

export class EnemyRenderer {
  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
         cameraY: number, settings: GameSettings, frameCount: number): void {
    const entities: Entity[] = world.getEntities();

    // 渲染敌人（entities tag="enemy"）
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "enemy") continue;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const health: HealthComponent = e.getComponent<HealthComponent>("Health")!;
      const ai: EnemyAIComponent = e.getComponent<EnemyAIComponent>("enemyAI")!;
      // 迁移现有 EnemyRenderer 的 6 种敌人渲染逻辑
    }

    // 渲染 XP 球（entities tag="xpOrb"）
    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "xpOrb") continue;
      const pos: PositionComponent = e.getComponent<PositionComponent>("Position")!;
      const pickup: XpPickupComponent = e.getComponent<XpPickupComponent>("xpPickup")!;
      // 迁移现有 XP 球渲染逻辑
    }
  }
}
```

**实现指令：** 从现有 `EnemyRenderer.ets`（727 行）迁移。保留 6 种敌人类型的渲染逻辑。

- [ ] **Step 3: Rewrite BossRenderer**

核心变化：
- `c.bosses` → entities 过滤 tag="boss"
- `c.materialDrops` → entities 过滤 tag="materialDrop"
- Boss HP 条渲染保留

```typescript
import { World, Entity, PositionComponent, HealthComponent } from '@qiuyu/engine';
import { BossAIComponent } from '../components/BossAIComponent';
import { MaterialPickupComponent } from '../components/MaterialPickupComponent';
import { GameSettings, BOSS_SIZE } from '../GameConstants';

export class BossRenderer {
  render(world: World, ctx: CanvasRenderingContext2D, cameraX: number,
         cameraY: number, settings: GameSettings, frameCount: number): void {
    const entities: Entity[] = world.getEntities();

    // 渲染 Boss（entities tag="boss"）
    // 渲染材料掉落（entities tag="materialDrop"）
    // 渲染 Boss HP 条
  }
}
```

**实现指令：** 从现有 `BossRenderer.ets`（913 行）迁移。保留 5 种 Boss 类型的渲染逻辑。

- [ ] **Step 4: Rewrite UIRenderer**

核心变化：
- `c.chunks` → `world.chunks`
- `c.player` → player 实体
- 小地图渲染保留

```typescript
import { World, Entity, PositionComponent } from '@qiuyu/engine';
import { GameSettings, MINIMAP_SIZE, CHUNK_SIZE, TILE_SIZE } from '../GameConstants';

export class UIRenderer {
  renderMinimap(world: World, ctx: CanvasRenderingContext2D,
                settings: GameSettings, frameCount: number): void {
    const player: Entity | null = world.findEntityByTag("player");
    if (!player) return;
    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const chunks: Map<string, Object> = world.chunks;

    // 迁移现有 UIRenderer 小地图逻辑
  }
}
```

- [ ] **Step 5: Build and commit**

```bash
git add entry/src/main/ets/game/renderers/PlayerRenderer.ets \
       entry/src/main/ets/game/renderers/EnemyRenderer.ets \
       entry/src/main/ets/game/renderers/BossRenderer.ets \
       entry/src/main/ets/game/renderers/UIRenderer.ets
git commit -m "feat: rewrite Player, Enemy, Boss, UI renderers for ECS data sources"
```

---

### Task 14: GameScene + Entry Transformation

**Files:**
- Create: `entry/src/main/ets/game/GameScene.ets`
- Rewrite: `entry/src/main/ets/pages/Index.ets` (1530 lines)

**Interfaces:**
- Consumes: World, 全部 19 个系统, 全部 6 个渲染器, 全部 5 个工厂, Engine, AudioManager, GameSettings
- Produces: GameScene 类，改造后的 Index.ets
- Consumed by: 无（顶层集成）

- [ ] **Step 1: Create GameScene**

```typescript
import { Scene, BaseContext, World, Entity, SystemContext,
         PositionComponent, HealthComponent } from '@qiuyu/engine';
import { AudioManager } from './AudioManager';
import { GameSettings, GameState } from './GameConstants';
import { WorldGenerator } from './WorldGenerator';
import { PlayerFactory } from './factories/PlayerFactory';
import { CameraComponent } from './components/CameraComponent';
import { GameStateComponent } from './components/GameStateComponent';

// Systems
import { SpatialRebuildSystem } from './systems/SpatialRebuildSystem';
import { ChunkLoadSystem } from './systems/ChunkLoadSystem';
import { PlayerMovementSystem } from './systems/PlayerMovementSystem';
import { PlayerCombatSystem } from './systems/PlayerCombatSystem';
import { EnemyAISystem } from './systems/EnemyAISystem';
import { BossSystem } from './systems/BossSystem';
import { TransformSystem } from './systems/TransformSystem';
import { TrapSystem } from './systems/TrapSystem';
import { MechanismSystem } from './systems/MechanismSystem';
import { ChestSystem } from './systems/ChestSystem';
import { MaterialDropSystem } from './systems/MaterialDropSystem';
import { XpLevelSystem } from './systems/XpLevelSystem';
import { DamageSystem } from './systems/DamageSystem';
import { EvolutionSystem } from './systems/EvolutionSystem';
import { CameraSystem } from './systems/CameraSystem';
import { ParticleSystem } from './systems/ParticleSystem';
import { AmbientParticleSystem } from './systems/AmbientParticleSystem';
import { SaveLoadSystem } from './systems/SaveLoadSystem';
import { CleanupSystem } from './systems/CleanupSystem';

// Renderers
import { TileRenderer } from './renderers/TileRenderer';
import { EffectRenderer } from './renderers/EffectRenderer';
import { EnemyRenderer } from './renderers/EnemyRenderer';
import { BossRenderer } from './renderers/BossRenderer';
import { PlayerRenderer } from './renderers/PlayerRenderer';
import { UIRenderer } from './renderers/UIRenderer';

export class GameScene extends Scene {
  private world: World;
  private audio: AudioManager;
  private settings: GameSettings;
  private tileRenderer: TileRenderer = new TileRenderer();
  private effectRendererUnder: EffectRenderer = new EffectRenderer("under");
  private effectRendererOver: EffectRenderer = new EffectRenderer("over");
  private enemyRenderer: EnemyRenderer = new EnemyRenderer();
  private bossRenderer: BossRenderer = new BossRenderer();
  private playerRenderer: PlayerRenderer = new PlayerRenderer();
  private uiRenderer: UIRenderer = new UIRenderer();

  constructor(audio: AudioManager, settings: GameSettings) {
    super();
    this.audio = audio;
    this.settings = settings;
    this.world = new World();

    // 初始化世界生成器
    const worldGen: WorldGenerator = new WorldGenerator();
    this.world.worldGen = worldGen;

    // 创建单例实体
    this.world.addEntity(PlayerFactory.create(0, 0));

    const cameraEntity: Entity = new Entity("camera");
    cameraEntity.addComponent(new CameraComponent());
    this.world.addEntity(cameraEntity);

    const gameStateEntity: Entity = new Entity("gameState");
    gameStateEntity.addComponent(new GameStateComponent());
    this.world.addEntity(gameStateEntity);

    // 注册系统（19 个，按执行顺序）
    this.world.addSystem(new SpatialRebuildSystem());
    this.world.addSystem(new ChunkLoadSystem());
    this.world.addSystem(new PlayerMovementSystem());
    this.world.addSystem(new PlayerCombatSystem());
    this.world.addSystem(new EnemyAISystem());
    this.world.addSystem(new BossSystem());
    this.world.addSystem(new TransformSystem());
    this.world.addSystem(new TrapSystem());
    this.world.addSystem(new MechanismSystem());
    this.world.addSystem(new ChestSystem());
    this.world.addSystem(new MaterialDropSystem());
    this.world.addSystem(new XpLevelSystem());
    this.world.addSystem(new DamageSystem());
    this.world.addSystem(new EvolutionSystem());
    this.world.addSystem(new CameraSystem());
    this.world.addSystem(new ParticleSystem());
    this.world.addSystem(new AmbientParticleSystem());
    this.world.addSystem(new SaveLoadSystem());
    this.world.addSystem(new CleanupSystem());
  }

  update(baseCtx: BaseContext, dt: number): void {
    const sysCtx: SystemContext = {
      world: this.world,
      ctx: baseCtx.ctx,
      minimapCtx: baseCtx.minimapCtx,
      screenW: baseCtx.screenW,
      screenH: baseCtx.screenH,
      cameraX: this.world.cameraX,
      cameraY: this.world.cameraY,
      input: baseCtx.input,
      resources: baseCtx.resources,
      audio: this.audio,
      settings: this.settings,
      frameCount: baseCtx.frameCount,
      dt: dt
    };
    this.world.update(sysCtx, dt);
  }

  render(baseCtx: BaseContext): void {
    const camX: number = this.world.cameraX;
    const camY: number = this.world.cameraY;
    const w: World = this.world;
    const ctx: CanvasRenderingContext2D = baseCtx.ctx;
    const s: GameSettings = this.settings;
    const fc: number = baseCtx.frameCount;

    this.tileRenderer.render(w, ctx, camX, camY, s, fc);
    this.effectRendererUnder.render(w, ctx, camX, camY, s, fc);
    this.enemyRenderer.render(w, ctx, camX, camY, s, fc);
    this.bossRenderer.render(w, ctx, camX, camY, s, fc);
    this.playerRenderer.render(w, ctx, camX, camY, s, fc);
    this.effectRendererOver.render(w, ctx, camX, camY, s, fc);
    this.uiRenderer.renderMinimap(w, ctx, s, fc);
  }

  getWorld(): World {
    return this.world;
  }
}
```

- [ ] **Step 2: Rewrite Index.ets**

核心变化：
- 移除 `EngineBase`/`GameEngine` 引用
- 直接使用 `Engine` + `GameScene`
- UI 状态查询改为从 World 实体读取组件
- 输入转发保持不变（Engine.setInputXxx）

```typescript
// 关键变化点：
// 1. import { Engine } from '@qiuyu/engine'（不再 import EngineBase/GameEngine）
// 2. import { GameScene } from '../game/GameScene'
// 3. aboutToAppear() 中：
//    - const gameScene = new GameScene(this.audio, this.settings)
//    - this.engine.sceneManager.pushScene(gameScene)
//    - this.engine.init(ctx, minimapCtx, screenW, screenH)
// 4. UI 状态查询方法：
//    - getPlayerHp() → world.findEntityByTag("player").getComponent("Health").current
//    - getInventory() → world.findEntityByTag("player").getComponent("inventory")
//    - 等等
// 5. 状态机控制：
//    - pause/resume → gameScene.getWorld().findEntityByTag("gameState").getComponent("gameState").state
```

**实现指令：** 从现有 `Index.ets`（1530 行）迁移。保留所有 UI 构建代码（@Builder 方法）。改变：
1. 引擎初始化：`new Engine()` + `pushScene(new GameScene(...))` + `engine.init()`
2. 所有 `this.gameEngine.getXxx()` 调用改为从 World 查询
3. 所有 `this.gameEngine.setXxx()` 调用改为直接写组件
4. 状态机控制改为写 GameStateComponent.state
5. 保留所有 @Builder UI 方法不变

- [ ] **Step 3: Build verification**

Run: `hvigorw assembleHap --no-daemon`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/GameScene.ets \
       entry/src/main/ets/pages/Index.ets
git commit -m "feat: create GameScene and transform Index.ets entry point for ECS"
```

---

### Task 15: Delete Legacy Files + Final Verification

**Files:**
- Delete: `entry/src/main/ets/engine/EngineBase.ets`
- Delete: `entry/src/main/ets/game/GameContext.ets`
- Delete: `entry/src/main/ets/game/GameEngine.ets`

- [ ] **Step 1: Delete legacy files**

```bash
git rm entry/src/main/ets/engine/EngineBase.ets
git rm entry/src/main/ets/game/GameContext.ets
git rm entry/src/main/ets/game/GameEngine.ets
```

- [ ] **Step 2: Verify no remaining references**

用 Grep 搜索整个项目，确保没有文件仍在 import 已删除的文件：

```bash
grep -r "EngineBase" entry/src/main/ets/ --include="*.ets"
grep -r "GameContext" entry/src/main/ets/ --include="*.ets"
grep -r "GameEngine" entry/src/main/ets/ --include="*.ets"
grep -r "MovementBridge\|TransformBridge\|BossBridge\|MechanismBridge\|DamageBridge\|ChestBridge\|SaveLoadBridge" entry/src/main/ets/ --include="*.ets"
```

Expected: 无匹配结果。如果有残留引用，修复它们。

- [ ] **Step 3: Full build verification**

Run: `hvigorw assembleHap --no-daemon`
Expected: BUILD SUCCESSFUL，无编译错误

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "refactor: delete GameContext, EngineBase, GameEngine — ECS migration complete"
```

- [ ] **Step 5: Smoke test**

在设备上运行游戏，验证：
1. 游戏正常启动，进入主界面
2. 角色可以移动、攻击
3. 敌人正常生成和 AI 行为
4. 区块正常加载
5. UI 正常显示（HP、经验、小地图）
6. 存档/读档正常

---

## Self-Review Notes

1. **Spec coverage:** 所有 spec 中列出的文件都有对应 Task。17 个组件（Task 2-3）、5 个工厂（Task 4）、19 个系统（Task 5-6, 7-11）、6 个渲染器（Task 12-13）、GameScene（Task 14）、Engine HAR（Task 1）、删除（Task 15）。

2. **Type consistency:** 组件 getType() 返回值与系统 getComponent() 调用一致（小写字符串）。SystemContext 字段名在 Engine HAR 和 GameScene 组装中一致。

3. **Design tension resolution:** `audio` 和 `settings` 在 SystemContext 中为 `Object` 类型，在游戏代码中转型。`chunks` 在 World 中为 `Map<string, Object>`，在游戏代码中转型为 `Map<string, ChunkData>`。`worldGen` 在 World 中为 `Object | null`，在游戏代码中转型为 `WorldGenerator`。
