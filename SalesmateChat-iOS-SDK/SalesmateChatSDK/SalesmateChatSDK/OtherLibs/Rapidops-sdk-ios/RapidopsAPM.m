// RapidopsAPM.m
//
 
//
 

#import "RapidopsCommon.h"

@interface RapidopsAPM ()
@property (nonatomic) NSMutableArray* exceptionURLs;
@end

@implementation RapidopsAPM

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsAPM* s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSURL * url = [NSURL URLWithString:RapidopsConnectionManager.sharedInstance.host];
        NSString* hostAndPath = [url.host stringByAppendingString:url.path];
        self.exceptionURLs = [NSMutableArray arrayWithObject:hostAndPath];
    }

    return self;
}

- (void)startAPM
{
    NSArray* swizzling =
    @[
        @{@"c":NSURLConnection.class, @"f":@YES, @"s":[NSValue valueWithPointer:@selector(sendSynchronousRequest:returningResponse:error:)]},
        @{@"c":NSURLConnection.class, @"f":@YES, @"s":[NSValue valueWithPointer:@selector(sendAsynchronousRequest:queue:completionHandler:)]},
        @{@"c":NSURLConnection.class, @"f":@NO,  @"s":[NSValue valueWithPointer:@selector(initWithRequest:delegate:)]},
        @{@"c":NSURLConnection.class, @"f":@NO,  @"s":[NSValue valueWithPointer:@selector(initWithRequest:delegate:startImmediately:)]},
        @{@"c":NSURLConnection.class, @"f":@NO,  @"s":[NSValue valueWithPointer:@selector(start)]},
        @{@"c":NSURLSession.class,    @"f":@NO,  @"s":[NSValue valueWithPointer:@selector(dataTaskWithRequest:completionHandler:)]},
        @{@"c":NSURLSession.class,    @"f":@NO,  @"s":[NSValue valueWithPointer:@selector(downloadTaskWithRequest:completionHandler:)]},
        @{@"c":NSURLSessionTask.class,     @"f":@NO,  @"s":[NSValue valueWithPointer:@selector(resume)]}
    ];


    for (NSDictionary* dict in swizzling)
    {
        Class c = dict[@"c"];
        BOOL isClassMethod = [dict[@"f"] boolValue];
        SEL originalSelector = [dict[@"s"] pointerValue];
        SEL RapidopsSelector = NSSelectorFromString([@"Rapidops_" stringByAppendingString:NSStringFromSelector(originalSelector)]);

        Method O_method = isClassMethod ? class_getClassMethod(c, originalSelector) : class_getInstanceMethod(c, originalSelector);
        Method C_method = isClassMethod ? class_getClassMethod(c, RapidopsSelector) : class_getInstanceMethod(c, RapidopsSelector);
        method_exchangeImplementations(O_method, C_method);
    }
}

- (void)addExceptionForAPM:(NSString *)string
{
    NSURL* url = [NSURL URLWithString:string];
    NSString* hostAndPath = [url.host stringByAppendingString:url.path];

    if (![RapidopsAPM.sharedInstance.exceptionURLs containsObject:hostAndPath])
    {
        [RapidopsAPM.sharedInstance.exceptionURLs addObject:hostAndPath];
    }
}

- (void)removeExceptionForAPM:(NSString *)string
{
    NSURL * url = [NSURL URLWithString:string];
    NSString* hostAndPath = [url.host stringByAppendingString:url.path];
    [RapidopsAPM.sharedInstance.exceptionURLs removeObject:hostAndPath];
}

- (BOOL)isException:(NSURLRequest *)request
{
    NSString* hostAndPath = [request.URL.host stringByAppendingString:request.URL.path];
    __block BOOL isException = NO;

    [RapidopsAPM.sharedInstance.exceptionURLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
    {
        if ([request.URL.host isEqualToString:obj] || [hostAndPath hasPrefix:obj])
        {
            isException = YES;
            *stop = YES;
        }
    }];

    return isException;
}
@end


#pragma mark -


@implementation NSURLConnection (RapidopsAPM)

- (RapidopsAPMNetworkLog *)APMNetworkLog
{
    return objc_getAssociatedObject(self, @selector(APMNetworkLog));
}

