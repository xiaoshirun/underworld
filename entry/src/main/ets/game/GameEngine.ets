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
  GenderType, WeaponForm, EvolutionBranch, EvolutionLevel,
  BossState, ChestState, BossRoom, MaterialDrop, TrapInstance, MechanismInstance,
  Inventory, TrapType, TrapState,
  MechanismType, SecretRoom,
  BossType, BossRole, BossPhase, MaterialType,
  BOSS_HP, BOSS_SIZE, BOSS_ATTACK_INTERVAL, BOSS_PHASE2_THRESHOLD,
  BOSS_RESPAWN_TIME, BOSS_ROOM_SIZE,
  PASSAGE_GUARDIAN_AGGRO, OPTIONAL_CHALLENGE_AGGRO,
  WEAPON_FORM_STATS,
  TRAP_TELEGRAPH_TIME, TRAP_ACTIVE_TIME, TRAP_COOLDOWN_TIME, TRAP_TRIGGER_RADIUS, TRAP_DAMAGE, TRAP_SIZE,
  MECH_INTERACT_RANGE, PUSH_BLOCK_SPEED, TELEPORT_COOLDOWN,
  COLOR_BG, COLOR_WALL, COLOR_WALL_EDGE, COLOR_FLOOR, COLOR_FLOOR_VAR,
  COLOR_WATER, COLOR_WATER_LIGHT, COLOR_LAVA, COLOR_LAVA_LIGHT,
  COLOR_CRYSTAL, COLOR_CRYSTAL_GLOW,
  COLOR_MUSHROOM_CAP, COLOR_MUSHROOM_STEM, COLOR_MUSHROOM_GLOW,
  COLOR_GLOW_STONE, COLOR_GLOW, COLOR_PLANT, COLOR_PLANT_LIGHT,
  COLOR_PLAYER_SKIN, COLOR_PLAYER_HAIR, COLOR_PLAYER_BODY, COLOR_PLAYER_BODY_DARK,
  COLOR_PLAYER_FEMALE_BODY, COLOR_PLAYER_FEMALE_BODY_DARK, COLOR_PLAYER_FEMALE_HAIR,
  COLOR_DRILL_BASE, COLOR_DRILL_TIP,
  COLOR_SLIME_GRAY, COLOR_SLIME_GRAY_LIGHT, COLOR_SLIME_PURPLE, COLOR_SLIME_PURPLE_LIGHT,
  COLOR_SLIME_RED, COLOR_SLIME_RED_LIGHT, COLOR_SLIME_BLUE, COLOR_SLIME_BLUE_LIGHT,
  COLOR_SLIME_YELLOW, COLOR_SLIME_YELLOW_LIGHT, COLOR_SLIME_GHOST, COLOR_SLIME_GHOST_LIGHT,
  COLOR_SLIME_EYE, COLOR_SLIME_PUPIL,
  COLOR_XP_ORB, COLOR_XP_GLOW,
  COLOR_MINIMAP_BG, COLOR_MINIMAP_PLAYER, COLOR_MINIMAP_ENEMY,
  COLOR_ATTACK_FLASH, COLOR_DAMAGE_PARTICLE, COLOR_DRILL_PARTICLE,
  COLOR_SPIKE, COLOR_SPIKE_TIP, COLOR_ROCK, COLOR_POISON_CLOUD,
  COLOR_LAVA_GEYSER, COLOR_VOID_CRACK, COLOR_VOID_PULL, COLOR_VORTEX,
  COLOR_TRAP_WARNING,
  COLOR_PRESSURE_PLATE, COLOR_PLATE_ACTIVE, COLOR_LEVER, COLOR_LEVER_HANDLE,
  COLOR_PUSH_BLOCK, COLOR_REFLECTOR, COLOR_BEAM, COLOR_BREAKABLE_WALL,
  COLOR_TELEPORT_RUNE, COLOR_TELEPORT_ENTRY, COLOR_TELEPORT_EXIT,
  COLOR_BOSS_CRYSTAL, COLOR_BOSS_MUSHROOM, COLOR_BOSS_LAVA, COLOR_BOSS_ABYSS, COLOR_BOSS_VOID,
  COLOR_BOSS_HP_BAR, COLOR_BOSS_HP_BG
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
  private playerGender: GenderType = GenderType.MALE;
  private bosses: BossState[] = [];
  private activeBoss: BossState | null = null;
  private bossRoomLocked: boolean = false;
  private materialDrops: MaterialDrop[] = [];
  private bossRooms: BossRoom[] = [];
  private traps: TrapInstance[] = [];
  private mechanisms: MechanismInstance[] = [];
  private secretRooms: SecretRoom[] = [];
  private teleportCooldown: number = 0;
  private input: InputState = {
    joyActive: false, joyDx: 0, joyDy: 0,
    jumpPressed: false, attackPressed: false, dashPressed: false, attackHeld: false,
    toolPressed: false
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
      isDrilling: false, drillTargetX: 0, drillTargetY: 0, drillHitCount: 0,
      gender: this.playerGender,
      currentWeaponForm: WeaponForm.BLADE,
      unlockedForms: [WeaponForm.BLADE],
      evolutionBranch: EvolutionBranch.CRYSTAL,
      evolutionLevel: EvolutionLevel.BASE,
      isUsingTool: false,
      toolCooldown: 0,
      inventory: {
        crystalOre: 0, mushroomOre: 0, flameOre: 0, abyssOre: 0, voidOre: 0,
        coreNormal: 0, coreRare: 0, formCore: 0,
        hpPotions: 3, gold: 0
      }
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

  setGender(g: GenderType): void {
    this.playerGender = g;
    if (this.player !== null) {
      this.player.gender = g;
    }
  }

  setInputTool(pressed: boolean): void {
    this.input.toolPressed = pressed;
  }

  switchWeaponForm(form: WeaponForm): void {
    if (this.player === null) return;
    const forms: WeaponForm[] = this.player.unlockedForms;
    let found: boolean = false;
    for (let i: number = 0; i < forms.length; i++) {
      if (forms[i] === form) { found = true; break; }
    }
    if (!found) return;
    this.player.currentWeaponForm = form;
  }

  cycleWeaponForm(): void {
    if (this.player === null) return;
    const forms: WeaponForm[] = this.player.unlockedForms;
    if (forms.length <= 1) return;
    let idx: number = 0;
    for (let i: number = 0; i < forms.length; i++) {
      if (forms[i] === this.player.currentWeaponForm) { idx = i; break; }
    }
    const nextIdx: number = (idx + 1) % forms.length;
    this.player.currentWeaponForm = forms[nextIdx];
  }

  getCurrentWeaponForm(): WeaponForm {
    if (this.player === null) return WeaponForm.BLADE;
    return this.player.currentWeaponForm;
  }

  getWeaponFormName(form: WeaponForm): string {
    const names: string[] = ['刃', '鞭', '锤', '杖', '双刃', '巨斧'];
    return names[form];
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
          for (let i: number = 0; i < chunk.traps.length; i++) {
            this.traps.push(chunk.traps[i]);
          }
          for (let i: number = 0; i < chunk.mechanisms.length; i++) {
            this.mechanisms.push(chunk.mechanisms[i]);
          }
          for (let i: number = 0; i < chunk.secretRooms.length; i++) {
            this.secretRooms.push(chunk.secretRooms[i]);
          }
          // Extract boss data
          for (let i: number = 0; i < chunk.bosses.length; i++) {
            this.bosses.push(chunk.bosses[i]);
          }
        }
      }
    }
    // Sync boss rooms from WorldGenerator
    const wgRooms: BossRoom[] = this.worldGen.getBossRooms();
    for (let i: number = 0; i < wgRooms.length; i++) {
      const wgRoom: BossRoom = wgRooms[i];
      let found: boolean = false;
      for (let j: number = 0; j < this.bossRooms.length; j++) {
        if (this.bossRooms[j].chunkX === wgRoom.chunkX && this.bossRooms[j].chunkY === wgRoom.chunkY) {
          found = true;
          break;
        }
      }
      if (!found) {
        this.bossRooms.push({
          chunkX: wgRoom.chunkX, chunkY: wgRoom.chunkY,
          bossType: wgRoom.bossType,
          entered: false, defeated: false, chestSpawned: false
        });
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
    return tile !== TileType.WALL && tile !== TileType.VOID && tile !== TileType.BROKEN_WALL;
  }

  private update(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    const ptx: number = Math.floor(p.x / TILE_SIZE);
    const pty: number = Math.floor(p.y / TILE_SIZE);
    this.loadChunksAround(ptx, pty);

    this.updatePlayer(p, dt);
    this.updateEnemies(dt);
    this.updateBosses(dt);
    this.checkBossRoomEntry(p);
    this.collectMaterialDrops(p);
    this.updateTraps(dt);
    this.updateMechanisms(dt);
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
      const formStats: number[] = WEAPON_FORM_STATS[p.currentWeaponForm];
      const formDuration: number = formStats[2];
      p.isAttacking = true;
      p.attackTimer = formDuration;
      this.input.attackPressed = false;
      this.performAttack(p);
    }
    if (p.isAttacking) {
      p.attackTimer -= dt;
      if (p.attackTimer <= 0) {
        p.isAttacking = false;
        const formStats: number[] = WEAPON_FORM_STATS[p.currentWeaponForm];
        p.attackTimer = formStats[3] - formStats[2];
      }
    } else if (p.attackTimer > 0) {
      p.attackTimer -= dt;
    }

    if (this.input.toolPressed && !p.isUsingTool && p.toolCooldown <= 0 && !p.isDrilling) {
      this.input.toolPressed = false;
      const toolX: number = p.x + Math.cos(p.facing) * 20;
      const toolY: number = p.y + Math.sin(p.facing) * 20;
      const wallTX: number = Math.floor(toolX / TILE_SIZE);
      const wallTY: number = Math.floor(toolY / TILE_SIZE);
      const wallTile: number = this.getTile(wallTX * TILE_SIZE, wallTY * TILE_SIZE);
      if (wallTile === TileType.WALL) {
        p.isUsingTool = true;
        p.isDrilling = true;
        p.drillTargetX = wallTX;
        p.drillTargetY = wallTY;
        p.drillHitCount = 0;
        p.vx = 0;
        p.vy = 0;
        p.toolCooldown = 200;
      }
    }
    if (p.toolCooldown > 0) p.toolCooldown -= dt;
    if (p.isUsingTool && !p.isDrilling) {
      p.isUsingTool = false;
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

    const formStats: number[] = WEAPON_FORM_STATS[p.currentWeaponForm];
    const formRange: number = formStats[0];
    const formWidth: number = formStats[1];

    const attackX: number = p.x + Math.cos(p.facing) * formRange;
    const attackY: number = p.y + Math.sin(p.facing) * formRange;

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
      if (dist < formWidth + s.size) {
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

    // Check boss hits
    for (let i: number = 0; i < this.bosses.length; i++) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;
      const dx: number = boss.x - attackX;
      const dy: number = boss.y - attackY;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist < formWidth + boss.size * 0.6) {
        boss.hp--;
        boss.hitFlash = 200;
        this.shakeTimer = 120;
        this.audio.playEnemyHit();
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 8; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 3;
            this.spawnParticle(boss.x, boss.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 400, this.getBossColor(boss.bossType), 4);
          }
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

  private updateTraps(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = 0; i < this.traps.length; i++) {
      const trap: TrapInstance = this.traps[i];
      const dx: number = p.x - trap.x;
      const dy: number = p.y - trap.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (trap.state) {
        case TrapState.IDLE:
          if (dist < trap.triggerRadius) {
            trap.state = TrapState.TELEGRAPH;
            trap.timer = TRAP_TELEGRAPH_TIME;
          }
          break;

        case TrapState.TELEGRAPH:
          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.ACTIVE;
            trap.timer = TRAP_ACTIVE_TIME;
            this.audio.playPlayerDamage();
          }
          break;

        case TrapState.ACTIVE:
          trap.timer -= dt;
          if (trap.trapType === TrapType.VOID_CRACK && dist < trap.triggerRadius * 1.5) {
            const pullStrength: number = 0.8 * (1.0 - dist / (trap.triggerRadius * 1.5));
            p.vx -= (dx / dist) * pullStrength;
            p.vy -= (dy / dist) * pullStrength;
          }
          if (dist < trap.size) {
            if (p.invincibleTimer <= 0) {
              p.hp -= trap.damage;
              p.invincibleTimer = INVINCIBLE_DURATION;
              this.shakeTimer = 150;
              if (this.settings.effectsEnabled) {
                for (let k: number = 0; k < 6; k++) {
                  const angle: number = Math.random() * Math.PI * 2;
                  const speed: number = 1.5 + Math.random() * 2;
                  this.spawnParticle(p.x, p.y,
                    Math.cos(angle) * speed, Math.sin(angle) * speed, 400, COLOR_DAMAGE_PARTICLE, 3);
                }
              }
              if (trap.trapType === TrapType.WATER_VORTEX) {
                p.x += (Math.random() - 0.5) * 120;
                p.y += (Math.random() - 0.5) * 120;
              }
            }
          }
          if (trap.timer <= 0) {
            trap.state = TrapState.COOLDOWN;
            trap.timer = TRAP_COOLDOWN_TIME;
          }
          break;

        case TrapState.COOLDOWN:
          trap.timer -= dt;
          if (trap.timer <= 0) {
            trap.state = TrapState.IDLE;
          }
          break;
      }
    }
  }

  private updateMechanisms(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    if (this.teleportCooldown > 0) this.teleportCooldown -= dt;

    for (let i: number = 0; i < this.mechanisms.length; i++) {
      const mech: MechanismInstance = this.mechanisms[i];
      const dx: number = p.x - mech.x;
      const dy: number = p.y - mech.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      switch (mech.mechanismType) {
        case MechanismType.PRESSURE_PLATE:
          const wasActive: boolean = mech.active;
          mech.active = dist < PRESSURE_PLATE_RANGE;
          if (mech.active !== wasActive) {
            this.checkMechanismLinks(mech);
          }
          break;

        case MechanismType.PUSH_BLOCK:
          if (mech.pushable && dist < PLAYER_SIZE + 12) {
            const pushDirX: number = p.vx;
            const pushDirY: number = p.vy;
            const pushLen: number = Math.sqrt(pushDirX * pushDirX + pushDirY * pushDirY);
            if (pushLen > 0.5) {
              const newX: number = mech.posX + (pushDirX / pushLen) * PUSH_BLOCK_SPEED;
              const newY: number = mech.posY + (pushDirY / pushLen) * PUSH_BLOCK_SPEED;
              const tileAtNew: number = this.getTile(newX, newY);
              if (tileAtNew === TileType.FLOOR || tileAtNew === TileType.BROKEN_WALL) {
                mech.posX = newX;
                mech.posY = newY;
                mech.x = newX;
                mech.y = newY;
                if (this.settings.effectsEnabled && this.frameCount % 3 === 0) {
                  this.spawnParticle(mech.x, mech.y + 8, (Math.random() - 0.5) * 0.5, -0.3, 300, COLOR_DRILL_PARTICLE, 2);
                }
              }
            }
          }
          break;

        case MechanismType.TELEPORT_RUNE:
          if (dist < MECH_INTERACT_RANGE && this.teleportCooldown <= 0) {
            const pairIndex: number = mech.linkedIndex;
            if (pairIndex >= 0 && pairIndex < this.mechanisms.length) {
              const paired: MechanismInstance = this.mechanisms[pairIndex];
              if (paired.mechanismType === MechanismType.TELEPORT_RUNE) {
                p.x = paired.x;
                p.y = paired.y;
                this.teleportCooldown = TELEPORT_COOLDOWN;
                this.audio.playDash();
                if (this.settings.effectsEnabled) {
                  for (let k: number = 0; k < 10; k++) {
                    const angle: number = Math.random() * Math.PI * 2;
                    const speed: number = 1.5 + Math.random() * 2;
                    this.spawnParticle(paired.x, paired.y,
                      Math.cos(angle) * speed, Math.sin(angle) * speed, 500, COLOR_TELEPORT_RUNE, 3);
                  }
                }
              }
            }
          }
          break;

        case MechanismType.LEVER:
          if (dist < MECH_INTERACT_RANGE && this.input.toolPressed) {
            this.input.toolPressed = false;
            mech.active = !mech.active;
            mech.rotation = mech.active ? 45 : -45;
            this.audio.playDrillHit();
            this.checkMechanismLinks(mech);
          }
          break;

        case MechanismType.CRYSTAL_REFLECTOR:
          if (dist < MECH_INTERACT_RANGE && this.input.toolPressed) {
            this.input.toolPressed = false;
            mech.rotation = (mech.rotation + 60) % 360;
            this.audio.playDrillHit();
          }
          break;
      }
    }

    this.checkBreakableWalls(p);
  }

  private checkMechanismLinks(mech: MechanismInstance): void {
    for (let i: number = 0; i < this.mechanisms.length; i++) {
      const other: MechanismInstance = this.mechanisms[i];
      if (other.linkedIndex >= 0 && other !== mech) {
        const linkedMech: MechanismInstance = this.mechanisms[other.linkedIndex];
        if (linkedMech === mech) {
          other.active = mech.active;
        }
      }
    }
  }

  private checkBreakableWalls(p: PlayerState): void {
    if (!p.isDrilling) return;
    const wallTX: number = p.drillTargetX;
    const wallTY: number = p.drillTargetY;
    const wallWorldX: number = wallTX * TILE_SIZE + TILE_SIZE / 2;
    const wallWorldY: number = wallTY * TILE_SIZE + TILE_SIZE / 2;

    for (let i: number = 0; i < this.secretRooms.length; i++) {
      const room: SecretRoom = this.secretRooms[i];
      if (room.revealed) continue;
      const roomWX: number = (room.chunkX * CHUNK_SIZE + room.wallTileX) * TILE_SIZE + TILE_SIZE / 2;
      const roomWY: number = (room.chunkY * CHUNK_SIZE + room.wallTileY) * TILE_SIZE + TILE_SIZE / 2;
      const dx: number = wallWorldX - roomWX;
      const dy: number = wallWorldY - roomWY;
      if (Math.abs(dx) < TILE_SIZE && Math.abs(dy) < TILE_SIZE) {
        room.revealed = true;
        this.setTile(roomWX, roomWY, TileType.FLOOR);
        this.audio.playWallBreak();
        this.shakeTimer = 200;
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 12; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 3;
            this.spawnParticle(roomWX, roomWY,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 600, COLOR_BREAKABLE_WALL, 4);
          }
        }
      }
    }
  }

  // ==================== Boss System ====================

  private getEntranceDir(cx: number, cy: number): number {
    let h: number = (cx * 13 + 7000) * 374761393 + (cy * 13 + 8000) * 668265263;
    h = ((h ^ (h >> 13)) * 1274126177) | 0;
    return ((h ^ (h >> 16)) >>> 0) % 4;
  }

  private getBossRoomEntranceTiles(chunkX: number, chunkY: number): number[][] {
    const center: number = Math.floor(CHUNK_SIZE / 2);
    const roomRadius: number = Math.floor(BOSS_ROOM_SIZE / 2);
    const dir: number = this.getEntranceDir(chunkX, chunkY);
    const tiles: number[][] = [];

    if (dir === 0) {
      tiles.push([chunkX * CHUNK_SIZE + center - 1, chunkY * CHUNK_SIZE + center - roomRadius]);
      tiles.push([chunkX * CHUNK_SIZE + center, chunkY * CHUNK_SIZE + center - roomRadius]);
      tiles.push([chunkX * CHUNK_SIZE + center + 1, chunkY * CHUNK_SIZE + center - roomRadius]);
    } else if (dir === 1) {
      tiles.push([chunkX * CHUNK_SIZE + center - 1, chunkY * CHUNK_SIZE + center + roomRadius]);
      tiles.push([chunkX * CHUNK_SIZE + center, chunkY * CHUNK_SIZE + center + roomRadius]);
      tiles.push([chunkX * CHUNK_SIZE + center + 1, chunkY * CHUNK_SIZE + center + roomRadius]);
    } else if (dir === 2) {
      tiles.push([chunkX * CHUNK_SIZE + center - roomRadius, chunkY * CHUNK_SIZE + center - 1]);
      tiles.push([chunkX * CHUNK_SIZE + center - roomRadius, chunkY * CHUNK_SIZE + center]);
      tiles.push([chunkX * CHUNK_SIZE + center - roomRadius, chunkY * CHUNK_SIZE + center + 1]);
    } else {
      tiles.push([chunkX * CHUNK_SIZE + center + roomRadius, chunkY * CHUNK_SIZE + center - 1]);
      tiles.push([chunkX * CHUNK_SIZE + center + roomRadius, chunkY * CHUNK_SIZE + center]);
      tiles.push([chunkX * CHUNK_SIZE + center + roomRadius, chunkY * CHUNK_SIZE + center + 1]);
    }
    return tiles;
  }

  private checkBossRoomEntry(p: PlayerState): void {
    const pcx: number = Math.floor(p.x / (CHUNK_SIZE * TILE_SIZE));
    const pcy: number = Math.floor(p.y / (CHUNK_SIZE * TILE_SIZE));

    for (let i: number = 0; i < this.bossRooms.length; i++) {
      const room: BossRoom = this.bossRooms[i];
      if (room.entered || room.defeated) continue;
      if (room.chunkX !== pcx || room.chunkY !== pcy) continue;

      // Check if this chunk is actually a boss room
      const key: string = this.chunkKey(room.chunkX, room.chunkY);
      const chunk: ChunkData | undefined = this.chunks.get(key);
      if (chunk === undefined || !chunk.isBossRoom) continue;

      // Player entered the boss room - seal and spawn
      room.entered = true;
      this.bossRoomLocked = true;

      // Seal entrance tiles
      const entranceTiles: number[][] = this.getBossRoomEntranceTiles(room.chunkX, room.chunkY);
      for (let j: number = 0; j < entranceTiles.length; j++) {
        this.setTile(
          entranceTiles[j][0] * TILE_SIZE + TILE_SIZE / 2,
          entranceTiles[j][1] * TILE_SIZE + TILE_SIZE / 2,
          TileType.WALL
        );
      }

      // Activate the boss
      for (let j: number = 0; j < this.bosses.length; j++) {
        const boss: BossState = this.bosses[j];
        if (!boss.active && !boss.defeated && boss.bossType === room.bossType) {
          boss.active = true;
          this.activeBoss = boss;
        }
      }

      this.audio.playWallBreak();
      this.shakeTimer = 300;
      break;
    }
  }

  private updateBosses(dt: number): void {
    if (this.player === null) return;
    const p: PlayerState = this.player;

    for (let i: number = this.bosses.length - 1; i >= 0; i--) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;

      const dx: number = p.x - boss.x;
      const dy: number = p.y - boss.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      // Movement AI
      if (boss.bossRole === BossRole.PASSAGE_GUARDIAN) {
        // Always chase player in sealed room
        if (dist > 1) {
          const speed: number = 1.5;
          boss.vx = (dx / dist) * speed;
          boss.vy = (dy / dist) * speed;
        }
      } else {
        // Optional Challenge - only chase within aggro radius
        if (dist < boss.aggroRadius) {
          if (dist > 1) {
            const speed: number = 1.8;
            boss.vx = (dx / dist) * speed;
            boss.vy = (dy / dist) * speed;
          }
        } else {
          // Wander randomly
          boss.attackTimer -= dt;
          if (boss.attackTimer <= 0) {
            const angle: number = Math.random() * Math.PI * 2;
            boss.vx = Math.cos(angle) * 0.5;
            boss.vy = Math.sin(angle) * 0.5;
            boss.attackTimer = 2000 + Math.random() * 3000;
          }
        }
      }

      boss.x += boss.vx;
      boss.y += boss.vy;

      // Attack timer
      boss.attackTimer -= dt;
      if (boss.attackTimer <= 0 && dist < boss.size + PLAYER_SIZE + 20) {
        // Melee attack
        boss.attackTimer = BOSS_ATTACK_INTERVAL;
        if (p.invincibleTimer <= 0) {
          p.hp -= 2;
          p.invincibleTimer = INVINCIBLE_DURATION;
          this.audio.playPlayerDamage();
          this.shakeTimer = 200;
          // Knockback
          if (dist > 1) {
            p.vx = -(dx / dist) * 6;
            p.vy = -(dy / dist) * 6;
          }
          if (this.settings.effectsEnabled) {
            for (let k: number = 0; k < 8; k++) {
              const angle: number = Math.random() * Math.PI * 2;
              const speed: number = 1 + Math.random() * 2;
              this.spawnParticle(p.x, p.y,
                Math.cos(angle) * speed, Math.sin(angle) * speed, 400, COLOR_DAMAGE_PARTICLE, 3);
            }
          }
        }
      }

      // Phase transition
      if (boss.phase === BossPhase.PHASE_1 && boss.hp <= boss.maxHp * BOSS_PHASE2_THRESHOLD) {
        boss.phase = BossPhase.PHASE_2;
        boss.hitFlash = 500;
        this.shakeTimer = 400;
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 20; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 2 + Math.random() * 4;
            this.spawnParticle(boss.x, boss.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 800, this.getBossColor(boss.bossType), 5);
          }
        }
      }

      // Boss death
      if (boss.hp <= 0) {
        boss.defeated = true;
        boss.active = false;

        // Handle boss room
        if (boss.bossRole === BossRole.PASSAGE_GUARDIAN) {
          this.bossRoomLocked = false;
          this.activeBoss = null;
          // Open entrance
          for (let j: number = 0; j < this.bossRooms.length; j++) {
            const room: BossRoom = this.bossRooms[j];
            if (room.chunkX === Math.floor(boss.x / (CHUNK_SIZE * TILE_SIZE)) &&
                room.chunkY === Math.floor(boss.y / (CHUNK_SIZE * TILE_SIZE))) {
              room.defeated = true;
              const entranceTiles: number[][] = this.getBossRoomEntranceTiles(room.chunkX, room.chunkY);
              for (let e: number = 0; e < entranceTiles.length; e++) {
                this.setTile(
                  entranceTiles[e][0] * TILE_SIZE + TILE_SIZE / 2,
                  entranceTiles[e][1] * TILE_SIZE + TILE_SIZE / 2,
                  TileType.FLOOR
                );
              }
              break;
            }
          }
        } else {
          // Optional Challenge - mark defeated for respawn timer
          const bcx: number = Math.floor(boss.x / (CHUNK_SIZE * TILE_SIZE));
          const bcy: number = Math.floor(boss.y / (CHUNK_SIZE * TILE_SIZE));
          this.worldGen.markOptionalBossDefeated(bcx, bcy);
          if (this.activeBoss === boss) this.activeBoss = null;
        }

        // Death particles
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 30; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 5;
            this.spawnParticle(boss.x, boss.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 1000, this.getBossColor(boss.bossType), 4 + Math.random() * 4);
          }
        }

        // Drop materials
        this.spawnBossDrops(boss);
        this.shakeTimer = 500;
        this.audio.playEnemyDeath();
      }

      // Hit flash decay
      if (boss.hitFlash > 0) {
        boss.hitFlash -= dt;
      }
    }
  }

  private getBossColor(bossType: BossType): string {
    if (bossType === BossType.CRYSTAL_GUARDIAN) return COLOR_BOSS_CRYSTAL;
    if (bossType === BossType.MUSHROOM_KING) return COLOR_BOSS_MUSHROOM;
    if (bossType === BossType.LAVA_BEAST) return COLOR_BOSS_LAVA;
    if (bossType === BossType.ABYSS_SIREN) return COLOR_BOSS_ABYSS;
    return COLOR_BOSS_VOID;
  }

  private spawnBossDrops(boss: BossState): void {
    // Drop 2-3 boss-specific ore materials
    const dropCount: number = 2 + Math.floor(Math.random() * 2);
    for (let i: number = 0; i < dropCount; i++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 20 + Math.random() * 30;
      const dropX: number = boss.x + Math.cos(angle) * dist;
      const dropY: number = boss.y + Math.sin(angle) * dist;

      let matType: MaterialType = MaterialType.CORE_NORMAL;
      if (boss.bossType === BossType.CRYSTAL_GUARDIAN) matType = MaterialType.CRYSTAL_ORE;
      else if (boss.bossType === BossType.MUSHROOM_KING) matType = MaterialType.MUSHROOM_ORE;
      else if (boss.bossType === BossType.LAVA_BEAST) matType = MaterialType.FLAME_ORE;
      else if (boss.bossType === BossType.ABYSS_SIREN) matType = MaterialType.ABYSS_ORE;
      else if (boss.bossType === BossType.VOID_RIFT) matType = MaterialType.VOID_ORE;

      this.materialDrops.push({
        x: dropX, y: dropY,
        type: matType, count: 1,
        bobPhase: Math.random() * Math.PI * 2,
        active: true
      });
    }

    // Always drop a rare core
    this.materialDrops.push({
      x: boss.x + (Math.random() - 0.5) * 40,
      y: boss.y + (Math.random() - 0.5) * 40,
      type: MaterialType.CORE_RARE, count: 1,
      bobPhase: Math.random() * Math.PI * 2,
      active: true
    });
  }

  private collectMaterialDrops(p: PlayerState): void {
    const collectRange: number = 30;
    for (let i: number = this.materialDrops.length - 1; i >= 0; i--) {
      const drop: MaterialDrop = this.materialDrops[i];
      if (!drop.active) continue;

      const dx: number = p.x - drop.x;
      const dy: number = p.y - drop.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (dist < collectRange) {
        drop.active = false;
        // Add to inventory
        if (drop.type === MaterialType.CRYSTAL_ORE) p.inventory.crystalOre += drop.count;
        else if (drop.type === MaterialType.MUSHROOM_ORE) p.inventory.mushroomOre += drop.count;
        else if (drop.type === MaterialType.FLAME_ORE) p.inventory.flameOre += drop.count;
        else if (drop.type === MaterialType.ABYSS_ORE) p.inventory.abyssOre += drop.count;
        else if (drop.type === MaterialType.VOID_ORE) p.inventory.voidOre += drop.count;
        else if (drop.type === MaterialType.CORE_NORMAL) p.inventory.coreNormal += drop.count;
        else if (drop.type === MaterialType.CORE_RARE) p.inventory.coreRare += drop.count;
        else if (drop.type === MaterialType.FORM_CORE) p.inventory.formCore += drop.count;

        this.audio.playXpCollect();
        if (this.settings.effectsEnabled) {
          for (let k: number = 0; k < 6; k++) {
            const angle: number = Math.random() * Math.PI * 2;
            const speed: number = 1 + Math.random() * 2;
            this.spawnParticle(drop.x, drop.y,
              Math.cos(angle) * speed, Math.sin(angle) * speed, 400, '#ffd700', 3);
          }
        }
      }
    }

    // Clean up inactive drops
    if (this.materialDrops.length > 50) {
      const active: MaterialDrop[] = [];
      for (let i: number = 0; i < this.materialDrops.length; i++) {
        if (this.materialDrops[i].active) active.push(this.materialDrops[i]);
      }
      this.materialDrops = active;
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
    this.renderTraps(c, offX, offY);
    this.renderMechanisms(c, offX, offY);
    this.renderEnemies(c, offX, offY);
    this.renderBosses(c, offX, offY);
    this.renderMaterialDrops(c, offX, offY);
    this.renderPlayer(c, offX, offY, p);
    this.renderParticles(c, offX, offY);
    this.renderAmbientParticles(c);
    this.renderVignette(c);
    this.renderBossHPBar(c);

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
      const engulfBodyColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY : COLOR_PLAYER_BODY;
      c.fillStyle = engulfBodyColor;
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

    const bodyColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY : COLOR_PLAYER_BODY;
    const bodyDarkColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_BODY_DARK : COLOR_PLAYER_BODY_DARK;
    const hairColor: string = p.gender === GenderType.FEMALE ? COLOR_PLAYER_FEMALE_HAIR : COLOR_PLAYER_HAIR;

    c.fillStyle = bodyColor;
    c.fillRect(screenX - 5, screenY - 2 + bobY, 10, 10);
    c.fillStyle = bodyDarkColor;
    c.fillRect(screenX - 5, screenY + 4 + bobY, 10, 4);

    c.fillStyle = COLOR_PLAYER_SKIN;
    c.fillRect(screenX - 4, screenY - 7 + bobY, 8, 6);

    c.fillStyle = hairColor;
    c.fillRect(screenX - 5, screenY - 9 + bobY, 10, 4);
    c.fillRect(screenX - 6, screenY - 7 + bobY, 2, 3);
    c.fillRect(screenX + 4, screenY - 7 + bobY, 2, 3);
    if (p.gender === GenderType.FEMALE) {
      c.fillRect(screenX - 7, screenY - 5 + bobY, 2, 8);
      c.fillRect(screenX + 5, screenY - 5 + bobY, 2, 8);
    }

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
    const drillLen: number = p.isDrilling ? 14 : 8;
    const drillOffX: number = Math.cos(p.facing) * (8 + (p.isDrilling ? 6 : 0));
    const drillOffY: number = Math.sin(p.facing) * (8 + (p.isDrilling ? 6 : 0));
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

    if (p.isDrilling) {
      c.fillStyle = COLOR_ATTACK_FLASH;
      c.globalAlpha = 0.6;
      c.beginPath();
      c.arc(tipX, tipY, 5 + Math.random() * 3, 0, Math.PI * 2);
      c.fill();
      c.globalAlpha = 1.0;
    }

    if (p.isAttacking) {
      this.renderWeaponAttackEffect(c, sx, sy, p, bobY);
    }
  }

  private renderWeaponAttackEffect(c: CanvasRenderingContext2D, sx: number, sy: number, p: PlayerState, bobY: number): void {
    const form: WeaponForm = p.currentWeaponForm;
    const formStats: number[] = WEAPON_FORM_STATS[form];
    const range: number = formStats[0];
    const width: number = formStats[1];
    const offX: number = Math.cos(p.facing) * range * 0.7;
    const offY: number = Math.sin(p.facing) * range * 0.7;
    const cx: number = sx + offX;
    const cy: number = sy + offY + bobY;

    c.globalAlpha = 0.65;

    if (form === WeaponForm.BLADE) {
      const arcStart: number = p.facing - 0.8;
      const arcEnd: number = p.facing + 0.8;
      c.strokeStyle = '#60a5fa';
      c.lineWidth = 3;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.8, arcStart, arcEnd);
      c.stroke();
      c.strokeStyle = '#93c5fd';
      c.lineWidth = 1.5;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.6, arcStart, arcEnd);
      c.stroke();
    } else if (form === WeaponForm.WHIP) {
      const whipLen: number = range * 1.0;
      const perpX: number = -Math.sin(p.facing);
      const perpY: number = Math.cos(p.facing);
      c.strokeStyle = '#a78bfa';
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(sx + Math.cos(p.facing) * 8, sy + bobY + Math.sin(p.facing) * 8);
      const cp1x: number = sx + Math.cos(p.facing) * whipLen * 0.5 + perpX * 12;
      const cp1y: number = sy + bobY + Math.sin(p.facing) * whipLen * 0.5 + perpY * 12;
      const endX: number = sx + Math.cos(p.facing) * whipLen;
      const endY: number = sy + bobY + Math.sin(p.facing) * whipLen;
      c.quadraticCurveTo(cp1x, cp1y, endX, endY);
      c.stroke();
    } else if (form === WeaponForm.HAMMER) {
      c.fillStyle = '#f97316';
      c.beginPath();
      c.arc(cx, cy, width * 0.5, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#fdba74';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(cx, cy, width * 0.7, 0, Math.PI * 2);
      c.stroke();
    } else if (form === WeaponForm.STAFF) {
      const boltX: number = sx + Math.cos(p.facing) * range;
      const boltY: number = sy + bobY + Math.sin(p.facing) * range;
      c.fillStyle = '#38bdf8';
      c.beginPath();
      c.arc(boltX, boltY, 5, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = '#7dd3fc';
      c.globalAlpha = 0.4;
      c.beginPath();
      c.arc(boltX, boltY, 9, 0, Math.PI * 2);
      c.fill();
    } else if (form === WeaponForm.DUAL_BLADES) {
      const perpX: number = -Math.sin(p.facing);
      const perpY: number = Math.cos(p.facing);
      c.strokeStyle = '#fb923c';
      c.lineWidth = 2.5;
      for (let side: number = -1; side <= 1; side += 2) {
        const arcCx: number = sx + perpX * 6 * side;
        const arcCy: number = sy + bobY + perpY * 6 * side;
        c.beginPath();
        c.arc(arcCx, arcCy, range * 0.6, p.facing - 0.6, p.facing + 0.6);
        c.stroke();
      }
    } else if (form === WeaponForm.GREAT_AXE) {
      c.fillStyle = '#ef4444';
      c.beginPath();
      c.arc(sx, sy + bobY, range * 0.9, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = '#fca5a5';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(sx, sy + bobY, range * 1.1, 0, Math.PI * 2);
      c.stroke();
    }

    c.globalAlpha = 1.0;
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

      const sc: number = s.size / 48;
      const bp: number = s.bouncePhase;
      const flash: boolean = s.hitFlash > 0;
      const cx: number = screenX;
      const cy: number = screenY;

      if (s.enemyType === EnemyType.GRAY_SLIME) {
        const bounce: number = Math.sin(bp) * 2 * sc;
        const squash: number = 1 + Math.sin(bp) * 0.08;
        c.save();
        c.translate(cx, cy + bounce);
        c.scale(squash, 1 / squash);
        c.globalAlpha = 0.2;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 12 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
        } else {
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_GRAY;
        }
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_GRAY_LIGHT;
          c.beginPath();
          c.ellipse(-3 * sc, -4 * sc, 6 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.4;
          c.beginPath();
          c.ellipse(-5 * sc, -6 * sc, 2 * sc, 1.5 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-4 * sc, -1 * sc, 2.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(4 * sc, -1 * sc, 2.5 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_PUPIL;
          c.beginPath();
          c.arc(-3.5 * sc, -0.5 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -0.5 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = COLOR_SLIME_PUPIL;
          c.lineWidth = 0.8;
          c.beginPath();
          c.arc(0, 3 * sc, 2 * sc, 0.1, Math.PI - 0.1);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.PURPLE_SLIME) {
        const bounce: number = Math.sin(bp * 1.3) * 1.5 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        if (!flash) {
          c.globalAlpha = 0.12 + Math.sin(this.frameCount * 0.05) * 0.05;
          c.fillStyle = COLOR_SLIME_PURPLE;
          c.beginPath();
          c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 0.25;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 14 * sc, 13 * sc, 3.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        for (let t: number = 0; t < 4; t++) {
          const angle: number = (t / 4) * Math.PI * 2 + this.frameCount * 0.03;
          const tx: number = Math.cos(angle) * 16 * sc;
          const ty: number = Math.sin(angle) * 10 * sc + 4 * sc;
          if (flash) {
            c.globalAlpha = 0.9;
            c.fillStyle = '#ffffff';
          } else {
            c.globalAlpha = 0.9;
            c.fillStyle = COLOR_SLIME_PURPLE;
          }
          c.beginPath();
          c.ellipse(tx, ty, 3 * sc, 2 * sc, angle, 0, Math.PI * 2);
          c.fill();
        }
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
        } else {
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_PURPLE;
        }
        c.beginPath();
        c.ellipse(0, 0, 15 * sc, 13 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_PURPLE_LIGHT;
          c.beginPath();
          c.ellipse(-3 * sc, -4 * sc, 7 * sc, 5 * sc, -0.3, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-4 * sc, -2 * sc, 2.8 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(4 * sc, -2 * sc, 2.8 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#ff0040';
          c.beginPath();
          c.arc(-3.5 * sc, -1.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1.5 * sc, 1.5 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1a1a2e';
          c.beginPath();
          c.arc(-3.5 * sc, -1.5 * sc, 0.8 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1.5 * sc, 0.8 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#4c1d95';
          c.lineWidth = 1.2 * sc;
          c.beginPath();
          c.moveTo(-7 * sc, -5 * sc);
          c.lineTo(-2 * sc, -4 * sc);
          c.stroke();
          c.beginPath();
          c.moveTo(7 * sc, -5 * sc);
          c.lineTo(2 * sc, -4 * sc);
          c.stroke();
          if (s.isEngulfing) {
            c.fillStyle = '#2d1060';
            c.beginPath();
            c.ellipse(0, 5 * sc, 5 * sc, 4 * sc, 0, 0, Math.PI * 2);
            c.fill();
          } else {
            c.fillStyle = '#2d1060';
            c.beginPath();
            c.ellipse(0, 5 * sc, 5 * sc, 3 * sc, 0, 0, Math.PI * 2);
            c.fill();
          }
        }
        c.restore();
      } else if (s.enemyType === EnemyType.RED_SLIME) {
        const charge: number = s.isCharging ? Math.abs(Math.sin(this.frameCount * 0.08)) : Math.abs(Math.sin(this.frameCount * 0.04)) * 0.3;
        c.save();
        c.translate(cx, cy);
        if (!flash) {
          c.globalAlpha = 0.1 + charge * 0.1;
          c.fillStyle = '#ff4444';
          c.beginPath();
          c.ellipse(0, 0, (18 + charge * 2) * sc, (16 + charge * 2) * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 0.25;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 13 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          for (let fi: number = 0; fi < 5; fi++) {
            const angle: number = -Math.PI * 0.8 + (fi / 4) * Math.PI * 0.6;
            const len: number = (5 + Math.sin(this.frameCount * 0.1 + fi) * 2) * sc;
            const sx: number = Math.cos(angle) * 12 * sc;
            const sy: number = Math.sin(angle) * 10 * sc;
            const ex: number = sx + Math.cos(angle) * len;
            const ey: number = sy + Math.sin(angle) * len;
            c.fillStyle = '#ff6600';
            c.globalAlpha = 0.7;
            c.beginPath();
            c.moveTo(sx - 1.5 * sc, sy);
            c.lineTo(ex, ey);
            c.lineTo(sx + 1.5 * sc, sy);
            c.closePath();
            c.fill();
          }
        }
        c.globalAlpha = 1.0;
        if (flash) {
          c.fillStyle = '#ffffff';
        } else {
          c.fillStyle = COLOR_SLIME_RED;
        }
        c.beginPath();
        c.ellipse(1 * sc, 0, 14 * sc, 11 * sc, 0.1, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_RED_LIGHT;
          c.beginPath();
          c.ellipse(-2 * sc, -3.5 * sc, 6 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-3.5 * sc, -1.5 * sc, 2.2 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(4 * sc, -1.5 * sc, 2.2 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#ffcc00';
          c.beginPath();
          c.arc(-3 * sc, -1 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1a1a2e';
          c.beginPath();
          c.arc(-3 * sc, -1 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4.5 * sc, -1 * sc, 0.6 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#7f1d1d';
          c.lineWidth = 1 * sc;
          c.beginPath();
          c.moveTo(-3 * sc, 4 * sc);
          c.lineTo(-1 * sc, 3 * sc);
          c.lineTo(1 * sc, 4 * sc);
          c.lineTo(3 * sc, 3 * sc);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.BLUE_SLIME) {
        const bounce: number = Math.sin(bp * 0.8) * 1.5 * sc;
        c.save();
        c.translate(cx, cy + bounce);
        if (!flash) {
          for (let d: number = 0; d < 5; d++) {
            const angle: number = (d / 5) * Math.PI * 2 + this.frameCount * 0.02;
            const dist: number = (16 + Math.sin(this.frameCount * 0.03 + d * 2) * 3) * sc;
            const dx: number = Math.cos(angle) * dist;
            const dy: number = Math.sin(angle) * dist * 0.7 - 2.5 * sc;
            c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
            c.globalAlpha = 0.4 + Math.sin(this.frameCount * 0.04 + d) * 0.2;
            c.beginPath();
            c.arc(dx, dy, 1.3 * sc, 0, Math.PI * 2);
            c.fill();
          }
        }
        c.globalAlpha = 0.2;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, 13 * sc, 12 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
        } else {
          c.globalAlpha = 0.75;
          c.fillStyle = COLOR_SLIME_BLUE;
        }
        c.beginPath();
        c.ellipse(0, 0, 14 * sc, 12 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.globalAlpha = 0.3;
          c.fillStyle = COLOR_SLIME_BLUE_LIGHT;
          const rippleOff: number = Math.sin(this.frameCount * 0.04) * 1.5 * sc;
          c.beginPath();
          c.ellipse(0, rippleOff, 10 * sc, 7 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#93c5fd';
          c.lineWidth = 0.8 * sc;
          c.globalAlpha = 0.4;
          for (let w: number = 0; w < 2; w++) {
            const wy: number = (-2 + w * 5) * sc;
            const woff: number = Math.sin(this.frameCount * 0.05 + w) * 2 * sc;
            c.beginPath();
            c.moveTo(-7 * sc, wy + woff);
            c.quadraticCurveTo(0, wy - woff - 1.5 * sc, 7 * sc, wy + woff);
            c.stroke();
          }
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-3.5 * sc, -1 * sc, 2.5 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(3.5 * sc, -1 * sc, 2.5 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#1e40af';
          c.beginPath();
          c.arc(-3 * sc, -0.5 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(4 * sc, -0.5 * sc, 1.2 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#1e3a5f';
          c.lineWidth = 0.8;
          c.beginPath();
          c.arc(0, 2.5 * sc, 2.5 * sc, 0.2, Math.PI - 0.2);
          c.stroke();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.YELLOW_SLIME) {
        const bounce: number = Math.abs(Math.sin(bp * 1.1)) * 3 * sc;
        c.save();
        c.translate(cx, cy - bounce);
        if (!flash) {
          c.globalAlpha = 0.08 + Math.sin(this.frameCount * 0.04) * 0.03;
          c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
          c.beginPath();
          c.ellipse(0, 0, 20 * sc, 18 * sc, 0, 0, Math.PI * 2);
          c.fill();
          for (let sp: number = 0; sp < 6; sp++) {
            const angle: number = (sp / 6) * Math.PI * 2 + this.frameCount * 0.03;
            const dist: number = (14 + Math.sin(this.frameCount * 0.05 + sp * 3) * 4) * sc;
            const sx: number = Math.cos(angle) * dist;
            const sy: number = Math.sin(angle) * dist * 0.6;
            const sparkSize: number = (0.8 + Math.sin(this.frameCount * 0.08 + sp * 2) * 0.5) * sc;
            c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
            c.globalAlpha = 0.5 + Math.sin(this.frameCount * 0.06 + sp) * 0.3;
            c.beginPath();
            c.moveTo(sx, sy - sparkSize * 2);
            c.lineTo(sx + sparkSize * 0.5, sy - sparkSize * 0.5);
            c.lineTo(sx + sparkSize * 2, sy);
            c.lineTo(sx + sparkSize * 0.5, sy + sparkSize * 0.5);
            c.lineTo(sx, sy + sparkSize * 2);
            c.lineTo(sx - sparkSize * 0.5, sy + sparkSize * 0.5);
            c.lineTo(sx - sparkSize * 2, sy);
            c.lineTo(sx - sparkSize * 0.5, sy - sparkSize * 0.5);
            c.closePath();
            c.fill();
          }
        }
        c.globalAlpha = 0.15;
        c.fillStyle = '#000000';
        c.beginPath();
        c.ellipse(0, (13 + bounce / sc) * sc, 11 * sc, 2.5 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (flash) {
          c.globalAlpha = 0.9;
          c.fillStyle = '#ffffff';
        } else {
          c.globalAlpha = 0.9;
          c.fillStyle = COLOR_SLIME_YELLOW;
        }
        c.beginPath();
        c.ellipse(0, 0, 12 * sc, 10 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_YELLOW_LIGHT;
          c.beginPath();
          c.ellipse(-2.5 * sc, -3.5 * sc, 5.5 * sc, 4 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.5;
          c.beginPath();
          c.ellipse(-4 * sc, -5.5 * sc, 2 * sc, 1.5 * sc, -0.2, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = 1.0;
        c.fillStyle = COLOR_SLIME_EYE;
        c.beginPath();
        c.arc(-3 * sc, -0.5 * sc, 2.2 * sc, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(3 * sc, -0.5 * sc, 2.2 * sc, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#92400e';
          c.beginPath();
          c.arc(-2.5 * sc, 0, 1 * sc, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.arc(3.5 * sc, 0, 1 * sc, 0, Math.PI * 2);
          c.fill();
          c.strokeStyle = '#92400e';
          c.lineWidth = 0.8;
          c.beginPath();
          c.arc(0, 2.5 * sc, 3 * sc, 0.1, Math.PI - 0.1);
          c.stroke();
          c.fillStyle = '#f59e0b';
          c.globalAlpha = 0.3;
          c.beginPath();
          c.ellipse(-6 * sc, 2 * sc, 2 * sc, 1.2 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.ellipse(6 * sc, 2 * sc, 2 * sc, 1.2 * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.restore();
      } else if (s.enemyType === EnemyType.GHOST_SLIME) {
        const float: number = Math.sin(bp * 0.5) * 3 * sc;
        const phase: number = Math.sin(this.frameCount * 0.05) * 0.15;
        c.save();
        c.translate(cx, cy + float);
        if (!flash) {
          c.globalAlpha = 0.06 + Math.sin(this.frameCount * 0.04) * 0.03;
          c.fillStyle = COLOR_SLIME_GHOST;
          c.beginPath();
          c.ellipse(0, 0, 22 * sc, 20 * sc, 0, 0, Math.PI * 2);
          c.fill();
          for (let w: number = 0; w < 4; w++) {
            const wAngle: number = (w / 4) * Math.PI * 2 + this.frameCount * 0.02;
            const wDist: number = (10 + Math.sin(this.frameCount * 0.03 + w * 2) * 5) * sc;
            const wx: number = Math.cos(wAngle) * wDist;
            const wy: number = Math.sin(wAngle) * wDist * 0.5 + 5 * sc;
            c.fillStyle = COLOR_SLIME_GHOST_LIGHT;
            c.globalAlpha = 0.15 + Math.sin(this.frameCount * 0.05 + w) * 0.1;
            c.beginPath();
            c.ellipse(wx, wy, 2.5 * sc, 1.5 * sc, wAngle, 0, Math.PI * 2);
            c.fill();
          }
        }
        const bodyAlpha: number = flash ? 0.9 : (0.45 + phase);
        c.globalAlpha = bodyAlpha;
        if (flash) {
          c.fillStyle = '#ffffff';
        } else {
          c.fillStyle = COLOR_SLIME_GHOST;
        }
        c.beginPath();
        c.moveTo(-12 * sc, 4 * sc);
        c.quadraticCurveTo(-13 * sc, -10 * sc, 0, -12 * sc);
        c.quadraticCurveTo(13 * sc, -10 * sc, 12 * sc, 4 * sc);
        const wv1: number = Math.sin(this.frameCount * 0.06) * 1.5 * sc;
        const wv2: number = Math.sin(this.frameCount * 0.06 + 1) * 1.5 * sc;
        const wv3: number = Math.sin(this.frameCount * 0.06 + 2) * 1.5 * sc;
        c.quadraticCurveTo(10 * sc, 10 * sc + wv1, 6 * sc, 8 * sc);
        c.quadraticCurveTo(3 * sc, 12 * sc + wv2, 0, 9 * sc);
        c.quadraticCurveTo(-3 * sc, 12 * sc + wv3, -6 * sc, 8 * sc);
        c.quadraticCurveTo(-10 * sc, 10 * sc + wv1, -12 * sc, 4 * sc);
        c.closePath();
        c.fill();
        if (!flash) {
          c.fillStyle = COLOR_SLIME_GHOST_LIGHT;
          c.globalAlpha = 0.2;
          c.beginPath();
          c.ellipse(0, -2 * sc, 7 * sc, 6 * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.globalAlpha = flash ? 0.9 : 0.8;
        c.fillStyle = flash ? '#ffffff' : '#e2e8f0';
        c.beginPath();
        c.ellipse(-4 * sc, -3 * sc, 2.5 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.ellipse(4 * sc, -3 * sc, 2.5 * sc, 3 * sc, 0, 0, Math.PI * 2);
        c.fill();
        if (!flash) {
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.9;
          c.beginPath();
          c.ellipse(-4 * sc, -2.5 * sc, 1.2 * sc, 1.5 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.beginPath();
          c.ellipse(4 * sc, -2.5 * sc, 1.2 * sc, 1.5 * sc, 0, 0, Math.PI * 2);
          c.fill();
          c.fillStyle = '#1e293b';
          c.globalAlpha = 0.6;
          c.beginPath();
          c.ellipse(0, 3 * sc, 2.5 * sc, (2 + Math.sin(this.frameCount * 0.04)) * sc, 0, 0, Math.PI * 2);
          c.fill();
        }
        c.restore();
      }

      c.globalAlpha = 1.0;
      if (s.isCharging && s.enemyType !== EnemyType.RED_SLIME) {
        const halfSize: number = s.size / 2;
        c.globalAlpha = 0.4;
        c.fillStyle = COLOR_SLIME_RED;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + 6, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      if (s.hp < s.maxHp) {
        const barW: number = s.size;
        const barH: number = 3;
        const barY: number = screenY - s.size / 2 - 6;
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

  private renderTraps(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.traps.length; i++) {
      const trap: TrapInstance = this.traps[i];
      const screenX: number = trap.x + offX;
      const screenY: number = trap.y + offY;

      if (screenX < -40 || screenX > this.screenW + 40 || screenY < -40 || screenY > this.screenH + 40) {
        continue;
      }

      if (trap.state === TrapState.IDLE) continue;

      const isActive: boolean = trap.state === TrapState.ACTIVE;
      const isTelegraph: boolean = trap.state === TrapState.TELEGRAPH;

      if (isTelegraph) {
        const pulse: number = 0.3 + 0.3 * Math.sin(this.frameCount * 0.3);
        c.globalAlpha = pulse;
        c.fillStyle = COLOR_TRAP_WARNING;
        c.beginPath();
        c.arc(screenX, screenY, trap.triggerRadius, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
      }

      switch (trap.trapType) {
        case TrapType.GROUND_SPIKES:
          if (isActive) {
            c.fillStyle = COLOR_SPIKE;
            for (let s: number = 0; s < 5; s++) {
              const sx: number = screenX - 10 + s * 5;
              const sy: number = screenY + 6;
              c.beginPath();
              c.moveTo(sx - 3, sy);
              c.lineTo(sx, sy - 14);
              c.lineTo(sx + 3, sy);
              c.closePath();
              c.fill();
            }
            c.fillStyle = COLOR_SPIKE_TIP;
            for (let s: number = 0; s < 5; s++) {
              const sx: number = screenX - 10 + s * 5;
              const sy: number = screenY + 6;
              c.beginPath();
              c.moveTo(sx - 1, sy - 10);
              c.lineTo(sx, sy - 14);
              c.lineTo(sx + 1, sy - 10);
              c.closePath();
              c.fill();
            }
          } else {
            c.fillStyle = COLOR_SPIKE;
            c.globalAlpha = 0.3;
            c.fillRect(screenX - 12, screenY + 4, 24, 3);
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.FALLING_ROCKS:
          if (isActive) {
            c.fillStyle = COLOR_ROCK;
            for (let r: number = 0; r < 4; r++) {
              const rx: number = screenX - 8 + r * 6;
              const ry: number = screenY - 6 + Math.sin(r * 1.5) * 4;
              c.fillRect(rx, ry, 5, 5);
            }
          } else if (isTelegraph) {
            c.fillStyle = COLOR_ROCK;
            c.globalAlpha = 0.4;
            const fallProgress: number = 1.0 - (trap.timer / TRAP_TELEGRAPH_TIME);
            for (let r: number = 0; r < 3; r++) {
              const rx: number = screenX - 6 + r * 6;
              const ry: number = screenY - 30 + fallProgress * 24;
              c.fillRect(rx, ry, 4, 4);
            }
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.POISON_SPORES:
          if (isActive) {
            c.globalAlpha = 0.5;
            c.fillStyle = COLOR_POISON_CLOUD;
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.8, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 0.3;
            c.beginPath();
            c.arc(screenX + 4, screenY - 3, trap.size * 0.5, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.LAVA_GEYSER:
          if (isActive) {
            const geyserH: number = 20 + Math.sin(this.frameCount * 0.2) * 5;
            c.fillStyle = COLOR_LAVA_GEYSER;
            c.globalAlpha = 0.8;
            c.fillRect(screenX - 6, screenY - geyserH, 12, geyserH);
            c.globalAlpha = 0.4;
            c.fillStyle = COLOR_LAVA;
            c.fillRect(screenX - 10, screenY - geyserH * 0.6, 20, geyserH * 0.6);
            c.globalAlpha = 1.0;
          } else if (isTelegraph) {
            c.fillStyle = COLOR_LAVA_GEYSER;
            c.globalAlpha = 0.2;
            c.beginPath();
            c.arc(screenX, screenY, 8, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.VOID_CRACK:
          c.fillStyle = COLOR_VOID_CRACK;
          if (isActive) {
            c.globalAlpha = 0.7 + 0.3 * Math.sin(this.frameCount * 0.15);
            c.beginPath();
            c.arc(screenX, screenY, trap.size * 0.6, 0, Math.PI * 2);
            c.fill();
            c.fillStyle = COLOR_VOID_PULL;
            c.globalAlpha = 0.4;
            c.beginPath();
            c.arc(screenX, screenY, trap.triggerRadius * 1.2, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          } else {
            c.globalAlpha = 0.3;
            c.beginPath();
            c.arc(screenX, screenY, 6, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;

        case TrapType.WATER_VORTEX:
          if (isActive) {
            const spin: number = this.frameCount * 0.1;
            c.strokeStyle = COLOR_VORTEX;
            c.lineWidth = 2;
            c.globalAlpha = 0.7;
            for (let ring: number = 0; ring < 3; ring++) {
              const r: number = 4 + ring * 5;
              c.beginPath();
              c.arc(screenX, screenY, r, spin + ring, spin + ring + Math.PI * 1.2);
              c.stroke();
            }
            c.globalAlpha = 1.0;
            c.lineWidth = 1;
          } else {
            c.fillStyle = COLOR_VORTEX;
            c.globalAlpha = 0.2;
            c.beginPath();
            c.arc(screenX, screenY, 5, 0, Math.PI * 2);
            c.fill();
            c.globalAlpha = 1.0;
          }
          break;
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderMechanisms(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.mechanisms.length; i++) {
      const mech: MechanismInstance = this.mechanisms[i];
      const screenX: number = mech.x + offX;
      const screenY: number = mech.y + offY;

      if (screenX < -40 || screenX > this.screenW + 40 || screenY < -40 || screenY > this.screenH + 40) {
        continue;
      }

      switch (mech.mechanismType) {
        case MechanismType.PRESSURE_PLATE:
          c.fillStyle = mech.active ? COLOR_PLATE_ACTIVE : COLOR_PRESSURE_PLATE;
          c.globalAlpha = mech.active ? 0.9 : 0.5;
          c.fillRect(screenX - 10, screenY - 10, 20, 20);
          c.globalAlpha = 0.3;
          c.fillStyle = mech.active ? COLOR_PLATE_ACTIVE : COLOR_PRESSURE_PLATE;
          c.fillRect(screenX - 12, screenY - 12, 24, 24);
          c.globalAlpha = 1.0;
          break;

        case MechanismType.LEVER:
          c.fillStyle = COLOR_LEVER;
          c.fillRect(screenX - 3, screenY - 12, 6, 24);
          c.save();
          c.translate(screenX, screenY);
          c.rotate(mech.rotation * Math.PI / 180);
          c.fillStyle = COLOR_LEVER_HANDLE;
          c.fillRect(-2, -14, 4, 14);
          c.beginPath();
          c.arc(0, -14, 4, 0, Math.PI * 2);
          c.fill();
          c.restore();
          break;

        case MechanismType.PUSH_BLOCK:
          const bx: number = mech.posX + offX;
          const by: number = mech.posY + offY;
          c.fillStyle = COLOR_PUSH_BLOCK;
          c.fillRect(bx - 12, by - 12, 24, 24);
          c.strokeStyle = '#737373';
          c.lineWidth = 1;
          c.strokeRect(bx - 12, by - 12, 24, 24);
          c.fillStyle = '#737373';
          c.fillRect(bx - 4, by - 4, 3, 3);
          c.fillRect(bx + 2, by + 2, 3, 3);
          break;

        case MechanismType.CRYSTAL_REFLECTOR:
          c.save();
          c.translate(screenX, screenY);
          c.rotate(mech.rotation * Math.PI / 180);
          c.fillStyle = COLOR_REFLECTOR;
          c.beginPath();
          for (let v: number = 0; v < 6; v++) {
            const angle: number = (v / 6) * Math.PI * 2;
            const r: number = 10;
            if (v === 0) c.moveTo(Math.cos(angle) * r, Math.sin(angle) * r);
            else c.lineTo(Math.cos(angle) * r, Math.sin(angle) * r);
          }
          c.closePath();
          c.fill();
          c.fillStyle = '#ffffff';
          c.globalAlpha = 0.5 + 0.3 * Math.sin(this.frameCount * 0.1);
          c.beginPath();
          c.arc(0, 0, 4, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.restore();
          break;

        case MechanismType.BREAKABLE_WALL:
          c.fillStyle = COLOR_BREAKABLE_WALL;
          c.fillRect(screenX - TILE_SIZE / 2, screenY - TILE_SIZE / 2, TILE_SIZE, TILE_SIZE);
          c.strokeStyle = '#3a3a55';
          c.lineWidth = 1;
          c.beginPath();
          c.moveTo(screenX - 8, screenY - 10);
          c.lineTo(screenX + 2, screenY + 4);
          c.moveTo(screenX + 6, screenY - 8);
          c.lineTo(screenX - 2, screenY + 8);
          c.stroke();
          break;

        case MechanismType.TELEPORT_RUNE:
          const runeColor: string = mech.active ? COLOR_TELEPORT_EXIT : COLOR_TELEPORT_ENTRY;
          const spin: number = this.frameCount * 0.03;
          c.strokeStyle = runeColor;
          c.lineWidth = 2;
          c.globalAlpha = 0.6;
          c.beginPath();
          c.arc(screenX, screenY, 12, 0, Math.PI * 2);
          c.stroke();
          c.globalAlpha = 0.4;
          c.beginPath();
          c.arc(screenX, screenY, 8, spin, spin + Math.PI * 1.5);
          c.stroke();
          c.fillStyle = COLOR_TELEPORT_RUNE;
          c.globalAlpha = 0.3 + 0.2 * Math.sin(this.frameCount * 0.08);
          c.beginPath();
          c.arc(screenX, screenY, 6, 0, Math.PI * 2);
          c.fill();
          c.globalAlpha = 1.0;
          c.lineWidth = 1;
          break;
      }
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

    // Boss dots (larger, distinct color)
    for (let i: number = 0; i < this.bosses.length; i++) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;
      const bdx: number = (boss.x / TILE_SIZE) - playerTX;
      const bdy: number = (boss.y / TILE_SIZE) - playerTY;
      if (Math.abs(bdx) > viewRange || Math.abs(bdy) > viewRange) continue;
      const bsx: number = (bdx + viewRange) * scale;
      const bsy: number = (bdy + viewRange) * scale;
      mc.fillStyle = '#ff0000';
      mc.fillRect(bsx - 3, bsy - 3, 6, 6);
    }

    mc.fillStyle = COLOR_MINIMAP_PLAYER;
    mc.fillRect(size / 2 - 2, size / 2 - 2, 5, 5);

    mc.strokeStyle = '#4a5568';
    mc.lineWidth = 1;
    mc.strokeRect(0, 0, size, size);
  }

  // ==================== Boss Rendering ====================

  private renderBosses(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.bosses.length; i++) {
      const boss: BossState = this.bosses[i];
      if (!boss.active || boss.defeated) continue;

      const screenX: number = boss.x + offX;
      const screenY: number = boss.y + offY;

      if (screenX < -60 || screenX > this.screenW + 60 || screenY < -60 || screenY > this.screenH + 60) {
        continue;
      }

      const bossColor: string = this.getBossColor(boss.bossType);
      const halfSize: number = boss.size / 2;
      const pulse: number = Math.sin(this.frameCount * 0.05) * 2;

      // Hit flash
      if (boss.hitFlash > 0) {
        c.globalAlpha = 0.5 + 0.5 * Math.sin(boss.hitFlash * 0.05);
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - halfSize - 2, screenY - halfSize - 2, boss.size + 4, boss.size + 4);
      }

      c.globalAlpha = 1.0;

      // Boss body based on type
      if (boss.bossType === BossType.CRYSTAL_GUARDIAN) {
        // Crystal shape - diamond
        c.fillStyle = bossColor;
        c.beginPath();
        c.moveTo(screenX, screenY - halfSize - pulse);
        c.lineTo(screenX + halfSize + pulse, screenY);
        c.lineTo(screenX, screenY + halfSize + pulse);
        c.lineTo(screenX - halfSize - pulse, screenY);
        c.closePath();
        c.fill();
        // Inner glow
        c.fillStyle = '#67e8f9';
        c.globalAlpha = 0.5 + 0.3 * Math.sin(this.frameCount * 0.08);
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.4, 0, Math.PI * 2);
        c.fill();
        c.globalAlpha = 1.0;
        // Eyes
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - 6, screenY - 4, 4, 6);
        c.fillRect(screenX + 3, screenY - 4, 4, 6);
      } else if (boss.bossType === BossType.MUSHROOM_KING) {
        // Mushroom cap (dome) + stem
        c.fillStyle = bossColor;
        c.beginPath();
        c.arc(screenX, screenY - 4, halfSize + pulse, Math.PI, 0);
        c.closePath();
        c.fill();
        // Spots on cap
        c.fillStyle = '#ff9ec4';
        c.beginPath();
        c.arc(screenX - 8, screenY - 12, 4, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(screenX + 6, screenY - 16, 3, 0, Math.PI * 2);
        c.fill();
        // Stem
        c.fillStyle = COLOR_MUSHROOM_STEM;
        c.fillRect(screenX - 8, screenY - 4, 16, halfSize);
        // Eyes
        c.fillStyle = '#ffffff';
        c.fillRect(screenX - 5, screenY + 2, 4, 5);
        c.fillRect(screenX + 2, screenY + 2, 4, 5);
      } else if (boss.bossType === BossType.LAVA_BEAST) {
        // Rough rocky body
        c.fillStyle = bossColor;
        c.fillRect(screenX - halfSize, screenY - halfSize, boss.size, boss.size);
        // Lava cracks
        c.strokeStyle = '#ffd700';
        c.lineWidth = 2;
        c.globalAlpha = 0.6 + 0.4 * Math.sin(this.frameCount * 0.1);
        c.beginPath();
        c.moveTo(screenX - 10, screenY - 12);
        c.lineTo(screenX - 2, screenY + 4);
        c.lineTo(screenX + 8, screenY - 6);
        c.moveTo(screenX + 4, screenY + 2);
        c.lineTo(screenX - 6, screenY + 14);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
        // Eyes
        c.fillStyle = '#ffd700';
        c.fillRect(screenX - 7, screenY - 6, 5, 5);
        c.fillRect(screenX + 3, screenY - 6, 5, 5);
      } else if (boss.bossType === BossType.ABYSS_SIREN) {
        // Flowing water form
        c.fillStyle = bossColor;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + pulse, 0, Math.PI * 2);
        c.fill();
        // Water tendrils
        c.strokeStyle = COLOR_WATER_LIGHT;
        c.lineWidth = 3;
        c.globalAlpha = 0.6;
        for (let t: number = 0; t < 4; t++) {
          const angle: number = (t / 4) * Math.PI * 2 + this.frameCount * 0.03;
          const ex: number = screenX + Math.cos(angle) * (halfSize + 10);
          const ey: number = screenY + Math.sin(angle) * (halfSize + 10);
          c.beginPath();
          c.moveTo(screenX + Math.cos(angle) * halfSize * 0.5, screenY + Math.sin(angle) * halfSize * 0.5);
          c.quadraticCurveTo(
            screenX + Math.cos(angle + 0.5) * halfSize,
            screenY + Math.sin(angle + 0.5) * halfSize,
            ex, ey
          );
          c.stroke();
        }
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
        // Eyes
        c.fillStyle = '#ffffff';
        c.beginPath();
        c.arc(screenX - 6, screenY - 3, 4, 0, Math.PI * 2);
        c.fill();
        c.beginPath();
        c.arc(screenX + 6, screenY - 3, 4, 0, Math.PI * 2);
        c.fill();
      } else if (boss.bossType === BossType.VOID_RIFT) {
        // Void portal - swirling dark mass
        c.fillStyle = bossColor;
        c.globalAlpha = 0.8;
        c.beginPath();
        c.arc(screenX, screenY, halfSize + pulse + 4, 0, Math.PI * 2);
        c.fill();
        // Inner void
        c.fillStyle = '#0d0d1a';
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.5, 0, Math.PI * 2);
        c.fill();
        // Swirl effect
        c.strokeStyle = '#a855f7';
        c.lineWidth = 2;
        c.globalAlpha = 0.5;
        const spin: number = this.frameCount * 0.04;
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.7, spin, spin + Math.PI * 1.2);
        c.stroke();
        c.beginPath();
        c.arc(screenX, screenY, halfSize * 0.9, spin + Math.PI, spin + Math.PI * 2.2);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
      }

      // Phase 2 indicator - pulsing aura
      if (boss.phase === BossPhase.PHASE_2) {
        c.strokeStyle = bossColor;
        c.lineWidth = 2;
        c.globalAlpha = 0.3 + 0.2 * Math.sin(this.frameCount * 0.1);
        c.beginPath();
        c.arc(screenX, screenY, halfSize + 8 + pulse, 0, Math.PI * 2);
        c.stroke();
        c.globalAlpha = 1.0;
        c.lineWidth = 1;
      }
    }
    c.globalAlpha = 1.0;
  }

  private renderMaterialDrops(c: CanvasRenderingContext2D, offX: number, offY: number): void {
    for (let i: number = 0; i < this.materialDrops.length; i++) {
      const drop: MaterialDrop = this.materialDrops[i];
      if (!drop.active) continue;

      const screenX: number = drop.x + offX;
      const screenY: number = drop.y + offY;

      if (screenX < -20 || screenX > this.screenW + 20 || screenY < -20 || screenY > this.screenH + 20) {
        continue;
      }

      const bob: number = Math.sin(this.frameCount * 0.06 + drop.bobPhase) * 3;
      const drawY: number = screenY + bob;

      let color: string = '#ffffff';
      if (drop.type === MaterialType.CRYSTAL_ORE) color = COLOR_CRYSTAL;
      else if (drop.type === MaterialType.MUSHROOM_ORE) color = COLOR_MUSHROOM_CAP;
      else if (drop.type === MaterialType.FLAME_ORE) color = COLOR_LAVA_LIGHT;
      else if (drop.type === MaterialType.ABYSS_ORE) color = COLOR_BOSS_ABYSS;
      else if (drop.type === MaterialType.VOID_ORE) color = COLOR_BOSS_VOID;
      else if (drop.type === MaterialType.CORE_NORMAL) color = '#c0c0c0';
      else if (drop.type === MaterialType.CORE_RARE) color = '#ffd700';
      else if (drop.type === MaterialType.FORM_CORE) color = '#e879f9';

      // Glow
      c.globalAlpha = 0.3;
      c.fillStyle = color;
      c.beginPath();
      c.arc(screenX, drawY, 8, 0, Math.PI * 2);
      c.fill();

      // Item
      c.globalAlpha = 1.0;
      c.fillStyle = color;
      c.fillRect(screenX - 4, drawY - 4, 8, 8);
      c.strokeStyle = '#ffffff';
      c.lineWidth = 1;
      c.strokeRect(screenX - 4, drawY - 4, 8, 8);
    }
    c.globalAlpha = 1.0;
  }

  private renderBossHPBar(c: CanvasRenderingContext2D): void {
    // Show HP bar for active boss
    const boss: BossState | null = this.activeBoss;
    if (boss === null || boss.defeated) {
      // Also check for any active optional boss
      for (let i: number = 0; i < this.bosses.length; i++) {
        if (this.bosses[i].active && !this.bosses[i].defeated) {
          this.drawBossHPBar(c, this.bosses[i]);
          return;
        }
      }
      return;
    }
    this.drawBossHPBar(c, boss);
  }

  private drawBossHPBar(c: CanvasRenderingContext2D, boss: BossState): void {
    const barW: number = 200;
    const barH: number = 12;
    const barX: number = (this.screenW - barW) / 2;
    const barY: number = 20;
    const hpRatio: number = Math.max(0, boss.hp / boss.maxHp);

    // Background
    c.fillStyle = COLOR_BOSS_HP_BG;
    c.globalAlpha = 0.8;
    c.fillRect(barX - 2, barY - 2, barW + 4, barH + 4);

    // HP bar
    c.fillStyle = COLOR_BOSS_HP_BAR;
    c.globalAlpha = 1.0;
    c.fillRect(barX, barY, barW * hpRatio, barH);

    // Border
    c.strokeStyle = '#ffffff';
    c.lineWidth = 1;
    c.globalAlpha = 0.5;
    c.strokeRect(barX - 2, barY - 2, barW + 4, barH + 4);

    // Boss name
    c.globalAlpha = 1.0;
    c.fillStyle = '#ffffff';
    c.font = '10px sans-serif';
    c.textAlign = 'center';
    let name: string = 'Boss';
    if (boss.bossType === BossType.CRYSTAL_GUARDIAN) name = 'Crystal Guardian';
    else if (boss.bossType === BossType.MUSHROOM_KING) name = 'Mushroom King';
    else if (boss.bossType === BossType.LAVA_BEAST) name = 'Lava Beast';
    else if (boss.bossType === BossType.ABYSS_SIREN) name = 'Abyss Siren';
    else if (boss.bossType === BossType.VOID_RIFT) name = 'Void Rift';
    if (boss.phase === BossPhase.PHASE_2) name += ' [Enraged]';
    c.fillText(name, this.screenW / 2, barY - 6);
  }
}
