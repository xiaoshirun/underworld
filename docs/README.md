# 设计文档索引

本项目的设计文档按时间顺序组织，分为设计规格 (specs) 和实现计划 (plans) 两类。

## 文档列表

### 第一阶段：功能扩展设计 (2026-09-27)

| 文档 | 类型 | 描述 |
|------|------|------|
| [武器进化扩展设计](superpowers/specs/2026-09-27-weapon-evolution-expansion-design.md) | 设计规格 | 武器形态系统 (6 形态)、陷阱/机关系统 (6+6 种)、5 Boss、3 级宝箱、暗影生物群落 |
| [武器进化扩展计划](superpowers/plans/2026-09-27-weapon-evolution-expansion.md) | 实现计划 | 上述设计的分步实现计划 |
| [变身系统设计](superpowers/specs/2026-09-27-transformation-system-design.md) | 设计规格 | 变身系统 (4 种形态)、能量管理、Boss 解锁机制 |
| [变身系统计划](superpowers/plans/2026-09-27-transformation-system.md) | 实现计划 | 上述设计的分步实现计划 |

### 第二阶段：ECS 引擎架构 (2026-09-28 ~ 09-30)

| 文档 | 类型 | 描述 |
|------|------|------|
| [ECS 引擎设计](superpowers/specs/2026-09-28-ecs-engine-design.md) | 设计规格 | 从单体 GameEngine 提取为可复用 ECS 框架：Entity/Component/System、场景管理、资源管理、6 个内置系统 |
| [ECS 引擎计划](superpowers/plans/2026-09-28-ecs-engine.md) | 实现计划 | 4 阶段迁移计划：引擎骨架 → 模块迁移 → 逻辑拆分 → UI 适配 |
| [ECS 实际化设计](superpowers/specs/2026-09-30-ecs-actualization-design.md) | 设计规格 | 全面重写：消除 GameContext 上帝对象，17 个游戏组件、19 个系统、6 个渲染器、5 个实体工厂 |
| [ECS 实际化计划](superpowers/plans/2026-09-30-ecs-actualization.md) | 实现计划 | 15 步实现计划：Engine HAR 基础 → 组件 → 工厂 → 系统 → 渲染器 → GameScene → 入口改造 |

## 架构演进历程

```
初始阶段 (09-27)
  GameEngine.ets (6500+ 行单体) + GameContext 状态对象
  ↓
ECS 引擎提取 (09-28)
  Engine HAR (通用框架) + GameEngine (游戏逻辑)
  ↓
ECS 实际化 (09-30)
  Engine HAR + GameScene (World + 19 Systems + 6 Renderers)
  消除 GameContext/EngineBase/GameEngine，完全 ECS 化
```

## 文档约定

- **设计规格 (specs/)** — 描述"做什么"和"为什么"，包含接口定义、数据结构、架构图
- **实现计划 (plans/)** — 描述"怎么做"，包含分步任务、代码示例、文件清单
- 所有文档使用 Markdown 格式
- 代码示例使用 ArkTS 语法
