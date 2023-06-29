import { WebPlugin } from '@capacitor/core';

import type { PermissionStatus, PreviewCameraLightPlugin } from './definitions';

export class PreviewCameraLightWeb
  extends WebPlugin
  implements PreviewCameraLightPlugin
{
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
  startPreview(): Promise<void> {
    throw new Error('Method not implemented.');
  }
  stopPreview(): Promise<void> {
    throw new Error('Method not implemented.');
  }
  takePhoto(): Promise<void> {
    throw new Error('Method not implemented.');
  }
  startRecord(): Promise<void> {
    throw new Error('Method not implemented.');
  }
  stopRecord(): Promise<void> {
    throw new Error('Method not implemented.');
  }
  flipCamera(): Promise<void> {
    throw new Error('Method not implemented.');
  }
  requestPermissions(): Promise<PermissionStatus> {
    throw new Error('Method not implemented.');
  }
}
