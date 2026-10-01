// entry/src/main/ets/native/DrawCmd.ets

export enum DrawType {
  SPRITE = 0,
  RECT = 1,
  TRIANGLE = 2,
}

export interface DrawCmd {
  type: number;
  textureId: number;
  x: number; y: number;
  width: number; height: number;
  rotation: number;
  srcX: number; srcY: number;
  srcW: number; srcH: number;
  texW: number; texH: number;
  r: number; g: number; b: number; a: number;
  flipX: number; flipY: number;
  layer: number;
  x2: number; y2: number;
  x3: number; y3: number;
}

export class DrawCmdBuffer {
  private cmds: DrawCmd[] = [];
  private circleTexId: number = 0;

  setCircleTextureId(texId: number): void {
    this.circleTexId = texId;
  }

  pushSprite(textureId: number, x: number, y: number,
             width: number, height: number,
             srcX: number, srcY: number, srcW: number, srcH: number,
             texW: number, texH: number,
             r: number, g: number, b: number, a: number,
             rotation: number, layer: number,
             flipX: number, flipY: number): void {
    this.cmds.push({
      type: DrawType.SPRITE,
      textureId, x, y, width, height,
      rotation, srcX, srcY, srcW, srcH,
      texW, texH,
      r, g, b, a, flipX, flipY, layer,
      x2: 0, y2: 0, x3: 0, y3: 0
    });
  }

  pushRect(x: number, y: number, width: number, height: number,
           r: number, g: number, b: number, a: number,
           rotation: number, layer: number): void {
    this.cmds.push({
      type: DrawType.RECT,
      textureId: 0,
      x, y, width, height,
      rotation,
      srcX: 0, srcY: 0, srcW: 0, srcH: 0,
      texW: 1, texH: 1,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer,
      x2: 0, y2: 0, x3: 0, y3: 0
    });
  }

  pushTriangle(x1: number, y1: number,
               x2: number, y2: number,
               x3: number, y3: number,
               r: number, g: number, b: number, a: number,
               layer: number): void {
    this.cmds.push({
      type: DrawType.TRIANGLE,
      textureId: 0,
      x: x1, y: y1,
      width: 0, height: 0,
      rotation: 0,
      srcX: 0, srcY: 0, srcW: 0, srcH: 0,
      texW: 1, texH: 1,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer,
      x2, y2, x3, y3
    });
  }

  pushCircle(cx: number, cy: number, radius: number,
             r: number, g: number, b: number, a: number,
             layer: number, textureId: number): void {
    this.cmds.push({
      type: DrawType.SPRITE,
      textureId: this.circleTexId,
      x: cx - radius, y: cy - radius,
      width: radius * 2, height: radius * 2,
      rotation: 0,
      srcX: 0, srcY: 0, srcW: 1, srcH: 1,
      texW: 1, texH: 1,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer,
      x2: 0, y2: 0, x3: 0, y3: 0
    });
  }

  pushLine(x1: number, y1: number, x2: number, y2: number,
           thickness: number,
           r: number, g: number, b: number, a: number,
           layer: number): void {
    const dx: number = x2 - x1;
    const dy: number = y2 - y1;
    const len: number = Math.sqrt(dx * dx + dy * dy);
    const angle: number = Math.atan2(dy, dx);
    const cx: number = (x1 + x2) / 2;
    const cy: number = (y1 + y2) / 2;
    this.cmds.push({
      type: DrawType.RECT,
      textureId: 0,
      x: cx - len / 2, y: cy - thickness / 2,
      width: len, height: thickness,
      rotation: angle,
      srcX: 0, srcY: 0, srcW: 0, srcH: 0,
      texW: 1, texH: 1,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer,
      x2: 0, y2: 0, x3: 0, y3: 0
    });
  }

  getCommands(): DrawCmd[] {
    return this.cmds;
  }

  clear(): void {
    this.cmds = [];
  }

  get length(): number {
    return this.cmds.length;
  }
}
