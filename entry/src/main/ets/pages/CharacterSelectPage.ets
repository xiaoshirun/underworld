import { display, router } from '@kit.ArkUI';
import { GenderType } from '../game/GameConstants';

interface BgParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  alpha: number;
  color: string;
}

@Entry
@Component
struct CharacterSelectPage {
  private bgCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private maleCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private femaleCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private bgAnimId: number = -1;
  private charAnimId: number = -1;
  private bgParticles: BgParticle[] = [];
  private screenW: number = 360;
  private screenH: number = 780;
  private animFrame: number = 0;
  @State username: string = '';
  @State selectedGender: GenderType = -1;
  @State confirmBtnScale: number = 1.0;

  aboutToAppear(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenW = px2vp(displayInfo.width);
      this.screenH = px2vp(displayInfo.height);
      const params = router.getParams();
      if (params !== null && params !== undefined) {
        const p = params as Record<string, Object>;
        if (p['username'] !== undefined) {
          this.username = p['username'] as string;
        }
      }
    } catch (e) {
      this.screenW = 360;
      this.screenH = 780;
    }
  }

  aboutToDisappear(): void {
    if (this.bgAnimId !== -1) {
      clearInterval(this.bgAnimId);
    }
    if (this.charAnimId !== -1) {
      clearInterval(this.charAnimId);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Canvas(this.bgCtx)
        .width('100%')
        .height('100%')
        .backgroundColor('#08080f')
        .onReady(() => {
          this.initBgParticles();
          this.startBgAnimation();
        })

      Column() {
        Text('选择角色')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#e2e8f0')
          .textShadow({ radius: 12, color: '#3b82f680', offsetX: 0, offsetY: 0 })
          .margin({ bottom: 6 })

        Text('选择你的冒险者')
          .fontSize(13)
          .fontColor('#64748b')
          .margin({ bottom: 32 })

        Row() {
          // Male character card
          Column() {
            Stack() {
              Canvas(this.maleCtx)
                .width(120)
                .height(160)
                .onReady(() => {
                  this.startCharAnimation();
                })

              if (this.selectedGender === GenderType.MALE) {
                Column()
                  .width(120)
                  .height(160)
                  .borderRadius(12)
                  .border({ width: 2, color: '#3b82f6' })
                  .shadow({ radius: 16, color: '#3b82f660', offsetX: 0, offsetY: 0 })
              }
            }

            Text('男性')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.selectedGender === GenderType.MALE ? '#3b82f6' : '#94a3b8')
              .margin({ top: 10 })

            Text('坚韧的探索者')
              .fontSize(11)
              .fontColor('#475569')
              .margin({ top: 2 })
          }
          .width(140)
          .padding({ top: 16, bottom: 16, left: 10, right: 10 })
          .backgroundColor('#0f172af0')
          .borderRadius(14)
          .border({ width: 1, color: this.selectedGender === GenderType.MALE ? '#3b82f640' : '#1e293b' })
          .shadow({ radius: 12, color: '#00000040', offsetX: 0, offsetY: 4 })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.selectedGender = GenderType.MALE;
            }
          })

          // Female character card
          Column() {
            Stack() {
              Canvas(this.femaleCtx)
                .width(120)
                .height(160)

              if (this.selectedGender === GenderType.FEMALE) {
                Column()
                  .width(120)
                  .height(160)
                  .borderRadius(12)
                  .border({ width: 2, color: '#8b5cf6' })
                  .shadow({ radius: 16, color: '#8b5cf660', offsetX: 0, offsetY: 0 })
              }
            }

            Text('女性')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.selectedGender === GenderType.FEMALE ? '#8b5cf6' : '#94a3b8')
              .margin({ top: 10 })

            Text('敏捷的冒险者')
              .fontSize(11)
              .fontColor('#475569')
              .margin({ top: 2 })
          }
          .width(140)
          .padding({ top: 16, bottom: 16, left: 10, right: 10 })
          .backgroundColor('#0f172af0')
          .borderRadius(14)
          .border({ width: 1, color: this.selectedGender === GenderType.FEMALE ? '#8b5cf640' : '#1e293b' })
          .shadow({ radius: 12, color: '#00000040', offsetX: 0, offsetY: 4 })
          .margin({ left: 16 })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.selectedGender = GenderType.FEMALE;
            }
          })
        }

        Button('确认选择')
          .width(200)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor(this.selectedGender >= 0 ? '#3b82f6' : '#1e293b')
          .borderRadius(10)
          .margin({ top: 36 })
          .scale({ x: this.confirmBtnScale, y: this.confirmBtnScale })
          .shadow(this.selectedGender >= 0 ?
            { radius: 12, color: '#3b82f640', offsetX: 0, offsetY: 4 } :
            { radius: 0, color: '#00000000', offsetX: 0, offsetY: 0 })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.confirmBtnScale = 0.96;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.confirmBtnScale = 1.0;
            }
          })
          .onClick(() => {
            if (this.selectedGender >= 0) {
              this.confirmSelection();
            }
          })

        Blank()

        Column() {
          Text('ICP备案号: 示例ICP备xxxxxxxx号')
            .fontSize(11)
            .fontColor('#374151')
          Text('v1.0.0')
            .fontSize(10)
            .fontColor('#1e293b')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 60 })
    }
    .width('100%')
    .height('100%')
  }

  private initBgParticles(): void {
    this.bgParticles = [];
    const colors: string[] = ['#22d3ee', '#3b82f6', '#8b5cf6', '#fbbf24', '#22d3ee'];
    for (let i: number = 0; i < 40; i++) {
      this.bgParticles.push({
        x: Math.random() * this.screenW,
        y: Math.random() * this.screenH,
        vx: (Math.random() - 0.5) * 0.3,
        vy: -0.2 - Math.random() * 0.4,
        size: 1 + Math.random() * 2.5,
        alpha: 0.1 + Math.random() * 0.3,
        color: colors[Math.floor(Math.random() * colors.length)]
      });
    }
  }

  private startBgAnimation(): void {
    this.bgAnimId = setInterval(() => {
      if (this.bgCtx === null) return;
      const c: CanvasRenderingContext2D = this.bgCtx;
      c.clearRect(0, 0, this.screenW, this.screenH);

      c.fillStyle = '#08080f';
      c.fillRect(0, 0, this.screenW, this.screenH);

      const grd = c.createRadialGradient(
        this.screenW / 2, this.screenH * 0.35, 10,
        this.screenW / 2, this.screenH * 0.35, this.screenW * 0.6
      );
      grd.addColorStop(0, '#1e3a5f18');
      grd.addColorStop(1, '#08080f00');
      c.fillStyle = grd;
      c.fillRect(0, 0, this.screenW, this.screenH);

      for (let i: number = 0; i < this.bgParticles.length; i++) {
        const p: BgParticle = this.bgParticles[i];
        p.x += p.vx;
        p.y += p.vy;

        if (p.y < -10) {
          p.y = this.screenH + 10;
          p.x = Math.random() * this.screenW;
        }
        if (p.x < -10) p.x = this.screenW + 10;
        if (p.x > this.screenW + 10) p.x = -10;

        c.globalAlpha = p.alpha;
        c.fillStyle = p.color;
        c.beginPath();
        c.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        c.fill();

        c.globalAlpha = p.alpha * 0.3;
        c.beginPath();
        c.arc(p.x, p.y, p.size * 3, 0, Math.PI * 2);
        c.fill();
      }
      c.globalAlpha = 1.0;
    }, 33);
  }

  private startCharAnimation(): void {
    this.charAnimId = setInterval(() => {
      this.animFrame++;
      this.drawMaleCharacter();
      this.drawFemaleCharacter();
    }, 50);
  }

  private drawMaleCharacter(): void {
    if (this.maleCtx === null) return;
    const c: CanvasRenderingContext2D = this.maleCtx;
    const w: number = 120;
    const h: number = 160;
    c.clearRect(0, 0, w, h);

    // Background glow
    const isSelected: boolean = this.selectedGender === GenderType.MALE;
    if (isSelected) {
      const grd = c.createRadialGradient(w / 2, h / 2, 5, w / 2, h / 2, 50);
      grd.addColorStop(0, '#3b82f620');
      grd.addColorStop(1, '#3b82f600');
      c.fillStyle = grd;
      c.fillRect(0, 0, w, h);
    }

    const bounce: number = Math.sin(this.animFrame * 0.08) * 2;
    const cx: number = w / 2;
    const baseY: number = h / 2 + 10 + bounce;

    // Shadow
    c.fillStyle = '#00000040';
    c.beginPath();
    c.ellipse(cx, baseY + 36, 18, 5, 0, 0, Math.PI * 2);
    c.fill();

    // Legs
    c.fillStyle = '#1e3a5f';
    c.fillRect(cx - 8, baseY + 16, 6, 18);
    c.fillRect(cx + 2, baseY + 16, 6, 18);

    // Boots
    c.fillStyle = '#4a3728';
    c.fillRect(cx - 9, baseY + 30, 8, 5);
    c.fillRect(cx + 1, baseY + 30, 8, 5);

    // Body (broader shoulders)
    c.fillStyle = '#3b82f6';
    c.fillRect(cx - 12, baseY - 4, 24, 22);

    // Body shading
    c.fillStyle = '#2563eb';
    c.fillRect(cx - 12, baseY - 4, 4, 22);
    c.fillRect(cx + 8, baseY - 4, 4, 22);

    // Belt
    c.fillStyle = '#92400e';
    c.fillRect(cx - 12, baseY + 14, 24, 3);
    c.fillStyle = '#fbbf24';
    c.fillRect(cx - 2, baseY + 14, 4, 3);

    // Arms
    c.fillStyle = '#3b82f6';
    c.fillRect(cx - 16, baseY - 2, 5, 16);
    c.fillRect(cx + 11, baseY - 2, 5, 16);

    // Hands
    c.fillStyle = '#f5c8a0';
    c.fillRect(cx - 16, baseY + 12, 5, 4);
    c.fillRect(cx + 11, baseY + 12, 5, 4);

    // Head
    c.fillStyle = '#f5c8a0';
    c.beginPath();
    c.arc(cx, baseY - 14, 11, 0, Math.PI * 2);
    c.fill();

    // Hair (short, brown)
    c.fillStyle = '#6b3a1a';
    c.beginPath();
    c.arc(cx, baseY - 18, 11, Math.PI, Math.PI * 2);
    c.fill();
    c.fillRect(cx - 11, baseY - 20, 22, 5);

    // Eyes
    c.fillStyle = '#ffffff';
    c.fillRect(cx - 6, baseY - 16, 4, 4);
    c.fillRect(cx + 2, baseY - 16, 4, 4);
    c.fillStyle = '#1a1a2e';
    c.fillRect(cx - 5, baseY - 15, 2, 3);
    c.fillRect(cx + 3, baseY - 15, 2, 3);

    // Mouth
    c.fillStyle = '#c9826b';
    c.fillRect(cx - 2, baseY - 8, 4, 1);

    // Weapon (drill) in right hand
    c.fillStyle = '#9ca3af';
    c.fillRect(cx + 14, baseY + 2, 3, 14);
    c.fillStyle = '#fbbf24';
    c.beginPath();
    c.moveTo(cx + 15.5, baseY + 16);
    c.lineTo(cx + 12, baseY + 24);
    c.lineTo(cx + 19, baseY + 24);
    c.closePath();
    c.fill();
  }

  private drawFemaleCharacter(): void {
    if (this.femaleCtx === null) return;
    const c: CanvasRenderingContext2D = this.femaleCtx;
    const w: number = 120;
    const h: number = 160;
    c.clearRect(0, 0, w, h);

    // Background glow
    const isSelected: boolean = this.selectedGender === GenderType.FEMALE;
    if (isSelected) {
      const grd = c.createRadialGradient(w / 2, h / 2, 5, w / 2, h / 2, 50);
      grd.addColorStop(0, '#8b5cf620');
      grd.addColorStop(1, '#8b5cf600');
      c.fillStyle = grd;
      c.fillRect(0, 0, w, h);
    }

    const bounce: number = Math.sin(this.animFrame * 0.08 + 1) * 2;
    const cx: number = w / 2;
    const baseY: number = h / 2 + 10 + bounce;

    // Shadow
    c.fillStyle = '#00000040';
    c.beginPath();
    c.ellipse(cx, baseY + 36, 16, 5, 0, 0, Math.PI * 2);
    c.fill();

    // Legs (slimmer)
    c.fillStyle = '#2e1065';
    c.fillRect(cx - 6, baseY + 16, 5, 18);
    c.fillRect(cx + 1, baseY + 16, 5, 18);

    // Boots
    c.fillStyle = '#4a3728';
    c.fillRect(cx - 7, baseY + 30, 7, 5);
    c.fillRect(cx, baseY + 30, 7, 5);

    // Body (narrower)
    c.fillStyle = '#8b5cf6';
    c.fillRect(cx - 10, baseY - 4, 20, 22);

    // Body shading
    c.fillStyle = '#7c3aed';
    c.fillRect(cx - 10, baseY - 4, 3, 22);
    c.fillRect(cx + 7, baseY - 4, 3, 22);

    // Belt
    c.fillStyle = '#581c87';
    c.fillRect(cx - 10, baseY + 14, 20, 3);
    c.fillStyle = '#c084fc';
    c.fillRect(cx - 2, baseY + 14, 4, 3);

    // Arms (slimmer)
    c.fillStyle = '#8b5cf6';
    c.fillRect(cx - 14, baseY - 2, 4, 14);
    c.fillRect(cx + 10, baseY - 2, 4, 14);

    // Hands
    c.fillStyle = '#f5c8a0';
    c.fillRect(cx - 14, baseY + 10, 4, 4);
    c.fillRect(cx + 10, baseY + 10, 4, 4);

    // Head
    c.fillStyle = '#f5c8a0';
    c.beginPath();
    c.arc(cx, baseY - 14, 10, 0, Math.PI * 2);
    c.fill();

    // Hair (long, purple, flowing)
    c.fillStyle = '#4a1a6b';
    c.beginPath();
    c.arc(cx, baseY - 18, 11, Math.PI, Math.PI * 2);
    c.fill();
    c.fillRect(cx - 11, baseY - 20, 22, 5);

    // Long flowing hair sides
    c.fillStyle = '#4a1a6b';
    c.fillRect(cx - 12, baseY - 18, 4, 22);
    c.fillRect(cx + 8, baseY - 18, 4, 22);

    // Hair tips with wave
    const hairWave: number = Math.sin(this.animFrame * 0.06) * 1.5;
    c.fillRect(cx - 13 + hairWave, baseY + 2, 4, 6);
    c.fillRect(cx + 9 - hairWave, baseY + 2, 4, 6);

    // Eyes (slightly larger)
    c.fillStyle = '#ffffff';
    c.fillRect(cx - 6, baseY - 16, 4, 4);
    c.fillRect(cx + 2, baseY - 16, 4, 4);
    c.fillStyle = '#6d28d9';
    c.fillRect(cx - 5, baseY - 15, 2, 3);
    c.fillRect(cx + 3, baseY - 15, 2, 3);

    // Eyelashes
    c.fillStyle = '#4a1a6b';
    c.fillRect(cx - 7, baseY - 17, 1, 1);
    c.fillRect(cx + 6, baseY - 17, 1, 1);

    // Mouth
    c.fillStyle = '#e88b9c';
    c.fillRect(cx - 2, baseY - 8, 4, 1);

    // Weapon (staff) in right hand
    c.fillStyle = '#7c3aed';
    c.fillRect(cx + 12, baseY - 6, 3, 22);
    c.fillStyle = '#c084fc';
    c.beginPath();
    c.arc(cx + 13.5, baseY - 8, 4, 0, Math.PI * 2);
    c.fill();

    // Staff glow
    c.globalAlpha = 0.3 + Math.sin(this.animFrame * 0.1) * 0.15;
    c.fillStyle = '#c084fc';
    c.beginPath();
    c.arc(cx + 13.5, baseY - 8, 7, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 1.0;
  }

  private confirmSelection(): void {
    if (this.bgAnimId !== -1) {
      clearInterval(this.bgAnimId);
      this.bgAnimId = -1;
    }
    if (this.charAnimId !== -1) {
      clearInterval(this.charAnimId);
      this.charAnimId = -1;
    }
    router.replaceUrl({
      url: 'pages/Index',
      params: {
        username: this.username,
        gender: this.selectedGender
      }
    });
  }
}
