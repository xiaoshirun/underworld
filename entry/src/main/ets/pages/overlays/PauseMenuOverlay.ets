import { common } from '@kit.AbilityKit';
import { SaveData } from '../../game/GameConstants';
import { SaveManager } from '../../game/SaveManager';

@Component
export struct PauseMenuOverlay {
  onResume: () => void = () => {};
  onClosed: () => void = () => {};
  onSaveGame: () => SaveData | null = () => null;
  onLoadGame: (data: SaveData) => void = () => {};
  onDeleteSave: () => void = () => {};
  onQuit: () => void = () => {};
  @State saveLevel: number = 0;
  @State saveTime: string = '';
  @State hasSave: boolean = false;
  @State saveFeedback: string = '';
  @State confirmLoad: boolean = false;
  @State confirmDelete: boolean = false;

  aboutToAppear(): void {
    this.refreshSaveInfo();
  }

  private async refreshSaveInfo(): Promise<void> {
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const exists: boolean = await SaveManager.hasSave(ctx);
    this.hasSave = exists;
    if (exists) {
      const data: SaveData | null = await SaveManager.load(ctx);
      if (data) {
        this.saveLevel = data.level;
        this.saveTime = this.formatTimestamp(data.timestamp);
      }
    }
  }

  private formatTimestamp(ts: number): string {
    const d: Date = new Date(ts);
    const y: string = d.getFullYear().toString();
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    const h: string = d.getHours().toString().padStart(2, '0');
    const min: string = d.getMinutes().toString().padStart(2, '0');
    return y + '-' + m + '-' + day + ' ' + h + ':' + min;
  }

  build() {
    Stack() {
      Column() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000e8')
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
        }
      })

      Column() {
        Text('游戏暂停')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#fbbf24')
          .margin({ bottom: 16 })

        Button('继续游戏')
          .width(200)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#22c55e')
          .borderRadius(8)
          .margin({ bottom: 16 })
          .onClick(() => {
            this.onResume();
            this.onClosed();
          })

        Divider().color('#334155').margin({ left: 20, right: 20 })

        Text('存档管理')
          .fontSize(13)
          .fontColor('#64748b')
          .margin({ top: 12, bottom: 8 })

        if (this.hasSave) {
          Column() {
            Row() {
              Text('Lv.' + this.saveLevel)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#fbbf24')
              Blank()
              Text(this.saveTime)
                .fontSize(11)
                .fontColor('#64748b')
            }
            .width('100%')
          }
          .width(200)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#1e293be0')
          .borderRadius(8)
          .margin({ bottom: 10 })
        } else {
          Text('无存档')
            .fontSize(12)
            .fontColor('#475569')
            .margin({ bottom: 10 })
        }

        Row() {
          Button('保存')
            .layoutWeight(1)
            .height(38)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .backgroundColor('#3b82f6')
            .borderRadius(8)
            .margin({ right: 6 })
            .onClick(() => {
              const data: SaveData | null = this.onSaveGame();
              if (data) {
                this.saveFeedback = '已保存';
                this.saveLevel = data.level;
                this.saveTime = this.formatTimestamp(data.timestamp);
                this.hasSave = true;
                setTimeout(() => {
                  this.saveFeedback = '';
                }, 1500);
              }
            })

          Button('读取')
            .layoutWeight(1)
            .height(38)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .backgroundColor(this.hasSave ? '#3b82f6' : '#1e293b')
            .borderRadius(8)
            .margin({ left: 6 })
            .enabled(this.hasSave && !this.confirmLoad)
            .onClick(() => {
              if (this.hasSave) {
                this.confirmLoad = true;
              }
            })
        }
        .width(200)
        .margin({ bottom: 6 })

        if (this.saveFeedback.length > 0) {
          Text(this.saveFeedback)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#22c55e')
            .margin({ bottom: 6 })
        }

        if (this.confirmLoad) {
          Column() {
            Text('读取将丢失当前进度，确认？')
              .fontSize(12)
              .fontColor('#fbbf24')
              .margin({ bottom: 8 })

            Row() {
              Button('确认')
                .layoutWeight(1)
                .height(32)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ffffff')
                .backgroundColor('#ef4444')
                .borderRadius(6)
                .margin({ right: 4 })
                .onClick(async () => {
                  this.confirmLoad = false;
                  const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
                  const data: SaveData | null = await SaveManager.load(ctx);
                  if (data) {
                    this.onLoadGame(data);
                    this.onClosed();
                  }
                })

              Button('取消')
                .layoutWeight(1)
                .height(32)
                .fontSize(13)
                .fontColor('#94a3b8')
                .backgroundColor('#1e293b')
                .borderRadius(6)
                .margin({ left: 4 })
                .onClick(() => {
                  this.confirmLoad = false;
                })
            }
            .width('100%')
          }
          .width(200)
          .padding(10)
          .backgroundColor('#1e293be0')
          .borderRadius(8)
          .margin({ bottom: 6 })
        }

        if (this.hasSave) {
          if (this.confirmDelete) {
            Column() {
              Text('确定删除存档？不可恢复')
                .fontSize(12)
                .fontColor('#ef4444')
                .margin({ bottom: 8 })

              Row() {
                Button('确认删除')
                  .layoutWeight(1)
                  .height(32)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#ffffff')
                  .backgroundColor('#dc2626')
                  .borderRadius(6)
                  .margin({ right: 4 })
                  .onClick(async () => {
                    this.confirmDelete = false;
                    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
                    await SaveManager.deleteSave(ctx);
                    this.onDeleteSave();
                    this.hasSave = false;
                    this.saveLevel = 0;
                    this.saveTime = '';
                  })

                Button('取消')
                  .layoutWeight(1)
                  .height(32)
                  .fontSize(13)
                  .fontColor('#94a3b8')
                  .backgroundColor('#1e293b')
                  .borderRadius(6)
                  .margin({ left: 4 })
                  .onClick(() => {
                    this.confirmDelete = false;
                  })
              }
              .width('100%')
            }
            .width(200)
            .padding(10)
            .backgroundColor('#1e293be0')
            .borderRadius(8)
            .margin({ bottom: 6 })
          } else {
            Text('删除存档')
              .fontSize(12)
              .fontColor('#ef4444')
              .margin({ top: 4, bottom: 8 })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.confirmDelete = true;
                }
              })
          }
        }

        Divider().color('#334155').margin({ left: 20, right: 20 })

        Button('退出游戏')
          .width(200)
          .height(40)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .backgroundColor('#6b7280')
          .borderRadius(8)
          .margin({ top: 12 })
          .onClick(() => {
            this.onQuit();
          })
      }
      .width(260)
      .padding(24)
      .backgroundColor('#0a0a15')
      .borderRadius(12)
      .border({ width: 2, color: '#7c3aed' })
    }
    .width('100%')
    .height('100%')
  }
}
