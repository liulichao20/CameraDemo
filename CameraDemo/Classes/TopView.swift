//
//  TopView.swift
//  Camera
//
//  Created by lichao_liu on 2017/12/26.
//  Copyright © 2017年 com.pa.com. All rights reserved.
//

import UIKit
protocol TopViewDelegate: class {
    func flashButtonDidPress(_ title: String)
}
class TopView: UIView {
    var configuration = Configuration()
    let flashButtonTitles = ["AUTO","ON","OFF"]
    var currentFlashIndex:Int = 0
    lazy var flashButton:UIButton = {
        [unowned self] in
        let button = UIButton()
        button.setImage(AssetManager.getImage("OFF"), for: UIControlState())
        button.setTitle("AUTO", for: UIControlState())
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(whenFlashButtonClicked), for: .touchUpInside)
        button.contentHorizontalAlignment = .left
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    @objc func whenFlashButtonClicked(_ button:UIButton){
        currentFlashIndex += 1
        currentFlashIndex = currentFlashIndex % flashButtonTitles.count
        switch currentFlashIndex{
        case 1:
            button.setTitleColor(UIColor(red: 0.98, green: 0.98, blue: 0.45, alpha: 1), for: UIControlState())
            button.setTitleColor(UIColor(red: 0.52, green: 0.52, blue: 0.24, alpha: 1), for: .highlighted)
        default:
            button.setTitleColor(UIColor.white, for: .normal)
            button.setTitleColor(UIColor.white, for: .highlighted)
        }
        let title = flashButtonTitles[currentFlashIndex]
        button.setImage(UIImage.init(named: title), for: .normal)
        button.setTitle(title, for: .normal)
        delegate?.flashButtonDidPress(title)
    }
    
    weak var delegate: TopViewDelegate?
    
    init(configuration: Configuration? = nil,frame:CGRect) {
        if let configuration = configuration {
            self.configuration = configuration
        }
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        addSubview(flashButton)
        flashButton.frame = CGRect(x: 12, y: 0, width: 55, height: 34)
    }
 
}
