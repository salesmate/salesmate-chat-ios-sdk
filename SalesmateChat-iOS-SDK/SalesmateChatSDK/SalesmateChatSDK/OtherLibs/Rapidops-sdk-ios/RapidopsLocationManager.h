// RapidopsLocationManager.h
//
 
//
 

#import <Foundation/Foundation.h>

@interface RapidopsLocationManager : NSObject
@property (nonatomic, copy) NSString* location;
@property (nonatomic, copy) NSString* latitude;
@property (nonatomic, copy) NSString* longitude;

@property (nonatomic, copy) NSString* city;
@property (nonatomic, copy) NSString* ISOCountryCode;
@property (nonatomic, copy) NSString* IP;
@property (nonatomic) BOOL isLocationInfoDisabled;
+ (instancetype)sharedInstance;

- (void)sendLocationInfo;
- (void)recordLocationInfo:(CLLocationCoordinate2D)location city:(NSString *)city ISOCountryCode:(NSString *)ISOCountryCode andIP:(NSString *)IP;
- (void)disableLocationInfo;

@end
