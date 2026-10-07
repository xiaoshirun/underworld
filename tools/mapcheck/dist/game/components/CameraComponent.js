"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CameraComponent = void 0;
class CameraComponent {
    constructor() {
        this.shakeX = 0;
        this.shakeY = 0;
        this.shakeTimer = 0;
    }
    getType() { return "camera"; }
}
exports.CameraComponent = CameraComponent;
