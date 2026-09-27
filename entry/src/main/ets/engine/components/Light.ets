export interface Light {
  color: string;
  radius: number;
  intensity: number;
  flicker: boolean;
  flickerSpeed: number;
  flickerPhase: number;
}

export function createLight(color: string, radius: number, intensity: number): Light {
  return { color: color, radius: radius, intensity: intensity, flicker: false, flickerSpeed: 0, flickerPhase: 0 };
}
