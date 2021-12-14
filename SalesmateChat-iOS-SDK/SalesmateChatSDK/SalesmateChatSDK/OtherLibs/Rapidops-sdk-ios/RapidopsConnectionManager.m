// RapidopsConnectionManager.m
//

//


#import "RapidopsCommon.h"

@interface RapidopsConnectionManager ()
{
    NSTimeInterval unsentSessionLength;
    NSTimeInterval lastSessionStartTime;
    BOOL isCrashing;
}
@end

NSString* const kRapidopsQSKeyAppKey           = @"app_key";
NSString* const kRapidopsQSKeyTenantId              = @"tenant_id";
NSString* const kRapidopsQSKeySessionId             = @"session_id";
NSString* const kRapidopsQSKeyVisitorId             = @"visitor_id";
NSString* const kRapidopsQSKeyUUID                  = @"uuid";


NSString* const kRapidopsQSKeyDeviceID         = @"device_id";
NSString* const kRapidopsQSKeyDeviceIDOld      = @"old_device_id";
NSString* const kRapidopsQSKeyDeviceIDParent   = @"parent_device_id";

NSString* const kRapidopsQSKeyTimestamp        = @"timestamp";
NSString* const kRapidopsQSKeyTimeZone         = @"tz";
NSString* const kRapidopsQSKeyTimeHourOfDay    = @"hour";
NSString* const kRapidopsQSKeyTimeDayOfWeek    = @"dow";

NSString* const kRapidopsQSKeySDKVersion       = @"sdk_version";
NSString* const kRapidopsQSKeySDKName          = @"sdk_name";

NSString* const kRapidopsQSKeySessionBegin     = @"begin_session";
NSString* const kRapidopsQSKeySessionDuration  = @"session_duration";
NSString* const kRapidopsQSKeySessionEnd       = @"end_session";

NSString* const kRapidopsQSKeyPushTokenSession = @"token_session";
NSString* const kRapidopsQSKeyPushTokeniOS     = @"ios_token";
NSString* const kRapidopsQSKeyPushTestMode     = @"test_mode";

NSString* const kRapidopsQSKeyLocation         = @"location";
NSString* const kRapidopsQSKeyLocationCity     = @"city";
NSString* const kRapidopsQSKeyLocationCountry  = @"country";
NSString* const kRapidopsQSKeyLocationIP       = @"ip_address";

NSString* const kRapidopsQSKeyMetrics          = @"metrics";
NSString* const kRapidopsQSKeyEvents           = @"events";
NSString* const kRapidopsQSKeyUserDetails      = @"user_details";
NSString* const kRapidopsQSKeyCrash            = @"crash";
NSString* const kRapidopsQSKeyChecksum256      = @"checksum256";
NSString* const kRapidopsQSKeyAttributionID    = @"aid";
NSString* const kRapidopsQSKeyConsent          = @"consent";

NSString* const kRapidopsUploadBoundary = @"0cae04a8b698d63ff6ea55d168993f21";
NSString* const kRapidopsInputEndpoint = @"/track";
const NSInteger kRapidopsGETRequestMaxLength = 2048;

@implementation RapidopsConnectionManager : NSObject

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;
    
    static RapidopsConnectionManager *s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        unsentSessionLength = 0.0;
    }
    
    return self;
}

