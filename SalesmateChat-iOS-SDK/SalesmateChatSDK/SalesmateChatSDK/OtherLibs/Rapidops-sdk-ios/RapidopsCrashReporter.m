// RapidopsCrashReporter.m
//
 
//
 

#import "RapidopsCommon.h"
#import <mach-o/dyld.h>
#include <execinfo.h>

NSString* const kRapidopsExceptionUserInfoBacktraceKey = @"kRapidopsExceptionUserInfoBacktraceKey";

NSString* const kRapidopsCRKeyBinaryImages      = @"_binary_images";
NSString* const kRapidopsCRKeyOS                = @"_os";
NSString* const kRapidopsCRKeyOSVersion         = @"_os_version";
NSString* const kRapidopsCRKeyDevice            = @"_device";
NSString* const kRapidopsCRKeyArchitecture      = @"_architecture";
NSString* const kRapidopsCRKeyResolution        = @"_resolution";
NSString* const kRapidopsCRKeyAppVersion        = @"_app_version";
NSString* const kRapidopsCRKeyAppBuild          = @"_app_build";
NSString* const kRapidopsCRKeyBuildUUID         = @"_build_uuid";
NSString* const kRapidopsCRKeyLoadAddress       = @"_load_address";
NSString* const kRapidopsCRKeyExecutableName    = @"_executable_name";
NSString* const kRapidopsCRKeyName              = @"_name";
NSString* const kRapidopsCRKeyType              = @"_type";
NSString* const kRapidopsCRKeyError             = @"_error";
NSString* const kRapidopsCRKeyNonfatal          = @"_nonfatal";
NSString* const kRapidopsCRKeyRAMCurrent        = @"_ram_current";
NSString* const kRapidopsCRKeyRAMTotal          = @"_ram_total";
NSString* const kRapidopsCRKeyDiskCurrent       = @"_disk_current";
NSString* const kRapidopsCRKeyDiskTotal         = @"_disk_total";
NSString* const kRapidopsCRKeyBattery           = @"_bat";
NSString* const kRapidopsCRKeyOrientation       = @"_orientation";
NSString* const kRapidopsCRKeyOnline            = @"_online";
NSString* const kRapidopsCRKeyOpenGL            = @"_opengl";
NSString* const kRapidopsCRKeyRoot              = @"_root";
NSString* const kRapidopsCRKeyBackground        = @"_background";
NSString* const kRapidopsCRKeyRun               = @"_run";
NSString* const kRapidopsCRKeyCustom            = @"_custom";
NSString* const kRapidopsCRKeyLogs              = @"_logs";
NSString* const kRapidopsCRKeySignalCode        = @"signal_code";
NSString* const kRapidopsCRKeyImageLoadAddress  = @"la";
NSString* const kRapidopsCRKeyImageBuildUUID    = @"id";


@interface RapidopsCrashReporter ()
@property (nonatomic) NSMutableArray* customCrashLogs;
@property (nonatomic) NSDateFormatter* dateFormatter;
@property (nonatomic) NSString* buildUUID;
@property (nonatomic) NSString* executableName;
@end


@implementation RapidopsCrashReporter

#if TARGET_OS_IOS

+ (instancetype)sharedInstance
{
    if (!RapidopsCommon.sharedInstance.hasStarted)
        return nil;

    static RapidopsCrashReporter *s_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
    return s_sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.crashSegmentation = nil;
        self.customCrashLogs = NSMutableArray.new;
        self.dateFormatter = NSDateFormatter.new;
        self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    }

    return self;
}

- (void)startCrashReporting
{
    if (!self.isEnabledOnInitialConfig)
        return;

    if (!RapidopsConsentManager.sharedInstance.consentForCrashReporting)
        return;

    NSSetUncaughtExceptionHandler(&RapidopsUncaughtExceptionHandler);
    signal(SIGABRT, RapidopsSignalHandler);
    signal(SIGILL, RapidopsSignalHandler);
    signal(SIGSEGV, RapidopsSignalHandler);
    signal(SIGFPE, RapidopsSignalHandler);
    signal(SIGBUS, RapidopsSignalHandler);
    signal(SIGPIPE, RapidopsSignalHandler);
    signal(SIGTRAP, RapidopsSignalHandler);
}


- (void)stopCrashReporting
{
    if (!self.isEnabledOnInitialConfig)
        return;

    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGTRAP, SIG_DFL);

    self.customCrashLogs = nil;
}


- (void)recordException:(NSException *)exception withStackTrace:(NSArray *)stackTrace isFatal:(BOOL)isFatal
{
    if (!RapidopsConsentManager.sharedInstance.consentForCrashReporting)
        return;

    if (stackTrace)
    {
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
        userInfo[kRapidopsExceptionUserInfoBacktraceKey] = stackTrace;
        exception = [NSException exceptionWithName:exception.name reason:exception.reason userInfo:userInfo];
    }

    RapidopsExceptionHandler(exception, isFatal, false);
}

