// RapidopsPersistency.m
//
 
//
 

#import "RapidopsCommon.h"

@interface RapidopsPersistency ()
@property (nonatomic) NSMutableArray* queuedRequests;
@property (nonatomic) NSMutableArray* recordedEvents;
@property (nonatomic) NSMutableDictionary* startedEvents;
@end

@implementation RapidopsPersistency
NSString* const kRapidopsQueuedRequestsPersistencyKey = @"kRapidopsQueuedRequestsPersistencyKey";
NSString* const kRapidopsStartedEventsPersistencyKey = @"kRapidopsStartedEventsPersistencyKey";
NSString* const kRapidopsStoredDeviceIDKey = @"kRapidopsStoredDeviceIDKey";
NSString* const kRapidopsWatchParentDeviceIDKey = @"kRapidopsWatchParentDeviceIDKey";
NSString* const kRapidopsStarRatingStatusKey = @"kRapidopsStarRatingStatusKey";
NSString* const kRapidopsNotificationPermissionKey = @"kRapidopsNotificationPermissionKey";
NSString* const kRapidopsRemoteConfigPersistencyKey = @"kRapidopsRemoteConfigPersistencyKey";

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsPersistency* s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSData* readData = [NSData dataWithContentsOfURL:[self storageFileURL]];

        if (readData)
        {
            NSDictionary* readDict = [NSKeyedUnarchiver unarchiveObjectWithData:readData];

            self.queuedRequests = [readDict[kRapidopsQueuedRequestsPersistencyKey] mutableCopy];
        }

        if (!self.queuedRequests)
            self.queuedRequests = NSMutableArray.new;

        if (!self.startedEvents)
            self.startedEvents = NSMutableDictionary.new;

        self.recordedEvents = NSMutableArray.new;
    }

    return self;
}

#pragma mark ---

- (void)addToQueue:(NSString *)queryString
{
    @synchronized (self)
    {
        [self.queuedRequests addObject:queryString];

        if (self.queuedRequests.count > self.storedRequestsLimit && !RapidopsConnectionManager.sharedInstance.connection)
            [self.queuedRequests removeObjectAtIndex:0];
    }
}

- (void)removeFromQueue:(NSString *)queryString
{
    @synchronized (self)
    {
        if (self.queuedRequests.count)
            [self.queuedRequests removeObject:queryString inRange:(NSRange){0, 1}];
    }
}

- (NSString *)firstItemInQueue
{
    @synchronized (self)
    {
        return self.queuedRequests.firstObject;
    }
}

#pragma mark ---

- (void)recordEvent:(RapidopsEvent *)event
{
    @synchronized (self.recordedEvents)
    {
        [self.recordedEvents addObject:event];

        if (self.recordedEvents.count >= self.eventSendThreshold)
            [RapidopsConnectionManager.sharedInstance sendEvents];
    }
}

- (NSString *)serializedRecordedEvents
{
    NSMutableArray* tempArray = NSMutableArray.new;

    @synchronized (self.recordedEvents)
    {
        if (self.recordedEvents.count == 0)
            return nil;

        for (RapidopsEvent* event in self.recordedEvents.copy)
        {
            [tempArray addObject:[event dictionaryRepresentation]];
            [self.recordedEvents removeObject:event];
        }
    }

    return [tempArray RPD_JSONify];
}

- (NSMutableArray *)serializedRecordedEventsAsArray
{
	NSMutableArray* tempArray = NSMutableArray.new;
	
	@synchronized (self.recordedEvents)
	{
		if (self.recordedEvents.count == 0)
			return nil;
		
		for (RapidopsEvent* event in self.recordedEvents.copy)
		{
			[tempArray addObject:[event dictionaryRepresentationWithJson]];
			[self.recordedEvents removeObject:event];
		}
	}
	
	return tempArray ;
}

#pragma mark ---

- (void)recordTimedEvent:(RapidopsEvent *)event
{
    @synchronized (self.startedEvents)
    {
        if (self.startedEvents[event.key])
        {
            Rapidops_LOG(@"Event with key '%@' already started!", event.key);
            return;
        }

        self.startedEvents[event.key] = event;
    }
}

- (RapidopsEvent *)timedEventForKey:(NSString *)key
{
    @synchronized (self.startedEvents)
    {
        RapidopsEvent *event = self.startedEvents[key];
        [self.startedEvents removeObjectForKey:key];

        return event;
    }
}

- (void)clearAllTimedEvents
{
    @synchronized (self.startedEvents)
    {
        [self.startedEvents removeAllObjects];
    }
}

#pragma mark ---

- (NSURL *)storageFileURL
{
    NSString* const kRapidopsPersistencyFileName = @"Rapidops.dat";

    static NSURL *url = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
#if TARGET_OS_TV
        NSSearchPathDirectory directory = NSCachesDirectory;
#else
        NSSearchPathDirectory directory = NSApplicationSupportDirectory;
#endif
        url = [[NSFileManager.defaultManager URLsForDirectory:directory inDomains:NSUserDomainMask] lastObject];

#if TARGET_OS_OSX
        url = [url URLByAppendingPathComponent:NSBundle.mainBundle.bundleIdentifier];
#endif
        NSError *error = nil;

        if (![NSFileManager.defaultManager fileExistsAtPath:url.path])
        {
            [NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
            if (error){ Rapidops_LOG(@"Application Support directory can not be created: \n%@", error); }
        }

        url = [url URLByAppendingPathComponent:kRapidopsPersistencyFileName];
    });

    return url;
}