- (void)proceedOnQueue
{
    Rapidops_LOG(@"Proceeding on queue...");
    
    if (self.connection)
    {
        Rapidops_LOG(@"Proceeding on queue is aborted: Already has a request in process!");
        return;
    }
    
    if (isCrashing)
    {
        Rapidops_LOG(@"Proceeding on queue is aborted: Application is crashing!");
        return;
    }
    
    if (self.customHeaderFieldName && !self.customHeaderFieldValue)
    {
        Rapidops_LOG(@"Proceeding on queue is aborted: customHeaderFieldName specified on config, but customHeaderFieldValue not set yet!");
        return;
    }
    
    NSString* firstItemInQueue = [RapidopsPersistency.sharedInstance firstItemInQueue];
    if (!firstItemInQueue)
    {
        Rapidops_LOG(@"Queue is empty. All requests are processed.");
        return;
    }
    
    if ([firstItemInQueue isEqual:NSNull.null])
    {
        Rapidops_LOG(@"Detected an NSNull in queue and removed.");
        
        [RapidopsPersistency.sharedInstance removeFromQueue:firstItemInQueue];
        [self proceedOnQueue];
        return;
    }
    
    [RapidopsCommon.sharedInstance startBackgroundTask];
    
    NSString* queryString = firstItemInQueue;
    
    if (self.applyZeroIDFAFix)
    {
        NSString* deviceIDZeroIDFA = [NSString stringWithFormat:@"&%@=%@", kRapidopsQSKeyDeviceID, kRapidopsZeroIDFA];
        NSString* oldDeviceIDZeroIDFA = [NSString stringWithFormat:@"&%@=%@", kRapidopsQSKeyDeviceIDOld, kRapidopsZeroIDFA];
        NSString* deviceIDFixed = [NSString stringWithFormat:@"&%@=%@", kRapidopsQSKeyDeviceID, RapidopsDeviceInfo.sharedInstance.deviceID.RPD_URLEscaped];
        
        if ([queryString containsString:deviceIDZeroIDFA])
        {
            Rapidops_LOG(@"Detected a request with zero-IDFA in queue and fixed.");
            
            queryString = [queryString stringByReplacingOccurrencesOfString:deviceIDZeroIDFA withString:deviceIDFixed];
        }
        
        if ([queryString containsString:oldDeviceIDZeroIDFA])
        {
            Rapidops_LOG(@"Detected a request with zero-IDFA in queue and removed.");
            
            [RapidopsPersistency.sharedInstance removeFromQueue:firstItemInQueue];
            [self proceedOnQueue];
            return;
        }
    }
    
    queryString = [self appendChecksum:queryString];
    
    NSString* serverInputEndpoint = [self.host stringByAppendingString:kRapidopsInputEndpoint];
    NSString* fullRequestURL = [serverInputEndpoint stringByAppendingFormat:@"?%@", queryString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullRequestURL]];
    
    NSData* pictureUploadData = [self pictureUploadDataForRequest:queryString];
    if (pictureUploadData)
    {
        NSString *contentType = [@"multipart/form-data; boundary=" stringByAppendingString:kRapidopsUploadBoundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        request.HTTPMethod = @"POST";
        request.HTTPBody = pictureUploadData;
    }
    else if (queryString.length > kRapidopsGETRequestMaxLength || self.alwaysUsePOST)
    {
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serverInputEndpoint]];
        request.HTTPMethod = @"POST";
        request.HTTPBody = [queryString RPD_dataUTF8];
    }
    
    if (self.customHeaderFieldName && self.customHeaderFieldValue)
        [request setValue:self.customHeaderFieldValue forHTTPHeaderField:self.customHeaderFieldName];
    
    self.connection = [[self URLSession] dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error)
                       {
        self.connection = nil;
        
        if (!error)
        {
            if ([self isRequestSuccessful:response])
            {
                Rapidops_LOG(@"Request <%p> successfully completed.", request);
                
                [RapidopsPersistency.sharedInstance removeFromQueue:firstItemInQueue];
                
                [RapidopsPersistency.sharedInstance saveToFile];
                
                [self proceedOnQueue];
            }
            else
            {
                Rapidops_LOG(@"Request <%p> failed!\nServer reply: %@", request, [data RPD_stringUTF8]);
            }
        }
        else
        {
            Rapidops_LOG(@"Request <%p> failed!\nError: %@", request, error);
#if TARGET_OS_WATCH
            [RapidopsPersistency.sharedInstance saveToFile];
#endif
        }
    }];
    
    [self.connection resume];
    
    Rapidops_LOG(@"Request <%p> started:\n[%@] %@ \n%@", (id)request, request.HTTPMethod, request.URL.absoluteString, request.HTTPBody ? ([request.HTTPBody RPD_stringUTF8] ?: @"Picture uploading...") : @"");
}

