// RapidopsPushNotifications.m
//
 
//
 

#import "RapidopsCommon.h"

NSString* const kRapidopsReservedEventPushAction = @"[RPD]_push_action";
NSString* const kRapidopsTokenError = @"kRapidopsTokenError";

#if (TARGET_OS_IOS || TARGET_OS_OSX)
@interface RapidopsPushNotifications () <UNUserNotificationCenterDelegate>
@property (nonatomic) NSString* token;
@property (nonatomic, copy) void (^permissionCompletion)(BOOL granted, NSError * error);
#else
@interface RapidopsPushNotifications ()
#endif
@end

#if TARGET_OS_IOS
    #define RPDApplication UIApplication
#elif TARGET_OS_OSX
    #define RPDApplication NSApplication
#endif

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@implementation RapidopsPushNotifications

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsPushNotifications* s_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {

    }

    return self;
}

#pragma mark ---

#if (TARGET_OS_IOS || TARGET_OS_OSX)
- (void)startPushNotifications
{
    if (!self.isEnabledOnInitialConfig)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForPushNotifications)
        return;

    if (@available(iOS 10.0, macOS 10.14, *))
        UNUserNotificationCenter.currentNotificationCenter.delegate = self;

    [self swizzlePushNotificationMethods];

#if TARGET_OS_IOS
    [UIApplication.sharedApplication registerForRemoteNotifications];
#elif TARGET_OS_OSX
    [NSApplication.sharedApplication registerForRemoteNotificationTypes:NSRemoteNotificationTypeBadge | NSRemoteNotificationTypeAlert | NSRemoteNotificationTypeSound];

    if (@available(macOS 10.14, *))
    {
        UNNotificationResponse* notificationResponse = self.launchNotification.userInfo[NSApplicationLaunchUserNotificationKey];
        if (notificationResponse)
            [self userNotificationCenter:UNUserNotificationCenter.currentNotificationCenter didReceiveNotificationResponse:notificationResponse withCompletionHandler:^{}];
    }
#endif
}

- (void)stopPushNotifications
{
    if (!self.isEnabledOnInitialConfig)
        return;

    if (@available(iOS 10.0, macOS 10.14, *))
    {
        if (UNUserNotificationCenter.currentNotificationCenter.delegate == self)
            UNUserNotificationCenter.currentNotificationCenter.delegate = nil;
    }

    [RPDApplication.sharedApplication unregisterForRemoteNotifications];
}

- (void)swizzlePushNotificationMethods
{
    static BOOL alreadySwizzled;
    if (alreadySwizzled)
        return;

    alreadySwizzled = YES;

    Class appDelegateClass = RPDApplication.sharedApplication.delegate.class;
    NSArray* selectors =
    @[
        @"application:didRegisterForRemoteNotificationsWithDeviceToken:",
        @"application:didFailToRegisterForRemoteNotificationsWithError:",
#if TARGET_OS_IOS
        @"application:didRegisterUserNotificationSettings:",
        @"application:didReceiveRemoteNotification:fetchCompletionHandler:",
#elif TARGET_OS_OSX
        @"application:didReceiveRemoteNotification:",
#endif
    ];

    for (NSString* selectorString in selectors)
    {
        SEL originalSelector = NSSelectorFromString(selectorString);
        Method originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector);

        if (originalMethod == NULL)
        {
            Method method = class_getInstanceMethod(self.class, originalSelector);
            IMP imp = method_getImplementation(method);
            const char* methodTypeEncoding = method_getTypeEncoding(method);
            class_addMethod(appDelegateClass, originalSelector, imp, methodTypeEncoding);
            originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector);
        }

        SEL RapidopsSelector = NSSelectorFromString([@"Rapidops_" stringByAppendingString:selectorString]);
        Method RapidopsMethod = class_getInstanceMethod(appDelegateClass, RapidopsSelector);
        method_exchangeImplementations(originalMethod, RapidopsMethod);
    }
}

