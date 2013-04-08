/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/
#import "SWOGLStatefulLayerSet.h"
#import "SWOGLLayer.h"
@interface SWOGLStatefulLayerSet()
@property (nonatomic, strong) NSMutableDictionary *statefulLayers;
@end

@implementation SWOGLStatefulLayerSet

-(id)init{
    if ([super init]) {
        self.statefulLayers = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)reactToEvent:(UIEvent *)event atPoint:(CGPoint)point{
    
}

-(void)setState:(SWOGLStatefulLayerSetState)state{
    if (_state != state) {
        _state = state;
        [self updateChildLayerQueue];
    }
}

-(void)addLayerWithTextureFromPath:(NSString*)path withDepth:(float)depth forState:(SWOGLStatefulLayerSetState)state{
    SWOGLLayer *layer = [[SWOGLLayer alloc]init];
    [self.layers addObject:layer];
    layer.depth = depth;
    [layer loadTextureAtPath:path];
    NSMutableArray *array = [self layersForState:state];
    [array addObject:layer];
    layer.offsetProvider = self;
    [self updateChildLayerQueue];
}

-(void)updateChildLayerQueue{
    for (NSString *key in self.statefulLayers.allKeys){
        NSArray *layers = [self.statefulLayers objectForKey:key];
        if (key.integerValue == self.state) {
            for(id layer in layers){
                if (![self.childlayerQueue.allObjects containsObject:layer]) {
                    [self.childlayerQueue addObject:layer];
                }
            }
        }else{
            NSMutableArray *all = [NSMutableArray arrayWithArray:self.childlayerQueue.allObjects];
            [self.childlayerQueue removeAllObjects];
            for (id layer in layers){
                [all removeObject:layer];
            }
            for(id layer in all){
                [self.childlayerQueue addObject:layer];
            }
        }
    }
}

-(void)addLayerWithTextureFromPath:(NSString*)path withDepth:(float)depth{
    SWOGLLayer *layer = [[SWOGLLayer alloc]init];
    layer.depth = depth;
    [layer loadTextureAtPath:path];
    [self addLayer:layer];
}


-(NSMutableArray*)layersForState:(SWOGLStatefulLayerSetState)state{
    NSMutableArray * res = [self.statefulLayers objectForKey:[self keyForState:state]];
    if (!res) {
        res = [NSMutableArray array];
        [self.statefulLayers setObject:res forKey:[self keyForState:state]];
    }
    return res;
}

-(NSString*)keyForState:(SWOGLStatefulLayerSetState)state{
    return [NSString stringWithFormat:@"%d", state];
}

@end
