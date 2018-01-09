//
//  ViewController.swift
//  CameraMaster
//
//  Created by 709857598@qq.com on 01/08/2018.
//  Copyright (c) 2018 709857598@qq.com. All rights reserved.
//

import UIKit
import CameraDemo
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        let btn = UIButton()
        btn.backgroundColor = UIColor.orange
        btn.addTarget(self, action: #selector(whenBtnClicked), for: .touchUpInside)
        btn.frame = CGRect(x: 50, y: 50, width: 100, height: 100)
        view.addSubview(btn)
    }
    
    @objc func whenBtnClicked() {
        let controller = CameraController(configuration: nil)
        present(controller, animated: true, completion: nil)
    }
}
