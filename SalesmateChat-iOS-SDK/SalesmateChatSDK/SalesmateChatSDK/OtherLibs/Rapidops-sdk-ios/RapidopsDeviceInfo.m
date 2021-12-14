// RapidopsDeviceInfo.m
//
 
//
 

#import "RapidopsCommon.h"
#import <mach-o/dyld.h>
#import <mach/mach_host.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#if TARGET_OS_IOS
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

NSString* const kRapidopsZeroIDFA = @"00000000-0000-0000-0000-000000000000";

NSString* const kRapidopsMetricKeyDevice             = @"device";
NSString* const kRapidopsMetricKeyOS                 = @"os";
NSString* const kRapidopsMetricKeyOSVersion          = @"osVersion";
NSString* const kRapidopsMetricKeyAppVersion         = @"appVersion";
NSString* const kRapidopsMetricKeyCarrier            = @"carrier";
NSString* const kRapidopsMetricKeyResolution         = @"resolution";
NSString* const kRapidopsMetricKeyDensity            = @"density";
NSString* const kRapidopsMetricKeyLocale             = @"locale";
NSString* const kRapidopsMetricKeyHasWatch           = @"haswatch";
NSString* const kRapidopsMetricKeyInstalledWatchApp  = @"installedwatchapp";

#if TARGET_OS_IOS
@interface RapidopsDeviceInfo ()
@property (nonatomic) CTTelephonyNetworkInfo* networkInfo;
@end
#endif

@implementation RapidopsDeviceInfo

+ (instancetype)sharedInstance
{
    static RapidopsDeviceInfo *s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.deviceID = [RapidopsPersistency.sharedInstance retrieveStoredDeviceID];
#if TARGET_OS_IOS
        //NOTE: Handle Limit Ad Tracking zero-IDFA problem
        if ([self.deviceID isEqualToString:kRapidopsZeroIDFA])
            [self initializeDeviceID:RPDIDFV];

        self.networkInfo = CTTelephonyNetworkInfo.new;
#endif
    }

    return self;
}

- (void)initializeDeviceID:(NSString *)deviceID
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

#if TARGET_OS_IOS
    if (!deviceID || !deviceID.length)
        self.deviceID = UIDevice.currentDevice.identifierForVendor.UUIDString;
    else if ([deviceID isEqualToString:RPDIDFV])
        self.deviceID = UIDevice.currentDevice.identifierForVendor.UUIDString;
    else if ([deviceID isEqualToString:RPDIDFA])
        self.deviceID = [self zeroSafeIDFA];
    else if ([deviceID isEqualToString:RPDOpenUDID])
        self.deviceID = [Rapidops_OpenUDID value];
    else
        self.deviceID = deviceID;

#elif TARGET_OS_WATCH
    if (!deviceID || !deviceID.length)
        self.deviceID = NSUUID.UUID.UUIDString;
    else
        self.deviceID = deviceID;

#elif TARGET_OS_TV
    if (!deviceID || !deviceID.length)
        self.deviceID = NSUUID.UUID.UUIDString;
    else
        self.deviceID = deviceID;

#elif TARGET_OS_OSX
    if (!deviceID || !deviceID.length)
        self.deviceID = NSUUID.UUID.UUIDString;
    else if ([deviceID isEqualToString:RPDOpenUDID])
        self.deviceID = [Rapidops_OpenUDID value];
    else
        self.deviceID = deviceID;
#else
    self.deviceID = @"UnsupportedPlaftormDevice";
#endif

#pragma GCC diagnostic pop

    [RapidopsPersistency.sharedInstance storeDeviceID:self.deviceID];
}

- (NSString *)zeroSafeIDFA
{
#if TARGET_OS_IOS
#ifndef Rapidops_EXCLUDE_IDFA
    NSString* IDFA = ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString;
#else
    NSString* IDFA = UIDevice.currentDevice.identifierForVendor.UUIDString;
#endif
    //NOTE: Handle Limit Ad Tracking zero-IDFA problem
    if ([IDFA isEqualToString:kRapidopsZeroIDFA])
        IDFA = UIDevice.currentDevice.identifierForVendor.UUIDString;

    return IDFA;
#else
    return nil;
#endif
}

