// Rapidops.m
//
 
//
 

#pragma mark - Core

#import "RapidopsCommon.h"

@interface Rapidops ()
{
    NSTimer* timer;
    BOOL isSuspended;
}
@end

@implementation Rapidops

+ (instancetype)sharedInstance
{
    static Rapidops *s_sharedRapidops = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedRapidops = self.new;});
    return s_sharedRapidops;
}

- (instancetype)init
{
    if (self = [super init])
    {
#if (TARGET_OS_IOS  || TARGET_OS_TV)
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didEnterBackgroundCallBack:)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(willEnterForegroundCallBack:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(willTerminateCallBack:)
                                                   name:UIApplicationWillTerminateNotification
                                                 object:nil];
#elif TARGET_OS_OSX
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(willTerminateCallBack:)
                                                   name:NSApplicationWillTerminateNotification
                                                 object:nil];
#endif
    }

    return self;
}

#pragma mark ---

- (void)startWithConfig:(RapidopsConfig *)config
{
    if (RapidopsCommon.sharedInstance.hasStarted)
        return;

    RapidopsCommon.sharedInstance.hasStarted = YES;
    RapidopsCommon.sharedInstance.enableDebug = config.enableDebug;
    RapidopsConsentManager.sharedInstance.requiresConsent = config.requiresConsent;

    if (!config.appKey.length || [config.appKey isEqualToString:@"YOUR_APP_KEY"])
        [NSException raise:@"RapidopsAppKeyNotSetException" format:@"appKey property on RapidopsConfig object is not set"];

    if (!config.host.length || [config.host isEqualToString:@"https://YOUR_Rapidops_SERVER"])
        [NSException raise:@"RapidopsHostNotSetException" format:@"host property on RapidopsConfig object is not set"];

    Rapidops_LOG(@"Initializing with %@ SDK v%@", kRapidopsSDKName, kRapidopsSDKVersion);

    if (!RapidopsDeviceInfo.sharedInstance.deviceID || config.forceDeviceIDInitialization)
        [RapidopsDeviceInfo.sharedInstance initializeDeviceID:config.deviceID];

    RapidopsConnectionManager.sharedInstance.appKey = config.appKey;
    RapidopsConnectionManager.sharedInstance.tenantID = config.tenantID;
    BOOL hostHasExtraSlash = [[config.host substringFromIndex:config.host.length - 1] isEqualToString:@"/"];
    RapidopsConnectionManager.sharedInstance.host = hostHasExtraSlash ? [config.host substringToIndex:config.host.length - 1] : config.host;
    RapidopsConnectionManager.sharedInstance.alwaysUsePOST = config.alwaysUsePOST;
    RapidopsConnectionManager.sharedInstance.pinnedCertificates = config.pinnedCertificates;
    RapidopsConnectionManager.sharedInstance.customHeaderFieldName = config.customHeaderFieldName;
    RapidopsConnectionManager.sharedInstance.customHeaderFieldValue = config.customHeaderFieldValue;
    RapidopsConnectionManager.sharedInstance.secretSalt = config.secretSalt;
    RapidopsConnectionManager.sharedInstance.applyZeroIDFAFix = config.applyZeroIDFAFix;

    RapidopsPersistency.sharedInstance.eventSendThreshold = config.eventSendThreshold;
    RapidopsPersistency.sharedInstance.storedRequestsLimit = MAX(1, config.storedRequestsLimit);

    RapidopsCommon.sharedInstance.manualSessionHandling = config.manualSessionHandling;
    RapidopsCommon.sharedInstance.enableAppleWatch = config.enableAppleWatch;
    RapidopsCommon.sharedInstance.enableAttribution = config.enableAttribution;

    if (!RapidopsCommon.sharedInstance.manualSessionHandling)
        [RapidopsConnectionManager.sharedInstance beginSession];

#if TARGET_OS_IOS
    RapidopsStarRating.sharedInstance.message = config.starRatingMessage;
    RapidopsStarRating.sharedInstance.sessionCount = config.starRatingSessionCount;
    RapidopsStarRating.sharedInstance.disableAskingForEachAppVersion = config.starRatingDisableAskingForEachAppVersion;
    RapidopsStarRating.sharedInstance.ratingCompletionForAutoAsk = config.starRatingCompletion;
    [RapidopsStarRating.sharedInstance checkForAutoAsk];

    RapidopsLocationManager.sharedInstance.location = CLLocationCoordinate2DIsValid(config.location) ? [NSString stringWithFormat:@"%f,%f", config.location.latitude, config.location.longitude] : nil;
    RapidopsLocationManager.sharedInstance.city = config.city;
    RapidopsLocationManager.sharedInstance.ISOCountryCode = config.ISOCountryCode;
    RapidopsLocationManager.sharedInstance.IP = config.IP;
    [RapidopsLocationManager.sharedInstance sendLocationInfo];

    RapidopsCrashReporter.sharedInstance.crashSegmentation = config.crashSegmentation;
    RapidopsCrashReporter.sharedInstance.crashLogLimit = MAX(1, config.crashLogLimit);
    if ([config.features containsObject:RPDCrashReporting])
    {
        RapidopsCrashReporter.sharedInstance.isEnabledOnInitialConfig = YES;
        [RapidopsCrashReporter.sharedInstance startCrashReporting];
    }
#endif

#if (TARGET_OS_IOS || TARGET_OS_OSX)
    if ([config.features containsObject:RPDPushNotifications])
    {
        RapidopsPushNotifications.sharedInstance.isEnabledOnInitialConfig = YES;
        RapidopsPushNotifications.sharedInstance.isTestDevice = config.isTestDevice;
        RapidopsPushNotifications.sharedInstance.sendPushTokenAlways = config.sendPushTokenAlways;
        RapidopsPushNotifications.sharedInstance.doNotShowAlertForNotifications = config.doNotShowAlertForNotifications;
        RapidopsPushNotifications.sharedInstance.launchNotification = config.launchNotification;
        [RapidopsPushNotifications.sharedInstance startPushNotifications];
    }
#endif

#if (TARGET_OS_IOS || TARGET_OS_TV)
    if ([config.features containsObject:RPDAutoViewTracking])
    {
        RapidopsViewTracking.sharedInstance.isEnabledOnInitialConfig = YES;
        [RapidopsViewTracking.sharedInstance startAutoViewTracking];
    }
#endif

//NOTE: Disable APM feature until server completely supports it

    timer = [NSTimer scheduledTimerWithTimeInterval:config.updateSessionPeriod target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];

    [RapidopsCommon.sharedInstance startAppleWatchMatching];

    [RapidopsCommon.sharedInstance startAttribution];

    RapidopsRemoteConfig.sharedInstance.isEnabledOnInitialConfig = config.enableRemoteConfig;
    RapidopsRemoteConfig.sharedInstance.remoteConfigCompletionHandler = config.remoteConfigCompletionHandler;
    [RapidopsRemoteConfig.sharedInstance startRemoteConfig];

    [RapidopsConnectionManager.sharedInstance proceedOnQueue];
}

