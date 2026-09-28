import { display, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { GameEngine } from '../game/GameEngine';
import { SaveManager } from '../game/SaveManager';
import { Engine, SceneDefinition } from '../engine/core/Engine';
import { GameScene } from '../game/GameScene';
import { MainMenuScene } from '../game/MainMenuScene';
import { Scene } from '../engine/scene/Scene';
import {
  PLAYER_MAX_HP, JOYSTICK_RADIUS, MINIMAP_SIZE,
  COLOR_HP_FULL, COLOR_HP_EMPTY,
  COLOR_JOY_BASE, COLOR_JOY_KNOB,
  COLOR_BTN_JUMP, COLOR_BTN_ATTACK, COLOR_BTN_DASH, COLOR_TOOL_BTN,
  COLOR_XP_ORB, DASH_COOLDOWN, GenderType, WeaponForm,
  EvolutionBranch, FORM_UNLOCK_COST, Inventory,
  TransformForm, TRANSFORM_MAX_ENERGY,
  COLOR_TRANSFORM_BTN_LOCKED, COLOR_TRANSFORM_BTN_READY, COLOR_TRANSFORM_ENERGY_BG,
  COLOR_TRANSFORM_SLIME, COLOR_TRANSFORM_GHOST, COLOR_TRANSFORM_ARMOR, COLOR_TRANSFORM_IRON_GOLD,
  GameState, SaveData
} from '../game/GameConstants';

@Entry
@Component
struct Index {
  private gameEngine: GameEngine = new GameEngine();
  private engine: Engine | null = null;
  private gameScene: GameScene | null = null;
  private gameCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private minimapCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private cacheCtx0: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private cacheCtx1: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private cacheCtx2: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private cacheCtx3: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private cacheCtx4: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private cacheCtx5: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private gameCanvasReady: boolean = false;
  private minimapCanvasReady: boolean = false;
  private cacheCanvasesReady: number = 0;
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
  @State playerGender: GenderType = GenderType.MALE;
  @State currentWeaponForm: WeaponForm = WeaponForm.BLADE;
  @State toolReady: boolean = true;
  @State showEvolution: boolean = false;
  @State evoBranch: number = 0;
  @State evoLevel: number = 0;
  @State evoOreHave: number = 0;
  @State evoOreNeed: number = 0;
  @State evoNormalHave: number = 0;
  @State evoNormalNeed: number = 0;
  @State evoRareHave: number = 0;
  @State evoRareNeed: number = 0;
  @State evoFormCore: number = 0;
  @State evoMaxLevel: boolean = false;
  @State lockedForms: number[] = [1, 2, 3, 4, 5];
  @State invOre: number = 0;
  @State invNormal: number = 0;
  @State invRare: number = 0;
  @State invFormCore: number = 0;
  @State isTransformed: boolean = false;
  @State transformEnergy: number = TRANSFORM_MAX_ENERGY;
  @State transformMaxEnergy: number = TRANSFORM_MAX_ENERGY;
  @State transformForm: TransformForm = TransformForm.NONE;
  @State transformCooldown: number = 0;
  @State unlockedTransforms: number[] = [];
  @State showFormSelect: boolean = false;
  @State transformUnlockForm: TransformForm = TransformForm.NONE;
  @State transformUnlockActive: boolean = false;
  @State gameState: GameState = GameState.PLAYING;
  @State showPauseMenu: boolean = false;
  @State showGameOver: boolean = false;
  @State showSaveIndicator: boolean = false;
  @State deathLevel: number = 1;
  @State deathChunks: number = 0;
  private branchNames: string[] = ['Crystal', 'Flame', 'Shadow', 'Toxin', 'Tide'];

  aboutToAppear(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      // Ensure landscape: width > height
      const rawW: number = px2vp(displayInfo.width);
      const rawH: number = px2vp(displayInfo.height);
      if (rawW > rawH) {
        this.screenW = rawW;
        this.screenH = rawH;
      } else {
        this.screenW = rawH;
        this.screenH = rawW;
      }
      const params = router.getParams();
      if (params !== null && params !== undefined) {
        const p = params as Record<string, Object>;
        if (p['username'] !== undefined) {
          this.username = p['username'] as string;
        }
        if (p['gender'] !== undefined) {
          this.playerGender = p['gender'] as GenderType;
        }
      }
    } catch (e) {
      this.screenW = 780;
      this.screenH = 360;
    }
  }

  aboutToDisappear(): void {
    if (this.engine) {
      this.engine.stop();
    }
    this.gameEngine.destroy();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Canvas(this.cacheCtx0)
        .width(1056)
        .height(1056)
        .onReady(() => { this.cacheCanvasesReady++; this.tryInitEngine(); })
      Canvas(this.cacheCtx1)
        .width(1056)
        .height(1056)
        .onReady(() => { this.cacheCanvasesReady++; this.tryInitEngine(); })
      Canvas(this.cacheCtx2)
        .width(1056)
        .height(1056)
        .onReady(() => { this.cacheCanvasesReady++; this.tryInitEngine(); })
      Canvas(this.cacheCtx3)
        .width(1056)
        .height(1056)
        .onReady(() => { this.cacheCanvasesReady++; this.tryInitEngine(); })
      Canvas(this.cacheCtx4)
        .width(1056)
        .height(1056)
        .onReady(() => { this.cacheCanvasesReady++; this.tryInitEngine(); })
      Canvas(this.cacheCtx5)
        .width(1056)
        .height(1056)
        .onReady(() => { this.cacheCanvasesReady++; this.tryInitEngine(); })

      Canvas(this.gameCtx)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.gameCanvasReady = true;
          this.tryInitEngine();
        })

      this.MinimapView()

      this.WeaponFormView()

      this.InventoryBarView()

      this.TopBarView()

      this.JoystickView()

      this.ActionButtonsView()

      if (this.engulfWarning) {
        this.EngulfWarningView()
      }

      if (this.showSettings) {
        this.SettingsOverlay()
      }

      if (this.showEvolution) {
        this.EvolutionOverlay()
      }

      this.TransformButtonView()
      this.TransformEnergyBarView()
      this.FormSelectPanel()
      this.TransformUnlockNotification()

      if (this.showPauseMenu) {
        this.PauseMenuOverlay()
      }

      if (this.showGameOver) {
        this.GameOverOverlay()
      }

      if (this.showSaveIndicator) {
        this.SaveIndicator()
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
    .margin({ left: 8, top: 46 })
    .borderRadius(4)
    .border({ width: 3, color: '#475569' })
    .backgroundColor('#0a0a15')
  }

  @Builder
  WeaponFormView() {
    Stack() {
      Column() {
        Text(this.gameEngine.getWeaponFormName(this.currentWeaponForm))
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#fbbf24')
      }
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor('#0f0f23e0')
      .borderRadius(3)
      .border({ width: 2, color: '#475569' })
    }
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.gameEngine.cycleWeaponForm();
        this.currentWeaponForm = this.gameEngine.getCurrentWeaponForm();
      }
    })
    .position({ x: 10, y: this.screenH - 100 })
  }

  @Builder
  InventoryBarView() {
    Row() {
      Row() {
        Text('◆')
          .fontSize(10)
          .fontColor('#00ced1')
        Text(this.invOre.toString())
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#e2e8f0')
          .margin({ left: 3 })
      }
      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
      .backgroundColor('#0f0f23c0')
      .borderRadius(2)
      .border({ width: 1, color: '#00ced140' })
      .margin({ right: 4 })

      Row() {
        Text('●')
          .fontSize(10)
          .fontColor('#a78bfa')
        Text(this.invNormal.toString())
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#e2e8f0')
          .margin({ left: 3 })
      }
      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
      .backgroundColor('#0f0f23c0')
      .borderRadius(2)
      .border({ width: 1, color: '#a78bfa40' })
      .margin({ right: 4 })

      Row() {
        Text('★')
          .fontSize(10)
          .fontColor('#fbbf24')
        Text(this.invRare.toString())
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#e2e8f0')
          .margin({ left: 3 })
      }
      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
      .backgroundColor('#0f0f23c0')
      .borderRadius(2)
      .border({ width: 1, color: '#fbbf2440' })
      .margin({ right: 4 })

      Row() {
        Text('◈')
          .fontSize(10)
          .fontColor('#f472b6')
        Text(this.invFormCore.toString())
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#e2e8f0')
          .margin({ left: 3 })
      }
      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
      .backgroundColor('#0f0f23c0')
      .borderRadius(2)
      .border({ width: 1, color: '#f472b640' })
    }
    .padding({ left: 4, right: 4, top: 3, bottom: 3 })
    .backgroundColor('#0a0a15d0')
    .borderRadius(3)
    .border({ width: 2, color: '#334155' })
    .position({ x: 10, y: this.screenH - 72 })
  }

  @Builder
  TopBarView() {
    Stack() {
      Column() {
        Row() {
          Stack() {
            Column()
              .width(32)
              .height(20)
              .backgroundColor('#4c1d95')
              .borderRadius(3)
              .border({ width: 1, color: '#7c3aed' })

            Text(this.playerLevel.toString())
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#fbbf24')
          }
          .width(32)
          .height(20)
          .margin({ right: 6 })

          Row() {
            ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], (i: number) => {
              Text(i < this.playerHp ? '♥' : '♡')
                .fontSize(14)
                .fontColor(i < this.playerHp ? '#ef4444' : '#374151')
                .margin({ left: i > 0 ? 1 : 0 })
            })
          }
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .backgroundColor('#0f0f23d0')
          .borderRadius(3)
          .border({ width: 2, color: '#334155' })
        }

        Row() {
          Stack() {
            Row()
              .width(80)
              .height(5)
              .backgroundColor('#0f0f23')
              .borderRadius(2)
              .border({ width: 1, color: '#1e293b' })

            Row()
              .width(this.playerLevel > 0 ? 80 * (this.playerXp / this.gameEngine.getLevelUpXp()) : 0)
              .height(5)
              .backgroundColor('#fbbf24')
              .borderRadius(2)
          }
          .width(80)
          .height(5)

          Text(this.playerXp + '/' + this.gameEngine.getLevelUpXp())
            .fontSize(9)
            .fontColor('#94a3b8')
            .margin({ left: 4 })
        }
        .margin({ top: 4 })
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor('#0a0a15d0')
      .borderRadius(4)
      .border({ width: 2, color: '#334155' })
    }
    .position({ x: this.screenW / 2 - 100, y: 8 })

    // Pause button
    Stack() {
      Column()
        .width(30)
        .height(30)
        .backgroundColor('#0f0f23e0')
        .borderRadius(3)
        .border({ width: 2, color: '#f59e0b' })

      Text('⏸')
        .fontSize(15)
        .fontColor('#fbbf24')
    }
    .width(30)
    .height(30)
    .position({ x: this.screenW - 72, y: 10 })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.gameEngine.pause();
      }
    })

    Stack() {
      Column()
        .width(30)
        .height(30)
        .backgroundColor('#0f0f23e0')
        .borderRadius(3)
        .border({ width: 2, color: '#475569' })

      Text('⚙')
        .fontSize(15)
        .fontColor('#94a3b8')
    }
    .width(30)
    .height(30)
    .position({ x: this.screenW - 38, y: 10 })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.showSettings = true;
      }
    })

    Stack() {
      Column()
        .width(30)
        .height(30)
        .backgroundColor('#0f0f23e0')
        .borderRadius(3)
        .border({ width: 2, color: '#7c3aed' })

      Text('✦')
        .fontSize(15)
        .fontColor('#a78bfa')
    }
    .width(30)
    .height(30)
    .position({ x: this.screenW - 74, y: 10 })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.refreshEvoState();
        this.showEvolution = true;
      }
    })
  }

  @Builder
  JoystickView() {
    Stack() {
      Column()
        .width(JOYSTICK_RADIUS * 2)
        .height(JOYSTICK_RADIUS * 2)
        .backgroundColor('#0f0f2360')
        .borderRadius(6)
        .border({ width: 3, color: '#334155' })

      Column()
        .width(JOYSTICK_RADIUS * 2 - 10)
        .height(JOYSTICK_RADIUS * 2 - 10)
        .backgroundColor('transparent')
        .borderRadius(4)
        .border({ width: 1, color: '#47556930' })

      Column()
        .width(38)
        .height(38)
        .backgroundColor('#94a3b8d0')
        .borderRadius(4)
        .border({ width: 2, color: '#cbd5e1' })
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
    Stack() {
      Stack() {
        Column()
          .width(54)
          .height(54)
          .backgroundColor('#0f0f23e0')
          .borderRadius(4)
          .border({ width: 3, color: '#ef4444' })

        Column()
          .width(44)
          .height(44)
          .backgroundColor('#ef444420')
          .borderRadius(3)
          .border({ width: 1, color: '#ef444440' })

        Text('⚔')
          .fontSize(24)
          .fontColor('#ef4444')
      }
      .width(54)
      .height(54)
      .position({ x: this.screenW - 66, y: this.screenH - 66 })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.gameEngine.setInputAttack(true);
        }
      })

      Stack() {
        Column()
          .width(46)
          .height(46)
          .backgroundColor('#0f0f23e0')
          .borderRadius(4)
          .border({ width: 3, color: '#22c55e' })

        Column()
          .width(36)
          .height(36)
          .backgroundColor('#22c55e20')
          .borderRadius(3)
          .border({ width: 1, color: '#22c55e40' })

        Text('↑')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#22c55e')
      }
      .width(46)
      .height(46)
      .position({ x: this.screenW - 128, y: this.screenH - 90 })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.gameEngine.setInputJump(true);
        }
      })

      Stack() {
        Column()
          .width(40)
          .height(40)
          .backgroundColor(this.dashReady ? '#0f0f23e0' : '#0a0a15e0')
          .borderRadius(4)
          .border({ width: 3, color: this.dashReady ? '#3b82f6' : '#1e3a5f' })

        Column()
          .width(30)
          .height(30)
          .backgroundColor(this.dashReady ? '#3b82f620' : '#1e3a5f20')
          .borderRadius(3)
          .border({ width: 1, color: this.dashReady ? '#3b82f640' : '#1e3a5f20' })

        Text('»')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.dashReady ? '#3b82f6' : '#1e3a5f')
      }
      .width(40)
      .height(40)
      .position({ x: this.screenW - 128, y: this.screenH - 38 })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down && this.dashReady) {
          this.gameEngine.setInputDash(true);
          this.dashReady = false;
          setTimeout(() => {
            this.dashReady = true;
          }, DASH_COOLDOWN);
        }
      })

      Stack() {
        Column()
          .width(42)
          .height(42)
          .backgroundColor(this.toolReady ? '#0f0f23e0' : '#0a0a15e0')
          .borderRadius(4)
          .border({ width: 3, color: this.toolReady ? '#f59e0b' : '#4a3520' })

        Column()
          .width(32)
          .height(32)
          .backgroundColor(this.toolReady ? '#f59e0b20' : '#4a352020')
          .borderRadius(3)
          .border({ width: 1, color: this.toolReady ? '#f59e0b40' : '#4a352020' })

        Text('⛏')
          .fontSize(19)
          .fontColor(this.toolReady ? '#f59e0b' : '#4a3520')
      }
      .width(42)
      .height(42)
      .position({ x: this.screenW - 66, y: this.screenH - 120 })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down && this.toolReady) {
          this.gameEngine.setInputTool(true);
          this.toolReady = false;
          setTimeout(() => {
            this.toolReady = true;
          }, 200);
        }
      })
    }
  }

  @Builder
  EngulfWarningView() {
    Row() {
      Text('!')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#fbbf24')
        .margin({ right: 6 })

      Text('被吞噬！连续攻击挣脱！')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
    }
    .width('90%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#7f1d1dd0')
    .borderRadius(4)
    .border({ width: 3, color: '#fbbf24' })
    .justifyContent(FlexAlign.Center)
    .position({ x: this.screenW * 0.05, y: this.screenH / 2 - 18 })
  }

  @Builder
  SettingsOverlay() {
    Stack() {
      Column() {
        Row() {
          Text('✦ 设置 ✦')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fbbf24')

          Blank()

          Stack() {
            Column()
              .width(26)
              .height(26)
              .backgroundColor('#2d1b4e')
              .borderRadius(2)
              .border({ width: 2, color: '#7c3aed' })

            Text('✕')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#c4b5fd')
          }
          .width(26)
          .height(26)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.showSettings = false;
            }
          })
        }
        .width('100%')
        .padding({ bottom: 10 })
        .border({ width: { bottom: 2 }, color: '#334155' })

        Column() {
          Row() {
            Text('♪ 音效')
              .fontSize(13)
              .fontColor('#e2e8f0')

            Blank()

            Stack() {
              Row()
                .width(40)
                .height(20)
                .backgroundColor(this.soundEnabled ? '#1e3a5f' : '#1a1a2e')
                .borderRadius(10)
                .border({ width: 2, color: this.soundEnabled ? '#3b82f6' : '#475569' })

              Column()
                .width(16)
                .height(16)
                .backgroundColor(this.soundEnabled ? '#3b82f6' : '#475569')
                .borderRadius(8)
                .translate({ x: this.soundEnabled ? 10 : -10 })
            }
            .width(40)
            .height(20)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.soundEnabled = !this.soundEnabled;
                this.gameEngine.setSettings({
                  soundEnabled: this.soundEnabled,
                  effectsEnabled: this.effectsEnabled
                });
              }
            })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })

          Divider().color('#334155').strokeWidth(1)

          Row() {
            Text('✧ 特效')
              .fontSize(13)
              .fontColor('#e2e8f0')

            Blank()

            Stack() {
              Row()
                .width(40)
                .height(20)
                .backgroundColor(this.effectsEnabled ? '#1e3a5f' : '#1a1a2e')
                .borderRadius(10)
                .border({ width: 2, color: this.effectsEnabled ? '#3b82f6' : '#475569' })

              Column()
                .width(16)
                .height(16)
                .backgroundColor(this.effectsEnabled ? '#3b82f6' : '#475569')
                .borderRadius(8)
                .translate({ x: this.effectsEnabled ? 10 : -10 })
            }
            .width(40)
            .height(20)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.effectsEnabled = !this.effectsEnabled;
                this.gameEngine.setSettings({
                  soundEnabled: this.soundEnabled,
                  effectsEnabled: this.effectsEnabled
                });
              }
            })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#0f0f23e0')
        .borderRadius(4)
        .border({ width: 2, color: '#334155' })

        Column() {
          Row() {
            Text('角色')
              .fontSize(11)
              .fontColor('#64748b')

            Blank()

            Text(this.username)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#fbbf24')
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#0f0f23e0')
        .borderRadius(4)
        .border({ width: 2, color: '#334155' })
        .margin({ top: 8 })

        Stack() {
          Column()
            .width('100%')
            .height(36)
            .backgroundColor('#7f1d1d')
            .borderRadius(4)
            .border({ width: 2, color: '#dc2626' })

          Text('退出登录')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fca5a5')
        }
        .width('100%')
        .height(36)
        .margin({ top: 14 })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.gameEngine.destroy();
            router.replaceUrl({ url: 'pages/LoginPage' });
          }
        })

        Blank()

        Column() {
          Text('ICP备案号: 示例ICP备xxxxxxxx号')
            .fontSize(9)
            .fontColor('#374151')
          Text('v1.0.0')
            .fontSize(8)
            .fontColor('#1e293b')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 6 })
      }
      .width('80%')
      .padding(16)
      .backgroundColor('#0a0a15f8')
      .borderRadius(6)
      .border({ width: 3, color: '#475569' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000c0')
  }

  @Builder
  EvolutionOverlay() {
    Stack() {
      Column() {
        Row() {
          Text('✦ 武器进化 ✦')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#c4b5fd')

          Blank()

          Stack() {
            Column()
              .width(26)
              .height(26)
              .backgroundColor('#2d1b4e')
              .borderRadius(2)
              .border({ width: 2, color: '#7c3aed' })

            Text('✕')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#c4b5fd')
          }
          .width(26)
          .height(26)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.showEvolution = false;
            }
          })
        }
        .width('100%')
        .padding({ bottom: 8 })
        .border({ width: { bottom: 2 }, color: '#4c1d95' })

        Row() {
          Text('形态')
            .fontSize(11)
            .fontColor('#64748b')
          Text(this.gameEngine.getWeaponFormName(this.currentWeaponForm))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fbbf24')
            .margin({ left: 6 })
        }
        .width('100%')
        .padding({ top: 8, bottom: 6 })

        Row() {
          ForEach(this.branchNames, (name: string, index: number) => {
            Stack() {
              Text(name)
                .fontSize(9)
                .fontWeight(this.evoBranch === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.evoBranch === index ? '#ffffff' : '#64748b')
            }
            .padding({ left: 8, right: 8, top: 5, bottom: 5 })
            .backgroundColor(this.evoBranch === index ? '#4c1d95' : '#0f0f23')
            .borderRadius(3)
            .border({ width: 2, color: this.evoBranch === index ? this.getBranchColor(index) : '#1e293b' })
            .margin({ left: index > 0 ? 4 : 0 })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.evoBranch = index;
              }
            })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: 8 })

        Row() {
          Text('进化等级')
            .fontSize(11)
            .fontColor('#94a3b8')
          Blank()
          Row() {
            ForEach([0, 1, 2], (i: number) => {
              Text(i < this.evoLevel ? '★' : '☆')
                .fontSize(14)
                .fontColor(i < this.evoLevel ? this.getBranchColor(this.evoBranch) : '#374151')
                .margin({ left: i > 0 ? 2 : 0 })
            })
          }
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor('#0f0f23e0')
        .borderRadius(4)
        .border({ width: 2, color: '#334155' })

        if (!this.evoMaxLevel) {
          Column() {
            Row() {
              Text('◆ 矿石')
                .fontSize(10)
                .fontColor('#00ced1')
              Blank()
              Text(this.evoOreHave + ' / ' + this.evoOreNeed)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.evoOreHave >= this.evoOreNeed ? '#22c55e' : '#ef4444')
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })

            Divider().color('#334155').strokeWidth(1)

            Row() {
              Text('● 普通核心')
                .fontSize(10)
                .fontColor('#a78bfa')
              Blank()
              Text(this.evoNormalHave + ' / ' + this.evoNormalNeed)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.evoNormalHave >= this.evoNormalNeed ? '#22c55e' : '#ef4444')
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })

            Divider().color('#334155').strokeWidth(1)

            Row() {
              Text('★ 稀有核心')
                .fontSize(10)
                .fontColor('#fbbf24')
              Blank()
              Text(this.evoRareHave + ' / ' + this.evoRareNeed)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.evoRareHave >= this.evoRareNeed ? '#22c55e' : '#ef4444')
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })
          }
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .backgroundColor('#0f0f23e0')
          .borderRadius(4)
          .border({ width: 2, color: '#334155' })
          .margin({ top: 8 })

          Stack() {
            Column()
              .width('100%')
              .height(36)
              .backgroundColor(this.canEvolveNow() ? '#4c1d95' : '#1a1a2e')
              .borderRadius(4)
              .border({ width: 2, color: this.canEvolveNow() ? '#7c3aed' : '#334155' })

            Text('✦ 进化 ✦')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.canEvolveNow() ? '#e9d5ff' : '#475569')
          }
          .width('100%')
          .height(36)
          .margin({ top: 10 })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down && this.canEvolveNow()) {
              if (this.gameEngine.tryEvolveWeapon()) {
                this.refreshEvoState();
              }
            }
          })
        } else {
          Row() {
            Text('★ 已达最高等级 ★')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#fbbf24')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .backgroundColor('#0f0f23e0')
          .borderRadius(4)
          .border({ width: 2, color: '#fbbf2460' })
          .margin({ top: 8 })
        }

        Column() {
          Row() {
            Text('解锁形态')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#e2e8f0')
            Blank()
            Text('◈ ' + this.evoFormCore)
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#f472b6')
          }
          .width('100%')
          .padding({ bottom: 6 })

          ForEach(this.lockedForms, (formIndex: number) => {
            Row() {
              Text(this.gameEngine.getWeaponFormName(formIndex as WeaponForm))
                .fontSize(10)
                .fontColor('#94a3b8')
              Blank()
              Stack() {
                Text('解锁 (1核心)')
                  .fontSize(9)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.evoFormCore >= FORM_UNLOCK_COST ? '#ffffff' : '#64748b')
              }
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.evoFormCore >= FORM_UNLOCK_COST ? '#4c1d95' : '#0f0f23')
              .borderRadius(3)
              .border({ width: 2, color: this.evoFormCore >= FORM_UNLOCK_COST ? '#7c3aed' : '#1e293b' })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down && this.evoFormCore >= FORM_UNLOCK_COST) {
                  this.gameEngine.unlockWeaponForm(formIndex as WeaponForm);
                  this.refreshEvoState();
                }
              })
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          })
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#0f0f23e0')
        .borderRadius(4)
        .border({ width: 2, color: '#334155' })
        .margin({ top: 8 })

        Blank()
      }
      .width('85%')
      .padding(14)
      .backgroundColor('#0a0a15f8')
      .borderRadius(6)
      .border({ width: 3, color: '#4c1d95' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000c0')
  }

  private getBranchColor(branch: number): string {
    if (branch === EvolutionBranch.CRYSTAL) return '#00ced1';
    if (branch === EvolutionBranch.FLAME) return '#ff4500';
    if (branch === EvolutionBranch.SHADOW) return '#6b21a8';
    if (branch === EvolutionBranch.TOXIN) return '#32cd32';
    if (branch === EvolutionBranch.TIDE) return '#4169e1';
    return '#ffffff';
  }

  private canEvolveNow(): boolean {
    if (this.evoMaxLevel) return false;
    return this.evoOreHave >= this.evoOreNeed &&
      this.evoNormalHave >= this.evoNormalNeed &&
      this.evoRareHave >= this.evoRareNeed;
  }

  private refreshEvoState(): void {
    this.evoBranch = this.gameEngine.getEvoBranch();
    this.evoLevel = this.gameEngine.getEvoLevel();
    this.evoOreHave = this.gameEngine.getEvoOreHave();
    this.evoOreNeed = this.gameEngine.getEvoOreNeed();
    this.evoNormalHave = this.gameEngine.getEvoNormalHave();
    this.evoNormalNeed = this.gameEngine.getEvoNormalNeed();
    this.evoRareHave = this.gameEngine.getEvoRareHave();
    this.evoRareNeed = this.gameEngine.getEvoRareNeed();
    this.evoFormCore = this.gameEngine.getEvoFormCore();
    this.evoMaxLevel = this.evoLevel >= 3;
    const unlocked: number[] = this.gameEngine.getUnlockedForms();
    const allForms: number[] = [0, 1, 2, 3, 4, 5];
    this.lockedForms = allForms.filter((f: number) => unlocked.indexOf(f) < 0);
  }

  private tryInitEngine(): void {
    if (this.gameCanvasReady && this.minimapCanvasReady && this.cacheCanvasesReady >= 6) {
      const ctx = getContext(this) as common.UIAbilityContext;
      this.gameEngine.setExternalLoop(true);
      this.gameEngine.init(this.gameCtx, this.minimapCtx, this.screenW, this.screenH,
        [this.cacheCtx0, this.cacheCtx1, this.cacheCtx2, this.cacheCtx3, this.cacheCtx4, this.cacheCtx5], ctx);
      this.gameEngine.setGender(this.playerGender);
      this.gameEngine.setSettings({
        soundEnabled: this.soundEnabled,
        effectsEnabled: this.effectsEnabled
      });
      this.gameEngine.setOnStateChange((state: GameState) => {
        this.gameState = state;
        if (state === GameState.PAUSED) {
          this.showPauseMenu = true;
        } else if (state === GameState.GAME_OVER) {
          this.showGameOver = true;
          if (this.gameEngine.getPlayer()) {
            this.deathLevel = this.gameEngine.getPlayer()!.level;
            this.deathChunks = this.gameEngine.getExploredChunks().length;
          }
        }
      });
      this.gameEngine.setOnSave(() => {
        this.showSaveIndicator = true;
        setTimeout(() => {
          this.showSaveIndicator = false;
        }, 1500);
      });

      const ge = this.gameEngine;
      const sceneDefs: SceneDefinition[] = [
        { name: 'main-menu', factory: (): Scene => new MainMenuScene() } as SceneDefinition,
        { name: 'game', factory: (): Scene => { this.gameScene = new GameScene(ge); return this.gameScene; } } as SceneDefinition,
      ];
      Engine.init({
        canvas: this.gameCtx,
        screenWidth: this.screenW,
        screenHeight: this.screenH,
        scenes: sceneDefs,
        entryScene: 'game',
        appContext: ctx,
      }).then((engine: Engine) => {
        this.engine = engine;
        engine.start();
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
      const inv: Inventory = this.gameEngine.getInventory();
      const branchOre: number = this.gameEngine.getEvoOreHave();
      if (branchOre !== this.invOre) {
        this.invOre = branchOre;
      }
      if (inv.coreNormal !== this.invNormal) {
        this.invNormal = inv.coreNormal;
      }
      if (inv.coreRare !== this.invRare) {
        this.invRare = inv.coreRare;
      }
      if (inv.formCore !== this.invFormCore) {
        this.invFormCore = inv.formCore;
      }
      // Transform state
      const isT: boolean = this.gameEngine.getIsTransformed();
      if (isT !== this.isTransformed) { this.isTransformed = isT; }
      if (isT) {
        const e: number = this.gameEngine.getTransformEnergy();
        if (e !== this.transformEnergy) { this.transformEnergy = e; }
        const f: TransformForm = this.gameEngine.getTransformForm();
        if (f !== this.transformForm) { this.transformForm = f; }
      }
      const cd: number = this.gameEngine.getTransformCooldown();
      if (cd !== this.transformCooldown) { this.transformCooldown = cd; }
      const ut: number[] = this.gameEngine.getUnlockedTransforms();
      if (ut.length !== this.unlockedTransforms.length) { this.unlockedTransforms = ut; }
      // Unlock notification
      const notify = this.gameEngine.getTransformUnlockNotify();
      if (notify.active && !this.transformUnlockActive) {
        this.transformUnlockActive = true;
        this.transformUnlockForm = notify.form;
        setTimeout(() => { this.transformUnlockActive = false; }, 3000);
      }
    }, 100);
  }

  @Builder
  TransformButtonView() {
    Stack() {
      Column()
        .width(38)
        .height(38)
        .backgroundColor('#0f0f23e0')
        .borderRadius(4)
        .border({ width: 2, color: this.isTransformed ? this.getFormColor(this.transformForm) :
          (this.unlockedTransforms.length > 0 && this.transformCooldown <= 0 ? COLOR_TRANSFORM_BTN_READY : COLOR_TRANSFORM_BTN_LOCKED) })

      Text(this.getTransformIcon())
        .fontSize(17)
        .fontColor('#ffffff')

      if (this.transformCooldown > 0 && !this.isTransformed) {
        Text(Math.ceil(this.transformCooldown / 1000).toString())
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffffa0')
          .position({ x: 13, y: 23 })
      }
    }
    .position({ x: 30, y: this.screenH - 140 })
    .onClick(() => {
      if (this.isTransformed) {
        this.gameEngine.deactivateTransform();
      } else if (this.unlockedTransforms.length === 1) {
        this.gameEngine.activateTransform(this.unlockedTransforms[0] as TransformForm);
      } else if (this.unlockedTransforms.length > 1) {
        this.showFormSelect = true;
      }
    })
  }

  @Builder
  TransformEnergyBarView() {
    if (this.isTransformed) {
      Column() {
        Stack({ alignContent: Alignment.Start }) {
          Row().width(100).height(7).backgroundColor('#0f0f23').borderRadius(3)
          Row()
            .width(100 * (this.transformEnergy / this.transformMaxEnergy))
            .height(7)
            .backgroundColor(this.getFormColor(this.transformForm))
            .borderRadius(3)
        }
        .border({ width: 2, color: '#334155' })
        .borderRadius(3)

        Text(Math.floor(this.transformEnergy).toString())
          .fontSize(8)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffffa0')
          .margin({ top: 1 })
      }
      .position({ x: 74, y: this.screenH - 136 })
    }
  }

  @Builder
  FormSelectPanel() {
    if (this.showFormSelect) {
      Column() {
        Text('选择形态')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#fbbf24')
          .margin({ bottom: 10 })

        Row({ space: 8 }) {
          ForEach(this.unlockedTransforms, (formId: number) => {
            Column() {
              Text(this.getFormIconForId(formId))
                .fontSize(20)
                .fontColor('#ffffff')
              Text(this.getFormNameForId(formId))
                .fontSize(9)
                .fontWeight(FontWeight.Medium)
                .fontColor('#ffffffc0')
                .margin({ top: 3 })
            }
            .width(50)
            .height(58)
            .backgroundColor('#0f0f23e0')
            .borderRadius(4)
            .border({ width: 2, color: this.getFormColor(formId as TransformForm) })
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.showFormSelect = false;
              this.gameEngine.activateTransform(formId as TransformForm);
            })
          })
        }

        Text('取消')
          .fontSize(10)
          .fontColor('#ffffff80')
          .margin({ top: 8 })
          .onClick(() => { this.showFormSelect = false; })
      }
      .width(260)
      .padding(14)
      .backgroundColor('#0a0a15f5')
      .borderRadius(6)
      .border({ width: 3, color: '#475569' })
      .position({ x: (this.screenW - 260) / 2, y: (this.screenH - 130) / 2 })
    }
  }

  @Builder
  TransformUnlockNotification() {
    if (this.transformUnlockActive) {
      Column() {
        Text('✦ 新形态解锁 ✦')
          .fontSize(13)
          .fontColor('#fbbf24')
          .fontWeight(FontWeight.Bold)
        Text(this.getFormIconForId(this.transformUnlockForm as number))
          .fontSize(28)
          .margin({ top: 6 })
        Text(this.getFormNameForId(this.transformUnlockForm as number))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .margin({ top: 3 })
      }
      .width(180)
      .padding(14)
      .backgroundColor('#0a0a15f5')
      .borderRadius(6)
      .border({ width: 3, color: '#fbbf24' })
      .position({ x: (this.screenW - 180) / 2, y: (this.screenH - 110) / 2 })
    }
  }

  private getTransformIcon(): string {
    if (this.isTransformed) {
      return this.getFormIconForId(this.transformForm as number);
    }
    return '⚡';
  }

  private getFormIconForId(formId: number): string {
    if (formId === TransformForm.SLIME) return '🟢';
    if (formId === TransformForm.GHOST) return '👻';
    if (formId === TransformForm.ARMOR) return '🛡';
    if (formId === TransformForm.IRON_MAN) return '🔴';
    return '?';
  }

  private getFormNameForId(formId: number): string {
    if (formId === TransformForm.SLIME) return 'Slime';
    if (formId === TransformForm.GHOST) return 'Ghost';
    if (formId === TransformForm.ARMOR) return 'Armor';
    if (formId === TransformForm.IRON_MAN) return 'Iron Man';
    return 'Unknown';
  }

  private getFormColor(form: TransformForm): string {
    if (form === TransformForm.SLIME) return COLOR_TRANSFORM_SLIME;
    if (form === TransformForm.GHOST) return COLOR_TRANSFORM_GHOST;
    if (form === TransformForm.ARMOR) return COLOR_TRANSFORM_ARMOR;
    if (form === TransformForm.IRON_MAN) return COLOR_TRANSFORM_IRON_GOLD;
    return COLOR_TRANSFORM_BTN_READY;
  }

  @Builder
  PauseMenuOverlay() {
    Stack() {
      Column() {
        // Dimmed background
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0,0,0,0.7)')
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          // Consume touch
        }
      })

      Column() {
        Text('游戏暂停')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#fbbf24')
          .margin({ bottom: 20 })

        Button('继续游戏')
          .width(180)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#22c55e')
          .borderRadius(8)
          .margin({ bottom: 12 })
          .onClick(() => {
            this.showPauseMenu = false;
            this.gameEngine.resume();
          })

        Button('读取存档')
          .width(180)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#3b82f6')
          .borderRadius(8)
          .margin({ bottom: 12 })
          .onClick(async () => {
            const ctx = getContext(this) as common.UIAbilityContext;
            const data = await SaveManager.load(ctx);
            if (data) {
              this.gameEngine.applySaveData(data);
              this.showPauseMenu = false;
              this.gameEngine.resume();
            }
          })

        Button('退出游戏')
          .width(180)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#ef4444')
          .borderRadius(8)
          .onClick(() => {
            this.gameEngine.quit();
            router.replace({ url: 'pages/LoginPage' });
          })
      }
      .width(240)
      .padding(24)
      .backgroundColor('#1a1a2e')
      .borderRadius(12)
      .border({ width: 3, color: '#f59e0b' })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  GameOverOverlay() {
    Stack() {
      Column() {
        // Red dimmed background
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(80,0,0,0.75)')
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          // Consume touch
        }
      })

      Column() {
        Text('你死了')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ef4444')
          .margin({ bottom: 16 })

        Text('等级: ' + this.deathLevel)
          .fontSize(14)
          .fontColor('#94a3b8')
          .margin({ bottom: 4 })

        Text('探索: ' + this.deathChunks + ' chunks')
          .fontSize(14)
          .fontColor('#94a3b8')
          .margin({ bottom: 20 })

        Button('重新开始')
          .width(180)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#22c55e')
          .borderRadius(8)
          .margin({ bottom: 12 })
          .onClick(async () => {
            const ctx = getContext(this) as common.UIAbilityContext;
            await SaveManager.deleteSave(ctx);
            this.showGameOver = false;
            this.gameEngine.restart();
          })

        Button('读取存档')
          .width(180)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#3b82f6')
          .borderRadius(8)
          .margin({ bottom: 12 })
          .onClick(async () => {
            const ctx = getContext(this) as common.UIAbilityContext;
            const data = await SaveManager.load(ctx);
            if (data) {
              this.showGameOver = false;
              this.gameEngine.applySaveData(data);
              this.gameEngine.resume();
            }
          })

        Button('返回主页')
          .width(180)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#6b7280')
          .borderRadius(8)
          .onClick(() => {
            this.gameEngine.quit();
            router.replace({ url: 'pages/LoginPage' });
          })
      }
      .width(260)
      .padding(24)
      .backgroundColor('#1a1a2e')
      .borderRadius(12)
      .border({ width: 3, color: '#ef4444' })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SaveIndicator() {
    Text('已保存')
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor('#22c55e')
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('rgba(0,0,0,0.7)')
      .borderRadius(6)
      .position({ x: this.screenW - 80, y: 50 })
      .opacity(0.9)
  }
}
