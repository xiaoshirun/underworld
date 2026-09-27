import { display, router } from '@kit.ArkUI';

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
struct LoginPage {
  private bgCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private bgAnimId: number = -1;
  private bgParticles: BgParticle[] = [];
  private screenW: number = 360;
  private screenH: number = 780;
  @State username: string = '';
  @State password: string = '';
  @State errorMsg: string = '';
  @State isLoading: boolean = false;
  @State loginBtnScale: number = 1.0;

  aboutToAppear(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenW = px2vp(displayInfo.width);
      this.screenH = px2vp(displayInfo.height);
    } catch (e) {
      this.screenW = 360;
      this.screenH = 780;
    }
  }

  aboutToDisappear(): void {
    if (this.bgAnimId !== -1) {
      clearInterval(this.bgAnimId);
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
        Column() {
          Stack() {
            Circle()
              .width(80)
              .height(80)
              .fill('#0f172a')
              .opacity(0.6)

            Column() {
              Text('⛏')
                .fontSize(32)
                .fontColor('#fbbf24')

              Text('◆')
                .fontSize(10)
                .fontColor('#22d3ee')
                .margin({ top: -2 })
            }
          }
          .margin({ bottom: 16 })

          Text('地下世界探索')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#e2e8f0')
            .textShadow({ radius: 12, color: '#3b82f680', offsetX: 0, offsetY: 0 })
            .margin({ bottom: 4 })

          Text('Underworld Explorer')
            .fontSize(13)
            .fontColor('#64748b')
            .letterSpacing(2)
            .margin({ bottom: 36 })
        }
        .margin({ top: 60 })

        Column() {
          Text('账号登录')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#cbd5e1')
            .margin({ bottom: 20 })

          Column() {
            Text('用户名')
              .fontSize(12)
              .fontColor('#94a3b8')
              .margin({ bottom: 6 })

            TextInput({ text: this.username, placeholder: '请输入用户名' })
              .height(44)
              .fontSize(15)
              .fontColor('#e2e8f0')
              .placeholderColor('#475569')
              .backgroundColor('#1e293b')
              .borderRadius(10)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => {
                this.username = value;
              })
          }
          .margin({ bottom: 14 })

          Column() {
            Text('密码')
              .fontSize(12)
              .fontColor('#94a3b8')
              .margin({ bottom: 6 })

            TextInput({ text: this.password, placeholder: '请输入密码' })
              .type(InputType.Password)
              .height(44)
              .fontSize(15)
              .fontColor('#e2e8f0')
              .placeholderColor('#475569')
              .backgroundColor('#1e293b')
              .borderRadius(10)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => {
                this.password = value;
              })
          }
          .margin({ bottom: 6 })

          if (this.errorMsg.length > 0) {
            Text(this.errorMsg)
              .fontSize(12)
              .fontColor('#f87171')
              .margin({ top: 4, bottom: 4 })
              .textShadow({ radius: 6, color: '#ef444440', offsetX: 0, offsetY: 0 })
          }

          Button(this.isLoading ? '登录中...' : '登 录')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .backgroundColor('#3b82f6')
            .borderRadius(10)
            .margin({ top: 18 })
            .scale({ x: this.loginBtnScale, y: this.loginBtnScale })
            .shadow({ radius: 12, color: '#3b82f640', offsetX: 0, offsetY: 4 })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.loginBtnScale = 0.96;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.loginBtnScale = 1.0;
              }
            })
            .onClick(() => {
              this.handleLogin();
            })

          Row() {
            Divider().layoutWeight(1).color('#334155')
            Text('测试账号')
              .fontSize(11)
              .fontColor('#475569')
              .margin({ left: 10, right: 10 })
            Divider().layoutWeight(1).color('#334155')
          }
          .width('100%')
          .margin({ top: 18 })

          Row() {
            Text('test')
              .fontSize(13)
              .fontColor('#22d3ee')
              .fontWeight(FontWeight.Medium)
            Text(' / ')
              .fontSize(13)
              .fontColor('#475569')
            Text('test')
              .fontSize(13)
              .fontColor('#22d3ee')
              .fontWeight(FontWeight.Medium)
          }
          .margin({ top: 10 })
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .backgroundColor('#1e293b')
          .borderRadius(8)
        }
        .width('85%')
        .padding({ left: 22, right: 22, top: 22, bottom: 22 })
        .backgroundColor('#0f172af0')
        .borderRadius(18)
        .border({ width: 1, color: '#1e293b' })
        .shadow({ radius: 20, color: '#00000060', offsetX: 0, offsetY: 8 })

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
        .margin({ bottom: 20 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
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

  private handleLogin(): void {
    this.errorMsg = '';

    if (this.username.length === 0) {
      this.errorMsg = '请输入用户名';
      return;
    }
    if (this.password.length === 0) {
      this.errorMsg = '请输入密码';
      return;
    }

    if (this.username === 'test' && this.password === 'test') {
      this.isLoading = true;
      if (this.bgAnimId !== -1) {
        clearInterval(this.bgAnimId);
        this.bgAnimId = -1;
      }
      setTimeout(() => {
        this.isLoading = false;
        router.replaceUrl({
          url: 'pages/CharacterSelectPage',
          params: { username: this.username }
        });
      }, 600);
    } else {
      this.errorMsg = '用户名或密码错误';
    }
  }
}
