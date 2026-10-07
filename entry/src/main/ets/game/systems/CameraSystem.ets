import { System, SystemContext, Entity, PositionComponent } from '@qiuyu/engine';
import { CameraComponent } from '../components/CameraComponent';

export class CameraSystem extends System {
  update(entities: Entity[], context: SystemContext): void {
    const player: Entity | null = context.world.findEntityByTag("player");
    const cameraEntity: Entity | null = context.world.findEntityByTag("camera");
    if (!player || !cameraEntity) return;

    const pos: PositionComponent = player.getComponent<PositionComponent>("Position")!;
    const cam: CameraComponent = cameraEntity.getComponent<CameraComponent>("camera")!;

    // 相机跟随（平滑插值）
    const targetX: number = pos.x - context.screenW / 2;
    const targetY: number = pos.y - context.screenH / 2;
    context.world.cameraX += (targetX - context.world.cameraX) * 0.1;
    context.world.cameraY += (targetY - context.world.cameraY) * 0.1;

    // 震动衰减 — actual values from existing GameEngine.updateShake()
    if (cam.shakeTimer > 0) {
      cam.shakeTimer -= context.dt;
      const intensity: number = 3 * (cam.shakeTimer / 150);
      cam.shakeX = (Math.random() - 0.5) * intensity * 2;
      cam.shakeY = (Math.random() - 0.5) * intensity * 2;
      if (cam.shakeTimer <= 0) {
        cam.shakeX = 0;
        cam.shakeY = 0;
      }
    }
  }
}
