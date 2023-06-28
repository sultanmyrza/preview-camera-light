import { WebPlugin } from '@capacitor/core';

import type { PreviewCameraLightPlugin } from './definitions';

export class PreviewCameraLightWeb
  extends WebPlugin
  implements PreviewCameraLightPlugin
{
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
