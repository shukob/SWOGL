/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import "CMApplicationDirectory.h"

@interface CMApplicationDirectory(){
    NSMutableDictionary *pathDictionary;
}

@end

@implementation CMApplicationDirectory

-(id)init{
    
    if([super init]){
        pathDictionary = [NSMutableDictionary new];
    }
    return self;
}

-(void)dealloc{
    pathDictionary = nil;
    #if CM_SHOULD_DEALLOC
[super dealloc];
#endif
}

-(NSString*)documentsDirectoryPath{
    id res = nil;
    if ((res = [pathDictionary objectForKey:@"documents"])) {
        return res;
    }else{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
        if ([paths count]>0) {
            NSString *documentsDirectory = [paths objectAtIndex:0]; 
            [pathDictionary setObject:documentsDirectory forKey:@"documents"];
            return documentsDirectory;
        }else{
            return res;
        }
    }
}
-(NSString*)temporaryDirectoryPath{
    id res = nil;
    if((res = [pathDictionary objectForKey:@"temporary"])){
        return res;
    }else{
        NSString *temporaryDirectory = NSTemporaryDirectory();
        [pathDictionary setObject:temporaryDirectory forKey:@"temporary"];
        return temporaryDirectory;
    }
}

-(NSString*)cacheDirectoryPath{
    id res = nil;
    if((res = [pathDictionary objectForKey:@"cache"])){
        return res;
        
    }else{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES); 
        if ([paths count]>0) {
            NSString *res = [paths objectAtIndex:0]; 
            [pathDictionary setObject:res forKey:@"cache"];
        }

        return res;
    }
}

-(NSString*)mainBundleDirectoryPath{
    id res = nil;
    if ((res = [pathDictionary objectForKey:@"mainBundle"])) {
        return res;
    }else{
        NSString *mainBundleDirectory = [[NSBundle mainBundle]resourcePath];
        [pathDictionary setObject:mainBundleDirectory forKey:@"mainBundle"];
        return mainBundleDirectory;
    }
}

-(NSString*)absolutePath:(NSString*)path inDirectoryType:(CMApplicationDirectoryType)type{
    switch (type) {
        case CMApplicationDirectoryCacheType:
            return [[self cacheDirectoryPath] stringByAppendingPathComponent:path];
        case CMApplicationDirectoryDocumentsType:
            return [[self documentsDirectoryPath] stringByAppendingPathComponent:path];
        case CMApplicationDirectoryTemporaryType:
            return [[self temporaryDirectoryPath] stringByAppendingPathComponent:path];
        case CMApplicationDirectoryMainBundleType:
            return [[self mainBundleDirectoryPath] stringByAppendingPathComponent:path];
        default:
            return nil;
    }
}

-(id)contentsOfFileInPath:(NSString*)path inDirectoryType:(CMApplicationDirectoryType)type shouldCreate:(BOOL)create  withDefaultContent:(id)content;{
    if (path && [path class] != [NSNull class]) {
        return [self contentsOfFileInPath:[self absolutePath:path inDirectoryType:type] shouldCreate:create withDefaultContent:content];
    }else{
        return nil;
    }
}

-(id)contentsOfFileInPath:(NSString*)path shouldCreate:(BOOL)create withDefaultContent:(id)content;{
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        return [NSData dataWithContentsOfFile:path];
    }else if(create){
        
        NSData *contentData = nil;
        if (!content) {
            content = @"";
        }
        
        contentData = [NSKeyedArchiver archivedDataWithRootObject:content];
        
        BOOL res = [[NSFileManager defaultManager]createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        if(res){
            [[NSFileManager defaultManager]createFileAtPath:path contents:contentData attributes:nil];
        }
        if(res){
            return contentData;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

-(BOOL)writeContents:(id)contents toPath:(NSString*)path inDirectoryType:(CMApplicationDirectoryType)type shouldOverwrite:(BOOL)overwrite{
    if(contents){
        NSString *absolutePath = [self absolutePath:path inDirectoryType:type];
        if (overwrite) {
            if([[NSFileManager defaultManager]fileExistsAtPath:absolutePath]){
                NSError *error;
                [[NSFileManager defaultManager]removeItemAtPath:absolutePath error:&error];
                if (error) {
                    return NO;
                }
            }
        }
        BOOL res = YES;
        if(![[NSFileManager defaultManager]fileExistsAtPath:[absolutePath stringByDeletingLastPathComponent]]){
            res = [[NSFileManager defaultManager] createDirectoryAtPath:[absolutePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if(res){
            res = [[NSFileManager defaultManager]createFileAtPath:absolutePath contents:contents attributes:nil];
        }
        return res;
    }else{
        return NO;
    }
}

-(NSURL*)fileURLForPath:(NSString*)path inDirectoryType:(CMApplicationDirectoryType)type{
    return [NSURL fileURLWithPath:[self absolutePath:path inDirectoryType:type]];
}

-(BOOL)createDirectoryStructurForURL:(NSURL*)url{
    if ([url isFileURL]) {
        NSString *path = [[url absoluteString]substringFromIndex:[@"file://localhost" length]];
        
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            return YES;
        }else{
            return [[NSFileManager defaultManager]createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }else{
        return NO;
    }
}

-(BOOL)writeContents:(NSData*)contents toURL:(NSURL*)url shouldOverwrite:(BOOL)overwrite{
    if ([self createDirectoryStructurForURL:url]) {
        if ([url checkResourceIsReachableAndReturnError:nil] && !overwrite) {
            return NO;
        }
        return [contents writeToURL:url atomically:YES];
    }else{
        return NO;
    }
}


@end
