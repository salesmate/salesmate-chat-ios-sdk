// RapidopsViewTracking.m
//
 
//
 

#import "RapidopsCommon.h"

@interface RapidopsViewTracking ()
@property (nonatomic) NSString* lastView;
@property (nonatomic) NSTimeInterval lastViewStartTime;
@property (nonatomic) NSTimeInterval accumulatedTime;
@property (nonatomic) NSMutableArray* exceptionViewControllers;
@end

NSString* const kRapidopsReservedEventView = @"[RPD]_view";

NSString* const kRapidopsVTKeyName     = @"name";
NSString* const kRapidopsVTKeySegment  = @"segment";
NSString* const kRapidopsVTKeyVisit    = @"visit";
NSString* const kRapidopsVTKeyStart    = @"start";

#if (TARGET_OS_IOS || TARGET_OS_TV)
@interface UIViewController (RapidopsViewTracking)
- (void)Rapidops_viewDidAppear:(BOOL)animated;
@end
#endif

@implementation RapidopsViewTracking

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsViewTracking* s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.exceptionViewControllers =
        @[
            @"RPDInternalViewController",
            @"UINavigationController",
            @"UIAlertController",
            @"UIPageViewController",
            @"UITabBarController",
            @"UIReferenceLibraryViewController",
            @"UISplitViewController",
            @"UIInputViewController",
            @"UISearchController",
            @"UISearchContainerViewController",
            @"UIApplicationRotationFollowingController",
            @"MFMailComposeInternalViewController",
            @"MFMailComposeInternalViewController",
            @"MFMailComposePlaceholderViewController",
            @"UIInputWindowController",
            @"_UIFallbackPresentationViewController",
            @"UIActivityViewController",
            @"UIActivityGroupViewController",
            @"_UIActivityGroupListViewController",
            @"_UIActivityViewControllerContentController",
            @"UIKeyboardCandidateRowViewController",
            @"UIKeyboardCandidateGridCollectionViewController",
            @"UIPrintMoreOptionsTableViewController",
            @"UIPrintPanelTableViewController",
            @"UIPrintPanelViewController",
            @"UIPrintPaperViewController",
            @"UIPrintPreviewViewController",
            @"UIPrintRangeViewController",
            @"UIDocumentMenuViewController",
            @"UIDocumentPickerViewController",
            @"UIDocumentPickerExtensionViewController",
            @"UIInterfaceActionGroupViewController",
            @"UISystemInputViewController",
            @"UIRecentsInputViewController",
            @"UICompatibilityInputViewController",
            @"UIInputViewAnimationControllerViewController",
            @"UISnapshotModalViewController",
            @"UIMultiColumnViewController",
            @"UIKeyCommandDiscoverabilityHUDViewController"
        ].mutableCopy;
    }

    return self;
}

#pragma mark -

- (void)startView:(NSString *)viewName
{
    if (!viewName)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForViewTracking)
        return;

    viewName = viewName.copy;

    [self endView];

    Rapidops_LOG(@"View tracking started: %@", viewName);

    NSMutableDictionary* segmentation =
    @{
        kRapidopsVTKeyName: viewName,
        kRapidopsVTKeySegment: RapidopsDeviceInfo.osName,
        kRapidopsVTKeyVisit: @1
    }.mutableCopy;

    if (!self.lastView)
        segmentation[kRapidopsVTKeyStart] = @1;

    [Rapidops.sharedInstance recordReservedEvent:kRapidopsReservedEventView segmentation:segmentation];

    self.lastView = viewName;
    self.lastViewStartTime = RapidopsCommon.sharedInstance.uniqueTimestamp;
}

- (void)endView
{
    if (!RapidopsConsentManager.sharedInstance.consentForViewTracking)
        return;

    if (self.lastView)
    {
        NSDictionary* segmentation =
        @{
            kRapidopsVTKeyName: self.lastView,
            kRapidopsVTKeySegment: RapidopsDeviceInfo.osName,
        };

        NSTimeInterval duration = NSDate.date.timeIntervalSince1970 - self.lastViewStartTime + self.accumulatedTime;
        self.accumulatedTime = 0;
        [Rapidops.sharedInstance recordReservedEvent:kRapidopsReservedEventView segmentation:segmentation count:1 sum:0 duration:duration timestamp:self.lastViewStartTime];

        Rapidops_LOG(@"View tracking ended: %@ duration: %f", self.lastView, duration);
    }
}

