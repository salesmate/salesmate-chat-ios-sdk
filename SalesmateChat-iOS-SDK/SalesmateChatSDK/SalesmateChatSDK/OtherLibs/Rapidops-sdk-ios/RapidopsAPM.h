// RapidopsAPM.h
//
 
//
 

#import <Foundation/Foundation.h>

@interface RapidopsAPM : NSObject
+ (instancetype)sharedInstance;
- (void)startAPM;
- (void)addExceptionForAPM:(NSString *)exceptionURL;
- (void)removeExceptionForAPM:(NSString* )exceptionURL;
- (BOOL)isException:(NSURLRequest *)request;
@end
