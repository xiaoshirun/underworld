"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CameraSystem = void 0;
const engine_1 = require("@qiuyu/engine");
class CameraSystem extends engine_1.System {
    update(entities, context) {
        const player = context.world.findEntityByTag("player");
        const cameraEntity = context.world.findEntityByTag("camera");
        if (!player || !cameraEntity)
            return;
        const pos = player.getComponent("Position");
        const cam = cameraEntity.getComponent("camera");
        // 相机跟随（平滑插值）
        const targetX = pos.x - context.screenW / 2;
        const targetY = pos.y - context.screenH / 2;
        context.world.cameraX += (targetX - context.world.cameraX) * 0.1;
        context.world.cameraY += (targetY - context.world.cameraY) * 0.1;
        // 震动衰减 — actual values from existing GameEngine.updateShake()
        if (cam.shakeTimer > 0) {
            cam.shakeTimer -= context.dt;
            const intensity = 3 * (cam.shakeTimer / 150);
            cam.shakeX = (Math.random() - 0.5) * intensity * 2;
            cam.shakeY = (Math.random() - 0.5) * intensity * 2;
            if (cam.shakeTimer <= 0) {
                cam.shakeX = 0;
                cam.shakeY = 0;
            }
        }
    }
}
exports.CameraSystem = CameraSystem;