- (void)saveToFile
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        [self saveToFileSync];
    });
}

- (void)saveToFileSync
{
    NSData* saveData;

    @synchronized (self)
    {
        saveData = [NSKeyedArchiver archivedDataWithRootObject:@{kRapidopsQueuedRequestsPersistencyKey: self.queuedRequests}];
    }

    [saveData writeToFile:[self storageFileURL].path atomically:YES];
    [RapidopsCommon.sharedInstance finishBackgroundTask];
}

#pragma mark ---

- (NSString* )retrieveStoredDeviceID
{
    NSString* retrievedDeviceID = [NSUserDefaults.standardUserDefaults objectForKey:kRapidopsStoredDeviceIDKey];

    if (retrievedDeviceID)
    {
        Rapidops_LOG(@"Device ID successfully retrieved from UserDefaults: %@", retrievedDeviceID);
        return retrievedDeviceID;
    }

    NSDictionary *keychainDict =
    @{
        (__bridge id)kSecAttrAccount:       kRapidopsStoredDeviceIDKey,
        (__bridge id)kSecAttrService:       kRapidopsStoredDeviceIDKey,
        (__bridge id)kSecClass:             (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccessible:    (__bridge id)kSecAttrAccessibleAlways,
        (__bridge id)kSecReturnData:        (__bridge id)kCFBooleanTrue,
        (__bridge id)kSecReturnAttributes:  (__bridge id)kCFBooleanTrue
    };

    CFDictionaryRef resultDictRef = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainDict, (CFTypeRef *)&resultDictRef);
    if (status == noErr)
    {
        NSDictionary *resultDict = (__bridge_transfer NSDictionary *)resultDictRef;
        NSData *data = resultDict[(__bridge id)kSecValueData];

        if (data)
        {
            retrievedDeviceID = [data RPD_stringUTF8];

            Rapidops_LOG(@"Device ID successfully retrieved from KeyChain: %@", retrievedDeviceID);

            [NSUserDefaults.standardUserDefaults setObject:retrievedDeviceID forKey:kRapidopsStoredDeviceIDKey];
            [NSUserDefaults.standardUserDefaults synchronize];

            return retrievedDeviceID;
        }
    }

    Rapidops_LOG(@"Device ID can not be retrieved!");

    return nil;
}

- (void)storeDeviceID:(NSString *)deviceID
{
    [NSUserDefaults.standardUserDefaults setObject:deviceID forKey:kRapidopsStoredDeviceIDKey];
    [NSUserDefaults.standardUserDefaults synchronize];

    NSDictionary *keychainDict =
    @{
        (__bridge id)kSecAttrAccount:       kRapidopsStoredDeviceIDKey,
        (__bridge id)kSecAttrService:       kRapidopsStoredDeviceIDKey,
        (__bridge id)kSecClass:             (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccessible:    (__bridge id)kSecAttrAccessibleAlways,
        (__bridge id)kSecValueData:         [deviceID RPD_dataUTF8]
    };

    SecItemDelete((__bridge CFDictionaryRef)keychainDict);

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainDict, NULL);

    if (status == noErr)
    {
        Rapidops_LOG(@"Device ID successfully stored: %@", deviceID);
    }
    else
    {
        Rapidops_LOG(@"Device ID can not be stored! %d", (int)status);
    }
}

- (NSString *)retrieveWatchParentDeviceID
{
    return [NSUserDefaults.standardUserDefaults objectForKey:kRapidopsWatchParentDeviceIDKey];
}

- (void)storeWatchParentDeviceID:(NSString *)deviceID
{
    [NSUserDefaults.standardUserDefaults setObject:deviceID forKey:kRapidopsWatchParentDeviceIDKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSDictionary *)retrieveStarRatingStatus
{
    NSDictionary* status = [NSUserDefaults.standardUserDefaults objectForKey:kRapidopsStarRatingStatusKey];
    if (!status)
        status = NSDictionary.new;

    return status;
}

- (void)storeStarRatingStatus:(NSDictionary *)status
{
    [NSUserDefaults.standardUserDefaults setObject:status forKey:kRapidopsStarRatingStatusKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (BOOL)retrieveNotificationPermission
{
    return [NSUserDefaults.standardUserDefaults boolForKey:kRapidopsNotificationPermissionKey];
}

- (void)storeNotificationPermission:(BOOL)allowed
{
    [NSUserDefaults.standardUserDefaults setBool:allowed forKey:kRapidopsNotificationPermissionKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSDictionary *)retrieveRemoteConfig
{
    NSDictionary* remoteConfig = [NSUserDefaults.standardUserDefaults objectForKey:kRapidopsRemoteConfigPersistencyKey];
    if (!remoteConfig)
        remoteConfig = NSDictionary.new;

    return remoteConfig;
}

- (void)storeRemoteConfig:(NSDictionary *)remoteConfig
{
    [NSUserDefaults.standardUserDefaults setObject:remoteConfig forKey:kRapidopsRemoteConfigPersistencyKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
