/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/
#import "CMImageUtility.h"
#import "SWOGLDisplay.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation CMImageUtility
+(float)expectedScaleForImagePath:(NSString *)path{
    NSString *lastPathComponent = [[path lastPathComponent]stringByDeletingPathExtension];
    if ([lastPathComponent hasSuffix:@"@2x"]) {
        return 2.0;
    }else{
        return 1.0;
    }
}
+(CGSize)sizeOfImageForData:(NSData*)data scale:(float)scale{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    CGSize size = [self sizeForImageSource:imageSource forScale:scale];
    if (imageSource) {
        CFRelease(imageSource);
    }

    return size;
}

+(CGSize)sizeForImageSource:(CGImageSourceRef)imageSource forScale:(float)scale{
    if (imageSource == NULL) {
        return CGSizeZero;
    }else{
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache, nil];
        CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
        CGFloat width = 1, height = 1;
        if (imageProperties) {
            NSNumber *widthNumber = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
            NSNumber *heightNumber = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
            width = [widthNumber floatValue] / scale;
            height = [heightNumber floatValue] / scale;
            CFRelease(imageProperties);
        }
        return CGSizeMake(width, height);
    }
}

+(CGSize)sizeOfImageAtPath:(NSString*)path{
    NSString *absolutePath = [self bestPathForResourcePath:path];
    NSURL *imageFileURL = [NSURL fileURLWithPath:absolutePath];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageFileURL, NULL);
    CGSize size = [self sizeForImageSource:imageSource forScale:[self expectedScaleForImagePath:absolutePath]];
    
    if (imageSource) {
        CFRelease(imageSource);
    }

    return size;
}

+(NSString*)bestPathForResourcePath:(NSString*)path{
    CFStringRef fileExtension = (__bridge CFStringRef) [path pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    NSString *res = path;
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)){
        if ([(SWOGLDisplay*)[SWOGLDisplay instance]scale]==2.0) {
            if ([self expectedScaleForImagePath:path]==2.0) {
                res = path;
            }else{
                NSString *_2xPath =[[[path stringByDeletingPathExtension]stringByAppendingString:@"@2x"]stringByAppendingPathExtension:(__bridge NSString*)fileExtension];
                if ([[NSFileManager defaultManager]fileExistsAtPath:_2xPath]) {
                    res = _2xPath;
                }else{
                    res = path;
                }
            }
        }else{
            res = path;
        }
    }else{
        res =  path;
    }
    if (fileUTI) {
        CFRelease(fileUTI);
    }

    return res;
}
@end
