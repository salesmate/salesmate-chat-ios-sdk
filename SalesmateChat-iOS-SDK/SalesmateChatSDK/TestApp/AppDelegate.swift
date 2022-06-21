//
//  AppDelegate.swift
//  TestApp
//
//  Created by Chintan Dave on 27/07/21.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import SalesmateChatSDK

#if TARGET_OS_SIMULATOR
var strGlobalDeviceToken:String =  "tokenFromSimulator"
#else
var strGlobalDeviceToken:String =  ""
#endif


@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
        }
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
        application.registerForRemoteNotifications()
        
        IQKeyboardManager.shared.enable = true
        
        return true
    }
    
    //MARK: -Remote Notiffications...
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        if strGlobalDeviceToken != deviceTokenString{
            strGlobalDeviceToken = deviceTokenString
        }
        
        strGlobalDeviceToken = deviceTokenString
        
        SalesmateChat.sendDeviceToken(with: strGlobalDeviceToken, deviceId: getUDIDForTheApp())
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if Platform.isSimulator{
            strGlobalDeviceToken =  "tokenFromSimulator"
        } else {
            strGlobalDeviceToken =  ""
        }
    }
    
    func getUDIDForTheApp() -> String {
        return UIDevice.current.identifierForVendor!.uuidString;
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }
    
}

struct Platform {
    static let isSimulator: Bool = {
        #if arch(i386) || arch(x86_64)
        return true
        #endif
        return false
    }()
}
