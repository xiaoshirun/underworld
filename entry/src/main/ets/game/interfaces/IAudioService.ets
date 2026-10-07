export interface IAudioService {
  playDrillHit(): void;
  playEnemyHit(): void;
  playEnemyDeath(): void;
  playXpCollect(): void;
  playDash(): void;
  playJump(): void;
  playPlayerDamage(): void;
  playEngulf(): void;
  playWallBreak(): void;
  playLevelUp(): void;
}
