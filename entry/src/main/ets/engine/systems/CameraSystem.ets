import { Entity } from '../core/Entity';
import { System } from '../core/System';
import { World } from '../core/World';
import { CameraComponent } from '../components/Camera';
import { Transform } from '../components/Transform';

export class CameraSystem extends System {
  readonly name: string = 'camera';
  readonly dependencies: string[] = [];
  priority: number = 20;

  private cameraX: number = 0;
  private cameraY: number = 0;
  private shakeOffsetX: number = 0;
  private shakeOffsetY: number = 0;

  update(world: World, dt: number, entities: Entity[]): void {
    const cameras: Entity[] = world.query('camera', 'transform');
    for (const e of cameras) {
      const cam: CameraComponent | undefined = world.getComponent<CameraComponent>(e, 'camera');
      const transform: Transform | undefined = world.getComponent<Transform>(e, 'transform');
      if (!cam || !transform) continue;

      if (cam.followEntity >= 0 && world.isEntityAlive(cam.followEntity)) {
        const target: Transform | undefined = world.getComponent<Transform>(cam.followEntity, 'transform');
        if (target) {
          const targetX: number = target.x + cam.offsetX;
          const targetY: number = target.y + cam.offsetY;
          transform.x += (targetX - transform.x) * cam.lerpSpeed;
          transform.y += (targetY - transform.y) * cam.lerpSpeed;
        }
      }

      if (transform.x < cam.worldMinX) transform.x = cam.worldMinX;
      if (transform.y < cam.worldMinY) transform.y = cam.worldMinY;
      if (transform.x > cam.worldMaxX) transform.x = cam.worldMaxX;
      if (transform.y > cam.worldMaxY) transform.y = cam.worldMaxY;

      if (cam.shakeTimer > 0) {
        cam.shakeTimer -= dt;
        const intensity: number = cam.shakeIntensity * (cam.shakeTimer / 1000);
        this.shakeOffsetX = (Math.random() * 2 - 1) * intensity;
        this.shakeOffsetY = (Math.random() * 2 - 1) * intensity;
      } else {
        this.shakeOffsetX = 0;
        this.shakeOffsetY = 0;
      }

      this.cameraX = transform.x + this.shakeOffsetX;
      this.cameraY = transform.y + this.shakeOffsetY;
    }
  }

  getCameraX(): number { return this.cameraX; }
  getCameraY(): number { return this.cameraY; }
  getShakeOffsetX(): number { return this.shakeOffsetX; }
  getShakeOffsetY(): number { return this.shakeOffsetY; }
}
