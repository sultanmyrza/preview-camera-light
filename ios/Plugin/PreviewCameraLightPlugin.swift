import Foundation
import Capacitor
import AVFoundation
import Photos

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(PreviewCameraLightPlugin)
public class PreviewCameraLightPlugin: CAPPlugin, AVCapturePhotoCaptureDelegate {
    private let implementation = PreviewCameraLight()
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var photoOutput: AVCapturePhotoOutput?
    
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
                guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No video device available"])
                }
                
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                
                self.captureSession = AVCaptureSession()
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                self.previewLayer?.videoGravity = .resizeAspectFill
                
                guard let captureSession = self.captureSession else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create capture session"])
                }
                
                if (captureSession.canAddInput(videoInput)) {
                    captureSession.addInput(videoInput)
                } else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't add video input"])
                }
                
                let photoOutput = AVCapturePhotoOutput()
                if (captureSession.canAddOutput(photoOutput)) {
                    captureSession.addOutput(photoOutput)
                    self.photoOutput = photoOutput  // make sure to define this property
                } else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't add photo output"])
                }
                
                if let bridge = self.bridge {
                    for item in bridge.webView!.getAllSubViews() {
                        let isScrollView = item.isKind(of: NSClassFromString("WKChildScrollView")!) || item.isKind(of: NSClassFromString("WKScrollView")!)
                        let isBridgeScrollView = item.isEqual(bridge.webView?.scrollView)
                        
                        if isScrollView && !isBridgeScrollView {
                            if item.tag == 0 {
                                self.targetViewController = item
                                break
                            }
                        }
                    }
                    
                    if let target = self.targetViewController, let previewLayer = self.previewLayer {
                        target.tag = 1
                        target.removeAllSubView()
                        target.layer.addSublayer(previewLayer)
                        previewLayer.frame = target.bounds
                    }
                }
                
                captureSession.startRunning()
                call.resolve()
                
            } catch {
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
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            print("Failed to convert image data to UIImage")
            return
        }
        let fileName = UUID().uuidString + ".jpg"
        let tempDir = NSTemporaryDirectory()
        let imageURL = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: imageURL)
            // Notify listeners of the saved image path
            self.notifyListeners("captureSuccessResult", data: ["path": imageURL.path, "name": fileName, "mimeType": "image/jpeg", "size": imageData.count])
        } catch {
            print("Failed to write image data to temporary file: \(error)")
            self.notifyListeners("captureErrorResult", data: ["errorMessage": "Failed to save image to temporary directory: \(error.localizedDescription)"])
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
