export interface PreviewCameraLightPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
