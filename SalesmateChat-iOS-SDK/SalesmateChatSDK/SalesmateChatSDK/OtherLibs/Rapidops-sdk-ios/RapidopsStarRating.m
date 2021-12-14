// RapidopsStarRating.m
//
 
//
 

#import "RapidopsCommon.h"
#if TARGET_OS_IOS
#import <WebKit/WebKit.h>
#endif

@interface RapidopsStarRating ()
#if TARGET_OS_IOS
@property (nonatomic) UIAlertController* alertController;
@property (nonatomic, copy) void (^ratingCompletion)(NSInteger);
#endif
@end

NSString* const kRapidopsReservedEventStarRating = @"[RPD]_star_rating";
NSString* const kRapidopsStarRatingStatusSessionCountKey = @"kRapidopsStarRatingStatusSessionCountKey";
NSString* const kRapidopsStarRatingStatusHasEverAskedAutomatically = @"kRapidopsStarRatingStatusHasEverAskedAutomatically";

NSString* const kRapidopsSRKeyAppKey         = @"app_key";
NSString* const kRapidopsSRKeyPlatform       = @"platform";
NSString* const kRapidopsSRKeyAppVersion     = @"app_version";
NSString* const kRapidopsSRKeyRating         = @"rating";
NSString* const kRapidopsSRKeyWidgetID       = @"widget_id";
NSString* const kRapidopsSRKeyDeviceID       = @"device_id";
NSString* const kRapidopsSRKeySDKVersion     = @"sdk_version";
NSString* const kRapidopsSRKeySDKName        = @"sdk_name";
NSString* const kRapidopsSRKeyID             = @"_id";
NSString* const kRapidopsSRKeyTargetDevices  = @"target_devices";
NSString* const kRapidopsSRKeyPhone          = @"phone";
NSString* const kRapidopsSRKeyTablet         = @"tablet";

NSString* const kRapidopsOutputEndpoint      = @"/o";
NSString* const kRapidopsFeedbackEndpoint    = @"/feedback";
NSString* const kRapidopsWidgetEndpoint      = @"/widget";

const CGFloat kRapidopsStarRatingButtonSize = 40.0;

@implementation RapidopsStarRating
#if TARGET_OS_IOS
{
    UIButton* btn_star[5];
}

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsStarRating* s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSString* langDesignator = [NSLocale.preferredLanguages.firstObject substringToIndex:2];

        NSDictionary* dictMessage =
        @{
            @"en": @"How would you rate the app?",
            @"tr": @"Uygulamayı nasıl değerlendirirsiniz?",
            @"ja": @"あなたの評価を教えてください。",
            @"zh": @"请告诉我你的评价。",
            @"ru": @"Как бы вы оценили приложение?",
            @"cz": @"Jak hodnotíte aplikaci?",
            @"lv": @"Kā Jūs novērtētu šo lietotni?",
            @"bn": @"আপনি কিভাবে এই এপ্লিক্যাশনটি মূল্যায়ন করবেন?",
            @"hi": @"आप एप्लीकेशन का मूल्यांकन कैसे करेंगे?",
        };

        self.message = dictMessage[langDesignator];
        if (!self.message)
            self.message = dictMessage[@"en"];
    }

    return self;
}

#pragma mark - Star Rating

- (void)showDialog:(void(^)(NSInteger rating))completion
{
    if (!RapidopsConsentManager.sharedInstance.consentForStarRating)
        return;

    self.ratingCompletion = completion;

    self.alertController = [UIAlertController alertControllerWithTitle:@" " message:self.message preferredStyle:UIAlertControllerStyleAlert];

    RPDButton* dismissButton = [RPDButton dismissAlertButton];
    dismissButton.onClick = ^(id sender)
    {
        [self.alertController dismissViewControllerAnimated:YES completion:^
        {
            [self finishWithRating:0];
        }];
    };
    [self.alertController.view addSubview:dismissButton];

    RPDInternalViewController* cvc = RPDInternalViewController.new;
    [cvc setPreferredContentSize:(CGSize){kRapidopsStarRatingButtonSize * 5, kRapidopsStarRatingButtonSize * 1.5}];
    [cvc.view addSubview:[self starView]];

    @try
    {
        [self.alertController setValue:cvc forKey:@"contentViewController"];
    }
    @catch (NSException* exception)
    {
        Rapidops_LOG(@"UIAlertController's contentViewController can not be set: \n%@", exception);
    }

    [RapidopsCommon.sharedInstance tryPresentingViewController:self.alertController];
}

