export interface CameraComponent {
  followEntity: number;
  lerpSpeed: number;
  offsetX: number;
  offsetY: number;
  shakeIntensity: number;
  shakeTimer: number;
  shakeDecay: number;
  zoom: number;
  worldMinX: number;
  worldMinY: number;
  worldMaxX: number;
  worldMaxY: number;
}

export function createCamera(): CameraComponent {
  return { followEntity: -1, lerpSpeed: 0.1, offsetX: 0, offsetY: 0, shakeIntensity: 0, shakeTimer: 0, shakeDecay: 0.9, zoom: 1.0, worldMinX: -99999, worldMinY: -99999, worldMaxX: 99999, worldMaxY: 99999 };
}
