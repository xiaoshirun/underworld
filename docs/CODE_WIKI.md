# 地下世界 (Underworld) — Code Wiki

> 基于 HarmonyOS 的 2D 像素风地牢探索游戏，采用自研 ECS（实体-组件-系统）架构引擎，Canvas2D 全程序化渲染。

---

## 目录

1. [项目概述](#1-项目概述)
2. [技术栈](#2-技术栈)
3. [整体架构](#3-整体架构)
4. [目录结构](#4-目录结构)
5. [Engine 模块（通用 ECS 引擎）](#5-engine-模块通用-ecs-引擎)
6. [Entry 游戏模块](#6-entry-游戏模块)
7. [页面层](#7-页面层)
8. [依赖关系](#8-依赖关系)
9. [核心数据流：游戏主循环](#9-核心数据流游戏主循环)
10. [项目运行方式](#10-项目运行方式)
11. [精灵资源生成管线](#11-精灵资源生成管线)
12. [已知问题与修复记录](#12-已知问题与修复记录)

---

## 1. 项目概述

**地下世界** 是一款运行在 HarmonyOS 平台上的 2D 横版地牢探索游戏。玩家扮演一名冒险者，在无限生成的程序化地牢中战斗、收集、进化。游戏核心特色：

- **无限程序化世界**：基于 Value Noise + FBM 的地牢生成，6 种生物群落（普通、水晶、蘑菇、水域、熔岩、暗影）
- **6 种史莱姆敌人** + **1 种拟人兽精英**，各有独特 AI（巡逻、追击、吞噬、充能、分裂）
- **5 类 Boss**，双阶段战斗机制
- **武器进化系统**：6 种武器形态 × 5 条进化路线 × 3 个等级
- **变身系统**：4 种变身形态（史莱姆、幽灵、铠甲、钢铁侠），能量管理
- **吞噬技能系统**：吞噬敌人获取技能，6 系技能 × 3 阶
- **陷阱与机关**：6 种陷阱 + 6 种机关
- **自动存档**：基于 Preferences 的完整状态序列化

---

## 2. 技术栈

| 类别 | 技术 |
|------|------|
| 平台 | HarmonyOS (SDK 5.0.0+ / API 12+) |
| 语言 | ArkTS (strict mode, `.ets`) |
| 渲染 | Canvas2D API（主画布 + 小地图画布） |
| 音频 | AudioKit (`AudioRenderer`) 程序化合成 |
| 存储 | Preferences API |
| 引擎 | 自研 ECS 引擎（`@qiuyu/engine` HAR 模块） |
| 构建工具 | hvigor / DevEco Studio |
| 资源生成 | Node.js + `@napi-rs/canvas`（离线精灵表生成） |

---

## 3. 整体架构

项目采用 **双模块结构**：通用引擎层 + 游戏业务层。

```
┌─────────────────────────────────────────────────────────────┐
│                        HarmonyOS Runtime                     │
├─────────────────────────────────────────────────────────────┤
│  Entry Module (HAP)                                          │
│  ┌──────────┐   ┌────────────────────────────────────────┐  │
│  │  Pages   │──▶│             GameScene                   │  │
│  │ (ArkUI)  │   │  World + Systems[] + Renderers[]         │  │
│  └──────────┘   └────────────────────────────────────────┘  │
│        │                │                                    │
│        │                ▼                                    │
│        │         ┌──────────────┐                            │
│        │         │  Factories   │  (创建 Entity+Component)   │
│        │         └──────────────┘                            │
│        │                │                                    │
│        ▼                ▼                                    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              @qiuyu/engine (HAR)                      │    │
│  │  Engine → SceneManager → Scene → World → System[]    │    │
│  │                    └── Entity[] + Component[]         │    │
│  │                    └── SpatialGrid (空间索引)          │    │
│  │                    └── ResourceManager (资源加载)      │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**架构分层：**

1. **引擎层 (`@qiuyu/engine`)**：与游戏逻辑无关的通用 ECS 基础设施，提供实体、组件、系统、场景、空间索引、资源管理等抽象。
2. **游戏业务层 (`entry`)**：基于引擎实现的具体游戏内容，包括组件、系统、工厂、渲染器、精灵生成等。
3. **页面层 (`pages`)**：ArkUI 声明式 UI，负责画布承载、触控输入、HUD 显示、弹窗等。

---

## 4. 目录结构

```
Game/
├── Engine/                          # 通用 ECS 引擎 (HAR 模块)
│   └── src/main/ets/
│       ├── Engine.ets               # 引擎入口：主循环 + 输入管理
│       ├── World.ets                # 实体管理 + 系统调度 + 空间索引
│       ├── Entity.ets               # 实体类 (id + tag + components)
│       ├── Component.ets            # 基础组件 (Position/Velocity/Health/Sprite/Collider) + Serializable
│       ├── System.ets               # System 抽象基类 + SystemContext
│       ├── Scene.ets                # Scene 基类 + BaseContext + InputState
│       ├── SceneManager.ets         # 场景栈管理 (push/pop/replace)
│       ├── SpatialGrid.ets          # 空间哈希网格 (碰撞查询加速)
│       ├── ResourceManager.ets      # 异步资源加载 + 精灵表切片
│       └── index.ets                # 模块统一导出
│
├── entry/                           # 游戏入口模块 (HAP)
│   └── src/main/ets/
│       ├── entryability/
│       │   └── EntryAbility.ets     # Ability 入口
│       ├── pages/
│       │   ├── Index.ets            # 游戏主页面 (Canvas + HUD + 触控)
│       │   ├── LoginPage.ets        # 登录页
│       │   ├── CharacterSelectPage.ets
│       │   └── overlays/            # 弹窗覆盖层
│       └── game/
│           ├── GameScene.ets        # 游戏场景 (装配 World/Systems/Renderers)
│           ├── GameConstants.ets    # 常量 + 枚举 + 接口定义
│           ├── WorldGenerator.ets   # 程序化世界生成
│           ├── PhysicsEngine.ets    # 物理/碰撞工具
│           ├── ParticleSystem.ets   # 粒子管理
│           ├── AudioManager.ets     # 音频合成服务
│           ├── SaveManager.ets      # 存档读写
│           ├── components/          # 游戏专用组件 (21 个)
│           ├── systems/             # 游戏系统 (25 个)
│           ├── factories/           # 实体工厂 (5 个)
│           ├── renderers/           # 渲染器 (10 个)
│           ├── sprites/             # 程序化精灵生成 (10 个)
│           ├── helpers/             # 系统辅助函数
│           └── interfaces/          # 服务接口
│
├── tools/spritegen/                 # 离线精灵表生成工具
│   ├── generate.js                  # 将 .ets 生成器转译并渲染为 PNG
│   └── README.md
│
├── docs/                            # 设计文档
└── design/                          # 设计资源
```

---

## 5. Engine 模块（通用 ECS 引擎）

引擎以 HAR 形式发布，通过 `@qiuyu/engine` 引入。它只提供框架，不包含任何游戏逻辑。

### 5.1 `Engine` — 引擎入口与主循环

**文件**：`Engine/src/main/ets/Engine.ets`

**职责**：
- 持有游戏画布上下文（主画布 + 小地图画布）
- 管理游戏主循环（`setInterval` 驱动 `tick()` + `render()`）
- 管理输入状态（摇杆、跳跃、攻击、冲刺、工具）
- 持有 `SceneManager` 和 `ResourceManager`

**关键属性**：

| 属性 | 类型 | 说明 |
|------|------|------|
| `sceneManager` | `SceneManager` | 场景管理器 |
| `resources` | `ResourceManager` | 资源管理器 |
| `ctx` / `minimapCtx` | `CanvasRenderingContext2D` | 主/小地图画布 |
| `input` | `InputState` | 当前输入状态 |
| `tickInterval` | `number` | 帧间隔（默认 33ms ≈ 30fps） |

**关键方法**：

| 方法 | 说明 |
|------|------|
| `init(ctx, minimapCtx, w, h)` | 初始化画布并启动主循环 |
| `startLoop()` / `stop()` | 启动/停止主循环 |
| `tick(dt)` | 推进一帧逻辑（update） |
| `render()` | 渲染一帧 |
| `setInputJoy/Attack/Jump/Dash/Tool(...)` | 输入设置接口 |

### 5.2 `World` — 实体与系统调度

**文件**：`Engine/src/main/ets/World.ets`

**职责**：
- 维护实体列表 `entities: Entity[]`
- 维护系统列表 `systems: System[]`
- 维护区块数据 `chunks: Map<string, Object>`
- 维护世界生成器 `worldGen`
- 维护相机坐标 `cameraX` / `cameraY`
- 每帧按注册顺序依次调用所有启用的 `System.update()`

**关键方法**：

| 方法 | 说明 |
|------|------|
| `addEntity(entity)` | 添加实体 |
| `removeEntity(entity)` | 标记实体为非活跃（帧末清理） |
| `addSystem(system)` | 注册系统（顺序敏感） |
| `query(componentType)` | 按组件类型查询活跃实体 |
| `queryWithTag(tag)` | 按 tag 查询 |
| `findEntityByTag(tag)` | 查找首个匹配 tag 的实体 |
| `rebuildSpatialGrid()` | 重建空间索引 |
| `update(context, dt)` | 依次执行所有系统并清理死亡实体 |

### 5.3 `Entity` — 实体

**文件**：`Engine/src/main/ets/Entity.ets`

**职责**：作为组件的容器，通过 `tag` 标识实体类型。

```typescript
class Entity {
  readonly id: number;        // 自增唯一 ID
  tag: string;                // 实体标识（"player"/"camera"/"gameState" 等）
  active: boolean;            // 是否活跃（false 表示待清理）
  addComponent<T>(c: T): T    // 添加组件，key 为 getType()
  getComponent<T>(type): T|null
  hasComponent(type): boolean
}
```

### 5.4 `Component` — 组件

**文件**：`Engine/src/main/ets/Component.ets`

引擎内置基础组件：

| 组件 | 字段 | 用途 |
|------|------|------|
| `PositionComponent` | `x, y` | 世界坐标 |
| `VelocityComponent` | `vx, vy` | 速度 |
| `HealthComponent` | `current, max` | 生命值，含 `isDead()/damage()/heal()` |
| `SpriteComponent` | `color, width, height, visible` | 精灵外观 |
| `ColliderComponent` | `width, height, offsetX, offsetY, isSolid` | 碰撞盒 |

还定义了 `Serializable` 接口（`serialize()`/`deserialize()`），游戏组件实现此接口以支持存档。

### 5.5 `System` — 系统

**文件**：`Engine/src/main/ets/System.ets`

```typescript
abstract class System {
  protected enabled: boolean;
  isEnabled(): boolean;
  setEnabled(enabled: boolean): void;
  abstract update(entities: Entity[], context: SystemContext): void;
}

interface SystemContext {
  world: World;
  screenW, screenH: number;
  input: InputState;
  audio: Object;
  frameCount: number;
  dt: number;
}
```

每个游戏系统继承 `System` 并实现 `update()`，通过 `context.world` 查询/操作实体。

### 5.6 `Scene` / `SceneManager` — 场景管理

**文件**：`Scene.ets`, `SceneManager.ets`

- `Scene`：抽象场景基类，定义 `update(baseCtx, dt)` 和 `render(baseCtx)` 生命周期方法。
- `SceneManager`：维护场景栈，支持 `pushScene`/`popScene`/`replaceScene`，只更新和渲染栈顶（active）场景。

### 5.7 `SpatialGrid<T>` — 空间哈希网格

**文件**：`SpatialGrid.ets`

用于加速空间查询（碰撞检测、AI 感知）。将世界划分为固定大小（默认 128px）的网格单元。

| 方法 | 说明 |
|------|------|
| `insert(x, y, item)` | 插入实体到对应网格 |
| `queryRadius(cx, cy, radius)` | 圆形范围查询 |
| `queryRect(x, y, w, h)` | 矩形范围查询 |
| `clear()` | 清空所有网格 |

### 5.8 `ResourceManager` — 资源管理

**文件**：`ResourceManager.ets`

提供异步图片和精灵表加载，带缓存。使用 `RawFileProvider` 接口解耦平台文件访问。

> **注意**：当前游戏实际使用 `entry` 中的 `SpriteManager` 进行精灵加载，引擎的 `ResourceManager` 未被业务层调用。

---

## 6. Entry 游戏模块

### 6.1 `GameScene` — 游戏场景中枢

**文件**：`entry/src/main/ets/game/GameScene.ets`

游戏的核心装配类，继承 `Scene`。负责：
- 创建 `World` 和 `WorldGenerator`
- 预加载出生区块 `(0,0)`
- 通过工厂创建玩家、相机、游戏状态等单例实体
- 按执行顺序注册全部系统
- 持有所有渲染器并在 `render()` 中按层绘制
- 持有 `SpriteManager` 进行精灵生成

**系统注册顺序**（执行顺序即更新顺序）：

| # | 系统 | 职责 |
|---|------|------|
| 1 | `SpatialRebuildSystem` | 重建空间索引 |
| 2 | `ChunkLoadSystem` | 区块加载/卸载 |
| 3 | `MonsterLevelSystem` | 怪物等级缩放 |
| 4 | `HumanoidBeastSystem` | 拟人兽 AI |
| 5 | `PlayerMovementSystem` | 玩家移动/跳跃/冲刺/钻孔 |
| 6 | `PlayerCombatSystem` | 攻击判定/武器形态 |
| 7 | `DevourSystem` | 吞噬技能 |
| 8 | `SkillSystem` | 技能释放 |
| 9 | `EnemyAISystem` | 6 种史莱姆 AI |
| 10 | `BossSystem` | Boss AI + 阶段切换 |
| 11 | `TransformSystem` | 变身逻辑 |
| 12 | `HumanFormSystem` | 人类形态 |
| 13 | `TrapSystem` | 陷阱伤害 |
| 14 | `MechanismSystem` | 机关交互 |
| 15 | `ChestSystem` | 开箱 |
| 16 | `MaterialDropSystem` | 材料拾取 |
| 17 | `XpLevelSystem` | 经验升级 |
| 18 | `DamageSystem` | 死亡检测 |
| 19 | `EvolutionSystem` | 武器进化 |
| 20 | `PassiveTreeSystem` | 被动天赋 |
| 21 | `CameraSystem` | 相机跟随 + 震动 |
| 22 | `ParticleSystem` | 粒子实体更新 |
| 23 | `AmbientParticleSystem` | 环境粒子 |
| 24 | `SaveLoadSystem` | 自动存档 |
| 25 | `CleanupSystem` | 清理死亡实体 |

**渲染层级**（`render()` 中依次绘制）：

1. `TileRenderer` — 地形瓦片
2. `EffectRenderer.renderLighting` — 光照
3. `EnemyRenderer` — 敌人
4. `EffectRenderer.render` — 特效
5. `BossRenderer` — Boss
6. `PlayerRenderer` — 玩家
7. `EffectRenderer.renderVignetteAndDamage` — 暗角/伤害闪屏
8. `UIRenderer.renderHUD` — HUD
9. `UIRenderer.renderMinimap` — 小地图

每个渲染器调用都用 `try/catch` 隔离，单渲染器异常不影响整体画面。

### 6.2 `GameConstants` — 常量与类型

**文件**：`entry/src/main/ets/game/GameConstants.ets`

集中定义所有游戏常量、枚举和接口。主要枚举：

| 枚举 | 值 | 说明 |
|------|-----|------|
| `TileType` | 0-9 | 瓦片类型（墙/地板/水/熔岩/水晶...） |
| `EnemyType` | 0-6 | 敌人类型（6 史莱姆 + 拟人兽） |
| `BossType` | 0-4 | Boss 类型 |
| `WeaponForm` | 0-5 | 武器形态（刃/鞭/锤/杖/双刃/巨斧） |
| `EvolutionBranch` | 0-4 | 进化路线（水晶/火焰/暗影/毒素/潮汐） |
| `TransformForm` | -1~3 | 变身形态 |
| `TrapType` / `MechanismType` | 0-5 | 陷阱/机关类型 |
| `GameState` | 0-3 | 游戏状态（加载/游戏中/暂停/结束） |
| `SkillFamily` | 0-5 | 技能系（弹跳/腐蚀/火/冰/雷/虚空） |

### 6.3 组件 (Components)

位于 `entry/src/main/ets/game/components/`，共 21 个游戏组件，均实现引擎的 `Component` 接口（通过 `getType()` 返回字符串标识）。

| 组件 | getType | 职责 |
|------|---------|------|
| `MovementComponent` | `movement` | 玩家移动状态（跳跃/冲刺/钻孔/被吞噬） |
| `CombatComponent` | `combat` | 战斗状态（攻击计时/冷却/无敌帧） |
| `TransformComponent` | `transform` | 变身状态（形态/能量/冷却/当前武器） |
| `InventoryComponent` | `inventory` | 背包（矿石/核心/变身核心） |
| `XpComponent` | `xp` | 经验与等级 |
| `EvolutionComponent` | `evolution` | 武器进化（分支/等级/解锁形态） |
| `LevelComponent` | `level` | 等级相关属性 |
| `SkillComponent` | `skill` | 技能槽与技能经验 |
| `DevourComponent` | `devour` | 吞噬状态 |
| `HumanFormComponent` | `humanForm` | 人类形态阶段与能量 |
| `EnemyAIComponent` | `enemyAI` | 敌人 AI 状态 |
| `BossAIComponent` | `bossAI` | Boss AI 状态（阶段/特殊技能） |
| `CameraComponent` | (camera 实体) | 相机参数 |
| `GameStateComponent` | `gameState` | 全局游戏状态 |
| `TrapComponent` | `trap` | 陷阱实例 |
| `MechanismComponent` | `mechanism` | 机关实例 |
| `ChestComponent` | `chest` | 宝箱 |
| `ParticleComponent` | `particle` | 粒子 |
| `XpPickupComponent` | `xpPickup` | 经验球拾取 |
| `MaterialPickupComponent` | `materialPickup` | 材料拾取 |
| `TransformCorePickupComponent` | `transformCorePickup` | 变身核心拾取 |

### 6.4 工厂 (Factories)

位于 `factories/`，负责创建带完整组件的实体。

| 工厂 | 方法 | 职责 |
|------|------|------|
| `PlayerFactory` | `create(x, y)` | 创建玩家实体（含 Position/Velocity/Health/Movement/Combat/Transform/Inventory/Xp/Evolution/Collider/Level/Skill/Devour/HumanForm） |
| `EnemyFactory` | `create(type, x, y, level)` | 创建敌人实体 |
| `BossFactory` | `create(type, x, y, role)` | 创建 Boss 实体 |
| `DropFactory` | `createXpOrb` / `createMaterial` / `createTransformCore` | 创建掉落物 |
| `WorldEntityFactory` | `createTrap` / `createMechanism` / `createChest` | 创建世界交互实体 |

### 6.5 渲染器 (Renderers)

位于 `renderers/`，从 `World` 查询实体并绘制到 Canvas。

| 渲染器 | 职责 |
|--------|------|
| `TileRenderer` | 绘制可见区块的地形瓦片 |
| `EffectRenderer` | 光照、粒子特效、暗角、伤害闪屏 |
| `EnemyRenderer` | 绘制敌人（使用 SpriteManager 的精灵表） |
| `BossRenderer` | 绘制 Boss 及血条 |
| `PlayerRenderer` | 绘制玩家（人形/史莱姆形态） |
| `BossFormsRenderer` | Boss 形态渲染 |
| `ChestRenderer` | 宝箱 |
| `TrapRenderer` | 陷阱 |
| `WeaponRenderer` | 武器 |
| `TransformFormRenderer` | 变身形态 |
| `UIRenderer` | HUD（血条/经验/技能）和小地图 |

### 6.6 精灵系统 (Sprites)

位于 `sprites/`，提供程序化精灵生成 + 外部 PNG 精灵表加载。

| 文件 | 职责 |
|------|------|
| `SpriteManager` | 精灵总管：调用生成器生成程序化精灵，并尝试用 rawfile PNG 覆盖 |
| `SpriteAtlas` | 精灵图集（按网格切帧） |
| `SpriteCache` | 精灵缓存（key → ImageBitmap） |
| `EnemySpriteGenerator` | 生成敌人精灵图集 |
| `BossSpriteGenerator` | 生成 Boss 精灵图集 |
| `PlayerSpriteGenerator` | 生成玩家人形精灵缓存 |
| `PlayerSlimeSprite` | 玩家史莱姆形态绘制 |
| `HumanoidBeastSprite` | 拟人兽绘制 |
| `WeaponSprite` | 武器图标绘制 |
| `AttackFxSprite` | 攻击特效绘制 |
| `ColorUtils` | 颜色工具 |

**SpriteManager 工作流程**：
1. `generateAll(harmonyContext)` — 先用 `OffscreenCanvas` 程序化生成所有精灵（enemy/boss/player）
2. 若提供了 `harmonyContext`，调用 `overlayExternalSheets()` 尝试从 `rawfile/sprites/` 加载 PNG 覆盖
3. PNG 加载失败时静默回退到程序化版本

### 6.7 辅助服务

| 文件 | 职责 |
|------|------|
| `AudioManager` | 程序化音效合成（AudioRenderer 池化） |
| `SaveManager` | 存档读写（Preferences） |
| `WorldGenerator` | 程序化地牢生成（噪声 + 生物群落） |
| `PhysicsEngine` | 碰撞检测与解析 |
| `ParticleSystem` | 粒子发射与更新 |
| `helpers/SystemHelpers` | 系统共用工具（震动/伤害闪屏/瓦片查询） |

---

## 7. 页面层

### 7.1 `Index` — 游戏主页面

**文件**：`entry/src/main/ets/pages/Index.ets`

游戏运行时的主页面，使用 ArkUI 声明式布局叠加在 Canvas 之上。

**核心职责**：
- 承载主游戏 Canvas 和小地图 Canvas
- 等待两个 Canvas `onReady` 后初始化引擎
- 处理触控输入（摇杆、攻击、跳跃、冲刺、工具）
- 通过 `setInterval` 轮询 World 状态并更新 UI（血条/经验/背包/变身）
- 管理弹窗（设置/进化/暂停/游戏结束/存档提示）

**初始化流程**：
1. Canvas `onReady` → `tryInitEngine()`
2. 两个 Canvas 都就绪后：
   - 创建 `GameScene(audio, settings, harmonyContext)`
   - `engine.sceneManager.pushScene(gameScene)`
   - `engine.init(ctx, minimapCtx, screenW, screenH)` — 启动主循环
   - `gameScene.initSprites()` — 异步生成精灵
   - 若为存档模式，`SaveManager.load()` 加载存档

### 7.2 其他页面

| 页面 | 职责 |
|------|------|
| `LoginPage` | 登录页 |
| `CharacterSelectPage` | 角色选择 |

### 7.3 覆盖层 (Overlays)

位于 `pages/overlays/`：

| 覆盖层 | 职责 |
|--------|------|
| `SettingsOverlay` | 游戏设置（音效/特效） |
| `EvolutionOverlay` | 武器进化面板 |
| `PauseMenuOverlay` | 暂停菜单（继续/读档） |
| `GameOverOverlay` | 游戏结束（重来/读档/退出） |
| `SaveIndicator` | 存档提示动画 |

---

## 8. 依赖关系

### 8.1 模块依赖

```
entry (HAP)
  └── @qiuyu/engine (file:../Engine)   # HAR 本地依赖

Engine (HAR)
  └── (无外部依赖)
```

### 8.2 内部依赖方向

```
Pages ──▶ GameScene ──▶ World ──▶ System[] ──▶ Entity + Component[]
  │           │
  │           ├─▶ Renderers ──▶ SpriteManager
  │           ├─▶ Factories ──▶ Entity + Component[]
  │           └─▶ SpriteManager ──▶ SpriteGenerator[]
  │
  └─▶ Engine (SceneManager/ResourceManager)
```

**依赖原则**：
- 游戏层依赖引擎层，引擎层不依赖游戏层
- 系统通过 `SystemContext.world` 访问实体，不直接相互引用
- 渲染器只读 World 状态，不修改游戏逻辑

---

## 9. 核心数据流：游戏主循环

```
setInterval (33ms)
  │
  ├─ Engine.tick(dt)
  │    └─ SceneManager.update(baseCtx, dt)
  │         └─ GameScene.update(baseCtx, dt)
  │              └─ World.update(sysCtx, dt)
  │                   ├─ for each enabled System: sys.update(entities, ctx)
  │                   └─ filter out inactive entities
  │
  └─ Engine.render()
       └─ SceneManager.render(baseCtx)
            └─ GameScene.render(baseCtx)
                 ├─ TileRenderer.render()
                 ├─ EffectRenderer.renderLighting()
                 ├─ EnemyRenderer.render()
                 ├─ EffectRenderer.render()
                 ├─ BossRenderer.render()
                 ├─ PlayerRenderer.render()
                 ├─ EffectRenderer.renderVignetteAndDamage()
                 ├─ UIRenderer.renderHUD()
                 └─ UIRenderer.renderMinimap()
```

**输入流**：触控事件 → `engine.setInputXxx()` → `Engine.input` → `BaseContext.input` → `SystemContext.input` → 各系统读取。

**状态同步流**：World 状态 → `startStatusMonitor` (100ms 轮询) → ArkUI `@State` → UI 重绘。

---

## 10. 项目运行方式

### 10.1 环境要求

- DevEco Studio 5.0+
- HarmonyOS SDK 5.0.0 (API 12+)
- HarmonyOS 设备或模拟器（手机/平板）

### 10.2 构建与运行

**方式一：DevEco Studio**
1. 用 DevEco Studio 打开项目根目录
2. 等待依赖同步（oh-package）完成
3. 连接设备或启动模拟器
4. 点击 Run（▶）

**方式二：命令行**
```bash
# 构建整个项目 HAP
hvigorw assembleHap --no-daemon

# 单独构建 Engine HAR
cd Engine
hvigorw assembleHar --no-daemon
```

### 10.3 精灵资源（重新生成 PNG）

`rawfile/sprites/` 下的 PNG 由 `tools/spritegen/generate.js` 从 `.ets` 生成器代码离线渲染得到，与游戏内程序化绘制逐像素同源。

```bash
cd tools/spritegen
npm install       # 首次运行安装 @napi-rs/canvas + typescript
npm run generate  # 或 node generate.js
```

生成产物会写入 `entry/src/main/resources/rawfile/sprites/`，并在 `tools/spritegen/preview.html` 生成可视化预览。

> **注意**：PNG 精灵表是可选优化。即使缺失或解码失败，游戏也会回退到 `OffscreenCanvas` 程序化绘制。

---

## 11. 精灵资源生成管线

```
.ets 生成器源码 (sprites/*.ets)
        │
        ▼  tools/spritegen/generate.js
   TypeScript 转译 → CommonJS
        │
        ▼  @napi-rs/canvas (OffscreenCanvas 垫片)
   调用 generateEnemyAtlas / generateBossAtlas / generatePlayerCache
        │
        ▼  canvas.toBuffer('image/png')
   rawfile/sprites/*.png
        │
        ▼  打包进 HAP
   运行时 SpriteManager.overlayExternalSheets()
        │
        ├─ 成功 → 用 PNG 覆盖程序化精灵
        └─ 失败 → 保留程序化精灵（兜底）
```

---

## 12. 已知问题与修复记录

### 12.1 [已修复] 精灵表图片解码失败 `image decode error, ret:[62980118]`

**现象**：运行时日志大量出现：
```
C02b60/Plugin  failed to get export symbol for the plugin.
C02b61/ImageSource  [ImageSource]image decode error, ret:[62980118].
```
错误码 `62980118` 对应 `IMAGE_DATA_ABNORMAL`（图片数据异常）。

**根因**：`SpriteManager.decodeRawImage()` 通过 `getRawFileDescriptor` 获取文件描述符后，用 `fileIo.readSync(descriptor.fd, buffer)` 读取数据，但未使用 `descriptor.offset`。当 rawfile 被打包进 HAP 时，fd 指向 HAP 包内偏移位置，直接从偏移 0 读取会读到错误数据，写入缓存文件后解码器无法识别。

**修复**：改用 `ctx.resourceManager.getRawFileContent(filePath)` 直接获取完整的 `ArrayBuffer`，并通过 `image.createImageSource(buffer)` 直接从内存解码，省去缓存文件拷贝。

**修改文件**：`entry/src/main/ets/game/sprites/SpriteManager.ets`
- `decodeRawImage()` 简化为 3 行（getRawFileContent → createPixelMap → release）
- 移除不再使用的 `@kit.CoreFileKit` (fileIo) 导入

### 12.2 日志中可忽略的系统级错误

以下错误来自 HarmonyOS 系统服务，非应用 bug，可忽略：

| 日志 | 来源 | 说明 |
|------|------|------|
| `CONCUR task xxx apply qos failed, errno = 4` | 系统调度 | QoS 调度失败，不影响功能 |
| `WMS SetWindowType: permission denied!` | 窗口管理 | 权限提示，模拟器常见 |
| `Ace ERROR EACCES` | 渲染框架 | 系统资源访问，不影响应用 |
| `ResourceManager ref <private> id not found` | 资源管理 | 系统资源引用，非应用资源 |

---

*文档版本：2026-10-01*
