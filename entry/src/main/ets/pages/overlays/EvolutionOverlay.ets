import { Entity } from '@qiuyu/engine';
import { WeaponForm, EvolutionBranch, FORM_UNLOCK_COST } from '../../game/GameConstants';
import { EvolutionComponent } from '../../game/components/EvolutionComponent';
import { InventoryComponent } from '../../game/components/InventoryComponent';
import { GameScene } from '../../game/GameScene';

@Component
export struct EvolutionOverlay {
  @Prop branchNames: string[] = [];
  @Prop evoBranch: number = 0;
  @Prop evoLevel: number = 0;
  @Prop evoOreHave: number = 0;
  @Prop evoOreNeed: number = 0;
  @Prop evoNormalHave: number = 0;
  @Prop evoNormalNeed: number = 0;
  @Prop evoRareHave: number = 0;
  @Prop evoRareNeed: number = 0;
  @Prop evoFormCore: number = 0;
  @Prop evoMaxLevel: boolean = false;
  @Prop lockedForms: number[] = [];
  @Prop currentWeaponForm: WeaponForm = WeaponForm.BLADE;
  gameScene: GameScene | null = null;
  onClose: () => void = () => {};
  onRefreshState: () => void = () => {};
  onSelectBranch: (index: number) => void = () => {};
  weaponFormNames: string[] = [];

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

  private getPlayerEntity(): Entity | null {
    if (this.gameScene === null) return null;
    return this.gameScene.getWorld().findEntityByTag("player");
  }

  private getWeaponFormName(form: WeaponForm): string {
    return this.weaponFormNames[form] || 'Unknown';
  }

  build() {
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
              this.onClose();
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
          Text(this.getWeaponFormName(this.currentWeaponForm))
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
                this.onSelectBranch(index);
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
        .backgroundColor('#0f0f23')
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
          .backgroundColor('#0f0f23')
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
              const player: Entity | null = this.getPlayerEntity();
              if (player !== null && this.gameScene !== null) {
                if (this.gameScene.getEvolutionSystem().tryEvolveWeapon(player)) {
                  this.onRefreshState();
                }
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
          .backgroundColor('#0f0f23')
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
              Text(this.getWeaponFormName(formIndex as WeaponForm))
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
                  const player: Entity | null = this.getPlayerEntity();
                  if (player !== null && this.gameScene !== null) {
                    this.gameScene.getEvolutionSystem().unlockWeaponForm(player, formIndex as WeaponForm);
                    this.onRefreshState();
                  }
                }
              })
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          })
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#0f0f23')
        .borderRadius(4)
        .border({ width: 2, color: '#334155' })
        .margin({ top: 8 })

        Blank()
      }
      .width('85%')
      .padding(14)
      .backgroundColor('#0a0a15')
      .borderRadius(6)
      .border({ width: 3, color: '#7c3aed' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000e8')
  }
}