- (void)setAPMNetworkLog:(RapidopsAPMNetworkLog *)APMNetworkLog
{
    objc_setAssociatedObject(self, @selector(APMNetworkLog), APMNetworkLog, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSData *)Rapidops_sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    RapidopsAPMNetworkLog* nl = [RapidopsAPMNetworkLog logWithRequest:request andOriginalDelegate:nil startNow:YES];

    NSData *data = [self Rapidops_sendSynchronousRequest:request returningResponse:response error:error];

    [nl finishWithStatusCode:((NSHTTPURLResponse*)*response).statusCode andDataSize:data.length];

    return data;
}

+ (void)Rapidops_sendAsynchronousRequest:(NSURLRequest *) request queue:(NSOperationQueue *) queue completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler

{
    RapidopsAPMNetworkLog* nl = [RapidopsAPMNetworkLog logWithRequest:request andOriginalDelegate:nil startNow:YES];

    [self Rapidops_sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse * response, NSData * data, NSError * connectionError)
    {
        [nl finishWithStatusCode:((NSHTTPURLResponse*)response).statusCode andDataSize:data.length];

        if (handler)
            handler(response, data, connectionError);
    }];
};

- (instancetype)Rapidops_initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
    RapidopsAPMNetworkLog* nl = [RapidopsAPMNetworkLog logWithRequest:request andOriginalDelegate:delegate startNow:YES];
    NSURLConnection* conn = [self Rapidops_initWithRequest:request delegate:(nl ?: delegate) startImmediately:YES];
    conn.APMNetworkLog = nl;

    return conn;
}

- (instancetype)Rapidops_initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
    RapidopsAPMNetworkLog* nl = [RapidopsAPMNetworkLog logWithRequest:request andOriginalDelegate:delegate startNow:startImmediately];
    NSURLConnection* conn = [self Rapidops_initWithRequest:request delegate:(nl ?: delegate) startImmediately:startImmediately];
    conn.APMNetworkLog = nl;

    return conn;
}

- (void)Rapidops_start
{
    [self.APMNetworkLog start];

    [self Rapidops_start];
}

@end


#pragma mark -


@implementation NSURLSessionTask (RapidopsAPM)

- (RapidopsAPMNetworkLog *)APMNetworkLog
{
    return objc_getAssociatedObject(self, @selector(APMNetworkLog));
}

- (void)setAPMNetworkLog:(id)APMNetworkLog
{
    objc_setAssociatedObject(self, @selector(APMNetworkLog), APMNetworkLog, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)Rapidops_resume
{
    [self.APMNetworkLog start];

    [self Rapidops_resume];
}

@end


@implementation NSURLSession (RapidopsAPM)
- (NSURLSessionDataTask *)Rapidops_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error))completionHandler
{
    RapidopsAPMNetworkLog* nl = [RapidopsAPMNetworkLog logWithRequest:request andOriginalDelegate:nil startNow:YES];

    NSURLSessionDataTask* dataTask = [self Rapidops_dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error)
    {
        [nl finishWithStatusCode:((NSHTTPURLResponse*)response).statusCode andDataSize:data.length];

        if (completionHandler)
            completionHandler(data, response, error);
    }];

    dataTask.APMNetworkLog = nl;

    return dataTask;
}

- (NSURLSessionDownloadTask *)Rapidops_downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL * location, NSURLResponse * response, NSError * error))completionHandler
{
    RapidopsAPMNetworkLog* nl = [RapidopsAPMNetworkLog logWithRequest:request andOriginalDelegate:nil startNow:YES];

    NSURLSessionDownloadTask* downloadTask = [self Rapidops_downloadTaskWithRequest:request completionHandler:^(NSURL * location, NSURLResponse * response, NSError * error)
    {
        NSHTTPURLResponse* HTTPresponse = (NSHTTPURLResponse*)response;
        long long dataSize = [[HTTPresponse allHeaderFields][@"Content-Length"] longLongValue];

        [nl finishWithStatusCode:((NSHTTPURLResponse*)response).statusCode andDataSize:dataSize];

        if (completionHandler)
            completionHandler(location, response, error);
    }];

    downloadTask.APMNetworkLog = nl;

    return downloadTask;
}

@end


