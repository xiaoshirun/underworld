# Transformation System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a transformation system where players defeat bosses to unlock 4 transform forms (Slime, Ghost, Armor, Iron Man), each replacing weapons with unique abilities, governed by an energy drain/recharge mechanic.

**Architecture:** State machine extension on existing PlayerState. All transform logic lives in GameEngine with `// === Transform System ===` section markers. UI uses ArkUI @State variables + @Builder components on Index page.

**Tech Stack:** HarmonyOS ArkTS/ArkUI, CanvasRenderingContext2D 2D primitives

**Spec:** `docs/superpowers/specs/2026-09-27-transformation-system-design.md`

## Global Constraints

- All code in ArkTS, no external libraries
- Rendering via CanvasRenderingContext2D (2D context), geometric primitives only
- Transform state on PlayerState (no separate system class)
- UI via ArkUI @State reactive variables + @Builder components
- Maintain 60fps target on HarmonyOS devices
- Follow existing code patterns: explicit type annotations, null checks, const declarations

---

### Task 1: Extend GameConstants with Transform Types & Constants

**Files:**
- Modify: `entry/src/main/ets/game/GameConstants.ets`

**Interfaces:**
- Consumes: existing PlayerState, Inventory, BossType enums
- Produces: TransformForm enum, transform constants, new PlayerState fields spec, new Inventory fields spec

- [ ] **Step 1: Add TransformForm enum after ChestType enum (after line 185)**

```typescript
export enum TransformForm {
  NONE = -1,
  SLIME = 0,
  GHOST = 1,
  ARMOR = 2,
  IRON_MAN = 3
}
```

- [ ] **Step 2: Add transform constants after existing expansion constants (after line 483)**

```typescript
// Transform system constants
export const TRANSFORM_MAX_ENERGY: number = 100;
export const TRANSFORM_COOLDOWN: number = 10000;
export const TRANSFORM_PASSIVE_REGEN: number = 1.0;
export const TRANSFORM_ACTIVATE_ANIM: number = 800;
export const TRANSFORM_REVERT_ANIM: number = 500;

// Energy drain per second by form (index = TransformForm value)
export const TRANSFORM_DRAIN_RATES: number[] = [2.0, 3.0, 2.5, 3.5];

// Form movement speeds
export const TRANSFORM_SPEEDS: number[] = [3.5, 2.8, 2.5, 4.0];

// Form attack energy costs
export const TRANSFORM_ATTACK_COSTS: number[] = [3, 5, 8, 2];

// Form attack cooldowns (ms)
export const TRANSFORM_ATTACK_COOLDOWNS: number[] = [600, 800, 1000, 350];

// Form damage reduction (percentage)
export const TRANSFORM_DAMAGE_REDUCTION: number[] = [0.3, 0.0, 0.5, 0.0];

// Energy recovery from kills
export const TRANSFORM_ENERGY_KILL_SLIME: number = 5;
export const TRANSFORM_ENERGY_KILL_ELITE: number = 10;
export const TRANSFORM_ENERGY_KILL_BOSS: number = 50;
export const TRANSFORM_ENERGY_XP_ORB: number = 1;

// Transform form colors
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

- [ ] **Step 3: Add transform fields to PlayerState interface (after `inventory: Inventory;` at line 266)**

```typescript
  isTransformed: boolean;
  transformForm: TransformForm;
  transformEnergy: number;
  transformMaxEnergy: number;
  transformCooldown: number;
  unlockedTransforms: number[];
  savedWeaponForm: WeaponForm;
  transformAnimTimer: number;
  transformFormAttackCooldown: number;
```

- [ ] **Step 4: Add transform core fields to Inventory interface (after `gold: number;` at line 422)**

```typescript
  transformCoreSlime: number;
  transformCoreArmor: number;
  transformCoreIronMan: number;
  transformCoreGhost: number;
```

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/game/GameConstants.ets
git commit -m "feat: add TransformForm enum, constants, and interface extensions for transform system"
```

---

### Task 2: Update Player Init & Boss Drop Logic

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: TransformForm enum, TRANSFORM_MAX_ENERGY constant, new PlayerState/Inventory fields from Task 1
- Produces: Player initialized with transform defaults, boss defeat spawns transform core drops

- [ ] **Step 1: Add import for new constants at top of GameEngine.ets**

Add to the import block from GameConstants:

```typescript
  TransformForm, TRANSFORM_MAX_ENERGY, TRANSFORM_COOLDOWN, TRANSFORM_PASSIVE_REGEN,
  TRANSFORM_DRAIN_RATES, TRANSFORM_SPEEDS, TRANSFORM_ATTACK_COSTS, TRANSFORM_ATTACK_COOLDOWNS,
  TRANSFORM_DAMAGE_REDUCTION, TRANSFORM_ENERGY_KILL_SLIME, TRANSFORM_ENERGY_KILL_ELITE,
  TRANSFORM_ENERGY_KILL_BOSS, TRANSFORM_ENERGY_XP_ORB, TRANSFORM_ACTIVATE_ANIM, TRANSFORM_REVERT_ANIM,
  COLOR_TRANSFORM_SLIME, COLOR_TRANSFORM_SLIME_DARK, COLOR_TRANSFORM_GHOST, COLOR_TRANSFORM_GHOST_DARK,
  COLOR_TRANSFORM_ARMOR, COLOR_TRANSFORM_ARMOR_ACCENT, COLOR_TRANSFORM_IRON_RED, COLOR_TRANSFORM_IRON_GOLD,
  COLOR_TRANSFORM_ENERGY_BG, COLOR_TRANSFORM_BTN_LOCKED, COLOR_TRANSFORM_BTN_READY, COLOR_TRANSFORM_FLASH,
```

- [ ] **Step 2: Update player initialization (around line 104-124) to include transform fields**

After `inventory: { ... }` closing, add:

