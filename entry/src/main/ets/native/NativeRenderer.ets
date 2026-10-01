// entry/src/main/ets/native/NativeRenderer.ets
import { DrawCmd } from './DrawCmd';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { napi } from '@kit.ArkTS';

const TAG: string = 'NativeRenderer';
const DOMAIN: number = 0x0000;

export class NativeRenderer {
  private nativeModule: Object | null = null;

  loadModule(): void {
    try {
      this.nativeModule = napi.loadModule('native_renderer');
      hilog.info(DOMAIN, TAG, 'Native module loaded');
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to load native module: ' + String(e));
    }
  }

  init(width: number, height: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeInit'] !== undefined) {
      (m['nativeInit'] as Function)(width, height);
    }
  }

  destroy(): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeDestroy'] !== undefined) {
      (m['nativeDestroy'] as Function)();
    }
  }

  resize(width: number, height: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeResize'] !== undefined) {
      (m['nativeResize'] as Function)(width, height);
    }
  }

  beginFrame(): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeBeginFrame'] !== undefined) {
      (m['nativeBeginFrame'] as Function)();
    }
  }

  submitCommands(cmds: DrawCmd[]): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeSubmitCommands'] !== undefined) {
      (m['nativeSubmitCommands'] as Function)(cmds);
    }
  }

  endFrame(): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeEndFrame'] !== undefined) {
      (m['nativeEndFrame'] as Function)();
    }
  }

  loadTexture(textureId: number, pngBuffer: ArrayBuffer): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeLoadTexture'] !== undefined) {
      (m['nativeLoadTexture'] as Function)(textureId, pngBuffer);
    }
  }

  unloadTexture(textureId: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeUnloadTexture'] !== undefined) {
      (m['nativeUnloadTexture'] as Function)(textureId);
    }
  }

  setCamera(x: number, y: number, zoom: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeSetCamera'] !== undefined) {
      (m['nativeSetCamera'] as Function)(x, y, zoom);
    }
  }

  touchInput(touchId: number, action: number, x: number, y: number): void {
    if (this.nativeModule === null) return;
    const m: Record<string, Function> = this.nativeModule as Record<string, Function>;
    if (m['nativeTouchInput'] !== undefined) {
      (m['nativeTouchInput'] as Function)(touchId, action, x, y);
    }
  }
}
