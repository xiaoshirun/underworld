export interface Transform {
  x: number;
  y: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
  zIndex: number;
}

export function createTransform(x: number, y: number): Transform {
  return { x: x, y: y, rotation: 0, scaleX: 1, scaleY: 1, zIndex: 0 };
}
