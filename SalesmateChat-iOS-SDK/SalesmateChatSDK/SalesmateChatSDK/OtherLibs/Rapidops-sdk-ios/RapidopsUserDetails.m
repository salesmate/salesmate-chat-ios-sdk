// RapidopsUserDetails.m
//
 
//
 

#import "RapidopsCommon.h"

@interface RapidopsUserDetails ()
@property (nonatomic) NSMutableDictionary* modifications;
@end

NSString* const kRapidopsLocalPicturePath = @"kRapidopsLocalPicturePath";

NSString* const kRapidopsUDKeyName          = @"name";
NSString* const kRapidopsUDKeyUsername      = @"username";
NSString* const kRapidopsUDKeyEmail         = @"email";
NSString* const kRapidopsUDKeyOrganization  = @"organization";
NSString* const kRapidopsUDKeyPhone         = @"phone";
NSString* const kRapidopsUDKeyGender        = @"gender";
NSString* const kRapidopsUDKeyPicture       = @"picture";
NSString* const kRapidopsUDKeyBirthyear     = @"byear";
NSString* const kRapidopsUDKeyCustom        = @"custom";

NSString* const kRapidopsUDKeyModifierSetOnce    = @"$setOnce";
NSString* const kRapidopsUDKeyModifierIncrement  = @"$inc";
NSString* const kRapidopsUDKeyModifierMultiply   = @"$mul";
NSString* const kRapidopsUDKeyModifierMax        = @"$max";
NSString* const kRapidopsUDKeyModifierMin        = @"$min";
NSString* const kRapidopsUDKeyModifierPush       = @"$push";
NSString* const kRapidopsUDKeyModifierAddToSet   = @"$addToSet";
NSString* const kRapidopsUDKeyModifierPull       = @"$pull";

@implementation RapidopsUserDetails

+ (instancetype)sharedInstance
{
    static RapidopsUserDetails *s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.modifications = NSMutableDictionary.new;
    }

    return self;
}

- (NSString *)serializedUserDetails
{
    NSMutableDictionary* userDictionary = NSMutableDictionary.new;
    if (self.name)
        userDictionary[kRapidopsUDKeyName] = self.name;
    if (self.username)
        userDictionary[kRapidopsUDKeyUsername] = self.username;
    if (self.email)
        userDictionary[kRapidopsUDKeyEmail] = self.email;
    if (self.organization)
        userDictionary[kRapidopsUDKeyOrganization] = self.organization;
    if (self.phone)
        userDictionary[kRapidopsUDKeyPhone] = self.phone;
    if (self.gender)
        userDictionary[kRapidopsUDKeyGender] = self.gender;
    if (self.pictureURL)
        userDictionary[kRapidopsUDKeyPicture] = self.pictureURL;
    if (self.birthYear)
        userDictionary[kRapidopsUDKeyBirthyear] = self.birthYear;
    if (self.custom)
        userDictionary[kRapidopsUDKeyCustom] = self.custom;

    if (userDictionary.allKeys.count)
        return [userDictionary RPD_JSONify];

    return nil;
}

- (void)clearUserDetails
{
    self.name = nil;
    self.username = nil;
    self.email = nil;
    self.organization = nil;
    self.phone = nil;
    self.gender = nil;
    self.pictureURL = nil;
    self.pictureLocalPath = nil;
    self.birthYear = nil;
    self.custom = nil;

    [self.modifications removeAllObjects];
}

#pragma mark -

- (void)set:(NSString *)key value:(NSString *)value
{
    self.modifications[key] = value.copy;
}

- (void)setOnce:(NSString *)key value:(NSString *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierSetOnce: value.copy};
}

- (void)unSet:(NSString *)key
{
    self.modifications[key] = NSNull.null;
}

- (void)increment:(NSString *)key
{
    [self incrementBy:key value:@1];
}

- (void)incrementBy:(NSString *)key value:(NSNumber *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierIncrement: value};
}

- (void)multiply:(NSString *)key value:(NSNumber *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierMultiply: value};
}

- (void)max:(NSString *)key value:(NSNumber *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierMax: value};
}

- (void)min:(NSString *)key value:(NSNumber *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierMin: value};
}

- (void)push:(NSString *)key value:(NSString *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierPush: value.copy};
}

- (void)push:(NSString *)key values:(NSArray *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierPush: value.copy};
}

- (void)pushUnique:(NSString *)key value:(NSString *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierAddToSet: value.copy};
}

- (void)pushUnique:(NSString *)key values:(NSArray *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierAddToSet: value.copy};
}

- (void)pull:(NSString *)key value:(NSString *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierPull: value.copy};
}

- (void)pull:(NSString *)key values:(NSArray *)value
{
    self.modifications[key] = @{kRapidopsUDKeyModifierPull: value.copy};
}

- (void)save
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForUserDetails)
        return;

    NSString* userDetails = [self serializedUserDetails];
    if (userDetails)
        [RapidopsConnectionManager.sharedInstance sendUserDetails:userDetails];

    if (self.pictureLocalPath && !self.pictureURL)
        [RapidopsConnectionManager.sharedInstance sendUserDetails:[@{kRapidopsLocalPicturePath: self.pictureLocalPath} RPD_JSONify]];

    if (self.modifications.count)
        [RapidopsConnectionManager.sharedInstance sendUserDetails:[@{kRapidopsUDKeyCustom: self.modifications} RPD_JSONify]];

    [self clearUserDetails];
}

@end
