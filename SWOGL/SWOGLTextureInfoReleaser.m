/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import "SWOGLTextureInfoReleaser.h"
#import "SWOGLBaseEffect.h"

@interface SWOGLTextureInfoReleaser()
@property (atomic, strong) NSMutableArray *targets;
@property (atomic, assign) BOOL releasing;
@end

@implementation SWOGLTextureInfoReleaser

-(id)init{
    if ([super init]) {
        self.targets = [NSMutableArray array];
    }
    return self;
}

+(void)releaseTextureInfo:(GLKTextureInfo *)textureInfo{
    if (textureInfo) {
        [[SWOGLTextureInfoReleaser instance]pushReleaseTarget:textureInfo];
    }

}

+(void)deleteTexture:(id)dict{
    @synchronized(self){

        GLKTextureInfo *textureInfo = [dict objectForKey:@"textureInfo"];
        GLuint name = textureInfo.name;
        glDeleteTextures(1, &name);
    }
}

-(void)pushReleaseTarget:(GLKTextureInfo *)textureInfo{
    while (self.releasing) {
        [NSThread sleepForTimeInterval:.001];
    }
    
    [self.targets addObject:textureInfo];
}

-(void)releaseTextureInfo{
    _releasing = YES;
    [[SWOGLBaseEffect sharedEffect]prepareToDraw];
    for (GLKTextureInfo *info in self.targets){
        GLuint name = info.name;
        glDeleteTextures(1, &name);
    }
    [self.targets removeAllObjects];
    _releasing = NO;
}

CMBasicSingletonPerformanceHack

@end
