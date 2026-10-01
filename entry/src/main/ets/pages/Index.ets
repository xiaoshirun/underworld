import { display, router, DrawingRenderingContext, xcomponent } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Engine, Entity, HealthComponent, SystemContext, World } from '@qiuyu/engine';
import { GameScene } from '../game/GameScene';
import { AudioManager } from '../game/AudioManager';
import { SaveManager } from '../game/SaveManager';
import { NativeRenderer } from '../native/NativeRenderer';
import { DrawCmdBuffer } from '../native/DrawCmd';
import {
  PLAYER_MAX_HP, JOYSTICK_RADIUS,
  DASH_COOLDOWN, WeaponForm,
  TransformForm, TRANSFORM_MAX_ENERGY,
  COLOR_TRANSFORM_BTN_LOCKED, COLOR_TRANSFORM_BTN_READY,
  COLOR_TRANSFORM_SLIME, COLOR_TRANSFORM_GHOST, COLOR_TRANSFORM_ARMOR, COLOR_TRANSFORM_IRON_GOLD,
  GameState, LEVEL_UP_XP, SaveData, GameSettings,
} from '../game/GameConstants';

// Components
import { XpComponent } from '../game/components/XpComponent';
import { InventoryComponent } from '../game/components/InventoryComponent';
import { TransformComponent } from '../game/components/TransformComponent';
import { EvolutionComponent } from '../game/components/EvolutionComponent';
import { MovementComponent } from '../game/components/MovementComponent';
import { GameStateComponent } from '../game/components/GameStateComponent';

// Overlay components
import { SettingsOverlay } from './overlays/SettingsOverlay';
import { EvolutionOverlay } from './overlays/EvolutionOverlay';
import { PauseMenuOverlay } from './overlays/PauseMenuOverlay';
import { GameOverOverlay } from './overlays/GameOverOverlay';
import { SaveIndicator } from './overlays/SaveIndicator';

@Entry
@Component
struct Index {
  private engine: Engine = new Engine();
  private gameScene: GameScene | null = null;
  private audio: AudioManager = new AudioManager();
  private settings: GameSettings = { soundEnabled: true, effectsEnabled: true } as GameSettings;
  // Drawing contexts kept for Engine.tick() compatibility (ECS systems require non-null ctx).
  // No Canvas UI components are rendered — XComponent + NativeRenderer handle display.
  private gameDrawingCtx: DrawingRenderingContext = new DrawingRenderingContext();
  private gameCtx: CanvasRenderingContext2D = CanvasRenderingContext2D.getContext2DFromDrawingContext(this.gameDrawingCtx, { antialias: true });
  private minimapDrawingCtx: DrawingRenderingContext = new DrawingRenderingContext();
  private minimapCtx: CanvasRenderingContext2D = CanvasRenderingContext2D.getContext2DFromDrawingContext(this.minimapDrawingCtx, { antialias: true });
  private xComponentController: xcomponent.XComponentController = new xcomponent.XComponentController();
  private nativeRenderer: NativeRenderer = new NativeRenderer();
  private cmdBuffer: DrawCmdBuffer = new DrawCmdBuffer();
  @State screenW: number = 360;
  @State screenH: number = 780;
  // Canvas 绘图坐标系是像素，而 screenW/screenH（vp）用于 UI 定位。
  // 引擎渲染必须用像素尺寸，否则只渲染屏幕左上角一小块（vp < px）。
  private pixelW: number = 1260;
  private pixelH: number = 2720;
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
  @State isNewGame: boolean = true;
  @State engulfWarning: boolean = false;
  @State dashReady: boolean = true;
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
  @State @Watch('onCanvasTickChange') canvasTick: number = 0;
  private loopIntervalId: number = -1;
  private lastTickTime: number = 0;
  private branchNames: string[] = ['Crystal', 'Flame', 'Shadow', 'Toxin', 'Tide'];
  private weaponFormNames: string[] = ['刃', '鞭', '锤', '杖', '双刃', '巨斧'];
  private monitorIntervalId: number = -1;

