// RapidopsDeviceInfo.h
//
 
//
 

#import <Foundation/Foundation.h>

extern NSString* const kRapidopsZeroIDFA;

@interface RapidopsDeviceInfo : NSObject

@property (nonatomic) NSString *deviceID;

+ (instancetype)sharedInstance;
- (void)initializeDeviceID:(NSString *)deviceID;
- (NSString *)zeroSafeIDFA;

+ (NSString *)device;
+ (NSString *)architecture;
+ (NSString *)osName;
+ (NSString *)osVersion;
+ (NSString *)carrier;
+ (NSString *)resolution;
+ (NSString *)density;
+ (NSString *)locale;
+ (NSString *)appVersion;
+ (NSString *)appBuild;
#if TARGET_OS_IOS
+ (NSInteger)hasWatch;
+ (NSInteger)installedWatchApp;
#endif

+ (NSString *)metrics;
+(NSMutableDictionary *)metricsAsDictionary;

+ (NSUInteger)connectionType;
+ (unsigned long long)freeRAM;
+ (unsigned long long)totalRAM;
+ (unsigned long long)freeDisk;
+ (unsigned long long)totalDisk;
+ (NSInteger)batteryLevel;
+ (NSString *)orientation;
+ (NSString *)OpenGLESversion;
+ (BOOL)isJailbroken;
+ (BOOL)isInBackground;
@end
