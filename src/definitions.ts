import type { PluginListenerHandle } from '@capacitor/core';

export interface PreviewCameraLightPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
  startPreview(): Promise<void>;
  stopPreview(): Promise<void>;
  takePhoto(): Promise<void>;
  startRecord(): Promise<void>;
  stopRecord(): Promise<void>;
  flipCamera(): Promise<void>;
  requestPermissions(): Promise<PermissionStatus>;
  addListener(
    eventName: 'captureSuccessResult',
    listenerFunc: CaptureSuccessResultListener,
  ): Promise<PluginListenerHandle> & PluginListenerHandle;
  addListener(
    eventName: 'captureErrorResult',
    listenerFunc: CaptureErrorResultListener,
  ): Promise<PluginListenerHandle> & PluginListenerHandle;
}

/**
 * Represents the listener function for capturing success results.
 * Listener will be called after `takePhoto()` or `stopRecord()`
 * @param result The result of a successful capture operation.
 */
export type CaptureSuccessResultListener = (
  result: CaptureSuccessResult,
) => void;

/**
 * Represents the listener function for capturing error results.
 * Listener will be called after `takePhoto()` or `stopRecord()`
 * @param result The result of a failed capture operation.
 *
 */
export type CaptureErrorResultListener = (result: CaptureErrorResult) => void;

/**
 * Represents the result of a successful capture operation.
 */
export interface CaptureSuccessResult {
  /**
   * The MIME type of the captured media.
   * Examples: "image/jpeg", "video/mp4".
   */
  mimeType: 'image/jpeg' | 'video/mp4';

  /**
   * The name of the captured media file.
   * Examples: "my-photo.jpeg", "my-video.mp4".
   */
  name: string;

  /**
   * The path to the captured media file.
   * Example: "file://path-to-my-video.mp4".
   */
  path: string;

  /**
   * The size of the captured media file in bytes.
   * Example: "7046447".
   */
  size: number;
}

/**
 * Represents the result of a failed capture operation.
 */
export interface CaptureErrorResult {
  /**
   * The error message describing the cause of the failure.
   */
  errorMessage: string;
}

/**
 * Represents the status of permissions required for camera and microphone access.
 * - `camera` permission is needed to take photo and record video without audio.
 * - `microphone` permission is needed to record video with audio.
 */
export interface PermissionStatus {
  camera: PermissionState;
  microphone: PermissionState;
}
