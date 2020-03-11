//
//  WebViewVC.swift
//  Network
//
//  Created by Rehana Syed on 08/02/2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import WebKit
import MachO
import DeviceKit
import FPSCounter
import SystemConfiguration.CaptiveNetwork

class WebViewVC: UIViewController, WKNavigationDelegate , WKUIDelegate,WKScriptMessageHandler{
    
    var urlstring : String = "https://editor.wallboard.info/pwa/client/index.html"
    var webView: WKWebView!
    var fps = 0
    let fpsCounter = FPSCounter()
    //@IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backgroundView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //let config = WKWebViewConfiguration()
        
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        let url = URL(string: urlstring)!
        configureWebview()
        webView.load(URLRequest(url: url))
        //fetchSystemDetails()
        // fetchSystemDetailsJSON()
    }
    
    @IBAction func btnScreenShot(_ sender: Any) {
        //self.TakeScreenshot()
    }
    
    func configureWebview(){
        let contentController = WKUserContentController()
        let scriptSource = "window.IOS = {};"
        let script = WKUserScript(source: scriptSource, injectionTime:.atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(script)
        contentController.add(self, name: "pwa")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        fpsCounter.delegate = self
        fpsCounter.startTracking()
        
        let height = UIScreen.main.bounds.height - (view.safeAreaInsets.top + view.safeAreaInsets.bottom)
        
        webView =  WKWebView(frame: CGRect(x: 0, y: view.safeAreaInsets.top, width: UIScreen.main.bounds.width, height:height ), configuration: config)
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view.addSubview(webView!)
    }
    
    func TakeScreenshotInBase64() -> String {
        UIGraphicsBeginImageContextWithOptions((self.webView.frame.size), false, 0.0)
        //drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        self.webView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let sourceImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let rect = CGRect(x: 0, y: 0, width: 180, height: 320)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 180, height: 320), false, 1.0)
        sourceImage?.draw(in: rect)
         let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let data = resizeImage?.pngData()
        let base64Str = data?.base64EncodedString(options: []) ?? ""
        return "\"\(base64Str)\""
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
            else if dict["event"] as? String ?? "" == "takeAScreenshot"{
                let str = TakeScreenshotInBase64()
                let js = "window.IOS.sendBase64String(\(str));"
                webView.evaluateJavaScript(js) { (res, error) in
                    print(error ?? "")
                }
            }
            else if dict["event"] as? String ?? "" == "getHardwareData"{
                let str = fetchSystemDetailsJSON()
                let js = "window.IOS.sendHardwareData(\(str));"
                webView.evaluateJavaScript(js) { (res, error) in
                    print(error ?? "")
                }
            }
        }
    }
    
    func fetchSystemDetailsJSON() -> String {
        
        var result = [String]()
        result = getIFAddresses()
        print(result)
        print(hostCPULoadInfo() as Any)
        print("CPU usage : \(cpuUsage())")
        let device = Device.current
        print("Device \(device)")
        let batteryLevel = Device.current.batteryLevel
        print("battery level: \(String(describing: batteryLevel))")
        let battery = Device.current.batteryState
        print("battery State \(String(describing: battery))")
        let memory = Device.volumeTotalCapacity ?? 0
        print("Memory = \(String(describing: memory))" )
        //let usedMemory = (memory ?? 0) -  (Device.volumeAvailableCapacity ?? 0)
        let usedMemory = memory - Int(Device.volumeAvailableCapacityForOpportunisticUsage ?? 0)
        let y = (Device.volumeAvailableCapacity ?? 0)/1073741824
        let z = (Device.volumeAvailableCapacityForImportantUsage ?? 0)/1073741824
        print("Available memory = \(String(describing: usedMemory))")
        let systemVersion = UIDevice.current.systemVersion
        print("version : \(systemVersion)")
        let maxMemory = Double(ProcessInfo.processInfo.physicalMemory)/1073741824
        let numOfCores =  ProcessInfo.processInfo.activeProcessorCount
        let ipAddress = getWiFiAddress() ?? ""
        let wifiName = getWiFiName() ?? ""
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let processorUsage = "\(cpuUsage())"
        
        //FPSCounter.showInStatusBar()
        print("RAM : \(Double(ProcessInfo.processInfo.physicalMemory)/1073741824)")
        
        print(report_memory())
        
        let json = "{\"Device_Model\" : \"\(device.name ?? "")\", \"OS_Version\" : \"\(systemVersion)\" , \"Max_RAM\" : \"\(maxMemory) GB\" , \"Total_Memory\" : \"\((memory)/1073741824) GB\", \"Used_Memory\" : \"\((usedMemory)/1073741824) GB\",\"CPU_Cores\" : \"\(numOfCores)\" , \"IP_Address\" : \"\(ipAddress)\" , \"UUID\" : \"\(uuid)\", \"FPS\" : \"\(self.fps)\"}"
        return json
    }
}

extension WebViewVC{
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        
        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return addresses
    }
    
    func hostCPULoadInfo() -> host_cpu_load_info? {
        let HOST_CPU_LOAD_INFO_COUNT = MemoryLayout<host_cpu_load_info>.stride/MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
        var cpuLoadInfo = host_cpu_load_info()
        
        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: HOST_CPU_LOAD_INFO_COUNT) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        if result != KERN_SUCCESS{
            print("Error  - \(#file): \(#function) - kern_result_t = \(result)")
            return nil
        }
        return cpuLoadInfo
    }
    
    fileprivate func cpuUsage() -> Double {
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t
        
        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))
        
        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
        if kr != KERN_SUCCESS {
            return -1
        }
        
        var thread_list: thread_act_array_t? = UnsafeMutablePointer(mutating: [thread_act_t]())
        var thread_count: mach_msg_type_number_t = 0
        defer {
            if let thread_list = thread_list {
                vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(thread_list).pointee), vm_size_t(thread_count))
            }
        }
        
        kr = task_threads(mach_task_self_, &thread_list, &thread_count)
        
        if kr != KERN_SUCCESS {
            return -1
        }
        
        var tot_cpu: Double = 0
        
        if let thread_list = thread_list {
            
            for j in 0 ..< Int(thread_count) {
                var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
                var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
                kr = thread_info(thread_list[j], thread_flavor_t(THREAD_BASIC_INFO),
                                 &thinfo, &thread_info_count)
                if kr != KERN_SUCCESS {
                    return -1
                }
                
                let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)
                
                if threadBasicInfo.flags != TH_FLAGS_IDLE {
                    tot_cpu += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                }
            } // for each thread
        }
        
        return tot_cpu
    }
    
    
    fileprivate func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
        var result = thread_basic_info()
        
        result.user_time = time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1])
        result.system_time = time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3])
        result.cpu_usage = threadInfo[4]
        result.policy = threadInfo[5]
        result.run_state = threadInfo[6]
        result.flags = threadInfo[7]
        result.suspend_count = threadInfo[8]
        result.sleep_time = threadInfo[9]
        
        return result
    }
    
    func report_memory() {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            print("Memory used in bytes: \(Double((taskInfo.resident_size))/1073741824)")
        }
        else {
            print("Error with task_info(): " +
                (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
        }
    }
    
    func getWiFiAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    func getWiFiName() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid
    }
    
}



extension WebViewVC : FPSCounterDelegate{
    func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int) {
        self.fps = fps
        
    }
    
    
}
