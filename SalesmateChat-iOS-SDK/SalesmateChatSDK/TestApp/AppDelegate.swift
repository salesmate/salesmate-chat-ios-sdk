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
        print("notification received:\(userInfo)");

        if SalesmateChat.isSalesmateChatSDKPushNotification(userInfo: userInfo) {
            SalesmateChat.handlePushNotification(userInfo: userInfo)
            completionHandler(.newData)
            return
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        //other notifications will be here(non-silent)
        let dict = response.notification.request.content.userInfo as! [String : AnyObject]
        
        if SalesmateChat.isSalesmateChatSDKPushNotification(userInfo: dict) {
            SalesmateChat.handlePushNotification(userInfo: dict)
            return
        }

        print("notification received:\(dict)");
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            self.getDictPayLoad(dict: dict)
        default:
            print("Unknown action")
        }
        completionHandler()
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let dict = notification.request.content.userInfo as! [String : AnyObject]
        
        if SalesmateChat.isSalesmateChatSDKPushNotification(userInfo: dict) {
            SalesmateChat.handlePushNotification(userInfo: dict)
            return
        }
        //let dictMessageTemp = dict["message"] as! [String : AnyObject]
        
//        print("notification received:\(dict)")
//
//        if UIApplication.shared.applicationState == .active{
//            print("notification received:\(dictMessageTemp)")
//        } else{
//            self.getDictPayLoad(dict: dict)
//        }
    }
    
    func getDictPayLoad(dict : [String : Any]) -> Void {
        
        let dictMessageTemp = dict["message"] as! [String : AnyObject]
        print("notification received:\(dictMessageTemp)")

        return;
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