- (void)logEventsOnServer
{
    
    [RapidopsCommon.sharedInstance startBackgroundTask];
    
    NSMutableArray* events = [RapidopsPersistency.sharedInstance serializedRecordedEventsAsArray];
    if ([events count] == 0) {
        return;
    }
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *appKey = [f numberFromString:self.appKey];
    param[@"appKey"] = appKey;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        NSString *vendorID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        param[@"device_id"] = vendorID;
    }
    param[@"events"] = [NSArray arrayWithArray:events];
    
    NSDictionary *queryDict = [[NSDictionary alloc] initWithDictionary:[self queryEssentialsAsDictionary]] ;
    [param addEntriesFromDictionary:queryDict];
    [param addEntriesFromDictionary:[self getLocationInfo]];
    param[@"metrics"] = [RapidopsDeviceInfo metricsAsDictionary];
    param[@"email"] = Rapidops.user.email;
    param[@"name"] = Rapidops.user.name;
    param[@"username"] = Rapidops.user.username;
    param[@"phone"] = Rapidops.user.phone;
    param[@"organization"] = Rapidops.user.organization;
    
//    if ([NSJSONSerialization isValidJSONObject:param]) {//validate it
//        NSError* error = nil;
//        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error: &error];
//        request.HTTPBody = jsonData;
//    }
    
    NSString* serverInputEndpoint = [self.host stringByAppendingString:kRapidopsInputEndpoint];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serverInputEndpoint]];
    
    NSString *queryStr = @"";
    for (NSString *key in param) {
        NSString *eventsStr = nil;
        if ([key  isEqual: @"events"]){
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:param[key] options:NSJSONWritingPrettyPrinted error:nil];
            if (jsonData != nil){
                eventsStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        }
        if (eventsStr == nil){
            eventsStr = param[key];
        }
        NSString *str = [NSString stringWithFormat:@"%@=%@",key,eventsStr];
        if ([queryStr length] == 0){
            queryStr = str;
        }else{
            queryStr = [queryStr stringByAppendingFormat:@"&%@", str];
        }
    }
    
    queryStr = [queryStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    
    request.HTTPBody = [queryStr dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
    
    if (self.customHeaderFieldName && self.customHeaderFieldValue)
        [request setValue:self.customHeaderFieldValue forHTTPHeaderField:self.customHeaderFieldName];
    
    //NSLog(@"%@", param);
    //NSLog(@"%@", request);
    
    NSURLSessionTask *task = [[self URLSession] dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error)
                              {
        if (!error)
        {
            if ([self isRequestSuccessful:response]) {
                Rapidops_LOG(@"Request <%p> successfully completed.", request);
                [RapidopsPersistency.sharedInstance saveToFile];
            }
            else {
                Rapidops_LOG(@"Request %@ failed!\nServer reply: %@, ", request.URL, [data RPD_stringUTF8]);
            }
        }else {
            Rapidops_LOG(@"Request %@ failed!\nError: %@", request.URL, error);
#if TARGET_OS_WATCH
            [RapidopsPersistency.sharedInstance saveToFile];
#endif
        }
    }];
    
    [task resume];
    
    Rapidops_LOG(@"Request <%p> started:\n[%@] %@ \n%@", (id)request, request.HTTPMethod, request.URL.absoluteString, request.HTTPBody ? ([request.HTTPBody RPD_stringUTF8] ?: @"Picture uploading...") : @"");
}
#pragma mark ---

- (void)beginSession
{
    if (!RapidopsConsentManager.sharedInstance.consentForSessions)
        return;
    
    lastSessionStartTime = NSDate.date.timeIntervalSince1970;
    unsentSessionLength = 0.0;
    
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@&%@=%@",
                             kRapidopsQSKeySessionBegin, @"1",
                             kRapidopsQSKeyMetrics, [RapidopsDeviceInfo metrics]];
    
    if (!RapidopsConsentManager.sharedInstance.consentForLocation || RapidopsLocationManager.sharedInstance.isLocationInfoDisabled)
        queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsQSKeyLocation, @""];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

