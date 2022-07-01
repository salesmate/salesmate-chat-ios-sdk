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
    
    @IBOutlet weak var tFieldEventName: UITextField!
    @IBOutlet weak var tFieldKey: UITextField!
    @IBOutlet weak var tFieldValue: UITextField!
    
    @IBOutlet weak var tFieldUserId: UITextField!
    @IBOutlet weak var tFieldEmail: UITextField!
    @IBOutlet weak var tFieldFirstName: UITextField!
    @IBOutlet weak var tFieldLastName: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSalesmateChatMessengerSDK(env: .staging, workspaceID: "70bca1a9-925d-48e6-98e7-3dc4c75a082c", appKey: "dfb7dff0-a8fb-11ec-8457-39918f70b6b9", tenantID: "staging16.salesmate.io")
        setVerifiedId()
    }
    func configureSalesmateChatMessengerSDK(env: Environment, workspaceID: String, appKey: String, tenantID: String) {
        let config = Configuration(workspaceID: workspaceID,
                                   appKey: appKey,
                                   tenantID: tenantID,
                                   environment: env)
        SalesmateChat.setSalesmateChat(configuration: config)
    }
    
    /*func configureSalesmateChatMessengerSDKForDev18(){
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
    
    func configureSalesmateChatMessengerSDKForMobileApp(){
        let config = Configuration(workspaceID: "555448a6-5ca5-4b72-9c7b-fe5adb849b5d",
                                   appKey: "2b753150-969b-11eb-9308-d78117f0a2fb",
                                   tenantID: "mobileapp.salesmate.io",
                                   environment: .production)
        SalesmateChat.setSalesmateChat(configuration: config)
    }*/
    
    func setVerifiedId() {
        guard !SalesmateChat.getVisitorId().isEmpty else {
            return
        }
        SalesmateChat.setVerifiedID(SalesmateChat.getVisitorId())
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        SalesmateChat.presentMessenger(from: self)
    }
    
    @IBAction func showChatPressed(_ sender: UIButton) {
        SalesmateChat.presentMessenger(from: self)
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
        userLogin()
    }
    
    func userLogin() {
        guard let userId = tFieldUserId.text, !userId.isEmpty else {
            self.showAlertWithTitle(title: "Salesmate Chat", andMessage: "Please enter valid user id")
            return
        }
        
        SalesmateChat.loginWith(userId: userId, email: tFieldEmail.text ?? "", firstName: tFieldFirstName.text ?? "", lastName: tFieldLastName.text ?? "", completion: { (success, error)  in
            if error == nil {
                DispatchQueue.main.async {
                    self.showAlertWithTitle(title: "Salesmate Chat", andMessage: "Login Success")
                }
            }
        })
    }
    
    func userUpdate() {
        guard let userId = tFieldUserId.text, !userId.isEmpty else {
            self.showAlertWithTitle(title: "Salesmate Chat", andMessage: "Please enter valid user id")
            return
        }
        
        SalesmateChat.loginWith(userId: userId, email: tFieldEmail.text ?? "", firstName: tFieldFirstName.text ?? "", lastName: tFieldLastName.text ?? "", completion: { (success, error)  in
            if error == nil {
                DispatchQueue.main.async {
                    self.showAlertWithTitle(title: "Salesmate Chat", andMessage: "Update Success")
                }
            }
        })
    }
    
    @IBAction func logoutPressed(_ sender: UIButton) {
        SalesmateChat.logout()
        tFieldUserId.text = ""
        tFieldEmail.text = ""
        tFieldFirstName.text = ""
        tFieldLastName.text = ""
        self.showAlertWithTitle(title: "Salesmate Chat", andMessage: "Logout Success")
    }
    
    @IBAction func updatePressed(_ sender: UIButton) {
        userUpdate()
        self.showAlertWithTitle(title: "Salesmate Chat", andMessage: "Update Success")
    }
    
    @IBAction func getVisitorIdPressed(_ sender: UIButton) {
        guard !SalesmateChat.getVisitorId().isEmpty else {
            return
        }
        self.showAlertWithTitle(title: "Salesmate Chat", andMessage: "Visitor Id is : \(SalesmateChat.getVisitorId())")

    }
    
    @IBAction func btnSendTestEventPressed(_ sender: Any) {
        
        guard let eventName = self.tFieldEventName.text?.trimmingCharacters(in: .whitespacesAndNewlines), !eventName.isEmpty else {
            self.showAlertWithTitle(title: "Please Enter EventName", andMessage: "");
            return;
        }
        
        let key = self.tFieldKey.text?.trimmingCharacters(in: .whitespacesAndNewlines);
        let value = self.tFieldValue.text?.trimmingCharacters(in: .whitespacesAndNewlines);
        
        if key != nil{
            SalesmateChat.logEventWith(eventName: eventName, withData: [key!:value ?? ""]);
        }else{
            SalesmateChat.logEventWith(eventName: eventName);
        }
        
        self.showAlertWithTitle(title: "Event Queued for delivery", andMessage: "");
        self.tFieldEventName.text = nil;
        self.tFieldKey.text = nil;
        self.tFieldValue.text = nil;
    }
    
    func showAlertWithTitle(title:String, andMessage message:String){
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil);
        alertVC.addAction(cancelAction);
        self.present(alertVC, animated: true, completion: nil);
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