void RapidopsUncaughtExceptionHandler(NSException *exception)
{
    RapidopsExceptionHandler(exception, true, true);
}

void RapidopsExceptionHandler(NSException *exception, bool isFatal, bool isAutoDetect)
{
    NSMutableDictionary* crashReport = NSMutableDictionary.dictionary;

    NSArray* stackTrace = exception.userInfo[kRapidopsExceptionUserInfoBacktraceKey];
    if (!stackTrace)
        stackTrace = exception.callStackSymbols;

    crashReport[kRapidopsCRKeyError] = [stackTrace componentsJoinedByString:@"\n"];
    crashReport[kRapidopsCRKeyBinaryImages] = [RapidopsCrashReporter.sharedInstance binaryImagesForStackTrace:stackTrace];
    crashReport[kRapidopsCRKeyOS] = RapidopsDeviceInfo.osName;
    crashReport[kRapidopsCRKeyOSVersion] = RapidopsDeviceInfo.osVersion;
    crashReport[kRapidopsCRKeyDevice] = RapidopsDeviceInfo.device;
    crashReport[kRapidopsCRKeyArchitecture] = RapidopsDeviceInfo.architecture;
    crashReport[kRapidopsCRKeyResolution] = RapidopsDeviceInfo.resolution;
    crashReport[kRapidopsCRKeyAppVersion] = RapidopsDeviceInfo.appVersion;
    crashReport[kRapidopsCRKeyAppBuild] = RapidopsDeviceInfo.appBuild;
    crashReport[kRapidopsCRKeyBuildUUID] = RapidopsCrashReporter.sharedInstance.buildUUID ?: @"";
    crashReport[kRapidopsCRKeyExecutableName] = RapidopsCrashReporter.sharedInstance.executableName ?: @"";
    crashReport[kRapidopsCRKeyName] = exception.description;
    crashReport[kRapidopsCRKeyType] = exception.name;
    crashReport[kRapidopsCRKeyNonfatal] = @(!isFatal);
    crashReport[kRapidopsCRKeyRAMCurrent] = @((RapidopsDeviceInfo.totalRAM-RapidopsDeviceInfo.freeRAM) / 1048576);
    crashReport[kRapidopsCRKeyRAMTotal] = @(RapidopsDeviceInfo.totalRAM / 1048576);
    crashReport[kRapidopsCRKeyDiskCurrent] = @((RapidopsDeviceInfo.totalDisk-RapidopsDeviceInfo.freeDisk) / 1048576);
    crashReport[kRapidopsCRKeyDiskTotal] = @(RapidopsDeviceInfo.totalDisk / 1048576);
    crashReport[kRapidopsCRKeyBattery] = @(RapidopsDeviceInfo.batteryLevel);
    crashReport[kRapidopsCRKeyOrientation] = RapidopsDeviceInfo.orientation;
    crashReport[kRapidopsCRKeyOnline] = @((RapidopsDeviceInfo.connectionType) ? 1 : 0 );
    crashReport[kRapidopsCRKeyOpenGL] = RapidopsDeviceInfo.OpenGLESversion;
    crashReport[kRapidopsCRKeyRoot] = @(RapidopsDeviceInfo.isJailbroken);
    crashReport[kRapidopsCRKeyBackground] = @(RapidopsDeviceInfo.isInBackground);
    crashReport[kRapidopsCRKeyRun] = @(RapidopsCommon.sharedInstance.timeSinceLaunch);

    NSMutableDictionary* custom = NSMutableDictionary.new;
    if (RapidopsCrashReporter.sharedInstance.crashSegmentation)
        [custom addEntriesFromDictionary:RapidopsCrashReporter.sharedInstance.crashSegmentation];

    NSMutableDictionary* userInfo = exception.userInfo.mutableCopy;
    [userInfo removeObjectForKey:kRapidopsExceptionUserInfoBacktraceKey];
    [custom addEntriesFromDictionary:userInfo];

    if (custom.allKeys.count)
        crashReport[kRapidopsCRKeyCustom] = custom;

    if (RapidopsCrashReporter.sharedInstance.customCrashLogs)
        crashReport[kRapidopsCRKeyLogs] = [RapidopsCrashReporter.sharedInstance.customCrashLogs componentsJoinedByString:@"\n"];

    if (!isAutoDetect)
    {
        [RapidopsConnectionManager.sharedInstance sendCrashReport:[crashReport RPD_JSONify] immediately:NO];
        return;
    }

    [RapidopsConnectionManager.sharedInstance sendCrashReport:[crashReport RPD_JSONify] immediately:YES];

    [RapidopsCrashReporter.sharedInstance stopCrashReporting];
}

