// RapidopsEvent.m
//
 
//
 

#import "RapidopsCommon.h"

@implementation RapidopsEvent

NSString* const kRapidopsEventKeyKey           = @"key";
NSString* const kRapidopsEventKeySegmentation  = @"segmentation";
NSString* const kRapidopsEventKeyCount         = @"count";
//NSString* const kRapidopsEventKeySum           = @"sum";
NSString* const kRapidopsEventKeyTimestamp     = @"timestamp";
//NSString* const kRapidopsEventKeyEventTime     = @"eventTime";
NSString* const kRapidopsEventKeyHourOfDay     = @"hour";
//NSString* const kRapidopsEventKeyDayOfWeek     = @"dow";
//NSString* const kRapidopsEventKeyDuration      = @"duration";

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary* eventData = NSMutableDictionary.dictionary;
    eventData[kRapidopsEventKeyKey] = self.key;
    if (self.segmentation)
    {
        eventData[kRapidopsEventKeySegmentation] = self.segmentation;
    }
    eventData[kRapidopsEventKeyCount] = @(self.count);
    //eventData[kRapidopsEventKeySum] = @(self.sum);
    eventData[kRapidopsEventKeyTimestamp] = @((long long)(self.timestamp * 1000));
    eventData[kRapidopsEventKeyHourOfDay] = @(self.hourOfDay);
//    eventData[kRapidopsEventKeyDayOfWeek] = @(self.dayOfWeek);
//    eventData[kRapidopsEventKeyDuration] = @(self.duration);
    return eventData;
}

- (NSDictionary *)dictionaryRepresentationWithJson
{
	NSMutableDictionary* eventData = NSMutableDictionary.dictionary;
	eventData[kRapidopsEventKeyKey] = self.key;
	if (self.segmentation)
	{
		eventData[kRapidopsEventKeySegmentation] = self.segmentation;
	}
	eventData[kRapidopsEventKeyCount] = @((long long)(self.count));
	//eventData[kRapidopsEventKeySum] = @((float)(self.sum));
	eventData[kRapidopsEventKeyTimestamp] = @((long long)(self.timestamp * 1000)) ;
//	eventData[kRapidopsEventKeyEventTime] = [NSNumber numberWithDouble:(self.timestamp)] ;
	eventData[kRapidopsEventKeyHourOfDay] = @(self.hourOfDay);
//	eventData[kRapidopsEventKeyDayOfWeek] = @(self.dayOfWeek);
//	eventData[kRapidopsEventKeyDuration] = [NSNumber numberWithDouble:(self.duration)];
	return eventData;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        self.key = [decoder decodeObjectForKey:NSStringFromSelector(@selector(key))];
        self.segmentation = [decoder decodeObjectForKey:NSStringFromSelector(@selector(segmentation))];
        self.count = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(count))];
        self.sum = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(sum))];
        self.timestamp = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(timestamp))];
        self.hourOfDay = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(hourOfDay))];
        self.dayOfWeek = [decoder decodeIntegerForKey:NSStringFromSelector(@selector(dayOfWeek))];
        self.duration = [decoder decodeDoubleForKey:NSStringFromSelector(@selector(duration))];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.key forKey:NSStringFromSelector(@selector(key))];
    [encoder encodeObject:self.segmentation forKey:NSStringFromSelector(@selector(segmentation))];
    [encoder encodeInteger:self.count forKey:NSStringFromSelector(@selector(count))];
    [encoder encodeDouble:self.sum forKey:NSStringFromSelector(@selector(sum))];
    [encoder encodeDouble:self.timestamp forKey:NSStringFromSelector(@selector(timestamp))];
    [encoder encodeInteger:self.hourOfDay forKey:NSStringFromSelector(@selector(hourOfDay))];
    [encoder encodeInteger:self.dayOfWeek forKey:NSStringFromSelector(@selector(dayOfWeek))];
    [encoder encodeDouble:self.duration forKey:NSStringFromSelector(@selector(duration))];
}
@end