- (void)checkForAutoAsk
{
    if (!self.sessionCount)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForStarRating)
        return;

    NSMutableDictionary* status = [RapidopsPersistency.sharedInstance retrieveStarRatingStatus].mutableCopy;

    if (self.disableAskingForEachAppVersion && status[kRapidopsStarRatingStatusHasEverAskedAutomatically])
        return;

    NSString* keyForAppVersion = [kRapidopsStarRatingStatusSessionCountKey stringByAppendingString:RapidopsDeviceInfo.appVersion];
    NSInteger sessionCountSoFar = [status[keyForAppVersion] integerValue];
    sessionCountSoFar++;

    if (self.sessionCount == sessionCountSoFar)
    {
        Rapidops_LOG(@"Asking for star-rating as session count reached specified limit %d ...", (int)self.sessionCount);

        [self showDialog:self.ratingCompletionForAutoAsk];

        status[kRapidopsStarRatingStatusHasEverAskedAutomatically] = @YES;
    }

    status[keyForAppVersion] = @(sessionCountSoFar);

    [RapidopsPersistency.sharedInstance storeStarRatingStatus:status];
}

- (UIView *)starView
{
    UIView* vw_star = [UIView.alloc initWithFrame:(CGRect){0, 0, kRapidopsStarRatingButtonSize * 5, kRapidopsStarRatingButtonSize}];
    vw_star.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;

    for (int i = 0; i < 5; i++)
    {
        btn_star[i] = [UIButton.alloc initWithFrame:(CGRect){i * kRapidopsStarRatingButtonSize, 0, kRapidopsStarRatingButtonSize, kRapidopsStarRatingButtonSize}];
        btn_star[i].titleLabel.font = [UIFont fontWithName:@"Helvetica" size:28];
        [btn_star[i] setTitle:@"★" forState:UIControlStateNormal];
        [btn_star[i] setTitleColor:[self passiveStarColor] forState:UIControlStateNormal];
        [btn_star[i] addTarget:self action:@selector(onClick_star:) forControlEvents:UIControlEventTouchUpInside];

        [vw_star addSubview:btn_star[i]];
    }

    return vw_star;
}

- (void)setMessage:(NSString *)message
{
    if (!message)
        return;

    _message = message;
}

- (void)onClick_star:(id)sender
{
    UIColor* color = [self activeStarColor];
    NSInteger rating = 0;

    for (int i = 0; i < 5; i++)
    {
        [btn_star[i] setTitleColor:color forState:UIControlStateNormal];

        if (btn_star[i] == sender)
        {
            color = [self passiveStarColor];
            rating = i + 1;
        }
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        [self.alertController dismissViewControllerAnimated:YES completion:^{ [self finishWithRating:rating]; }];
    });
}

- (void)finishWithRating:(NSInteger)rating
{
    if (self.ratingCompletion)
        self.ratingCompletion(rating);

    if (rating != 0)
    {
        NSDictionary* segmentation =
        @{
            kRapidopsSRKeyPlatform: RapidopsDeviceInfo.osName,
            kRapidopsSRKeyAppVersion: RapidopsDeviceInfo.appVersion,
            kRapidopsSRKeyRating: @(rating)
        };

        [Rapidops.sharedInstance recordReservedEvent:kRapidopsReservedEventStarRating segmentation:segmentation];
    }

    self.alertController = nil;
    self.ratingCompletion = nil;
}

- (UIColor *)activeStarColor
{
    return [UIColor colorWithRed:253/255.0 green:148/255.0 blue:38/255.0 alpha:1];
}

- (UIColor *)passiveStarColor
{
    return [UIColor colorWithWhite:178/255.0 alpha:1];
}

#pragma mark - Feedback Widget