- (void)pauseView
{
    if (self.lastViewStartTime)
        self.accumulatedTime = NSDate.date.timeIntervalSince1970 - self.lastViewStartTime;
}

- (void)resumeView
{
    self.lastViewStartTime = RapidopsCommon.sharedInstance.uniqueTimestamp;
}

#pragma mark -

#if (TARGET_OS_IOS || TARGET_OS_TV)
- (void)startAutoViewTracking
{
    if (!self.isEnabledOnInitialConfig)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForViewTracking)
        return;

    self.isAutoViewTrackingActive = YES;

    [self swizzleViewTrackingMethods];

    UIViewController* topVC = RapidopsCommon.sharedInstance.topViewController;
    NSString* viewTitle = [RapidopsViewTracking.sharedInstance titleForViewController:topVC];
    [self startView:viewTitle];
}

- (void)swizzleViewTrackingMethods
{
    static BOOL alreadySwizzled;
    if (alreadySwizzled)
        return;

    alreadySwizzled = YES;

    Method O_method = class_getInstanceMethod(UIViewController.class, @selector(viewDidAppear:));
    Method C_method = class_getInstanceMethod(UIViewController.class, @selector(Rapidops_viewDidAppear:));
    method_exchangeImplementations(O_method, C_method);
}

- (void)stopAutoViewTracking
{
    if (!self.isEnabledOnInitialConfig)
        return;

    self.isAutoViewTrackingActive = NO;

    self.lastView = nil;
    self.lastViewStartTime = 0;
    self.accumulatedTime = 0;
}

#pragma mark -

- (void)setIsAutoViewTrackingActive:(BOOL)isAutoViewTrackingActive
{
    if (!self.isEnabledOnInitialConfig)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForViewTracking)
        return;

    _isAutoViewTrackingActive = isAutoViewTrackingActive;
}

#pragma mark -

- (void)addExceptionForAutoViewTracking:(NSString *)exception
{
    if (![self.exceptionViewControllers containsObject:exception])
        [self.exceptionViewControllers addObject:exception];
}

- (void)removeExceptionForAutoViewTracking:(NSString *)exception
{
    [self.exceptionViewControllers removeObject:exception];
}

#pragma mark -

- (NSString*)titleForViewController:(UIViewController *)viewController
{
    if (!viewController)
        return nil;

    NSString* title = viewController.title;

    if (!title)
        title = [viewController.navigationItem.titleView isKindOfClass:UILabel.class] ? ((UILabel *)viewController.navigationItem.titleView).text : nil;

    if (!title)
        title = NSStringFromClass(viewController.class);

    return title;
}

#endif
@end

#pragma mark -

#if (TARGET_OS_IOS || TARGET_OS_TV)
@implementation UIViewController (RapidopsViewTracking)
- (void)Rapidops_viewDidAppear:(BOOL)animated
{
    [self Rapidops_viewDidAppear:animated];

    if (!RapidopsViewTracking.sharedInstance.isAutoViewTrackingActive)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForViewTracking)
        return;

    NSString* viewTitle = [RapidopsViewTracking.sharedInstance titleForViewController:self];

    if ([RapidopsViewTracking.sharedInstance.lastView isEqualToString:viewTitle])
        return;

    BOOL isException = NO;

    for (NSString* exception in RapidopsViewTracking.sharedInstance.exceptionViewControllers)
    {
        isException = [self.title isEqualToString:exception] ||
                      [self isKindOfClass:NSClassFromString(exception)] ||
                      [NSStringFromClass(self.class) isEqualToString:exception];

        if (isException)
            break;
    }

    if (!isException)
        [RapidopsViewTracking.sharedInstance startView:viewTitle];
}
@end
#endif
