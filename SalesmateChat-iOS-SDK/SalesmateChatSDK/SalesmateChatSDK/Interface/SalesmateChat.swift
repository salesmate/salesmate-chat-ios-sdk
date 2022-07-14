//
//  SalesmateChat.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 20/07/21.
//

import UIKit
import WebKit

@objc public enum Environment: Int {
    case development
    case staging
    case production
    
    var baseAPIURL: URL {
        switch self {
        case .development: return URL(string: "https://apis-dev.salesmate.io")!
        case .staging: return URL(string: "https://apis-staging.salesmate.io")!
        case .production: return URL(string: "https://apis.salesmate.io")!
        }
    }
}

@objc public class Configuration: NSObject {
    @objc let workspaceID: String
    @objc let appKey: String
    @objc let tenantID: String
    @objc let environment: Environment
    
    @objc public init(workspaceID: String, appKey: String, tenantID: String, environment: Environment) {
        self.workspaceID = workspaceID
        self.appKey = appKey
        self.tenantID = tenantID
        self.environment = environment
    }
}

@objc public class SalesmateChat: NSObject {
    
    private var client: ChatClient
    private var config: Configeration
    
    private static var shared: SalesmateChat?
    
    private var isLoading: Bool = false
    
    private let rootNC = UINavigationController()
    
    private init?(with settings: Configuration) {
        self.config = Configeration(connection: settings, environment: settings.environment)
        
        let chatStream = StarscreamChatStream(for: config)
        let chatAPI = ChatAPIClient(config: config)
        
        self.client = SalesmateChatClient(config: config, chatStream: chatStream, chatAPI: chatAPI)
    }
    
    @objc public static func setSalesmateChat(configuration settings: Configuration) {
        shared = SalesmateChat(with: settings)
        
        shared?.updateCustomization()
        shared?.setupAnalyticsSDK();
        shared?.client.connect(completion: { _ in })
    }
    
    @objc public static func presentMessenger(from viewController: UIViewController) {
        shared?.presentMessenger(from: viewController)
    }
    
    @objc public static func logEventWith(eventName:String, withData data:[AnyHashable:Any]? = nil){
        shared?.logEventWith(eventName: eventName, withData: data);
    }
    
    public static func setVerifiedID(_ ID: String) {
        shared?.config.verifiedID = ID
    }
    
    @objc public static func loginWith(userId: String?, email: String?, firstName: String?, lastName: String?, completion: @escaping (String?, Error?) -> Void) {
        let loginUser = LoginUser(userId: userId, email: email, firstName: firstName, lastName: lastName)
        shared?.client.loginWith(with: loginUser, completion: { (result) in
            switch result {
            case .success(let response):
                self.setVerifiedID(userId ?? "")
                shared?.saveUserId(userId: userId ?? "")
                completion(response, nil)
            case .failure(let error):
                completion(nil, error)
                break
            }
        })
    }
    
    @objc public static func logout() {
        shared?.logout()
    }
    
    @objc public static func getVisitorId() -> String {
        return shared?.getVisitorId() ?? ""
    }
    
    @objc public static func update(userId: String?, email: String?, firstName: String?, lastName: String?, completion: @escaping (String?, Error?) -> Void) {
        let loginUser = LoginUser(userId: userId, email: email, firstName: firstName, lastName: lastName)
        shared?.client.update(with: loginUser, completion: { (result) in
            switch result {
            case .success(let response):
                self.setVerifiedID(userId ?? "")
                shared?.saveUserId(userId: userId ?? "")
                completion(response, nil)
            case .failure(let error):
                completion(nil, error)
                break
            }
        })
    }
    
    @objc public static func sendDeviceToken(with deviceToken: String, deviceId: String) {
        shared?.client.sendDeviceToken(with: deviceToken, deviceId: deviceId, completion: { (result) in
            switch result {
            case .success:
                print("success")
            case .failure:
                print("failure")
                break
            }
        })
    }
    
    @objc public static func isSalesmateChatSDKPushNotification(userInfo: [AnyHashable : Any]) -> Bool {
        return shared?.isSalesmateChatSDKPushNotification(userInfo: userInfo) ?? false
        
    }
    
    @objc public static func handlePushNotification(userInfo: [AnyHashable : Any]) {
        
        if UIApplication.shared.applicationState == .active {
            if isFromSalesmateChatSDK() {
                return
            }
        } else {
            shared?.redirectToChatHomeVC()
        }
        
    }
}

extension SalesmateChat {
    
    private func setupAnalyticsSDK(){
        let rapidopsConfig = RapidopsConfig();
        let hostStr = "https://\(config.identity.tenantID)/apis" //CAC.shared.base.host ?? "https://\(config.identity.tenantID)/apis"
        rapidopsConfig.host = "\(hostStr)/analytics/v1"
        rapidopsConfig.appKey = config.identity.appKey;
        rapidopsConfig.enableDebug = true;
        rapidopsConfig.alwaysUsePOST = true;
        rapidopsConfig.deviceID = config.uniqueID;
        rapidopsConfig.tenantID = config.identity.tenantID;
        rapidopsConfig.customHeaderFieldName = "user-agent"
        if let userAgentValue = WKWebView().value(forKey: "userAgent") as? String {
            rapidopsConfig.customHeaderFieldValue = userAgentValue
            
        }
        Rapidops.sharedInstance().start(with: rapidopsConfig)
    }
    