- (void)updateSession
{
    if (!RapidopsConsentManager.sharedInstance.consentForSessions)
        return;
    
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%d",
                             kRapidopsQSKeySessionDuration, (int)[self sessionLengthInSeconds]];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

- (void)endSession
{
    if (!RapidopsConsentManager.sharedInstance.consentForSessions)
        return;
    
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@&%@=%d",
                             kRapidopsQSKeySessionEnd, @"1",
                             kRapidopsQSKeySessionDuration, (int)[self sessionLengthInSeconds]];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

#pragma mark ---

- (void)sendEvents
{
    [self logEventsOnServer];
    
}

#pragma mark ---

- (void)sendPushToken:(NSString *)token
{
    typedef enum : NSInteger
    {
        RPDPushTokenModeProduction,
        RPDPushTokenModeDevelopment,
        RPDPushTokenModeAdHoc,
    } RPDPushTokenMode;
    
    int testMode;
#ifdef DEBUG
    testMode = RPDPushTokenModeDevelopment;
#else
    testMode = RapidopsPushNotifications.sharedInstance.isTestDevice ? RPDPushTokenModeAdHoc : RPDPushTokenModeProduction;
#endif
    
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@&%@=%@&%@=%d",
                             kRapidopsQSKeyPushTokenSession, @"1",
                             kRapidopsQSKeyPushTokeniOS, token,
                             kRapidopsQSKeyPushTestMode, testMode];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

- (void)sendLocationInfo
{
    NSString* location = RapidopsLocationManager.sharedInstance.location.RPD_URLEscaped;
    NSString* city = RapidopsLocationManager.sharedInstance.city.RPD_URLEscaped;
    NSString* ISOCountryCode = RapidopsLocationManager.sharedInstance.ISOCountryCode.RPD_URLEscaped;
    NSString* IP = RapidopsLocationManager.sharedInstance.IP.RPD_URLEscaped;
    
    if (!(location || city || ISOCountryCode || IP))
        return;
    
    NSString* queryString = [self queryEssentials];
    
    if (location)
        queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsQSKeyLocation, location];
    
    if (city)
        queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsQSKeyLocationCity, city];
    
    if (ISOCountryCode)
        queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsQSKeyLocationCountry, ISOCountryCode];
    
    if (IP)
        queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsQSKeyLocationIP, IP];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

- (NSMutableDictionary *)getLocationInfo
{
    NSString* city = RapidopsLocationManager.sharedInstance.city;
    NSString* ISOCountryCode = RapidopsLocationManager.sharedInstance.ISOCountryCode;
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    dict[@"city"] = city;
    dict[@"country"] = ISOCountryCode;
    dict[@"latitude"] = RapidopsLocationManager.sharedInstance.latitude;
    dict[@"longitude"] = RapidopsLocationManager.sharedInstance.longitude;
    return dict;
}

- (void)sendUserDetails:(NSString *)userDetails
{
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@",
                             kRapidopsQSKeyUserDetails, userDetails];
    if ([[RapidopsUserDetails sharedInstance] name] != nil){
        queryString = [NSString stringWithFormat:@"%@&name=%@",queryString,[[RapidopsUserDetails sharedInstance] name]];
    }
    
    if ([[RapidopsUserDetails sharedInstance] email] != nil){
        queryString = [NSString stringWithFormat:@"%@&email=%@",queryString,[[RapidopsUserDetails sharedInstance] email]];
    }
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

