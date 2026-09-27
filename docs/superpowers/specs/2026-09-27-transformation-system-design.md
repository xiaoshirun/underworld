# Transformation System (变身系统) - Design Specification

## Overview

This document specifies the transformation system — a late-game progression feature that lets players temporarily transform into powerful forms, each with completely unique abilities that replace all weapon attacks. The system rewards boss progression with new playstyles and adds strategic depth through energy management.

**Platform:** HarmonyOS ArkTS/ArkUI with Canvas-based game rendering
**Prerequisites:** Boss system (5 biome bosses), weapon system, player combat/movement states
**Architecture:** Approach A — State machine extension on existing PlayerState, all logic within GameEngine

---

## 1. Core Concept

### 1.1 Design Goals

- **Reward boss progression**: Defeating specific bosses unlocks their associated transformation form
- **Distinct playstyles**: Each form fundamentally changes how the player moves, attacks, and interacts with the world
- **Strategic resource management**: Limited energy forces thoughtful usage — transform at the right moment
- **Non-permanent power**: Transformation is temporary; weapons remain the player's core identity

### 1.2 Key Decisions

| Decision | Answer |
|----------|--------|
| Energy system | Rechargeable device; energy recovers by killing enemies and passively over time |
| Weapon interaction | Transformation **completely replaces** weapons during transformed state |
| Acquisition | Boss drops — defeat specific boss to unlock that form |
| Form count | 4 forms, all unlockable independently |
| Form switching | Multiple forms unlockable, switchable via UI selection panel |
| Duration | Energy depletes continuously; auto-reverts when energy reaches 0 |
| UI trigger | Independent transform button on screen; long-press opens form selection |

---

## 2. TransformForm Enum & Boss Mapping

### 2.1 Form Definitions

```typescript
export enum TransformForm {
  NONE = -1,      // Not transformed
  SLIME = 0,      // 史莱姆形态
  GHOST = 1,      // 幽灵形态
  ARMOR = 2,      // 铠甲勇士形态
  IRON_MAN = 3    // 钢铁侠形态
}
```

### 2.2 Boss-to-Form Mapping

| Boss | Biome | Drops Form | Form Core Item |
|------|-------|-----------|----------------|
| Mushroom King | MUSHROOM | SLIME | `transformCoreSlime` |
| Crystal Guardian | CRYSTAL | ARMOR | `transformCoreArmor` |
| Lava Beast | LAVA | IRON_MAN | `transformCoreIronMan` |
| Void Rift | SHADOW | GHOST | `transformCoreGhost` |
| Abyss Siren | WATER | (no form — drops other rewards) | — |

First defeat drops the form core (guaranteed). Subsequent defeats of the same boss do not drop additional cores. The form core is consumed on first acquisition to unlock the form permanently.

---

## 3. PlayerState Extensions

### 3.1 New Fields on PlayerState

```typescript
// Added to PlayerState interface
isTransformed: boolean;          // Currently in transformed state
transformForm: TransformForm;    // Active form (NONE when not transformed)
transformEnergy: number;         // Current energy (0 - transformMaxEnergy)
transformMaxEnergy: number;      // Max energy capacity (100)
transformCooldown: number;       // Cooldown timer after reverting (ms)
unlockedTransforms: number[];    // Array of unlocked TransformForm values
savedWeaponForm: WeaponForm;     // Weapon form saved on transform, restored on revert
```

### 3.2 Inventory Extension

```typescript
// Added to Inventory interface
transformCoreSlime: number;   // 0 or 1 (consumed on unlock)
transformCoreArmor: number;
transformCoreIronMan: number;
transformCoreGhost: number;
```

---

## 4. Form Abilities & Mechanics

### 4.1 Slime Form (史莱姆形态)

**Visual**: Player sprite replaced by a large green slime blob (larger than enemy slimes). Semi-transparent body with visible player eyes inside. Squash-and-stretch animation on movement.

**Movement**:
- Speed: 3.5 (slightly faster than normal 3.0)
- Jump height: 2x normal — high bouncy movement
- Can bounce off walls (reverses vx on wall contact)
- No dash; bouncing replaces dashing

