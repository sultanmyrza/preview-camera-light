import Foundation
import Capacitor
import AVFoundation
import Photos

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(PreviewCameraLightPlugin)
public class PreviewCameraLightPlugin: CAPPlugin, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    private let implementation = PreviewCameraLight()
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    
    private var targetViewController: UIView?
    
    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": implementation.echo(value)
        ])
    }
    
    @objc func startPreview(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            do {
                // Check if video capture device is available
                guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No video device available"])
                }
                
                // Create a device input with the video capture device
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                
                // Check if audio capture device is available
                guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No audio device available"])
                }
                
                // Create a device input with the audio capture device
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                
                // Create a new AVCaptureSession
                self.captureSession = AVCaptureSession()
                
                // Create a new AVCaptureVideoPreviewLayer with the capture session
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                // Set the video gravity to maintain the aspect ratio
                self.previewLayer?.videoGravity = .resizeAspectFill
                
                guard let captureSession = self.captureSession else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create capture session"])
                }
                
                // Add video input to the capture session
                if (captureSession.canAddInput(videoInput)) {
                    captureSession.addInput(videoInput)
                } else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't add video input"])
                }
                
                // Add audio input to the capture session
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                } else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't add audio input"])
                }
                
                // Create a new AVCapturePhotoOutput
                let photoOutput = AVCapturePhotoOutput()
                // Add photo output to the capture session
                if (captureSession.canAddOutput(photoOutput)) {
                    captureSession.addOutput(photoOutput)
                    self.photoOutput = photoOutput  // make sure to define this property
                } else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't add photo output"])
                }
                
                // Create a new AVCaptureMovieFileOutput
                let movieOutput = AVCaptureMovieFileOutput()
                // Add movie output to the capture session
                if (captureSession.canAddOutput(movieOutput)) {
                    captureSession.addOutput(movieOutput)
                    self.movieOutput = movieOutput
                } else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't add movie output"])
                }
                
                // Check for web view and get all subviews
                if let bridge = self.bridge {
                    for item in bridge.webView!.getAllSubViews() {
                        let isScrollView = item.isKind(of: NSClassFromString("WKChildScrollView")!) || item.isKind(of: NSClassFromString("WKScrollView")!)
                        let isBridgeScrollView = item.isEqual(bridge.webView?.scrollView)
                        
                        // Look for a scroll view that is not the web view's scroll view and has a tag of 0
                        if isScrollView && !isBridgeScrollView {
                            if item.tag == 0 {
                                self.targetViewController = item
                                break
                            }
                        }
                    }
                    
                    // If a target view controller is found, remove all its subviews and add the preview layer to it
                    if let target = self.targetViewController, let previewLayer = self.previewLayer {
                        target.tag = 1
                        target.removeAllSubView()
                        target.layer.addSublayer(previewLayer)
                        previewLayer.frame = target.bounds
                    }
                }
                
                // Start the capture session
                captureSession.startRunning()
                call.resolve()
                
            } catch {
                // In case of error, reject the call with error message
                call.reject("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func stopPreview(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if let previewLayer = self.previewLayer {
                previewLayer.removeFromSuperlayer()
                self.previewLayer = nil
            }

            if let captureSession = self.captureSession {
                captureSession.stopRunning()
                self.captureSession = nil
            }

            if let target = self.targetViewController {
                target.tag = 0
            }

            call.resolve()
        }
    }
    
    @objc func takePhoto(_ call: CAPPluginCall) {
        let settings = AVCapturePhotoSettings()
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            self.notifyListeners("captureErrorResult", data: ["errorMessage": "Failed to get image data"])
            return
        }
        do {
            let fileName = UUID().uuidString + ".jpg"
            let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try imageData.write(to: filePath)
            self.notifyListeners("captureSuccessResult", data: ["path": filePath.path, "name": fileName, "mimeType": "image/jpeg", "size": imageData.count])
        } catch {
            self.notifyListeners("captureErrorResult", data: ["errorMessage": "Failed to save image to temporary directory: \(error.localizedDescription)"])
        }
    }
    
    @objc func startRecord(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let fileName = NSUUID().uuidString + ".mov"
            let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            self.movieOutput?.startRecording(to: filePath, recordingDelegate: self)
            call.resolve()
        }
    }

    @objc func stopRecord(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.movieOutput?.stopRecording()
            call.resolve()
        }
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            self.notifyListeners("captureErrorResult", data: ["errorMessage": "Failed to record video: \(error.localizedDescription)"])
        } else {
            self.notifyListeners("captureSuccessResult", data: ["path": outputFileURL.path])
        }
    }
    
    @objc override public func checkPermissions(_ call: CAPPluginCall) {
        var result: [String: Any] = [:]
        let cameraPermissionState = AVCaptureDevice.authorizationStatus(for: .video).authorizationState
        let microphonePermissionState = AVCaptureDevice.authorizationStatus(for: .audio).authorizationState
        result["camera"] = cameraPermissionState
        result["microphone"] = microphonePermissionState
        call.resolve(result)
    }
    
    @objc override public func requestPermissions(_ call: CAPPluginCall) {
        let group = DispatchGroup()
        group.enter()
        AVCaptureDevice.requestAccess(for: .video) { _ in
            group.leave()
        }
        group.enter()
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            group.leave()
        }
        group.notify(queue: DispatchQueue.main) { [weak self] in
            self?.checkPermissions(call)
        }
    }
}

internal protocol CameraAuthorizationState {
    var authorizationState: String { get }
}

extension AVAuthorizationStatus: CameraAuthorizationState {
    var authorizationState: String {
        switch self {
        case .denied, .restricted:
            return "denied"
        case .authorized:
            return "granted"
        case .notDetermined:
            fallthrough
        @unknown default:
            return "prompt"
        }
    }
}

extension UIView {
    private static var allSubviews: [UIView] = []
    
    private func viewArray(root: UIView) -> [UIView] {
        for view in root.subviews {
            if view.isKind(of: UIView.self) {
                UIView.allSubviews.append(view)
            }
            _ = viewArray(root: view)
        }
        return UIView.allSubviews
    }
    
    fileprivate func getAllSubViews() -> [UIView] {
        UIView.allSubviews = []
        return viewArray(root: self)
    }
    
    fileprivate func removeAllSubView() {
        subviews.forEach {
            $0.removeFromSuperview()
        }
    }
}