- (void)sendCrashReport:(NSString *)report immediately:(BOOL)immediately;
{
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@",
                             kRapidopsQSKeyCrash, report];
    
    if (!immediately)
    {
        [RapidopsPersistency.sharedInstance addToQueue:queryString];
        [self proceedOnQueue];
        return;
    }
    
    //NOTE: Prevent `event` and `end_session` requests from being started, after `sendEvents` and `endSession` calls below.
    isCrashing = YES;
    
    [self sendEvents];
    
    if (!RapidopsCommon.sharedInstance.manualSessionHandling)
        [self endSession];
    
    if (self.customHeaderFieldName && !self.customHeaderFieldValue)
    {
        Rapidops_LOG(@"customHeaderFieldName specified on config, but customHeaderFieldValue not set! Crash report stored to be sent later!");
        
        [RapidopsPersistency.sharedInstance addToQueue:queryString];
        [RapidopsPersistency.sharedInstance saveToFileSync];
        return;
    }
    
    [RapidopsPersistency.sharedInstance saveToFileSync];
    
    NSString* serverInputEndpoint = [self.host stringByAppendingString:kRapidopsInputEndpoint];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serverInputEndpoint]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self appendChecksum:queryString] RPD_dataUTF8];
    
    if (self.customHeaderFieldName && self.customHeaderFieldValue)
        [request setValue:self.customHeaderFieldValue forHTTPHeaderField:self.customHeaderFieldName];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [[[self URLSession] dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError*  error)
      {
        if (error || ![self isRequestSuccessful:response])
        {
            Rapidops_LOG(@"Crash Report Request <%p> failed!\n%@: %@", request, error ? @"Error" : @"Server reply", error ?: [data RPD_stringUTF8]);
            [RapidopsPersistency.sharedInstance addToQueue:queryString];
            [RapidopsPersistency.sharedInstance saveToFileSync];
        }
        else
        {
            Rapidops_LOG(@"Crash Report Request <%p> successfully completed.", request);
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }] resume];
    
    Rapidops_LOG(@"Crash Report Request <%p> started:\n[%@] %@ \n%@", (id)request, request.HTTPMethod, request.URL.absoluteString, [request.HTTPBody RPD_stringUTF8]);
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)sendOldDeviceID:(NSString *)oldDeviceID
{
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@",
                             kRapidopsQSKeyDeviceIDOld, oldDeviceID.RPD_URLEscaped];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

- (void)sendParentDeviceID:(NSString *)parentDeviceID
{
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@",
                             kRapidopsQSKeyDeviceIDParent, parentDeviceID.RPD_URLEscaped];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

- (void)sendAttribution:(NSString *)attribution
{
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@",
                             kRapidopsQSKeyAttributionID, attribution];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

- (void)sendConsentChanges:(NSString *)consentChanges
{
    NSString* queryString = [[self queryEssentials] stringByAppendingFormat:@"&%@=%@",
                             kRapidopsQSKeyConsent, consentChanges];
    
    [RapidopsPersistency.sharedInstance addToQueue:queryString];
    
    [self proceedOnQueue];
}

#pragma mark ---

- (NSString *)queryEssentials
{
    NSString* uuid = @"";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"SessionID"] != nil) {
        uuid = [userDefaults valueForKey:@"SessionID"];
    } else {
        uuid = [[NSUUID UUID] UUIDString];
    }
    return [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%lld&%@=%d&%@=%d&%@=%d&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",
            kRapidopsQSKeyAppKey, self.appKey,
            kRapidopsQSKeyDeviceID, RapidopsDeviceInfo.sharedInstance.deviceID.RPD_URLEscaped,
            kRapidopsQSKeyTimestamp, (long long)(RapidopsCommon.sharedInstance.uniqueTimestamp * 1000),
            kRapidopsQSKeyTimeHourOfDay, (int)RapidopsCommon.sharedInstance.hourOfDay,
            kRapidopsQSKeyTimeDayOfWeek, (int)RapidopsCommon.sharedInstance.dayOfWeek,
            kRapidopsQSKeyTimeZone, (int)RapidopsCommon.sharedInstance.timeZone,
            kRapidopsQSKeySDKVersion, kRapidopsSDKVersion,
            kRapidopsQSKeySDKName, kRapidopsSDKName,kRapidopsQSKeySessionId,[[NSUUID UUID] UUIDString], kRapidopsQSKeyVisitorId, [[NSUUID UUID] UUIDString], kRapidopsQSKeyTenantId, self.tenantID, kRapidopsQSKeyUUID, uuid];
}

