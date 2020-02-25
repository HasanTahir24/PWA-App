//
//  WebViewVC.swift
//  Network
//
//  Created by Rehana Syed on 08/02/2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import WebKit

class WebViewVC: UIViewController, WKNavigationDelegate , WKUIDelegate,WKScriptMessageHandler{
   
    var urlstring : String = "https://editor.wallboard.info/pwa/client/index.html"
    var webView: WKWebView!
    //@IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backgroundView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
       //let config = WKWebViewConfiguration()

        let contentController = WKUserContentController()
        let scriptSource = "window.IOS = {};"
        let script = WKUserScript(source: scriptSource, injectionTime:.atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(script)
        contentController.add(self, name: "pwa")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView =  WKWebView(frame: view.bounds, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view.addSubview(webView!)

    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        let url = URL(string: urlstring)!
        webView.load(URLRequest(url: url))
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

    func getMyJavaScript() -> String {
        if let filepath = Bundle.main.path(forResource: "injection", ofType: "js") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return ""
            }
        } else {
           return ""
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name  == "pwa"{
            guard let dict = message.body as? [String:Any] else{return}
            if dict["event"] as? String ?? "" == "reset"{
                Constants.shouldShowSecondScreen = false
            }
        }
    }
       

}
