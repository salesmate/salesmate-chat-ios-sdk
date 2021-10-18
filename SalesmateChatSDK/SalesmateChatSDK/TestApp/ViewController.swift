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

        self.configureSalesmate()

//        if let id = UIDevice.current.identifierForVendor?.uuidString {
//            SalesmateChat.setVerifiedID(id)
//        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        SalesmateChat.presentMessenger(from: self)
    }

    @IBAction func showChatPressed(_ sender: UIButton) {
        SalesmateChat.presentMessenger(from: self)
    }
    
    func configureSalesmate(){
        let setting = Settings(workspaceID: "3ade8edc-5a62-45dc-b7a5-46b0e40ffb57",
                               appKey: "2f33c730-b08a-11eb-99e2-f3b202d2d81c",
                               tenantID: "dev18.salesmate.io")

        SalesmateChat.setSalesmateChat(configeration: setting)
    }
}
