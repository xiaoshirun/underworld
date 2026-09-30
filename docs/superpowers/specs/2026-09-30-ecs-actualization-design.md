# ECS 实际化 — 全面重写设计规格

## 概述

将游戏从 GameContext 上帝对象架构全面重写为 ECS（Entity-Component-System）架构。消除 GameContext、EngineBase、GameEngine 及 7 个 Bridge 接口，所有游戏状态拆分为实体上的组件，所有系统继承 Engine.System，系统间通过组件通信而非直接调用。

## 动机

当前架构的核心问题：

1. **GameContext 上帝对象** — 40+ 字段，所有 14 个系统和 6 个渲染器直接读写，无封装
2. **Bridge 循环依赖** — GameEngine 实现 7 个 Bridge 接口，系统回调 GameEngine，形成双向耦合
3. **共享可变状态** — `shakeTimer`、`player.hp` 等被 7+ 个系统同时写入，竞态风险
4. **Engine HAR 的 ECS 基础设施完全闲置** — Entity/Component/System 数组无人使用
5. **不可复用** — 游戏逻辑与 GameContext 深度绑定，Engine HAR 无法服务于其他游戏

## 架构

### 核心层级

```
Engine HAR（通用引擎）
  Engine → SceneManager → Scene → World → System[] → Entity[] + Component[]

Entry（游戏专用）
  Index.ets → Engine + GameScene
  GameScene → World + System[] + Renderer[]
  Factories → Entity + Component[]
```

### 数据流

```
Engine.tick(dt)
  → SceneManager.update(sceneCtx, dt)
    → GameScene.update(baseCtx, dt)
      → 组装 SceneContext（world + audio + settings + baseCtx）
      → World.update(sceneCtx, dt)
        → SpatialRebuildSystem    — 重建空间索引
        → ChunkLoadSystem          — 加载区块，创建实体
        → PlayerMovementSystem     — 玩家移动
        → PlayerCombatSystem       — 玩家攻击
        → EnemyAISystem            — 敌人 AI
        → BossSystem               — Boss AI
        → TransformSystem          — 变身逻辑
        → TrapSystem               — 陷阱伤害
        → MechanismSystem          — 机关交互
        → ChestSystem              — 开箱
        → MaterialDropSystem       — 拾取材料
        → XpLevelSystem            — 经验升级
        → DamageSystem             — 死亡检测
        → EvolutionSystem          — 进化
        → CameraSystem             — 相机跟随 + 震动
        → ParticleSystem           — 粒子更新
        → AmbientParticleSystem    — 环境粒子
        → SaveLoadSystem           — 自动存档
        → CleanupSystem            — 清理死亡实体
      → 帧末清理 active=false 的实体
    → GameScene.render(baseCtx)
      → TileRenderer → EffectRenderer(under) → EnemyRenderer
      → BossRenderer → PlayerRenderer → EffectRenderer(over) → UIRenderer
```

### 系统间通信

消除所有 Bridge 接口，系统通过组件通信：

- **PlayerMovementSystem** 设 `CombatComponent.isAttacking = true`
- **PlayerCombatSystem** 下一帧（或同帧后续顺序）读取该标记执行攻击
- **PlayerCombatSystem** 写 `enemy.HealthComponent.damage(amount)`
- **EnemyAISystem** 读 `enemy.HealthComponent.isDead()` 处理死亡
- **DamageSystem** 读 `player.HealthComponent` 检测玩家死亡
- **系统不直接调用其他系统的方法**

## Engine HAR 改造

### World.ets（新增）

```typescript
export class World {
  private entities: Entity[] = [];
  private systems: System[] = [];
  private spatialGrid: SpatialGrid<Entity> = new SpatialGrid<Entity>(128);
  chunks: Map<string, ChunkData> = new Map<string, ChunkData>();
  worldGen: WorldGen;
  cameraX: number = 0;
  cameraY: number = 0;

  addEntity(entity: Entity): Entity;
  removeEntity(entity: Entity): void;       // 标记 active=false，延迟删除
  addSystem(system: System): void;

  query(componentType: string): Entity[];   // 按组件类型筛选
  queryWithTag(tag: string): Entity[];      // 按 tag 筛选
  findEntityByTag(tag: string): Entity | null;  // 快速找单例实体

  rebuildSpatialGrid(): void;
  getSpatialGrid(): SpatialGrid<Entity>;

  update(context: SceneContext, dt: number): void;
  // 遍历 systems，帧末 filter active=false
}
```

