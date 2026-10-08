import { common } from '@kit.AbilityKit';
import preferences from '@ohos.data.preferences';
import { SaveData } from './GameConstants';

const SAVE_STORE_NAME: string = 'game_save';
const SAVE_KEY: string = 'save_data';

export class SaveManager {
  static async save(ctx: common.UIAbilityContext, data: SaveData): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(ctx, SAVE_STORE_NAME);
      const json: string = JSON.stringify(data);
      await prefs.put(SAVE_KEY, json);
      await prefs.flush();
    } catch (e) {
      console.error('[SaveManager] save error:', e);
    }
  }

  static async load(ctx: common.UIAbilityContext): Promise<SaveData | null> {
    try {
      const prefs = await preferences.getPreferences(ctx, SAVE_STORE_NAME);
      const json = await prefs.get(SAVE_KEY, '') as string;
      if (json.length === 0) {
        return null;
      }
      const data: SaveData = JSON.parse(json) as SaveData;
      return data;
    } catch (e) {
      console.error('[SaveManager] load error:', e);
      return null;
    }
  }

  static async deleteSave(ctx: common.UIAbilityContext): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(ctx, SAVE_STORE_NAME);
      await prefs.delete(SAVE_KEY);
      await prefs.flush();
    } catch (e) {
      console.error('[SaveManager] deleteSave error:', e);
    }
  }

  static async hasSave(ctx: common.UIAbilityContext): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(ctx, SAVE_STORE_NAME);
      const json = await prefs.get(SAVE_KEY, '') as string;
      return json.length > 0;
    } catch (e) {
      return false;
    }
  }
}
