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
    
    static let apiUrl = "https://jswiftbot.mybluemix.net/mobileapi"
    
    // Token to use for verifing access to the Mobile API
    static let mobileApiSecurityToken = "1234"

    // Bluemix Push configuration
    public static let bluemixRegion = ".ng.bluemix.net"
    public static let appGUID = "e34a187c-a0d2-47e4-b558-c7dc9b45dfbd"
    public static let clientSecret = "cfab758b-8a43-4773-bf9e-9ae37cc8d8cc"
}

