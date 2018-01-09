//
//  Configuration.swift
//  Camera
//
//  Created by lichao_liu on 2017/12/25.
//  Copyright © 2017年 com.pa.com. All rights reserved.
//

import UIKit

public class Configuration: NSObject {

   public var allowPinchToZoom = true
   public var allowedOrientations = UIInterfaceOrientationMask.all

    var rotationTransform:CGAffineTransform {
        let currentOrientation = UIDevice.current.orientation
        switch currentOrientation {
        case .portrait:
            if allowedOrientations.contains(.portrait){
                CameraHelper.previousOrientation = .portrait
            }
        case .portraitUpsideDown:
            if allowedOrientations.contains(.portraitUpsideDown){
                CameraHelper.previousOrientation = .portraitUpsideDown
            }
        case .landscapeRight:
            if allowedOrientations.contains(.landscapeRight){
                CameraHelper.previousOrientation = .landscapeRight
            }
        case .landscapeLeft:
            if allowedOrientations.contains(.landscapeLeft){
                CameraHelper.previousOrientation = .landscapeLeft
            }
        default:
            break
        }
        
        if CameraHelper.previousOrientation == .unknown {
            if allowedOrientations.contains(.portrait){
                CameraHelper.previousOrientation = .portrait
            }else if allowedOrientations.contains(.landscapeLeft){
                CameraHelper.previousOrientation = .landscapeLeft
            }else if allowedOrientations.contains(.landscapeRight){
                CameraHelper.previousOrientation = .landscapeRight
            }else if allowedOrientations.contains(.portraitUpsideDown){
                CameraHelper.previousOrientation = .portraitUpsideDown
            }
        }
        return CameraHelper.getTransform(fromDeviceOrientation: CameraHelper.previousOrientation)
    }
    
}
