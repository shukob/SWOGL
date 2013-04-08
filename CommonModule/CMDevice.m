/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import "CMDevice.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "define.h"
static BOOL screenRelatedFeatureInitialized;
static CGFloat widerScreenLength = 0 ;
static BOOL widerScreen;
@implementation CMDevice
static NSString *platform;
+ (NSString *) platform{
    if(!platform){
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        platform = [NSString stringWithUTF8String:machine];
        free(machine);
    }
    return platform;
}

+ (BOOL)platformIsiPod{
    return [[self platform]hasPrefix:@"iPod"];
}

+ (BOOL)platformIsiPhone{
    return  [[self platform]hasPrefix:@"iPhone"];
    
}

//We use integer here for caching result
static NSInteger lowMemoryAvailability = -1;
+(BOOL) lowMemoryAvaliability{
    if (lowMemoryAvailability<0) {
        
        if ([self platformIsiPod]) {
            if ([self platformMajorVersion]<=3) {
                lowMemoryAvailability = YES;
            }else{
                lowMemoryAvailability = NO;
            }
        }else if([self platformIsiPhone]){
            if ([self platformMajorVersion]<=2) {
                lowMemoryAvailability = YES;
            }else{
                lowMemoryAvailability = NO;
            }
        }else{
            lowMemoryAvailability = NO;
        }
    }
    return lowMemoryAvailability;
}

+(void)initializeScreenRelatedFeatures{
    widerScreen = IS_WIDESCREEN;
    widerScreenLength = widerScreen ? 568 : 480;
    screenRelatedFeatureInitialized = YES;
}

+(BOOL)widerScreen{
    if (!screenRelatedFeatureInitialized) {
        [self initializeScreenRelatedFeatures];
    }
    return widerScreen;
}

+(CGFloat)widerScreenLength{
    if (!screenRelatedFeatureInitialized) {
        [self initializeScreenRelatedFeatures];
    }
    return widerScreenLength;
}


+(NSInteger)bestFPS{
    return 30;
    NSString * p = [self platform];
    if ([p hasPrefix:@"iPhone"]) {
        NSString *v = [p substringFromIndex:6];
        NSArray *versions = [v componentsSeparatedByString:@","];
        NSInteger majorVersion = [[versions objectAtIndex:0]integerValue];
        if (majorVersion >= 4) {
            return 30;
        }else{
            return 25;
        }
    }else if([p hasPrefix:@"iPad"]){
        NSString *v = [p substringFromIndex:4];
        NSArray *versions = [v componentsSeparatedByString:@","];
        NSInteger majorVersion = [[versions objectAtIndex:0]integerValue];
        if (majorVersion >= 3) {
            return 30;
        }else{
            return 20;
        }
    }else if([p hasPrefix:@"iPod"]){
        NSString *v = [p substringFromIndex:4];
        NSArray *versions = [v componentsSeparatedByString:@","];
        NSInteger majorVersion = [[versions objectAtIndex:0]integerValue];
        if (majorVersion >= 3) {
            return 30;
        }else{
            return 20;
        }
    }else{
        return 13;
    }
}

+ (NSString *) platformString{
    NSString *platform = [self platform];
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"]) return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    if ([platform isEqualToString:@"iPod1,1"]) return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"]) return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"]) return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"]) return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPad1,1"]) return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"]) return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"]) return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"]) return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"i386"]) return @"Simulator";
    if ([platform isEqualToString:@"x86_64"]) return @"Simulator";
    return platform;
}
static NSInteger platformMajorVersion = -1;
+(NSInteger)platformMajorVersion{
    if(platformMajorVersion<0){
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([^0-9]*)([0-9]*),?([0-9]*)$" options:NSRegularExpressionCaseInsensitive
                                      
                                                                                 error:nil];
        NSArray *matches = [regex matchesInString:[self platform] options:0 range:NSMakeRange(0, [self platform].length)];
        if(matches.count){
            NSString *s = [[self platform] substringWithRange:[[matches objectAtIndex:0]rangeAtIndex:2]];
            platformMajorVersion = [s integerValue];
        }else{
            platformMajorVersion = 0;
        }
        
    }
    return platformMajorVersion;
    
}

@end
