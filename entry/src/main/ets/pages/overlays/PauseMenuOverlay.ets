import { common } from '@kit.AbilityKit';
import { SaveData } from '../../game/GameConstants';
import { SaveManager } from '../../game/SaveManager';

@Component
export struct PauseMenuOverlay {
  onResume: () => void = () => {};
  onClosed: () => void = () => {};
  onLoadGame: (data: SaveData) => void = () => {};
  onQuit: () => void = () => {};

  build() {
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
            this.onResume();
            this.onClosed();
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
            const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
            const data: SaveData | null = await SaveManager.load(ctx);
            if (data) {
              this.onLoadGame(data);
              this.onClosed();
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
            this.onQuit();
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
}
