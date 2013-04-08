/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/
#import "SWOGLTexture.h"
#import "SWOGLDisplay.h"
#import "CMApplicationDirectory.h"
#import "SWOGLTextureInfoReleaser.h"
#import "CMImageUtility.h"
#import "define.h"
@interface SWOGLTexture()
@property (nonatomic, assign) BOOL textureReloadingRequired;
@end

@implementation SWOGLTexture
@synthesize textureInfo = _textureInfo, quad = _quad;

-(id)init{
    if ([super init]) {
        self.scale = 1.0;
    }
    return self;
}

-(BOOL)loadTextureAtPath:(NSString*)path{
    if(path){
        [self clear];
        NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES],
                                  GLKTextureLoaderOriginBottomLeft,
                                  nil];
        BOOL _2x = NO;
        if ([(SWOGLDisplay*)[SWOGLDisplay instance]scale]==2.0) {
            if ([[[path lastPathComponent]stringByDeletingPathExtension] hasSuffix:@"@2x"]){
                _2x = YES;
            }else{
                NSString *extention = [path pathExtension];
                NSString *path2x = [[[path stringByDeletingPathExtension]stringByAppendingString:@"@2x"] stringByAppendingPathExtension:extention];
                if([[NSFileManager defaultManager]fileExistsAtPath:path2x]){
                    path = path2x;
                    _2x = YES;
                }
            }
        }
        NSURL *url = [NSURL fileURLWithPath:path];
        if (_2x){
            self.scale = 2.0;
        }else{
            self.scale = 1.0;
        }
        NSError *error;

        _textureInfo = [GLKTextureLoader textureWithContentsOfURL:url options:options error:&error];
        
        if (_textureInfo == nil) {
            NSLog(@"Error loading file: %@", [error localizedDescription]);
            NSLog(@"Target URL: %@", url);
            return NO;
        }else{
            [self setupGeometry];
            return YES;
            
        }
    }else{
        return NO;
    }
    
}

-(BOOL)loadTextureWithImage:(UIImage*)image scale:(float)scale{
    if(image) {
        [self clear];
        self.scale = scale;
        NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES],
                                  GLKTextureLoaderOriginBottomLeft,
                                  nil];
        NSError *error;
        _textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:&error];
        if (_textureInfo == nil) {
            NSLog(@"Error loading file: %@", [error localizedDescription]);
            return NO;
        }else{
            [self setupGeometry];
            return YES;
        }
    }else{
        return NO;
    }
}

-(BOOL)loadTextureWithData:(NSData*)data scale:(float)scale{
    if (data) {
        [self clear];
        self.scale = scale;
        NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES],
                                  GLKTextureLoaderOriginBottomLeft,
                                  nil];
        NSError *error;
        _textureInfo = [GLKTextureLoader textureWithContentsOfData:data options:options error:&error];
        if (_textureInfo == nil) {
            NSLog(@"Error loading file: %@", [error localizedDescription]);
            return NO;
        }else{
            [self setupGeometry];
            return YES;
        }
        
    }else{
        return NO;
    }
}

-(void)clear{
    [self releaseTextureInfo];
}

-(void)releaseTextureInfoImpl{
    if(_textureInfo){
        [SWOGLTextureInfoReleaser releaseTextureInfo:_textureInfo];
        _textureInfo = nil;
    }
}

-(void)releaseTextureInfo{
    [self performSelectorOnMainThread:@selector(releaseTextureInfoImpl) withObject:self waitUntilDone:YES];
}

-(GLKTextureInfo*)textureInfo{
    if (self.textureReloadingRequired || !_textureInfo) {
        [self releaseTextureInfo];
        self.textureReloadingRequired = NO;
        if (self.path) {
            [self loadTextureAtPath:self.path];
        }else if(self.image){
            [self loadTextureWithImage:self.image scale:self.scale];
        }else if(self.data){
            [self loadTextureWithData:self.data scale:self.scale];
        }

    }
    return _textureInfo;
}