void RapidopsSignalHandler(int signalCode)
{
    const NSInteger kRapidopsStackFramesMax = 128;
    void *stack[kRapidopsStackFramesMax];
    NSInteger frameCount = backtrace(stack, kRapidopsStackFramesMax);
    char **lines = backtrace_symbols(stack, (int)frameCount);

    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frameCount];
    for (NSInteger i = 1; i < frameCount; i++)
        [backtrace addObject:[NSString stringWithUTF8String:lines[i]]];

    free(lines);

    NSDictionary *userInfo = @{kRapidopsCRKeySignalCode: @(signalCode), kRapidopsExceptionUserInfoBacktraceKey: backtrace};
    NSString *reason = [NSString stringWithFormat:@"App terminated by SIG%@", [NSString stringWithUTF8String:sys_signame[signalCode]].uppercaseString];
    NSException *e = [NSException exceptionWithName:@"Fatal Signal" reason:reason userInfo:userInfo];

    RapidopsUncaughtExceptionHandler(e);
}

- (void)log:(NSString *)log
{
    if (!RapidopsConsentManager.sharedInstance.consentForCrashReporting)
        return;

    const NSInteger kRapidopsCustomCrashLogLengthLimit = 1000;

    if (log.length > kRapidopsCustomCrashLogLengthLimit)
        log = [log substringToIndex:kRapidopsCustomCrashLogLengthLimit];

    NSString* logWithDateTime = [NSString stringWithFormat:@"<%@> %@",[self.dateFormatter stringFromDate:NSDate.date], log];
    [self.customCrashLogs addObject:logWithDateTime];

    if (self.customCrashLogs.count > self.crashLogLimit)
        [self.customCrashLogs removeObjectAtIndex:0];
}

- (NSDictionary *)binaryImagesForStackTrace:(NSArray *)stackTrace
{
    NSMutableSet* binaryImagesInStack = NSMutableSet.new;
    for (NSString* line in stackTrace)
    {
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+\\s" options:0 error:nil];
        NSString* trimmedLine = [regex stringByReplacingMatchesInString:line options:0 range:(NSRange){0,line.length} withTemplate:@" "];
        NSArray* lineComponents = [trimmedLine componentsSeparatedByString:@" "];
        if (lineComponents.count > 1)
            [binaryImagesInStack addObject:lineComponents[1]];
    }

    NSMutableDictionary* binaryImages = NSMutableDictionary.new;

    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++)
    {
        const char* imageNameChar = _dyld_get_image_name(i);
        if (imageNameChar == NULL)
        {
            Rapidops_LOG(@"Image Name can not be retrieved!");
            continue;
        }

        NSString *imageName = [NSString stringWithUTF8String:imageNameChar].lastPathComponent;

        if (![binaryImagesInStack containsObject:imageName])
        {
            Rapidops_LOG(@"Image Name is not in stack trace, so it is not needed!");
            continue;
        }


        const struct mach_header* imageHeader = _dyld_get_image_header(i);
        if (imageHeader == NULL)
        {
            Rapidops_LOG(@"Image Header can not be retrieved!");
            continue;
        }

        BOOL is64bit = imageHeader->magic == MH_MAGIC_64 || imageHeader->magic == MH_CIGAM_64;
        uintptr_t ptr = (uintptr_t)imageHeader + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
        NSString* imageUUID = nil;

        for (uint32_t j = 0; j < imageHeader->ncmds; j++)
        {
            const struct segment_command_64* segCmd = (struct segment_command_64*)ptr;

            if (segCmd->cmd == LC_UUID)
            {
                const uint8_t* uuid = ((const struct uuid_command*)segCmd)->uuid;
                imageUUID = [NSUUID.alloc initWithUUIDBytes:uuid].UUIDString;
                break;
            }
            ptr += segCmd->cmdsize;
        }

        if (!imageUUID)
        {
            Rapidops_LOG(@"Image UUID can not be retrieved!");
            continue;
        }

        //NOTE: Include app's own build UUID directly in crash report object, as Rapidops Server needs it for fast lookup
        if (imageHeader->filetype == MH_EXECUTE)
        {
            RapidopsCrashReporter.sharedInstance.buildUUID = imageUUID;
            RapidopsCrashReporter.sharedInstance.executableName = imageName;
        }

        NSString *imageLoadAddress = [NSString stringWithFormat:@"0x%llX", (uint64_t)imageHeader];

        binaryImages[imageName] = @{kRapidopsCRKeyImageLoadAddress: imageLoadAddress, kRapidopsCRKeyImageBuildUUID: imageUUID};
    }

    return [NSDictionary dictionaryWithDictionary:binaryImages];
}
#endif
@end