  aboutToAppear(): void {
    try {
      const displayInfo: display.Display = display.getDefaultDisplaySync();
      const pxW: number = displayInfo.width;
      const pxH: number = displayInfo.height;
      const vpW: number = px2vp(pxW);
      const vpH: number = px2vp(pxH);
      // 应用锁定横屏（module.json5 orientation=landscape），而 display 在手机上
      // 常返回自然竖屏尺寸。必须强制换算成横屏，否则所有下半屏控件
      // （摇杆/攻击/跳跃/冲刺/工具）会被定位到窗口之外，表现为"按键无反应"。
      if (pxW > pxH) {
        this.screenW = vpW;
        this.screenH = vpH;
        this.pixelW = pxW;
        this.pixelH = pxH;
      } else {
        this.screenW = vpH;
        this.screenH = vpW;
        this.pixelW = pxH;
        this.pixelH = pxW;
      }
      const params: Object | null = router.getParams();
      if (params !== null && params !== undefined) {
        const p: Record<string, Object> = params as Record<string, Object>;
        if (p['username'] !== undefined) {
          this.username = p['username'] as string;
        }
        if (p['isNewGame'] !== undefined) {
          this.isNewGame = p['isNewGame'] as boolean;
        }
      }
    } catch (e) {
      // 兜底尺寸与横屏锁定保持一致
      this.screenW = 780;
      this.screenH = 360;
      this.pixelW = 2720;
      this.pixelH = 1260;
    }
  }

  aboutToDisappear(): void {
    if (this.monitorIntervalId !== -1) {
      clearInterval(this.monitorIntervalId);
    }
    if (this.loopIntervalId !== -1) {
      clearInterval(this.loopIntervalId);
      this.loopIntervalId = -1;
    }
    this.engine.stop();
    this.nativeRenderer.destroy();
    this.audio.destroy();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      XComponent({
        id: 'gameSurface',
        type: xcomponent.XComponentType.SURFACE,
        controller: this.xComponentController
      })
        .width(this.screenW)
        .height(this.screenH)
        .hitTestBehavior(HitTestMode.Transparent)
        .onLoad(() => {
          console.log('[Index] XComponent onLoad');
          this.nativeRenderer.loadModule();
          this.nativeRenderer.init(this.pixelW, this.pixelH);
          try {
            this.tryInitEngine();
          } catch (initErr) {
            console.error('[Index] tryInitEngine FAILED: ' + String(initErr));
            console.error('[Index] Error stack: ' + (initErr as Error).stack);
          }
        })
        .onTouch((event: TouchEvent) => {
          for (let i: number = 0; i < event.touches.length; i++) {
            const touch: TouchObject = event.touches[i];
            const action: number = event.type === TouchType.Down ? 0 :
                                   event.type === TouchType.Move ? 1 : 2;
            this.nativeRenderer.touchInput(
              touch.id, action,
              vp2px(touch.x), vp2px(touch.y)
            );
          }
        })

      this.WeaponFormView()

      this.InventoryBarView()

      this.TopBarView()

      this.JoystickView()

      this.ActionButtonsView()

      if (this.engulfWarning) {
        this.EngulfWarningView()
      }

      if (this.showSettings) {
        SettingsOverlay({
          soundEnabled: this.soundEnabled,
          effectsEnabled: this.effectsEnabled,
          username: this.username,
          engine: this.engine,
          audio: this.audio,
          settings: this.settings,
          onClose: () => { this.showSettings = false; }
        })
      }

      if (this.showEvolution) {
        EvolutionOverlay({
          branchNames: this.branchNames,
          evoBranch: this.evoBranch,
          evoLevel: this.evoLevel,
          evoOreHave: this.evoOreHave,
          evoOreNeed: this.evoOreNeed,
          evoNormalHave: this.evoNormalHave,
          evoNormalNeed: this.evoNormalNeed,
          evoRareHave: this.evoRareHave,
          evoRareNeed: this.evoRareNeed,
          evoFormCore: this.evoFormCore,
          evoMaxLevel: this.evoMaxLevel,
          lockedForms: this.lockedForms,
          currentWeaponForm: this.currentWeaponForm,
          gameScene: this.gameScene,
          weaponFormNames: this.weaponFormNames,
          onClose: () => { this.showEvolution = false; },
          onRefreshState: () => { this.refreshEvoState(); },
          onSelectBranch: (index: number) => { this.evoBranch = index; }
        })
      }

      this.TransformButtonView()
      this.TransformEnergyBarView()
      this.FormSelectPanel()
      this.TransformUnlockNotification()

      if (this.showPauseMenu) {
        PauseMenuOverlay({
          onResume: () => { this.resumeGame(); },
          onClosed: () => { this.showPauseMenu = false; },
          onLoadGame: (data: SaveData) => { this.handleLoadGame(data); }
        })
      }

      if (this.showGameOver) {
        GameOverOverlay({
          deathLevel: this.deathLevel,
          deathChunks: this.deathChunks,
          onRestart: () => { this.restartGame(); this.showGameOver = false; },
          onLoadGame: (data: SaveData) => { this.handleLoadGame(data); this.showGameOver = false; },
          onQuit: () => { this.quitGame(); }
        })
      }

      if (this.showSaveIndicator) {
        SaveIndicator({ screenW: this.screenW })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }

  @Builder
  WeaponFormView() {
    Stack() {
      Column() {
        Text(this.getWeaponFormName(this.currentWeaponForm))
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
        this.cycleWeaponForm();
      }
    })
    .position({ x: 10, y: this.screenH * 0.50 })
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
    .position({ x: 10, y: this.screenH * 0.58 })
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
              .width(this.playerLevel > 0 ? 80 * (this.playerXp / LEVEL_UP_XP) : 0)
              .height(5)
              .backgroundColor('#fbbf24')
              .borderRadius(2)
          }
          .width(80)
          .height(5)

