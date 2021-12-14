// RapidopsEvent.h
//
 
//
 

#import <Foundation/Foundation.h>

@interface RapidopsEvent : NSObject <NSCoding>

@property (nonatomic, copy) NSString* key;
@property (nonatomic, copy) NSDictionary* segmentation;
@property (nonatomic) NSUInteger count;
@property (nonatomic) double sum;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) NSUInteger hourOfDay;
@property (nonatomic) NSUInteger dayOfWeek;
@property (nonatomic) NSTimeInterval duration;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)dictionaryRepresentationWithJson;


@end
