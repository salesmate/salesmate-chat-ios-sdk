// RapidopsCommon.m
//
 
//
 

#import "RapidopsCommon.h"
#include <CommonCrypto/CommonDigest.h>

@interface RapidopsCommon ()
{
    NSCalendar* gregorianCalendar;
    NSTimeInterval startTime;
}
@property long long lastTimestamp;
#if (TARGET_OS_IOS || TARGET_OS_TV)
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
#endif
@end

NSString* const kRapidopsSDKVersion = @"19.02";
NSString* const kRapidopsSDKName = @"objc-native-ios";

NSString* const kRapidopsParentDeviceIDTransferKey = @"kRapidopsParentDeviceIDTransferKey";
NSString* const kRapidopsAttributionIDFAKey = @"idfa";

NSString* const kRapidopsErrorDomain = @"ly.count.ErrorDomain";

@implementation RapidopsCommon

+ (instancetype)sharedInstance
{
    static RapidopsCommon *s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        gregorianCalendar = [NSCalendar.alloc initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        startTime = NSDate.date.timeIntervalSince1970;
    }

    return self;
}

void RapidopsInternalLog(NSString *format, ...)
{
    if (!RapidopsCommon.sharedInstance.enableDebug)
        return;

    va_list args;
    va_start(args, format);

    NSString* logFormat = [NSString stringWithFormat:@"[Rapidops] %@", format];
    NSString* logString = [NSString.alloc initWithFormat:logFormat arguments:args];
    NSLog(@"%@", logString);

    va_end(args);
}


#pragma mark - Time/Date related methods
- (NSInteger)hourOfDay
{
    NSDateComponents* components = [gregorianCalendar components:NSCalendarUnitHour fromDate:NSDate.date];
    return components.hour;
}

- (NSInteger)dayOfWeek
{
    NSDateComponents* components = [gregorianCalendar components:NSCalendarUnitWeekday fromDate:NSDate.date];
    return components.weekday - 1;
}

- (NSInteger)timeZone
{
    return NSTimeZone.systemTimeZone.secondsFromGMT / 60;
}

- (NSInteger)timeSinceLaunch
{
    return (int)NSDate.date.timeIntervalSince1970 - startTime;
}

- (NSTimeInterval)uniqueTimestamp
{
    long long now = floor(NSDate.date.timeIntervalSince1970 * 1000);

    if (now <= self.lastTimestamp)
        self.lastTimestamp++;
    else
        self.lastTimestamp = now;

    return (NSTimeInterval)(self.lastTimestamp / 1000.0);
}

#pragma mark - Watch Connectivity

- (void)startAppleWatchMatching
{
    if (!self.enableAppleWatch)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForAppleWatch)
        return;

#if (TARGET_OS_IOS || TARGET_OS_WATCH)
    if (@available(iOS 9.0, *))
    {
        if ([WCSession isSupported])
        {
            WCSession.defaultSession.delegate = (id<WCSessionDelegate>)self;
            [WCSession.defaultSession activateSession];
        }
    }
#endif

#if TARGET_OS_IOS
    if (@available(iOS 9.0, *))
    {
        if (WCSession.defaultSession.paired && WCSession.defaultSession.watchAppInstalled)
        {
            [WCSession.defaultSession transferUserInfo:@{kRapidopsParentDeviceIDTransferKey: RapidopsDeviceInfo.sharedInstance.deviceID}];
            Rapidops_LOG(@"Transferring parent device ID %@ ...", RapidopsDeviceInfo.sharedInstance.deviceID);
        }
    }
#endif
}

#if TARGET_OS_WATCH
- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo
{
    Rapidops_LOG(@"Watch received user info: \n%@", userInfo);

    NSString* parentDeviceID = userInfo[kRapidopsParentDeviceIDTransferKey];

    if (parentDeviceID && ![parentDeviceID isEqualToString:[RapidopsPersistency.sharedInstance retrieveWatchParentDeviceID]])
    {
        [RapidopsConnectionManager.sharedInstance sendParentDeviceID:parentDeviceID];

        Rapidops_LOG(@"Parent device ID %@ added to queue.", parentDeviceID);

        [RapidopsPersistency.sharedInstance storeWatchParentDeviceID:parentDeviceID];
    }
}
#endif

#pragma mark - Attribution

- (void)startAttribution
{
    if (!self.enableAttribution)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForAttribution)
        return;

    NSDictionary* attribution = nil;

