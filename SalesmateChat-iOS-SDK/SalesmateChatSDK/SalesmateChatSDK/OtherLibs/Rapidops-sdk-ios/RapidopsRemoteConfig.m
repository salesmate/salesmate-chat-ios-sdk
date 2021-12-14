// RapidopsLocationManager.h
//
 
//
 

#import "RapidopsCommon.h"

NSString* const kRapidopsRCOutputEndpoint        = @"/o";
NSString* const kRapidopsRCSDKEndpoint           = @"/sdk";

NSString* const kRapidopsRCKeyMethod             = @"method";
NSString* const kRapidopsRCKeyFetchRemoteConfig  = @"fetch_remote_config";
NSString* const kRapidopsRCKeyKeys               = @"keys";
NSString* const kRapidopsRCKeyOmitKeys           = @"omit_keys";
NSString* const kRapidopsRCKeyMetrics            = @"metrics";

@interface RapidopsRemoteConfig ()
@property (nonatomic) NSDictionary* cachedRemoteConfig;
@end

@implementation RapidopsRemoteConfig

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsRemoteConfig* s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.cachedRemoteConfig = [RapidopsPersistency.sharedInstance retrieveRemoteConfig];
    }

    return self;
}

#pragma mark ---

- (void)startRemoteConfig
{
    if (!self.isEnabledOnInitialConfig)
        return;

    if (!RapidopsConsentManager.sharedInstance.hasAnyConsent)
        return;

    Rapidops_LOG(@"Fetching remote config on start...");

    [self fetchRemoteConfigForKeys:nil omitKeys:nil completionHandler:^(NSDictionary *remoteConfig, NSError *error)
    {
        if (!error)
        {
            Rapidops_LOG(@"Fetching remote config on start is successful. \n%@", remoteConfig);

            self.cachedRemoteConfig = remoteConfig;
            [RapidopsPersistency.sharedInstance storeRemoteConfig:self.cachedRemoteConfig];
        }
        else
        {
            Rapidops_LOG(@"Fetching remote config on start failed: %@", error);
        }

        if (self.remoteConfigCompletionHandler)
            self.remoteConfigCompletionHandler(error);
    }];
}

- (void)updateRemoteConfigForForKeys:(NSArray *)keys omitKeys:(NSArray *)omitKeys completionHandler:(void (^)(NSError * error))completionHandler
{
    if (!RapidopsConsentManager.sharedInstance.hasAnyConsent)
        return;

    Rapidops_LOG(@"Fetching remote config manually...");

    [self fetchRemoteConfigForKeys:keys omitKeys:omitKeys completionHandler:^(NSDictionary *remoteConfig, NSError *error)
    {
        if (!error)
        {
            Rapidops_LOG(@"Fetching remote config manually is successful. \n%@", remoteConfig);

            if (!keys && !omitKeys)
            {
                self.cachedRemoteConfig = remoteConfig;
            }
            else
            {
                NSMutableDictionary* partiallyUpdatedRemoteConfig = self.cachedRemoteConfig.mutableCopy;
                [partiallyUpdatedRemoteConfig addEntriesFromDictionary:remoteConfig];
                self.cachedRemoteConfig = [NSDictionary dictionaryWithDictionary:partiallyUpdatedRemoteConfig];
            }

            [RapidopsPersistency.sharedInstance storeRemoteConfig:self.cachedRemoteConfig];
        }
        else
        {
            Rapidops_LOG(@"Fetching remote config manually failed: %@", error);
        }

        if (completionHandler)
            completionHandler(error);
    }];
}

- (id)remoteConfigValueForKey:(NSString *)key
{
    return self.cachedRemoteConfig[key];
}

- (void)clearCachedRemoteConfig
{
    self.cachedRemoteConfig = nil;
    [RapidopsPersistency.sharedInstance storeRemoteConfig:self.cachedRemoteConfig];
}

#pragma mark ---

- (void)fetchRemoteConfigForKeys:(NSArray *)keys omitKeys:(NSArray *)omitKeys completionHandler:(void (^)(NSDictionary* remoteConfig, NSError * error))completionHandler
{
    if (!completionHandler)
        return;

    NSURL* remoteConfigURL = [self remoteConfigURLForKeys:keys omitKeys:omitKeys];

    NSURLRequest* request = [NSURLRequest requestWithURL:remoteConfigURL];
    NSURLSessionTask* task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
    {
        NSDictionary* remoteConfig = nil;

        if (!error)
        {
            remoteConfig = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        }

        if (!error)
        {
            if (((NSHTTPURLResponse*)response).statusCode != 200)
            {
                NSMutableDictionary* userInfo = remoteConfig.mutableCopy;
                userInfo[NSLocalizedDescriptionKey] = @"Remote config general API error";
                error = [NSError errorWithDomain:kRapidopsErrorDomain code:RPDErrorRemoteConfigGeneralAPIError userInfo:userInfo];
            }
        }

        if (error)
        {
            Rapidops_LOG(@"Remote Config Request <%p> failed!\nError: %@", request, error);

            dispatch_async(dispatch_get_main_queue(), ^
            {
                completionHandler(nil, error);
            });

            return;
        }

        Rapidops_LOG(@"Remote Config Request <%p> successfully completed.", request);

        dispatch_async(dispatch_get_main_queue(), ^
        {
            completionHandler(remoteConfig, nil);
        });
    }];

    [task resume];

    Rapidops_LOG(@"Remote Config Request <%p> started:\n[%@] %@", (id)request, request.HTTPMethod, request.URL.absoluteString);
}

- (NSURL *)remoteConfigURLForKeys:(NSArray *)keys omitKeys:(NSArray *)omitKeys
{
    NSString* queryString = [RapidopsConnectionManager.sharedInstance queryEssentials];

    queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsRCKeyMethod, kRapidopsRCKeyFetchRemoteConfig];

    if (keys)
    {
        queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsRCKeyKeys, keys.RPD_JSONify];
    }
    else if (omitKeys)
    {
        queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsRCKeyOmitKeys, omitKeys.RPD_JSONify];
    }

    if (RapidopsConsentManager.sharedInstance.consentForSessions)
    {
        queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsRCKeyMetrics, [RapidopsDeviceInfo metrics]];
    }

    queryString = [RapidopsConnectionManager.sharedInstance appendChecksum:queryString];

    NSString* URLString = [NSString stringWithFormat:@"%@%@%@?%@",
                           RapidopsConnectionManager.sharedInstance.host,
                           kRapidopsRCOutputEndpoint, kRapidopsRCSDKEndpoint,
                           queryString];

    return [NSURL URLWithString:URLString];
}

@end