          Text(this.playerXp + '/' + LEVEL_UP_XP)
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
    .position({ x: this.screenW - 74, y: 10 })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pauseGame();
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
    .position({ x: this.screenW - 110, y: 10 })
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
    .position({ x: 20, y: this.screenH * 0.66 })
    .onTouch((event: TouchEvent) => {
      this.handleJoystickTouch(event);
    })
  }

  @Builder
  ActionButtonsView() {
    // 全屏透明包裹层：按钮全部用 position() 悬浮定位，必须给包裹层真实尺寸，
    // 否则 0×0 容器会把命中测试困在自身边界内（子组件悬在边界外可能点不到）。
    // Transparent 保证不遮挡下方同层的摇杆与游戏 Canvas。
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
      .position({ x: this.screenW - 66, y: this.screenH * 0.82 })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.engine.setInputAttack(true);
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
      .position({ x: this.screenW - 120, y: this.screenH * 0.73 })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.engine.setInputJump(true);
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
      .position({ x: this.screenW - 120, y: this.screenH * 0.88 })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down && this.dashReady) {
          this.engine.setInputDash(true);
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
      .position({ x: this.screenW - 66, y: this.screenH * 0.66 })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down && this.toolReady) {
          this.engine.setInputTool(true);
          this.toolReady = false;
          setTimeout(() => {
            this.toolReady = true;
          }, 200);
        }
      })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
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
    .position({ x: this.screenW * 0.05, y: this.screenH * 0.43 })
  }

  private refreshEvoState(): void {
    const player: Entity | null = this.getPlayerEntity();
    if (player === null) return;

    this.evoBranch = this.gameScene!.getEvolutionSystem().getEvoBranch(player);
    this.evoLevel = this.gameScene!.getEvolutionSystem().getEvoLevel(player);
    this.evoOreHave = this.gameScene!.getEvolutionSystem().getEvoOreHave(player);

    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    if (evo !== null) {
      const level: number = evo.evolutionLevel;
      if (level >= 3) {
        this.evoOreNeed = 0;
        this.evoNormalNeed = 0;
        this.evoRareNeed = 0;
      } else {
        const EVOLUTION_COST_ORE: number[] = [0, 2, 4, 6];
        const EVOLUTION_COST_NORMAL: number[] = [0, 3, 0, 0];
        const EVOLUTION_COST_RARE: number[] = [0, 0, 1, 2];
        this.evoOreNeed = EVOLUTION_COST_ORE[level + 1];
        this.evoNormalNeed = EVOLUTION_COST_NORMAL[level + 1];
        this.evoRareNeed = EVOLUTION_COST_RARE[level + 1];
      }

      const unlocked: number[] = evo.unlockedForms.slice();
      const allForms: number[] = [0, 1, 2, 3, 4, 5];
      this.lockedForms = allForms.filter((f: number) => unlocked.indexOf(f) < 0);
    }

    const inv: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
    if (inv !== null) {
      this.evoNormalHave = inv.coreNormal;
      this.evoRareHave = inv.coreRare;
      this.evoFormCore = inv.formCore;
    }

    this.evoMaxLevel = this.evoLevel >= 3;
  }

  onCanvasTickChange(): void {
    // 1. 收集绘制命令（所有 renderer 写入 cmdBuffer）
    this.cmdBuffer.clear();
    if (this.gameScene !== null) {
      this.gameScene.collectCommands(this.cmdBuffer);
    }
    // 2. 提交到原生渲染器
    this.nativeRenderer.beginFrame();
    if (this.gameScene !== null) {
      const world: World = this.gameScene.getWorld();
      this.nativeRenderer.setCamera(world.cameraX, world.cameraY, 1.0);
    }
    this.nativeRenderer.submitCommands(this.cmdBuffer.getCommands());
    this.nativeRenderer.endFrame();
  }

  private tryInitEngine(): void {
    console.log('[Index] tryInitEngine CALLED');

    if (this.gameScene !== null) {
      console.log('[Index] Engine already initialized, skipping');
      return;
    }

    console.log('[Index] XComponent ready, starting initialization...');
    try {
      const harmonyCtx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      console.log('[Index] Step 1: Creating GameScene...');
      this.gameScene = new GameScene(this.audio, this.settings, harmonyCtx);
      console.log('[Index] Step 2: GameScene created successfully');

      console.log('[Index] Step 3: Pushing scene to engine...');
      this.engine.sceneManager.pushScene(this.gameScene);
      console.log('[Index] Step 4: Scene pushed successfully');

      console.log('[Index] Step 5: Calling engine.init() with pixelW=' + this.pixelW + ' pixelH=' + this.pixelH);
      this.engine.init(this.gameCtx, this.minimapCtx, this.pixelW, this.pixelH);
      // 使用外部循环：setInterval 只更新游戏状态，onCanvasTickChange 中执行原生渲染
      this.engine.setExternalLoop(true);
      console.log('[Index] Step 6: Engine.init() completed - starting external loop');

      // 外部游戏循环：每帧更新游戏状态
      this.lastTickTime = Date.now();
      this.loopIntervalId = setInterval(() => {
        const now: number = Date.now();
        const dt: number = (now - this.lastTickTime) / 1000.0;
        this.lastTickTime = now;
        this.engine.tick(dt);
        this.canvasTick++;
      }, 33);
      console.log('[Index] External game loop started at ~30fps');

      console.log('[Index] Step 7: Starting sprite generation...');
      this.gameScene.initSprites(this.nativeRenderer).then(() => {
        console.log('[Index] Step 8: Sprite generation complete');
      }).catch((err: Error) => {
        console.error('[Index] Sprite generation FAILED: ' + String(err));
      });

      console.log('[Index] Step 9: Starting status monitor...');
      this.startStatusMonitor();

      if (!this.isNewGame) {
        console.log('[Index] Step 10: Loading saved game...');
        SaveManager.load(harmonyCtx).then((data: Object | null) => {
          if (data !== null) {
            console.log('[Index] Step 11: Save data loaded');
            this.handleLoadGame(data as SaveData);
          } else {
            console.log('[Index] Step 11: No save data found');
          }
        }).catch((err: Error) => {
          console.error('[Index] Save load FAILED: ' + String(err));
        });
      } else {
        console.log('[Index] New game mode, skipping save load');
      }

      console.log('[Index] INITIALIZATION COMPLETE - game loop is running');
    } catch (e) {
      console.error('[Index] tryInitEngine EXCEPTION: ' + String(e));
      console.error('[Index] Error stack: ' + (e as Error).stack);
    }
  }

  private joyPointerId: number = -1;

  private handleJoystickTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      if (event.changedTouches.length === 0) return;
      const touch: TouchObject = event.changedTouches[0];
      this.joyPointerId = touch.id;
      this.joyCenterX = touch.x;
      this.joyCenterY = touch.y;
      this.joyActive = true;
      this.joyKnobX = 0;
      this.joyKnobY = 0;
      this.engine.setInputJoy(true, 0, 0);
    } else if (event.type === TouchType.Move && this.joyActive) {
      // 只跟踪按下摇杆的那根手指：touches[0] 可能是同时按住的其他按钮的手指
      const touch: TouchObject | null = this.findTouchById(event, this.joyPointerId);
      if (touch === null) return;
      let dx: number = touch.x - this.joyCenterX;
      let dy: number = touch.y - this.joyCenterY;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist > JOYSTICK_RADIUS) {
        dx = (dx / dist) * JOYSTICK_RADIUS;
        dy = (dy / dist) * JOYSTICK_RADIUS;
      }
      this.joyKnobX = dx;
      this.joyKnobY = dy;
      this.engine.setInputJoy(true, dx / JOYSTICK_RADIUS, dy / JOYSTICK_RADIUS);
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      const touch: TouchObject | null = this.findTouchById(event, this.joyPointerId);
      if (this.joyActive && touch === null && event.touches.length > 0) {
        // 抬起的是别的手指，摇杆仍在操作中
        return;
      }
      this.joyActive = false;
      this.joyPointerId = -1;
      this.joyKnobX = 0;
      this.joyKnobY = 0;
      this.engine.setInputJoy(false, 0, 0);
    }
  }

  private findTouchById(event: TouchEvent, pointerId: number): TouchObject | null {
    const all: TouchObject[] = event.touches;
    for (let i: number = 0; i < all.length; i++) {
      if (all[i].id === pointerId) {
        return all[i];
      }
    }
    const changed: TouchObject[] = event.changedTouches;
    for (let i: number = 0; i < changed.length; i++) {
      if (changed[i].id === pointerId) {
        return changed[i];
      }
    }
    return null;
  }

  private startStatusMonitor(): void {
    this.monitorIntervalId = setInterval(() => {
      if (this.gameScene === null) return;
      const world: World = this.gameScene.getWorld();

      // Game state
      const gsEntity: Entity | null = world.findEntityByTag("gameState");
      if (gsEntity !== null) {
        const gs: GameStateComponent | null = gsEntity.getComponent<GameStateComponent>("gameState");
        if (gs !== null) {
          if (gs.state !== this.gameState) {
            this.gameState = gs.state;
            if (gs.state === GameState.PAUSED) {
              this.showPauseMenu = true;
            } else if (gs.state === GameState.GAME_OVER) {
              this.showGameOver = true;
              const player: Entity | null = this.getPlayerEntity();
              if (player !== null) {
                const xp: XpComponent | null = player.getComponent<XpComponent>("xp");
                if (xp !== null) {
                  this.deathLevel = xp.level;
                }
              }
              this.deathChunks = world.chunks.size;
            }
          }

          // Transform unlock notification
          if (gs.transformUnlockNotifyTimer > 0 && !this.transformUnlockActive) {
            this.transformUnlockActive = true;
            this.transformUnlockForm = gs.transformUnlockNotifyForm as TransformForm;
            setTimeout(() => { this.transformUnlockActive = false; }, 3000);
          }
        }
      }

      // Player state
      const player: Entity | null = this.getPlayerEntity();
      if (player === null) return;

      const health: HealthComponent | null = player.getComponent<HealthComponent>("Health");
      if (health !== null) {
        const hp: number = health.current;
        if (hp !== this.playerHp) {
          this.playerHp = hp;
        }
      }

      const xp: XpComponent | null = player.getComponent<XpComponent>("xp");
      if (xp !== null) {
        if (xp.xp !== this.playerXp) {
          this.playerXp = xp.xp;
        }
        if (xp.level !== this.playerLevel) {
          this.playerLevel = xp.level;
        }
      }

      const inv: InventoryComponent | null = player.getComponent<InventoryComponent>("inventory");
      if (inv !== null) {
        const branchOre: number = this.gameScene!.getEvolutionSystem().getEvoOreHave(player);
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

        // Compute unlocked transforms
        const unlocked: number[] = [];
        if (inv.transformCoreSlime > 0) unlocked.push(TransformForm.SLIME);
        if (inv.transformCoreGhost > 0) unlocked.push(TransformForm.GHOST);
        if (inv.transformCoreArmor > 0) unlocked.push(TransformForm.ARMOR);
        if (inv.transformCoreIronMan > 0) unlocked.push(TransformForm.IRON_MAN);
        if (unlocked.length !== this.unlockedTransforms.length) {
          this.unlockedTransforms = unlocked;
        }
      }

      // Transform state
      const transform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
      if (transform !== null) {
        const isT: boolean = transform.isTransformed;
        if (isT !== this.isTransformed) {
          this.isTransformed = isT;
        }
        if (isT) {
          if (transform.transformEnergy !== this.transformEnergy) {
            this.transformEnergy = transform.transformEnergy;
          }
          if (transform.transformForm !== this.transformForm) {
            this.transformForm = transform.transformForm as TransformForm;
          }
        }
        if (transform.transformCooldown !== this.transformCooldown) {
          this.transformCooldown = transform.transformCooldown;
        }

        // Update current weapon form
        if (transform.currentWeaponForm !== this.currentWeaponForm) {
          this.currentWeaponForm = transform.currentWeaponForm as WeaponForm;
        }
      }

      // Engulf warning
      const movement: MovementComponent | null = player.getComponent<MovementComponent>("movement");
      if (movement !== null) {
        if (movement.isEngulfed !== this.engulfWarning) {
          this.engulfWarning = movement.isEngulfed;
        }
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
    .position({ x: this.screenW - 180, y: this.screenH * 0.57 })
    .onClick(() => {
      const player: Entity | null = this.getPlayerEntity();
      if (player === null) return;

      const transform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
      if (transform === null) return;

      if (this.isTransformed) {
        transform.transformForm = TransformForm.NONE;
      } else if (this.unlockedTransforms.length === 1) {
        transform.transformForm = this.unlockedTransforms[0];
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
      .position({ x: this.screenW - 178, y: this.screenH * 0.53 })
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
              const player: Entity | null = this.getPlayerEntity();
              if (player !== null) {
                const transform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
                if (transform !== null) {
                  transform.transformForm = formId;
                }
              }
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
      .position({ x: (this.screenW - 260) / 2, y: this.screenH * 0.32 })
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
      .position({ x: (this.screenW - 180) / 2, y: this.screenH * 0.35 })
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

  private getPlayerEntity(): Entity | null {
    if (this.gameScene === null) return null;
    return this.gameScene.getWorld().findEntityByTag("player");
  }

  private getWeaponFormName(form: WeaponForm): string {
    return this.weaponFormNames[form] || 'Unknown';
  }

  private cycleWeaponForm(): void {
    const player: Entity | null = this.getPlayerEntity();
    if (player === null) return;

    const transform: TransformComponent | null = player.getComponent<TransformComponent>("transform");
    const evo: EvolutionComponent | null = player.getComponent<EvolutionComponent>("evolution");
    if (transform === null || evo === null) return;

    const forms: number[] = evo.unlockedForms;
    if (forms.length <= 1) return;

    let idx: number = 0;
    for (let i: number = 0; i < forms.length; i++) {
      if (forms[i] === transform.currentWeaponForm) {
        idx = i;
        break;
      }
    }
    const nextIdx: number = (idx + 1) % forms.length;
    transform.currentWeaponForm = forms[nextIdx];
    this.currentWeaponForm = forms[nextIdx] as WeaponForm;
  }

  private buildSystemContext(): SystemContext {
    if (this.gameScene === null) {
      throw new Error('GameScene not initialized');
    }
    const world: World = this.gameScene.getWorld();
    return {
      world: world,
      screenW: this.screenW,
      screenH: this.screenH,
      input: this.engine.input,
      audio: this.audio as Object,
      frameCount: this.engine.getFrameCount(),
      dt: 0
    };
  }

  private pauseGame(): void {
    if (this.gameScene === null) return;
    const gsEntity: Entity | null = this.gameScene.getWorld().findEntityByTag("gameState");
    if (gsEntity !== null) {
      const gs: GameStateComponent | null = gsEntity.getComponent<GameStateComponent>("gameState");
      if (gs !== null && gs.state === GameState.PLAYING) {
        gs.state = GameState.PAUSED;
        this.engine.stop();
      }
    }
  }

  private resumeGame(): void {
    if (this.gameScene === null) return;
    const gsEntity: Entity | null = this.gameScene.getWorld().findEntityByTag("gameState");
    if (gsEntity !== null) {
      const gs: GameStateComponent | null = gsEntity.getComponent<GameStateComponent>("gameState");
      if (gs !== null && gs.state === GameState.PAUSED) {
        gs.state = GameState.PLAYING;
        this.engine.startLoop();
      }
    }
  }

  private quitGame(): void {
    this.engine.stop();
    this.nativeRenderer.destroy();
    this.audio.destroy();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  private restartGame(): void {
    if (this.gameScene === null) return;

    const harmonyCtx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const newScene: GameScene = new GameScene(this.audio, this.settings, harmonyCtx);
    this.engine.sceneManager.replaceScene(newScene);
    this.gameScene = newScene;
    newScene.initSprites(this.nativeRenderer).catch((err: Error) => {
      console.error('[Index] Sprite re-init FAILED on restart: ' + String(err));
    });

    this.gameState = GameState.PLAYING;
    this.showPauseMenu = false;
    this.showGameOver = false;
    this.playerHp = PLAYER_MAX_HP;
    this.playerXp = 0;
    this.playerLevel = 1;
    this.isTransformed = false;
    this.transformForm = TransformForm.NONE;
    this.transformEnergy = TRANSFORM_MAX_ENERGY;
    this.transformCooldown = 0;
    this.currentWeaponForm = WeaponForm.BLADE;
  }

  private handleLoadGame(data: SaveData): void {
    const player: Entity | null = this.getPlayerEntity();
    if (player === null || this.gameScene === null) return;

    const sysCtx: SystemContext = this.buildSystemContext();
    this.gameScene.getSaveLoadSystem().applySaveData(player, data, sysCtx);
    this.resumeGame();
  }
}