- (void)checkFeedbackWidgetWithID:(NSString *)widgetID completionHandler:(void (^)(NSError * error))completionHandler
{
    if (!RapidopsConsentManager.sharedInstance.consentForStarRating)
        return;

    if (!widgetID.length)
        return;

    NSURL* widgetCheckURL = [self widgetCheckURL:widgetID];
    NSURLRequest* feedbackWidgetCheckRequest = [NSURLRequest requestWithURL:widgetCheckURL];
    NSURLSessionTask* task = [NSURLSession.sharedSession dataTaskWithRequest:feedbackWidgetCheckRequest completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
    {
        NSDictionary* widgetInfo = nil;

        if (!error)
        {
            widgetInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        }

        if (!error)
        {
            NSMutableDictionary* userInfo = widgetInfo.mutableCopy;

            if (![widgetInfo[kRapidopsSRKeyID] isEqualToString:widgetID])
            {
                userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Feedback widget with ID %@ is not available.", widgetID];
                error = [NSError errorWithDomain:kRapidopsErrorDomain code:RPDErrorFeedbackWidgetNotAvailable userInfo:userInfo];
            }
            else if (![self isDeviceTargetedByWidget:widgetInfo])
            {
                userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Feedback widget with ID %@ does not include this device in target devices list.", widgetID];
                error = [NSError errorWithDomain:kRapidopsErrorDomain code:RPDErrorFeedbackWidgetNotTargetedForDevice userInfo:userInfo];
            }
        }

        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                if (completionHandler)
                    completionHandler(error);
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self presentFeedbackWidgetWithID:widgetID completionHandler:completionHandler];
        });
    }];

    [task resume];
}

- (void)presentFeedbackWidgetWithID:(NSString *)widgetID completionHandler:(void (^)(NSError * error))completionHandler
{
    __block RPDInternalViewController* webVC = RPDInternalViewController.new;
    webVC.view.backgroundColor = UIColor.whiteColor;
    webVC.view.bounds = UIScreen.mainScreen.bounds;
    webVC.modalPresentationStyle = UIModalPresentationCustom;

    WKWebView* webView = [WKWebView.alloc initWithFrame:webVC.view.bounds];
    [webVC.view addSubview:webView];
    NSURL* widgetDisplayURL = [self widgetDisplayURL:widgetID];
    [webView loadRequest:[NSURLRequest requestWithURL:widgetDisplayURL]];

    RPDButton* dismissButton = [RPDButton dismissAlertButton];
    dismissButton.onClick = ^(id sender)
    {
        [webVC dismissViewControllerAnimated:YES completion:^
        {
            if (completionHandler)
                completionHandler(nil);

            webVC = nil;
        }];
    };
    [webVC.view addSubview:dismissButton];

    CGPoint center = dismissButton.center;
    center.y += 20; //NOTE: adjust dismiss button position for status bar
    if (webVC.view.bounds.size.height == 812 || webVC.view.bounds.size.height == 896)
        center.y += 24; //NOTE: adjust dismiss button position for iPhone X type of devices
    dismissButton.center = center;

    [RapidopsCommon.sharedInstance tryPresentingViewController:webVC];
}

- (NSURL *)widgetCheckURL:(NSString *)widgetID
{
    NSString* queryString = [RapidopsConnectionManager.sharedInstance queryEssentials];

    queryString = [queryString stringByAppendingFormat:@"&%@=%@", kRapidopsSRKeyWidgetID, widgetID];

    queryString = [RapidopsConnectionManager.sharedInstance appendChecksum:queryString];

    NSString* URLString = [NSString stringWithFormat:@"%@%@%@%@?%@",
                           RapidopsConnectionManager.sharedInstance.host,
                           kRapidopsOutputEndpoint, kRapidopsFeedbackEndpoint, kRapidopsWidgetEndpoint,
                           queryString];

    return [NSURL URLWithString:URLString];
}

- (NSURL *)widgetDisplayURL:(NSString *)widgetID
{
    NSString* queryString = [RapidopsConnectionManager.sharedInstance queryEssentials];

    queryString = [queryString stringByAppendingFormat:@"&%@=%@&%@=%@",
                   kRapidopsSRKeyWidgetID, widgetID,
                   kRapidopsSRKeyAppVersion, RapidopsDeviceInfo.appVersion];

    queryString = [RapidopsConnectionManager.sharedInstance appendChecksum:queryString];

    NSString* URLString = [NSString stringWithFormat:@"%@%@?%@",
                           RapidopsConnectionManager.sharedInstance.host,
                           kRapidopsFeedbackEndpoint,
                           queryString];

    return [NSURL URLWithString:URLString];
}

- (BOOL)isDeviceTargetedByWidget:(NSDictionary *)widgetInfo
{
    BOOL isTablet = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    BOOL isPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    BOOL isTabletTargeted = [widgetInfo[kRapidopsSRKeyTargetDevices][kRapidopsSRKeyTablet] boolValue];
    BOOL isPhoneTargeted = [widgetInfo[kRapidopsSRKeyTargetDevices][kRapidopsSRKeyPhone] boolValue];

    return ((isTablet && isTabletTargeted) || (isPhone && isPhoneTargeted));
}

#endif
@end
