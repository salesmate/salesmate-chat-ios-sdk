// RapidopsPushNotifications.h
//
 
//
 

#import <Foundation/Foundation.h>

@interface RapidopsPushNotifications : NSObject

@property (nonatomic) BOOL isEnabledOnInitialConfig;
@property (nonatomic) BOOL isTestDevice;
@property (nonatomic) BOOL sendPushTokenAlways;
@property (nonatomic) BOOL doNotShowAlertForNotifications;
@property (nonatomic) NSNotification* launchNotification;

+ (instancetype)sharedInstance;

#if (TARGET_OS_IOS || TARGET_OS_OSX)
- (void)startPushNotifications;
- (void)stopPushNotifications;
- (void)askForNotificationPermissionWithOptions:(NSUInteger)options completionHandler:(void (^)(BOOL granted, NSError * error))completionHandler;
- (void)recordActionForNotification:(NSDictionary *)userInfo clickedButtonIndex:(NSInteger)buttonIndex;
- (void)sendToken;
- (void)clearToken;
#endif
@end
