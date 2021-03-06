//
//  KituraBotShared.swift
//  KituraBot
//
//  Created by Jacopo Mangiavacchi on 7/27/16.
//  Copyright © 2016 Jacopo. All rights reserved.
//

import Foundation
import UserNotifications
//import Alamofire


public class KituraBotShared {
    
    public static func storeDeviceId(_ storeDeviceId: String?) {
        if let groupDefaults = UserDefaults(suiteName: Configuration.sharedGroup) {
            groupDefaults.set(storeDeviceId, forKey: "DeviceId")
            groupDefaults.synchronize()
        }
        else {
            print("ERROR Saving Group Default")
        }
    }

    public static func getDeviceId() -> String? {
        if let groupDefaults = UserDefaults(suiteName: Configuration.sharedGroup) {
            return groupDefaults.string(forKey: "DeviceId")
        }
        else {
            print("ERROR Loading Group Default")
        }
        return nil
    }

    
    public static func storeContext(_ context: String?) {
        if let groupDefaults = UserDefaults(suiteName: Configuration.sharedGroup) {
            groupDefaults.set(context, forKey: "context")
            groupDefaults.synchronize()
        }
        else {
            print("ERROR Saving Group Default")
        }
    }
    
    public static func getContext() -> String? {
        if let groupDefaults = UserDefaults(suiteName: Configuration.sharedGroup) {
            return groupDefaults.string(forKey: "context")
        }
        else {
            print("ERROR Loading Group Default")
        }
        return nil
    }

    public static func storeLastNotificationResponse(_ responseMessage: String?) {
        if let groupDefaults = UserDefaults(suiteName: Configuration.sharedGroup) {
            groupDefaults.set(responseMessage, forKey: "lastNotificationResponse")
            groupDefaults.synchronize()
        }
        else {
            print("ERROR Saving Last Notification Default")
        }
    }
    
    public static func getLastNotificationResponse() -> String? {
        if let groupDefaults = UserDefaults(suiteName: Configuration.sharedGroup) {
            return groupDefaults.object(forKey: "lastNotificationResponse") as? String
        }
        else {
            print("ERROR Loading Last Notification Default")
        }
        
        return nil
    }
    
    private static func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    
    public static func sendMesage(text: String, completion: @escaping (_ responseText: String) -> Void) {

        //{
        //    "senderID" : "xxx",
        //    "messageText" : "Hello from Mobile to Bluemix",
        //    "securityToken" : "1234",
        //    "context" : {"a": 1, "b": "B"}
        //}
        
        let deviceId = getDeviceId() ?? ""
        
        var jsonDictionary: [String:Any] = ["senderID" : deviceId, "messageText" : text, "securityToken" : Configuration.mobileApiSecurityToken]
        
        if let context = getContext() {
            jsonDictionary["context"] = convertStringToDictionary(text: context)
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
        let dataString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
        print(dataString)

        
        let url = URL(string: Configuration.apiUrl)
        let session = URLSession.shared
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20.0)
        
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let _:Data = data, let _:URLResponse = response, error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print(dataString)
            
            let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
            
            //{
            //    "responseMessage": "ECHO: Hello from Mobile to Bluemix",
            //    "context": {
            //        "b": "B",
            //        "a": 1
            //    }
            //}
            if let response = json?["responseMessage"] as? String {
                
                if let jsonResponseContext = json?["context"] {
                    do {
                        let jsonContextData = try JSONSerialization.data(withJSONObject: jsonResponseContext, options: .prettyPrinted)
                        if let jsonDataString = NSString(data: jsonContextData, encoding: String.Encoding.utf8.rawValue) {
                            KituraBotShared.storeContext(jsonDataString as String)
                        }
                    }
                    catch {
                        print("error in json serialization")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(response)
                }
            }
            else {
                print("no valid responseMessage")
            }
        }
        
        task.resume()
        
    }
    
    
    public static func sendResetContextMesage() {
        
        //http://localhost:8090/message/channel/MobileAppEcho/user/1F82B348-0DD8-42A9-9ED1-80A6A060E784/reset/token/1234
        
        let deviceId = getDeviceId() ?? ""
        
        let url = URL(string: Configuration.resetUrl.replacingOccurrences(of: "[USER_ID]", with: deviceId))
        let session = URLSession.shared
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20.0)
        
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("error")
                return
            }
        }
        
        task.resume()
    }
    
    
    public static func sendLocalNotification(text: String) {
        //let action = UNNotificationAction(identifier:"reply", title:"Reply", options:[])
        let action = UNTextInputNotificationAction(
            identifier: "reply",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type here...")
        
        let category = UNNotificationCategory(identifier: "message", actions: [action], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let content = UNMutableNotificationContent()
        content.title = "KituraBot"
        content.subtitle = "You've got a response"
        content.body = text
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "message"
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier:"KituraBotRequest", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request){(error) in
            
            if (error != nil){
                
                //handle here
                
            }
            
        }
    }
}
