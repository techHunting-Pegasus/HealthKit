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
        
        if let websiteUrl = UserDefaults.standard.string(forKey: "login_url") {
            guard let requestUrl = URL(string: websiteUrl) else { return }
            loadURL(url: requestUrl)
        }
        
        UserDefaults.standard.addObserver(self, forKeyPath: "login_url", options: .new, context: nil)
    }
    
    func loadURL(url: URL) {
        let request = URLRequest(url: url)
        self.webView.loadRequest(request)
    }

    override func observeValue(forKeyPath _keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let keyPath = _keyPath else { return }
        switch keyPath {
        case "login_url":
            // Load the URL on the main thread 
            DispatchQueue.main.async { [weak self] in
                if let szUrl = change?[.newKey] as? String,
                    let url = URL(string: szUrl) {
                    self?.loadURL(url: url)
                }
            }
        default: break
        }
    }
}