**Attack — Split Shot**:
- Press attack: Player splits into 3 small slimes that shoot outward in facing direction
- Each small slime travels ~80px, deals 2 damage, then returns to player
- Cooldown: 600ms
- Energy cost: 3 per attack

**Passive — Damage Reduction**:
- Takes 30% less damage from all sources (slime body absorbs impact)

**Energy Drain**: 2.0 per second

### 4.2 Ghost Form (幽灵形态)

**Visual**: Player sprite rendered at 50% alpha with purple-blue tint. Flowing trail particles behind movement. Slight floating bob animation (always slightly airborne visually).

**Movement**:
- Speed: 2.8 (slightly slower)
- **Phase through walls**: Can move through WALL tiles (treated as FLOOR while transformed)
- No collision with walls — ghost drifts through
- Jump: Float upward instead of parabolic jump (reduced gravity)
- No dash

**Attack — Soul Shockwave**:
- Press attack: Expanding ring of ghostly energy centered on player
- Ring expands from 0 to 80px radius over 400ms
- Deals 3 damage to all enemies within ring
- Cooldown: 800ms
- Energy cost: 5 per attack

**Passive — Invulnerability Frames**:
- After taking damage, gain 1.5s invincibility (vs normal 0.8s)
- During iframes, player alpha flickers rapidly

**Energy Drain**: 3.0 per second (fastest drain — phasing is powerful)

### 4.3 Armor Form (铠甲勇士形态)

**Visual**: Player sprite enlarged by 30%. Metallic silver body with glowing red accents on chest and fists. Helmet visor glow in facing direction. Heavy footstep particles.

**Movement**:
- Speed: 2.5 (slower, heavy feel)
- Jump: Normal height
- Dash: Enhanced dash — dash distance 1.5x, dash damage enabled (dash deals 1 damage to enemies hit)
- Knockback resistance: 50% less knockback from enemy contact

**Attack — Rider Kick**:
- Press attack: Powerful forward charge in facing direction
- Charges 60px forward at high speed (15px/frame for 4 frames)
- Deals 5 damage to all enemies in path
- Pierces through enemies (no stop on hit)
- Cooldown: 1000ms
- Energy cost: 8 per attack (high cost, high impact)

**Passive — Damage Reduction**:
- Takes 50% less damage from all sources (heavy armor)

**Energy Drain**: 2.5 per second

### 4.4 Iron Man Form (钢铁侠形态)

**Visual**: Player sprite replaced by armored red-gold figure. Jet boots emit flame particles when hovering. Chest arc reactor glow (small bright circle). Repulsor glow on hands during attack.

**Movement**:
- Speed: 4.0 (fastest form)
- **Flight/Hover**: Ignores all terrain — moves freely in all directions (up/down/left/right)
- No jumping needed — direct vertical movement via joystick
- No dash; speed compensates
- Collision with walls still active (flies over floors/water/lava but not through walls)

**Attack — Repulsor Beam**:
- Press attack: Fires a beam projectile in facing direction
- Beam travels 150px at 8px/frame
- Deals 3 damage, pierces first enemy
- Visual: bright energy line with glow trail
- Cooldown: 350ms (rapid fire)
- Energy cost: 2 per attack

**Passive — Terrain Immunity**:
- No damage from lava tiles (hovering above)
- No damage from water/vortex effects
- No damage from ground traps (spikes, poison)

**Energy Drain**: 3.5 per second (fastest — flight + ranged is strongest combo)

---

## 5. Energy System

### 5.1 Energy Parameters

| Parameter | Value |
|-----------|-------|
| Max energy | 100 |
| Starting energy (first transform) | 100 (full) |
| Revert cooldown | 10 seconds (10000ms) |
| Passive regen (not transformed) | 1.0 per second |

### 5.2 Energy Recovery

| Source | Amount |
|--------|--------|
| Kill any enemy (slime) | +5 energy |
| Kill elite enemy | +10 energy |
| Kill boss | +50 energy (instant large burst) |
| Passive regen (not transformed) | +1 per second |
| Collect XP orb | +1 energy |

