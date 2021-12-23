//
//  SalesmateChat.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 20/07/21.
//

import UIKit

public enum Environment {
    case development
    case production

    var baseAPIURL: URL {
        switch self {
        case .development: return URL(string: "https://apis-dev.salesmate.io")!
        case .production: return URL(string: "https://apis.salesmate.io")!
        }
    }
}

public struct Configuration {

    let workspaceID: String
    let appKey: String
    let tenantID: String
    let environment: Environment

    public init(workspaceID: String, appKey: String, tenantID: String, environment: Environment) {
        self.workspaceID = workspaceID
        self.appKey = appKey
        self.tenantID = tenantID
        self.environment = environment
    }
}

public class SalesmateChat {

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

    public static func setSalesmateChat(configuration settings: Configuration) {
        shared = SalesmateChat(with: settings)

        shared?.updateCustomization()
        shared?.setupAnalyticsSDK();
        shared?.client.connect(completion: { _ in })
    }

    public static func presentMessenger(from viewController: UIViewController) {
        shared?.presentMessenger(from: viewController)
    }
    
    public static func logEventWith(eventName:String, withData data:[AnyHashable:Any]? = nil){
        shared?.logEventWith(eventName: eventName, withData: data);
    }

    public static func setVerifiedID(_ ID: String) {
        shared?.config.verifiedID = ID
    }
    
    public static func loginWith(userId: String?, email: String?, firstName: String?, lastName: String?) {
        let loginUser = LoginUser(userId: userId, email: email, firstName: firstName, lastName: lastName)
        shared?.client.loginWith(with: loginUser, completion: { result in
            
        })
        shared?.client.loginWith(with: loginUser, completion: { _ in })
    }
}

extension SalesmateChat {
    
    private func setupAnalyticsSDK(){
        let rapidopsConfig = RapidopsConfig();
        let hostStr = "https://\(config.identity.tenantID)/apis" //CAC.shared.base.host ?? "https://\(config.identity.tenantID)/apis"
        rapidopsConfig.host = "\(hostStr)/sm-web-anl/v1"
        rapidopsConfig.appKey = config.identity.appKey;
        rapidopsConfig.enableDebug = true;
        rapidopsConfig.alwaysUsePOST = true;
        rapidopsConfig.deviceID = config.uniqueID;
        rapidopsConfig.tenantID = config.identity.tenantID;
        
        Rapidops.sharedInstance().start(with: rapidopsConfig);
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
        let VC = HomeVC.create(with: HomeViewModel(config: config, client: client))

        rootNC.setViewControllers([VC], animated: true)
        rootNC.navigationBar.isHidden = true

        if UIDevice.current.isIPad {
            rootNC.modalPresentationStyle = .fullScreen
        }

        viewController?.present(rootNC, animated: true, completion: nil)
    }
}
