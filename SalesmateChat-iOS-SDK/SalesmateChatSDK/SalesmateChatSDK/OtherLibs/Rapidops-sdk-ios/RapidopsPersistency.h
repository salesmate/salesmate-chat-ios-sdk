// RapidopsPersistency.h
//
 
//
 

#import <Foundation/Foundation.h>

@class RapidopsEvent;

@interface RapidopsPersistency : NSObject

+ (instancetype)sharedInstance;

- (void)addToQueue:(NSString *)queryString;
- (void)removeFromQueue:(NSString *)queryString;
- (NSString *)firstItemInQueue;

- (void)recordEvent:(RapidopsEvent *)event;
- (NSString *)serializedRecordedEvents;
- (NSMutableArray *)serializedRecordedEventsAsArray;

- (void)recordTimedEvent:(RapidopsEvent *)event;
- (RapidopsEvent *)timedEventForKey:(NSString *)key;
- (void)clearAllTimedEvents;

- (void)saveToFile;
- (void)saveToFileSync;

- (NSString *)retrieveStoredDeviceID;
- (void)storeDeviceID:(NSString *)deviceID;

- (NSString *)retrieveWatchParentDeviceID;
- (void)storeWatchParentDeviceID:(NSString *)deviceID;

- (NSDictionary *)retrieveStarRatingStatus;
- (void)storeStarRatingStatus:(NSDictionary *)status;

- (BOOL)retrieveNotificationPermission;
- (void)storeNotificationPermission:(BOOL)allowed;


- (NSDictionary *)retrieveRemoteConfig;
- (void)storeRemoteConfig:(NSDictionary *)remoteConfig;

@property (nonatomic) NSUInteger eventSendThreshold;
@property (nonatomic) NSUInteger storedRequestsLimit;
@end
