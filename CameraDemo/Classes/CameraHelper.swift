//
//  CameraHelper.swift
//  Camera
//
//  Created by lichao_liu on 2017/12/22.
//  Copyright © 2017年 com.pa.com. All rights reserved.
//

import UIKit
import AVFoundation

struct CameraHelper {
    static var previousOrientation = UIDeviceOrientation.unknown
    
    static func getVideoOrientation(fromDeviceOrientation orientation:UIDeviceOrientation)->AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    static func videoOrientation() -> AVCaptureVideoOrientation {
        return getVideoOrientation(fromDeviceOrientation: previousOrientation)
    }
    
    static func getTransform(fromDeviceOrientation orientation:UIDeviceOrientation)->CGAffineTransform {
        switch orientation {
        case .landscapeLeft:
            return CGAffineTransform(rotationAngle: CGFloat.pi*0.5)
        case .landscapeRight:
            return CGAffineTransform(rotationAngle: -(CGFloat.pi*0.5))
        case .portraitUpsideDown:
            return CGAffineTransform(rotationAngle: CGFloat.pi)
        default:
            return CGAffineTransform.identity
        }
    }
}
