// RapidopsAPMNetworkLog.h
//
 
//
 

#import <Foundation/Foundation.h>
#import "Rapidops.h"

@interface RapidopsAPMNetworkLog : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
+ (instancetype)logWithRequest:(NSURLRequest *)request andOriginalDelegate:(id)originalDelegate startNow:(BOOL)startNow;
- (void)start;
- (void)updateWithResponse:(NSURLResponse *)response;
- (void)finish;
- (void)finishWithStatusCode:(NSInteger)statusCode andDataSize:(long long)dataSize;
@end
