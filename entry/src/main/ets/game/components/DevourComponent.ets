import { Component, Serializable } from '@qiuyu/engine';
import { DevourState } from '../GameConstants';

export class DevourComponent implements Component, Serializable {
  state: number = DevourState.IDLE;
  devourTimer: number = 0;
  devourTargetId: number = -1;

  getType(): string { return "devour"; }

  serialize(): Record<string, Object> {
    return { state: this.state, devourTimer: this.devourTimer, devourTargetId: this.devourTargetId };
  }

  deserialize(data: Record<string, Object>): void {
    this.state = data["state"] as number;
    this.devourTimer = data["devourTimer"] as number;
    this.devourTargetId = data["devourTargetId"] as number;
  }
}
