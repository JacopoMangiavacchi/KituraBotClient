//
//  Configuration.swift
//  KituraBot
//
//  Created by Jacopo Mangiavacchi on 10/3/16.
//  Copyright © 2016 Jacopo. All rights reserved.
//

import Foundation

public struct Configuration {
    public static let appName = "KBot"
    static let sharedGroup = "group.jacopomangiavacchi.KituraBot"
    
    static let apiUrl = "https://xxx/mobileapi"
    
    // Token to use for verifing access to the Mobile API
    static let mobileApiSecurityToken = "1234"

    // Bluemix Push configuration
    public static let bluemixRegion = ".ng.bluemix.net"
    public static let appGUID = "xxx"
    public static let clientSecret = "xxx"
}