```typescript
      isTransformed: false,
      transformForm: TransformForm.NONE,
      transformEnergy: TRANSFORM_MAX_ENERGY,
      transformMaxEnergy: TRANSFORM_MAX_ENERGY,
      transformCooldown: 0,
      unlockedTransforms: [],
      savedWeaponForm: WeaponForm.BLADE,
      transformAnimTimer: 0,
      transformFormAttackCooldown: 0,
```

And in inventory block, add:

```typescript
        transformCoreSlime: 0, transformCoreArmor: 0,
        transformCoreIronMan: 0, transformCoreGhost: 0,
```

- [ ] **Step 3: Add transform core drop to spawnBossDrops method (after line 1378)**

After the existing rare core drop, add transform core drop logic:

```typescript
    // Drop transform core (first defeat only — check if player already has it)
    const transformDrop: TransformForm = this.getTransformCoreForBoss(boss.bossType);
    if (transformDrop !== TransformForm.NONE) {
      const alreadyHas: boolean = this.player !== null &&
        this.player.unlockedTransforms.indexOf(transformDrop) !== -1;
      if (!alreadyHas) {
        this.materialDrops.push({
          x: boss.x + (Math.random() - 0.5) * 30,
          y: boss.y + (Math.random() - 0.5) * 30,
          type: MaterialType.FORM_CORE, count: 1,
          bobPhase: Math.random() * Math.PI * 2,
          active: true
        });
        // Mark which transform core via extraData — use a separate tracking mechanism
        // Store transform form in a parallel array indexed by drop
        this.transformCoreDrops.push({ dropIndex: this.materialDrops.length - 1, form: transformDrop });
      }
    }
```

- [ ] **Step 4: Add helper method getTransformCoreForBoss**

```typescript
  private transformCoreDrops: { dropIndex: number; form: TransformForm }[] = [];

  private getTransformCoreForBoss(bossType: BossType): TransformForm {
    if (bossType === BossType.MUSHROOM_KING) return TransformForm.SLIME;
    if (bossType === BossType.CRYSTAL_GUARDIAN) return TransformForm.ARMOR;
    if (bossType === BossType.LAVA_BEAST) return TransformForm.IRON_MAN;
    if (bossType === BossType.VOID_RIFT) return TransformForm.GHOST;
    return TransformForm.NONE;
  }
```

- [ ] **Step 5: Update collectMaterialDrops to handle transform cores**

In the existing `collectMaterialDrops` method, after the FORM_CORE case handling, add transform core resolution:

```typescript
      // Check if this is a transform core drop
      for (let t: number = 0; t < this.transformCoreDrops.length; t++) {
        if (this.transformCoreDrops[t].dropIndex === dropIndex) {
          const form: TransformForm = this.transformCoreDrops[t].form;
          if (p.unlockedTransforms.indexOf(form) === -1) {
            p.unlockedTransforms.push(form);
            this.transformUnlockNotifyTimer = 3000;
            this.transformUnlockNotifyForm = form;
          }
          this.transformCoreDrops.splice(t, 1);
          break;
        }
      }
```

Add tracking fields to GameEngine class:

```typescript
  private transformUnlockNotifyTimer: number = 0;
  private transformUnlockNotifyForm: TransformForm = TransformForm.NONE;
```

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: player init with transform fields and boss transform core drops"
```

---

### Task 3: Transform Activation, Revert & Energy System

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: PlayerState transform fields from Task 2, TransformForm enum
- Produces: Public methods `activateTransform(form)`, `deactivateTransform()`, `getTransformState()` for UI

- [ ] **Step 1: Add transform system section after updatePlayer call in update method (line 341)**

After `this.updatePlayer(p, dt);` add:

```typescript
    // === Transform System Update ===
    this.updateTransformSystem(p, dt);
```

- [ ] **Step 2: Implement updateTransformSystem method**

Add after the updatePlayer method block:

```typescript
  // === Transform System ===

  private updateTransformSystem(p: PlayerState, dt: number): void {
    // Cooldown tick when not transformed
    if (!p.isTransformed && p.transformCooldown > 0) {
      p.transformCooldown -= dt;
      if (p.transformCooldown < 0) p.transformCooldown = 0;
    }

    // Transform animation timer
    if (p.transformAnimTimer > 0) {
      p.transformAnimTimer -= dt;
      if (p.transformAnimTimer < 0) p.transformAnimTimer = 0;
    }

    // Unlock notification timer
    if (this.transformUnlockNotifyTimer > 0) {
      this.transformUnlockNotifyTimer -= dt;
      if (this.transformUnlockNotifyTimer < 0) this.transformUnlockNotifyTimer = 0;
    }

    if (!p.isTransformed) {
      // Passive energy regen when not transformed
      p.transformEnergy += TRANSFORM_PASSIVE_REGEN * (dt / 1000);
      if (p.transformEnergy > p.transformMaxEnergy) {
        p.transformEnergy = p.transformMaxEnergy;
      }
      return;
    }

    // Energy drain
    const formIndex: number = p.transformForm as number;
    const drainRate: number = TRANSFORM_DRAIN_RATES[formIndex];
    p.transformEnergy -= drainRate * (dt / 1000);

    // Form attack cooldown tick
    if (p.transformFormAttackCooldown > 0) {
      p.transformFormAttackCooldown -= dt;
      if (p.transformFormAttackCooldown < 0) p.transformFormAttackCooldown = 0;
    }

    // Auto-revert on energy depletion
    if (p.transformEnergy <= 0) {
      p.transformEnergy = 0;
      this.deactivateTransform();
    }

    // Form-specific ambient effects
    this.updateTransformAmbientEffects(p, dt);
  }

  private updateTransformAmbientEffects(p: PlayerState, dt: number): void {
    if (!this.settings.effectsEnabled) return;
    const form: TransformForm = p.transformForm;

    if (form === TransformForm.SLIME && this.frameCount % 20 === 0) {
      // Drip particles
      this.spawnParticle(p.x, p.y + PLAYER_SIZE, 0, 1, 400, COLOR_TRANSFORM_SLIME, 2);
    } else if (form === TransformForm.GHOST && this.frameCount % 5 === 0) {
      // Trailing wisps
      this.spawnParticle(p.x + (Math.random() - 0.5) * 8, p.y + (Math.random() - 0.5) * 8,
        (Math.random() - 0.5) * 0.5, -0.5 - Math.random() * 0.5, 300, COLOR_TRANSFORM_GHOST, 3);
    } else if (form === TransformForm.IRON_MAN && this.frameCount % 3 === 0) {
      // Jet flame particles from feet
      this.spawnParticle(p.x - 3, p.y + PLAYER_SIZE, (Math.random() - 0.5) * 0.5, 1.5 + Math.random(), 200,
        Math.random() > 0.5 ? '#ff6b00' : '#fbbf24', 2 + Math.random() * 2);
      this.spawnParticle(p.x + 3, p.y + PLAYER_SIZE, (Math.random() - 0.5) * 0.5, 1.5 + Math.random(), 200,
        Math.random() > 0.5 ? '#ff6b00' : '#fbbf24', 2 + Math.random() * 2);
    }
  }