- (void)setNewDeviceID:(NSString *)deviceID onServer:(BOOL)onServer
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return;

    if (!RapidopsConsentManager.sharedInstance.hasAnyConsent)
        return;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

#if TARGET_OS_IOS
    if ([deviceID isEqualToString:RPDIDFA])
        deviceID = [RapidopsDeviceInfo.sharedInstance zeroSafeIDFA];
    else if ([deviceID isEqualToString:RPDIDFV])
        deviceID = UIDevice.currentDevice.identifierForVendor.UUIDString;
    else if ([deviceID isEqualToString:RPDOpenUDID])
        deviceID = [Rapidops_OpenUDID value];
#elif TARGET_OS_OSX
    if ([deviceID isEqualToString:RPDOpenUDID])
        deviceID = [Rapidops_OpenUDID value];
#endif

#pragma GCC diagnostic pop

    if ([deviceID isEqualToString:RapidopsDeviceInfo.sharedInstance.deviceID])
        return;

    if (onServer)
    {
        NSString* oldDeviceID = RapidopsDeviceInfo.sharedInstance.deviceID;

        [RapidopsDeviceInfo.sharedInstance initializeDeviceID:deviceID];

        [RapidopsConnectionManager.sharedInstance sendOldDeviceID:oldDeviceID];
    }
    else
    {
        [self suspend];

        [RapidopsDeviceInfo.sharedInstance initializeDeviceID:deviceID];

        [self resume];

        [RapidopsPersistency.sharedInstance clearAllTimedEvents];
    }

    [RapidopsRemoteConfig.sharedInstance clearCachedRemoteConfig];
    [RapidopsRemoteConfig.sharedInstance startRemoteConfig];
}

