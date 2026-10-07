"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlayerMovementSystem = void 0;
const engine_1 = require("@qiuyu/engine");
const GameConstants_1 = require("../GameConstants");
const SystemHelpers_1 = require("../helpers/SystemHelpers");
class PlayerMovementSystem extends engine_1.System {
    update(entities, context) {
        const player = context.world.findEntityByTag("player");
        if (player === null)
            return;
        const pos = player.getComponent("Position");
        const vel = player.getComponent("Velocity");
        const health = player.getComponent("Health");
        const movement = player.getComponent("movement");
        const combat = player.getComponent("combat");
        const transform = player.getComponent("transform");
        const humanForm = player.getComponent("humanForm");
        if (pos === null || vel === null || health === null || movement === null || combat === null || transform === null)
            return;
        if (health.isDead())
            return;
        // Transform movement is handled by TransformSystem
        if (transform.isTransformed)
            return;
        // Human form speed bonus
        let speedMult = 1.0;
        if (humanForm !== null && humanForm.isHumanForm && humanForm.humanFormStage >= 0) {
            speedMult = 1.0 + GameConstants_1.HUMAN_FORM_SPEED_BONUS[humanForm.humanFormStage];
        }
        const audio = context.audio;
        const chunks = context.world.chunks;
        // Engulfed player logic
        if (movement.isEngulfed) {
            this.updateEngulfedPlayer(entities, player, pos, health, movement, combat, audio, context);
            return;
        }
        // Joystick input
        let moveX = 0;
        let moveY = 0;
        if (context.input.joyActive) {
            const len = Math.sqrt(context.input.joyDx * context.input.joyDx + context.input.joyDy * context.input.joyDy);
            if (len > 0.1) {
                moveX = context.input.joyDx / len;
                moveY = context.input.joyDy / len;
                movement.facing = Math.atan2(context.input.joyDy, context.input.joyDx);
            }
        }
        // Drilling: cancel if joystick moved significantly
        if (movement.isDrilling) {
            if (context.input.joyActive) {
                const dLen = Math.sqrt(context.input.joyDx * context.input.joyDx + context.input.joyDy * context.input.joyDy);
                if (dLen > 0.3) {
                    movement.isDrilling = false;
                    movement.isUsingTool = false;
                    movement.drillHitCount = 0;
                }
            }
            if (movement.isDrilling) {
                this.updateDrilling(pos, movement, chunks, audio, context);
                return;
            }
        }
        // Dash movement
        if (movement.isDashing) {
            movement.dashTimer -= context.dt;
            if (movement.dashTimer <= 0) {
                movement.isDashing = false;
            }
            else {
                vel.vx = movement.dashDirX * GameConstants_1.DASH_SPEED * speedMult;
                vel.vy = movement.dashDirY * GameConstants_1.DASH_SPEED * speedMult;
            }
        }
        else {
            vel.vx = moveX * GameConstants_1.PLAYER_SPEED * speedMult;
            vel.vy = moveY * GameConstants_1.PLAYER_SPEED * speedMult;
        }
        // Collision resolution
        const newX = pos.x + vel.vx;
        const newY = pos.y + vel.vy;
        if (!this.checkPlayerCollision(newX, pos.y, transform, chunks)) {
            pos.x = newX;
        }
        if (!this.checkPlayerCollision(pos.x, newY, transform, chunks)) {
            pos.y = newY;
        }
        // Jump
        if (context.input.jumpPressed && !movement.isJumping) {
            movement.isJumping = true;
            movement.jumpTimer = 300;
            context.input.jumpPressed = false;
            audio.playJump();
        }
        if (movement.isJumping) {
            movement.jumpTimer -= context.dt;
            const progress = 1.0 - (movement.jumpTimer / 300);
            movement.jumpHeight = Math.sin(progress * Math.PI) * 12;
            if (movement.jumpTimer <= 0) {
                movement.isJumping = false;
                movement.jumpHeight = 0;
            }
        }
        // Attack trigger
        if (context.input.attackPressed && !combat.isAttacking && combat.attackTimer <= 0) {
            const formStats = GameConstants_1.WEAPON_FORM_STATS[transform.currentWeaponForm];
            const formDuration = formStats[2];
            combat.isAttacking = true;
            combat.attackTimer = formDuration;
            context.input.attackPressed = false;
        }
        // Attack timer: active phase then cooldown
        if (combat.isAttacking) {
            combat.attackTimer -= context.dt;
            if (combat.attackTimer <= 0) {
                combat.isAttacking = false;
                const formStats = GameConstants_1.WEAPON_FORM_STATS[transform.currentWeaponForm];
                combat.attackTimer = formStats[3] - formStats[2];
            }
        }
        else if (combat.attackTimer > 0) {
            combat.attackTimer -= context.dt;
        }
        // Tool / drill trigger
        if (context.input.toolPressed && !movement.isUsingTool && movement.toolCooldown <= 0 && !movement.isDrilling) {
            context.input.toolPressed = false;
            const cosF = Math.cos(movement.facing);
            const sinF = Math.sin(movement.facing);
            let bestTX = -1;
            let bestTY = -1;
            let bestDist = 9999;
            for (let r = 1; r <= 3; r++) {
                const checkX = pos.x + cosF * GameConstants_1.TILE_SIZE * r;
                const checkY = pos.y + sinF * GameConstants_1.TILE_SIZE * r;
                const ctx2 = Math.floor(checkX / GameConstants_1.TILE_SIZE);
                const cty = Math.floor(checkY / GameConstants_1.TILE_SIZE);
                for (let ox = -1; ox <= 1; ox++) {
                    for (let oy = -1; oy <= 1; oy++) {
                        const ttx = ctx2 + ox;
                        const tty = cty + oy;
                        if ((0, SystemHelpers_1.getTile)(chunks, ttx * GameConstants_1.TILE_SIZE, tty * GameConstants_1.TILE_SIZE) === GameConstants_1.TileType.WALL) {
                            const dx = (ttx * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2) - pos.x;
                            const dy = (tty * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2) - pos.y;
                            const dist = dx * dx + dy * dy;
                            if (dist < bestDist) {
                                bestDist = dist;
                                bestTX = ttx;
                                bestTY = tty;
                            }
                        }
                    }
                }
            }
            if (bestTX >= 0) {
                movement.isUsingTool = true;
                movement.isDrilling = true;
                movement.drillTargetX = bestTX;
                movement.drillTargetY = bestTY;
                movement.drillHitCount = 0;
                vel.vx = 0;
                vel.vy = 0;
                movement.toolCooldown = 200;
            }
        }
        if (movement.toolCooldown > 0)
            movement.toolCooldown -= context.dt;
        if (movement.isUsingTool && !movement.isDrilling) {
            movement.isUsingTool = false;
        }
        // Dash trigger
        if (context.input.dashPressed && !movement.isDashing && movement.dashCooldown <= 0) {
            movement.isDashing = true;
            movement.dashTimer = GameConstants_1.DASH_DURATION;
            movement.dashCooldown = GameConstants_1.DASH_COOLDOWN;
            combat.invincibleTimer = GameConstants_1.DASH_DURATION;
            const dx = Math.cos(movement.facing);
            const dy = Math.sin(movement.facing);
            movement.dashDirX = dx;
            movement.dashDirY = dy;
            context.input.dashPressed = false;
            audio.playDash();
        }
        if (movement.dashCooldown > 0)
            movement.dashCooldown -= context.dt;
        if (combat.invincibleTimer > 0)
            combat.invincibleTimer -= context.dt;
        // Animation
        if (Math.abs(vel.vx) > 0.1 || Math.abs(vel.vy) > 0.1) {
            combat.animFrame += 0.15;
        }
    }
    updateDrilling(pos, movement, chunks, audio, context) {
        const wallWorldX = movement.drillTargetX * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
        const wallWorldY = movement.drillTargetY * GameConstants_1.TILE_SIZE + GameConstants_1.TILE_SIZE / 2;
        movement.facing = Math.atan2(wallWorldY - pos.y, wallWorldX - pos.x);
        const distToWall = Math.sqrt((pos.x - wallWorldX) * (pos.x - wallWorldX) + (pos.y - wallWorldY) * (pos.y - wallWorldY));
        if (distToWall > GameConstants_1.TILE_SIZE * 2.5) {
            movement.isDrilling = false;
            movement.drillHitCount = 0;
            return;
        }
        movement.drillHitCount += context.dt;
        if (context.frameCount % 19 === 0) {
            audio.playDrillHit();
        }
        const breakTime = GameConstants_1.DRILL_BREAK_HITS * 300;
        if (movement.drillHitCount >= breakTime) {
            (0, SystemHelpers_1.setTile)(chunks, wallWorldX, wallWorldY, GameConstants_1.TileType.BROKEN_WALL);
            audio.playWallBreak();
            movement.isDrilling = false;
            movement.drillHitCount = 0;
        }
    }
    updateEngulfedPlayer(entities, player, pos, health, movement, combat, audio, context) {
        movement.engulfDamageTimer -= context.dt;
        if (movement.engulfDamageTimer <= 0) {
            health.damage(GameConstants_1.SLIME_DAMAGE);
            movement.engulfDamageTimer = GameConstants_1.ENGULF_DAMAGE_INTERVAL;
            audio.playPlayerDamage();
            (0, SystemHelpers_1.shakeCamera)(context, 100);
            (0, SystemHelpers_1.triggerDamageFlash)(context);
        }
        if (movement.engulfEscapeCount >= GameConstants_1.ENGULF_ESCAPE_ATTACKS) {
            movement.isEngulfed = false;
            // Find the engulfing enemy
            let engulfingEnemy = null;
            for (let i = 0; i < entities.length; i++) {
                const e = entities[i];
                if (e.active && e.tag === "enemy") {
                    const ai = e.getComponent("enemyAI");
                    if (ai !== null && ai.isEngulfing && ai.engulfedPlayer) {
                        engulfingEnemy = e;
                        break;
                    }
                }
            }
            if (engulfingEnemy !== null) {
                const ai = engulfingEnemy.getComponent("enemyAI");
                const enemyPos = engulfingEnemy.getComponent("Position");
                ai.isEngulfing = false;
                ai.engulfedPlayer = false;
                const angle = Math.random() * Math.PI * 2;
                pos.x = enemyPos.x + Math.cos(angle) * 20;
                pos.y = enemyPos.y + Math.sin(angle) * 20;
            }
            movement.engulfEscapeCount = 0;
            combat.invincibleTimer = GameConstants_1.INVINCIBLE_DURATION;
        }
    }
    checkPlayerCollision(x, y, transform, chunks) {
        if (transform.isTransformed && transform.transformForm === GameConstants_1.TransformForm.GHOST) {
            return false;
        }
        const halfSize = GameConstants_1.PLAYER_SIZE / 2;
        const cornersX = [x - halfSize, x + halfSize];
        const cornersY = [y - halfSize, y + halfSize];
        for (let i = 0; i < 2; i++) {
            for (let j = 0; j < 2; j++) {
                const tile = (0, SystemHelpers_1.getTile)(chunks, cornersX[i], cornersY[j]);
                if (!(0, SystemHelpers_1.isWalkable)(tile))
                    return true;
            }
        }
        return false;
    }
}
exports.PlayerMovementSystem = PlayerMovementSystem;
