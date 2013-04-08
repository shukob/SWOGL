/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/
#import "SWOGLLayerAnimation.h"
#import "SWOGLInterpolation.h"
#import "SWOGLTexture.h"
@interface SWOGLLayerAnimation()
@end

@implementation SWOGLLayerAnimation
@synthesize animationStartedAt = _animationStartedAt;
-(id)init{
    if ([super init]) {
        self.animationDuration = 0;
        self.animationType = SWOGLLayerAnimationTypeNone;
        self.frameProperties = [NSMutableArray array];
    }
    return self;
}

+(SWOGLLayerAnimation*)animationWithType:(SWOGLLayerAnimationType)animationType{
    SWOGLLayerAnimation *animation = [[SWOGLLayerAnimation alloc]init];
    animation.animationType = animationType;
    return animation;
}

-(void)startAnimation{
    if(!self.animating){
        self.animationStartedAt = [NSDate date];
    }
}

-(void)stopAnimation{
    self.animationStartedAt = nil;
}

-(NSInteger)totalFrames{
    switch (self.animationType) {
        case SWOGLLayerAnimationTypeNone:
            return 0;
        case SWOGLLayerAnimationTypeAlphaTransition:
        case SWOGLLayerAnimationTypeConsecutiveImages:
        case SWOGLLayerAnimationTypeRectMovement:
            return self.frameProperties.count;
        default:
            return 0;
    }
}

-(NSInteger)currentAnimationFrame{
    return [self currentFloatingPointAnimationFrame];
}

-(float)currentFloatingPointAnimationFrame{
    if (self.animationDuration <= 0) {
        return SWOGLAnimatableInvalidFrame;
    }
    NSInteger totalFrames = [self totalFrames];;
    if (!totalFrames) {
        return SWOGLAnimatableInvalidFrame;
    }else{
        NSTimeInterval interval = -[self.animationStartedAt timeIntervalSinceNow];
        NSTimeInterval oneFrame = self.animationDuration / totalFrames;
        float frame =  SWOGLAnimatableInvalidFrame;
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

-(id)currentProperty{
    NSInteger animationFrame = [self currentAnimationFrame];
    if (animationFrame == SWOGLAnimatableInvalidFrame) {
        [self stopAnimation];
        return nil;
    }else{
        return [self.frameProperties objectAtIndex:animationFrame];
    }
}

-(id)currentInterpolatedProperty{
    NSInteger animationFrame = [self currentAnimationFrame];
    if (animationFrame == SWOGLAnimatableInvalidFrame) {
        [self stopAnimation];
        return nil;
    }
    switch (self.animationType) {
        case SWOGLLayerAnimationTypeNone:
        case SWOGLLayerAnimationTypeConsecutiveImages:
            return [self currentProperty];
        case SWOGLLayerAnimationTypeAlphaTransition:
        case SWOGLLayerAnimationTypeRectMovement:{
            float floatingPointFrame = [self currentFloatingPointAnimationFrame];
            if (floatingPointFrame == SWOGLAnimatableInvalidFrame) {
                [self stopAnimation];
                return nil;
            }else{
                NSInteger integerFrame = floatingPointFrame;
                float fraction = floatingPointFrame - integerFrame;
                if (integerFrame==self.totalFrames - 1) {
                    return [self currentProperty];
                }else{
                    NSString *type = nil;
                    if (self.animationType==SWOGLLayerAnimationTypeAlphaTransition) {
                        type = @"NSNumber";
                    }else{
                        type = @"CGPoint";
                    }
                    id previousProperty = [self.frameProperties objectAtIndex:integerFrame];
                    id nextProperety = [self.frameProperties objectAtIndex:integerFrame+1];
                    id res = [SWOGLInterpolation interpolatedValueBetween:previousProperty andAnother:nextProperety withFraction:fraction forType:type];
                    return res;
                }

            }
        }
        default:
            return nil;
    }
}

-(void)setAnimationTexturesUsingPathList:(NSArray*)pathList{
    [self.frameProperties removeAllObjects];
    for (NSString *path in pathList){
        SWOGLTexture * texture = [SWOGLTexture textureWithImageFilePath:path];
        [self.frameProperties addObject:texture];
    }
}

-(id)lastProperty{
    return [self.frameProperties lastObject];
}


@end