- (void)setCustomHeaderFieldValue:(NSString *)customHeaderFieldValue
{
    RapidopsConnectionManager.sharedInstance.customHeaderFieldValue = customHeaderFieldValue.copy;
    [RapidopsConnectionManager.sharedInstance proceedOnQueue];
}

#pragma mark ---

- (void)beginSession
{
    if (RapidopsCommon.sharedInstance.manualSessionHandling)
        [RapidopsConnectionManager.sharedInstance beginSession];
}

- (void)updateSession
{
    if (RapidopsCommon.sharedInstance.manualSessionHandling)
        [RapidopsConnectionManager.sharedInstance updateSession];
}

- (void)endSession
{
    if (RapidopsCommon.sharedInstance.manualSessionHandling)
        [RapidopsConnectionManager.sharedInstance endSession];
}

#pragma mark ---

- (void)onTimer:(NSTimer *)timer
{
    if (isSuspended)
        return;

    if (!RapidopsCommon.sharedInstance.manualSessionHandling)
        [RapidopsConnectionManager.sharedInstance updateSession];

    [RapidopsConnectionManager.sharedInstance sendEvents];
}

- (void)suspend
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return;

    if (isSuspended)
        return;

    Rapidops_LOG(@"Suspending...");

    isSuspended = YES;

    [RapidopsConnectionManager.sharedInstance sendEvents];

    if (!RapidopsCommon.sharedInstance.manualSessionHandling)
        [RapidopsConnectionManager.sharedInstance endSession];

    [RapidopsViewTracking.sharedInstance pauseView];

    [RapidopsPersistency.sharedInstance saveToFile];
}

- (void)resume
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return;

#if TARGET_OS_WATCH
    //NOTE: Skip first time to prevent double begin session because of applicationDidBecomeActive call on launch of watchOS apps
    static BOOL isFirstCall = YES;

    if (isFirstCall)
    {
        isFirstCall = NO;
        return;
    }
#endif

    if (!RapidopsCommon.sharedInstance.manualSessionHandling)
        [RapidopsConnectionManager.sharedInstance beginSession];

    [RapidopsViewTracking.sharedInstance resumeView];

    isSuspended = NO;
}

#pragma mark ---

- (void)didEnterBackgroundCallBack:(NSNotification *)notification
{
    Rapidops_LOG(@"App did enter background.");
    [self suspend];
}

- (void)willEnterForegroundCallBack:(NSNotification *)notification
{
    Rapidops_LOG(@"App will enter foreground.");
    [self resume];
}

- (void)willTerminateCallBack:(NSNotification *)notification
{
    Rapidops_LOG(@"App will terminate.");

    [RapidopsViewTracking.sharedInstance endView];

    [self suspend];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];

    if (timer)
    {
        [timer invalidate];
        timer = nil;
    }
}



#pragma mark - Consents
- (void)giveConsentForFeature:(NSString *)featureName
{
    if (!featureName.length)
        return;

    [RapidopsConsentManager.sharedInstance giveConsentForFeatures:@[featureName]];
}

