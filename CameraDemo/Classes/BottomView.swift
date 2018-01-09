//
//  BottomView.swift
//  Camera
//
//  Created by lichao_liu on 2017/12/26.
//  Copyright © 2017年 com.pa.com. All rights reserved.
//

import UIKit

class BottomView: UIView {
    typealias BottomViewBtnClickedBlock = ((_ btnType:BottomViewBtnType)->Void)
    enum BottomViewBtnType:Int {
        case takePhoto,cancel,rotation,done,rePhoto
    }
    var btnClickedBlock:BottomViewBtnClickedBlock!
  
    var configration:Configuration = Configuration()
    lazy var rePhotoeBtn:UIButton = { [unowned self] in
        return self.createBtn(image: AssetManager.getImage("rePhoto"), tagType: .rePhoto,isHidden:true)
        }()
    lazy var takePhotoBtn:UIButton = { [unowned self] in
        return self.createBtn(image: AssetManager.getImage("photo"), tagType: .takePhoto)
        }()
    
    lazy var cancelBtn:UIButton = { [unowned self] in
        return self.createBtn(image: AssetManager.getImage("close_button"), tagType: .cancel)
        }()
    
    lazy var rotationBtn:UIButton = { [unowned self] in
        return self.createBtn(image: AssetManager.getImage("changeB"), tagType: .rotation)
        }()
    
    lazy var doneBtn:UIButton = { [unowned self] in
        return self.createBtn(image: AssetManager.getImage("picOk"), tagType: .done,isHidden:true)
        }()
    
    init(frame:CGRect ,configuration:Configuration? = nil,btnClickedBlock:@escaping BottomViewBtnClickedBlock) {
        if let configuration = configuration {
            self.configration = configuration
        }
        self.btnClickedBlock = btnClickedBlock
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        [rePhotoeBtn,takePhotoBtn,cancelBtn,rotationBtn,doneBtn].forEach {
            addSubview($0)
        }
        backgroundColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
        let centerX = UIScreen.main.bounds.width/2
        takePhotoBtn.frame = CGRect(x: centerX - 30, y: 20, width: 60, height: 60)
        rePhotoeBtn.frame = CGRect(x: centerX - 25 - 60, y: 20, width: 60, height: 60)
        doneBtn.frame = CGRect(x: centerX + 25, y: 20, width: 60, height: 60)
        cancelBtn.frame = CGRect(x: takePhotoBtn.frame.minX - 20 - 40, y: 30, width: 40, height: 40)
        rotationBtn.frame = CGRect(x: takePhotoBtn.frame.maxX + 20, y: 30, width: 40, height: 40)
    }
    
    @objc func whenBtnClicked(sender:UIButton){
        if let btnType = BottomViewBtnType(rawValue: sender.tag){
            btnClickedBlock(btnType)
            changeBtnState(btnType: btnType)
        }
    }
    
    func createBtn(image:UIImage,tagType:BottomViewBtnType,isHidden:Bool = false)->UIButton {
        let btn = UIButton(type: .custom)
        btn.setBackgroundImage(image, for: .normal)
        btn.tag = tagType.rawValue
        btn.isHidden = isHidden
        btn.addTarget(self, action: #selector(whenBtnClicked(sender:)), for: .touchUpInside)
        return btn
    }
    
    func changeBtnState(btnType:BottomViewBtnType) {
        switch btnType {
        case .rotation:
            if rotationBtn.backgroundImage(for: .normal) == AssetManager.getImage("changeF") {
                rotationBtn.setBackgroundImage(AssetManager.getImage("changeB"), for: .normal)
            }else {
                rotationBtn.setBackgroundImage(AssetManager.getImage("changeF"), for: .normal)
            }
        case .rePhoto:
            rePhotoeBtn.isHidden = true
            doneBtn.isHidden = true
            
           takePhotoBtn.isHidden = false
           cancelBtn.isHidden = false
            rotationBtn.isHidden = false
            
        case .takePhoto:
            rePhotoeBtn.isHidden = false
            doneBtn.isHidden = false
            
            takePhotoBtn.isHidden = true
            cancelBtn.isHidden = true
            rotationBtn.isHidden = true
        default:
            break
        }
    }
}