```

- [ ] **Step 3: Implement activateTransform and deactivateTransform public methods**

```typescript
  activateTransform(form: TransformForm): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;
    if (p.isTransformed) return;
    if (p.transformCooldown > 0) return;
    if (p.unlockedTransforms.indexOf(form as number) === -1) return;

    // Save weapon form
    p.savedWeaponForm = p.currentWeaponForm;

    // Activate
    p.isTransformed = true;
    p.transformForm = form;
    p.transformEnergy = p.transformMaxEnergy;
    p.transformAnimTimer = TRANSFORM_ACTIVATE_ANIM;
    p.transformFormAttackCooldown = 0;

    // Spawn activation particles
    if (this.settings.effectsEnabled) {
      for (let i: number = 0; i < 12; i++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 2 + Math.random() * 3;
        const color: string = this.getTransformColor(form);
        this.spawnParticle(p.x, p.y, Math.cos(angle) * speed, Math.sin(angle) * speed, 600, color, 3 + Math.random() * 2);
      }
    }
    this.shakeTimer = 200;
  }

  deactivateTransform(): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;
    if (!p.isTransformed) return;

    // Restore weapon
    p.currentWeaponForm = p.savedWeaponForm;

    // Deactivate
    p.isTransformed = false;
    p.transformForm = TransformForm.NONE;
    p.transformAnimTimer = TRANSFORM_REVERT_ANIM;

    // Set cooldown if energy depleted
    if (p.transformEnergy <= 0) {
      p.transformCooldown = TRANSFORM_COOLDOWN;
    }

    // Revert particles
    if (this.settings.effectsEnabled) {
      for (let i: number = 0; i < 6; i++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 1 + Math.random() * 2;
        this.spawnParticle(p.x, p.y, -Math.cos(angle) * speed, -Math.sin(angle) * speed, 400, '#ffffff', 2);
      }
    }
  }

  private getTransformColor(form: TransformForm): string {
    if (form === TransformForm.SLIME) return COLOR_TRANSFORM_SLIME;
    if (form === TransformForm.GHOST) return COLOR_TRANSFORM_GHOST;
    if (form === TransformForm.ARMOR) return COLOR_TRANSFORM_ARMOR;
    return COLOR_TRANSFORM_IRON_GOLD;
  }

  // Public getters for UI
  getIsTransformed(): boolean {
    return this.player !== null && this.player.isTransformed;
  }

  getTransformEnergy(): number {
    return this.player !== null ? this.player.transformEnergy : 0;
  }

  getTransformMaxEnergy(): number {
    return this.player !== null ? this.player.transformMaxEnergy : TRANSFORM_MAX_ENERGY;
  }

  getTransformForm(): TransformForm {
    return this.player !== null ? this.player.transformForm : TransformForm.NONE;
  }

  getTransformCooldown(): number {
    return this.player !== null ? this.player.transformCooldown : 0;
  }

  getUnlockedTransforms(): number[] {
    return this.player !== null ? this.player.unlockedTransforms : [];
  }

  getTransformUnlockNotify(): { active: boolean; form: TransformForm } {
    return { active: this.transformUnlockNotifyTimer > 0, form: this.transformUnlockNotifyForm };
  }
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: transform activation, revert, energy drain/regen system"
```

---

### Task 4: Transform Form Movement & Combat Overrides

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: TransformForm enum, TRANSFORM_SPEEDS, TRANSFORM_ATTACK_COSTS, TRANSFORM_ATTACK_COOLDOWNS, TRANSFORM_DAMAGE_REDUCTION
- Produces: Modified updatePlayer to branch on transform state, 4 form-specific update methods

- [ ] **Step 1: Modify updatePlayer to check transform state early**

At the top of `updatePlayer` (after the engulfed check at line 358-361), add transform movement override:

```typescript
    if (p.isTransformed) {
      this.updateTransformMovement(p, dt, moveX, moveY);
      // Handle transform attack
      if (this.input.attackPressed) {
        this.input.attackPressed = false;
        this.handleTransformAttack(p);
      }
      // Handle jump for applicable forms
      if (this.input.jumpPressed && p.transformForm !== TransformForm.IRON_MAN) {
        this.input.jumpPressed = false;
        if (p.transformForm === TransformForm.SLIME) {
          p.isJumping = true;
          p.jumpTimer = 400; // Higher jump for slime
        } else {
          p.isJumping = true;
          p.jumpTimer = 300;
        }
      }
      // Skip normal movement/attack — transform handles it
      // Still need collision, enemy contact, etc.
      this.applyTransformCollision(p);
      this.checkEnemyContact(p);
      this.checkTrapDamage(p);
      return;
    }
