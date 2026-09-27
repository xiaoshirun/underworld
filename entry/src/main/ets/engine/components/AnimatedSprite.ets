export interface AnimatedSprite {
  frames: string[];
  currentFrame: number;
  frameDuration: number;
  elapsed: number;
  loop: boolean;
  playing: boolean;
}

export function createAnimatedSprite(frames: string[], frameDuration: number): AnimatedSprite {
  return { frames: frames, currentFrame: 0, frameDuration: frameDuration, elapsed: 0, loop: true, playing: true };
}
