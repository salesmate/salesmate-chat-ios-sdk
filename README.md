# salesmate-chat-ios-sdk

**Configuration**

Configure Messenger at your salesmate.io link(For more detail visit: https://support.salesmate.io/hc/en-us/categories/360005786852-Messenger)

**Installation Steps:**

We allow installation via CocoaPods and Swift Package Installation 

//Documentation Pending

At your salesmate link, go to profile -> Setup -> Messenger(from App & Add-Ons sections) -> Installation

Here you will find these 3 things: 'workspace_id', 'app_key' and 'tenant_id'. Copy that, use

Now, in your iOS Code, Open appDelegate file, and add following method for configuration

    #import SalesmateChatSDK//Add this at header section
    
    func configureSalesmateChatMessengerSDK(){
        let config = Configuration(workspaceID: "#WORKSPACE_ID here",
                                   appKey: "#APPKEY here",
                                   tenantID: "#TENANT_ID here",
                                   environment: ".development or .production based on your build config")
        SalesmateChat.setSalesmateChat(configuration: config)
    }

Make call for this method in your 'didFinishLaunchingWithOptions' method of your AppDelegate like this:

        self.configureSalesmateChatMessengerSDK()

Hurray!..... You completed the configuration part.

Now in your whole application, wherever you wanted to present chat window, Add below code:

        #import SalesmateChatSDK//Don't forget to import our SDK
        
        
        SalesmateChat.presentMessenger(from: "View controller's object from where you are presenting this-- if you are presenting from same viewcontroller then use 'self'")
        
        
**Analytics**

For adding Analytics, Follow below instructions:
//Implementation Pending


**Notifications**

For handling notifications, Follow below instructions:
//Implementation Pending