```

- [ ] **Step 2: Implement updateTransformMovement**

```typescript
  private updateTransformMovement(p: PlayerState, dt: number, moveX: number, moveY: number): void {
    const form: TransformForm = p.transformForm;
    const speed: number = TRANSFORM_SPEEDS[form as number];

    if (form === TransformForm.IRON_MAN) {
      // Flight: direct movement in all directions, no gravity
      p.vx = moveX * speed;
      p.vy = moveY * speed;
    } else if (form === TransformForm.GHOST) {
      // Ghost: normal movement but no wall collision
      p.vx = moveX * speed;
      p.vy = moveY * speed;
    } else if (form === TransformForm.SLIME) {
      // Slime: normal movement with higher speed
      if (p.isDashing) {
        p.dashTimer -= dt;
        if (p.dashTimer <= 0) p.isDashing = false;
        else {
          p.vx = p.dashDirX * DASH_SPEED;
          p.vy = p.dashDirY * DASH_SPEED;
        }
      } else {
        p.vx = moveX * speed;
        p.vy = moveY * speed;
      }
    } else {
      // ARMOR: slower, heavy feel
      if (p.isDashing) {
        p.dashTimer -= dt;
        if (p.dashTimer <= 0) p.isDashing = false;
        else {
          p.vx = p.dashDirX * DASH_SPEED * 1.5;
          p.vy = p.dashDirY * DASH_SPEED * 1.5;
          // Dash damage to enemies
          this.checkTransformDashDamage(p);
        }
      } else {
        p.vx = moveX * speed;
        p.vy = moveY * speed;
      }
    }

    // Facing direction
    if (Math.abs(moveX) > 0.1 || Math.abs(moveY) > 0.1) {
      p.facing = Math.atan2(moveY, moveX);
    }

    // Jump timer
    if (p.isJumping) {
      p.jumpTimer -= dt;
      if (form === TransformForm.SLIME) {
        p.jumpHeight = Math.sin((1 - p.jumpTimer / 400) * Math.PI) * 16;
      } else {
        p.jumpHeight = Math.sin((1 - p.jumpTimer / 300) * Math.PI) * 8;
      }
      if (p.jumpTimer <= 0) {
        p.isJumping = false;
        p.jumpHeight = 0;
      }
    }
  }
```

- [ ] **Step 3: Implement applyTransformCollision**

```typescript
  private applyTransformCollision(p: PlayerState): void {
    const newX: number = p.x + p.vx;
    const newY: number = p.y + p.vy;

    if (p.transformForm === TransformForm.GHOST) {
      // Ghost: no wall collision — phase through everything
      p.x = newX;
      p.y = newY;
    } else if (p.transformForm === TransformForm.IRON_MAN) {
      // Iron Man: wall collision but ignore terrain damage
      if (!this.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      }
      if (!this.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      }
    } else if (p.transformForm === TransformForm.SLIME) {
      // Slime: wall bounce
      if (!this.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      } else {
        p.vx = -p.vx; // Bounce off wall
      }
      if (!this.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      } else {
        p.vy = -p.vy;
      }
    } else {
      // ARMOR: normal collision
      if (!this.checkPlayerCollision(newX, p.y)) {
        p.x = newX;
      }
      if (!this.checkPlayerCollision(p.x, newY)) {
        p.y = newY;
      }
    }
  }
```

- [ ] **Step 4: Implement handleTransformAttack**

```typescript
  private handleTransformAttack(p: PlayerState): void {
    const form: TransformForm = p.transformForm;
    const formIndex: number = form as number;
    const cost: number = TRANSFORM_ATTACK_COSTS[formIndex];
    const cooldown: number = TRANSFORM_ATTACK_COOLDOWNS[formIndex];

    if (p.transformFormAttackCooldown > 0) return;
    if (p.transformEnergy < cost) return;

    p.transformEnergy -= cost;
    p.transformFormAttackCooldown = cooldown;
    p.isAttacking = true;
    p.attackTimer = ATTACK_DURATION;

    const cosF: number = Math.cos(p.facing);
    const sinF: number = Math.sin(p.facing);

    if (form === TransformForm.SLIME) {
      // Split Shot: 3 small slimes shoot outward
      for (let i: number = -1; i <= 1; i++) {
        const spreadAngle: number = p.facing + i * 0.3;
        const sx: number = Math.cos(spreadAngle);
        const sy: number = Math.sin(spreadAngle);
        // Spawn projectile-like particles that damage enemies
        for (let d: number = 0; d < 80; d += 8) {
          const px: number = p.x + sx * d;
          const py: number = p.y + sy * d;
          this.damageEnemiesAt(px, py, 10, 2);
        }
        if (this.settings.effectsEnabled) {
          for (let d: number = 0; d < 60; d += 12) {
            this.spawnParticle(p.x + sx * d, p.y + sy * d,
              sx * 0.5, sy * 0.5, 300, COLOR_TRANSFORM_SLIME, 4);
          }
        }
      }
    } else if (form === TransformForm.GHOST) {
      // Soul Shockwave: expanding ring
      if (this.settings.effectsEnabled) {
        for (let a: number = 0; a < Math.PI * 2; a += 0.3) {
          this.spawnParticle(p.x + Math.cos(a) * 20, p.y + Math.sin(a) * 20,
            Math.cos(a) * 2, Math.sin(a) * 2, 400, COLOR_TRANSFORM_GHOST, 3);
        }
      }
      this.damageEnemiesInRadius(p.x, p.y, 80, 3);
    } else if (form === TransformForm.ARMOR) {
      // Rider Kick: charge forward 60px
      const chargeDist: number = 60;
      for (let d: number = 0; d < chargeDist; d += 6) {
        const cx: number = p.x + cosF * d;
        const cy: number = p.y + sinF * d;
        this.damageEnemiesAt(cx, cy, 12, 5);
      }
      // Move player forward
      p.x += cosF * chargeDist;
      p.y += sinF * chargeDist;
      if (this.settings.effectsEnabled) {
        for (let d: number = 0; d < chargeDist; d += 10) {
          this.spawnParticle(p.x - cosF * d, p.y - sinF * d,
            (Math.random() - 0.5) * 2, (Math.random() - 0.5) * 2, 400, COLOR_TRANSFORM_ARMOR_ACCENT, 4);
        }
      }
      this.shakeTimer = 150;
    } else if (form === TransformForm.IRON_MAN) {
      // Repulsor Beam: projectile traveling 150px
      const beamLen: number = 150;
      for (let d: number = 0; d < beamLen; d += 6) {
        const bx: number = p.x + cosF * d;
        const by: number = p.y + sinF * d;
        this.damageEnemiesAt(bx, by, 8, 3);
      }
      if (this.settings.effectsEnabled) {
        for (let d: number = 0; d < beamLen; d += 10) {
          this.spawnParticle(p.x + cosF * d, p.y + sinF * d,
            cosF * 0.3 + (Math.random() - 0.5), sinF * 0.3 + (Math.random() - 0.5),
            250, COLOR_TRANSFORM_IRON_GOLD, 3);
        }
      }
    }
  }