- (void)askForNotificationPermissionWithOptions:(NSUInteger)options completionHandler:(void (^)(BOOL granted, NSError * error))completionHandler
{
    if (!RapidopsConsentManager.sharedInstance.consentForPushNotifications)
        return;

    if (@available(iOS 10.0, macOS 10.14, *))
    {
        if (options == 0)
            options = UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert;

        [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError* error)
        {
            if (completionHandler)
                completionHandler(granted, error);

            [self sendToken];
        }];
    }
#if TARGET_OS_IOS
    else
    {
        self.permissionCompletion = completionHandler;

        if (options == 0)
            options = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;

        UIUserNotificationType userNotificationTypes = (UIUserNotificationType)options;
        UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
        [UIApplication.sharedApplication registerUserNotificationSettings:settings];
    }
#endif
}

- (void)sendToken
{
    if (!RapidopsConsentManager.sharedInstance.consentForPushNotifications)
        return;

    if (!self.token)
        return;

    if ([self.token isEqualToString:kRapidopsTokenError])
    {
        [self clearToken];
        return;
    }

    if (self.sendPushTokenAlways)
    {
        [RapidopsConnectionManager.sharedInstance sendPushToken:self.token];
        return;
    }

    BOOL hasNotificationPermissionBefore = [RapidopsPersistency.sharedInstance retrieveNotificationPermission];

    if (@available(iOS 10.0, macOS 10.14, *))
    {
        [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* settings)
        {
            BOOL hasProvisionalPermission = NO;
            if (@available(iOS 12.0, *))
            {
                hasProvisionalPermission = settings.authorizationStatus == UNAuthorizationStatusProvisional;
            }
        
            if (settings.authorizationStatus == UNAuthorizationStatusAuthorized || hasProvisionalPermission)
            {
                [RapidopsConnectionManager.sharedInstance sendPushToken:self.token];
                [RapidopsPersistency.sharedInstance storeNotificationPermission:YES];
            }
            else if (hasNotificationPermissionBefore)
            {
                [self clearToken];
                [RapidopsPersistency.sharedInstance storeNotificationPermission:NO];
            }
        }];
    }
#if TARGET_OS_IOS
    else
    {
        if (UIApplication.sharedApplication.currentUserNotificationSettings.types != UIUserNotificationTypeNone)
        {
            [RapidopsConnectionManager.sharedInstance sendPushToken:self.token];
            [RapidopsPersistency.sharedInstance storeNotificationPermission:YES];
        }
        else if (hasNotificationPermissionBefore)
        {
            [self clearToken];
            [RapidopsPersistency.sharedInstance storeNotificationPermission:NO];
        }
    }
#endif
}

- (void)clearToken
{
    [RapidopsConnectionManager.sharedInstance sendPushToken:@""];
}

