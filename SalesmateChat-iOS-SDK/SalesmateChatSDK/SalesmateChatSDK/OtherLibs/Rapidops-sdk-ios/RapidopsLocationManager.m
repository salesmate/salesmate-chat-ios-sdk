// RapidopsLocationManager.m
//
 
//
 

#import "RapidopsCommon.h"


@implementation RapidopsLocationManager

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsLocationManager* s_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {

    }

    return self;
}

#pragma mark ---

- (void)sendLocationInfo
{
    if (!RapidopsConsentManager.sharedInstance.consentForLocation)
        return;

    [RapidopsConnectionManager.sharedInstance sendLocationInfo];
}

- (void)recordLocationInfo:(CLLocationCoordinate2D)location city:(NSString *)city ISOCountryCode:(NSString *)ISOCountryCode andIP:(NSString *)IP
{
    if (!RapidopsConsentManager.sharedInstance.consentForLocation)
        return;

	if (CLLocationCoordinate2DIsValid(location)) {
        self.location = [NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude];
				self.longitude = [NSString stringWithFormat:@"%f", location.longitude];
				self.latitude = [NSString stringWithFormat:@"%f", location.latitude];
	}

	else {
        self.location = nil;
				self.longitude = @"";
				self.latitude = @"";
	}

    self.city = city;
    self.ISOCountryCode = ISOCountryCode;
    self.IP = IP;

    if ((self.location || self.city || self.ISOCountryCode || self.IP))
        self.isLocationInfoDisabled = NO;

    [RapidopsConnectionManager.sharedInstance sendLocationInfo];
}

- (void)disableLocationInfo
{
    if (!RapidopsConsentManager.sharedInstance.consentForLocation)
        return;

    self.isLocationInfoDisabled = YES;

    //NOTE: Set location to empty string, as Rapidops Server needs it for disabling geo-location
    self.location = @"";
    self.city = nil;
    self.ISOCountryCode = nil;
    self.IP = nil;

    [RapidopsConnectionManager.sharedInstance sendLocationInfo];
}

@end
