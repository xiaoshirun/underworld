# 地下世界 (Underworld)

一款 HarmonyOS 像素风格地下探索游戏。

## 游戏特色

- **自由探索**：无任务系统，玩家驱动的进度
- **变形系统**：4 种形态（史莱姆、幽灵、铠甲、钢铁侠）
- **能量系统**：通过击败 Boss 获取核心，解锁新能力
- **程序化世界**：基于区块的随机生成地图

## 技术栈

- **平台**：HarmonyOS
- **语言**：ArkTS / ArkUI
- **渲染**：Canvas 2D
- **世界生成**：Chunk-based 程序化生成

## 构建

### Debug 构建（IDE）

在 DevEco Studio 中直接点击 Run，使用自动生成的调试签名。

### Release 构建（命令行）

```bash
./build-release.sh
```

输出文件：`build/outputs/default/Game-release-signed.app`

## 签名配置

- **Debug**：DevEco Studio 自动生成（`C:\Users\QiuQiu\.ohos\config\`）
- **Release**：使用 `hap-sign-tool` 直接签名（hvigor SignHap 不兼容）
  - 证书：`entry/signature/resl/xsr.cer`
  - 私钥：`entry/signature/resl/xsr_original.p12`
  - Profile：`entry/signature/resl/xsrRelease.p7b`

## 包名

`com.xsr.underworld`

## 发布

华为应用市场（AppGallery Connect）