- (void)handleNotification:(NSDictionary *)notification
{
#if (TARGET_OS_IOS || TARGET_OS_OSX)
    if (!RapidopsConsentManager.sharedInstance.consentForPushNotifications)
        return;

    Rapidops_LOG(@"Handling remote notification %@", notification);

    NSDictionary* RapidopsPayload = notification[kRapidopsPNKeyRapidopsPayload];
    NSString* notificationID = RapidopsPayload[kRapidopsPNKeyNotificationID];

    if (!notificationID)
    {
        Rapidops_LOG(@"Rapidops payload not found in notification dictionary!");
        return;
    }

    Rapidops_LOG(@"Rapidops Push Notification ID: %@", notificationID);
#endif

#if TARGET_OS_OSX
    //NOTE: For macOS targets, just record action event.
    [self recordActionEvent:notificationID buttonIndex:0];
#endif

#if TARGET_OS_IOS
    if (self.doNotShowAlertForNotifications)
    {
        Rapidops_LOG(@"doNotShowAlertForNotifications flag is set!");
        return;
    }


    id alert = notification[@"aps"][@"alert"];
    NSString* message = nil;
    NSString* title = nil;

    if ([alert isKindOfClass:NSDictionary.class])
    {
        message = alert[@"body"];
        title = alert[@"title"];
    }
    else
    {
        message = (NSString*)alert;
        title = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    }

    if (!message)
    {
        Rapidops_LOG(@"Message not found in notification dictionary!");
        return;
    }


    __block UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];


    RPDButton* defaultButton = nil;
    NSString* defaultURL = RapidopsPayload[kRapidopsPNKeyDefaultURL];
    if (defaultURL)
    {
        defaultButton = [RPDButton buttonWithType:UIButtonTypeCustom];
        defaultButton.frame = alertController.view.bounds;
        defaultButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        defaultButton.onClick = ^(id sender)
        {
            [self recordActionEvent:notificationID buttonIndex:0];

            [self openURL:defaultURL];

            [alertController dismissViewControllerAnimated:YES completion:^
            {
                alertController = nil;
            }];
        };
        [alertController.view addSubview:defaultButton];
    }


    RPDButton* dismissButton = [RPDButton dismissAlertButton];
    dismissButton.onClick = ^(id sender)
    {
        [self recordActionEvent:notificationID buttonIndex:0];

        [alertController dismissViewControllerAnimated:YES completion:^
        {
            alertController = nil;
        }];
    };
    [alertController.view addSubview:dismissButton];


    NSArray* buttons = RapidopsPayload[kRapidopsPNKeyButtons];
    [buttons enumerateObjectsUsingBlock:^(NSDictionary* button, NSUInteger idx, BOOL * stop)
    {
        //NOTE: Add space to force buttons to be laid out vertically
        NSString* actionTitle = [button[kRapidopsPNKeyActionButtonTitle] stringByAppendingString:@"                       "];
        NSString* URL = button[kRapidopsPNKeyActionButtonURL];

        UIAlertAction* visit = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
        {
            [self recordActionEvent:notificationID buttonIndex:idx + 1];

            [self openURL:URL];

            alertController = nil;
        }];

        [alertController addAction:visit];
    }];

    [RapidopsCommon.sharedInstance tryPresentingViewController:alertController];

    const CGFloat kRapidopsActionButtonHeight = 44.0;
    CGRect tempFrame = defaultButton.frame;
    tempFrame.size.height -= buttons.count * kRapidopsActionButtonHeight;
    defaultButton.frame = tempFrame;
#endif
}

- (void)openURL:(NSString *)URLString
{
    if (!URLString)
        return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
#if TARGET_OS_IOS
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:URLString]];
#elif TARGET_OS_OSX
        [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:URLString]];
#endif
    });
}

- (void)recordActionForNotification:(NSDictionary *)userInfo clickedButtonIndex:(NSInteger)buttonIndex
{
    if (!RapidopsConsentManager.sharedInstance.consentForPushNotifications)
        return;

    NSDictionary* RapidopsPayload = userInfo[kRapidopsPNKeyRapidopsPayload];
    NSString* notificationID = RapidopsPayload[kRapidopsPNKeyNotificationID];

    [self recordActionEvent:notificationID buttonIndex:buttonIndex];
}

- (void)recordActionEvent:(NSString *)notificationID buttonIndex:(NSInteger)buttonIndex
{
    if (!notificationID)
        return;

    NSDictionary* segmentation =
    @{
        kRapidopsPNKeyNotificationID: notificationID,
        kRapidopsPNKeyActionButtonIndex: @(buttonIndex)
    };

    [Rapidops.sharedInstance recordReservedEvent:kRapidopsReservedEventPushAction segmentation:segmentation];
}

