export interface Sprite {
  color: string;
  width: number;
  height: number;
  visible: boolean;
  alpha: number;
  flipX: boolean;
}

export function createSprite(color: string, width: number, height: number): Sprite {
  return { color: color, width: width, height: height, visible: true, alpha: 1.0, flipX: false };
}
