/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/
#import "SWOGLLayerSet.h"
#import "SWOGLLayer.h"
@interface SWOGLLayerSet()
@property (nonatomic, strong) NSMutableArray* layerHierachy;
@property (nonatomic, assign) BOOL layerHierachyStored;
@end
@implementation SWOGLLayerSet

@synthesize value = _value, frame = _frame, depth = _depth, position = _position, contentSize = _contentSize, hidden = _hidden, childlayerQueue = _childlayerQueue, layers = _layers, offsetProvider = _offsetProvider, repeatAnimation = _repeatAnimation, animating = _animating, animationDuration = _animationDuration, userInteractionEnabled = _userInteractionEnabled, animationStartedAt = _animationStartedAt, animations = _animations, alpha = _alpha;

-(id)init{
    if ([super init]) {
        self.childlayerQueue = [[CMPriorityQueue alloc]init];
        _layers = [NSMutableArray array];
        self.userInteractionEnabled = YES;
        self.animations = [NSMutableArray array];
        self.layerHierachy = [NSMutableArray array];
    }
    return self;
}

-(void)renderWithProjectionMatrix:(GLKMatrix4)projectionMatrix{
    if (self.hidden) {
        return;
    }
    if (self.layerHierachyStored) {
        for (id<SWOGLLayerProtocol> renderable in self.layerHierachy){
            if ([renderable hidden]) {
                continue;
            }
            [renderable renderWithProjectionMatrix:projectionMatrix];
        }
    }else{
        for (id<SWOGLLayerProtocol> renderable in [self.childlayerQueue allObjects]){
            if ([renderable hidden]) {
                continue;
            }
            [renderable renderWithProjectionMatrix:projectionMatrix];
        }
    }
}

-(void)render{
    if(self.hidden){
        return;
    }
    [self.childlayerQueue.allObjects makeObjectsPerformSelector:@selector(render)];
}

-(void)addLayer:(id<SWOGLRenderable, SWOGLOffsetProvidable>)layer{
    [self.layers addObject:layer];
    layer.offsetProvider = self;
    [self.childlayerQueue addObject:(id<CMPriorityObject>)layer];
}

-(void)addLayerWithTextureFromPath:(NSString*)path withDepth:(float)depth{
    SWOGLLayer *layer = [[SWOGLLayer alloc]init];
    layer.depth = depth;
    [layer loadTextureAtPath:path];
    [self addLayer:layer];
}

-(id<SWOGLRenderable>)layerAtIndex:(NSInteger)index{
    if (self.layers.count > index) {
        return [self.layers objectAtIndex:index];
    }else{
        return nil;
    }
}


-(BOOL)containsPoint:(CGPoint)point{
    return CGRectContainsPoint(self.frame, point);
}

-(CGRect)frame{
    if (!self.childlayerQueue.count) {
        return CGRectZero;
    }else{
        CGRect res = CGRectZero;
        if (self.layerHierachyStored) {
            if (!self.layerHierachy.count) {
                return CGRectZero;
            }
            res = [[self.layerHierachy objectAtIndex:0]frame];
            for (int i = 1; i < self.layerHierachy.count; ++i) {
                res = CGRectUnion(res, [[self.layerHierachy objectAtIndex:i]frame]);
            }
        }else{
            res = [(id<SWOGLLocatable>)self.childlayerQueue.peekObject frame];
            for (id<SWOGLLocatable> locatable in self.childlayerQueue.allObjects){
                res = CGRectUnion(res, locatable.frame);
            }
        }
        return res;
    }
}

-(void)reactToEvent:(UIEvent *)event atPoint:(CGPoint)point{
    if(self.userInteractionEnabled){
        if (self.layerHierachyStored) {
            for (id<SWOGLLocatable> locatable in self.layerHierachy.reverseObjectEnumerator){
                if ([(id<SWOGLUserInteractable>)locatable reactsToEvent:event atPoint:point]) {
                    [(id<SWOGLUserInteractable>)locatable reactToEvent:event atPoint:point];
                    return;
                }
            }
        }else{
            for (id<SWOGLLocatable> locatable in self.childlayerQueue.allObjects.reverseObjectEnumerator){
                if ([(id<SWOGLUserInteractable>)locatable reactsToEvent:event atPoint:point]) {
                    [(id<SWOGLUserInteractable>)locatable reactToEvent:event atPoint:point];
                    return;
                }
            }
        }
    }
    [self startAnimation];
}

-(BOOL)reactsToEvent:(UIEvent *)event atPoint:(CGPoint)point{
    if (self.userInteractionEnabled) {
        return [self containsPoint:point];
    }else{
        return NO;
    }
}

-(float)value{
    return self.depth;
}

-(GLKVector2)positionOffset{
    if(!self.offsetProvider){
        return self.position;
    }else{
        return GLKVector2Add(self.offsetProvider.positionOffset, self.position);
    }
}

-(float)depthOffset{
    if(!self.offsetProvider){
        return self.depth;
    }else{
        return self.offsetProvider.depthOffset + self.depth;
    }
}

-(void)startAnimation{
    for (id<SWOGLLayerProtocol> layer in self.layers){
        [layer startAnimation];
    }
}

-(void)stopAnimation{
    for (id<SWOGLLayerProtocol> layer in self.layers){
        [layer stopAnimation];
    }
    
}

-(NSInteger)currentAnimationFrame{
    return SWOGLAnimatableInvalidFrame;
}

-(NSInteger)totalFrames{
    return 0;
}

-(void)addAnimation:(SWOGLLayerAnimation *)animation{
    if(animation){
        [self.animations addObject:animation];
        for (id<SWOGLLayerProtocol> layer in self.layers){
            [layer addAnimation:animation];
        }
    }
}

-(void)storeLayerHierarchy{
    [self.layerHierachy removeAllObjects];
    for (id<SWOGLLocatable> locatable in self.childlayerQueue.allObjects){
        [self.layerHierachy addObject:locatable];
        if ([locatable respondsToSelector:@selector(storeLayerHierarchy)]) {
            [locatable performSelector:@selector(storeLayerHierarchy)];
        }
    }
    self.layerHierachyStored = YES;
}

-(void)clearLayerHierarchy{
    for (id<SWOGLLocatable> locatable in self.childlayerQueue.allObjects){
        if ([locatable respondsToSelector:@selector(clearLayerHierarchy)]) {
            [locatable performSelector:@selector(clearLayerHierarchy)];
        }
    }
    [self.layerHierachy removeAllObjects];
    self.layerHierachyStored = NO;
}

@end