#pragma mark ---

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0), macos(10.14))
{
    Rapidops_LOG(@"userNotificationCenter:willPresentNotification:withCompletionHandler:");
    Rapidops_LOG(@"%@", notification.request.content.userInfo.description);

    if (!self.doNotShowAlertForNotifications)
    {
        NSDictionary* RapidopsPayload = notification.request.content.userInfo[kRapidopsPNKeyRapidopsPayload];
        NSString* notificationID = RapidopsPayload[kRapidopsPNKeyNotificationID];

        if (notificationID)
            completionHandler(UNNotificationPresentationOptionAlert);
    }

    id<UNUserNotificationCenterDelegate> appDelegate = (id<UNUserNotificationCenterDelegate>)RPDApplication.sharedApplication.delegate;

    if ([appDelegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)])
        [appDelegate userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
    else
        completionHandler(UNNotificationPresentationOptionNone);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0), macos(10.14))
{
    Rapidops_LOG(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:");
    Rapidops_LOG(@"%@", response.notification.request.content.userInfo.description);

    if (RapidopsConsentManager.sharedInstance.consentForPushNotifications)
    {
        NSDictionary* RapidopsPayload = response.notification.request.content.userInfo[kRapidopsPNKeyRapidopsPayload];
        NSString* notificationID = RapidopsPayload[kRapidopsPNKeyNotificationID];

        if (notificationID)
        {
            NSInteger buttonIndex = 0;
            NSString* URL = nil;

            Rapidops_LOG(@"Action Identifier: %@", response.actionIdentifier);

            if ([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier])
            {
                URL = RapidopsPayload[kRapidopsPNKeyDefaultURL];
            }
            else if ([response.actionIdentifier hasPrefix:kRapidopsActionIdentifier])
            {
                buttonIndex = [[response.actionIdentifier stringByReplacingOccurrencesOfString:kRapidopsActionIdentifier withString:@""] integerValue];
                URL = RapidopsPayload[kRapidopsPNKeyButtons][buttonIndex - 1][kRapidopsPNKeyActionButtonURL];
            }

            [self recordActionEvent:notificationID buttonIndex:buttonIndex];

            [self openURL:URL];
        }
    }

    id<UNUserNotificationCenterDelegate> appDelegate = (id<UNUserNotificationCenterDelegate>)RPDApplication.sharedApplication.delegate;

    if ([appDelegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)])
        [appDelegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    else
        completionHandler();
}

#pragma mark ---

- (void)application:(RPDApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{}
- (void)application:(RPDApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{}
#if TARGET_OS_IOS
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler(UIBackgroundFetchResultNewData);
}
#elif TARGET_OS_OSX
- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *,id> *)userInfo{}
#endif
#endif
@end


@implementation NSObject (RapidopsPushNotifications)
#if (TARGET_OS_IOS || TARGET_OS_OSX)
- (void)Rapidops_application:(RPDApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    Rapidops_LOG(@"App didRegisterForRemoteNotificationsWithDeviceToken: %@", deviceToken);

    const char* bytes = [deviceToken bytes];
    NSMutableString *token = NSMutableString.new;
    for (NSUInteger i = 0; i < deviceToken.length; i++)
        [token appendFormat:@"%02hhx", bytes[i]];

    RapidopsPushNotifications.sharedInstance.token = token;

    [RapidopsPushNotifications.sharedInstance sendToken];

    [self Rapidops_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)Rapidops_application:(RPDApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    Rapidops_LOG(@"App didFailToRegisterForRemoteNotificationsWithError: %@", error);

    RapidopsPushNotifications.sharedInstance.token = kRapidopsTokenError;

    [RapidopsPushNotifications.sharedInstance sendToken];

    [self Rapidops_application:application didFailToRegisterForRemoteNotificationsWithError:error];
}
#endif

#if TARGET_OS_IOS
- (void)Rapidops_application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    Rapidops_LOG(@"App didRegisterUserNotificationSettings: %@", notificationSettings);

    [RapidopsPushNotifications.sharedInstance sendToken];

    BOOL granted = UIApplication.sharedApplication.currentUserNotificationSettings.types != UIUserNotificationTypeNone;

    if (RapidopsPushNotifications.sharedInstance.permissionCompletion)
        RapidopsPushNotifications.sharedInstance.permissionCompletion(granted, nil);

    [self Rapidops_application:application didRegisterUserNotificationSettings:notificationSettings];
}

- (void)Rapidops_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
{
    Rapidops_LOG(@"App didReceiveRemoteNotification:fetchCompletionHandler");

    [RapidopsPushNotifications.sharedInstance handleNotification:userInfo];

    [self Rapidops_application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

#elif TARGET_OS_OSX
- (void)Rapidops_application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *,id> *)userInfo
{
    Rapidops_LOG(@"App didReceiveRemoteNotification:");

    [RapidopsPushNotifications.sharedInstance handleNotification:userInfo];

    [self Rapidops_application:application didReceiveRemoteNotification:userInfo];
}
#endif

@end
#pragma GCC diagnostic pop
