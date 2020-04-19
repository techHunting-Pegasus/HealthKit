//
//  BlurViewController.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 4/19/20.
//  Copyright © 2020 Schu Studios, LLC. All rights reserved.
//

import UIKit

class BlurViewController: UIViewController {

    override func loadView() {
        super.loadView()

        let blurEffect = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        self.view = blurEffectView

    }
}
