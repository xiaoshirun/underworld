import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE, PLAYER_SPEED,
  DASH_SPEED, DASH_DURATION, DASH_COOLDOWN, ATTACK_DURATION, ATTACK_COOLDOWN,
  ATTACK_RANGE, ATTACK_WIDTH, PLAYER_MAX_HP, INVINCIBLE_DURATION,
  SLIME_SIZE, SLIME_SPEED, PURPLE_SLIME_SPEED, PURPLE_SLIME_DETECT,
  RED_SLIME_SPEED, RED_SLIME_DETECT, BLUE_SLIME_SPEED,
  SLIME_DAMAGE, SLIME_KNOCKBACK,
  ENGULF_DAMAGE_INTERVAL, ENGULF_ESCAPE_ATTACKS, DRILL_BREAK_HITS,
  XP_ORB_SIZE, XP_COLLECT_RANGE, XP_MAGNET_RANGE, LEVEL_UP_XP,
  CHUNK_LOAD_RADIUS,
  MINIMAP_SIZE, FRAME_INTERVAL, MINIMAP_UPDATE_INTERVAL,
  TileType, EnemyType, BiomeType, PlayerState, SlimeState, XpOrb, Particle,
  ChunkData, InputState, GameSettings, AmbientParticle,
  COLOR_BG, COLOR_WALL, COLOR_WALL_EDGE, COLOR_FLOOR, COLOR_FLOOR_VAR,
  COLOR_WATER, COLOR_WATER_LIGHT, COLOR_LAVA, COLOR_LAVA_LIGHT,
  COLOR_CRYSTAL, COLOR_CRYSTAL_GLOW,
  COLOR_MUSHROOM_CAP, COLOR_MUSHROOM_STEM, COLOR_MUSHROOM_GLOW,
  COLOR_GLOW_STONE, COLOR_GLOW, COLOR_PLANT, COLOR_PLANT_LIGHT,
  COLOR_PLAYER_SKIN, COLOR_PLAYER_HAIR, COLOR_PLAYER_BODY, COLOR_PLAYER_BODY_DARK,
  COLOR_DRILL_BASE, COLOR_DRILL_TIP,
  COLOR_SLIME_GRAY, COLOR_SLIME_GRAY_LIGHT, COLOR_SLIME_PURPLE, COLOR_SLIME_PURPLE_LIGHT,
  COLOR_SLIME_RED, COLOR_SLIME_RED_LIGHT, COLOR_SLIME_BLUE, COLOR_SLIME_BLUE_LIGHT,
  COLOR_SLIME_YELLOW, COLOR_SLIME_YELLOW_LIGHT, COLOR_SLIME_GHOST, COLOR_SLIME_GHOST_LIGHT,
  COLOR_SLIME_EYE, COLOR_SLIME_PUPIL,
  COLOR_XP_ORB, COLOR_XP_GLOW,
  COLOR_MINIMAP_BG, COLOR_MINIMAP_PLAYER, COLOR_MINIMAP_ENEMY,
  COLOR_ATTACK_FLASH, COLOR_DAMAGE_PARTICLE, COLOR_DRILL_PARTICLE
} from './GameConstants';
import { WorldGenerator } from './WorldGenerator';
import { AudioManager } from './AudioManager';

export class GameEngine {
  private ctx: CanvasRenderingContext2D | null = null;
  private minimapCtx: CanvasRenderingContext2D | null = null;
  private worldGen: WorldGenerator = new WorldGenerator();
  private chunks: Map<string, ChunkData> = new Map();
  private player: PlayerState | null = null;
  private enemies: SlimeState[] = [];
  private xpOrbs: XpOrb[] = [];
  private particles: Particle[] = [];
  private cameraX: number = 0;
  private cameraY: number = 0;
  private screenW: number = 0;
  private screenH: number = 0;
  private gameLoopId: number = -1;
  private frameCount: number = 0;
  private shakeX: number = 0;
  private shakeY: number = 0;
  private shakeTimer: number = 0;
  private audio: AudioManager = new AudioManager();
  private settings: GameSettings = { soundEnabled: true, effectsEnabled: true };
  private ambientParticles: AmbientParticle[] = [];
  private input: InputState = {
    joyActive: false, joyDx: 0, joyDy: 0,
    jumpPressed: false, attackPressed: false, dashPressed: false, attackHeld: false
  };

  init(ctx: CanvasRenderingContext2D, minimapCtx: CanvasRenderingContext2D, screenW: number, screenH: number): void {
    this.ctx = ctx;
    this.minimapCtx = minimapCtx;
    this.screenW = screenW;
    this.screenH = screenH;

    this.loadChunksAround(0, 0);

    const startX: number = CHUNK_SIZE * TILE_SIZE / 2;
    const startY: number = CHUNK_SIZE * TILE_SIZE / 2;
    this.player = {
      x: startX, y: startY, vx: 0, vy: 0, hp: PLAYER_MAX_HP,
      facing: 0, isAttacking: false, attackTimer: 0,
      isDashing: false, dashTimer: 0, dashCooldown: 0, dashDirX: 0, dashDirY: 0,
      isJumping: false, jumpTimer: 0, jumpHeight: 0, invincibleTimer: 0, animFrame: 0,
      xp: 0, level: 1,
      isEngulfed: false, engulfSlimeIndex: -1, engulfEscapeCount: 0, engulfDamageTimer: 0,
      isDrilling: false, drillTargetX: 0, drillTargetY: 0, drillHitCount: 0
    };

    this.cameraX = startX - screenW / 2;
    this.cameraY = startY - screenH / 2;
    this.initAmbientParticles();
    this.startLoop();
  }

  private startLoop(): void {
    this.gameLoopId = setInterval(() => {
      this.update(FRAME_INTERVAL);
      this.render();
      this.frameCount++;
    }, FRAME_INTERVAL);
  }

  destroy(): void {
    if (this.gameLoopId !== -1) {
      clearInterval(this.gameLoopId);
      this.gameLoopId = -1;
    }
  }

  setInputJoy(active: boolean, dx: number, dy: number): void {
    this.input.joyActive = active;
    this.input.joyDx = dx;
    this.input.joyDy = dy;
  }

  setInputJump(pressed: boolean): void {
    this.input.jumpPressed = pressed;
  }

  setInputAttack(pressed: boolean): void {
    this.input.attackPressed = pressed;
  }

  setInputDash(pressed: boolean): void {
    this.input.dashPressed = pressed;
  }

  getPlayerHp(): number {
    return this.player === null ? 0 : this.player.hp;
  }

  getPlayerXp(): number {
    return this.player === null ? 0 : this.player.xp;
  }