    private func updateCustomization() {
        isLoading = true
        
        client.getConfigerations { result in
            switch result {
            case .success(let customization):
                self.config.update(with: customization)
            case .failure:
                break
            }
            
            self.isLoading = false
            
            if let look = self.config.look {
                runOnMain {
                    HUDVC.shared = HUDVC.create(with: HUDViewModel(look: look))
                }
            }
            
            runOnMain { self.showHomeVC() }
        }
    }
    
    private func logEventWith(eventName:String, withData data:[AnyHashable:Any]?){
        Rapidops.sharedInstance().recordEvent(eventName, segmentation: data);
    }
    
    private func presentMessenger(from viewController: UIViewController) {
        if config.look == nil {
            showStartVC(from: viewController)
            
            if !isLoading {
                updateCustomization()
            }
            
            client.connect(completion: { _ in })
        } else {
            showHomeVC(from: viewController)
        }
    }
    
    private func showStartVC(from viewController: UIViewController? = nil) {
        let VC = StartVC.create(with: StartViewModel())
        
        rootNC.setViewControllers([VC], animated: true)
        rootNC.navigationBar.isHidden = true
        
        if UIDevice.current.isIPad {
            rootNC.modalPresentationStyle = .fullScreen
        }
        
        viewController?.present(rootNC, animated: false, completion: nil)
    }
    
    private func showHomeVC(from viewController: UIViewController? = nil) {
        let VC = SalesmateChatHomeVC.create(with: HomeViewModel(config: config, client: client))
        
        rootNC.setViewControllers([VC], animated: true)
        rootNC.navigationBar.isHidden = true
        
        if UIDevice.current.isIPad {
            rootNC.modalPresentationStyle = .fullScreen
        }
        
        viewController?.present(rootNC, animated: true, completion: nil)
    }
    
    private func logout() {
        SalesmateChat.shared?.config.verifiedID = nil
        SalesmateChat.shared?.config.channels = []
        SalesmateChat.shared?.client.clearConversations()
        SalesmateChat.shared?.client.clearMessages()
        SalesmateChat.shared?.config.uniqueID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        UserDefaults.standard.removeObject(forKey: UserDefaultStorage.userDefaultKey)
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.synchronize()
    }
    
    private func getVisitorId() -> String? {
        return self.getUserId() ?? ""
    }
    
    private func saveUserId(userId: String) {
        let defaults = UserDefaults.standard
        defaults.set(userId, forKey: "userId")
        defaults.synchronize()
    }
    
    private func getUserId() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "userId") ?? ""
    }
    
    private func isSalesmateChatSDKPushNotification(userInfo: [AnyHashable : Any]) -> Bool? {
        var isSalesmateChatSDKPush: Bool = false
        if let messageObj = userInfo["message"] as? [String: Any] {
            if let message = messageObj["message"] as? [String: Any] {
                if let isChatPush = message[isSalesmateVisitorSDK] as? Bool, isChatPush {
                    isSalesmateChatSDKPush = true
                }
            }
        }
        return isSalesmateChatSDKPush
    }
    
    func redirectToChatHomeVC() {
        
        if SalesmateChat.isFromSalesmateChatSDK() {
            return
        }
        let VC = SalesmateChatHomeVC.create(with: HomeViewModel(config: config, client: client))
        
        rootNC.setViewControllers([VC], animated: true)
        rootNC.navigationBar.isHidden = true
        
        if UIDevice.current.isIPad {
            rootNC.modalPresentationStyle = .fullScreen
        }
        UIApplication.topViewController()?.present(rootNC, animated: true, completion: nil)
    }
    
    private func showConvesationVC(from viewController: UIViewController? = nil, conversationId: String) {
        let VC = SalesmateChatHomeVC.create(with: HomeViewModel(config: config, client: client))
        
        rootNC.setViewControllers([VC], animated: true)
        rootNC.navigationBar.isHidden = true
        
        if UIDevice.current.isIPad {
            rootNC.modalPresentationStyle = .fullScreen
        }
        viewController?.present(rootNC, animated: true, completion: {
            VC.redirectToChatConversation(conversationId: conversationId)
        })
    }

    static func redirectToConversation(conversationId: String) {
        if let topViewController = UIApplication.topViewController() {
            shared?.showConvesationVC(from: topViewController, conversationId: conversationId)
        }
    }
    
    static func isFromSalesmateChatSDK() -> Bool {
        
        var isPartOfTheSDK: Bool = false
        if let topViewController = UIApplication.topViewController() {
            if topViewController.isKind(of: StartVC.self) {
                isPartOfTheSDK = true
            } else if topViewController.isKind(of: SalesmateChatHomeVC.self) {
                isPartOfTheSDK = true
            } else if topViewController.isKind(of: NewVisitorVC.self) {
                isPartOfTheSDK = true
            } else if topViewController.isKind(of: RecentConversationsVC.self) {
                isPartOfTheSDK = true
            } else if topViewController.isKind(of: ConversationsVC.self) {
                isPartOfTheSDK = true
            } else if topViewController.isKind(of: ChatVC.self) {
                isPartOfTheSDK = true
            }
        }
        return isPartOfTheSDK
    }
}
