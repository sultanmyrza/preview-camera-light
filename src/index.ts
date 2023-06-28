import { registerPlugin } from '@capacitor/core';

import type { PreviewCameraLightPlugin } from './definitions';

const PreviewCameraLight = registerPlugin<PreviewCameraLightPlugin>(
  'PreviewCameraLight',
  {
    web: () => import('./web').then(m => new m.PreviewCameraLightWeb()),
  },
);

export * from './definitions';
export { PreviewCameraLight };
