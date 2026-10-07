import { Component, Serializable } from '@qiuyu/engine';
import { DevourState } from '../GameConstants';

export class DevourComponent implements Component, Serializable {
  state: number = DevourState.IDLE;
  devourTimer: number = 0;
  devourTargetId: number = -1;

  getType(): string { return "devour"; }

  serialize(): Record<string, Object> {
    const result: Record<string, Object> = {} as Record<string, Object>;
    result["state"] = this.state as Object;
    result["devourTimer"] = this.devourTimer as Object;
    result["devourTargetId"] = this.devourTargetId as Object;
    return result;
  }

  deserialize(data: Record<string, Object>): void {
    this.state = data["state"] as number;
    this.devourTimer = data["devourTimer"] as number;
    this.devourTargetId = data["devourTargetId"] as number;
  }
}
