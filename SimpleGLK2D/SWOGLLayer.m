/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/
#import "SWOGLLayer.h"
#import "CMApplicationDirectory.h"
#import "SWOGLDisplay.h"
#import "SWOGLUtility.h"
#import "SWOGLLayerAnimation.h"
#import "SWOGLBaseEffect.h"
@interface SWOGLLayer()

@end

@implementation SWOGLLayer

-(id)init{
    if ([super init]) {
        self.effect = [SWOGLBaseEffect sharedEffect];
        self.userInteractionEnabled = YES;
        self.animations = [NSMutableArray array];
        self.alpha = 1;
    }
    return self;
}

- (GLKMatrix4) modelMatrix {
    
    GLKMatrix4 mat = GLKMatrix4MakeTranslation(0, 0, self.depth);
    mat = GLKMatrix4Translate(mat, self.position.x, -self.position.y, 0);
    if (self.offsetProvider) {
        mat = GLKMatrix4Translate(mat, [self.offsetProvider positionOffset].x, -[self.offsetProvider positionOffset].y,0);
    }
    if (self.animations.count) {
        for (SWOGLLayerAnimation *animation in self.animations){
            if (animation.animating) {
                switch (animation.animationType) {
                    case SWOGLLayerAnimationTypeRectMovement:{
                        id value = [animation currentInterpolatedProperty];
                        if (value) {
                            CGPoint point = [value CGPointValue];
                            GLKVector2 offset = GLKVector2Make(point.x, point.y);
                            mat = GLKMatrix4Translate(mat, offset.x, -offset.y, 0);
                        }
                    }
                        
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }
    return mat;
    
    
}

-(void)renderWithProjectionMatrix:(GLKMatrix4)projectionMatrix{
    if (self.hidden) {
        return;
    }

    self.effect.transform.projectionMatrix = projectionMatrix;
    [self render];
}

-(void)translateModelViewMatrixWithOffset:(GLKVector2)offset{
    self.effect.transform.modelviewMatrix = GLKMatrix4Translate(self.effect.transform.modelviewMatrix, offset.x, -offset.y, 0);
}

-(void)prepareForRenderingUsingTexture:(SWOGLTexture*)texture{
    if (!texture.textureInfo) {
        return;
    }
    self.effect.texture2d0.enabled = YES;
    self.effect.texture2d0.envMode = GLKTextureEnvModeModulate;
    self.effect.texture2d0.target = GLKTextureTarget2D;
    self.effect.constantColor = GLKVector4Make(1, 1, 1, self.alpha);
    self.effect.transform.modelviewMatrix = self.modelMatrix;

    
    if (self.animations.count) {
        for (SWOGLLayerAnimation *animation in self.animations){
            if (animation.animating) {
                switch (animation.animationType) {
                    case SWOGLLayerAnimationTypeAlphaTransition:{
                        id value = [animation currentInterpolatedProperty];
                        if (value) {
                            self.effect.constantColor = GLKVector4Make(1, 1, 1, self.alpha * [value floatValue]);
                        }
                        
                    }
                        break;
                    case SWOGLLayerAnimationTypeConsecutiveImages:{
                        id value = [animation currentProperty];
                        if (value) {
                            texture = [animation currentProperty];
                        }
                        
                    }
                        break;
                    case SWOGLLayerAnimationTypeRectMovement:{
                      //TODO
                    }
                        
                        break;
                        
                    default:
                        break;
                }
            }else{
                switch (animation.animationType) {
                    case SWOGLLayerAnimationTypeAlphaTransition:{
                        id value = [animation lastProperty];
                        if (value) {
                            self.alpha*=[value floatValue];
                        }
                        
                    }
                        break;
                    case SWOGLLayerAnimationTypeConsecutiveImages:{
                        id value = [animation lastProperty];
                        if (value) {
                            self.texture = [animation lastProperty];
                        }
                        
                    }
                        break;
                    case SWOGLLayerAnimationTypeRectMovement:{
                        id value = [animation lastProperty];
                        if (value) {
                            CGPoint point = [value CGPointValue];
                            GLKVector2 offset = GLKVector2Make(point.x, point.y);
                            self.position = GLKVector2Add(self.position, offset);
                            [self translateModelViewMatrixWithOffset:offset];
                        }
                    }
                        
                        break;
                        
                    default:
                        break;
                }
                
            }
        }
    }
    self.effect.texture2d0.name = texture.textureInfo.name;
    [self.effect prepareToDraw];
}

- (void)render {
    if (self.hidden) {
        return;
    }
    if(!self.solidColor){
        SWOGLTexture *texture = self.texture;
        if (!texture.textureInfo) {
            return;
        }
        [self prepareForRenderingUsingTexture:texture];
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);

        TexturedQuad quad = texture.quad;
        [self customizeQuadBeforeRendering:&quad];
        long offset = (long)&quad;
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (void *) (offset + offsetof(TexturedVertex, geometryVertex)));
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (void *) (offset + offsetof(TexturedVertex, textureVertex)));
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glDisableVertexAttribArray(GLKVertexAttribPosition);
        glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    }else{
        self.effect.texture2d0.enabled  = NO;
        self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
        self.effect.transform.modelviewMatrix = self.modelMatrix;
        self.effect.constantColor = self.fillColor;
        if (self.animations.count) {
            for (SWOGLLayerAnimation *animation in self.animations){
                if (animation.animating) {
                    switch (animation.animationType) {
                        case SWOGLLayerAnimationTypeAlphaTransition:{
                            id value = [animation currentInterpolatedProperty];
                            if (value) {
                                GLKVector4 color = self.effect.constantColor;
                                color.a *= [value floatValue];
                                self.effect.constantColor=color;
                            }
                        }
                            break;
                        case SWOGLLayerAnimationTypeRectMovement:{
                          //TODO
                        }
                            break;
                            
                        default:
                            break;
                    }
                }else{
                    switch (animation.animationType) {
                        case SWOGLLayerAnimationTypeAlphaTransition:{
                            id value = [animation lastProperty];
                            if (value) {
                                self.fillColor = GLKVector4Make(self.fillColor.r, self.fillColor.g, self.fillColor.b, self.fillColor.a*[value floatValue]);
                            }
                        }
                            break;
                        case SWOGLLayerAnimationTypeRectMovement:{
                            id value = [animation lastProperty];
                            if (value) {
                                CGPoint point = [value CGPointValue];
                                GLKVector2 offset = GLKVector2Make(point.x, point.y);
                                self.position = GLKVector2Add(self.position, offset);
                                [self translateModelViewMatrixWithOffset:offset];
                            }
                        }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }
        
        [self.effect prepareToDraw];
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        float vertices[8];
        [SWOGLUtility setRect:CGRectMake(0, 0, self.contentSize.width, self.contentSize.height) toVertices:vertices];
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        glDisableVertexAttribArray(GLKVertexAttribPosition);
        
    }
    
}

-(BOOL)loadTextureAtPath:(NSString *)path{
    self.texture = [SWOGLTexture textureWithImageFilePath:path];
    if (self.texture) {
        self.contentSize = self.texture.size;
        return YES;
    }else{
        return NO;
    }
}


-(float)value{
    return self.depth;
}

-(CGRect)frame{
    GLKMatrix4 mat = self.modelMatrix;
    float x = mat.m30;
    float y = mat.m31;
    return  CGRectMake(x, -y, self.contentSize.width, self.contentSize.height);
}

-(BOOL)containsPoint:(CGPoint)point{
    return CGRectContainsPoint(self.frame, point);
}

-(void)reactToEvent:(UIEvent *)event atPoint:(CGPoint)point{
    if (self.animating) {
    }else{
        [self startAnimation];
    }
}

-(void)startAnimation{
    if(!self.animating){
        self.animationStartedAt = [NSDate date];
    }
    for (SWOGLLayerAnimation *animation in self.animations){
        [animation startAnimation];
    }
}

-(void)stopAnimation{
    self.animationStartedAt = nil;
    for (SWOGLLayerAnimation *animation in self.animations){
        [animation stopAnimation];
    }
    
}
-(NSInteger)currentAnimationFrame{
    if (self.animationDuration <= 0) {
        return SWOGLAnimatableInvalidFrame;
    }
    NSInteger totalFrames = [self totalFrames];;
    if (!totalFrames) {
        return SWOGLAnimatableInvalidFrame;
    }else{
        NSTimeInterval interval = -[self.animationStartedAt timeIntervalSinceNow];
        NSTimeInterval oneFrame = self.animationDuration / totalFrames;
        NSInteger frame =  SWOGLAnimatableInvalidFrame;
        if(self.repeatAnimation){
            interval = interval - ((int)(interval / self.animationDuration) * self.animationDuration);
        }
        frame = interval / oneFrame;
        if (frame < totalFrames) {
            return frame;
        }else{
            return SWOGLAnimatableInvalidFrame;
        }
    }
}

-(BOOL)animating{
    return self.animationStartedAt!=nil;
}

-(float)depth{
    float res = _depth;
    if (self.offsetProvider) {
        res += self.offsetProvider.depthOffset;
    }
    return res;
}

-(void)unloadTexture{
    [_texture releaseTextureInfo];
    _texture = nil;
}

-(BOOL)reactsToEvent:(UIEvent *)event atPoint:(CGPoint)point{
    if(self.userInteractionEnabled){
        return [self containsPoint:point];
    }else{
        return NO;
    }
}

-(void)setTexture:(SWOGLTexture *)texture{
    [_texture releaseTextureInfo];
    _texture = texture;
    if (texture) {
        self.contentSize = self.texture.size;
    }
}

-(void)addAnimation:(SWOGLLayerAnimation *)animation{
    [self.animations addObject:animation];
}

-(void)customizeQuadBeforeRendering:(TexturedQuad *)quadPtr{
    
}

@end
