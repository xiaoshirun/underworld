import { Component } from '@qiuyu/engine';

export class CameraComponent implements Component {
  shakeX: number = 0;
  shakeY: number = 0;
  shakeTimer: number = 0;

  getType(): string { return "camera"; }
}
