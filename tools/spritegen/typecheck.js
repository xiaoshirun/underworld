'use strict';

/**
 * typecheck.js — 真类型检查（语法诊断之外）改动过的游戏源码。
 *
 * 用 TypeScript 编译器对 sprites/renderers 相关文件做 noEmit 检查，
 * 重点捕捉：Canvas/OffscreenCanvas 上下文类型混用、联合类型参数、
 * 共享模块签名漂移。外部模块（@qiuyu/engine、@kit.* 等）解析失败
 * 以 TS2307 报告，默认过滤（本地无 HarmonyOS SDK），保留其余全部诊断。
 *
 * 用法：node typecheck.js        （过滤外部模块噪音）
 *       node typecheck.js --all  （不过滤）
 */

const ts = require('typescript');
const path = require('path');

const FILES = [
  '../../entry/src/main/ets/game/sprites/ColorUtils.ets',
  '../../entry/src/main/ets/game/sprites/PlayerSlimeSprite.ets',
  '../../entry/src/main/ets/game/sprites/HumanoidBeastSprite.ets',
  '../../entry/src/main/ets/game/sprites/WeaponSprite.ets',
  '../../entry/src/main/ets/game/sprites/AttackFxSprite.ets',
  '../../entry/src/main/ets/game/sprites/EnemySpriteGenerator.ets',
  '../../entry/src/main/ets/game/sprites/PlayerSpriteGenerator.ets',
  '../../entry/src/main/ets/game/sprites/SpriteManager.ets',
  '../../entry/src/main/ets/game/renderers/PlayerRenderer.ets',
  '../../entry/src/main/ets/game/renderers/EnemyRenderer.ets',
  '../../entry/src/main/ets/game/renderers/WeaponRenderer.ets',
  '../../entry/src/main/ets/game/GameScene.ets',
  '../../entry/src/main/ets/game/systems/PlayerMovementSystem.ets',
  '../../entry/src/main/ets/game/systems/ChunkLoadSystem.ets',
  '../../entry/src/main/ets/pages/Index.ets',
  '../../Engine/src/main/ets/Engine.ets',
  '../../Engine/src/main/ets/World.ets'
].map((f) => path.resolve(__dirname, f));

const filterExternal = !process.argv.includes('--all');

const program = ts.createProgram(FILES, {
  noEmit: true,
  strict: false,
  target: ts.ScriptTarget.ES2020,
  module: ts.ModuleKind.ES2020,
  moduleResolution: ts.ModuleResolutionKind.NodeJs,
  skipLibCheck: true,
  lib: ['lib.dom.d.ts', 'lib.es2020.d.ts']
});

const wanted = new Set(FILES.map((f) => f.replace(/\\/g, '/')));
const diags = ts
  .getPreEmitDiagnostics(program)
  .filter((d) => d.file && wanted.has(d.file.fileName.replace(/\\/g, '/')))
  .filter((d) => (filterExternal ? d.code !== 2307 : true));

let externalSkipped = 0;
if (filterExternal) {
  externalSkipped = ts
    .getPreEmitDiagnostics(program)
    .filter((d) => d.file && wanted.has(d.file.fileName.replace(/\\/g, '/')))
    .filter((d) => d.code === 2307).length;
}

if (diags.length === 0) {
  console.log('TYPECHECK OK (' + FILES.length + ' files' +
    (filterExternal ? ', skipped ' + externalSkipped + ' external-module TS2307' : '') + ')');
  process.exit(0);
}

for (const d of diags) {
  const pos = d.file.getLineAndCharacterOfPosition(d.start);
  console.log(path.basename(d.file.fileName) + ':' + (pos.line + 1) +
    ' TS' + d.code + ' ' + ts.flattenDiagnosticMessageText(d.messageText, ' ').slice(0, 200));
}
console.log('---');
console.log(diags.length + ' diagnostic(s)' + (filterExternal ? ', external TS2307 skipped: ' + externalSkipped : ''));
process.exit(1);
