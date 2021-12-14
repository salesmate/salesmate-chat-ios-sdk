// RapidopsNotificationService.m
//
 
//
 

#import "RapidopsNotificationService.h"

#if DEBUG
#define Rapidops_EXT_LOG(fmt, ...) NSLog([@"%@ " stringByAppendingString:fmt], @"[RapidopsNSE]", ##__VA_ARGS__)
#else
#define Rapidops_EXT_LOG(...)
#endif

NSString* const kRapidopsActionIdentifier = @"RapidopsActionIdentifier";
NSString* const kRapidopsCategoryIdentifier = @"RapidopsCategoryIdentifier";

NSString* const kRapidopsPNKeyRapidopsPayload     = @"c";
NSString* const kRapidopsPNKeyNotificationID     = @"i";
NSString* const kRapidopsPNKeyButtons            = @"b";
NSString* const kRapidopsPNKeyDefaultURL         = @"l";
NSString* const kRapidopsPNKeyAttachment         = @"a";
NSString* const kRapidopsPNKeyActionButtonIndex  = @"b";
NSString* const kRapidopsPNKeyActionButtonTitle  = @"t";
NSString* const kRapidopsPNKeyActionButtonURL    = @"l";

@implementation RapidopsNotificationService
#if TARGET_OS_IOS
+ (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *))contentHandler
{
    Rapidops_EXT_LOG(@"didReceiveNotificationRequest:withContentHandler:");

    NSDictionary* RapidopsPayload = request.content.userInfo[kRapidopsPNKeyRapidopsPayload];
    NSString* notificationID = RapidopsPayload[kRapidopsPNKeyNotificationID];

    if (!notificationID)
    {
        Rapidops_EXT_LOG(@"Rapidops payload not found in notification dictionary!");

        contentHandler(request.content);
        return;
    }

    Rapidops_EXT_LOG(@"Checking for notification modifiers...");
    UNMutableNotificationContent* bestAttemptContent = request.content.mutableCopy;

    NSArray* buttons = RapidopsPayload[kRapidopsPNKeyButtons];
    if (buttons.count)
    {
        Rapidops_EXT_LOG(@"%d custom action buttons found.", (int)buttons.count);

        NSMutableArray* actions = NSMutableArray.new;

        [buttons enumerateObjectsUsingBlock:^(NSDictionary* button, NSUInteger idx, BOOL * stop)
        {
            NSString* actionIdentifier = [NSString stringWithFormat:@"%@%lu", kRapidopsActionIdentifier, (unsigned long)idx + 1];
            UNNotificationAction* action = [UNNotificationAction actionWithIdentifier:actionIdentifier title:button[kRapidopsPNKeyActionButtonTitle] options:UNNotificationActionOptionForeground];
            [actions addObject:action];
        }];

        NSString* categoryIdentifier = [kRapidopsCategoryIdentifier stringByAppendingString:notificationID];

        UNNotificationCategory* category = [UNNotificationCategory categoryWithIdentifier:categoryIdentifier actions:actions intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];

        [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:[NSSet setWithObject:category]];

        bestAttemptContent.categoryIdentifier = categoryIdentifier;
    
        Rapidops_EXT_LOG(@"%d custom action buttons added.", (int)buttons.count);
    }

    NSString* attachmentURL = RapidopsPayload[kRapidopsPNKeyAttachment];
    if (!attachmentURL.length)
    {
        Rapidops_EXT_LOG(@"No attachment specified in Rapidops payload.");
        Rapidops_EXT_LOG(@"Handling of notification finished.");
        contentHandler(bestAttemptContent);
        return;
    }

    Rapidops_EXT_LOG(@"Attachment specified in Rapidops payload: %@", attachmentURL);

    [[NSURLSession.sharedSession downloadTaskWithURL:[NSURL URLWithString:attachmentURL] completionHandler:^(NSURL * location, NSURLResponse * response, NSError * error)
    {
        if (!error)
        {
            Rapidops_EXT_LOG(@"Attachment download completed!");

            NSString* attachmentFileName = [NSString stringWithFormat:@"%@-%@", notificationID, response.suggestedFilename ?: response.URL.absoluteString.lastPathComponent];

            NSString* tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:attachmentFileName];

            if (location && tempPath)
            {
                [NSFileManager.defaultManager moveItemAtPath:location.path toPath:tempPath error:nil];

                NSError* attachmentError = nil;
                UNNotificationAttachment* attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentFileName URL:[NSURL fileURLWithPath:tempPath] options:nil error:&attachmentError];

                if (attachment && !attachmentError)
                {
                    bestAttemptContent.attachments = @[attachment];

                    Rapidops_EXT_LOG(@"Attachment added to notification!");
                }
                else
                {
                    Rapidops_EXT_LOG(@"Attachment creation error: %@", attachmentError);
                }
            }
            else
            {
                Rapidops_EXT_LOG(@"Attachment `location` and/or `tempPath` is nil!");
            }
        }
        else
        {
            Rapidops_EXT_LOG(@"Attachment download error: %@", error);
        }

        Rapidops_EXT_LOG(@"Handling of notification finished.");
        contentHandler(bestAttemptContent);
    }] resume];
}
#endif
@end