#pragma mark -

+ (NSString *)device
{
#if TARGET_OS_OSX
    char *modelKey = "hw.model";
#else
    char *modelKey = "hw.machine";
#endif
    size_t size;
    sysctlbyname(modelKey, NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname(modelKey, model, &size, NULL, 0);
    NSString *modelString = @(model);
    free(model);
    return modelString;
}

+ (NSString *)architecture
{
    NSString* architecture = nil;

#if TARGET_OS_IOS
    size_t size;
    cpu_type_t type;

    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);

    if (type == CPU_TYPE_ARM64)
        architecture = @"arm64";
    else if (type == CPU_TYPE_ARM)
    {
        NSString* device = RapidopsDeviceInfo.device;
        NSInteger modelNo = [[device substringFromIndex:device.length - 1] integerValue];
        if (([device hasPrefix:@"iPhone5,"] && modelNo >= 1 && modelNo <= 4)  ||
           ([device hasPrefix:@"iPad3,"]   && modelNo >= 4 && modelNo <= 6))
            architecture = @"armv7s";
        else
            architecture = @"armv7";
    }
#endif
    return architecture;
}

+ (NSString *)osName
{
#if TARGET_OS_IOS
    return @"iOS";
#elif TARGET_OS_WATCH
    return @"watchOS";
#elif TARGET_OS_TV
    return @"tvOS";
#else
    return @"macOS";
#endif
}