```

- [ ] **Step 5: Add helper methods damageEnemiesAt and damageEnemiesInRadius**

```typescript
  private damageEnemiesAt(x: number, y: number, radius: number, damage: number): void {
    for (let i: number = 0; i < this.slimes.length; i++) {
      const s: SlimeState = this.slimes[i];
      if (!s.active) continue;
      const dx: number = s.x - x;
      const dy: number = s.y - y;
      if (dx * dx + dy * dy < radius * radius) {
        s.hp -= damage;
        s.hitFlash = 200;
        if (this.settings.effectsEnabled) {
          this.spawnParticle(s.x, s.y, 0, -1, 300, COLOR_DAMAGE_PARTICLE, 3);
        }
      }
    }
  }

  private damageEnemiesInRadius(cx: number, cy: number, radius: number, damage: number): void {
    this.damageEnemiesAt(cx, cy, radius, damage);
    // Also damage bosses
    if (this.activeBoss !== null && this.activeBoss.active && !this.activeBoss.defeated) {
      const dx: number = this.activeBoss.x - cx;
      const dy: number = this.activeBoss.y - cy;
      if (dx * dx + dy * dy < radius * radius) {
        this.activeBoss.hp -= damage;
        this.activeBoss.hitFlash = 200;
      }
    }
  }

  private checkTransformDashDamage(p: PlayerState): void {
    // Armor dash: damage enemies in path
    for (let i: number = 0; i < this.slimes.length; i++) {
      const s: SlimeState = this.slimes[i];
      if (!s.active) continue;
      const dx: number = s.x - p.x;
      const dy: number = s.y - p.y;
      if (dx * dx + dy * dy < 30 * 30) {
        s.hp -= 1;
        s.hitFlash = 200;
      }
    }
  }
```

- [ ] **Step 6: Apply transform damage reduction in enemy contact check**

In the existing enemy contact damage section of updatePlayer (where player takes damage from slime contact), wrap the damage application:

```typescript
    // When player would take damage from enemy contact:
    let incomingDamage: number = SLIME_DAMAGE;
    if (p.isTransformed) {
      const reduction: number = TRANSFORM_DAMAGE_REDUCTION[p.transformForm as number];
      incomingDamage = Math.max(1, Math.floor(incomingDamage * (1 - reduction)));
    }
```

- [ ] **Step 7: Skip terrain damage for Iron Man form**

In trap damage check and lava/water damage sections, add early return:

```typescript
    // In checkTrapDamage or terrain damage section:
    if (p.isTransformed && p.transformForm === TransformForm.IRON_MAN) {
      // Iron Man hovers — immune to ground traps and terrain
      return;
    }
```

- [ ] **Step 8: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: transform form movement, combat overrides, and damage modifiers"
```

---

### Task 5: Transform Form Rendering

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: PlayerState transform fields, TransformForm, transform color constants
- Produces: 4 render methods called from renderPlayer when isTransformed

- [ ] **Step 1: Modify renderPlayer to branch on transform state**

In the existing `renderPlayer` method, after computing screenX/screenY and before the normal rendering, add:

```typescript
    // Transform rendering override
    if (p.isTransformed) {
      const bobY: number = p.isJumping ? -p.jumpHeight : Math.sin(this.frameCount * 0.08) * 1.5;
      if (p.transformForm === TransformForm.SLIME) {
        this.renderSlimeForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.GHOST) {
        this.renderGhostForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.ARMOR) {
        this.renderArmorForm(c, screenX, screenY, p, bobY);
      } else if (p.transformForm === TransformForm.IRON_MAN) {
        this.renderIronManForm(c, screenX, screenY, p, bobY);
      }
      // Transform animation overlay
      if (p.transformAnimTimer > 0) {
        this.renderTransformAnim(c, screenX, screenY, p);
      }
      return;
    }
```

- [ ] **Step 2: Implement renderSlimeForm**

```typescript
  private renderSlimeForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const size: number = 18; // Larger than normal slimes
    const squash: number = p.isJumping ? 0.8 : 1.0 + Math.sin(this.frameCount * 0.1) * 0.05;
    const stretch: number = p.isJumping ? 1.3 : 1.0 - Math.sin(this.frameCount * 0.1) * 0.05;

    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY);
    c.scale(squash, stretch);

    // Body
    c.fillStyle = COLOR_TRANSFORM_SLIME;
    c.beginPath();
    c.ellipse(0, 2, size / 2, size / 2.2, 0, 0, Math.PI * 2);
    c.fill();

    // Highlight
    c.fillStyle = COLOR_TRANSFORM_SLIME_DARK;
    c.beginPath();
    c.ellipse(0, 4, size / 2.5, size / 3, 0, 0, Math.PI * 2);
    c.fill();

    // Eyes
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(-4, -2, 3, 4, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(4, -2, 3, 4, 0, 0, Math.PI * 2);
    c.fill();

    // Pupils (face facing direction)
    const pupilOffX: number = Math.cos(p.facing) * 1.5;
    const pupilOffY: number = Math.sin(p.facing) * 1.5;
    c.fillStyle = '#1a1a2e';
    c.beginPath();
    c.arc(-4 + pupilOffX, -2 + pupilOffY, 1.5, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.arc(4 + pupilOffX, -2 + pupilOffY, 1.5, 0, Math.PI * 2);
    c.fill();

    c.restore();
  }
```

