# @sultanmyrza/preview-camera-lite

Capture photos/videos on iOS, Android and Web

## Install

```bash
npm install @sultanmyrza/preview-camera-lite
npx cap sync
```

## API

<docgen-index>

* [`echo(...)`](#echo)
* [`startPreview()`](#startpreview)
* [`stopPreview()`](#stoppreview)
* [`takePhoto()`](#takephoto)
* [`startRecord()`](#startrecord)
* [`stopRecord()`](#stoprecord)
* [`flipCamera()`](#flipcamera)
* [`requestPermissions()`](#requestpermissions)
* [`addListener('captureSuccessResult', ...)`](#addlistenercapturesuccessresult)
* [`addListener('captureErrorResult', ...)`](#addlistenercaptureerrorresult)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### echo(...)

```typescript
echo(options: { value: string; }) => Promise<{ value: string; }>
```

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ value: string; }</code> |

**Returns:** <code>Promise&lt;{ value: string; }&gt;</code>

--------------------


### startPreview()

```typescript
startPreview() => Promise<void>
```

--------------------


### stopPreview()

```typescript
stopPreview() => Promise<void>
```

--------------------


### takePhoto()

```typescript
takePhoto() => Promise<void>
```

--------------------


### startRecord()

```typescript
startRecord() => Promise<void>
```

--------------------


### stopRecord()

```typescript
stopRecord() => Promise<void>
```

--------------------


### flipCamera()

```typescript
flipCamera() => Promise<void>
```

--------------------


### requestPermissions()

```typescript
requestPermissions() => Promise<PermissionStatus>
```

**Returns:** <code>Promise&lt;<a href="#permissionstatus">PermissionStatus</a>&gt;</code>

--------------------


### addListener('captureSuccessResult', ...)

```typescript
addListener(eventName: 'captureSuccessResult', listenerFunc: CaptureSuccessResultListener) => Promise<PluginListenerHandle> & PluginListenerHandle
```

| Param              | Type                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'captureSuccessResult'</code>                                                   |
| **`listenerFunc`** | <code><a href="#capturesuccessresultlistener">CaptureSuccessResultListener</a></code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt; & <a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### addListener('captureErrorResult', ...)

```typescript
addListener(eventName: 'captureErrorResult', listenerFunc: CaptureErrorResultListener) => Promise<PluginListenerHandle> & PluginListenerHandle
```

| Param              | Type                                                                              |
| ------------------ | --------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'captureErrorResult'</code>                                                 |
| **`listenerFunc`** | <code><a href="#captureerrorresultlistener">CaptureErrorResultListener</a></code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt; & <a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### Interfaces


#### PermissionStatus

Represents the status of permissions required for camera and microphone access.
- `camera` permission is needed to take photo and record video without audio.
- `microphone` permission is needed to record video with audio.

| Prop             | Type                                                        |
| ---------------- | ----------------------------------------------------------- |
| **`camera`**     | <code><a href="#permissionstate">PermissionState</a></code> |
| **`microphone`** | <code><a href="#permissionstate">PermissionState</a></code> |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### CaptureSuccessResult

Represents the result of a successful capture operation.

| Prop           | Type                                     | Description                                                                     |
| -------------- | ---------------------------------------- | ------------------------------------------------------------------------------- |
| **`mimeType`** | <code>'image/jpeg' \| 'video/mp4'</code> | The MIME type of the captured media. Examples: "image/jpeg", "video/mp4".       |
| **`name`**     | <code>string</code>                      | The name of the captured media file. Examples: "my-photo.jpeg", "my-video.mp4". |
| **`path`**     | <code>string</code>                      | The path to the captured media file. Example: "file://path-to-my-video.mp4".    |
| **`size`**     | <code>number</code>                      | The size of the captured media file in bytes. Example: "7046447".               |


#### CaptureErrorResult

Represents the result of a failed capture operation.

| Prop               | Type                | Description                                            |
| ------------------ | ------------------- | ------------------------------------------------------ |
| **`errorMessage`** | <code>string</code> | The error message describing the cause of the failure. |


### Type Aliases


#### PermissionState

<code>'prompt' | 'prompt-with-rationale' | 'granted' | 'denied'</code>


#### CaptureSuccessResultListener

Represents the listener function for capturing success results.
Listener will be called after `takePhoto()` or `stopRecord()`

<code>(result: <a href="#capturesuccessresult">CaptureSuccessResult</a>): void</code>


#### CaptureErrorResultListener

Represents the listener function for capturing error results.
Listener will be called after `takePhoto()` or `stopRecord()`

<code>(result: <a href="#captureerrorresult">CaptureErrorResult</a>): void</code>

</docgen-api>