  getPlayerLevel(): number {
    return this.player === null ? 1 : this.player.level;
  }

  getLevelUpXp(): number {
    return LEVEL_UP_XP;
  }

  getSettings(): GameSettings {
    return this.settings;
  }

  setSettings(s: GameSettings): void {
    this.settings = s;
    this.audio.setSettings(s);
  }

  private chunkKey(cx: number, cy: number): string {
    return cx + ',' + cy;
  }

  private loadChunksAround(tileX: number, tileY: number): void {
    const pcx: number = Math.floor(tileX / CHUNK_SIZE);
    const pcy: number = Math.floor(tileY / CHUNK_SIZE);
    for (let dy: number = -CHUNK_LOAD_RADIUS; dy <= CHUNK_LOAD_RADIUS; dy++) {
      for (let dx: number = -CHUNK_LOAD_RADIUS; dx <= CHUNK_LOAD_RADIUS; dx++) {
        const cx: number = pcx + dx;
        const cy: number = pcy + dy;
        const key: string = this.chunkKey(cx, cy);
        if (!this.chunks.has(key)) {
          const chunk: ChunkData = this.worldGen.generateChunk(cx, cy);
          this.chunks.set(key, chunk);
          for (let i: number = 0; i < chunk.enemies.length; i++) {
            this.enemies.push(chunk.enemies[i]);
          }
        }
      }
    }
  }

  getTile(worldX: number, worldY: number): number {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = this.chunkKey(cx, cy);
    const chunk: ChunkData | undefined = this.chunks.get(key);
    if (chunk === undefined) return TileType.WALL;
    const lx: number = tx - cx * CHUNK_SIZE;
    const ly: number = ty - cy * CHUNK_SIZE;
    return chunk.tiles[ly][lx];
  }

  setTile(worldX: number, worldY: number, tileType: number): void {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = this.chunkKey(cx, cy);
    const chunk: ChunkData | undefined = this.chunks.get(key);
    if (chunk === undefined) return;
    const lx: number = tx - cx * CHUNK_SIZE;
    const ly: number = ty - cy * CHUNK_SIZE;
    chunk.tiles[ly][lx] = tileType;
  }

  private isWalkable(tile: number): boolean {
    return tile !== TileType.WALL && tile !== TileType.VOID;
  }

  private update(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    const ptx: number = Math.floor(p.x / TILE_SIZE);
    const pty: number = Math.floor(p.y / TILE_SIZE);
    this.loadChunksAround(ptx, pty);

    this.updatePlayer(p, dt);
    this.updateEnemies(dt);
    this.updateXpOrbs(dt);
    this.updateParticles(dt);
    this.updateAmbientParticles(dt);
    this.updateCamera(p);
    this.updateShake(dt);
  }

  private updatePlayer(p: PlayerState, dt: number): void {
    if (p.isEngulfed) {
      this.updateEngulfedPlayer(p, dt);
      return;
    }

    let moveX: number = 0;
    let moveY: number = 0;

    if (this.input.joyActive) {
      const len: number = Math.sqrt(this.input.joyDx * this.input.joyDx + this.input.joyDy * this.input.joyDy);
      if (len > 0.1) {
        moveX = this.input.joyDx / len;
        moveY = this.input.joyDy / len;
        p.facing = Math.atan2(this.input.joyDy, this.input.joyDx);
      }
    }

    if (p.isDrilling) {
      this.updateDrilling(p, dt);
      return;
    }

    if (p.isDashing) {
      p.dashTimer -= dt;
      if (p.dashTimer <= 0) {
        p.isDashing = false;
      } else {
        p.vx = p.dashDirX * DASH_SPEED;
        p.vy = p.dashDirY * DASH_SPEED;
        if (this.settings.effectsEnabled && this.frameCount % 3 === 0) {
          this.spawnParticle(p.x, p.y + PLAYER_SIZE / 2, 0, 0, 200, COLOR_PLAYER_BODY, 4);
        }
      }
    } else {
      p.vx = moveX * PLAYER_SPEED;
      p.vy = moveY * PLAYER_SPEED;
    }

    const newX: number = p.x + p.vx;
    const newY: number = p.y + p.vy;
    if (!this.checkPlayerCollision(newX, p.y)) {
      p.x = newX;
    }
    if (!this.checkPlayerCollision(p.x, newY)) {
      p.y = newY;
    }

    if (this.input.jumpPressed && !p.isJumping) {
      p.isJumping = true;
      p.jumpTimer = 300;
      this.input.jumpPressed = false;
      this.audio.playJump();
    }
    if (p.isJumping) {
      p.jumpTimer -= dt;
      const progress: number = 1.0 - (p.jumpTimer / 300);
      p.jumpHeight = Math.sin(progress * Math.PI) * 12;
      if (p.jumpTimer <= 0) {
        p.isJumping = false;
        p.jumpHeight = 0;
      }
    }

    if (this.input.attackPressed && !p.isAttacking && p.attackTimer <= 0) {
      p.isAttacking = true;
      p.attackTimer = ATTACK_DURATION;
      this.input.attackPressed = false;
      this.performAttack(p);
    }
    if (p.isAttacking) {
      p.attackTimer -= dt;
      if (p.attackTimer <= 0) {
        p.isAttacking = false;
        p.attackTimer = ATTACK_COOLDOWN - ATTACK_DURATION;
      }
    } else if (p.attackTimer > 0) {
      p.attackTimer -= dt;
    }

    if (this.input.dashPressed && !p.isDashing && p.dashCooldown <= 0) {
      p.isDashing = true;
      p.dashTimer = DASH_DURATION;
      p.dashCooldown = DASH_COOLDOWN;
      p.invincibleTimer = DASH_DURATION;
      const dx: number = Math.cos(p.facing);
      const dy: number = Math.sin(p.facing);
      p.dashDirX = dx;
      p.dashDirY = dy;
      this.input.dashPressed = false;
      this.audio.playDash();
    }
    if (p.dashCooldown > 0) p.dashCooldown -= dt;
    if (p.invincibleTimer > 0) p.invincibleTimer -= dt;

    if (Math.abs(p.vx) > 0.1 || Math.abs(p.vy) > 0.1) {
      p.animFrame += 0.15;
    }
  }

