import { router } from '@kit.ArkUI';
import { Engine } from '@qiuyu/engine';
import { AudioManager } from '../../game/AudioManager';
import { GameSettings } from '../../game/GameConstants';

@Component
export struct SettingsOverlay {
  @Prop soundEnabled: boolean = true;
  @Prop effectsEnabled: boolean = true;
  @Prop username: string = '';
  engine: Engine | null = null;
  audio: AudioManager | null = null;
  settings: GameSettings | null = null;
  onClose: () => void = () => {};

  build() {
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
              this.onClose();
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
              if (event.type === TouchType.Down && this.settings !== null && this.audio !== null) {
                this.settings.soundEnabled = !this.settings.soundEnabled;
                this.audio.setSettings(this.settings);
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
              if (event.type === TouchType.Down && this.settings !== null && this.audio !== null) {
                this.settings.effectsEnabled = !this.settings.effectsEnabled;
                this.audio.setSettings(this.settings);
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
            if (this.engine !== null) {
              this.engine.stop();
            }
            if (this.audio !== null) {
              this.audio.destroy();
            }
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
}
