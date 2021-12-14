// RapidopsPersistency.m
//
 
//
 

#import "RapidopsCommon.h"

NSString* const RPDConsentSessions             = @"sessions";
NSString* const RPDConsentEvents               = @"events";
NSString* const RPDConsentUserDetails          = @"users";
NSString* const RPDConsentCrashReporting       = @"crashes";
NSString* const RPDConsentPushNotifications    = @"push";
NSString* const RPDConsentLocation             = @"location";
NSString* const RPDConsentViewTracking         = @"views";
NSString* const RPDConsentAttribution          = @"attribution";
NSString* const RPDConsentStarRating           = @"star-rating";
NSString* const RPDConsentAppleWatch           = @"accessory-devices";


@interface RapidopsConsentManager ()
@property (nonatomic, strong) NSMutableDictionary* consentChanges;
@end

@implementation RapidopsConsentManager

@synthesize consentForSessions = _consentForSessions;
@synthesize consentForEvents = _consentForEvents;
@synthesize consentForUserDetails = _consentForUserDetails;
@synthesize consentForCrashReporting = _consentForCrashReporting;
@synthesize consentForPushNotifications = _consentForPushNotifications;
@synthesize consentForLocation = _consentForLocation;
@synthesize consentForViewTracking = _consentForViewTracking;
@synthesize consentForAttribution = _consentForAttribution;
@synthesize consentForStarRating = _consentForStarRating;
@synthesize consentForAppleWatch = _consentForAppleWatch;

#pragma mark -

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsConsentManager* s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}


- (instancetype)init
{
    if (self = [super init])
    {
        self.consentChanges = NSMutableDictionary.new;
    }

    return self;
}


#pragma mark -


- (void)giveConsentForAllFeatures
{
    [self giveConsentForFeatures:[self allFeatures]];
}


- (void)giveConsentForFeatures:(NSArray *)features
{
    if (!self.requiresConsent)
        return;

    if (!features.count)
        return;

    if ([features containsObject:RPDConsentSessions] && !self.consentForSessions)
        self.consentForSessions = YES;

    if ([features containsObject:RPDConsentEvents] && !self.consentForEvents)
        self.consentForEvents = YES;

    if ([features containsObject:RPDConsentUserDetails] && !self.consentForUserDetails)
        self.consentForUserDetails = YES;

    if ([features containsObject:RPDConsentCrashReporting] && !self.consentForCrashReporting)
        self.consentForCrashReporting = YES;

    if ([features containsObject:RPDConsentPushNotifications] && !self.consentForPushNotifications)
        self.consentForPushNotifications = YES;

    if ([features containsObject:RPDConsentLocation] && !self.consentForLocation)
        self.consentForLocation = YES;

    if ([features containsObject:RPDConsentViewTracking] && !self.consentForViewTracking)
        self.consentForViewTracking = YES;

    if ([features containsObject:RPDConsentAttribution] && !self.consentForAttribution)
        self.consentForAttribution = YES;

    if ([features containsObject:RPDConsentStarRating] && !self.consentForStarRating)
        self.consentForStarRating = YES;

    if ([features containsObject:RPDConsentAppleWatch] && !self.consentForAppleWatch)
        self.consentForAppleWatch = YES;

    [self sendConsentChanges];
}


- (void)cancelConsentForAllFeatures
{
    [self cancelConsentForFeatures:[self allFeatures]];
}


- (void)cancelConsentForFeatures:(NSArray *)features
{
    if (!self.requiresConsent)
        return;

    if ([features containsObject:RPDConsentSessions] && self.consentForSessions)
        self.consentForSessions = NO;

    if ([features containsObject:RPDConsentEvents] && self.consentForEvents)
        self.consentForEvents = NO;

    if ([features containsObject:RPDConsentUserDetails] && self.consentForUserDetails)
        self.consentForUserDetails = NO;

    if ([features containsObject:RPDConsentCrashReporting] && self.consentForCrashReporting)
        self.consentForCrashReporting = NO;

    if ([features containsObject:RPDConsentPushNotifications] && self.consentForPushNotifications)
        self.consentForPushNotifications = NO;

    if ([features containsObject:RPDConsentLocation] && self.consentForLocation)
        self.consentForLocation = NO;

    if ([features containsObject:RPDConsentViewTracking] && self.consentForViewTracking)
        self.consentForViewTracking = NO;

    if ([features containsObject:RPDConsentAttribution] && self.consentForAttribution)
        self.consentForAttribution = NO;

    if ([features containsObject:RPDConsentStarRating] && self.consentForStarRating)
        self.consentForStarRating = NO;

    if ([features containsObject:RPDConsentAppleWatch] && self.consentForAppleWatch)
        self.consentForAppleWatch = NO;

    [self sendConsentChanges];
}