- [ ] **Step 3: Implement renderGhostForm**

```typescript
  private renderGhostForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    c.save();
    c.globalAlpha = 0.5 + Math.sin(this.frameCount * 0.06) * 0.15;
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY - 3);

    // Ghost body (flowing shape)
    c.fillStyle = COLOR_TRANSFORM_GHOST;
    c.beginPath();
    c.arc(0, -4, 8, Math.PI, 0);
    c.lineTo(8, 6);
    // Wavy bottom
    for (let i: number = 0; i < 4; i++) {
      const wx: number = 8 - i * 4;
      const wy: number = 6 + (i % 2 === 0 ? 4 : 0);
      c.lineTo(wx, wy);
    }
    c.closePath();
    c.fill();

    // Dark overlay
    c.fillStyle = COLOR_TRANSFORM_GHOST_DARK;
    c.beginPath();
    c.arc(0, -2, 5, 0, Math.PI * 2);
    c.fill();

    // Eyes (glowing)
    c.fillStyle = '#ffffff';
    c.beginPath();
    c.ellipse(-3, -4, 2, 3, 0, 0, Math.PI * 2);
    c.fill();
    c.beginPath();
    c.ellipse(3, -4, 2, 3, 0, 0, Math.PI * 2);
    c.fill();

    c.restore();
  }
```

- [ ] **Step 4: Implement renderArmorForm**

```typescript
  private renderArmorForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const scale: number = 1.3;
    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY);
    c.scale(scale, scale);

    // Body (metallic)
    c.fillStyle = COLOR_TRANSFORM_ARMOR;
    c.fillRect(-6, -4, 12, 14);

    // Chest accent
    c.fillStyle = COLOR_TRANSFORM_ARMOR_ACCENT;
    c.fillRect(-4, -2, 8, 3);

    // Helmet
    c.fillStyle = '#64748b';
    c.fillRect(-5, -9, 10, 6);

    // Visor
    c.fillStyle = COLOR_TRANSFORM_ARMOR_ACCENT;
    const visorGlow: number = 0.6 + Math.sin(this.frameCount * 0.08) * 0.3;
    c.globalAlpha = visorGlow;
    c.fillRect(-4, -7, 8, 2);
    c.globalAlpha = 1.0;

    // Fists
    c.fillStyle = COLOR_TRANSFORM_ARMOR;
    c.fillRect(-8, 2, 3, 4);
    c.fillRect(5, 2, 3, 4);

    // Legs
    c.fillStyle = '#475569';
    c.fillRect(-4, 10, 3, 4);
    c.fillRect(1, 10, 3, 4);

    c.restore();
  }
```

- [ ] **Step 5: Implement renderIronManForm**

```typescript
  private renderIronManForm(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    c.save();
    c.translate(sx + PLAYER_SIZE / 2, sy + PLAYER_SIZE / 2 + bobY - 2);

    // Body (red-gold armor)
    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-6, -4, 12, 14);

    // Gold accents
    c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
    c.fillRect(-5, 0, 10, 3);

    // Head/faceplate
    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-5, -9, 10, 6);
    c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
    c.fillRect(-4, -7, 8, 3);

    // Eyes (glowing white)
    c.fillStyle = '#ffffff';
    c.fillRect(-3, -7, 2, 1);
    c.fillRect(1, -7, 2, 1);

    // Arc reactor (chest)
    const reactorGlow: number = 0.7 + Math.sin(this.frameCount * 0.1) * 0.3;
    c.fillStyle = '#67e8f9';
    c.globalAlpha = reactorGlow;
    c.beginPath();
    c.arc(0, 2, 2.5, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;

    // Repulsor hands (glow when attacking)
    if (p.isAttacking) {
      c.fillStyle = COLOR_TRANSFORM_IRON_GOLD;
      c.globalAlpha = 0.9;
      c.beginPath();
      c.arc(-8, 3, 3, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(8, 3, 3, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    // Boots
    c.fillStyle = COLOR_TRANSFORM_IRON_RED;
    c.fillRect(-5, 10, 4, 4);
    c.fillRect(1, 10, 4, 4);

    c.restore();
  }
```

- [ ] **Step 6: Implement renderTransformAnim**

```typescript
  private renderTransformAnim(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState): void {
    const progress: number = 1 - (p.transformAnimTimer / TRANSFORM_ACTIVATE_ANIM);
    const cx: number = sx + PLAYER_SIZE / 2;
    const cy: number = sy + PLAYER_SIZE / 2;

    // Expanding flash ring
    c.save();
    c.globalAlpha = 1 - progress;
    c.strokeStyle = COLOR_TRANSFORM_FLASH;
    c.lineWidth = 3 - progress * 2;
    c.beginPath();
    c.arc(cx, cy, progress * 30, 0, Math.PI * 2);
    c.stroke();

    // Scale effect
    const scale: number = 0.5 + progress * 0.7;
    c.globalAlpha = Math.min(1, progress * 2);
    c.fillStyle = this.getTransformColor(p.transformForm);
    c.beginPath();
    c.arc(cx, cy, 8 * scale, 0, Math.PI * 2);
    c.fill();
    c.restore();
  }
```

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: transform form rendering — slime, ghost, armor, iron man pixel art"
```

---

### Task 6: Transform UI — Button, Energy Bar & Form Selection Panel

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

**Interfaces:**
- Consumes: GameEngine public getters (getIsTransformed, getTransformEnergy, getTransformMaxEnergy, getTransformForm, getTransformCooldown, getUnlockedTransforms, activateTransform, deactivateTransform, getTransformUnlockNotify)
- Produces: Transform button, energy bar, form selection panel on game UI

- [ ] **Step 1: Add imports for transform constants**

Add to the import from GameConstants:

```typescript
  TransformForm, TRANSFORM_MAX_ENERGY, TRANSFORM_COOLDOWN,
  COLOR_TRANSFORM_BTN_LOCKED, COLOR_TRANSFORM_BTN_READY, COLOR_TRANSFORM_ENERGY_BG,
  COLOR_TRANSFORM_SLIME, COLOR_TRANSFORM_GHOST, COLOR_TRANSFORM_ARMOR, COLOR_TRANSFORM_IRON_GOLD,
