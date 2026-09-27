export interface AudioSource {
  soundId: string;
  volume: number;
  loop: boolean;
  spatial: boolean;
  playing: boolean;
}

export function createAudioSource(soundId: string): AudioSource {
  return { soundId: soundId, volume: 1.0, loop: false, spatial: false, playing: false };
}
