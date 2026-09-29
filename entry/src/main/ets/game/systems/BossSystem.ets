import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { BossAIComponent } from '../components/BossAIComponent';
import { GameStateComponent } from '../components/GameStateComponent';
import { TransformComponent } from '../components/TransformComponent';
import { CombatComponent } from '../components/CombatComponent';
import { CameraComponent } from '../components/CameraComponent';
import { ChestComponent } from '../components/ChestComponent';
import { DropFactory } from '../factories/DropFactory';
import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE, BOSS_SIZE,
  BOSS_ATTACK_INTERVAL, BOSS_PHASE2_THRESHOLD, BOSS_ROOM_SIZE,
  INVINCIBLE_DURATION,
  TRANSFORM_ENERGY_KILL_BOSS,
  TileType, BossType, BossRole, BossPhase, MaterialType, TransformForm,
  ChunkData, GameSettings,
} from '../GameConstants';

interface AudioManager {
  playPlayerDamage(): void;
  playEnemyDeath(): void;
}

// extraData index for hit flash timer (BossAIComponent lacks a dedicated hitFlash field)
const EXTRA_HIT_FLASH: number = 0;

export class BossSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const playerPos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const playerVel: VelocityComponent | null = player.getComponent<VelocityComponent>("Velocity");
    const playerHealth: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const playerCombat: CombatComponent | null = player.getComponent<CombatComponent>("combat");
    const playerTransform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
    if (playerPos === null || playerVel === null || playerHealth === null ||
        playerCombat === null || playerTransform === null) return;

    if (playerHealth.isDead()) return;

    const gsEntity: Entity | null = context.world.findEntityByTag("gameState");
    const gs: GameStateComponent | null = gsEntity !== null
      ? gsEntity.getComponent<GameStateComponent>("gameState") : null;

    const audio: AudioManager = context.audio as AudioManager;
    const settings: GameSettings = context.settings as GameSettings;
    const dt: number = context.dt;
    const chunks: Map<string, Object> = context.world.chunks;

    for (let i: number = 0; i < entities.length; i++) {
      const e: Entity = entities[i];
      if (!e.active || e.tag !== "boss") continue;

      const pos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
      const vel: VelocityComponent | null = e.getComponent<VelocityComponent>("Velocity");
      const health: HealthComponent | null = e.getComponent<HealthComponent>("Health");
      const ai: BossAIComponent | null = e.getComponent<BossAIComponent>("bossAI");
      if (pos === null || vel === null || health === null || ai === null) continue;
      if (ai.defeated) continue;

      const dx: number = playerPos.x - pos.x;
      const dy: number = playerPos.y - pos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      // --- Movement AI by role ---
      if (ai.bossRole === BossRole.PASSAGE_GUARDIAN) {
        // Passage guardians always chase the player
        if (dist > 1) {
          const speed: number = 1.5;
          vel.vx = (dx / dist) * speed;
          vel.vy = (dy / dist) * speed;
        }
      } else {
        // Optional challenge bosses chase only within aggro radius
        if (dist < ai.aggroRadius) {
          if (dist > 1) {
            const speed: number = 1.8;
            vel.vx = (dx / dist) * speed;
            vel.vy = (dy / dist) * speed;
          }
        } else {
          // Idle wander
          ai.attackTimer -= dt;
          if (ai.attackTimer <= 0) {
            const angle: number = Math.random() * Math.PI * 2;
            vel.vx = Math.cos(angle) * 0.5;
            vel.vy = Math.sin(angle) * 0.5;
            ai.attackTimer = 2000 + Math.random() * 3000;
          }
        }
      }

      // Apply velocity to position
      pos.x += vel.vx;
      pos.y += vel.vy;

      // --- Melee attack ---
      ai.attackTimer -= dt;
      if (ai.attackTimer <= 0 && dist < BOSS_SIZE + PLAYER_SIZE + 20) {
        ai.attackTimer = BOSS_ATTACK_INTERVAL;
        if (playerCombat.invincibleTimer <= 0) {
          playerHealth.damage(2);
          playerCombat.invincibleTimer = INVINCIBLE_DURATION;
          audio.playPlayerDamage();

          // Damage flash
          if (gs !== null) {
            gs.damageFlashTimer = 200;
          }

          // Camera shake
          this.shakeCamera(context, 200);

          // Knockback
          if (dist > 1) {
            playerVel.vx = -(dx / dist) * 6;
            playerVel.vy = -(dy / dist) * 6;
          }
        }
      }

      // --- Phase transition ---
      if (health.current > 0 && ai.phase === BossPhase.PHASE_1 &&
          health.current <= health.max * BOSS_PHASE2_THRESHOLD) {
        ai.phase = BossPhase.PHASE_2;
        if (ai.extraData.length <= EXTRA_HIT_FLASH) {
          ai.extraData.push(500);
        } else {
          ai.extraData[EXTRA_HIT_FLASH] = 500;
        }
        this.shakeCamera(context, 400);
      }

      // --- Death check ---
      if (health.current <= 0 && !ai.defeated) {
        this.onBossDeath(e, pos, health, ai, playerPos, playerTransform,
          gs, audio, settings, chunks, context);
      }

      // --- Hit flash decay ---
      if (ai.extraData.length > EXTRA_HIT_FLASH && ai.extraData[EXTRA_HIT_FLASH] > 0) {
        ai.extraData[EXTRA_HIT_FLASH] -= dt;
      }
    }
  }

  private onBossDeath(
    bossEntity: Entity,
    bossPos: PositionComponent,
    bossHealth: HealthComponent,
    ai: BossAIComponent,
    playerPos: PositionComponent,
    playerTransform: TransformComponent,
    gs: GameStateComponent | null,
    audio: AudioManager,
    settings: GameSettings,
    chunks: Map<string, Object>,
    context: SystemContext
  ): void {
    ai.defeated = true;

    // Grant transform energy for boss kill
    if (playerTransform.isTransformed) {
      playerTransform.transformEnergy += TRANSFORM_ENERGY_KILL_BOSS;
      if (playerTransform.transformEnergy > playerTransform.transformMaxEnergy) {
        playerTransform.transformEnergy = playerTransform.transformMaxEnergy;
      }
    }

    bossEntity.active = false;

    // --- Boss room handling ---
    if (ai.bossRole === BossRole.PASSAGE_GUARDIAN) {
      // Unlock boss room
      if (gs !== null) {
        gs.bossRoomLocked = false;
      }

      // Open boss room entrance tiles
      const bcx: number = Math.floor(bossPos.x / (CHUNK_SIZE * TILE_SIZE));
      const bcy: number = Math.floor(bossPos.y / (CHUNK_SIZE * TILE_SIZE));
      this.openBossRoomEntrance(bcx, bcy, chunks);
    }

    // --- Create drops ---
    this.spawnBossDrops(bossPos, ai, context);

    // --- Create boss chest entity ---
    const chestEntity: Entity = new Entity("chest");
    chestEntity.addComponent(new PositionComponent(bossPos.x, bossPos.y));
    const chestComp: ChestComponent = new ChestComponent();
    chestComp.chestType = 2; // ChestType.BOSS
    chestEntity.addComponent(chestComp);
    context.world.addEntity(chestEntity);

    // --- Effects ---
    this.shakeCamera(context, 500);
    audio.playEnemyDeath();
  }

  private spawnBossDrops(
    bossPos: PositionComponent,
    ai: BossAIComponent,
    context: SystemContext
  ): void {
    // Material drops based on boss type
    const dropCount: number = 2 + Math.floor(Math.random() * 2);
    for (let i: number = 0; i < dropCount; i++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 20 + Math.random() * 30;
      const dropX: number = bossPos.x + Math.cos(angle) * dist;
      const dropY: number = bossPos.y + Math.sin(angle) * dist;

      let matType: number = MaterialType.CORE_NORMAL;
      if (ai.bossType === BossType.CRYSTAL_GUARDIAN) {
        matType = MaterialType.CRYSTAL_ORE;
      } else if (ai.bossType === BossType.MUSHROOM_KING) {
        matType = MaterialType.MUSHROOM_ORE;
      } else if (ai.bossType === BossType.LAVA_BEAST) {
        matType = MaterialType.FLAME_ORE;
      } else if (ai.bossType === BossType.ABYSS_SIREN) {
        matType = MaterialType.ABYSS_ORE;
      } else if (ai.bossType === BossType.VOID_RIFT) {
        matType = MaterialType.VOID_ORE;
      }

      const matDrop: Entity = DropFactory.createMaterialDrop(dropX, dropY, matType, 1);
      context.world.addEntity(matDrop);
    }

    // Rare core drop
    const rareDrop: Entity = DropFactory.createMaterialDrop(
      bossPos.x + (Math.random() - 0.5) * 40,
      bossPos.y + (Math.random() - 0.5) * 40,
      MaterialType.CORE_RARE, 1
    );
    context.world.addEntity(rareDrop);

    // Transform core drop
    const transformForm: number = this.getCoreForBoss(ai.bossType);
    if (transformForm !== TransformForm.NONE) {
      const coreDrop: Entity = DropFactory.createTransformCore(
        bossPos.x + (Math.random() - 0.5) * 30,
        bossPos.y + (Math.random() - 0.5) * 30,
        transformForm, 1
      );
      context.world.addEntity(coreDrop);
    }
  }

  private getCoreForBoss(bossType: number): number {
    if (bossType === BossType.MUSHROOM_KING) return TransformForm.SLIME;
    if (bossType === BossType.CRYSTAL_GUARDIAN) return TransformForm.ARMOR;
    if (bossType === BossType.LAVA_BEAST) return TransformForm.IRON_MAN;
    if (bossType === BossType.VOID_RIFT) return TransformForm.GHOST;
    return TransformForm.NONE;
  }

  private openBossRoomEntrance(chunkX: number, chunkY: number, chunks: Map<string, Object>): void {
    const center: number = Math.floor(CHUNK_SIZE / 2);
    const roomRadius: number = Math.floor(BOSS_ROOM_SIZE / 2);
    const dir: number = this.getEntranceDir(chunkX, chunkY);

    // Calculate entrance tile coordinates (tile space, not world space)
    const entranceTilesX: number[] = [];
    const entranceTilesY: number[] = [];

    if (dir === 0) {
      // Top wall
      entranceTilesX.push(chunkX * CHUNK_SIZE + center - 1);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center - roomRadius);
      entranceTilesX.push(chunkX * CHUNK_SIZE + center);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center - roomRadius);
      entranceTilesX.push(chunkX * CHUNK_SIZE + center + 1);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center - roomRadius);
    } else if (dir === 1) {
      // Bottom wall
      entranceTilesX.push(chunkX * CHUNK_SIZE + center - 1);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center + roomRadius);
      entranceTilesX.push(chunkX * CHUNK_SIZE + center);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center + roomRadius);
      entranceTilesX.push(chunkX * CHUNK_SIZE + center + 1);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center + roomRadius);
    } else if (dir === 2) {
      // Left wall
      entranceTilesX.push(chunkX * CHUNK_SIZE + center - roomRadius);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center - 1);
      entranceTilesX.push(chunkX * CHUNK_SIZE + center - roomRadius);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center);
      entranceTilesX.push(chunkX * CHUNK_SIZE + center - roomRadius);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center + 1);
    } else {
      // Right wall
      entranceTilesX.push(chunkX * CHUNK_SIZE + center + roomRadius);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center - 1);
      entranceTilesX.push(chunkX * CHUNK_SIZE + center + roomRadius);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center);
      entranceTilesX.push(chunkX * CHUNK_SIZE + center + roomRadius);
      entranceTilesY.push(chunkY * CHUNK_SIZE + center + 1);
    }

    // Set entrance tiles to FLOOR
    for (let i: number = 0; i < entranceTilesX.length; i++) {
      const worldX: number = entranceTilesX[i] * TILE_SIZE + TILE_SIZE / 2;
      const worldY: number = entranceTilesY[i] * TILE_SIZE + TILE_SIZE / 2;
      this.setTile(chunks, worldX, worldY, TileType.FLOOR);
    }
  }

  private getEntranceDir(cx: number, cy: number): number {
    let h: number = (cx * 13 + 7000) * 374761393 + (cy * 13 + 8000) * 668265263;
    h = ((h ^ (h >> 13)) * 1274126177) | 0;
    return ((h ^ (h >> 16)) >>> 0) % 4;
  }

  private setTile(chunks: Map<string, Object>, worldX: number, worldY: number, tileType: number): void {
    const tx: number = Math.floor(worldX / TILE_SIZE);
    const ty: number = Math.floor(worldY / TILE_SIZE);
    const cx: number = Math.floor(tx / CHUNK_SIZE);
    const cy: number = Math.floor(ty / CHUNK_SIZE);
    const key: string = cx + ',' + cy;
    const chunk: ChunkData | undefined = chunks.get(key) as ChunkData | undefined;
    if (chunk === undefined) return;
    const lx: number = tx - cx * CHUNK_SIZE;
    const ly: number = ty - cy * CHUNK_SIZE;
    chunk.tiles[ly][lx] = tileType;
  }

  private shakeCamera(context: SystemContext, duration: number): void {
    const cameraEntity: Entity | null = context.world.findEntityByTag("camera");
    if (cameraEntity !== null) {
      const cam: CameraComponent = cameraEntity.getComponent<CameraComponent>("camera")!;
      cam.shakeTimer = duration;
    }
  }
}
