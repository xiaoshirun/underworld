import { display, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { SaveManager } from '../game/SaveManager';

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
  private bgAnimId: number = -1;
  private bgParticles: BgParticle[] = [];
  private screenW: number = 360;
  private screenH: number = 780;
  @State username: string = '';
  @State hasSave: boolean = false;
  @State newGameScale: number = 1.0;
  @State continueScale: number = 1.0;
  @State isLandscape: boolean = false;

  aboutToAppear(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      const rawW: number = px2vp(displayInfo.width);
      const rawH: number = px2vp(displayInfo.height);
      if (rawW > rawH) {
        this.screenW = rawW;
        this.screenH = rawH;
        this.isLandscape = true;
      } else {
        this.screenW = rawH;
        this.screenH = rawW;
        this.isLandscape = false;
      }
      const params = router.getParams();
      if (params !== null && params !== undefined) {
        const p = params as Record<string, Object>;
        if (p['username'] !== undefined) {
          this.username = p['username'] as string;
        }
      }
      const harmonyCtx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      SaveManager.load(harmonyCtx).then((data: Object | null) => {
        this.hasSave = data !== null;
      });
    } catch (e) {
      this.screenW = 780;
      this.screenH = 360;
      this.isLandscape = true;
    }
  }

  aboutToDisappear(): void {
    if (this.bgAnimId !== -1) {
      clearInterval(this.bgAnimId);
    }
  }

  @Builder
  FooterView() {
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

      if (this.isLandscape) {
        Row() {
          Column() {
            Text('深渊史莱姆')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#e2e8f0')
              .textShadow({ radius: 12, color: '#22d3ee80', offsetX: 0, offsetY: 0 })
              .margin({ bottom: 6 })

            Text('吞噬 · 进化 · 拟人')
              .fontSize(12)
              .fontColor('#64748b')
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(3)
          .height('100%')
          .padding({ top: 40 })

          Column() {
            Button('新游戏')
              .width(200)
              .height(48)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff')
              .backgroundColor('#3b82f6')
              .borderRadius(10)
              .margin({ bottom: 16 })
              .scale({ x: this.newGameScale, y: this.newGameScale })
              .shadow({ radius: 12, color: '#3b82f640', offsetX: 0, offsetY: 4 })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.newGameScale = 0.96;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.newGameScale = 1.0;
                }
              })
              .onClick(() => {
                this.startNewGame();
              })

            if (this.hasSave) {
              Button('继续游戏')
                .width(200)
                .height(48)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ffffff')
                .backgroundColor('#22c55e')
                .borderRadius(10)
                .margin({ bottom: 16 })
                .scale({ x: this.continueScale, y: this.continueScale })
                .shadow({ radius: 12, color: '#22c55e40', offsetX: 0, offsetY: 4 })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.continueScale = 0.96;
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.continueScale = 1.0;
                  }
                })
                .onClick(() => {
                  this.continueGame();
                })
            }
          }
          .layoutWeight(7)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 20 })
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Top)
      } else {
        Column() {
          Text('深渊史莱姆')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#e2e8f0')
            .textShadow({ radius: 12, color: '#22d3ee80', offsetX: 0, offsetY: 0 })
            .margin({ bottom: 6 })

          Text('吞噬 · 进化 · 拟人')
            .fontSize(13)
            .fontColor('#64748b')
            .margin({ bottom: 48 })

          Button('新游戏')
            .width(200)
            .height(48)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .backgroundColor('#3b82f6')
            .borderRadius(10)
            .margin({ bottom: 16 })
            .scale({ x: this.newGameScale, y: this.newGameScale })
            .shadow({ radius: 12, color: '#3b82f640', offsetX: 0, offsetY: 4 })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.newGameScale = 0.96;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.newGameScale = 1.0;
              }
            })
            .onClick(() => {
              this.startNewGame();
            })

          if (this.hasSave) {
            Button('继续游戏')
              .width(200)
              .height(48)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff')
              .backgroundColor('#22c55e')
              .borderRadius(10)
              .margin({ bottom: 16 })
              .scale({ x: this.continueScale, y: this.continueScale })
              .shadow({ radius: 12, color: '#22c55e40', offsetX: 0, offsetY: 4 })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.continueScale = 0.96;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.continueScale = 1.0;
                }
              })
              .onClick(() => {
                this.continueGame();
              })
          }

          Blank()

          Column() {
            this.FooterView()
          }
          .margin({ bottom: 20 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 80 })
      }
    }
    .width('100%')
    .height('100%')
  }

  private startNewGame(): void {
    if (this.bgAnimId !== -1) {
      clearInterval(this.bgAnimId);
      this.bgAnimId = -1;
    }
    router.replaceUrl({
      url: 'pages/Index',
      params: {
        username: this.username,
        isNewGame: true
      }
    });
  }

  private continueGame(): void {
    if (this.bgAnimId !== -1) {
      clearInterval(this.bgAnimId);
      this.bgAnimId = -1;
    }
    router.replaceUrl({
      url: 'pages/Index',
      params: {
        username: this.username,
        isNewGame: false
      }
    });
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
}
