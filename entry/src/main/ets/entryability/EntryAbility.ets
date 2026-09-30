import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'UnderworldGame', 'onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'UnderworldGame', 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'UnderworldGame', 'onWindowStageCreate');
    windowStage.loadContent('pages/LoginPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'UnderworldGame', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'UnderworldGame', 'Content loaded successfully');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'UnderworldGame', 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'UnderworldGame', 'onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'UnderworldGame', 'onBackground');
  }
}
