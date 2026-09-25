import { display, router } from '@kit.ArkUI';
import { GameEngine } from '../game/GameEngine';
import {
  PLAYER_MAX_HP, JOYSTICK_RADIUS, MINIMAP_SIZE,
  COLOR_HP_FULL, COLOR_HP_EMPTY,
  COLOR_JOY_BASE, COLOR_JOY_KNOB,
  COLOR_BTN_JUMP, COLOR_BTN_ATTACK, COLOR_BTN_DASH,
  COLOR_XP_ORB, DASH_COOLDOWN
} from '../game/GameConstants';

@Entry
@Component
struct Index {
  private gameEngine: GameEngine = new GameEngine();
  private gameCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private minimapCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private gameCanvasReady: boolean = false;
  private minimapCanvasReady: boolean = false;
  @State screenW: number = 360;
  @State screenH: number = 780;
  @State playerHp: number = PLAYER_MAX_HP;
  @State playerXp: number = 0;
  @State playerLevel: number = 1;
  @State joyActive: boolean = false;
  @State joyKnobX: number = 0;
  @State joyKnobY: number = 0;
  @State joyCenterX: number = 0;
  @State joyCenterY: number = 0;
  @State showSettings: boolean = false;
  @State soundEnabled: boolean = true;
  @State effectsEnabled: boolean = true;
  @State username: string = 'test';
  @State engulfWarning: boolean = false;
  @State dashReady: boolean = true;

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
    this.gameEngine.destroy();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Canvas(this.gameCtx)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.gameCanvasReady = true;
          this.tryInitEngine();
        })

      this.MinimapView()

      this.TopBarView()

      this.JoystickView()

      this.ActionButtonsView()

      if (this.engulfWarning) {
        this.EngulfWarningView()
      }

      if (this.showSettings) {
        this.SettingsOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }

  @Builder
  MinimapView() {
    Stack() {
      Canvas(this.minimapCtx)
        .width(MINIMAP_SIZE)
        .height(MINIMAP_SIZE)
        .onReady(() => {
          this.minimapCanvasReady = true;
          this.tryInitEngine();
        })
    }
    .width(MINIMAP_SIZE + 6)
    .height(MINIMAP_SIZE + 6)
    .margin({ left: 10, top: 76 })
    .borderRadius(8)
    .border({ width: 1, color: '#334155' })
    .backgroundColor('#0a0a15')
    .shadow({ radius: 8, color: '#00000080', offsetX: 0, offsetY: 2 })
  }

  @Builder
  TopBarView() {
    Stack() {
      Column() {
        Row() {
          Text('Lv.' + this.playerLevel)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fbbf24')
            .margin({ right: 8 })

          Column() {
            for (let i = 0; i < 10; i++) {
              Row()
                .width(17)
                .height(8)
                .backgroundColor(i < this.playerHp ? COLOR_HP_FULL : COLOR_HP_EMPTY)
                .borderRadius(2)
                .margin({ left: i > 0 ? 1 : 0 })
                .opacity(i < this.playerHp ? 1.0 : 0.5)
            }
          }
          .height(12)
          .padding({ left: 3, right: 3, top: 2, bottom: 2 })
          .backgroundColor('#1f293780')
          .borderRadius(4)
        }

        Row() {
          Stack() {
            Row()
              .width(90)
              .height(5)
              .backgroundColor('#1e293b')
              .borderRadius(3)

            Row()
              .width(this.playerLevel > 0 ? 90 * (this.playerXp / this.gameEngine.getLevelUpXp()) : 0)
              .height(5)
              .backgroundColor(COLOR_XP_ORB)
              .borderRadius(3)
          }
          .width(90)
          .height(5)

          Text(this.playerXp + '/' + this.gameEngine.getLevelUpXp())
            .fontSize(10)
            .fontColor('#64748b')
            .margin({ left: 6 })
        }
        .margin({ top: 4 })
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    }
    .position({ x: this.screenW / 2 - 105, y: 10 })

    Stack() {
      Circle()
        .width(32)
        .height(32)
        .fill('#1e293b')
        .opacity(0.8)

      Text('⚙')
        .fontSize(16)
        .fontColor('#94a3b8')
    }
    .width(32)
    .height(32)
    .position({ x: this.screenW - 42, y: 12 })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.showSettings = true;
      }
    })
  }

  @Builder
  JoystickView() {
    Stack() {
      Circle()
        .width(JOYSTICK_RADIUS * 2)
        .height(JOYSTICK_RADIUS * 2)
        .fill(COLOR_JOY_BASE)
        .opacity(0.35)

      Circle()
        .width(JOYSTICK_RADIUS * 2 - 8)
        .height(JOYSTICK_RADIUS * 2 - 8)
        .fill('transparent')
        .border({ width: 1, color: '#47556940' })

      Circle()
        .width(42)
        .height(42)
        .fill(COLOR_JOY_KNOB)
        .opacity(0.85)
        .shadow({ radius: 6, color: '#00000060', offsetX: 0, offsetY: 2 })
        .translate({ x: this.joyKnobX, y: this.joyKnobY })
    }
    .width(JOYSTICK_RADIUS * 2)
    .height(JOYSTICK_RADIUS * 2)
    .position({ x: 20, y: this.screenH - JOYSTICK_RADIUS * 2 - 40 })
    .onTouch((event: TouchEvent) => {
      this.handleJoystickTouch(event);
    })
  }

  @Builder
  ActionButtonsView() {
    Column() {
      Row() {
        Stack() {
          Circle()
            .width(50)
            .height(50)
            .fill(COLOR_BTN_JUMP)
            .opacity(0.85)
            .shadow({ radius: 6, color: '#22c55e40', offsetX: 0, offsetY: 2 })

          Text('跳')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
        }
        .width(50)
        .height(50)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.gameEngine.setInputJump(true);
          }
        })

        Stack() {
          Circle()
            .width(50)
            .height(50)
            .fill(this.dashReady ? COLOR_BTN_DASH : '#1e3a5f')
            .opacity(this.dashReady ? 0.85 : 0.5)
            .shadow({ radius: 6, color: '#3b82f640', offsetX: 0, offsetY: 2 })

          Text('闪')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
        }
        .width(50)
        .height(50)
        .margin({ left: 12 })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down && this.dashReady) {
            this.gameEngine.setInputDash(true);
            this.dashReady = false;
            setTimeout(() => {
              this.dashReady = true;
            }, DASH_COOLDOWN);
          }
        })
      }

      Row() {
        Stack() {
          Circle()
            .width(62)
            .height(62)
            .fill(COLOR_BTN_ATTACK)
            .opacity(0.85)
            .shadow({ radius: 8, color: '#ef444450', offsetX: 0, offsetY: 3 })

          Circle()
            .width(54)
            .height(54)
            .fill('transparent')
            .border({ width: 1, color: '#ffffff20' })

          Text('攻击')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
        }
        .width(62)
        .height(62)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.gameEngine.setInputAttack(true);
          }
        })
      }
      .margin({ top: 10 })
    }
    .position({ x: this.screenW - 160, y: this.screenH - 200 })
  }

  @Builder
  EngulfWarningView() {
    Row() {
      Text('!')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#fbbf24')
        .margin({ right: 8 })

      Text('被吞噬！连续攻击挣脱！')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
    }
    .width('90%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor('#dc262690')
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
    .position({ x: this.screenW * 0.05, y: this.screenH / 2 - 20 })
    .shadow({ radius: 12, color: '#dc262660', offsetX: 0, offsetY: 0 })
  }

  @Builder
  SettingsOverlay() {
    Stack() {
      Column() {
        Row() {
          Text('设置')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor('#e2e8f0')

          Blank()

          Stack() {
            Circle()
              .width(28)
              .height(28)
              .fill('#1e293b')

            Text('✕')
              .fontSize(14)
              .fontColor('#94a3b8')
          }
          .width(28)
          .height(28)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.showSettings = false;
            }
          })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Column() {
          Row() {
            Text('音效')
              .fontSize(14)
              .fontColor('#e2e8f0')

            Blank()

            Toggle({ type: ToggleType.Switch, isOn: this.soundEnabled })
              .selectedColor('#3b82f6')
              .onChange((isOn: boolean) => {
                this.soundEnabled = isOn;
                this.gameEngine.setSettings({
                  soundEnabled: this.soundEnabled,
                  effectsEnabled: this.effectsEnabled
                });
              })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })

          Divider().color('#1e293b')

          Row() {
            Text('特效')
              .fontSize(14)
              .fontColor('#e2e8f0')

            Blank()

            Toggle({ type: ToggleType.Switch, isOn: this.effectsEnabled })
              .selectedColor('#3b82f6')
              .onChange((isOn: boolean) => {
                this.effectsEnabled = isOn;
                this.gameEngine.setSettings({
                  soundEnabled: this.soundEnabled,
                  effectsEnabled: this.effectsEnabled
                });
              })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
        }
        .padding({ left: 14, right: 14, top: 4, bottom: 4 })
        .backgroundColor('#1e293b40')
        .borderRadius(10)

        Column() {
          Row() {
            Text('用户')
              .fontSize(14)
              .fontColor('#94a3b8')

            Blank()

            Text(this.username)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#e2e8f0')
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
        }
        .padding({ left: 14, right: 14, top: 4, bottom: 4 })
        .backgroundColor('#1e293b40')
        .borderRadius(10)
        .margin({ top: 10 })

        Button('退出登录')
          .width('100%')
          .height(42)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#ffffff')
          .backgroundColor('#dc2626')
          .borderRadius(10)
          .margin({ top: 18 })
          .shadow({ radius: 8, color: '#dc262640', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.gameEngine.destroy();
            router.replaceUrl({ url: 'pages/LoginPage' });
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
        .margin({ bottom: 8 })
      }
      .width('82%')
      .padding(20)
      .backgroundColor('#0f172af5')
      .borderRadius(18)
      .border({ width: 1, color: '#1e293b' })
      .shadow({ radius: 24, color: '#000000a0', offsetX: 0, offsetY: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000b0')
  }

  private tryInitEngine(): void {
    if (this.gameCanvasReady && this.minimapCanvasReady) {
      this.gameEngine.init(this.gameCtx, this.minimapCtx, this.screenW, this.screenH);
      this.gameEngine.setSettings({
        soundEnabled: this.soundEnabled,
        effectsEnabled: this.effectsEnabled
      });
      this.startStatusMonitor();
    }
  }

  private handleJoystickTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      const touch = event.touches[0];
      this.joyCenterX = touch.x;
      this.joyCenterY = touch.y;
      this.joyActive = true;
      this.joyKnobX = 0;
      this.joyKnobY = 0;
      this.gameEngine.setInputJoy(true, 0, 0);
    } else if (event.type === TouchType.Move && this.joyActive) {
      const touch = event.touches[0];
      let dx: number = touch.x - this.joyCenterX;
      let dy: number = touch.y - this.joyCenterY;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist > JOYSTICK_RADIUS) {
        dx = (dx / dist) * JOYSTICK_RADIUS;
        dy = (dy / dist) * JOYSTICK_RADIUS;
      }
      this.joyKnobX = dx;
      this.joyKnobY = dy;
      this.gameEngine.setInputJoy(true, dx / JOYSTICK_RADIUS, dy / JOYSTICK_RADIUS);
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.joyActive = false;
      this.joyKnobX = 0;
      this.joyKnobY = 0;
      this.gameEngine.setInputJoy(false, 0, 0);
    }
  }

  private startStatusMonitor(): void {
    setInterval(() => {
      const hp: number = this.gameEngine.getPlayerHp();
      if (hp !== this.playerHp) {
        this.playerHp = hp;
      }
      const xp: number = this.gameEngine.getPlayerXp();
      if (xp !== this.playerXp) {
        this.playerXp = xp;
      }
      const level: number = this.gameEngine.getPlayerLevel();
      if (level !== this.playerLevel) {
        this.playerLevel = level;
      }
    }, 100);
  }
}
