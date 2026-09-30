import { System, SystemContext, Entity, PositionComponent, VelocityComponent, HealthComponent } from '@qiuyu/engine';
import { MovementComponent } from '../components/MovementComponent';
import { CombatComponent } from '../components/CombatComponent';
import { EnemyAIComponent } from '../components/EnemyAIComponent';
import { LevelComponent } from '../components/LevelComponent';
import { SkillComponent } from '../components/SkillComponent';
import { DevourComponent } from '../components/DevourComponent';
import { HumanFormComponent } from '../components/HumanFormComponent';
import { SkillSystem } from './SkillSystem';
import { DropFactory } from '../factories/DropFactory';
import { shakeCamera } from '../helpers/SystemHelpers';
import {
  SLIME_KNOCKBACK, ATTACK_RANGE, ATTACK_WIDTH, ATTACK_DURATION, ATTACK_COOLDOWN,
  TRANSFORM_ENERGY_KILL_SLIME, DevourState, SkillSlot,
} from '../GameConstants';
import { IAudioService } from '../interfaces/IAudioService';

export class PlayerCombatSystem extends System {

  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    if (player === null) return;

    const pos: PositionComponent | null = player.getComponent<PositionComponent>("Position");
    const movement: MovementComponent | null = player.getComponent<MovementComponent>("movement");
    const combat: CombatComponent | null = player.getComponent<CombatComponent>("combat");
    const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
    const playerLevel: LevelComponent | null = player.getComponent<LevelComponent>("level");
    const skill: SkillComponent | null = player.getComponent<SkillComponent>("skill");
    const devour: DevourComponent | null = player.getComponent<DevourComponent>("devour");
    const humanForm: HumanFormComponent | null = player.getComponent<HumanFormComponent>("humanForm");
    if (pos === null || movement === null || combat === null || health === null) return;
    if (playerLevel === null || skill === null) return;

    const audio: IAudioService = context.audio as IAudioService;

    // Skip if devour is in progress
    if (devour !== null && devour.state !== DevourState.IDLE) return;

    // Handle attack trigger (engulf escape or normal attack initiation)
    if (context.input.attackPressed) {
      context.input.attackPressed = false;
      if (movement.isEngulfed) {
        movement.engulfEscapeCount++;
        audio.playEnemyHit();
        shakeCamera(context, 80);
        return;
      }

      // Check if we have a skill equipped and cooldown is ready
      const selectedSkill: SkillSlot | null = skill.getSelectedSkill();
      if (selectedSkill !== null && skill.skillCooldown <= 0) {
        combat.isAttacking = true;
        const cooldown: number = SkillSystem.getSkillCooldown(selectedSkill.family, selectedSkill.tier);
        combat.attackTimer = cooldown;
        skill.skillCooldown = cooldown;
      } else if (selectedSkill === null) {
        // Basic bump attack (no skill equipped)
        combat.isAttacking = true;
        combat.attackTimer = ATTACK_COOLDOWN;
      }
    }

    // Process active attack
    if (combat.isAttacking) {
      combat.attackTimer -= context.dt;
      if (combat.attackTimer <= 0) {
        combat.isAttacking = false;
      } else {
        this.performSkillAttack(entities, pos, movement, combat, playerLevel, skill, humanForm, audio, context);
      }
    }
  }

  private performSkillAttack(
    entities: Entity[],
    pos: PositionComponent,
    movement: MovementComponent,
    combat: CombatComponent,
    playerLevel: LevelComponent,
    skill: SkillComponent,
    humanForm: HumanFormComponent | null,
    audio: IAudioService,
    context: SystemContext
  ): void {
    const selectedSkill: SkillSlot | null = skill.getSelectedSkill();
    let attackRange: number = ATTACK_RANGE;
    let attackWidth: number = ATTACK_WIDTH;
    let damage: number = 1;

    if (selectedSkill !== null) {
      attackRange = SkillSystem.getSkillRange(selectedSkill.family, selectedSkill.tier);
      damage = SkillSystem.getSkillDamage(selectedSkill.family, selectedSkill.tier, playerLevel.level);
      attackWidth = SkillSystem.getSkillAoeRadius(selectedSkill.family, selectedSkill.tier);
      if (attackWidth === 0) attackWidth = 20; // Single target skills have small hitbox
    }

    const attackX: number = pos.x + Math.cos(movement.facing) * attackRange;
    const attackY: number = pos.y + Math.sin(movement.facing) * attackRange;

    const nearby: Entity[] = context.world.getSpatialGrid().queryRadius(attackX, attackY, attackWidth + 60);

    for (let i: number = 0; i < nearby.length; i++) {
      const e: Entity = nearby[i];
      if (!e.active) continue;

      if (e.tag === "enemy") {
        const enemyPos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
        const enemyVel: VelocityComponent | null = e.getComponent<VelocityComponent>("Velocity");
        const enemyHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
        const ai: EnemyAIComponent | null = e.getComponent<EnemyAIComponent>("enemyAI");
        if (enemyPos === null || enemyVel === null || enemyHealth === null || ai === null) continue;

        const dx: number = enemyPos.x - attackX;
        const dy: number = enemyPos.y - attackY;
        const dist: number = Math.sqrt(dx * dx + dy * dy);
        if (dist < attackWidth + ai.size) {
          enemyHealth.damage(damage);
          ai.hitFlash = 150;
          const knockAngle: number = Math.atan2(dy, dx);
          enemyVel.vx = Math.cos(knockAngle) * SLIME_KNOCKBACK;
          enemyVel.vy = Math.sin(knockAngle) * SLIME_KNOCKBACK;
          shakeCamera(context, 100);
          audio.playEnemyHit();

          if (enemyHealth.isDead()) {
            this.onEnemyDeath(e, enemyPos, ai, humanForm, audio, context);
          }
        }
      } else if (e.tag === "boss") {
        const bossPos: PositionComponent | null = e.getComponent<PositionComponent>("Position");
        const bossHealth: HealthComponent | null = e.getComponent<HealthComponent>("Health");
        if (bossPos === null || bossHealth === null) continue;

        const dx: number = bossPos.x - attackX;
        const dy: number = bossPos.y - attackY;
        const dist: number = Math.sqrt(dx * dx + dy * dy);
        if (dist < attackWidth + 60) {
          bossHealth.damage(damage);
          shakeCamera(context, 120);
          audio.playEnemyHit();
        }
      }
    }
  }

  private onEnemyDeath(
    enemy: Entity,
    enemyPos: PositionComponent,
    ai: EnemyAIComponent,
    humanForm: HumanFormComponent | null,
    audio: IAudioService,
    context: SystemContext
  ): void {
    enemy.active = false;

    // Human form energy gain
    if (humanForm !== null && humanForm.isHumanForm) {
      humanForm.formEnergy += TRANSFORM_ENERGY_KILL_SLIME;
      if (humanForm.formEnergy > humanForm.formMaxEnergy) {
        humanForm.formEnergy = humanForm.formMaxEnergy;
      }
    }

    audio.playEnemyDeath();

    // Create XP orb drops
    const orbCount: number = 1 + Math.floor(Math.random() * 3);
    for (let k: number = 0; k < orbCount; k++) {
      const angle: number = Math.random() * Math.PI * 2;
      const dist: number = 5 + Math.random() * 15;
      const orb: Entity = DropFactory.createXpOrb(
        enemyPos.x + Math.cos(angle) * dist,
        enemyPos.y + Math.sin(angle) * dist,
        1
      );
      context.world.addEntity(orb);
    }
  }
}
