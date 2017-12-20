//
//  PopViewController.swift
//  Pixel city
//
//  Created by PeterChen on 2017/8/31.
//  Copyright © 2017年 PeterChen. All rights reserved.
//

import UIKit

class PopViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var popImageView: UIImageView!

    var passImage: UIImage!
    
    func initData(forImage image: UIImage) {
        self.passImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = passImage
        addDoubleTap()
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    
     @objc func screenDoubleTap() {
        dismiss(animated: true, completion: nil)
    }

    
}