### 5.3 Energy Drain Rates

| Form | Drain (per second) | Approx Duration (full energy) |
|------|--------------------|-----------------------------|
| SLIME | 2.0 | ~50 seconds |
| GHOST | 3.0 | ~33 seconds |
| ARMOR | 2.5 | ~40 seconds |
| IRON_MAN | 3.5 | ~28 seconds |

### 5.4 Energy Depletion Flow

1. Energy reaches 0 → automatic transformation revert
2. 500ms revert animation (flash + particle burst)
3. `transformCooldown` set to 10000ms
4. During cooldown: transform button shows cooldown indicator, cannot re-transform
5. Cooldown expires → button available again
6. Player can also manually tap transform button to revert early (keep remaining energy)

---

## 6. Transformation Flow

### 6.1 Activating Transformation

```
Player taps transform button
  → Check: unlockedTransforms.length > 0?
    → No: Button shows locked icon, no action
    → Yes: Open form selection panel (if multiple forms)
      → Player selects form
        → Check: transformCooldown <= 0?
          → No: Show cooldown indicator
          → Yes:
            1. Save current weaponForm to savedWeaponForm
            2. Set isTransformed = true
            3. Set transformForm = selected form
            4. Set transformEnergy = transformMaxEnergy (100)
            5. Play transform animation (800ms flash + scale effect)
            6. Disable weapon rendering, enable form rendering
```

### 6.2 During Transformation

- Weapon attacks disabled; form-specific attacks active
- Player rendering replaced by form-specific rendering
- Movement modified per form abilities
- Energy bar displayed (replaces or overlays weapon form UI)
- Energy drains continuously each frame

### 6.3 Reverting

```
Energy reaches 0 OR player taps transform button
  → Set isTransformed = false
  → Set transformForm = NONE
  → Restore currentWeaponForm from savedWeaponForm
  → Play revert animation (500ms)
  → If energy == 0: set transformCooldown = 10000
```

---

## 7. UI Design

### 7.1 Transform Button

- Position: Right side of screen, above attack button
- Size: 40x40px
- Visual states:
  - **Locked**: Gray lock icon (no forms unlocked)
  - **Ready**: Colored icon showing current selected form, subtle pulse glow
  - **Active**: Bright glow, energy bar overlay on button border
  - **Cooldown**: Dimmed with sweep timer indicator

### 7.2 Energy Bar

- Displayed when transformed
- Position: Below HP bar, same width
- Color: Gradient based on form (SLIME: green, GHOST: purple, ARMOR: silver, IRON_MAN: gold)
- Flashes red when energy < 20%
- Shows numeric value on tap

### 7.3 Form Selection Panel

- Triggered by long-press on transform button (or tap when multiple forms unlocked)
- Position: Center screen overlay
- Layout: Horizontal row of form icons (max 4 slots)
- Each slot shows:
  - Form icon (pixel art thumbnail)
  - Form name
  - Unlock status (locked = gray silhouette)
  - Selected indicator (border glow)
- Tap form to select → panel closes → selected form is now the active choice

### 7.4 Form Icons (Pixel Art Thumbnails)

| Form | Icon Description |
|------|-----------------|
| SLIME | Green blob with eyes |
| GHOST | Purple translucent figure |
| ARMOR | Silver helmet with red visor |
| IRON_MAN | Red-gold faceplate |

---

## 8. Rendering

### 8.1 Form Rendering Methods

Each form adds a dedicated render method in GameEngine:

```typescript
private renderSlimeForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState): void
private renderGhostForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState): void
private renderArmorForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState): void
private renderIronManForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState): void
```

All rendering uses Canvas 2D primitives (fillRect, arc, fillText) consistent with existing pixel art style. No sprite sheets.

### 8.2 Transform Animation

On transform activate:
- 800ms animation
- Player scales up from 0.5x to 1.2x to 1.0x
- Bright flash (white circle expanding then fading)
- Form-colored particles burst outward (12 particles)

