//
//  WebViewVC.swift
//  Network
//
//  Created by Rehana Syed on 08/02/2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import WebKit

class WebViewVC: UIViewController, WKNavigationDelegate {

    //var webView: WKWebView!
    var urlstring : String = ""
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backgroundView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        let url = URL(string: urlstring)!
        webView.load(URLRequest(url: url))
        //webView.load(URLRequest(url: url))
        //webView.load(URLRequest(url: url))
    }
    
    @IBAction func btnScreenShot(_ sender: Any) {
        self.TakeScreenshot()
    }
    
    func TakeScreenshot() {
        UIGraphicsBeginImageContextWithOptions((self.webView.frame.size), false, 0.0)
        //drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        self.webView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let sourceImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let data = sourceImage?.pngData()
        let convertedImage = data?.base64EncodedString(options: .lineLength64Characters) ?? ""
        print(convertedImage)
    }


}
