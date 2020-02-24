//
//  Constants.swift
//  Network
//
//  Created by Hasan on 24/02/2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

class Constants{
    static var shouldShowSecondScreen : Bool{
        get{
            return UserDefaults.standard.bool(forKey: "shouldShowSecondScreen")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "shouldShowSecondScreen")
        }
    }
}
