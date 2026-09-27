export type ColliderType = 'box' | 'circle';

export interface Collider {
  type: ColliderType;
  width: number;
  height: number;
  radius: number;
  offsetX: number;
  offsetY: number;
  isTrigger: boolean;
  layer: number;
  mask: number;
  onCollisionEnter: boolean;
}

export function createBoxCollider(w: number, h: number): Collider {
  return { type: 'box', width: w, height: h, radius: 0, offsetX: 0, offsetY: 0, isTrigger: false, layer: 0, mask: 0xFFFF, onCollisionEnter: false };
}

export function createCircleCollider(radius: number): Collider {
  return { type: 'circle', width: 0, height: 0, radius: radius, offsetX: 0, offsetY: 0, isTrigger: false, layer: 0, mask: 0xFFFF, onCollisionEnter: false };
}