On transform revert:
- 500ms animation
- Player flickers rapidly (alpha 0→1→0→1)
- Small implosion particles (6 particles inward)

### 8.3 Form-Specific Visual Effects

| Form | Ambient Effect |
|------|---------------|
| SLIME | Drip particles every 20 frames (green dots falling) |
| GHOST | Trailing wisps (purple particles with short life) |
| ARMOR | Ground impact particles when landing from jump |
| IRON_MAN | Jet flame particles from feet (orange/yellow) |

---

## 9. Color Constants

```typescript
// Transform system colors
export const COLOR_TRANSFORM_SLIME: string = '#4ade80';
export const COLOR_TRANSFORM_SLIME_DARK: string = '#22c55e';
export const COLOR_TRANSFORM_GHOST: string = '#a78bfa';
export const COLOR_TRANSFORM_GHOST_DARK: string = '#7c3aed';
export const COLOR_TRANSFORM_ARMOR: string = '#94a3b8';
export const COLOR_TRANSFORM_ARMOR_ACCENT: string = '#ef4444';
export const COLOR_TRANSFORM_IRON_RED: string = '#dc2626';
export const COLOR_TRANSFORM_IRON_GOLD: string = '#fbbf24';
export const COLOR_TRANSFORM_ENERGY_BG: string = '#1f2937';
export const COLOR_TRANSFORM_BTN_LOCKED: string = '#4b5563';
export const COLOR_TRANSFORM_BTN_READY: string = '#22d3ee';
export const COLOR_TRANSFORM_FLASH: string = '#ffffff';
```

---

## 10. GameEngine Integration Points

### 10.1 Update Loop Additions

In the main update loop, after `updatePlayer`:

```
updatePlayer
  → if isTransformed:
    → updateTransformEnergy(dt)     // drain energy
    → updateFormMovement(dt)         // form-specific movement overrides
    → checkTransformRevert()         // energy <= 0 check
  → updateTransformCooldown(dt)     // cooldown tick when not transformed
```

Form-specific attack handling replaces normal attack processing when `isTransformed == true`.

### 10.2 Render Loop Additions

In the main render loop, `renderPlayer` branch:

```
renderPlayer:
  → if isTransformed:
    → renderSlimeForm / renderGhostForm / renderArmorForm / renderIronManForm
    → renderTransformParticles
  → else:
    → normal player rendering (existing code)
```

### 10.3 Collision Modifications

- Ghost form: `getTileAt(x, y)` returns FLOOR for WALL tiles when `transformForm == GHOST`
- Iron Man form: Lava/Water/Vortex tile damage checks skipped when `isTransformed && transformForm == IRON_MAN`
- Slime form: Wall bounce logic in movement update

### 10.4 Boss Defeat Hook

When a boss is defeated, check boss-to-form mapping. If the boss drops a form core:
1. Spawn `MaterialDrop` with appropriate `transformCore` type
2. Player collects it → added to inventory
3. On collection: if form not yet unlocked, add to `unlockedTransforms` and consume the core
4. Show unlock notification (form name + icon flash on screen)

---

## 11. Balance Considerations

- Transformation is meant for **tough encounters and exploration**, not as the default state
- Energy drain ensures players can't stay transformed indefinitely
- Killing enemies to recharge creates a risk/reward loop: stay in form longer by fighting aggressively
- Each form has trade-offs: Iron Man has highest mobility but fastest drain; Armor has best defense but slowest movement
- Cooldown prevents spam-transforming to reset energy (must manage energy wisely)
- Boss forms are balanced against late-game weapon evolution levels — a Level 3 weapon should feel comparable to a transformation

---

## 12. Implementation Constraints

- All code in ArkTS, no external libraries
- Rendering via CanvasRenderingContext2D (2D context)
- No sprite sheets — all visuals from geometric primitives
- Transform state lives on PlayerState (no separate system class)
- UI via ArkUI @State reactive variables + @Builder components
- Must maintain 60fps target on HarmonyOS devices