- (void)sendConsentChanges
{
    if (self.consentChanges.allKeys.count)
    {
        [RapidopsConnectionManager.sharedInstance sendConsentChanges:[self.consentChanges RPD_JSONify]];
        [self.consentChanges removeAllObjects];
    }
}


- (NSArray *)allFeatures
{
    return
    @[
        RPDConsentSessions,
        RPDConsentEvents,
        RPDConsentUserDetails,
        RPDConsentCrashReporting,
        RPDConsentPushNotifications,
        RPDConsentLocation,
        RPDConsentViewTracking,
        RPDConsentAttribution,
        RPDConsentStarRating,
        RPDConsentAppleWatch,
    ];
}


- (BOOL)hasAnyConsent
{
    return
    self.consentForSessions ||
    self.consentForEvents ||
    self.consentForUserDetails ||
    self.consentForCrashReporting ||
    self.consentForPushNotifications ||
    self.consentForLocation ||
    self.consentForViewTracking ||
    self.consentForAttribution ||
    self.consentForStarRating ||
    self.consentForAppleWatch;
}


#pragma mark -


- (void)setConsentForSessions:(BOOL)consentForSessions
{
    _consentForSessions = consentForSessions;

    if (consentForSessions)
    {
        Rapidops_LOG(@"Consent for Session is given.");

        if (!RapidopsCommon.sharedInstance.manualSessionHandling)
            [RapidopsConnectionManager.sharedInstance beginSession];
    }
    else
    {
        Rapidops_LOG(@"Consent for Session is cancelled.");
    }

    self.consentChanges[RPDConsentSessions] = @(consentForSessions);
}


- (void)setConsentForEvents:(BOOL)consentForEvents
{
    _consentForEvents = consentForEvents;

    if (consentForEvents)
    {
        Rapidops_LOG(@"Consent for Events is given.");
    }
    else
    {
        Rapidops_LOG(@"Consent for Events is cancelled.");

        [RapidopsConnectionManager.sharedInstance sendEvents];
        [RapidopsPersistency.sharedInstance clearAllTimedEvents];
    }

    self.consentChanges[RPDConsentEvents] = @(consentForEvents);
}


- (void)setConsentForUserDetails:(BOOL)consentForUserDetails
{
    _consentForUserDetails = consentForUserDetails;

    if (consentForUserDetails)
    {
        Rapidops_LOG(@"Consent for UserDetails is given.");
    }
    else
    {
        Rapidops_LOG(@"Consent for UserDetails is cancelled.");

        [RapidopsUserDetails.sharedInstance clearUserDetails];
    }

    self.consentChanges[RPDConsentUserDetails] = @(consentForUserDetails);
}


- (void)setConsentForCrashReporting:(BOOL)consentForCrashReporting
{
    _consentForCrashReporting = consentForCrashReporting;

#if TARGET_OS_IOS
    if (consentForCrashReporting)
    {
        Rapidops_LOG(@"Consent for CrashReporting is given.");

        [RapidopsCrashReporter.sharedInstance startCrashReporting];
    }
    else
    {
        Rapidops_LOG(@"Consent for CrashReporting is cancelled.");

        [RapidopsCrashReporter.sharedInstance stopCrashReporting];
    }
#endif

    self.consentChanges[RPDConsentCrashReporting] = @(consentForCrashReporting);
}


- (void)setConsentForPushNotifications:(BOOL)consentForPushNotifications
{
    _consentForPushNotifications = consentForPushNotifications;

#if TARGET_OS_IOS
    if (consentForPushNotifications)
    {
        Rapidops_LOG(@"Consent for PushNotifications is given.");

        [RapidopsPushNotifications.sharedInstance startPushNotifications];
    }
    else
    {
        Rapidops_LOG(@"Consent for PushNotifications is cancelled.");

        [RapidopsPushNotifications.sharedInstance stopPushNotifications];
    }
#endif

    self.consentChanges[RPDConsentPushNotifications] = @(consentForPushNotifications);
}


