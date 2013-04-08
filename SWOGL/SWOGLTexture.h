/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef struct {
    CGPoint geometryVertex;
    CGPoint textureVertex;
    
} TexturedVertex;

typedef struct {
    TexturedVertex bl;
    TexturedVertex br;
    TexturedVertex tl;
    TexturedVertex tr;
} TexturedQuad;

void SWOGLTextureQuadLog(TexturedQuad* quad);

void SWOGLTextureTranslateGeometry(TexturedQuad *quad, GLKVector2 offset);
void SWOGLTextureScaleGeometry(TexturedQuad *quad, GLKVector2 scale);

@interface SWOGLTexture : NSObject
+(SWOGLTexture*)textureWithImageFilePath:(NSString*)path;
+(SWOGLTexture*)textureWithText:(NSString *)text size:(CGSize)size font:(UIFont*)font color:(GLKVector4)color options:(NSDictionary*)options;
+(SWOGLTexture*)textureWithData:(NSData*)data scale:(float)scale;
+(SWOGLTexture*)textureWithImage:(UIImage*)image scale:(float)scale;
-(void)releaseTextureInfo;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, readonly) TexturedQuad quad;
@property (nonatomic, readonly) GLKTextureInfo *textureInfo;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, readonly) long quadPtr;
@property (nonatomic, assign) float scale;
-(TexturedQuad)quadForRect:(CGRect)rect;
@end
