//
//  ViewController.swift
//  TestApp
//
//  Created by Chintan Dave on 27/07/21.
//

import UIKit
import AudioToolbox
import SalesmateChatSDK

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        // Dev7
        //        let setting = Settings(workspaceID: "4a3c2628-b49a-4a1a-8c60-e8d062b53bc7",
        //                               appKey: "44134f30-7b48-11eb-824b-677ababecb5c",
        //                               tenantID: "dev7.salesmate.io",
        //                               environment: .development)

        
        //        // Dev27
//                let setting = Settings(workspaceID: "15b160f2-7fcf-4295-9236-81d120c5b47c",
//                                       appKey: "dac84910-21bc-11ec-adce-354c2694d0d3",
//                                       tenantID: "dev27.salesmate.io",
//                                       environment: .development)
        //Dev18
//        let config = Configuration(workspaceID: "3ade8edc-5a62-45dc-b7a5-46b0e40ffb57",
//                                   appKey: "2f33c730-b08a-11eb-99e2-f3b202d2d81c",
//                                   tenantID: "dev18.salesmate.io",
//                                   environment: .development)
//        SalesmateChat.setSalesmateChat(configuration: config)
        
        self.configureSalesmateChatMessengerSDKForDev27()
        
        
        //        if let id = UIDevice.current.identifierForVendor?.uuidString {
        //            SalesmateChat.setVerifiedID(id)
        //        }
        
        //        playAllSound()
    }
    
    func configureSalesmateChatMessengerSDKForDev18(){
        let config = Configuration(workspaceID: "3ade8edc-5a62-45dc-b7a5-46b0e40ffb57",
                                   appKey: "2f33c730-b08a-11eb-99e2-f3b202d2d81c",
                                   tenantID: "dev18.salesmate.io",
                                   environment: .development)
        SalesmateChat.setSalesmateChat(configuration: config)
    }
    
    func configureSalesmateChatMessengerSDKForDev27(){
        let config = Configuration(workspaceID: "15b160f2-7fcf-4295-9236-81d120c5b47c",
                                   appKey: "dac84910-21bc-11ec-adce-354c2694d0d3",
                                   tenantID: "dev27.salesmate.io",
                                   environment: .development)
        SalesmateChat.setSalesmateChat(configuration: config)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SalesmateChat.presentMessenger(from: self)
    }
    
    @IBAction func showChatPressed(_ sender: UIButton) {
        SalesmateChat.presentMessenger(from: self)
    }
    
    private var soundID: Int = 1007
    
    private func playAllSound () {
        print(soundID)
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(soundID)) {
            self.soundID += 1
            self.playAllSound()
        }
    }
}