- (void)setConsentForLocation:(BOOL)consentForLocation
{
    _consentForLocation = consentForLocation;

    if (consentForLocation)
    {
        Rapidops_LOG(@"Consent for Location is given.");

        [RapidopsLocationManager.sharedInstance sendLocationInfo];
    }
    else
    {
        Rapidops_LOG(@"Consent for Location is cancelled.");
    }

    self.consentChanges[RPDConsentLocation] = @(consentForLocation);
}


- (void)setConsentForViewTracking:(BOOL)consentForViewTracking
{
    _consentForViewTracking = consentForViewTracking;

#if (TARGET_OS_IOS || TARGET_OS_TV)
    if (consentForViewTracking)
    {
        Rapidops_LOG(@"Consent for ViewTracking is given.");

        [RapidopsViewTracking.sharedInstance startAutoViewTracking];
    }
    else
    {
        Rapidops_LOG(@"Consent for ViewTracking is cancelled.");

        [RapidopsViewTracking.sharedInstance stopAutoViewTracking];
    }
#endif

    self.consentChanges[RPDConsentViewTracking] = @(consentForViewTracking);
}


- (void)setConsentForAttribution:(BOOL)consentForAttribution
{
    _consentForAttribution = consentForAttribution;

    if (consentForAttribution)
    {
        Rapidops_LOG(@"Consent for Attribution is given.");

        [RapidopsCommon.sharedInstance startAttribution];
    }
    else
    {
        Rapidops_LOG(@"Consent for Attribution is cancelled.");
    }

    self.consentChanges[RPDConsentAttribution] = @(consentForAttribution);
}


- (void)setConsentForStarRating:(BOOL)consentForStarRating
{
    _consentForStarRating = consentForStarRating;

#if TARGET_OS_IOS
    if (consentForStarRating)
    {
        Rapidops_LOG(@"Consent for StarRating is given.");

        [RapidopsStarRating.sharedInstance checkForAutoAsk];
    }
    else
    {
        Rapidops_LOG(@"Consent for StarRating is cancelled.");
    }
#endif

    self.consentChanges[RPDConsentStarRating] = @(consentForStarRating);
}


- (void)setConsentForAppleWatch:(BOOL)consentForAppleWatch
{
    _consentForAppleWatch = consentForAppleWatch;

#if (TARGET_OS_IOS || TARGET_OS_WATCH)
    if (consentForAppleWatch)
    {
        Rapidops_LOG(@"Consent for AppleWatch is given.");

        [RapidopsCommon.sharedInstance startAppleWatchMatching];
    }
    else
    {
        Rapidops_LOG(@"Consent for AppleWatch is cancelled.");
    }
#endif

    self.consentChanges[RPDConsentAppleWatch] = @(consentForAppleWatch);
}

#pragma mark -

- (BOOL)consentForSessions
{
    if (!self.requiresConsent)
      return YES;

    return _consentForSessions;
}


- (BOOL)consentForEvents
{
    if (!self.requiresConsent)
      return YES;

    return _consentForEvents;
}


- (BOOL)consentForUserDetails
{
    if (!self.requiresConsent)
      return YES;

    return _consentForUserDetails;
}


- (BOOL)consentForCrashReporting
{
    if (!self.requiresConsent)
      return YES;

    return _consentForCrashReporting;
}


- (BOOL)consentForPushNotifications
{
    if (!self.requiresConsent)
      return YES;

    return _consentForPushNotifications;
}


- (BOOL)consentForLocation
{
    if (!self.requiresConsent)
        return YES;

    return _consentForLocation;
}


- (BOOL)consentForViewTracking
{
    if (!self.requiresConsent)
      return YES;

    return _consentForViewTracking;
}


- (BOOL)consentForAttribution
{
    if (!self.requiresConsent)
      return YES;

    return _consentForAttribution;
}


- (BOOL)consentForStarRating
{
    if (!self.requiresConsent)
      return YES;

    return _consentForStarRating;
}


- (BOOL)consentForAppleWatch
{
    if (!self.requiresConsent)
      return YES;

    return _consentForAppleWatch;
}

@end