World 持有区块数据（`chunks`）和世界生成器（`worldGen`），这些是环境数据而非实体状态。

### Entity.ets（增强）

```typescript
export class Entity {
  id: number;                    // 自增 ID
  tag: string;                   // 新增：快速标识 "player"/"enemy"/"boss"/"camera"/"game"
  active: boolean = true;        // 已有：延迟删除标记
  private components: Map<string, Component> = new Map();

  addComponent(component: Component): void;
  getComponent<T extends Component>(type: string): T | undefined;
  hasComponent(type: string): boolean;
  removeComponent(type: string): void;
  getAllComponents(): Component[];
}
```

### Component.ets（扩展 Serializable）

```typescript
export interface Component {
  getType(): string;
}

export interface Serializable {
  serialize(): Record<string, Object>;
  deserialize(data: Record<string, Object>): void;
}
```

基础组件（Position, Velocity, Health, Sprite, Collider）保留在 Engine HAR。游戏专用组件放在 entry 模块。

### System.ets（增强 SystemContext）

```typescript
export interface SystemContext {
  world: World;                    // 新增
  ctx: CanvasRenderingContext2D;
  minimapCtx: CanvasRenderingContext2D;
  screenW: number;
  screenH: number;
  cameraX: number;
  cameraY: number;
  input: InputState;
  resources: ResourceManager;
  audio: AudioManager;             // 新增
  settings: GameSettings;          // 新增
  frameCount: number;              // 新增：从 Engine.frameCount 传入
  dt: number;
}

export abstract class System {
  protected enabled: boolean = true;
  isEnabled(): boolean;
  setEnabled(v: boolean): void;
  abstract update(entities: Entity[], context: SystemContext): void;
}
```

### Scene.ets（改造 SceneContext）

Engine 传递 BaseContext，Scene 自行组装完整上下文：

