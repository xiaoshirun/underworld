# Run Doc — Preview

本项目是 HarmonyOS ArkTS 原生应用（DevEco/hvigor），仓库内没有 hvigorw CLI，**无法运行浏览器 dev server**。
线程预览使用的是 spritegen 工具产出的**自包含静态 HTML**（base64 内嵌全部 16 张精灵图表，无外部依赖、无端口）。

## 预览模式

- 文件：`tools/spritegen/preview.html`（独立 HTML，`register_preview(htmlPath=...)` 直接注册）
- 内容：玩家/玩家史莱姆/敌人 ×7/Boss ×5/武器/攻击特效的生成结果可视化

## 如何复现产物（artifacts）

```bash
cd tools/spritegen
npm install          # 首次；依赖 typescript@5 + @napi-rs/canvas（Node ≥18）
npm run generate     # 转译游戏 .ets 绘制源码 → 渲染 PNG 到 entry/src/main/resources/rawfile/sprites/（16 张）
                     #   并重新生成 tools/spritegen/preview.html（base64 内嵌最新素材）
node typecheck.js    # 对改动的游戏源码做真类型检查（可选）
```

注：`npm run generate` 会同时刷新 `rawfile/sprites/*.png` 与 `preview.html`，两者永远同源。

## 如何“运行”预览

无需启动任何进程。在新线程里调用 `register_preview`：

- `htmlPath`: `<repo>\tools\spritegen\preview.html`（绝对路径）

注册后页面出现在 Preview tab；修改 `preview.html` 后重载预览即可看到更新。
