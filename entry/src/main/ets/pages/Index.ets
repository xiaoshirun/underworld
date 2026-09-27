import { display, router } from '@kit.ArkUI';
import { GameEngine } from '../game/GameEngine';
import {
  PLAYER_MAX_HP, JOYSTICK_RADIUS, MINIMAP_SIZE,
  COLOR_HP_FULL, COLOR_HP_EMPTY,
  COLOR_JOY_BASE, COLOR_JOY_KNOB,
  COLOR_BTN_JUMP, COLOR_BTN_ATTACK, COLOR_BTN_DASH, COLOR_TOOL_BTN,
  COLOR_XP_ORB, DASH_COOLDOWN, GenderType, WeaponForm,
  EvolutionBranch, FORM_UNLOCK_COST, Inventory,
  TransformForm, TRANSFORM_MAX_ENERGY, TRANSFORM_COOLDOWN,
  COLOR_TRANSFORM_BTN_LOCKED, COLOR_TRANSFORM_BTN_READY, COLOR_TRANSFORM_ENERGY_BG,
  COLOR_TRANSFORM_SLIME, COLOR_TRANSFORM_GHOST, COLOR_TRANSFORM_ARMOR, COLOR_TRANSFORM_IRON_GOLD
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
  private branchNames: string[] = ['Crystal', 'Flame', 'Shadow', 'Toxin', 'Tide'];

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
        if (p['gender'] !== undefined) {
          this.playerGender = p['gender'] as GenderType;
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
  WeaponFormView() {
    Stack() {
      Row() {
        Text(this.gameEngine.getWeaponFormName(this.currentWeaponForm))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
      }
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor('#1e293be0')
      .borderRadius(6)
      .border({ width: 1, color: '#475569' })
    }
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.gameEngine.cycleWeaponForm();
        this.currentWeaponForm = this.gameEngine.getCurrentWeaponForm();
      }
    })
    .position({ x: 10, y: 76 + MINIMAP_SIZE + 14 })
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
          .fontColor('#e2e8f0')
          .margin({ left: 2 })
      }
      .margin({ right: 8 })

      Row() {
        Text('●')
          .fontSize(10)
          .fontColor('#a78bfa')
        Text(this.invNormal.toString())
          .fontSize(10)
          .fontColor('#e2e8f0')
          .margin({ left: 2 })
      }
      .margin({ right: 8 })

      Row() {
        Text('★')
          .fontSize(10)
          .fontColor('#fbbf24')
        Text(this.invRare.toString())
          .fontSize(10)
          .fontColor('#e2e8f0')
          .margin({ left: 2 })
      }
      .margin({ right: 8 })

      Row() {
        Text('◈')
          .fontSize(10)
          .fontColor('#f472b6')
        Text(this.invFormCore.toString())
          .fontSize(10)
          .fontColor('#e2e8f0')
          .margin({ left: 2 })
      }
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor('#1e293be0')
    .borderRadius(6)
    .border({ width: 1, color: '#334155' })
    .position({ x: 10, y: 76 + MINIMAP_SIZE + 14 + 36 })
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

    Stack() {
      Circle()
        .width(32)
        .height(32)
        .fill('#1e293b')
        .opacity(0.8)

      Text('✦')
        .fontSize(16)
        .fontColor('#a78bfa')
    }
    .width(32)
    .height(32)
    .position({ x: this.screenW - 82, y: 12 })
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
            .width(44)
            .height(44)
            .fill(this.toolReady ? COLOR_TOOL_BTN : '#4a3520')
            .opacity(this.toolReady ? 0.85 : 0.5)
            .shadow({ radius: 6, color: '#f59e0b40', offsetX: 0, offsetY: 2 })

          Text('钻')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
        }
        .width(44)
        .height(44)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down && this.toolReady) {
            this.gameEngine.setInputTool(true);
            this.toolReady = false;
            setTimeout(() => {
              this.toolReady = true;
            }, 200);
          }
        })

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
        .margin({ left: 10 })
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

  @Builder
  EvolutionOverlay() {
    Stack() {
      Column() {
        // Header
        Row() {
          Text('武器进化')
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
              this.showEvolution = false;
            }
          })
        }
        .width('100%')
        .margin({ bottom: 12 })

        // Current weapon form
        Row() {
          Text('形态: ')
            .fontSize(13)
            .fontColor('#94a3b8')
          Text(this.gameEngine.getWeaponFormName(this.currentWeaponForm))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fbbf24')
        }
        .width('100%')
        .margin({ bottom: 10 })

        // Branch tabs
        Row() {
          ForEach(this.branchNames, (name: string, index: number) => {
            Stack() {
              Text(name)
                .fontSize(11)
                .fontWeight(this.evoBranch === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.evoBranch === index ? this.getBranchColor(index) : '#64748b')
            }
            .padding({ left: 8, right: 8, top: 5, bottom: 5 })
            .backgroundColor(this.evoBranch === index ? '#1e293b' : '#0f172a')
            .borderRadius(6)
            .border({ width: 1, color: this.evoBranch === index ? this.getBranchColor(index) : '#1e293b' })
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
        .margin({ bottom: 14 })

        // Evolution level display
        Row() {
          Text('进化等级')
            .fontSize(13)
            .fontColor('#94a3b8')
          Blank()
          Text(this.evoLevel + ' / 3')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getBranchColor(this.evoBranch))
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
        .backgroundColor('#1e293b40')
        .borderRadius(8)

        // Material costs
        if (!this.evoMaxLevel) {
          Column() {
            Row() {
              Text('矿石')
                .fontSize(12)
                .fontColor('#94a3b8')
              Blank()
              Text(this.evoOreHave + ' / ' + this.evoOreNeed)
                .fontSize(12)
                .fontColor(this.evoOreHave >= this.evoOreNeed ? '#22c55e' : '#ef4444')
            }
            .width('100%')
            .padding({ top: 6, bottom: 6 })

            Divider().color('#1e293b')

            Row() {
              Text('普通核心')
                .fontSize(12)
                .fontColor('#94a3b8')
              Blank()
              Text(this.evoNormalHave + ' / ' + this.evoNormalNeed)
                .fontSize(12)
                .fontColor(this.evoNormalHave >= this.evoNormalNeed ? '#22c55e' : '#ef4444')
            }
            .width('100%')
            .padding({ top: 6, bottom: 6 })

            Divider().color('#1e293b')

            Row() {
              Text('稀有核心')
                .fontSize(12)
                .fontColor('#94a3b8')
              Blank()
              Text(this.evoRareHave + ' / ' + this.evoRareNeed)
                .fontSize(12)
                .fontColor(this.evoRareHave >= this.evoRareNeed ? '#22c55e' : '#ef4444')
            }
            .width('100%')
            .padding({ top: 6, bottom: 6 })
          }
          .padding({ left: 14, right: 14, top: 4, bottom: 4 })
          .backgroundColor('#1e293b40')
          .borderRadius(8)
          .margin({ top: 10 })

          // Evolve button
          Button('进化')
            .width('100%')
            .height(40)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .backgroundColor(this.canEvolveNow() ? '#7c3aed' : '#374151')
            .borderRadius(10)
            .margin({ top: 12 })
            .enabled(this.canEvolveNow())
            .shadow({ radius: this.canEvolveNow() ? 10 : 0, color: '#7c3aed60', offsetX: 0, offsetY: 2 })
            .onClick(() => {
              if (this.gameEngine.tryEvolveWeapon()) {
                this.refreshEvoState();
              }
            })
        } else {
          Row() {
            Text('已达最高等级')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#fbbf24')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .backgroundColor('#1e293b40')
          .borderRadius(8)
          .margin({ top: 10 })
        }

        // Form unlock section
        Column() {
          Row() {
            Text('解锁形态')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#e2e8f0')
            Blank()
            Text('形态核心: ' + this.evoFormCore)
              .fontSize(11)
              .fontColor('#a78bfa')
          }
          .width('100%')
          .margin({ bottom: 8 })

          ForEach(this.lockedForms, (formIndex: number) => {
            Row() {
              Text(this.gameEngine.getWeaponFormName(formIndex as WeaponForm))
                .fontSize(12)
                .fontColor('#94a3b8')
              Blank()
              Stack() {
                Text('解锁 (1核心)')
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.evoFormCore >= FORM_UNLOCK_COST ? '#ffffff' : '#64748b')
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(this.evoFormCore >= FORM_UNLOCK_COST ? '#4f46e5' : '#1e293b')
              .borderRadius(6)
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down && this.evoFormCore >= FORM_UNLOCK_COST) {
                  this.gameEngine.unlockWeaponForm(formIndex as WeaponForm);
                  this.refreshEvoState();
                }
              })
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })
          })
        }
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor('#1e293b40')
        .borderRadius(8)
        .margin({ top: 10 })

        Blank()
      }
      .width('88%')
      .padding(18)
      .backgroundColor('#0f172af5')
      .borderRadius(18)
      .border({ width: 1, color: '#1e293b' })
      .shadow({ radius: 24, color: '#000000a0', offsetX: 0, offsetY: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000b0')
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
    if (this.gameCanvasReady && this.minimapCanvasReady) {
      this.gameEngine.init(this.gameCtx, this.minimapCtx, this.screenW, this.screenH);
      this.gameEngine.setGender(this.playerGender);
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
      // Button background
      Circle()
        .width(40)
        .height(40)
        .fill(this.isTransformed ? this.getFormColor(this.transformForm) :
          (this.unlockedTransforms.length > 0 && this.transformCooldown <= 0 ? COLOR_TRANSFORM_BTN_READY : COLOR_TRANSFORM_BTN_LOCKED))

      // Icon
      Text(this.getTransformIcon())
        .fontSize(18)
        .fontColor('#ffffff')

      // Cooldown overlay
      if (this.transformCooldown > 0 && !this.isTransformed) {
        Text(Math.ceil(this.transformCooldown / 1000).toString())
          .fontSize(12)
          .fontColor('#ffffffa0')
          .position({ x: 14, y: 26 })
      }
    }
    .position({ x: this.screenW - 55, y: this.screenH - 200 })
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
          // Background
          Row().width(120).height(8).backgroundColor(COLOR_TRANSFORM_ENERGY_BG).borderRadius(4)
          // Fill
          Row()
            .width(120 * (this.transformEnergy / this.transformMaxEnergy))
            .height(8)
            .backgroundColor(this.getFormColor(this.transformForm))
            .borderRadius(4)
        }
        Text(Math.floor(this.transformEnergy).toString())
          .fontSize(9)
          .fontColor('#ffffffa0')
          .margin({ top: 2 })
      }
      .position({ x: this.screenW - 135, y: this.screenH - 155 })
    }
  }

  @Builder
  FormSelectPanel() {
    if (this.showFormSelect) {
      Column() {
        Text('Select Form')
          .fontSize(14)
          .fontColor('#ffffff')
          .margin({ bottom: 12 })

        Row({ space: 12 }) {
          ForEach(this.unlockedTransforms, (formId: number) => {
            Column() {
              Text(this.getFormIconForId(formId))
                .fontSize(24)
                .fontColor('#ffffff')
              Text(this.getFormNameForId(formId))
                .fontSize(10)
                .fontColor('#ffffffc0')
                .margin({ top: 4 })
            }
            .width(56)
            .height(64)
            .backgroundColor('#1e293be0')
            .borderRadius(8)
            .border({ width: 1, color: this.getFormColor(formId as TransformForm) })
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.showFormSelect = false;
              this.gameEngine.activateTransform(formId as TransformForm);
            })
          })
        }

        Text('Cancel')
          .fontSize(12)
          .fontColor('#ffffff80')
          .margin({ top: 8 })
          .onClick(() => { this.showFormSelect = false; })
      }
      .width(280)
      .padding(16)
      .backgroundColor('#0f172af0')
      .borderRadius(12)
      .position({ x: (this.screenW - 280) / 2, y: (this.screenH - 140) / 2 })
    }
  }

  @Builder
  TransformUnlockNotification() {
    if (this.transformUnlockActive) {
      Column() {
        Text('NEW FORM UNLOCKED!')
          .fontSize(14)
          .fontColor('#fbbf24')
          .fontWeight(FontWeight.Bold)
        Text(this.getFormIconForId(this.transformUnlockForm as number))
          .fontSize(32)
          .margin({ top: 8 })
        Text(this.getFormNameForId(this.transformUnlockForm as number))
          .fontSize(16)
          .fontColor('#ffffff')
          .margin({ top: 4 })
      }
      .width(200)
      .padding(16)
      .backgroundColor('#0f172af0')
      .borderRadius(12)
      .border({ width: 2, color: '#fbbf24' })
      .position({ x: (this.screenW - 200) / 2, y: (this.screenH - 120) / 2 })
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
}