- (void)giveConsentForFeatures:(NSArray *)features
{
    [RapidopsConsentManager.sharedInstance giveConsentForFeatures:features];
}

- (void)giveConsentForAllFeatures
{
    [RapidopsConsentManager.sharedInstance giveConsentForAllFeatures];
}

- (void)cancelConsentForFeature:(NSString *)featureName
{
    if (!featureName.length)
        return;

    [RapidopsConsentManager.sharedInstance cancelConsentForFeatures:@[featureName]];
}

- (void)cancelConsentForFeatures:(NSArray *)features
{
    [RapidopsConsentManager.sharedInstance cancelConsentForFeatures:features];
}

- (void)cancelConsentForAllFeatures
{
    [RapidopsConsentManager.sharedInstance cancelConsentForAllFeatures];
}

- (NSString *)deviceID
{
    return RapidopsDeviceInfo.sharedInstance.deviceID.RPD_URLEscaped;
}



#pragma mark - Events
- (void)recordEvent:(NSString *)key
{
    [self recordEvent:key segmentation:nil count:1 sum:0 duration:0];
}

- (void)recordEvent:(NSString *)key count:(NSUInteger)count
{
    [self recordEvent:key segmentation:nil count:count sum:0 duration:0];
}

- (void)recordEvent:(NSString *)key sum:(double)sum
{
    [self recordEvent:key segmentation:nil count:1 sum:sum duration:0];
}

- (void)recordEvent:(NSString *)key duration:(NSTimeInterval)duration
{
    [self recordEvent:key segmentation:nil count:1 sum:0 duration:duration];
}

- (void)recordEvent:(NSString *)key count:(NSUInteger)count sum:(double)sum
{
    [self recordEvent:key segmentation:nil count:count sum:sum duration:0];
}

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation
{
    [self recordEvent:key segmentation:segmentation count:1 sum:0 duration:0];
}

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(NSUInteger)count
{
    [self recordEvent:key segmentation:segmentation count:count sum:0 duration:0];
}

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(NSUInteger)count sum:(double)sum
{
    [self recordEvent:key segmentation:segmentation count:count sum:sum duration:0];
}

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(NSUInteger)count sum:(double)sum duration:(NSTimeInterval)duration
{
    if (!RapidopsConsentManager.sharedInstance.consentForEvents)
        return;

    [self recordEvent:key segmentation:segmentation count:count sum:sum duration:duration timestamp:RapidopsCommon.sharedInstance.uniqueTimestamp];
}

#pragma mark -

- (void)recordReservedEvent:(NSString *)key segmentation:(NSDictionary *)segmentation
{
    [self recordEvent:key segmentation:segmentation count:1 sum:0 duration:0 timestamp:RapidopsCommon.sharedInstance.uniqueTimestamp];
}

- (void)recordReservedEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(NSUInteger)count sum:(double)sum duration:(NSTimeInterval)duration timestamp:(NSTimeInterval)timestamp
{
    [self recordEvent:key segmentation:segmentation count:count sum:sum duration:duration timestamp:timestamp];
}

#pragma mark -

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(NSUInteger)count sum:(double)sum duration:(NSTimeInterval)duration timestamp:(NSTimeInterval)timestamp
{
    if (key.length == 0)
        return;

    RapidopsEvent *event = RapidopsEvent.new;
    event.key = key;
    event.segmentation = segmentation;
    event.count = MAX(count, 1);
    event.sum = sum;
	// NSTimeInterval is defined as double
		long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    event.timestamp = currentTime;
    event.hourOfDay = RapidopsCommon.sharedInstance.hourOfDay;
    event.dayOfWeek = RapidopsCommon.sharedInstance.dayOfWeek;
    event.duration = duration;

    [RapidopsPersistency.sharedInstance recordEvent:event];
}

#pragma mark ---

