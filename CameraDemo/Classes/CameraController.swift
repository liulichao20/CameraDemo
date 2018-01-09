//
//  CameraController.swift
//  Camera
//
//  Created by lichao_liu on 2017/12/22.
//  Copyright © 2017年 com.pa.com. All rights reserved.
//

import UIKit
import AVFoundation

open class AssetManager {
    
    open static func getImage(_ name: String) -> UIImage {
        let traitCollection = UITraitCollection(displayScale: 3)
        var bundle = Bundle(for: AssetManager.self)
        
        if let resource = bundle.resourcePath, let resourceBundle = Bundle(path: resource + "/CameraDemo.bundle") {
            bundle = resourceBundle
        }
        if let image = UIImage(named: name, in: bundle, compatibleWith: traitCollection) {
            return image 
        }else {
            return UIImage()
        }
        
    }
}
protocol CameraControllerDelegate:NSObjectProtocol {
    func doneButtonDidPress(_ cameraController:CameraController,image:UIImage)
    func cancelButtonDidPress(_ cameraController:CameraController)
}

public class CameraController: UIViewController {
    
    var blurView:UIVisualEffectView!
    var focusImageView:UIImageView!
    var capturedImageView:UIImageView!
    var containerView:UIView!
    
    lazy var noCameraLabel:UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "相机暂不可用"
        label.sizeToFit()
        return label
    }()
    
    lazy var noCameraButton:UIButton = {[unowned self] in
        let button = UIButton(type: .system)
        let title = NSAttributedString(string: "设置",
                                       attributes: [
                                        NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16),
                                        NSAttributedStringKey.foregroundColor: UIColor.orange
            ])
        
        button.setAttributedTitle(title, for: UIControlState())
        button.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 5.0, right: 10.0)
        button.sizeToFit()
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        
        return button
        }()
    
    lazy var topView:TopView = {[unowned self] in
        let view = TopView(configuration: self.configuration,frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 34))
        view.backgroundColor = UIColor.clear
        view.delegate = self
        return view
        }()
    
    lazy var bottomView:BottomView = {[unowned self] in
        let view = BottomView(frame:CGRect(x: 0, y: UIScreen.main.bounds.height - 100, width: UIScreen.main.bounds.width, height: 100),configuration: self.configuration, btnClickedBlock: { btnType in
            switch btnType {
            case BottomView.BottomViewBtnType.done:
                self.dismiss(animated: true, completion: nil)
            case BottomView.BottomViewBtnType.cancel:
                self.dismiss(animated: true, completion: nil)
            case BottomView.BottomViewBtnType.takePhoto:
                self.takePicture { image in
                    
                }
            case BottomView.BottomViewBtnType.rePhoto:
                self.capturedImageView.isHidden = true
                self.previewLayer?.isHidden = false
            case BottomView.BottomViewBtnType.rotation:
                self.rotateCamera()
            }
        })
        return view
        }()
    
    lazy var tapGestureRecognizer:UITapGestureRecognizer = {[unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action:#selector(tapGestureRecognizerHandle(gesture:)))
        return gesture
        }()
    
    lazy var pinchGestureRecognizer:UIPinchGestureRecognizer = {[unowned self] in
        let gesture = UIPinchGestureRecognizer()
        gesture.addTarget(self, action: #selector(pinchGestureRecognizerHandle(gesture:)))
        return gesture
        }()
    
    var previewLayer:AVCaptureVideoPreviewLayer?
    weak var delegate:CameraControllerDelegate?
    var animationTimer:Timer?
    var startOnFrontCamera:Bool = false
    var allowPinchToZoom:Bool = true
    
    var minimZoomFactor:CGFloat = 1
    var maximumZoomFactor:CGFloat = 3
    var currentZoomFactor:CGFloat = 1
    var previousZoomFactor:CGFloat = 1
    
    var configuration:Configuration = Configuration()
   public init(configuration: Configuration? = nil) {
        if let config = configuration {
            self.configuration = config
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    var cameraMan = CameraMan()
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
        setUpView()
        view.addSubview(containerView)
        containerView.addSubview(topView)
        view.addSubview(bottomView)
        view.addGestureRecognizer(tapGestureRecognizer)
        if allowPinchToZoom {
            view.addGestureRecognizer(pinchGestureRecognizer)
        }
        cameraMan.delegate = self
        cameraMan.setup(startOnFrontCamera)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRotation(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setUpView() {
        let containerViewFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 100)
        containerView = UIView()
        containerView.backgroundColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
        containerView.frame = containerViewFrame
        
        let effect = UIBlurEffect(style: .light)
        blurView = UIVisualEffectView(effect: effect)
        blurView.frame = containerViewFrame
        blurView.alpha = 0.8
        blurView.isHidden = true
        
        capturedImageView = UIImageView()
        capturedImageView.backgroundColor = UIColor.clear
        capturedImageView.contentMode = .scaleAspectFill
        capturedImageView.isHidden = true
        capturedImageView.frame = containerViewFrame
        
        focusImageView = UIImageView()
        focusImageView.backgroundColor = UIColor.clear
        
        focusImageView.image = AssetManager.getImage("focusIcon")
        focusImageView.alpha = 0
        focusImageView.frame = CGRect(x: 0, y: 0, width: 110, height: 110)
        
        [blurView,focusImageView,capturedImageView].forEach {
            containerView.addSubview($0)
        }
    }
    
    @objc func tapGestureRecognizerHandle(gesture:UITapGestureRecognizer){
        focusTo(gesture.location(in: view))
    }
    
    @objc func pinchGestureRecognizerHandle(gesture:UIPinchGestureRecognizer){
        switch gesture.state {
        case .began:
            fallthrough
        case .changed:
            zoomTo(gesture.scale)
        case .ended:
            zoomTo(gesture.scale)
            previousZoomFactor = currentZoomFactor
        default:
            break
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer?.connection?.videoOrientation = .portrait
        applyOrientationTransforms()
    }
    
    func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: cameraMan.session)
        layer.backgroundColor = UIColor.black.cgColor
        layer.autoreverses = true
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        containerView.layer.insertSublayer(layer, at: 0)
        layer.frame = containerView.layer.frame
        view.clipsToBounds = true
        previewLayer = layer
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let centerX = view.bounds.width/2
        noCameraLabel.center = CGPoint(x: centerX, y: view.bounds.height/2-80)
        noCameraButton.center = CGPoint(x: centerX, y: noCameraLabel.frame.maxY + 20)
        
        
    }
    
    @objc func settingsButtonTapped() {
        if let url = URL(string: UIApplicationOpenSettingsURLString){
            UIApplication.shared.openURL(url)
        }
    }
    
    func rotateCamera() {
        blurView.isHidden = false
        UIView.transition(with: self.containerView, duration: 1, options: .transitionFlipFromRight, animations: {
            self.cameraMan.switchCamera({
                self.blurView.isHidden = true
            })
        }) { _ in
        }
    }
    
    func flashCamera(_ title:String) {
        let mapping:[String:AVCaptureDevice.FlashMode] = [
            "ON":.on,"OFF":.off
        ]
        cameraMan.flash(mapping[title] ?? .auto)
    }
    
    func takePicture(_ completion: @escaping(_ image:UIImage?)->Void) {
        guard let previewLayer = previewLayer else {
            return
        }
        self.capturedImageView.image = nil
        self.blurView.isHidden = false
        
        cameraMan.takePhoto(previewLayer) { (image) in
            completion(image)
            self.previewLayer?.isHidden = true
            self.blurView.isHidden = true
            self.capturedImageView.isHidden = false
            self.capturedImageView.image = image
        }
    }
    
    @objc func timerDidFire() {
        UIView.animate(withDuration: 0.3, animations: {
            self.focusImageView.alpha = 0
        }) { _ in
            self.focusImageView.transform = .identity
        }
    }
    
    func focusTo(_ point:CGPoint) {
        focusImageView.transform = .identity
        animationTimer?.invalidate()
        
        let convertedPoint = CGPoint(x: point.x/UIScreen.main.bounds.width, y: point.y/UIScreen.main.bounds.height)
        cameraMan.focus(convertedPoint)
        focusImageView.center = point
        
        UIView.animate(withDuration: 0.5, animations: {
            self.focusImageView.alpha = 1
            self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }) { _ in
            self.animationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerDidFire), userInfo: nil, repeats: false)
        }
    }
    
    func zoomTo(_ zoomFactor:CGFloat) {
        guard  let device = cameraMan.currentInput?.device else {
            return
        }
        let maximumDeviceZoomFactor = device.activeFormat.videoMaxZoomFactor
        let newZoomFactor = previousZoomFactor * zoomFactor
        currentZoomFactor = min(maximumZoomFactor, max(minimZoomFactor,min(newZoomFactor,maximumDeviceZoomFactor)))
        cameraMan.zoom(currentZoomFactor)
    }
    
    func showNoCamera(_ show:Bool) {
        let centerX = view.bounds.width / 2
        noCameraLabel.center = CGPoint(x: centerX,
                                       y: view.bounds.height / 2 - 80)
        noCameraButton.center = CGPoint(x: centerX,
                                        y: noCameraLabel.frame.maxY + 20)
        [noCameraButton,noCameraLabel].forEach {
            show ? self.view.addSubview($0) : $0.removeFromSuperview()
        }
    }
    
    @objc func handleRotation(_ note:Notification) {
        applyOrientationTransforms()
    }
    
    func applyOrientationTransforms() {
        let rotate = configuration.rotationTransform
        UIView.animate(withDuration: 0.25) {
            [self.bottomView.cancelBtn,self.bottomView.rePhotoeBtn,self.bottomView.doneBtn,self.bottomView.takePhotoBtn,self.bottomView.rotationBtn].forEach({
                $0.transform = rotate
            })
        }
        
    }
}

extension CameraController:CameraManDelegate {
    func cameraManDidStart(_cameraMan: CameraMan) {
        setupPreviewLayer()
    }
    
    func cameraManNotAvailabel(_ cameraMan: CameraMan) {
        showNoCamera(true)
        focusImageView.isHidden = true
        bottomView.takePhotoBtn.isEnabled = false
        bottomView.rotationBtn.isEnabled = false
    }
    
    func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput) {
        topView.flashButton.isHidden = !input.device.hasFlash
    }
}

extension CameraController:TopViewDelegate {
    func flashButtonDidPress(_ title: String) {
        flashCamera(title)
    }
}