-(void)setupGeometry{
    _size = CGSizeMake(self.textureInfo.width/self.scale, self.textureInfo.height/self.scale);
    TexturedQuad newQuad;
    CGSize displaySize = [[SWOGLDisplay instance]size];
    newQuad.bl.geometryVertex = CGPointMake(0, displaySize.height - self.size.height);
    newQuad.br.geometryVertex = CGPointMake(self.size.width, displaySize.height - self.size.height);
    newQuad.tl.geometryVertex = CGPointMake(0, displaySize.height);
    newQuad.tr.geometryVertex = CGPointMake(self.size.width, displaySize.height);
    
    newQuad.bl.textureVertex = CGPointMake(0, 0);
    newQuad.br.textureVertex = CGPointMake(1, 0);
    newQuad.tl.textureVertex = CGPointMake(0, 1);
    newQuad.tr.textureVertex = CGPointMake(1, 1);
    _quad = newQuad;
}

+(UIImage*)createTextImage:(NSString*)text size:(CGSize)size font:(UIFont*)font color:(GLKVector4)color options:(NSDictionary*)options{
    float scale = 1.0;
    if ((scale = [(SWOGLDisplay*)[SWOGLDisplay instance]scale])!=1.0) {
        UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    }else{
        UIGraphicsBeginImageContext(size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, UIRGBColor(color.r, color.g, color.b, color.a).CGColor);
    [text drawInRect:CGRectMake(0, 0, size.width, size.height) withFont:font];
    UIImage* res = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return  res;
}

+(SWOGLTexture*)textureWithImage:(UIImage*)image scale:(float)scale{
    @autoreleasepool {
    SWOGLTexture *texture = [[SWOGLTexture alloc]init];
    texture.image = image;
    texture.scale = scale;
//    [texture loadTextureWithImage:image scale:scale];
    return texture;
    }
}

+(SWOGLTexture*)textureWithImageFilePath:(NSString*)path{
    @autoreleasepool {
    SWOGLTexture *texture = [[SWOGLTexture alloc]init];
    texture.path = path;
    return texture;
    }
}

+(SWOGLTexture*)textureWithData:(NSData*)data scale:(float)scale{
    @autoreleasepool {
    SWOGLTexture *texture = [[SWOGLTexture alloc]init];
    texture.data = data;
    texture.scale = scale;
//    [texture loadTextureWithData:data scale:scale];
    return texture;
    }
}

+(SWOGLTexture*)textureWithText:(NSString *)text size:(CGSize)size font:(UIFont *)font color:(GLKVector4)color options:(NSDictionary *)options{
    SWOGLTexture *texture = [[SWOGLTexture alloc]init];
    UIImage *textImage = [SWOGLTexture createTextImage:text size:size font:font color:color options:options];
    texture.image = textImage;
    texture.scale = [(SWOGLDisplay*)[SWOGLDisplay instance]scale];
//    [texture loadTextureWithImage:textImage scale:[(SWOGLDisplay*)[SWOGLDisplay instance]scale]];
    return texture;
}

-(long)quadPtr{
    return (long)&_quad;
}

-(TexturedQuad)quad{
    [self setupGeometry];
    return _quad;
}

void SWOGLTextureTranslateGeometry(TexturedQuad *quad, GLKVector2 offset){
    quad->bl.geometryVertex.x += offset.x;
    quad->br.geometryVertex.x += offset.x;
    quad->tl.geometryVertex.x += offset.x;
    quad->tr.geometryVertex.x += offset.x;
    
    quad->bl.geometryVertex.y -= offset.y;
    quad->br.geometryVertex.y -= offset.y;
    quad->tl.geometryVertex.y -= offset.y;
    quad->tr.geometryVertex.y -= offset.y;
}

void SWOGLTextureScaleGeometry(TexturedQuad *quad, GLKVector2 scale){
    quad->br.geometryVertex.x = quad->bl.geometryVertex.x + (quad->br.geometryVertex.x - quad->bl.geometryVertex.x)*scale.x;
    quad->tr.geometryVertex.x =  quad->tl.geometryVertex.x + (quad->tr.geometryVertex.x - quad->tl.geometryVertex.x)*scale.x;
    
    quad->tr.geometryVertex.y = quad->br.geometryVertex.y + (quad->tr.geometryVertex.y - quad->br.geometryVertex.y)*scale.y;
    quad->tl.geometryVertex.y =  quad->bl.geometryVertex.y + (quad->tl.geometryVertex.y - quad->bl.geometryVertex.y)*scale.y;
}


-(CGSize)size{
    if (_textureInfo) {
        return CGSizeMake(self.textureInfo.width/self.scale, self.textureInfo.height/self.scale);
    }else if(self.path){
        return [CMImageUtility sizeOfImageAtPath:self.path];
    }else if(self.image){
        return self.image.size;
    }else if(self.data){
        return [CMImageUtility sizeOfImageForData:self.data scale:self.scale];
    }else{
        return CGSizeZero;
    }
}


-(void)dealloc{
    [self releaseTextureInfo];
}

/*rect is relative to this texture, i.e. left top is (0, 0).*/
-(TexturedQuad)quadForRect:(CGRect)rect{
    TexturedQuad newQuad;
    CGSize displaySize = [[SWOGLDisplay instance]size];
    newQuad.bl.geometryVertex = CGPointMake(rect.origin.x, -rect.origin.y + displaySize.height - rect.size.height);
    newQuad.br.geometryVertex = CGPointMake(rect.origin.x + rect.size.width, -rect.origin.y + displaySize.height - rect.size.height);
    newQuad.tl.geometryVertex = CGPointMake(rect.origin.x, -rect.origin.y + displaySize.height);
    newQuad.tr.geometryVertex = CGPointMake(rect.origin.x + rect.size.width, -rect.origin.y + displaySize.height);
    
    CGSize originalSize = self.size;
    float bottomY =1 - (rect.origin.y + rect.size.height)/originalSize.height;
    float topY = 1 - rect.origin.y/originalSize.height;
    float leftX = rect.origin.x / originalSize.width;
    float rightX = (rect.origin.x + rect.size.width)/originalSize.width;
    newQuad.bl.textureVertex = CGPointMake(leftX, bottomY);
    newQuad.br.textureVertex = CGPointMake(rightX, bottomY);
    newQuad.tl.textureVertex = CGPointMake(leftX, topY);
    newQuad.tr.textureVertex = CGPointMake(rightX, topY);
    return newQuad;
}


void SWOGLTextureQuadLog(TexturedQuad* quad){
    NSLog(@"TextureQuad: Geometry:{bl:(%f, %f) br:(%f, %f) tl:(%f, %f) tr:(%f, %f)} Texture{bl:(%f, %f) br:(%f, %f) tl:(%f, %f) tr:(%f, %f)}",
          quad->bl.geometryVertex.x, quad->bl.geometryVertex.y,
          quad->br.geometryVertex.x, quad->br.geometryVertex.y,
          quad->tl.geometryVertex.x, quad->tl.geometryVertex.y,
          quad->tr.geometryVertex.x, quad->tr.geometryVertex.y,
          quad->bl.textureVertex.x, quad->bl.textureVertex.y,
          quad->br.textureVertex.x, quad->br.textureVertex.y,
          quad->tl.textureVertex.x, quad->tl.textureVertex.y,
          quad->tr.textureVertex.x, quad->tr.textureVertex.y);
}
-(void)setPath:(NSString *)path{
    if(path != _path){
        _path = path;
        _data = nil;
        _image = nil;
        self.textureReloadingRequired = YES;
    }
}

-(void)setImage:(UIImage *)image{
    if (image != _image) {
        _image = image;
        _path = nil;
        _data = nil;
        self.textureReloadingRequired = YES;
    }
}

-(void)setData:(NSData *)data{
    if (data != _data) {
        _data = data;
        _path = nil;
        _image = nil;
        self.textureReloadingRequired = YES;
    }
}

@end