+ (NSString *)osVersion
{
#if TARGET_OS_IOS
    return UIDevice.currentDevice.systemVersion;
#elif TARGET_OS_WATCH
    return WKInterfaceDevice.currentDevice.systemVersion;
#elif TARGET_OS_TV
    return UIDevice.currentDevice.systemVersion;
#else
    return [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"][@"ProductVersion"];
#endif
}

+ (NSString *)carrier
{
#if TARGET_OS_IOS
    return RapidopsDeviceInfo.sharedInstance.networkInfo.subscriberCellularProvider.carrierName;
#endif
    return nil;
}

+ (NSString *)resolution
{
#if TARGET_OS_IOS
    CGRect bounds = UIScreen.mainScreen.bounds;
    CGFloat scale = UIScreen.mainScreen.scale;
#elif TARGET_OS_WATCH
    CGRect bounds = WKInterfaceDevice.currentDevice.screenBounds;
    CGFloat scale = WKInterfaceDevice.currentDevice.screenScale;
#elif TARGET_OS_TV
    CGRect bounds = (CGRect){0,0,1920,1080};
    CGFloat scale = 1.0;
#else
    NSRect bounds = NSScreen.mainScreen.frame;
    CGFloat scale = NSScreen.mainScreen.backingScaleFactor;
#endif
    return [NSString stringWithFormat:@"%gx%g", bounds.size.width * scale, bounds.size.height * scale];
}

+ (NSString *)density
{
#if TARGET_OS_IOS
    CGFloat scale = UIScreen.mainScreen.scale;
#elif TARGET_OS_WATCH
    CGFloat scale = WKInterfaceDevice.currentDevice.screenScale;
#elif TARGET_OS_TV
    CGFloat scale = 1.0;
#else
    CGFloat scale = NSScreen.mainScreen.backingScaleFactor;
#endif
    return [NSString stringWithFormat:@"@%dx", (int)scale];
}

+ (NSString *)locale
{
    return NSLocale.currentLocale.localeIdentifier;
}

+ (NSString *)appVersion
{
    return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString *)appBuild
{
    return [NSBundle.mainBundle objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
}

#if TARGET_OS_IOS
+ (NSInteger)hasWatch
{
    if (@available(iOS 9.0, *))
        return (NSInteger)WCSession.defaultSession.paired;

    return 0;
}

+ (NSInteger)installedWatchApp
{
    if (@available(iOS 9.0, *))
        return (NSInteger)WCSession.defaultSession.watchAppInstalled;

    return 0;
}
#endif

+ (NSDictionary *)metricsAsDictionary
{
	NSMutableDictionary* metricsDictionary = NSMutableDictionary.new;
	metricsDictionary[kRapidopsMetricKeyDevice] = RapidopsDeviceInfo.device;
	metricsDictionary[kRapidopsMetricKeyOS] = RapidopsDeviceInfo.osName;
	metricsDictionary[kRapidopsMetricKeyOSVersion] = RapidopsDeviceInfo.osVersion;
	metricsDictionary[kRapidopsMetricKeyAppVersion] = RapidopsDeviceInfo.appVersion;
	
	NSString *carrier = RapidopsDeviceInfo.carrier;
	if (carrier)
		metricsDictionary[kRapidopsMetricKeyCarrier] = carrier;
	
	metricsDictionary[kRapidopsMetricKeyResolution] = RapidopsDeviceInfo.resolution;
	metricsDictionary[kRapidopsMetricKeyDensity] = RapidopsDeviceInfo.density;
	metricsDictionary[kRapidopsMetricKeyLocale] = RapidopsDeviceInfo.locale;
	return metricsDictionary;
}

+ (NSString *)metrics
{
    NSMutableDictionary* metricsDictionary = NSMutableDictionary.new;
    metricsDictionary[kRapidopsMetricKeyDevice] = RapidopsDeviceInfo.device;
    metricsDictionary[kRapidopsMetricKeyOS] = RapidopsDeviceInfo.osName;
    metricsDictionary[kRapidopsMetricKeyOSVersion] = RapidopsDeviceInfo.osVersion;
    metricsDictionary[kRapidopsMetricKeyAppVersion] = RapidopsDeviceInfo.appVersion;

    NSString *carrier = RapidopsDeviceInfo.carrier;
    if (carrier)
        metricsDictionary[kRapidopsMetricKeyCarrier] = carrier;

    metricsDictionary[kRapidopsMetricKeyResolution] = RapidopsDeviceInfo.resolution;
    metricsDictionary[kRapidopsMetricKeyDensity] = RapidopsDeviceInfo.density;
    metricsDictionary[kRapidopsMetricKeyLocale] = RapidopsDeviceInfo.locale;

#if TARGET_OS_IOS
    if (RapidopsCommon.sharedInstance.enableAppleWatch)
    {
        if (RapidopsConsentManager.sharedInstance.consentForAppleWatch)
        {
            metricsDictionary[kRapidopsMetricKeyHasWatch] = @(RapidopsDeviceInfo.hasWatch);
            metricsDictionary[kRapidopsMetricKeyInstalledWatchApp] = @(RapidopsDeviceInfo.installedWatchApp);
        }
    }
#endif

    return [metricsDictionary RPD_JSONify];
}

#pragma mark -

+ (NSUInteger)connectionType
{
    typedef enum : NSInteger
    {
        RPDConnectionNone,
        RPDConnectionWiFi,
        RPDConnectionCellNetwork,
        RPDConnectionCellNetwork2G,
        RPDConnectionCellNetwork3G,
        RPDConnectionCellNetworkLTE
    } RPDConnectionType;

    RPDConnectionType connType = RPDConnectionNone;

    @try
    {
        struct ifaddrs *interfaces, *i;

        if (!getifaddrs(&interfaces))
        {
            i = interfaces;

            while (i != NULL)
            {
                if (i->ifa_addr->sa_family == AF_INET)
                {
                    if ([[NSString stringWithUTF8String:i->ifa_name] isEqualToString:@"pdp_ip0"])
                    {
                        connType = RPDConnectionCellNetwork;

#if TARGET_OS_IOS
                        NSDictionary* connectionTypes =
                        @{
                            CTRadioAccessTechnologyGPRS: @(RPDConnectionCellNetwork2G),
                            CTRadioAccessTechnologyEdge: @(RPDConnectionCellNetwork2G),
                            CTRadioAccessTechnologyCDMA1x: @(RPDConnectionCellNetwork2G),
                            CTRadioAccessTechnologyWCDMA: @(RPDConnectionCellNetwork3G),
                            CTRadioAccessTechnologyHSDPA: @(RPDConnectionCellNetwork3G),
                            CTRadioAccessTechnologyHSUPA: @(RPDConnectionCellNetwork3G),
                            CTRadioAccessTechnologyCDMAEVDORev0: @(RPDConnectionCellNetwork3G),
                            CTRadioAccessTechnologyCDMAEVDORevA: @(RPDConnectionCellNetwork3G),
                            CTRadioAccessTechnologyCDMAEVDORevB: @(RPDConnectionCellNetwork3G),
                            CTRadioAccessTechnologyeHRPD: @(RPDConnectionCellNetwork3G),
                            CTRadioAccessTechnologyLTE: @(RPDConnectionCellNetworkLTE)
                        };

                        NSString* radioAccessTech = RapidopsDeviceInfo.sharedInstance.networkInfo.currentRadioAccessTechnology;
                        if (connectionTypes[radioAccessTech])
                            connType = [connectionTypes[radioAccessTech] integerValue];
#endif
                    }
                    else if ([[NSString stringWithUTF8String:i->ifa_name] isEqualToString:@"en0"])
                    {
                        connType = RPDConnectionWiFi;
                        break;
                    }
                }

                i = i->ifa_next;
            }
        }

        freeifaddrs(interfaces);
    }
    @catch (NSException *exception)
    {
        Rapidops_LOG(@"Connection type can not be retrieved: \n%@", exception);
    }

    return connType;
}

+ (unsigned long long)freeRAM
{
    vm_statistics_data_t vms;
    mach_msg_type_number_t ic = HOST_VM_INFO_COUNT;
    kern_return_t kr = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vms, &ic);
    if (kr != KERN_SUCCESS)
        return -1;

    return vm_page_size * (vms.free_count);
}

+ (unsigned long long)totalRAM
{
    return NSProcessInfo.processInfo.physicalMemory;
}

+ (unsigned long long)freeDisk
{
    return [[NSFileManager.defaultManager attributesOfFileSystemForPath:NSHomeDirectory() error:nil][NSFileSystemFreeSize] longLongValue];
}

+ (unsigned long long)totalDisk
{
    return [[NSFileManager.defaultManager attributesOfFileSystemForPath:NSHomeDirectory() error:nil][NSFileSystemSize] longLongValue];
}

+ (NSInteger)batteryLevel
{
#if TARGET_OS_IOS
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    return abs((int)(UIDevice.currentDevice.batteryLevel * 100));
#else
    return 100;
#endif
}

+ (NSString *)orientation
{
#if TARGET_OS_IOS
    NSArray *orientations = @[@"Unknown", @"Portrait", @"PortraitUpsideDown", @"LandscapeLeft", @"LandscapeRight", @"FaceUp", @"FaceDown"];
    return orientations[UIDevice.currentDevice.orientation];
#else
    return @"Unknown";
#endif

}


+ (NSString *)OpenGLESversion
{
#if TARGET_OS_IOS
    EAGLContext *aContext;

    aContext = [EAGLContext.alloc initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (aContext)
        return @"3.0";

    aContext = [EAGLContext.alloc initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (aContext)
        return @"2.0";

    return @"1.0";
#else
    return @"1.0";
#endif
}


+ (BOOL)isJailbroken
{
    FILE *f = fopen("/bin/bash", "r");
    BOOL isJailbroken = (f != NULL);
    fclose(f);
    return isJailbroken;
}

+ (BOOL)isInBackground
{
#if TARGET_OS_IOS
    return UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
#else
    return NO;
#endif
}

@end
