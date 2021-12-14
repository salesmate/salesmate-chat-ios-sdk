// RapidopsNotificationService.h
//
 
//
 

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <UserNotifications/UserNotifications.h>
#endif

NS_ASSUME_NONNULL_BEGIN

extern NSString* const kRapidopsActionIdentifier;

extern NSString* const kRapidopsPNKeyRapidopsPayload;
extern NSString* const kRapidopsPNKeyNotificationID;
extern NSString* const kRapidopsPNKeyButtons;
extern NSString* const kRapidopsPNKeyDefaultURL;
extern NSString* const kRapidopsPNKeyAttachment;
extern NSString* const kRapidopsPNKeyActionButtonIndex;
extern NSString* const kRapidopsPNKeyActionButtonTitle;
extern NSString* const kRapidopsPNKeyActionButtonURL;

@interface RapidopsNotificationService : NSObject
#if TARGET_OS_IOS
+ (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *))contentHandler API_AVAILABLE(ios(10.0));
#endif

NS_ASSUME_NONNULL_END

@end
