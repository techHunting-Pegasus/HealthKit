//
//  ViewController.swift
//  Piviot App
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
        URLCache.shared.removeAllCachedResponses()
        if let url = URL(string: "https://pastebin.com/raw/qS7qC94N") {
            let task = URLSession.shared.dataTask(with: url) { [weak self] (_data, response, error) in
             
                // parse url
                var websiteUrl = "http://pivotdev.gbehavior.com:8000"
                
                if let data = _data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let newUrl = json?["home_url"] as? String {
                    websiteUrl = newUrl
                }
                DispatchQueue.main.async {
                    guard let requestUrl = URL(string: websiteUrl) else { return }
                    let request = URLRequest(url: requestUrl)
                    self?.webView.loadRequest(request)
                }
            }
            task.resume()
        }
    }

    
}

