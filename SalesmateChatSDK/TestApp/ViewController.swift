//
//  ViewController.swift
//  TestApp
//
//  Created by Chintan Dave on 27/07/21.
//

import UIKit
import SalesmateChatSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
            
        let setting = Settings(workspaceID: "4a3c2628-b49a-4a1a-8c60-e8d062b53bc7",
                               appKey: "44134f30-7b48-11eb-824b-677ababecb5c",
                               tenantID: "dev7.salesmate.io")
        
        SalesmateChat.setSalesmateChat(configeration: setting)
    }
}
