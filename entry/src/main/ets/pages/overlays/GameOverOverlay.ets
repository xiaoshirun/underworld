import { common } from '@kit.AbilityKit';
import { SaveData } from '../../game/GameConstants';
import { SaveManager } from '../../game/SaveManager';

@Component
export struct GameOverOverlay {
  @Prop deathLevel: number = 1;
  @Prop deathChunks: number = 0;
  onRestart: () => void = () => {};
  onLoadGame: (data: SaveData) => void = () => {};
  onQuit: () => void = () => {};
  @State hasSave: boolean = false;

  aboutToAppear(): void {
    this.checkSave();
  }

  private async checkSave(): Promise<void> {
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.hasSave = await SaveManager.hasSave(ctx);
  }

  build() {
    Stack() {
      Column() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#500000ee')
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
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

        Text('探索: ' + this.deathChunks + ' 区域')
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
          .onClick(() => {
            this.onRestart();
          })

        if (this.hasSave) {
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
              const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
              const data: SaveData | null = await SaveManager.load(ctx);
              if (data) {
                this.onLoadGame(data);
              }
            })
        }

        Button('返回主页')
          .width(180)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#6b7280')
          .borderRadius(8)
          .onClick(() => {
            this.onQuit();
          })
      }
      .width(260)
      .padding(24)
      .backgroundColor('#0a0a15')
      .borderRadius(12)
      .border({ width: 3, color: '#dc2626' })
    }
    .width('100%')
    .height('100%')
  }
}
