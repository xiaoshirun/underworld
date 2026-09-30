import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { SaveData, SAVE_KEY, SAVE_PREF_NAME, SAVE_VERSION } from './GameConstants';

export class SaveManager {
  static async save(context: common.UIAbilityContext, data: SaveData): Promise<void> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(context, SAVE_PREF_NAME);
      const jsonStr: string = JSON.stringify(data);
      await pref.put(SAVE_KEY, jsonStr);
      await pref.flush();
    } catch (e) {
      console.error('SaveManager.save failed: ' + JSON.stringify(e));
    }
  }

  static async load(context: common.UIAbilityContext): Promise<SaveData | null> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(context, SAVE_PREF_NAME);
      const jsonStr: string = await pref.get(SAVE_KEY, '') as string;
      if (!jsonStr || jsonStr.length === 0) {
        return null;
      }
      const data: SaveData = JSON.parse(jsonStr) as SaveData;
      if (data.version !== SAVE_VERSION) {
        return null;
      }
      return data;
    } catch (e) {
      console.error('SaveManager.load failed: ' + JSON.stringify(e));
      return null;
    }
  }

  static async deleteSave(context: common.UIAbilityContext): Promise<void> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(context, SAVE_PREF_NAME);
      await pref.delete(SAVE_KEY);
      await pref.flush();
    } catch (e) {
      console.error('SaveManager.deleteSave failed: ' + JSON.stringify(e));
    }
  }
}
