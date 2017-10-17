//
//  ViewController.swift
//  Pivot App
//
//  Created by Ryan Schumacher on 10/4/17.
//  Copyright © 2017 Schu Studios, LLC. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    let decoder = JSONDecoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let websiteUrl = "http://pivotdev.gbehavior.com"
        guard let requestUrl = URL(string: websiteUrl) else { return }
        let request = URLRequest(url: requestUrl)
        self.webView.loadRequest(request)
        
    }

    
}

