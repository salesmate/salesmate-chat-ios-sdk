//
//  SalesmateChat.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 20/07/21.
//

import UIKit

public struct Settings {
    
    let workspaceID: String
    let appKey: String
    let tenantID: String
    
    public init(workspaceID: String, appKey: String, tenantID: String) {
        self.workspaceID = workspaceID
        self.appKey = appKey
        self.tenantID = tenantID
    }
}

public class SalesmateChat {

    private var client: ChatClient
    private var config: Configeration
    
    private static var shared: SalesmateChat?
    
    init?(with settings: Settings) {
        self.config = Configeration(connection: settings, environment: Environment.current)
        
        let chatStream = StarscreamChatStream(for: config)
        let chatAPI = ChatAPIClient(config: config)
        
        self.client = SalesmateChatClient(config: config, chatStream: chatStream, chatAPI: chatAPI)
    }
    
    public static func setSalesmateChat(configeration settings: Settings) {
        shared = SalesmateChat(with: settings)
        
        shared?.updateCustomization()
        shared?.client.connect(completion: { result in })
    }
    
    public static func presentMessenger(from viewController: UIViewController) {
        shared?.presentMessenger(from: viewController)
    }
    
    private func updateCustomization() {
        client.getConfigerations { result in
            switch result {
            case .success(let customization):
                self.config.update(with: customization)
                print("")
            case .failure: break
            }
        }
    }
    
    private func presentMessenger(from viewController: UIViewController) {
        let VC = HomeVC.create(with: HomeViewModel(config: config, client: client))
        let NC = UINavigationController(rootViewController: VC)
        
        NC.navigationBar.isHidden = true
        
        viewController.present(NC, animated: true, completion: nil)
    }
}
