// RapidopsConfig.m
//
 
//
 

#import "RapidopsCommon.h"

@implementation RapidopsConfig

//NOTE: Rapidops features
#if TARGET_OS_IOS
    NSString* const RPDPushNotifications = @"RPDPushNotifications";
    NSString* const RPDCrashReporting = @"RPDCrashReporting";
    NSString* const RPDAutoViewTracking = @"RPDAutoViewTracking";
#elif TARGET_OS_TV
    NSString* const RPDAutoViewTracking = @"RPDAutoViewTracking";
#elif TARGET_OS_OSX
    NSString* const RPDPushNotifications = @"RPDPushNotifications";
#endif
//NOTE: Disable APM feature until Rapidops Server completely supports it
// NSString* const RPDAPM = @"RPDAPM";


//NOTE: Device ID options
#if TARGET_OS_IOS
    NSString* const RPDIDFA = @"RPDIDFA";
    NSString* const RPDIDFV = @"RPDIDFV";
    NSString* const RPDOpenUDID = @"RPDOpenUDID";
#elif TARGET_OS_OSX
    NSString* const RPDOpenUDID = @"RPDOpenUDID";
#endif


- (instancetype)init
{
    if (self = [super init])
    {
#if TARGET_OS_WATCH
        self.updateSessionPeriod = 20.0;
        self.eventSendThreshold = 1;
        self.enableAppleWatch = YES;
#else
        self.updateSessionPeriod = 60.0;
        self.eventSendThreshold = 1;
#endif
        self.storedRequestsLimit = 1000;
        self.crashLogLimit = 100;

        self.location = kCLLocationCoordinate2DInvalid;
    }

    return self;
}

@end