- (NSMutableDictionary *)queryEssentialsAsDictionary{
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[kRapidopsQSKeyAppKey] = self.appKey;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        NSString *vendorID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        dict[@"device_id"] = vendorID;
        
    }
    dict[kRapidopsQSKeySDKVersion] = kRapidopsSDKVersion;
    dict[kRapidopsQSKeySDKName] = kRapidopsSDKName;
    dict[kRapidopsQSKeyTimeHourOfDay] =[NSString stringWithFormat:@"%ld",(long)RapidopsCommon.sharedInstance.hourOfDay] ;
    dict[kRapidopsQSKeyTimeDayOfWeek] = [NSString stringWithFormat:@"%ld",RapidopsCommon.sharedInstance.dayOfWeek];
    dict[kRapidopsQSKeyTimeZone] = [NSString stringWithFormat:@"%ld",RapidopsCommon.sharedInstance.timeZone];
    
    dict[kRapidopsQSKeySessionId] = [[NSUUID UUID] UUIDString];
    dict[kRapidopsQSKeyVisitorId] = [[NSUUID UUID] UUIDString];
    dict[kRapidopsQSKeyTenantId] = self.tenantID;
    dict[kRapidopsQSKeyTimestamp] = @((long)(NSTimeInterval)[[NSDate date] timeIntervalSince1970]*1000);
    
    NSString* uuid = @"";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"SessionID"] != nil) {
        uuid = [userDefaults valueForKey:@"SessionID"];
    } else {
        uuid = [[NSUUID UUID] UUIDString];
    }
    dict[kRapidopsQSKeyUUID] = uuid;
    
    return dict;
}


- (NSInteger)sessionLengthInSeconds
{
    NSTimeInterval currentTime = NSDate.date.timeIntervalSince1970;
    unsentSessionLength += (currentTime - lastSessionStartTime);
    lastSessionStartTime = currentTime;
    int sessionLengthInSeconds = (int)unsentSessionLength;
    unsentSessionLength -= sessionLengthInSeconds;
    return sessionLengthInSeconds;
}

- (NSData *)pictureUploadDataForRequest:(NSString *)requestString
{
#if TARGET_OS_IOS
    NSString* localPicturePath = nil;
    NSString* tempURLString = [@"http://example.com/path?" stringByAppendingString:requestString];
    NSURLComponents* URLComponents = [NSURLComponents componentsWithString:tempURLString];
    for (NSURLQueryItem* queryItem in URLComponents.queryItems)
    {
        if ([queryItem.name isEqualToString:kRapidopsQSKeyUserDetails])
        {
            NSString* unescapedValue = [queryItem.value stringByRemovingPercentEncoding];
            if (!unescapedValue)
                return nil;
            
            NSDictionary* pathDictionary = [NSJSONSerialization JSONObjectWithData:[unescapedValue RPD_dataUTF8] options:0 error:nil];
            localPicturePath = pathDictionary[kRapidopsLocalPicturePath];
            break;
        }
    }
    
    if (!localPicturePath || !localPicturePath.length)
        return nil;
    
    Rapidops_LOG(@"Local picture path successfully extracted from query string: %@", localPicturePath);
    
    NSArray* allowedFileTypes = @[@"gif", @"png", @"jpg", @"jpeg"];
    NSString* fileExt = localPicturePath.pathExtension.lowercaseString;
    NSInteger fileExtIndex = [allowedFileTypes indexOfObject:fileExt];
    
    if (fileExtIndex == NSNotFound)
        return nil;
    
    NSData* imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:localPicturePath]];
    
    if (!imageData)
    {
        Rapidops_LOG(@"Local picture data can not be read!");
        return nil;
    }
    
    Rapidops_LOG(@"Local picture data read successfully.");
    
    //NOTE: Overcome failing PNG file upload if data is directly read from disk
    if (fileExtIndex == 1)
        imageData = UIImagePNGRepresentation([UIImage imageWithData:imageData]);
    
    //NOTE: Remap content type from jpg to jpeg
    if (fileExtIndex == 2)
        fileExtIndex = 3;
    
    NSString* boundaryStart = [NSString stringWithFormat:@"--%@\r\n", kRapidopsUploadBoundary];
    NSString* contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"pictureFile\"; filename=\"%@\"\r\n", localPicturePath.lastPathComponent];
    NSString* contentType = [NSString stringWithFormat:@"Content-Type: image/%@\r\n\r\n", allowedFileTypes[fileExtIndex]];
    NSString* boundaryEnd = [NSString stringWithFormat:@"\r\n--%@--\r\n", kRapidopsUploadBoundary];
    
    NSMutableData* uploadData = NSMutableData.new;
    [uploadData appendData:[boundaryStart RPD_dataUTF8]];
    [uploadData appendData:[contentDisposition RPD_dataUTF8]];
    [uploadData appendData:[contentType RPD_dataUTF8]];
    [uploadData appendData:imageData];
    [uploadData appendData:[boundaryEnd RPD_dataUTF8]];
    return uploadData;