- (void)startEvent:(NSString *)key
{
    if (!RapidopsConsentManager.sharedInstance.consentForEvents)
        return;

    RapidopsEvent *event = RapidopsEvent.new;
    event.key = key;
    event.timestamp = RapidopsCommon.sharedInstance.uniqueTimestamp;
    event.hourOfDay = RapidopsCommon.sharedInstance.hourOfDay;
    event.dayOfWeek = RapidopsCommon.sharedInstance.dayOfWeek;

    [RapidopsPersistency.sharedInstance recordTimedEvent:event];
}

- (void)endEvent:(NSString *)key
{
    [self endEvent:key segmentation:nil count:1 sum:0];
}

- (void)endEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(NSUInteger)count sum:(double)sum
{
    if (!RapidopsConsentManager.sharedInstance.consentForEvents)
        return;

    RapidopsEvent *event = [RapidopsPersistency.sharedInstance timedEventForKey:key];

    if (!event)
    {
        Rapidops_LOG(@"Event with key '%@' not started yet or cancelled/ended before!", key);
        return;
    }

    event.segmentation = segmentation;
    event.count = MAX(count, 1);
    event.sum = sum;
    event.duration = NSDate.date.timeIntervalSince1970 - event.timestamp;

    [RapidopsPersistency.sharedInstance recordEvent:event];
}

- (void)cancelEvent:(NSString *)key
{
    if (!RapidopsConsentManager.sharedInstance.consentForEvents)
        return;

    RapidopsEvent *event = [RapidopsPersistency.sharedInstance timedEventForKey:key];

    if (!event)
    {
        Rapidops_LOG(@"Event with key '%@' not started yet or cancelled/ended before!", key);
        return;
    }

    Rapidops_LOG(@"Event with key '%@' cancelled!", key);
}


#pragma mark - Push Notifications
#if (TARGET_OS_IOS || TARGET_OS_OSX)

- (void)askForNotificationPermission
{
    [RapidopsPushNotifications.sharedInstance askForNotificationPermissionWithOptions:0 completionHandler:nil];
}

- (void)askForNotificationPermissionWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError * error))completionHandler;
{
    [RapidopsPushNotifications.sharedInstance askForNotificationPermissionWithOptions:options completionHandler:completionHandler];
}

- (void)recordActionForNotification:(NSDictionary *)userInfo clickedButtonIndex:(NSInteger)buttonIndex;
{
    [RapidopsPushNotifications.sharedInstance recordActionForNotification:userInfo clickedButtonIndex:buttonIndex];
}

- (void)recordPushNotificationToken
{
    [RapidopsPushNotifications.sharedInstance sendToken];
}

- (void)clearPushNotificationToken
{
    [RapidopsPushNotifications.sharedInstance clearToken];
}
#endif



#pragma mark - Location

- (void)recordLocation:(CLLocationCoordinate2D)location
{
    [RapidopsLocationManager.sharedInstance recordLocationInfo:location city:nil ISOCountryCode:nil andIP:nil];
}

- (void)recordCity:(NSString *)city andISOCountryCode:(NSString *)ISOCountryCode
{
    [RapidopsLocationManager.sharedInstance recordLocationInfo:kCLLocationCoordinate2DInvalid city:city ISOCountryCode:ISOCountryCode andIP:nil];
}

- (void)recordIP:(NSString *)IP
{
    [RapidopsLocationManager.sharedInstance recordLocationInfo:kCLLocationCoordinate2DInvalid city:nil ISOCountryCode:nil andIP:IP];
}

- (void)disableLocationInfo
{
    [RapidopsLocationManager.sharedInstance disableLocationInfo];
}



#pragma mark - Crash Reporting

#if TARGET_OS_IOS
- (void)recordHandledException:(NSException *)exception
{
    [RapidopsCrashReporter.sharedInstance recordException:exception withStackTrace:nil isFatal:NO];
}