```

- [ ] **Step 2: Add @State variables for transform UI**

```typescript
  @State isTransformed: boolean = false;
  @State transformEnergy: number = TRANSFORM_MAX_ENERGY;
  @State transformMaxEnergy: number = TRANSFORM_MAX_ENERGY;
  @State transformForm: TransformForm = TransformForm.NONE;
  @State transformCooldown: number = 0;
  @State unlockedTransforms: number[] = [];
  @State showTransformPanel: boolean = false;
  @State showFormSelect: boolean = false;
  @State transformUnlockForm: TransformForm = TransformForm.NONE;
  @State transformUnlockActive: boolean = false;
  private selectedTransformForm: TransformForm = TransformForm.SLIME;
```

- [ ] **Step 3: Add TransformButtonView builder**

```typescript
  @Builder
  TransformButtonView() {
    Stack() {
      // Button background
      Circle()
        .width(40)
        .height(40)
        .fill(this.isTransformed ? this.getFormColor(this.transformForm) :
          (this.unlockedTransforms.length > 0 && this.transformCooldown <= 0 ? COLOR_TRANSFORM_BTN_READY : COLOR_TRANSFORM_BTN_LOCKED))

      // Icon
      Text(this.getTransformIcon())
        .fontSize(18)
        .fontColor('#ffffff')

      // Cooldown overlay
      if (this.transformCooldown > 0 && !this.isTransformed) {
        Text(Math.ceil(this.transformCooldown / 1000).toString())
          .fontSize(12)
          .fontColor('#ffffffa0')
          .position({ x: 14, y: 26 })
      }
    }
    .position({ x: this.screenW - 55, y: this.screenH - 200 })
    .onClick(() => {
      if (this.isTransformed) {
        this.gameEngine.deactivateTransform();
      } else if (this.unlockedTransforms.length === 1) {
        this.gameEngine.activateTransform(this.unlockedTransforms[0] as TransformForm);
      } else if (this.unlockedTransforms.length > 1) {
        this.showFormSelect = true;
      }
    })
  }
```

- [ ] **Step 4: Add TransformEnergyBarView builder**

```typescript
  @Builder
  TransformEnergyBarView() {
    if (this.isTransformed) {
      Column() {
        Stack({ alignContent: Alignment.Start }) {
          // Background
          Row().width(120).height(8).backgroundColor(COLOR_TRANSFORM_ENERGY_BG).borderRadius(4)
          // Fill
          Row()
            .width(120 * (this.transformEnergy / this.transformMaxEnergy))
            .height(8)
            .backgroundColor(this.getFormColor(this.transformForm))
            .borderRadius(4)
        }
        Text(Math.floor(this.transformEnergy).toString())
          .fontSize(9)
          .fontColor('#ffffffa0')
          .margin({ top: 2 })
      }
      .position({ x: this.screenW - 135, y: this.screenH - 155 })
    }
  }
```

- [ ] **Step 5: Add FormSelectPanel builder**

```typescript
  @Builder
  FormSelectPanel() {
    if (this.showFormSelect) {
      Column() {
        Text('Select Form')
          .fontSize(14)
          .fontColor('#ffffff')
          .margin({ bottom: 12 })

        Row({ space: 12 }) {
          ForEach(this.unlockedTransforms, (formId: number) => {
            Column() {
              Text(this.getFormIconForId(formId))
                .fontSize(24)
                .fontColor('#ffffff')
              Text(this.getFormNameForId(formId))
                .fontSize(10)
                .fontColor('#ffffffc0')
                .margin({ top: 4 })
            }
            .width(56)
            .height(64)
            .backgroundColor('#1e293be0')
            .borderRadius(8)
            .border({ width: 1, color: this.getFormColor(formId as TransformForm) })
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.showFormSelect = false;
              this.gameEngine.activateTransform(formId as TransformForm);
            })
          })
        }

        Text('Cancel')
          .fontSize(12)
          .fontColor('#ffffff80')
          .margin({ top: 8 })
          .onClick(() => { this.showFormSelect = false; })
      }
      .width(280)
      .padding(16)
      .backgroundColor('#0f172af0')
      .borderRadius(12)
      .position({ x: (this.screenW - 280) / 2, y: (this.screenH - 140) / 2 })
    }
  }
```

- [ ] **Step 6: Add TransformUnlockNotification builder**

```typescript
  @Builder
  TransformUnlockNotification() {
    if (this.transformUnlockActive) {
      Column() {
        Text('NEW FORM UNLOCKED!')
          .fontSize(14)
          .fontColor('#fbbf24')
          .fontWeight(FontWeight.Bold)
        Text(this.getFormIconForId(this.transformUnlockForm as number))
          .fontSize(32)
          .margin({ top: 8 })
        Text(this.getFormNameForId(this.transformUnlockForm as number))
          .fontSize(16)
          .fontColor('#ffffff')
          .margin({ top: 4 })
      }
      .width(200)
      .padding(16)
      .backgroundColor('#0f172af0')
      .borderRadius(12)
      .border({ width: 2, color: '#fbbf24' })
      .position({ x: (this.screenW - 200) / 2, y: (this.screenH - 120) / 2 })
    }
  }
