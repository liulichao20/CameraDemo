//
//  CameraMan.swift
//  Camera
//
//  Created by lichao_liu on 2017/12/20.
//  Copyright © 2017年 com.pa.com. All rights reserved.
//
import AVFoundation
import UIKit
import PhotosUI

protocol CameraManDelegate: class {
    func cameraManNotAvailabel(_ cameraMan:CameraMan)
    func cameraManDidStart(_cameraMan:CameraMan)
    func cameraMan(_ cameraMan:CameraMan,didChangeInput input: AVCaptureDeviceInput)
}

class CameraMan {
    weak var delegate: CameraManDelegate?
    
    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "no.hyper.ImagePicker.Camera.SessionQueue")
    
    var backCamera: AVCaptureDeviceInput?
    var frontCamera: AVCaptureDeviceInput?
    var stillImageOutput: AVCaptureStillImageOutput?
    var startOnFrontCamera: Bool = false
    
    deinit {
        stop()
    }
    
    func setup(_ startOnFrontCamera: Bool = false) {
        self.startOnFrontCamera = startOnFrontCamera
        checkPermission()
    }
    
    func setupDevices() {
        // Input
        AVCaptureDevice.devices().filter {
            return $0.hasMediaType(AVMediaType.video)
            }.forEach {
                switch $0.position {
                case .front:
                    self.frontCamera = try? AVCaptureDeviceInput(device: $0)
                case .back:
                    self.backCamera = try? AVCaptureDeviceInput(device: $0)
                default:
                    break
                }
        }
        
        // Output
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
    }
    
    func addInput(_ input: AVCaptureDeviceInput) {
        configurePreset(input)
        if session.canAddInput(input) {
            session.addInput(input)
            
            DispatchQueue.main.async {
                self.delegate?.cameraMan(self, didChangeInput: input)
            }
        }
    }
    
    // MARK: - Permission
    
    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch status {
        case .authorized:
            start()
        case .notDetermined:
            requestPermission()
        default:
            delegate?.cameraManNotAvailabel(self)
        }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.start()
                } else {
                    self.delegate?.cameraManNotAvailabel(self)
                }
            }
        }
    }
    
    // MARK: - Session
    
    var currentInput: AVCaptureDeviceInput? {
        return session.inputs.first as? AVCaptureDeviceInput
    }
    
    fileprivate func start() {
        // Devices
        setupDevices()
        
        guard let input = (self.startOnFrontCamera) ? frontCamera ?? backCamera : backCamera, let output = stillImageOutput else { return }
        
        addInput(input)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        queue.async {
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.delegate?.cameraManDidStart(_cameraMan: self)
            }
        }
    }
    
    func stop() {
        self.session.stopRunning()
    }
    
    func switchCamera(_ completion: (() -> Void)? = nil) {
        guard let currentInput = currentInput
            else {
                completion?()
                return
        }
        
        queue.async {
            guard let input = (currentInput == self.backCamera) ? self.frontCamera : self.backCamera
                else {
                    DispatchQueue.main.async {
                        completion?()
                    }
                    return
            }
            
            self.configure {
                self.session.removeInput(currentInput)
                self.addInput(input)
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func takePhoto(_ previewLayer: AVCaptureVideoPreviewLayer, completion: @escaping (_ image:UIImage?) -> Void) {
        guard let connection = stillImageOutput?.connection(with: AVMediaType.video) else { return }
        connection.videoOrientation = CameraHelper.videoOrientation()
        queue.async {
            self.stillImageOutput?.captureStillImageAsynchronously(from: connection) { buffer, error in
                guard let buffer = buffer, error == nil && CMSampleBufferIsValid(buffer),
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                    let image = UIImage(data: imageData)
                    else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                }
                completion(image)
            }
        }
    }
    
    func fixRevolve(image:UIImage) -> UIImage{
        if image.imageOrientation == .up{
            return image
        }
        
        var transform:CGAffineTransform = CGAffineTransform.identity
        switch image.imageOrientation {
        case .down,.downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        case .left,.leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
        case .right,.rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi / 2))
        default:
            break
        }
        switch image.imageOrientation {
        case .upMirrored,.downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored,.rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        let ctx:CGContext = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height),
                                      bitsPerComponent: image.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                      space: image.cgImage!.colorSpace!,
                                      bitmapInfo: image.cgImage!.bitmapInfo.rawValue)!
        ctx.concatenate(transform)
        switch image.imageOrientation {
        case .leftMirrored,.left,.rightMirrored,.right:
            ctx.draw(image.cgImage!, in: CGRect(x: 0,y: 0,width: image.size.height,height: image.size.width))
        default:
            ctx.draw(image.cgImage!, in: CGRect(x: 0,y: 0,width: image.size.width,height: image.size.height))
        }
        let cgimg:CGImage = ctx.makeImage()!
        let img:UIImage = UIImage(cgImage: cgimg)
        return img
        
    }
    
    func flash(_ mode: AVCaptureDevice.FlashMode) {
        guard let device = currentInput?.device, device.isFlashModeSupported(mode) else { return }
        queue.async {
            self.lock {
                device.flashMode = mode
            }
        }
    }
    
    func focus(_ point: CGPoint) {
        guard let device = currentInput?.device, device.isFocusModeSupported(AVCaptureDevice.FocusMode.locked) else { return }
        queue.async {
            self.lock {
                device.focusPointOfInterest = point
            }
        }
    }
    
    func zoom(_ zoomFactor: CGFloat) {
        guard let device = currentInput?.device, device.position == .back else { return }
        queue.async {
            self.lock {
                device.videoZoomFactor = zoomFactor
            }
        }
    }
    
    // MARK: - Lock
    func lock(_ block: () -> Void) {
        if let device = currentInput?.device, (try? device.lockForConfiguration()) != nil {
            block()
            device.unlockForConfiguration()
        }
    }
    
    // MARK: - Configure
    func configure(_ block: () -> Void) {
        session.beginConfiguration()
        block()
        session.commitConfiguration()
    }
    
    // MARK: - Preset
    func configurePreset(_ input: AVCaptureDeviceInput) {
        for asset in preferredPresets() {
            if input.device.supportsSessionPreset(AVCaptureSession.Preset(rawValue: asset)) && self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: asset)) {
                self.session.sessionPreset = AVCaptureSession.Preset(rawValue: asset)
                return
            }
        }
    }
    
    func preferredPresets() -> [String] {
        return [
            AVCaptureSession.Preset.high.rawValue,
            AVCaptureSession.Preset.high.rawValue,
            AVCaptureSession.Preset.low.rawValue
        ]
    }
}
