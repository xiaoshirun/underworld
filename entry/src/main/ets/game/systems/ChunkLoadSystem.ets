import { TILE_SIZE, CHUNK_SIZE, PlayerState } from '../GameConstants';
import { GameContext } from '../GameContext';

export class ChunkLoadSystem {
  private g: GameContext;

  constructor(g: GameContext) {
    this.g = g;
  }

  update(): void {
    if (this.g.player === null) return;
    const p: PlayerState = this.g.player;

    const ptx: number = Math.floor(p.x / TILE_SIZE);
    const pty: number = Math.floor(p.y / TILE_SIZE);
    this.g.loadChunksAround(ptx, pty);
  }
}