  private updateDrilling(p: PlayerState, dt: number): void {
    const wallWorldX: number = p.drillTargetX * TILE_SIZE + TILE_SIZE / 2;
    const wallWorldY: number = p.drillTargetY * TILE_SIZE + TILE_SIZE / 2;
    p.facing = Math.atan2(wallWorldY - p.y, wallWorldX - p.x);

    if (this.frameCount % 5 === 0) {
      this.audio.playDrillHit();
      if (this.settings.effectsEnabled) {
        const angle: number = Math.random() * Math.PI * 2;
        this.spawnParticle(wallWorldX, wallWorldY,
          Math.cos(angle) * 2, Math.sin(angle) * 2, 200, COLOR_DRILL_PARTICLE, 3);
      }
    }

    if (this.input.attackPressed) {
      p.drillHitCount++;
      this.input.attackPressed = false;
      this.audio.playDrillHit();
      if (p.drillHitCount >= DRILL_BREAK_HITS) {
        this.setTile(wallWorldX, wallWorldY, TileType.BROKEN_WALL);
        this.audio.playWallBreak();
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 8; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 3;
            this.spawnParticle(wallWorldX, wallWorldY,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 400, COLOR_WALL, 4);
          }
        }
        p.isDrilling = false;
        p.drillHitCount = 0;
      }
    }

    if (!this.input.attackHeld && p.drillHitCount > 0) {
      const elapsed: number = p.drillHitCount * 200;
      if (elapsed > 1000) {
        p.isDrilling = false;
        p.drillHitCount = 0;
      }
    }
  }

  private updateEngulfedPlayer(p: PlayerState, dt: number): void {
    p.engulfDamageTimer -= dt;
    if (p.engulfDamageTimer <= 0) {
      p.hp -= SLIME_DAMAGE;
      if (p.hp < 0) p.hp = 0;
      p.engulfDamageTimer = ENGULF_DAMAGE_INTERVAL;
      this.audio.playPlayerDamage();
      this.shakeTimer = 100;
    }

    if (p.engulfEscapeCount >= ENGULF_ESCAPE_ATTACKS) {
      p.isEngulfed = false;
      if (p.engulfSlimeIndex >= 0 && p.engulfSlimeIndex < this.enemies.length) {
        const s: SlimeState = this.enemies[p.engulfSlimeIndex];
        s.isEngulfing = false;
        s.engulfedPlayer = false;
        const angle: number = Math.random() * Math.PI * 2;
        p.x = s.x + Math.cos(angle) * 20;
        p.y = s.y + Math.sin(angle) * 20;
      }
      p.engulfSlimeIndex = -1;
      p.engulfEscapeCount = 0;
      p.invincibleTimer = INVINCIBLE_DURATION;
    }
  }

  private checkPlayerCollision(x: number, y: number): boolean {
    const halfSize: number = PLAYER_SIZE / 2;
    const cornersX: number[] = [x - halfSize, x + halfSize];
    const cornersY: number[] = [y - halfSize, y + halfSize];
    for (let i: number = 0; i < 2; i++) {
      for (let j: number = 0; j < 2; j++) {
        const tile: number = this.getTile(cornersX[i], cornersY[j]);
        if (!this.isWalkable(tile)) return true;
      }
    }
    return false;
  }

  private performAttack(p: PlayerState): void {
    if (p.isEngulfed) {
      p.engulfEscapeCount++;
      this.audio.playEnemyHit();
      this.shakeTimer = 80;
      return;
    }

    const attackX: number = p.x + Math.cos(p.facing) * ATTACK_RANGE;
    const attackY: number = p.y + Math.sin(p.facing) * ATTACK_RANGE;

    const wallTX: number = Math.floor(attackX / TILE_SIZE);
    const wallTY: number = Math.floor(attackY / TILE_SIZE);
    const wallTile: number = this.getTile(wallTX * TILE_SIZE, wallTY * TILE_SIZE);
    if (wallTile === TileType.WALL) {
      p.isDrilling = true;
      p.drillTargetX = wallTX;
      p.drillTargetY = wallTY;
      p.drillHitCount = 0;
      p.vx = 0;
      p.vy = 0;
    }

    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;
      const dx: number = s.x - attackX;
      const dy: number = s.y - attackY;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist < ATTACK_WIDTH + s.size) {
        s.hp--;
        s.hitFlash = 150;
        const knockAngle: number = Math.atan2(dy, dx);
        s.vx = Math.cos(knockAngle) * SLIME_KNOCKBACK;
        s.vy = Math.sin(knockAngle) * SLIME_KNOCKBACK;
        this.shakeTimer = 100;
        this.audio.playEnemyHit();
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 6; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 3;
            this.spawnParticle(s.x, s.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 300, COLOR_DAMAGE_PARTICLE, 3);
          }
        }
        if (s.hp <= 0) {
          this.onEnemyDeath(s);
        }
      }
    }

    if (this.settings.effectsEnabled) {
      for (let k: number = 0; k < 3; k++) {
        const spread: number = (Math.random() - 0.5) * 0.8;
        const angle: number = p.facing + spread;
        const speed: number = 2 + Math.random() * 2;
        this.spawnParticle(attackX, attackY,
          Math.cos(angle) * speed, Math.sin(angle) * speed, 200, COLOR_ATTACK_FLASH, 2);
      }
    }
  }

  private onEnemyDeath(s: SlimeState): void {
    s.active = false;
    this.audio.playEnemyDeath();
    if (this.settings.effectsEnabled) {
      for (let k: number = 0; k < 10; k++) {
        const angle: number = Math.random() * Math.PI * 2;
        const speed: number = 1 + Math.random() * 2;
        this.spawnParticle(s.x, s.y,
          Math.cos(angle) * speed, Math.sin(angle) * speed, 500, this.getEnemyColor(s), 4);
      }
    }
    const orbCount: number = 1 + Math.floor(Math.random() * 3);
    for (let k: number = 0; k < orbCount; k++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 5 + Math.random() * 15;
      this.xpOrbs.push({
        x: s.x + Math.cos(angle) * dist,
        y: s.y + Math.sin(angle) * dist,
        value: 1, bobPhase: Math.random() * Math.PI * 2, active: true
      });
    }
  }

  private getEnemyColor(s: SlimeState): string {
    switch (s.enemyType) {
      case EnemyType.GRAY_SLIME: return COLOR_SLIME_GRAY_LIGHT;
      case EnemyType.PURPLE_SLIME: return COLOR_SLIME_PURPLE_LIGHT;
      case EnemyType.RED_SLIME: return COLOR_SLIME_RED_LIGHT;
      case EnemyType.BLUE_SLIME: return COLOR_SLIME_BLUE_LIGHT;
      case EnemyType.YELLOW_SLIME: return COLOR_SLIME_YELLOW_LIGHT;
      case EnemyType.GHOST_SLIME: return COLOR_SLIME_GHOST_LIGHT;
      default: return COLOR_SLIME_GRAY_LIGHT;
    }
  }

  private updateEnemies(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;

      s.bouncePhase += 0.05;
      if (s.hitFlash > 0) s.hitFlash -= dt;
      s.vx *= 0.9;
      s.vy *= 0.9;

      if (s.isEngulfing) continue;

      const dx: number = p.x - s.x;
      const dy: number = p.y - s.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (s.enemyType) {
        case EnemyType.GRAY_SLIME: {
          s.moveTimer -= dt;
          if (s.moveTimer <= 0) {
            s.moveTimer = 2000 + Math.random() * 3000;
            const angle: number = Math.random() * Math.PI * 2;
            s.targetX = Math.cos(angle) * SLIME_SPEED;
            s.targetY = Math.sin(angle) * SLIME_SPEED;
          }
          s.vx += s.targetX * 0.02;
          s.vy += s.targetY * 0.02;
          break;
        }
        case EnemyType.PURPLE_SLIME: {
          if (dist < PURPLE_SLIME_DETECT && dist > 1) {
            s.vx += (dx / dist) * PURPLE_SLIME_SPEED * 0.1;
            s.vy += (dy / dist) * PURPLE_SLIME_SPEED * 0.1;
            if (dist < s.size + PLAYER_SIZE && p.invincibleTimer <= 0 && !p.isEngulfed) {
              if (Math.random() < 0.01) {
                s.isEngulfing = true;
                s.engulfedPlayer = true;
                p.isEngulfed = true;
                p.engulfSlimeIndex = i;
                p.engulfEscapeCount = 0;
                p.engulfDamageTimer = ENGULF_DAMAGE_INTERVAL;
                this.audio.playEngulf();
              }
            }
          }
          break;
        }
        case EnemyType.RED_SLIME: {
          if (dist < RED_SLIME_DETECT && dist > 1) {
            if (!s.isCharging) {
              s.chargeTimer -= dt;
              if (s.chargeTimer <= 0) {
                s.isCharging = true;
                s.chargeTimer = 500;
                s.vx = (dx / dist) * RED_SLIME_SPEED * 2;
                s.vy = (dy / dist) * RED_SLIME_SPEED * 2;
              } else {
                s.vx += (dx / dist) * RED_SLIME_SPEED * 0.03;
                s.vy += (dy / dist) * RED_SLIME_SPEED * 0.03;
              }
            } else {
              s.chargeTimer -= dt;
              if (s.chargeTimer <= 0) {
                s.isCharging = false;
                s.chargeTimer = 1500;
              }
            }
          }
          break;
        }
        case EnemyType.BLUE_SLIME: {
          if (dist < PURPLE_SLIME_DETECT && dist > 1) {
            s.vx += (dx / dist) * BLUE_SLIME_SPEED * 0.05;
            s.vy += (dy / dist) * BLUE_SLIME_SPEED * 0.05;
          }
          s.moveTimer -= dt;
          if (s.moveTimer <= 0) {
            s.moveTimer = 1500 + Math.random() * 2000;
            const angle: number = Math.random() * Math.PI * 2;
            s.targetX = Math.cos(angle) * BLUE_SLIME_SPEED * 0.5;
            s.targetY = Math.sin(angle) * BLUE_SLIME_SPEED * 0.5;
          }
          s.vx += s.targetX * 0.01;
          s.vy += s.targetY * 0.01;
          break;
        }
        case EnemyType.YELLOW_SLIME: {
          s.moveTimer -= dt;
          if (s.moveTimer <= 0) {
            s.moveTimer = 3000 + Math.random() * 2000;
            const angle: number = Math.random() * Math.PI * 2;
            s.targetX = Math.cos(angle) * SLIME_SPEED * 0.5;
            s.targetY = Math.sin(angle) * SLIME_SPEED * 0.5;
          }
          s.vx += s.targetX * 0.01;
          s.vy += s.targetY * 0.01;
          break;
        }
        case EnemyType.GHOST_SLIME: {
          if (dist < PURPLE_SLIME_DETECT * 1.5 && dist > 1) {
            const speed: number = PURPLE_SLIME_SPEED * 0.8;
            s.vx += (dx / dist) * speed * 0.08;
            s.vy += (dy / dist) * speed * 0.08;
          }
          break;
        }
      }

      let maxSpeed: number = SLIME_SPEED;
      switch (s.enemyType) {
        case EnemyType.PURPLE_SLIME: maxSpeed = PURPLE_SLIME_SPEED; break;
        case EnemyType.RED_SLIME: maxSpeed = s.isCharging ? RED_SLIME_SPEED * 2 : RED_SLIME_SPEED; break;
        case EnemyType.BLUE_SLIME: maxSpeed = BLUE_SLIME_SPEED; break;
        case EnemyType.GHOST_SLIME: maxSpeed = PURPLE_SLIME_SPEED * 0.8; break;
        default: maxSpeed = SLIME_SPEED; break;
      }
      const speed: number = Math.sqrt(s.vx * s.vx + s.vy * s.vy);
      if (speed > maxSpeed) {
        s.vx = (s.vx / speed) * maxSpeed;
        s.vy = (s.vy / speed) * maxSpeed;
      }

      const newX: number = s.x + s.vx;
      const newY: number = s.y + s.vy;
      if (s.enemyType === EnemyType.GHOST_SLIME) {
        s.x = newX;
        s.y = newY;
      } else {
        if (!this.checkEnemyCollision(newX, s.y)) { s.x = newX; } else { s.vx = -s.vx; }
        if (!this.checkEnemyCollision(s.x, newY)) { s.y = newY; } else { s.vy = -s.vy; }
      }

      if (p.invincibleTimer <= 0 && !p.isEngulfed && !s.isEngulfing) {
        const cdx: number = p.x - s.x;
        const cdy: number = p.y - s.y;
        const cdist: number = Math.sqrt(cdx * cdx + cdy * cdy);
        if (cdist < PLAYER_SIZE / 2 + s.size / 2) {
          p.hp -= SLIME_DAMAGE;
          if (p.hp < 0) p.hp = 0;
          p.invincibleTimer = INVINCIBLE_DURATION;
          const knockAngle: number = Math.atan2(cdy, cdx);
          p.x -= Math.cos(knockAngle) * 5;
          p.y -= Math.sin(knockAngle) * 5;
          this.shakeTimer = 150;
          this.audio.playPlayerDamage();
          if (this.settings.effectsEnabled) {
            for (let k: number = 0; k < 4; k++) {
              const angle: number = Math.random() * Math.PI * 2;
              const spd: number = 1 + Math.random() * 2;
              this.spawnParticle(p.x, p.y,
                Math.cos(angle) * spd, Math.sin(angle) * spd, 300, COLOR_DAMAGE_PARTICLE, 3);
            }
          }
        }
      }
    }
  }

  private checkEnemyCollision(x: number, y: number): boolean {
    const halfSize: number = SLIME_SIZE / 2;
    const cornersX: number[] = [x - halfSize, x + halfSize];
    const cornersY: number[] = [y - halfSize, y + halfSize];
    for (let i: number = 0; i < 2; i++) {
      for (let j: number = 0; j < 2; j++) {
        const tile: number = this.getTile(cornersX[i], cornersY[j]);
        if (!this.isWalkable(tile)) return true;
      }
    }
    return false;
  }

  private updateXpOrbs(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = 0; i < this.xpOrbs.length; i++) {
      const orb: XpOrb = this.xpOrbs[i];
      if (!orb.active) continue;

      orb.bobPhase += 0.08;

      const dx: number = p.x - orb.x;
      const dy: number = p.y - orb.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < XP_MAGNET_RANGE && dist > 1) {
        const pullSpeed: number = 3.0 * (1.0 - dist / XP_MAGNET_RANGE);
        orb.x += (dx / dist) * pullSpeed;
        orb.y += (dy / dist) * pullSpeed;
      }

      if (dist < XP_COLLECT_RANGE) {
        orb.active = false;
        p.xp += orb.value;
        this.audio.playXpCollect();
        if (p.xp >= LEVEL_UP_XP) {
          p.xp -= LEVEL_UP_XP;
          p.level++;
          if (p.hp < PLAYER_MAX_HP) p.hp++;
          this.audio.playLevelUp();
          if (this.settings.effectsEnabled) {
            for (let k: number = 0; k < 15; k++) {
              const angle: number = Math.random() * Math.PI * 2;
              const speed: number = 2 + Math.random() * 3;
              this.spawnParticle(p.x, p.y,
                Math.cos(angle) * speed, Math.sin(angle) * speed, 600, COLOR_XP_ORB, 4);
            }
          }
        }
      }
    }

    if (this.xpOrbs.length > 200) {
      const active: XpOrb[] = [];
      for (let i: number = 0; i < this.xpOrbs.length; i++) {
        if (this.xpOrbs[i].active) active.push(this.xpOrbs[i]);
      }
      this.xpOrbs = active;
    }
  }

  private spawnParticle(x: number, y: number, vx: number, vy: number, life: number, color: string, size: number): void {
    this.particles.push({ x: x, y: y, vx: vx, vy: vy, life: life, maxLife: life, color: color, size: size });
  }

  private updateParticles(dt: number): void {
    for (let i: number = this.particles.length - 1; i >= 0; i--) {
      const pt: Particle = this.particles[i];
      pt.x += pt.vx;
      pt.y += pt.vy;
      pt.vx *= 0.95;
      pt.vy *= 0.95;
      pt.life -= dt;
      if (pt.life <= 0) {
        this.particles.splice(i, 1);
      }
    }
  }

  private updateCamera(p: PlayerState): void {
    const targetX: number = p.x - this.screenW / 2;
    const targetY: number = p.y - this.screenH / 2;
    this.cameraX += (targetX - this.cameraX) * 0.1;
    this.cameraY += (targetY - this.cameraY) * 0.1;
  }

  private updateShake(dt: number): void {
    if (this.shakeTimer > 0) {
      this.shakeTimer -= dt;
      const intensity: number = 3 * (this.shakeTimer / 150);
      this.shakeX = (Math.random() - 0.5) * intensity * 2;
      this.shakeY = (Math.random() - 0.5) * intensity * 2;
    } else {
      this.shakeX = 0;
      this.shakeY = 0;
    }
  }

  private render(): void {
    if (this.ctx === null || this.player === null) return;
    const c: CanvasRenderingContext2D = this.ctx;
    const p: PlayerState = this.player;

    c.clearRect(0, 0, this.screenW, this.screenH);
    c.fillStyle = COLOR_BG;
    c.fillRect(0, 0, this.screenW, this.screenH);

    const offX: number = -this.cameraX + this.shakeX;
    const offY: number = -this.cameraY + this.shakeY;

    this.renderWorld(c, offX, offY);
    this.renderPlayerLight(c, offX, offY, p);
    this.renderXpOrbs(c, offX, offY);
    this.renderEnemies(c, offX, offY);
    this.renderPlayer(c, offX, offY, p);
    this.renderParticles(c, offX, offY);
    this.renderAmbientParticles(c);
    this.renderVignette(c);

    if (this.frameCount % MINIMAP_UPDATE_INTERVAL === 0) {
      this.renderMinimap();
    }
  }

  private renderWorld(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    const startTX: number = Math.floor(this.cameraX / TILE_SIZE) - 1;
    const startTY: number = Math.floor(this.cameraY / TILE_SIZE) - 1;
    const endTX: number = Math.ceil((this.cameraX + this.screenW) / TILE_SIZE) + 1;
    const endTY: number = Math.ceil((this.cameraY + this.screenH) / TILE_SIZE) + 1;

    for (let ty: number = startTY; ty <= endTY; ty++) {
      for (let tx: number = startTX; tx <= endTX; tx++) {
        const screenX: number = tx * TILE_SIZE + offX;
        const screenY: number = ty * TILE_SIZE + offY;
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);

        if (tile === TileType.WALL) {
          c.fillStyle = COLOR_WALL;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.fillStyle = COLOR_WALL_EDGE;
          c.fillRect(screenX, screenY, TILE_SIZE, 2);
          c.fillRect(screenX, screenY, 2, TILE_SIZE);
          const hash: number = ((tx * 31 + ty * 17) % 5);
          if (hash === 0) {
            c.fillStyle = '#1f1f35';
            c.fillRect(screenX + 8, screenY + 8, 4, 3);
          } else if (hash === 1) {
            c.fillStyle = '#1f1f35';
            c.fillRect(screenX + 20, screenY + 18, 5, 3);
          } else if (hash === 2) {
            c.fillStyle = '#22223a';
            c.fillRect(screenX + 14, screenY + 4, 3, 5);
          }
        } else if (tile === TileType.FLOOR) {
          const variant: number = ((tx * 7 + ty * 13) % 3);
          c.fillStyle = variant === 0 ? COLOR_FLOOR : COLOR_FLOOR_VAR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          if (variant === 1) {
            c.fillStyle = '#1e1e38';
            c.fillRect(screenX + 8, screenY + 12, 3, 3);
          } else if (variant === 2) {
            c.fillStyle = '#0e0e1a';
            c.fillRect(screenX + 20, screenY + 6, 2, 2);
            c.fillRect(screenX + 4, screenY + 22, 2, 1);
          }
          c.fillStyle = '#0a0a14';
          c.globalAlpha = 0.15;
          c.fillRect(screenX, screenY + TILE_SIZE - 1, TILE_SIZE, 1);
          c.fillRect(screenX + TILE_SIZE - 1, screenY, 1, TILE_SIZE);
          c.globalAlpha = 1.0;
        } else if (tile === TileType.BROKEN_WALL) {
          c.fillStyle = '#2a2a3e';
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.fillStyle = '#3a3a4e';
          c.fillRect(screenX + 4, screenY + 4, 6, 4);
          c.fillRect(screenX + 18, screenY + 14, 8, 5);
          c.fillRect(screenX + 8, screenY + 22, 5, 6);
        } else if (tile === TileType.GLOW_STONE) {
          c.fillStyle = COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const glowR: number = 20 + Math.sin(this.frameCount * 0.05 + tx) * 4;
          c.globalAlpha = 0.15;
          c.fillStyle = COLOR_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, glowR, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = COLOR_GLOW_STONE;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, 5, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#fff8dc';
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2 - 1, screenY + TILE_SIZE / 2 - 1, 2, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.PLANT) {
          c.fillStyle = COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.fillStyle = COLOR_PLANT;
          c.fillRect(screenX + 14, screenY + 16, 4, 12);
          c.fillStyle = COLOR_PLANT_LIGHT;
          c.beginPath();
          c.arc(screenX + 16, screenY + 14, 6, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = COLOR_PLANT;
          c.beginPath();
          c.arc(screenX + 12, screenY + 18, 4, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.WATER) {
          const waveOff: number = Math.sin(this.frameCount * 0.03 + tx * 0.5) * 2;
          c.fillStyle = COLOR_WATER;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.fillStyle = COLOR_WATER_LIGHT;
          c.globalAlpha = 0.4;
          c.fillRect(screenX + 4, screenY + 8 + waveOff, 24, 3);
          c.fillRect(screenX + 8, screenY + 20 - waveOff, 16, 2);
          c.globalAlpha = 1.0;
        } else if (tile === TileType.CRYSTAL) {
          c.fillStyle = COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const glow: number = 12 + Math.sin(this.frameCount * 0.04 + tx + ty) * 4;
          c.globalAlpha = 0.2;
          c.fillStyle = COLOR_CRYSTAL_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, glow, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = COLOR_CRYSTAL;
          c.beginPath();
          c.moveTo(screenX + TILE_SIZE / 2, screenY + 6);
          c.lineTo(screenX + TILE_SIZE / 2 + 6, screenY + TILE_SIZE / 2);
          c.lineTo(screenX + TILE_SIZE / 2, screenY + TILE_SIZE - 6);
          c.lineTo(screenX + TILE_SIZE / 2 - 6, screenY + TILE_SIZE / 2);
          c.closePath();
          c.fill();
          c.fillStyle = '#e0ffff';
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2 - 1, screenY + TILE_SIZE / 2 - 2, 2, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.MUSHROOM) {
          c.fillStyle = COLOR_FLOOR;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          c.globalAlpha = 0.15;
          c.fillStyle = COLOR_MUSHROOM_GLOW;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + TILE_SIZE / 2, 14, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.fillStyle = COLOR_MUSHROOM_STEM;
          c.fillRect(screenX + 13, screenY + 16, 6, 12);
          c.fillStyle = COLOR_MUSHROOM_CAP;
          c.beginPath();
          c.arc(screenX + TILE_SIZE / 2, screenY + 14, 9, Math.PI, 0);
          c.fill();
          c.fillStyle = '#ffffff';
          c.beginPath();
          c.arc(screenX + 13, screenY + 11, 2, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(screenX + 19, screenY + 9, 1.5, 0, Math.PI * 2);
          c.fill();
        } else if (tile === TileType.LAVA) {
          c.fillStyle = COLOR_LAVA;
          c.fillRect(screenX, screenY, TILE_SIZE, TILE_SIZE);
          const lavaOff: number = Math.sin(this.frameCount * 0.05 + tx * 0.7) * 3;
          c.fillStyle = COLOR_LAVA_LIGHT;
          c.globalAlpha = 0.6;
          c.fillRect(screenX + 4, screenY + 6 + lavaOff, 20, 4);
          c.fillRect(screenX + 10, screenY + 18 - lavaOff, 14, 3);
          c.globalAlpha = 1.0;
        }
      }
    }
  }

  private renderPlayer(c: CanvasRenderingContext2D, offX: number, offY: number, p: PlayerState): void {
    const screenX: number = p.x + offX;
    const screenY: number = p.y + offY - p.jumpHeight;
    const half: number = PLAYER_SIZE / 2;

    if (p.isEngulfed) {
      c.globalAlpha = 0.5 + Math.sin(this.frameCount * 0.2) * 0.3;
      c.fillStyle = COLOR_PLAYER_BODY;
      c.beginPath();
      c.arc(screenX, screenY, half * 0.6, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
      return;
    }

    if (p.invincibleTimer > 0 && Math.floor(this.frameCount / 3) % 2 === 0) {
      return;
    }

    if (p.isJumping) {
      c.globalAlpha = 0.3;
      c.fillStyle = '#000000';
      c.beginPath();
      c.ellipse(screenX, p.y + offY + half, half * 0.8, half * 0.3, 0, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    const bobY: number = Math.sin(p.animFrame) * 1.5;

    c.fillStyle = COLOR_PLAYER_BODY;
    c.fillRect(screenX - 5, screenY - 2 + bobY, 10, 10);
    c.fillStyle = COLOR_PLAYER_BODY_DARK;
    c.fillRect(screenX - 5, screenY + 4 + bobY, 10, 4);

    c.fillStyle = COLOR_PLAYER_SKIN;
    c.fillRect(screenX - 4, screenY - 7 + bobY, 8, 6);

    c.fillStyle = COLOR_PLAYER_HAIR;
    c.fillRect(screenX - 5, screenY - 9 + bobY, 10, 4);
    c.fillRect(screenX - 6, screenY - 7 + bobY, 2, 3);
    c.fillRect(screenX + 4, screenY - 7 + bobY, 2, 3);

    c.fillStyle = '#ffffff';
    c.fillRect(screenX - 2, screenY - 5 + bobY, 2, 2);
    c.fillRect(screenX + 1, screenY - 5 + bobY, 2, 2);
    c.fillStyle = '#1a1a2e';
    c.fillRect(screenX - 1, screenY - 4 + bobY, 1, 1);
    c.fillRect(screenX + 2, screenY - 4 + bobY, 1, 1);

    c.fillStyle = '#5b3a1a';
    c.fillRect(screenX - 4, screenY + 8 + bobY, 3, 4);
    c.fillRect(screenX + 1, screenY + 8 + bobY, 3, 4);

    this.renderDrill(c, screenX, screenY, p, bobY);
  }

  private renderDrill(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const drillLen: number = p.isAttacking ? 16 : (p.isDrilling ? 14 : 8);
    const drillOffX: number = Math.cos(p.facing) * (8 + (p.isAttacking || p.isDrilling ? 6 : 0));
    const drillOffY: number = Math.sin(p.facing) * (8 + (p.isAttacking || p.isDrilling ? 6 : 0));
    const baseX: number = sx + drillOffX;
    const baseY: number = sy + drillOffY + bobY;

    c.fillStyle = COLOR_DRILL_BASE;
    c.fillRect(baseX - 2, baseY - 2, 4, 4);

    const tipX: number = baseX + Math.cos(p.facing) * drillLen;
    const tipY: number = baseY + Math.sin(p.facing) * drillLen;
    c.strokeStyle = COLOR_DRILL_TIP;
    c.lineWidth = 3;
    c.beginPath();
    c.moveTo(baseX, baseY);
    c.lineTo(tipX, tipY);
    c.stroke();

    if (p.isAttacking || p.isDrilling) {
      c.fillStyle = COLOR_ATTACK_FLASH;
      c.globalAlpha = 0.6;
      c.beginPath();
      c.arc(tipX, tipY, 5 + Math.random() * 3, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }
  }

  private renderEnemies(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;

      const screenX: number = s.x + offX;
      const screenY: number = s.y + offY;

      if (screenX < -50 || screenX > this.screenW + 50 || screenY < -50 || screenY > this.screenH + 50) {
        continue;
      }

      const bounce: number = Math.sin(s.bouncePhase) * 2;
      const halfSize: number = s.size / 2;

      let baseColor: string = COLOR_SLIME_GRAY;
      let lightColor: string = COLOR_SLIME_GRAY_LIGHT;
      switch (s.enemyType) {
        case EnemyType.GRAY_SLIME: baseColor = COLOR_SLIME_GRAY; lightColor = COLOR_SLIME_GRAY_LIGHT; break;
        case EnemyType.PURPLE_SLIME: baseColor = COLOR_SLIME_PURPLE; lightColor = COLOR_SLIME_PURPLE_LIGHT; break;
        case EnemyType.RED_SLIME: baseColor = COLOR_SLIME_RED; lightColor = COLOR_SLIME_RED_LIGHT; break;
        case EnemyType.BLUE_SLIME: baseColor = COLOR_SLIME_BLUE; lightColor = COLOR_SLIME_BLUE_LIGHT; break;
        case EnemyType.YELLOW_SLIME: baseColor = COLOR_SLIME_YELLOW; lightColor = COLOR_SLIME_YELLOW_LIGHT; break;
        case EnemyType.GHOST_SLIME: baseColor = COLOR_SLIME_GHOST; lightColor = COLOR_SLIME_GHOST_LIGHT; break;
      }

      if (s.hitFlash > 0) {
        c.globalAlpha = 0.8;
        c.fillStyle = '#ffffff';
      } else {
        c.globalAlpha = s.enemyType === EnemyType.GHOST_SLIME ? 0.5 : 0.9;
        c.fillStyle = baseColor;
      }

      if (s.isEngulfing) {
        const engSize: number = halfSize * 1.4;
        c.beginPath();
        c.ellipse(screenX, screenY + bounce, engSize, engSize * 0.9, 0, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = lightColor;
        c.globalAlpha = 0.3;
        c.beginPath();
        c.ellipse(screenX, screenY + bounce + 2, engSize * 0.6, engSize * 0.4, 0, 0, Math.PI * 2);
        c.fill();
      } else {
        c.beginPath();
        c.ellipse(screenX, screenY + bounce, halfSize, halfSize * 0.8, 0, 0, Math.PI * 2);
        c.fill();

        c.fillStyle = lightColor;
        c.beginPath();
        c.ellipse(screenX - 1, screenY - 2 + bounce, halfSize * 0.5, halfSize * 0.4, 0, 0, Math.PI * 2);
        c.fill();
      }

      c.globalAlpha = 1.0;
      c.fillStyle = COLOR_SLIME_EYE;
      c.beginPath();
      c.arc(screenX - 3, screenY - 2 + bounce, 2, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(screenX + 3, screenY - 2 + bounce, 2, 0, Math.PI * 2);
      c.fill();

      c.fillStyle = COLOR_SLIME_PUPIL;
      c.beginPath();
      c.arc(screenX - 2.5, screenY - 1.5 + bounce, 1, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.arc(screenX + 3.5, screenY - 1.5 + bounce, 1, 0, Math.PI * 2);
      c.fill();

      if (s.isCharging) {
        c.globalAlpha = 0.4;
        c.fillStyle = COLOR_SLIME_RED;
        c.beginPath();
        c.arc(screenX, screenY + bounce, halfSize + 6, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      if (s.hp < s.maxHp) {
        const barW: number = halfSize * 2;
        const barH: number = 3;
        const barY: number = screenY - halfSize - 6 + bounce;
        c.fillStyle = '#374151';
        c.fillRect(screenX - barW / 2, barY, barW, barH);
        c.fillStyle = '#ef4444';
        c.fillRect(screenX - barW / 2, barY, barW * (s.hp / s.maxHp), barH);
      }
    }
  }

  private renderXpOrbs(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.xpOrbs.length; i++) {
      const orb: XpOrb = this.xpOrbs[i];
      if (!orb.active) continue;

      const screenX: number = orb.x + offX;
      const screenY: number = orb.y + offY;

      if (screenX < -20 || screenX > this.screenW + 20 || screenY < -20 || screenY > this.screenH + 20) {
        continue;
      }

      const bob: number = Math.sin(orb.bobPhase) * 2;

      c.globalAlpha = 0.2;
      c.fillStyle = COLOR_XP_GLOW;
      c.beginPath();
      c.arc(screenX, screenY + bob, XP_ORB_SIZE + 4, 0, Math.PI * 2);
      c.fill();

      c.globalAlpha = 0.9;
      c.fillStyle = COLOR_XP_ORB;
      c.beginPath();
      c.arc(screenX, screenY + bob, XP_ORB_SIZE, 0, Math.PI * 2);
      c.fill();

      c.globalAlpha = 1.0;
      c.fillStyle = '#ffffff';
      c.beginPath();
      c.arc(screenX - 1, screenY - 1 + bob, 2, 0, Math.PI * 2);
      c.fill();
    }
    c.globalAlpha = 1.0;
  }

  private renderParticles(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.particles.length; i++) {
      const pt: Particle = this.particles[i];
      const alpha: number = pt.life / pt.maxLife;
      c.globalAlpha = alpha;
      c.fillStyle = pt.color;
      const sz: number = pt.size * alpha;
      c.fillRect(pt.x + offX - sz / 2, pt.y + offY - sz / 2, sz, sz);
    }
    c.globalAlpha = 1.0;
  }

  private initAmbientParticles(): void {
    const colors: string[] = ['#ffd70033', '#00ced133', '#ff69b433', '#4ade8033', '#60a5fa33'];
    for (let i: number = 0; i < 30; i++) {
      this.ambientParticles.push({
        x: Math.random() * this.screenW,
        y: Math.random() * this.screenH,
        vx: (Math.random() - 0.5) * 0.3,
        vy: -0.1 - Math.random() * 0.3,
        size: 1 + Math.random() * 2.5,
        alpha: 0.1 + Math.random() * 0.25,
        color: colors[Math.floor(Math.random() * colors.length)],
        life: Math.random() * 4000,
        maxLife: 3000 + Math.random() * 3000
      });
    }
  }

  private updateAmbientParticles(dt: number): void {
    for (let i: number = 0; i < this.ambientParticles.length; i++) {
      const ap: AmbientParticle = this.ambientParticles[i];
      ap.x += ap.vx;
      ap.y += ap.vy;
      ap.life -= dt;
      if (ap.life <= 0 || ap.y < -10 || ap.x < -10 || ap.x > this.screenW + 10) {
        ap.x = Math.random() * this.screenW;
        ap.y = this.screenH + 5;
        ap.life = ap.maxLife;
        ap.alpha = 0.1 + Math.random() * 0.25;
      }
    }
  }

  private renderAmbientParticles(c: CanvasRenderingContext2D): void {
    if (!this.settings.effectsEnabled) return;
    for (let i: number = 0; i < this.ambientParticles.length; i++) {
      const ap: AmbientParticle = this.ambientParticles[i];
      const fadeRatio: number = ap.life / ap.maxLife;
      const alpha: number = ap.alpha * (fadeRatio < 0.2 ? fadeRatio / 0.2 : 1.0);
      c.globalAlpha = alpha;
      c.fillStyle = ap.color;
      c.beginPath();
      c.arc(ap.x, ap.y, ap.size, 0, Math.PI * 2);
      c.fill();
    }
    c.globalAlpha = 1.0;
  }

  private renderVignette(c: CanvasRenderingContext2D): void {
    const cx: number = this.screenW / 2;
    const cy: number = this.screenH / 2;
    const radius: number = Math.max(this.screenW, this.screenH) * 0.7;
    const gradient: CanvasGradient = c.createRadialGradient(cx, cy, radius * 0.4, cx, cy, radius);
    gradient.addColorStop(0, 'rgba(0,0,0,0)');
    gradient.addColorStop(1, 'rgba(0,0,0,0.45)');
    c.fillStyle = gradient;
    c.fillRect(0, 0, this.screenW, this.screenH);
  }

  private renderPlayerLight(c: CanvasRenderingContext2D, offX: number, offY: number, p: PlayerState): void {
    const screenX: number = p.x + offX;
    const screenY: number = p.y + offY;
    const radius: number = 120 + Math.sin(this.frameCount * 0.02) * 8;
    const gradient: CanvasGradient = c.createRadialGradient(screenX, screenY, 0, screenX, screenY, radius);
    gradient.addColorStop(0, 'rgba(255,200,100,0.06)');
    gradient.addColorStop(0.5, 'rgba(255,180,80,0.02)');
    gradient.addColorStop(1, 'rgba(0,0,0,0)');
    c.fillStyle = gradient;
    c.fillRect(screenX - radius, screenY - radius, radius * 2, radius * 2);
  }

  private renderMinimap(): void {
    if (this.minimapCtx === null || this.player === null) return;
    const mc: CanvasRenderingContext2D = this.minimapCtx;
    const size: number = MINIMAP_SIZE;
    const p: PlayerState = this.player;

    mc.fillStyle = COLOR_MINIMAP_BG;
    mc.fillRect(0, 0, size, size);

    const viewRange: number = 40;
    const playerTX: number = Math.floor(p.x / TILE_SIZE);
    const playerTY: number = Math.floor(p.y / TILE_SIZE);
    const scale: number = size / (viewRange * 2);

    for (let dy: number = -viewRange; dy <= viewRange; dy++) {
      for (let dx: number = -viewRange; dx <= viewRange; dx++) {
        const tx: number = playerTX + dx;
        const ty: number = playerTY + dy;
        const tile: number = this.getTile(tx * TILE_SIZE, ty * TILE_SIZE);
        const sx: number = (dx + viewRange) * scale;
        const sy: number = (dy + viewRange) * scale;

        if (tile === TileType.WALL) {
          mc.fillStyle = '#2a2a4e';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.GLOW_STONE) {
          mc.fillStyle = '#ffd700';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.CRYSTAL) {
          mc.fillStyle = '#00ced1';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.WATER) {
          mc.fillStyle = '#1a3a5c';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        } else if (tile === TileType.LAVA) {
          mc.fillStyle = '#8b2500';
          mc.fillRect(sx, sy, scale + 0.5, scale + 0.5);
        }
      }
    }

    for (let i: number = 0; i < this.enemies.length; i++) {
      const s: SlimeState = this.enemies[i];
      if (!s.active) continue;
      const sdx: number = (s.x / TILE_SIZE) - playerTX;
      const sdy: number = (s.y / TILE_SIZE) - playerTY;
      if (Math.abs(sdx) > viewRange || Math.abs(sdy) > viewRange) continue;
      const sx: number = (sdx + viewRange) * scale;
      const sy: number = (sdy + viewRange) * scale;
      mc.fillStyle = COLOR_MINIMAP_ENEMY;
      mc.fillRect(sx - 1, sy - 1, 3, 3);
    }

    mc.fillStyle = COLOR_MINIMAP_PLAYER;
    mc.fillRect(size / 2 - 2, size / 2 - 2, 5, 5);

    mc.strokeStyle = '#4a5568';
    mc.lineWidth = 1;
    mc.strokeRect(0, 0, size, size);
  }
}
