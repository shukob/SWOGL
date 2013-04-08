/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import "SWOGLOrientationAwareLayer.h"
#import "SWOGLDisplay.h"
@interface SWOGLOrientationAwareLayer()
@property(nonatomic, strong)  NSMutableDictionary *textures;


@end

@implementation SWOGLOrientationAwareLayer

-(id)init{
    if ([super init]) {
        self.textures = [NSMutableDictionary dictionary];
    }
    return self;
}
-(SWOGLTexture*)texture{
    UIInterfaceOrientation orientation = [[SWOGLDisplay instance]interfaceOrientation];
    SWOGLTexture *texture = [self.textures objectForKey:[self keyForOrientation:orientation]];
    self.contentSize = texture.size;
    return texture;
}

-(BOOL)loadTextureAtPath:(NSString *)path forOrientation:(UIInterfaceOrientation)orientation{
    if(path){
        SWOGLTexture *texture = [SWOGLTexture textureWithImageFilePath:path];
        if(texture){
            [self.textures setObject:texture forKey:[self keyForOrientation:orientation]];
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

-(NSString*)keyForOrientation:(UIInterfaceOrientation)orientation{
    return [NSString stringWithFormat:@"%d", orientation];
}

@end
