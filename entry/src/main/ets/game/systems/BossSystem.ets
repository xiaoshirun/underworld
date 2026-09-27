import {
  TILE_SIZE, CHUNK_SIZE, PLAYER_SIZE,
  BOSS_ATTACK_INTERVAL, BOSS_PHASE2_THRESHOLD,
  INVINCIBLE_DURATION,
  TRANSFORM_ENERGY_KILL_BOSS,
  TileType, PlayerState, BossState, BossRole, BossPhase, BossType,
  MaterialType, ChestType, TransformForm, TransformCoreDrop, BossRoom,
} from '../GameConstants';
import { GameContext } from '../GameContext';

export interface BossBridge {
  getCoreForBoss(bossType: BossType): TransformForm;
  autoSave(): void;
}

export class BossSystem {
  private g: GameContext;
  private bridge: BossBridge;

  constructor(g: GameContext, bridge: BossBridge) {
    this.g = g;
    this.bridge = bridge;
  }

  update(dt: number): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;

    for (let i: number = this.g.bosses.length - 1; i >= 0; i--) {
      const boss: BossState = this.g.bosses[i];
      if (!boss.active || boss.defeated) continue;

      const dx: number = p.x - boss.x;
      const dy: number = p.y - boss.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);

      if (boss.bossRole === BossRole.PASSAGE_GUARDIAN) {
        if (dist > 1) {
          const speed: number = 1.5;
          boss.vx = (dx / dist) * speed;
          boss.vy = (dy / dist) * speed;
        }
      } else {
        if (dist < boss.aggroRadius) {
          if (dist > 1) {
            const speed: number = 1.8;
            boss.vx = (dx / dist) * speed;
            boss.vy = (dy / dist) * speed;
          }
        } else {
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

      boss.attackTimer -= dt;
      if (boss.attackTimer <= 0 && dist < boss.size + PLAYER_SIZE + 20) {
        boss.attackTimer = BOSS_ATTACK_INTERVAL;
        if (p.invincibleTimer <= 0) {
          p.hp -= 2;
          p.invincibleTimer = INVINCIBLE_DURATION;
          this.g.audio.playPlayerDamage();
          this.g.damageFlashTimer = 200;
          this.g.shakeTimer = 200;
          if (dist > 1) {
            p.vx = -(dx / dist) * 6;
            p.vy = -(dy / dist) * 6;
          }
          if (this.g.settings.effectsEnabled) {
            this.g.particleMgr.blood(p.x, p.y, -(dx / dist), -(dy / dist));
          }
        }
      }

      if (boss.phase === BossPhase.PHASE_1 && boss.hp <= boss.maxHp * BOSS_PHASE2_THRESHOLD) {
        boss.phase = BossPhase.PHASE_2;
        boss.hitFlash = 500;
        this.g.shakeTimer = 400;
        if (this.g.settings.effectsEnabled) {
          this.g.particleMgr.explosion(boss.x, boss.y, this.g.getBossColor(boss.bossType), 20);
          this.g.particleMgr.sparks(boss.x, boss.y, '#ffffff', 12);
        }
      }

      if (boss.hp <= 0) {
        this.onBossDeath(boss, p);
      }

      if (boss.hitFlash > 0) {
        boss.hitFlash -= dt;
      }
    }
  }

  private onBossDeath(boss: BossState, p: PlayerState): void {
    boss.defeated = true;
    if (this.g.player !== null && this.g.player.isTransformed) {
      this.g.player.transformEnergy += TRANSFORM_ENERGY_KILL_BOSS;
      if (this.g.player.transformEnergy > this.g.player.transformMaxEnergy) {
        this.g.player.transformEnergy = this.g.player.transformMaxEnergy;
      }
    }
    boss.active = false;

    if (boss.bossRole === BossRole.PASSAGE_GUARDIAN) {
      this.g.bossRoomLocked = false;
      this.g.activeBoss = null;
      for (let j: number = 0; j < this.g.bossRooms.length; j++) {
        const room: BossRoom = this.g.bossRooms[j];
        if (room.chunkX === Math.floor(boss.x / (CHUNK_SIZE * TILE_SIZE)) &&
            room.chunkY === Math.floor(boss.y / (CHUNK_SIZE * TILE_SIZE))) {
          room.defeated = true;
          const entranceTiles: number[][] = this.g.getBossRoomEntranceTiles(room.chunkX, room.chunkY);
          for (let e: number = 0; e < entranceTiles.length; e++) {
            this.g.setTile(
              entranceTiles[e][0] * TILE_SIZE + TILE_SIZE / 2,
              entranceTiles[e][1] * TILE_SIZE + TILE_SIZE / 2,
              TileType.FLOOR
            );
          }
          break;
        }
      }
    } else {
      const bcx: number = Math.floor(boss.x / (CHUNK_SIZE * TILE_SIZE));
      const bcy: number = Math.floor(boss.y / (CHUNK_SIZE * TILE_SIZE));
      this.g.worldGen.markOptionalBossDefeated(bcx, bcy);
      if (this.g.activeBoss === boss) this.g.activeBoss = null;
    }

    if (this.g.settings.effectsEnabled) {
      this.g.particleMgr.explosion(boss.x, boss.y, this.g.getBossColor(boss.bossType), 30);
      this.g.particleMgr.sparks(boss.x, boss.y, '#ffffff', 15);
      this.g.particleMgr.smoke(boss.x, boss.y);
    }

    this.spawnBossDrops(boss);

    this.g.chests.push({
      x: boss.x, y: boss.y,
      chestType: ChestType.BOSS,
      opened: false, active: true,
      guardianDefeated: true, guardianCount: 0,
      openAnim: 0
    });

    this.g.shakeTimer = 500;
    this.g.audio.playEnemyDeath();
    this.bridge.autoSave();
  }

  private spawnBossDrops(boss: BossState): void {
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

      this.g.materialDrops.push({
        x: dropX, y: dropY,
        type: matType, count: 1,
        bobPhase: Math.random() * Math.PI * 2,
        active: true
      });
    }

    this.g.materialDrops.push({
      x: boss.x + (Math.random() - 0.5) * 40,
      y: boss.y + (Math.random() - 0.5) * 40,
      type: MaterialType.CORE_RARE, count: 1,
      bobPhase: Math.random() * Math.PI * 2,
      active: true
    });

    const transformDrop: TransformForm = this.bridge.getCoreForBoss(boss.bossType);
    if (transformDrop !== TransformForm.NONE) {
      const alreadyHas: boolean = this.g.player !== null &&
        this.g.player.unlockedTransforms.indexOf(transformDrop) !== -1;
      if (!alreadyHas) {
        this.g.materialDrops.push({
          x: boss.x + (Math.random() - 0.5) * 30,
          y: boss.y + (Math.random() - 0.5) * 30,
          type: MaterialType.FORM_CORE, count: 1,
          bobPhase: Math.random() * Math.PI * 2,
          active: true
        });
        this.g.transformCoreDrops.push({ dropIndex: this.g.materialDrops.length - 1, form: transformDrop } as TransformCoreDrop);
      }
    }
  }
}