#if (TARGET_OS_IOS || TARGET_OS_TV)
#ifndef Rapidops_EXCLUDE_IDFA
    if (ASIdentifierManager.sharedManager.advertisingTrackingEnabled)
    {
        attribution = @{kRapidopsAttributionIDFAKey: ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString};
    }
#endif
#endif

    if (!attribution)
        return;

    [RapidopsConnectionManager.sharedInstance sendAttribution:[attribution RPD_JSONify]];
}

#pragma mark - Others

- (void)startBackgroundTask
{
#if (TARGET_OS_IOS || TARGET_OS_TV)
    if (self.bgTask != UIBackgroundTaskInvalid)
        return;

    self.bgTask = [UIApplication.sharedApplication beginBackgroundTaskWithExpirationHandler:^
    {
        [UIApplication.sharedApplication endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
#endif
}

- (void)finishBackgroundTask
{
#if (TARGET_OS_IOS || TARGET_OS_TV)
    if (self.bgTask != UIBackgroundTaskInvalid && !RapidopsConnectionManager.sharedInstance.connection)
    {
        [UIApplication.sharedApplication endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
#endif
}

#if (TARGET_OS_IOS || TARGET_OS_TV)
- (UIViewController *)topViewController
{
    UIViewController* topVC = UIApplication.sharedApplication.keyWindow.rootViewController;

    while (YES)
    {
        if (topVC.presentedViewController)
            topVC = topVC.presentedViewController;
         else if ([topVC isKindOfClass:UINavigationController.class])
             topVC = ((UINavigationController *)topVC).topViewController;
         else if ([topVC isKindOfClass:UITabBarController.class])
             topVC = ((UITabBarController *)topVC).selectedViewController;
         else
             break;
    }

    return topVC;
}

- (void)tryPresentingViewController:(UIViewController *)viewController
{
    UIViewController* topVC = self.topViewController;

    if (topVC)
    {
        [topVC presentViewController:viewController animated:YES completion:nil];
        return;
    }

    [self performSelector:@selector(tryPresentingViewController:) withObject:viewController afterDelay:1.0];
}
#endif

@end


#pragma mark - Internal ViewController
#if TARGET_OS_IOS
@implementation RPDInternalViewController : UIViewController

@end


@implementation RPDButton : UIButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    }

    return self;
}

- (void)touchUpInside:(id)sender
{
    if (self.onClick)
        self.onClick(self);
}

+ (RPDButton *)dismissAlertButton
{
    const CGFloat kRapidopsDismissButtonSize = 30.0;
    const CGFloat kRapidopsDismissButtonMargin = 10.0;
    RPDButton* dismissButton = [RPDButton buttonWithType:UIButtonTypeCustom];
    dismissButton.frame = (CGRect){UIScreen.mainScreen.bounds.size.width - kRapidopsDismissButtonSize - kRapidopsDismissButtonMargin, kRapidopsDismissButtonMargin, kRapidopsDismissButtonSize, kRapidopsDismissButtonSize};
    [dismissButton setTitle:@"✕" forState:UIControlStateNormal];
    [dismissButton setTitleColor:UIColor.grayColor forState:UIControlStateNormal];
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;

    return dismissButton;
}

@end
#endif

#pragma mark - Categories
NSString* RapidopsJSONFromObject(id object)
{
    if (!object)
        return nil;

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (error){ Rapidops_LOG(@"JSON can not be created: \n%@", error); }

    return [data RPD_stringUTF8];
}

@implementation NSString (Rapidops)
- (NSString *)RPD_URLEscaped
{
    NSCharacterSet* charset = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:charset];
}

- (NSString *)RPD_SHA256
{
    const char* s = [self UTF8String];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(s, (CC_LONG)strlen(s), digest);

    NSMutableString* hash = NSMutableString.new;
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [hash appendFormat:@"%02x", digest[i]];

    return hash;
}

- (NSData *)RPD_dataUTF8
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}
@end

@implementation NSArray (Rapidops)
- (NSString *)RPD_JSONify
{
    return [RapidopsJSONFromObject(self) RPD_URLEscaped];
}
@end

@implementation NSDictionary (Rapidops)
- (NSString *)RPD_JSONify
{
    return [RapidopsJSONFromObject(self) RPD_URLEscaped];
}
@end

@implementation NSData (Rapidops)
- (NSString *)RPD_stringUTF8
{
    return [NSString.alloc initWithData:self encoding:NSUTF8StringEncoding];
}
@end
