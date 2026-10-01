# Task 15: Texture Pipeline (纹理管线)

## Status
**Completed**

## Summary
Wired up real native GPU texture IDs so that all sprite renderers use actual textures uploaded to OpenGL ES instead of the placeholder `textureId: 0`. A new raw-RGBA upload path was added through the NAPI bridge, and SpriteManager now owns the texture-ID lifecycle for every atlas type.

## Changes

### C++ / NAPI layer (3 files)
| File | Change |
|------|--------|
| `napi_bridge.h` | Declared `NativeLoadTextureRaw` |
| `napi_bridge.cpp` | Implemented `NativeLoadTextureRaw` — accepts `(textureId, width, height, ArrayBuffer)`, copies RGBA pixels, calls `Renderer::loadTexture` |
| `napi_init.cpp` | Registered `"nativeLoadTextureRaw"` in the NAPI property table |

### ArkTS bridge (1 file)
| File | Change |
|------|--------|
| `NativeRenderer.ets` | Added `loadTextureRaw(textureId, rgbaBuffer, width, height)` method |

### Sprite system (2 files)
| File | Change |
|------|--------|
| `SpriteAtlas.ets` | Added `textureId: number = 0` field |
| `SpriteManager.ets` | Major additions: `setNativeRenderer()`, `uploadNativeTextures()`, `generatePlaceholderPixels()`, `setAtlasTextureId()`, `getPlayerCacheFrameSrc()`, and six texture-ID getters. `generateAll()` now calls `uploadNativeTextures()` at the end. |

### Renderers (3 files)
| File | Change |
|------|--------|
| `EnemyRenderer.ets` | `pushSprite(0, ...)` → `pushSprite(sm.getEnemyAtlasTextureId(), ...)` |
| `BossRenderer.ets` | `pushSprite(0, ...)` → `pushSprite(sm.getBossAtlasTextureId(), ...)` |
| `PlayerRenderer.ets` | Player slime → `getPlayerSlimeAtlasTextureId()`; human form → `getPlayerCacheTextureId()` with computed `srcX/srcY` |

### Scene / page wiring (2 files)
| File | Change |
|------|--------|
| `GameScene.ets` | `initSprites(nativeRenderer?)` now passes NativeRenderer to SpriteManager |
| `Index.ets` | Passes `this.nativeRenderer` to `initSprites()` in both initial setup and `restartGame()` |

## Design Decisions

### Raw RGBA upload vs PNG encoding
The existing `NativeRenderer.loadTexture()` path expects a PNG buffer decoded by stb_image on the C++ side. Generating valid PNGs in ArkTS would require implementing CRC32 and deflate. Instead, a new `loadTextureRaw` path was added that passes raw RGBA pixels directly through NAPI, matching the `Renderer::loadTexture(textureId, pixels, w, h)` signature already present in C++.

### Placeholder textures
Each atlas type gets a distinctive color so rendering issues are visually debuggable:
- Enemies: red-orange `(220, 80, 60)`
- Bosses: purple `(160, 60, 200)`
- Player slime: blue `(60, 120, 220)`
- Weapons: silver `(180, 180, 190)`
- Attack FX: yellow-orange `(240, 180, 40)`
- Player cache: green `(60, 200, 120)`

Each placeholder includes a soft vignette gradient for visual distinction.

### Texture ID allocation
IDs are allocated sequentially starting from 1 (0 is reserved as "no texture" / default). Each atlas type gets one native texture.

## Verification
- `grep` confirms zero remaining `pushSprite(0,` calls — all sprite draws now use real texture IDs.
- 11 files modified, 230 insertions, 7 deletions.