```typescript
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

### Engine.ets（简化 tick）

```typescript
tick(dt: number): void {
  const activeScene = this.sceneManager.getActiveScene();
  if (activeScene !== null && this.ctx !== null) {
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
```

移除 Engine 自身的 entities/systems 数组（由 World 管理），移除 delegate 回退路径。

### index.ets（更新导出）

新增导出：`World`, `BaseContext`, `Serializable`

## 游戏专用组件

放在 `entry/src/main/ets/game/components/`，每个组件一个文件。

### 玩家组件

| 组件 | 字段 | 来源 |
|------|------|------|
| MovementComponent | facing, isJumping, jumpTimer, jumpHeight, isDashing, dashTimer, dashCooldown, isDrilling, drillTargetX, drillTargetY, drillHitCount, isUsingTool, toolCooldown, isEngulfed, engulfEscapeCount, engulfDamageTimer | PlayerState 移动字段 |
| CombatComponent | isAttacking, attackTimer, attackCooldown, invincibleTimer, animFrame | PlayerState 战斗字段 |
| TransformComponent | isTransformed, transformForm, savedWeaponForm, currentWeaponForm, transformEnergy, transformCooldown, transformAnimTimer, transformFormAttackCooldown | PlayerState 变身字段 |
| InventoryComponent | coreNormal, coreRare, formCore, hpPotions, gold, crystalOre, mushroomOre, flameOre, abyssOre, voidOre | player.inventory |
| XpComponent | xp, level | player.xp/level |
| EvolutionComponent | evolutionLevel, unlockedForms, evolutionBranch | PlayerState 进化字段 |

### 敌人组件

| 组件 | 字段 |
|------|------|
| EnemyAIComponent | enemyType, bouncePhase, hitFlash, moveTimer, targetX, targetY, isCharging, chargeTimer, isEngulfing, engulfedPlayer |
| BossAIComponent | bossType, bossRole, phase, attackTimer, defeated, active |

### 掉落物组件

| 组件 | 字段 |
|------|------|
| XpPickupComponent | xpValue, active |
| MaterialPickupComponent | materialType, amount, active |
| TransformCorePickupComponent | form, rarity, active |

### 世界组件

| 组件 | 字段 |
|------|------|
| TrapComponent | trapType, state, timer |
| MechanismComponent | mechanismType, active, rotation, posX, posY |
| ChestComponent | chestType, opened, openAnim, loot |
| ParticleComponent | life, maxLife, color, size, vx, vy, gravity, fadeRate |

### 全局组件

| 组件 | 字段 |
|------|------|
| CameraComponent | shakeX, shakeY, shakeTimer |
| GameStateComponent | state, damageFlashTimer, bossRoomLocked |

## 实体工厂

放在 `entry/src/main/ets/game/factories/`。

### PlayerFactory

```typescript
static create(settings: GameSettings): Entity {
  const entity = new Entity("player");
  entity.addComponent(new PositionComponent(startX, startY));
  entity.addComponent(new VelocityComponent(0, 0));
  entity.addComponent(new HealthComponent(maxHp, maxHp));
  entity.addComponent(new MovementComponent());
  entity.addComponent(new CombatComponent());
  entity.addComponent(new TransformComponent());
  entity.addComponent(new InventoryComponent());
  entity.addComponent(new XpComponent());
  entity.addComponent(new EvolutionComponent());
  entity.addComponent(new ColliderComponent(20, 20, 0, 0));
  return entity;
}
```

### EnemyFactory

创建史莱姆实体：Position + Velocity + Health + EnemyAI + Collider + XpReward

### BossFactory

创建 Boss 实体：Position + Velocity + Health + BossAI + Collider

### DropFactory

- `createXpOrb(x, y, value)` → Position + XpPickup
- `createMaterialDrop(x, y, type, amount)` → Position + MaterialPickup
- `createTransformCore(x, y, form, rarity)` → Position + TransformCorePickup

### WorldEntityFactory

- `createTrap(x, y, type)` → Position + Trap + Collider
- `createMechanism(x, y, type)` → Position + Mechanism + Collider
- `createChest(x, y, type, loot)` → Position + Chest + Collider

## 系统迁移

### 系统执行顺序

| 序号 | 系统 | 查询组件 | Bridge 消除 |
|------|------|----------|------------|
| 1 | SpatialRebuildSystem | 所有 Position 实体 | 新增，替代 rebuildSpatialGrids() |
| 2 | ChunkLoadSystem | player.Position | 直接 world.addEntity() 创建实体 |
| 3 | PlayerMovementSystem | player.Position + Velocity + Movement + Combat + Transform | bridge.performAttack() → 设 CombatComponent.isAttacking |
| 4 | PlayerCombatSystem | player.Combat + Position → spatial query enemy.Health | 直接写 enemy.HealthComponent.damage() |
| 5 | EnemyAISystem | enemy.AI + Position → player.Position | 直接写 player.HealthComponent.damage() |
| 6 | BossSystem | boss.AI + Position → player.Position | 直接创建掉落实体 + 写 HealthComponent |
| 7 | TransformSystem | player.Transform + Combat + Movement | bridge.onEnemyDeath() → 查询 HealthComponent.isDead() |
| 8 | TrapSystem | trap.Trap → spatial query player.Position | 直接写 player.HealthComponent.damage() |
| 9 | MechanismSystem | mechanism.Mechanism → player.Position + input | bridge.checkBreakableWalls() → 直接操作 world.chunks |
| 10 | ChestSystem | chest.Chest → player.Position | 直接写 player.InventoryComponent |
| 11 | MaterialDropSystem | material.MaterialPickup → player.Position | 直接写 player.InventoryComponent + EvolutionComponent |
| 12 | XpLevelSystem | player.Xp → spatial query XpPickup | 直接写 player.XpComponent + HealthComponent |
| 13 | DamageSystem | player.Health + GameState | bridge.setState() → 直接写 GameStateComponent.state |
| 14 | EvolutionSystem | player.Evolution + Inventory | 无 bridge，直接读写组件 |
| 15 | CameraSystem | player.Position + camera.Camera | 新增，从 GameEngine.updateCamera/updateShake 提取 |
| 16 | ParticleSystem | particle.Particle | 新增，从 GameContext.updateParticles 提取 |
| 17 | AmbientParticleSystem | — | 新增，从 GameEngine.updateAmbientParticles 提取 |
| 18 | SaveLoadSystem | 全部实体 | 每个 Component 实现 serialize()/deserialize() |
| 19 | CleanupSystem | active=false 的实体 | 新增，帧末清理 |

### 新增系统详情

**SpatialRebuildSystem** — 每帧第一执行，遍历所有带 PositionComponent 的活跃实体，重建 SpatialGrid\<Entity\>。

**CameraSystem** — 读取 player.Position，更新 CameraComponent 的 cameraX/Y（跟随逻辑）和 shakeX/Y/shakeTimer（震动衰减）。World.cameraX/Y 从 CameraComponent 同步。

**ParticleSystem** — 遍历所有带 ParticleComponent 的实体，更新位置、生命值。life<=0 的标记 active=false。

**AmbientParticleSystem** — 管理环境粒子（非实体，保留数组），根据相机位置和设置更新。

**CleanupSystem** — 最后执行，`entities = entities.filter(e => e.active)`。

## 渲染器改造

渲染器保持独立类，数据源从 GameContext 改为 World 查询：

```typescript
// 旧
class PlayerRenderer {
  render(g: GameContext): void {
    const p = g.player;
    // 绘制 p.x, p.y, p.facing, p.isAttacking...
  }
}

// 新
class PlayerRenderer {
  render(world: World, ctx: CanvasRenderingContext2D,
         cameraX: number, cameraY: number, settings: GameSettings,
         frameCount: number): void {
    const player = world.findEntityByTag("player");
    if (!player) return;
    const pos = player.getComponent<PositionComponent>("position");
    const movement = player.getComponent<MovementComponent>("movement");
    const combat = player.getComponent<CombatComponent>("combat");
    const transform = player.getComponent<TransformComponent>("transform");
    // 绘制 pos.x, pos.y, movement.facing, combat.isAttacking...
  }
}
```

6 个渲染器全部按此模式改造：TileRenderer、PlayerRenderer、EnemyRenderer、BossRenderer、EffectRenderer、UIRenderer。

## 存档序列化

每个游戏专用组件实现 `Serializable` 接口：

```typescript
export class InventoryComponent implements Component, Serializable {
  getType(): string { return "inventory"; }

  serialize(): Record<string, Object> {
    return {
      coreNormal: this.coreNormal,
      coreRare: this.coreRare,
      // ...
    };
  }

  deserialize(data: Record<string, Object>): void {
    this.coreNormal = data["coreNormal"] as number;
    this.coreRare = data["coreRare"] as number;
    // ...
  }
}
```

SaveLoadSystem 遍历所有实体，按 tag 和组件类型序列化。加载时反向：读数据 → 创建实体 → 反序列化组件 → 恢复到 World。

## 入口改造

### Index.ets（页面入口）

```typescript
@Entry struct GamePage {
  private engine: Engine = new Engine();
  private audio: AudioManager = new AudioManager();

  aboutToAppear() {
    this.audio.init();
    const settings: GameSettings = { /* ... */ };
    const gameScene = new GameScene(this.audio, settings);
    this.engine.sceneManager.pushScene(gameScene);
    this.engine.init(ctx, minimapCtx, screenW, screenH);
  }

  // 输入直接转发到 Engine
  onJoyInput(active: boolean, dx: number, dy: number) {
    this.engine.setInputJoy(active, dx, dy);
  }
}
```

### GameScene

```typescript
export class GameScene extends Scene {
  private world: World;
  private renderers: Renderer[];
  private audio: AudioManager;
  private settings: GameSettings;

  constructor(audio: AudioManager, settings: GameSettings) {
    super();
    this.audio = audio;
    this.settings = settings;
    this.world = new World();

    // 创建单例实体
    this.world.addEntity(PlayerFactory.create(settings));
    this.world.addEntity(this.createCameraEntity());
    this.world.addEntity(this.createGameStateEntity());

    // 注册系统（19 个，按执行顺序）
    this.world.addSystem(new SpatialRebuildSystem());
    this.world.addSystem(new ChunkLoadSystem());
    // ... 全部系统

    // 创建渲染器
    this.renderers = [
      new TileRenderer(), new EffectRenderer(),
      new EnemyRenderer(), new BossRenderer(),
      new PlayerRenderer(), new EffectRenderer(),
      new UIRenderer()
    ];
  }

  update(baseCtx: BaseContext, dt: number): void {
    const ctx: SystemContext = {
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
      dt: dt,
      frameCount: baseCtx.frameCount
    };
    this.world.update(ctx, dt);
  }

  render(baseCtx: BaseContext): void {
    for (const renderer of this.renderers) {
      renderer.render(this.world, baseCtx.ctx, this.world.cameraX, this.world.cameraY,
                      this.settings, baseCtx.frameCount);
    }
  }
}
```

## 删除清单

| 文件 | 原因 |
|------|------|
| `entry/src/main/ets/engine/EngineBase.ets` | GameContext 不存在，EngineBase 无存在意义 |
| `entry/src/main/ets/game/GameContext.ets` | 上帝对象，被 World + 实体组件完全替代 |
| `entry/src/main/ets/game/GameEngine.ets` | Bridge 接口 + 系统编排被 World + GameScene 替代 |
| 7 个 Bridge 接口定义（在 GameEngine.ets 中） | 系统间通过组件通信 |

## 保留不变

| 文件 | 说明 |
|------|------|
| `GameConstants.ets` | 枚举、常量、类型定义 |
| `ParticleSystem.ets` | ParticleManager 工具类（emitter presets） |
| `AudioManager.ets` | 音频服务 |
| `WorldGen.ets` | 世界生成器 |
| `Engine/SpatialGrid.ets` | 空间索引（Engine HAR） |
| `Engine/ResourceManager.ets` | 资源管理（Engine HAR） |
| `Engine/SceneManager.ets` | 场景管理（Engine HAR） |

## 文件结构总览

```
Engine/src/main/ets/
├── Engine.ets              (修改)
├── World.ets               (新增)
├── Entity.ets              (增强)
├── Component.ets           (扩展 Serializable)
├── System.ets              (增强 SystemContext)
├── Scene.ets               (改造: BaseContext)
├── SceneManager.ets        (不变)
├── SpatialGrid.ets         (不变)
├── ResourceManager.ets     (不变)
└── index.ets               (更新导出)

entry/src/main/ets/
├── pages/Index.ets                      (大改)
├── engine/EngineBase.ets                (删除)
├── game/
│   ├── GameConstants.ets                (保留)
│   ├── GameContext.ets                  (删除)
│   ├── GameEngine.ets                   (删除)
│   ├── ParticleSystem.ets              (保留)
│   ├── components/                      (新增 17 个组件文件)
│   │   ├── MovementComponent.ets
│   │   ├── CombatComponent.ets
│   │   ├── TransformComponent.ets
│   │   ├── InventoryComponent.ets
│   │   ├── XpComponent.ets
│   │   ├── EvolutionComponent.ets
│   │   ├── EnemyAIComponent.ets
│   │   ├── BossAIComponent.ets
│   │   ├── XpPickupComponent.ets
│   │   ├── MaterialPickupComponent.ets
│   │   ├── TransformCorePickupComponent.ets
│   │   ├── TrapComponent.ets
│   │   ├── MechanismComponent.ets
│   │   ├── ChestComponent.ets
│   │   ├── ParticleComponent.ets
│   │   ├── CameraComponent.ets
│   │   └── GameStateComponent.ets
│   ├── factories/                       (新增 5 个工厂文件)
│   │   ├── PlayerFactory.ets
│   │   ├── EnemyFactory.ets
│   │   ├── BossFactory.ets
│   │   ├── DropFactory.ets
│   │   └── WorldEntityFactory.ets
│   ├── systems/                         (全部重写 + 5 个新增)
│   │   ├── SpatialRebuildSystem.ets     (新增)
│   │   ├── ChunkLoadSystem.ets          (重写)
│   │   ├── PlayerMovementSystem.ets     (重写)
│   │   ├── PlayerCombatSystem.ets       (重写)
│   │   ├── EnemyAISystem.ets            (重写)
│   │   ├── BossSystem.ets               (重写)
│   │   ├── TransformSystem.ets          (重写)
│   │   ├── TrapSystem.ets               (重写)
│   │   ├── MechanismSystem.ets          (重写)
│   │   ├── ChestSystem.ets              (重写)
│   │   ├── MaterialDropSystem.ets       (重写)
│   │   ├── XpLevelSystem.ets            (重写)
│   │   ├── DamageSystem.ets             (重写)
│   │   ├── EvolutionSystem.ets          (重写)
│   │   ├── CameraSystem.ets             (新增)
│   │   ├── ParticleSystem.ets           (新增)
│   │   ├── AmbientParticleSystem.ets    (新增)
│   │   ├── SaveLoadSystem.ets           (重写)
│   │   └── CleanupSystem.ets            (新增)
│   └── renderers/                       (全部改造数据源)
│       ├── TileRenderer.ets
│       ├── PlayerRenderer.ets
│       ├── EnemyRenderer.ets
│       ├── BossRenderer.ets
│       ├── EffectRenderer.ets
│       └── UIRenderer.ets
```

## 约束

- ArkTS strict mode：所有变量必须有显式类型注解
- Engine HAR 不导入 HarmonyOS 平台 API（使用 RawFileProvider 接口模式）
- 游戏专用组件放在 entry 模块，不污染 Engine HAR
- 区块数据（chunks）保留为 World 的数据，不做实体化（数据量过大，不适合 ECS 查询模式）
- 渲染器保持独立类，不继承 System（渲染与逻辑分离）
- 粒子系统（ParticleManager 工具类）保留，ParticleSystem 作为 ECS 系统管理粒子实体
