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
  r: number; g: number; b: number; a: number;
  flipX: number; flipY: number;
  layer: number;
}

export class DrawCmdBuffer {
  private cmds: DrawCmd[] = [];

  pushSprite(textureId: number, x: number, y: number,
             width: number, height: number,
             srcX: number, srcY: number, srcW: number, srcH: number,
             r: number, g: number, b: number, a: number,
             rotation: number, layer: number,
             flipX: number, flipY: number): void {
    this.cmds.push({
      type: DrawType.SPRITE,
      textureId, x, y, width, height,
      rotation, srcX, srcY, srcW, srcH,
      r, g, b, a, flipX, flipY, layer
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
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer
    });
  }

  pushTriangle(x1: number, y1: number,
               x2: number, y2: number,
               x3: number, y3: number,
               r: number, g: number, b: number, a: number,
               layer: number): void {
    // 三角形用包围盒 + 裁剪近似，或分解为 Rect 近似
    // 简化实现：用 3 个极细 Rect 画三角形边框
    // 完整实现需要 C++ 端支持真正的三角形渲染
    // 暂用 pushRect 近似
    const cx: number = (x1 + x2 + x3) / 3;
    const cy: number = (y1 + y2 + y3) / 3;
    const maxW: number = Math.max(Math.abs(x2 - x1), Math.abs(x3 - x1), 1);
    const maxH: number = Math.max(Math.abs(y2 - y1), Math.abs(y3 - y1), 1);
    this.cmds.push({
      type: DrawType.RECT,
      textureId: 0,
      x: cx - maxW / 2, y: cy - maxH / 2,
      width: maxW, height: maxH,
      rotation: 0,
      srcX: 0, srcY: 0, srcW: 0, srcH: 0,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer
    });
  }

  pushCircle(cx: number, cy: number, radius: number,
             r: number, g: number, b: number, a: number,
             layer: number, textureId: number): void {
    this.cmds.push({
      type: DrawType.SPRITE,
      textureId,
      x: cx - radius, y: cy - radius,
      width: radius * 2, height: radius * 2,
      rotation: 0,
      srcX: 0, srcY: 0, srcW: 1, srcH: 1,
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer
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
      r, g, b, a,
      flipX: 0, flipY: 0,
      layer
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
