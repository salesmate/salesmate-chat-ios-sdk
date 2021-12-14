// RapidopsCommon.h
//
 
//
 

#import <Foundation/Foundation.h>
#import "Rapidops.h"
#import "Rapidops_OpenUDID.h"
#import "RapidopsPersistency.h"
#import "RapidopsConnectionManager.h"
#import "RapidopsEvent.h"
#import "RapidopsUserDetails.h"
#import "RapidopsDeviceInfo.h"
#import "RapidopsCrashReporter.h"
#import "RapidopsAPMNetworkLog.h"
#import "RapidopsAPM.h"
#import "RapidopsConfig.h"
#import "RapidopsViewTracking.h"
#import "RapidopsStarRating.h"
#import "RapidopsPushNotifications.h"
#import "RapidopsNotificationService.h"
#import "RapidopsConsentManager.h"
#import "RapidopsLocationManager.h"
#import "RapidopsRemoteConfig.h"

#if DEBUGH
#define Rapidops_LOG(fmt, ...) RapidopsInternalLog(fmt, ##__VA_ARGS__)
#else
#define Rapidops_LOG(...)
#endif

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#ifndef Rapidops_EXCLUDE_IDFA
#import <AdSupport/ASIdentifierManager.h>
#endif
#import "WatchConnectivity/WatchConnectivity.h"
#endif

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#import "WatchConnectivity/WatchConnectivity.h"
#endif

#if TARGET_OS_TV
#import <UIKit/UIKit.h>
#ifndef Rapidops_EXCLUDE_IDFA
#import <AdSupport/ASIdentifierManager.h>
#endif
#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#import <objc/runtime.h>

extern NSString* const kRapidopsSDKVersion;
extern NSString* const kRapidopsSDKName;

extern NSString* const kRapidopsErrorDomain;

NS_ERROR_ENUM(kRapidopsErrorDomain)
{
    RPDErrorFeedbackWidgetNotAvailable = 10001,
    RPDErrorFeedbackWidgetNotTargetedForDevice = 10002,
    RPDErrorRemoteConfigGeneralAPIError = 10011,
};

@interface RapidopsCommon : NSObject

@property (nonatomic) BOOL hasStarted;
@property (nonatomic) BOOL enableDebug;
@property (nonatomic) BOOL enableAppleWatch;
@property (nonatomic) BOOL enableAttribution;
@property (nonatomic) BOOL manualSessionHandling;

void RapidopsInternalLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

+ (instancetype)sharedInstance;
- (NSInteger)hourOfDay;
- (NSInteger)dayOfWeek;
- (NSInteger)timeZone;
- (NSInteger)timeSinceLaunch;
- (NSTimeInterval)uniqueTimestamp;

- (void)startBackgroundTask;
- (void)finishBackgroundTask;

#if (TARGET_OS_IOS || TARGET_OS_TV)
- (UIViewController *)topViewController;
- (void)tryPresentingViewController:(UIViewController *)viewController;
#endif

- (void)startAppleWatchMatching;
- (void)startAttribution;
@end


#if TARGET_OS_IOS
@interface RPDInternalViewController : UIViewController
@end

@interface RPDButton : UIButton
@property (nonatomic, copy) void (^onClick)(id sender);
+ (RPDButton *)dismissAlertButton;
@end
#endif


@interface NSString (Rapidops)
- (NSString *)RPD_URLEscaped;
- (NSString *)RPD_SHA256;
- (NSData *)RPD_dataUTF8;
@end

@interface NSArray (Rapidops)
- (NSString *)RPD_JSONify;
@end

@interface NSDictionary (Rapidops)
- (NSString *)RPD_JSONify;
@end

@interface NSData (Rapidops)
- (NSString *)RPD_stringUTF8;
@end

@interface Rapidops (RecordReservedEvent)
- (void)recordReservedEvent:(NSString *)key segmentation:(NSDictionary *)segmentation;
- (void)recordReservedEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(NSUInteger)count sum:(double)sum duration:(NSTimeInterval)duration timestamp:(NSTimeInterval)timestamp;
@end

@interface RapidopsUserDetails (ClearUserDetails)
- (void)clearUserDetails;
@end
