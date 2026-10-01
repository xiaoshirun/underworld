# Tasks 11-14: Rewrite All Game Renderers to DrawCmd

## Status: COMPLETED

## Summary

All remaining game renderers have been rewritten from Canvas 2D API (`render(ctx, ...)`) to DrawCmd-based native rendering (`collectCommands(world, buf, ...)`). The old `render()` methods are preserved for fallback (cleanup deferred to Task 19).

## Files Modified

### Task 11: ChestRenderer + TrapRenderer
- **`entry/src/main/ets/game/renderers/ChestRenderer.ets`** (+233 lines)
  - Added `collectCommands(world, buf, offX, offY, screenW, screenH, settings, frameCount)`
  - Handles CHEST, LOCKED_CHEST, TRAPPED_CHEST entity types
  - Converts: rect bodies, lid animations, lock icons, trap indicators, sparkle particles

- **`entry/src/main/ets/game/renderers/TrapRenderer.ets`** (+176 lines)
  - Added `collectCommands(world, buf, offX, offY, screenW, screenH, frameCount)`
  - Handles SPIKE_TRAP, POISON_DART, SWING_BLADE, FALLING_ROCK types
  - Converts: spike triangles, dart lines, blade arcs, rock circles

### Task 12: PlayerRenderer + WeaponRenderer + TransformFormRenderer
- **`entry/src/main/ets/game/renderers/PlayerRenderer.ets`** (+515 lines)
  - Added `collectCommands(world, buf, cameraX, cameraY, screenW, screenH, settings, frameCount, spriteManager)`
  - Delegates to `collectPlayerCommands` (shadow, body sprite/procedural, equipment, effects)
  - Integrates WeaponRenderer and TransformFormRenderer calls
  - Handles 5 evolution forms: SLIME, HUMANOID, ELEMENTAL, SHADOW, COSMIC

- **`entry/src/main/ets/game/renderers/WeaponRenderer.ets`** (+200 lines)
  - Added `collectWeaponOnPlayerCommands(buf, screenX, screenY, pc, bobY)` - weapon on player body
  - Added `collectAttackEffectCommands(buf, screenX, screenY, pc, bobY)` - swing arcs, thrust lines, projectile trails

- **`entry/src/main/ets/game/renderers/TransformFormRenderer.ets`** (+119 lines)
  - Added 5 form-specific methods: `collectSlimeCommands`, `collectHumanoidCommands`, `collectElementalCommands`, `collectShadowCommands`, `collectCosmicCommands`
  - Each converts procedural body, aura, and particle effects

### Task 13: EnemyRenderer + BossRenderer + BossFormsRenderer
- **`entry/src/main/ets/game/renderers/EnemyRenderer.ets`** (+537 lines net)
  - Added `collectCommands(world, buf, cameraX, cameraY, screenW, screenH, settings, frameCount, spriteManager)`
  - Handles all enemy types with sprite or procedural fallback
  - Converts: shadow, body, eyes, accessories, status effects, HP bars

- **`entry/src/main/ets/game/renderers/BossRenderer.ets`** (+541 lines)
  - Added `collectCommands` + 12 helper methods
  - Covers 5 boss types: CrystalGuardian, MushroomKing, LavaBeast, AbyssSiren, VoidRift
  - Each boss has unique procedural rendering (diamond bodies, spore particles, magma cracks, tentacles, void rings)
  - Added `collectMaterialDropsCommands` for ore/core drop entities

- **`entry/src/main/ets/game/renderers/BossFormsRenderer.ets`** (+296 lines)
  - Added 5 boss-form-specific `collectCommands` methods matching BossRenderer's boss types
  - Parallel conversion of BossFormsRenderer's procedural rendering

### Task 14: EffectRenderer + GameScene Registration
- **`entry/src/main/ets/game/renderers/EffectRenderer.ets`** (+261 lines)
  - Added 6 methods:
    - `collectCommands` - delegates to trapRenderer + mechanisms + chestRenderer
    - `collectLightingCommands` - darkness overlay, player glow, tile light sources
    - `collectVignetteCommands` - vignette, low HP overlay, damage flash
    - `collectParticlesCommands` - particle system rendering
    - `collectAmbientCommands` - ambient particle rendering
    - `collectMechanismsCommands` (private) - PRESSURE_PLATE, LEVER, PUSH_BLOCK, CRYSTAL_REFLECTOR, BREAKABLE_WALL, TELEPORT_RUNE

- **`entry/src/main/ets/game/GameScene.ets`** (+23 lines net)
  - Fixed DrawCmdBuffer import path (`'../native/DrawCmd'`)
  - Updated `collectCommands` to register all 7 renderer calls in correct render order:
    1. Tiles (tileRenderer)
    2. Lighting (effectRenderer.collectLightingCommands)
    3. Enemies (enemyRenderer)
    4. Traps/Mechanisms/Chests (effectRenderer.collectCommands)
    5. Bosses (bossRenderer)
    6. Player + Weapon + Transform (playerRenderer)
    7. Vignette + Damage Flash (effectRenderer.collectVignetteCommands)

## Conversion Patterns Applied

| Canvas 2D API | DrawCmd Equivalent |
|---|---|
| `fillRect(x,y,w,h)` | `buf.pushRect(x,y,w,h, r,g,b,a, rot, layer)` |
| `arc(cx,cy,r,0,2PI)` | `buf.pushCircle(cx,cy,r, r,g,b,a, layer)` |
| `drawImage(img,sx,sy,sw,sh,dx,dy,dw,dh)` | `buf.pushSprite(texId,dx,dy,dw,dh, sx,sy,sw,sh, r,g,b,a, rot,layer,flipX,flipY)` |
| `globalAlpha = x` | Multiply alpha into color: `a *= x` |
| `fillStyle = '#RRGGBB'` | `hexToRgb('#RRGGBB')` -> `{r,g,b}` |
| `save/translate/rotate` | Pre-compute rotated coordinates |
| `radialGradient` | Concentric `pushCircle` calls |
| `strokeRect` | 4 thin `pushRect` calls |
| `beginPath/moveTo/lineTo` (triangle) | `buf.pushTriangle(x1,y1,x2,y2,x3,y3, r,g,b,a, layer)` |
| `moveTo/lineTo` (line) | `buf.pushLine(x1,y1,x2,y2, thickness, r,g,b,a, layer)` |
| `ellipse` | Approximate with `pushCircle` |
| `quadraticCurveTo` | Approximate with `pushLine` segments |

## Key Design Decisions

1. **Sprite textureId = 0**: Placeholder until Task 15 wires real sprite atlas IDs
2. **Layer = 0**: All commands use game layer (layer parameter reserved for future UI/overlay separation)
3. **Old render() methods preserved**: Cleanup deferred to Task 19 when Canvas path is fully removed
4. **hexToRgb duplicated per file**: Each renderer has its own local `hexToRgb` function (no shared utility yet)
5. **Rotation pre-computed**: Instead of save/translate/rotate, all vertex positions are rotated mathematically before pushing

## Bugs Fixed During Implementation

- DrawCmdBuffer import path in GameScene: `'./native/DrawCmd'` -> `'../native/DrawCmd'`
- TrapRenderer argument order in EffectRenderer: reordered to match `(world, buf, offX, offY, ...)`
- ChestRenderer camera offset: use `offX/offY` (negated camera) not raw `cameraX/cameraY`
- PlayerRenderer missing weapon calls: added `weaponRenderer.collectWeaponOnPlayerCommands` and `collectAttackEffectCommands`