- (void)recordHandledException:(NSException *)exception withStackTrace:(NSArray *)stackTrace
{
    [RapidopsCrashReporter.sharedInstance recordException:exception withStackTrace:stackTrace isFatal:NO];
}

- (void)recordUnhandledException:(NSException *)exception withStackTrace:(NSArray * _Nullable)stackTrace
{
    [RapidopsCrashReporter.sharedInstance recordException:exception withStackTrace:stackTrace isFatal:YES];
}

- (void)recordCrashLog:(NSString *)log
{
    [RapidopsCrashReporter.sharedInstance log:log];
}

- (void)crashLog:(NSString *)format, ...
{

}

#endif



#pragma mark - APM

- (void)addExceptionForAPM:(NSString *)exceptionURL
{
    [RapidopsAPM.sharedInstance addExceptionForAPM:exceptionURL];
}

- (void)removeExceptionForAPM:(NSString *)exceptionURL
{
    [RapidopsAPM.sharedInstance removeExceptionForAPM:exceptionURL];
}



#pragma mark - View Tracking

- (void)recordView:(NSString *)viewName;
{
    [RapidopsViewTracking.sharedInstance startView:viewName];
}

- (void)reportView:(NSString *)viewName
{

}

#if TARGET_OS_IOS
- (void)addExceptionForAutoViewTracking:(NSString *)exception
{
    [RapidopsViewTracking.sharedInstance addExceptionForAutoViewTracking:exception.copy];
}

- (void)removeExceptionForAutoViewTracking:(NSString *)exception
{
    [RapidopsViewTracking.sharedInstance removeExceptionForAutoViewTracking:exception.copy];
}

- (void)setIsAutoViewTrackingActive:(BOOL)isAutoViewTrackingActive
{
    RapidopsViewTracking.sharedInstance.isAutoViewTrackingActive = isAutoViewTrackingActive;
}

- (BOOL)isAutoViewTrackingActive
{
    return RapidopsViewTracking.sharedInstance.isAutoViewTrackingActive;
}
#endif



#pragma mark - User Details

+ (RapidopsUserDetails *)user
{
    return RapidopsUserDetails.sharedInstance;
}

- (void)userLoggedIn:(NSString *)userID
{
    [self setNewDeviceID:userID onServer:YES];
}

- (void)userLoggedOut
{
    [self setNewDeviceID:nil onServer:NO];
}



#pragma mark - Star Rating
#if TARGET_OS_IOS

- (void)askForStarRating:(void(^)(NSInteger rating))completion
{
    [RapidopsStarRating.sharedInstance showDialog:completion];
}

- (void)presentFeedbackWidgetWithID:(NSString *)widgetID completionHandler:(void (^)(NSError * error))completionHandler
{
    [RapidopsStarRating.sharedInstance checkFeedbackWidgetWithID:widgetID completionHandler:completionHandler];
}

#endif



#pragma mark - Remote Config

- (id)remoteConfigValueForKey:(NSString *)key
{
    return [RapidopsRemoteConfig.sharedInstance remoteConfigValueForKey:key];
}

- (void)updateRemoteConfigWithCompletionHandler:(void (^)(NSError * error))completionHandler
{
    [RapidopsRemoteConfig.sharedInstance updateRemoteConfigForForKeys:nil omitKeys:nil completionHandler:completionHandler];
}

- (void)updateRemoteConfigOnlyForKeys:(NSArray *)keys completionHandler:(void (^)(NSError * error))completionHandler
{
    [RapidopsRemoteConfig.sharedInstance updateRemoteConfigForForKeys:keys omitKeys:nil completionHandler:completionHandler];
}

- (void)updateRemoteConfigExceptForKeys:(NSArray *)omitKeys completionHandler:(void (^)(NSError * error))completionHandler
{
    [RapidopsRemoteConfig.sharedInstance updateRemoteConfigForForKeys:nil omitKeys:omitKeys completionHandler:completionHandler];
}


@end