#endif
    return nil;
}

- (NSString *)appendChecksum:(NSString *)queryString
{
    if (self.secretSalt)
    {
        NSString* checksum = [[queryString stringByAppendingString:self.secretSalt] RPD_SHA256];
        return [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsQSKeyChecksum256, checksum];
    }
    
    return queryString;
}

- (BOOL)isRequestSuccessful:(NSURLResponse *)response
{
    if (!response)
        return NO;
    
    NSInteger code = ((NSHTTPURLResponse*)response).statusCode;
    
    return (code >= 200 && code < 300);
}

#pragma mark ---

- (NSURLSession *)URLSession
{
    if (self.pinnedCertificates)
    {
        Rapidops_LOG(@"%d pinned certificate(s) specified in config.", (int)self.pinnedCertificates.count);
        NSURLSessionConfiguration *sc = [NSURLSessionConfiguration defaultSessionConfiguration];
        return [NSURLSession sessionWithConfiguration:sc delegate:self delegateQueue:nil];
    }
    
    return NSURLSession.sharedSession;
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecKeyRef serverKey = SecTrustCopyPublicKey(serverTrust);
    SecPolicyRef policy = SecPolicyCreateSSL(true, (__bridge CFStringRef)challenge.protectionSpace.host);
    
    __block BOOL isLocalAndServerCertMatch = NO;
    
    for (NSString* certificate in self.pinnedCertificates )
    {
        NSString* localCertPath = [NSBundle.mainBundle pathForResource:certificate ofType:nil];
        if (!localCertPath)
            [NSException raise:@"RapidopsCertificateNotFoundException" format:@"Bundled certificate can not be found for %@", certificate];
        NSData* localCertData = [NSData dataWithContentsOfFile:localCertPath];
        SecCertificateRef localCert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)localCertData);
        SecTrustRef localTrust = NULL;
        SecTrustCreateWithCertificates(localCert, policy, &localTrust);
        SecKeyRef localKey = SecTrustCopyPublicKey(localTrust);
        
        CFRelease(localCert);
        CFRelease(localTrust);
        
        if (serverKey != NULL && localKey != NULL && [(__bridge id)serverKey isEqual:(__bridge id)localKey])
        {
            Rapidops_LOG(@"Pinned certificate and server certificate match.");
            
            isLocalAndServerCertMatch = YES;
            CFRelease(localKey);
            break;
        }
        
        if (localKey) CFRelease(localKey);
    }
    
    SecTrustResultType serverTrustResult;
    SecTrustEvaluate(serverTrust, &serverTrustResult);
    BOOL isServerCertValid = (serverTrustResult == kSecTrustResultUnspecified || serverTrustResult == kSecTrustResultProceed);
    
    if (isLocalAndServerCertMatch && isServerCertValid)
    {
        Rapidops_LOG(@"Pinned certificate check is successful. Proceeding with request.");
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
    }
    else
    {
        Rapidops_LOG(@"Pinned certificate check is failed! Cancelling request.");
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
    }
    
    if (serverKey) CFRelease(serverKey);
    CFRelease(policy);
}

@end