```

- [ ] **Step 7: Add helper methods for form display**

```typescript
  private getTransformIcon(): string {
    if (this.isTransformed) {
      return this.getFormIconForId(this.transformForm as number);
    }
    return '⚡';
  }

  private getFormIconForId(formId: number): string {
    if (formId === TransformForm.SLIME) return '🟢';
    if (formId === TransformForm.GHOST) return '👻';
    if (formId === TransformForm.ARMOR) return '🛡';
    if (formId === TransformForm.IRON_MAN) return '🔴';
    return '?';
  }

  private getFormNameForId(formId: number): string {
    if (formId === TransformForm.SLIME) return 'Slime';
    if (formId === TransformForm.GHOST) return 'Ghost';
    if (formId === TransformForm.ARMOR) return 'Armor';
    if (formId === TransformForm.IRON_MAN) return 'Iron Man';
    return 'Unknown';
  }

  private getFormColor(form: TransformForm): string {
    if (form === TransformForm.SLIME) return COLOR_TRANSFORM_SLIME;
    if (form === TransformForm.GHOST) return COLOR_TRANSFORM_GHOST;
    if (form === TransformForm.ARMOR) return COLOR_TRANSFORM_ARMOR;
    if (form === TransformForm.IRON_MAN) return COLOR_TRANSFORM_IRON_GOLD;
    return COLOR_TRANSFORM_BTN_READY;
  }
```

- [ ] **Step 8: Add transform views to build() Stack**

In the existing build() method's Stack, add after existing button views:

```typescript
      TransformButtonView()
      TransformEnergyBarView()
      FormSelectPanel()
      TransformUnlockNotification()
```

- [ ] **Step 9: Update status monitor to poll transform state**

In the existing `startStatusMonitor` interval, add:

```typescript
      // Transform state
      const isT: boolean = this.gameEngine.getIsTransformed();
      if (isT !== this.isTransformed) { this.isTransformed = isT; }
      if (isT) {
        const e: number = this.gameEngine.getTransformEnergy();
        if (e !== this.transformEnergy) { this.transformEnergy = e; }
        const f: TransformForm = this.gameEngine.getTransformForm();
        if (f !== this.transformForm) { this.transformForm = f; }
      }
      const cd: number = this.gameEngine.getTransformCooldown();
      if (cd !== this.transformCooldown) { this.transformCooldown = cd; }
      const ut: number[] = this.gameEngine.getUnlockedTransforms();
      if (ut.length !== this.unlockedTransforms.length) { this.unlockedTransforms = ut; }
      // Unlock notification
      const notify = this.gameEngine.getTransformUnlockNotify();
      if (notify.active && !this.transformUnlockActive) {
        this.transformUnlockActive = true;
        this.transformUnlockForm = notify.form;
        setTimeout(() => { this.transformUnlockActive = false; }, 3000);
      }
```

- [ ] **Step 10: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat: transform UI — button, energy bar, form selection panel, unlock notification"
```

---

### Task 7: Ghost Form Wall Phasing Integration

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: TransformForm.GHOST, checkPlayerCollision, getTileAt methods
- Produces: Ghost form ignores wall tile collision

- [ ] **Step 1: Modify checkPlayerCollision to handle ghost form**

In the existing `checkPlayerCollision` method, add at the very top:

```typescript
  private checkPlayerCollision(x: number, y: number): boolean {
    // Ghost form phases through walls
    if (this.player !== null && this.player.isTransformed &&
        this.player.transformForm === TransformForm.GHOST) {
      return false;
    }
    // ... existing collision logic
```

- [ ] **Step 2: Skip terrain damage for Iron Man in trap checks**

In the existing trap damage and terrain damage sections, add early return:

```typescript
    if (this.player !== null && this.player.isTransformed &&
        this.player.transformForm === TransformForm.IRON_MAN) {
      return; // Iron Man hovers above terrain
    }
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: ghost wall phasing and iron man terrain immunity integration"
```

---

### Task 8: Final Integration & Energy Recovery Hooks

**Files:**
- Modify: `entry/src/main/ets/game/GameEngine.ets`

**Interfaces:**
- Consumes: All transform system methods from Tasks 2-7
- Produces: Energy recovery on enemy kill, XP orb collect, and transform system fully integrated

- [ ] **Step 1: Add energy recovery on enemy kill**

In the enemy death handling section (where slimes are marked inactive after hp <= 0), add:

```typescript
        // Transform energy recovery on kill
        if (this.player !== null && this.player.isTransformed) {
          this.player.transformEnergy += TRANSFORM_ENERGY_KILL_SLIME;
          if (this.player.transformEnergy > this.player.transformMaxEnergy) {
            this.player.transformEnergy = this.player.transformMaxEnergy;
          }
        }
```

- [ ] **Step 2: Add energy recovery on XP orb collect**

In the existing XP orb collection code, add:

```typescript
        // Transform energy recovery
        if (p.isTransformed) {
          p.transformEnergy += TRANSFORM_ENERGY_XP_ORB;
          if (p.transformEnergy > p.transformMaxEnergy) {
            p.transformEnergy = p.transformMaxEnergy;
          }
        }
```

- [ ] **Step 3: Add energy recovery on boss kill**

In the boss death section (after `boss.defeated = true`), add:

```typescript
        // Transform energy recovery on boss kill
        if (this.player !== null && this.player.isTransformed) {
          this.player.transformEnergy += TRANSFORM_ENERGY_KILL_BOSS;
          if (this.player.transformEnergy > this.player.transformMaxEnergy) {
            this.player.transformEnergy = this.player.transformMaxEnergy;
          }
        }
```

- [ ] **Step 4: Verify update/render loop ordering**

Confirm the update loop order:
```
updatePlayer → updateTransformSystem → updateEnemies → updateBosses → ...
```

Confirm the render loop includes transform rendering via the renderPlayer branch.

- [ ] **Step 5: Test full flow**

Verify:
1. Player starts with no transforms unlocked
2. Defeat Mushroom King → transform core drops → collect → Slime form unlocked
3. Tap transform button → Slime form activates → weapon replaced
4. Energy drains over time → attack costs energy → kill enemies to recover
5. Energy hits 0 → auto revert → cooldown starts
6. Defeat more bosses → unlock more forms → form selection panel works
7. Ghost form phases through walls
8. Iron Man flies over terrain, immune to traps
9. Armor dash damages enemies, rider kick pierces

- [ ] **Step 6: Final commit**

```bash
git add entry/src/main/ets/game/GameEngine.ets
git commit -m "feat: transform system final integration — energy recovery hooks and verification"
```
