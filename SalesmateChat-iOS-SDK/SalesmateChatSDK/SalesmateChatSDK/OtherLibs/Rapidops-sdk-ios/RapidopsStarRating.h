// RapidopsStarRating.h
//
 
//
 

#import <Foundation/Foundation.h>

@interface RapidopsStarRating : NSObject
#if TARGET_OS_IOS
+ (instancetype)sharedInstance;

- (void)showDialog:(void(^)(NSInteger rating))completion;
- (void)checkFeedbackWidgetWithID:(NSString *)widgetID completionHandler:(void (^)(NSError * error))completionHandler;
- (void)checkForAutoAsk;

@property (nonatomic) NSString* message;
@property (nonatomic) NSString* dismissButtonTitle;
@property (nonatomic) NSUInteger sessionCount;
@property (nonatomic) BOOL disableAskingForEachAppVersion;
@property (nonatomic, copy) void (^ratingCompletionForAutoAsk)(NSInteger);
#endif
@end
