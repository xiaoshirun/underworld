interface NativeRendererModule {
  nativeInit(surfaceId: string, width: number, height: number): void;
  nativeDestroy(): void;
  nativeResize(width: number, height: number): void;
  nativeBeginFrame(): void;
  nativeSubmitCommands(cmds: object[]): void;
  nativeEndFrame(): void;
  nativeLoadTexture(textureId: number, pngBuffer: ArrayBuffer): void;
  nativeLoadTextureRaw(textureId: number, rgbaBuffer: ArrayBuffer, width: number, height: number): void;
  nativeUnloadTexture(textureId: number): void;
  nativeSetCamera(x: number, y: number, zoom: number): void;
  nativeGetCircleTextureId(): number;
  nativeGetWhiteTextureId(): number;
  nativeTouchInput(touchId: number, action: number, x: number, y: number): void;
  onSurfaceCreated(surfaceId: string, width: number, height: number): void;
  onSurfaceChanged(width: number, height: number): void;
  onSurfaceDestroyed(): void;
}

declare const nativeRendererModule: NativeRendererModule;
export default nativeRendererModule;
