/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import "SWOGLViewController.h"
#import "CMApplicationDirectory.h"
#import "SWOGLLayer.h"
#import "SWOGLLayerSet.h"
#import "SWOGLDisplay.h"
#import "SWOGLReactable.h"
#import "SWOGLOrientationAwareLayer.h"
#import "SWOGLStatefulLayerSet.h"
#import "SWOGLTextLayer.h"
#import "SWOGLUtility.h"
#import "SWOGLLayerAnimation.h"
#import "SWOGLLayerProtocol.h"
#import "SWOGLTextureInfoReleaser.h"
#import "CMDevice.h"
#define BUFFER_OFFSET(i) ((char *)NULL + (i))
typedef enum _SWOGLViewControllerSnapshotMode{
    SWOGLViewControllerSnapshotModeNone,
    SWOGLViewControllerSnapshotModeAboveThreashold,
    SWOGLViewControllerSnapshotModeBelowThreashold,
    SWOGLViewControllerSnapshotModeAll,
    SWOGLViewControllerSnapshotModeBitweenThreasholds,
}SWOGLViewControllerSnapshotMode;

@interface SWOGLViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    NSDate* _startDate;
    
}

@property (nonatomic, assign) SWOGLViewControllerSnapshotMode snapshotMode;
@property (nonatomic, assign) float snapshotThreasholdDepth;
@property (nonatomic, assign) float snapshotThreasholdDepthLimit;
@property (nonatomic, assign) BOOL requestedFinishRendering;
@property (nonatomic, assign) BOOL glFinished;
- (void)setupGL;
- (void)tearDownGL;


@end

@implementation SWOGLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    self.renderingMode = SWOGLViewControllerRenderingModeAll;
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    _startDate = [NSDate date];
    [self setupGL];
    view.backgroundColor = [UIColor blackColor];
    
    self.preferredFramesPerSecond = [CMDevice bestFPS];
    
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = [[GLKBaseEffect alloc] init];
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glEnable(GL_ALPHA_TEST);
    
    glAlphaFunc(GL_GREATER,0.1);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

-(void)setMatrices{
    GLKMatrix4 projectionMatrix =GLKMatrix4MakeOrtho(0, [(SWOGLDisplay*)[SWOGLDisplay instance]size].width, 0, [(SWOGLDisplay*)[SWOGLDisplay instance]size].height, -self.depthRange , self.depthRange);
    self.effect.transform.projectionMatrix = projectionMatrix;
}
#pragma mark - GLKView and GLKViewController delegate methods

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    UIInterfaceOrientation currentOrientation = self.interfaceOrientation;
    if (UIInterfaceOrientationIsPortrait(currentOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            [[SWOGLDisplay instance]setSize:CGSizeMake([CMDevice widerScreenLength], 320)];
    }else if(UIInterfaceOrientationIsLandscape(currentOrientation)&& UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        [[SWOGLDisplay instance]setSize:CGSizeMake(320, [CMDevice widerScreenLength])];
    }else if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && UIInterfaceOrientationIsLandscape(currentOrientation)){
        [[SWOGLDisplay instance]setSize:CGSizeMake([CMDevice widerScreenLength], 320)];
    }else if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation) && UIInterfaceOrientationIsPortrait(currentOrientation)){
        [[SWOGLDisplay instance]setSize:CGSizeMake(320, [CMDevice widerScreenLength])];
    }
    UIInterfaceOrientation orientation = toInterfaceOrientation;
    
    [[SWOGLDisplay instance]setInterfaceOrientation:orientation];
    [self setMatrices];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{

}

- (void)update
{
    [self setMatrices];
}
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{

    if (self.requestedFinishRendering) {
        glFinish();
        self.glFinished = YES;
        return;
    }
    self.glFinished = NO;
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    for(id<SWOGLLayerProtocol> renderable in [self.layers allObjects]){
        if (self.snapshotMode == SWOGLViewControllerSnapshotModeAboveThreashold) {
            if ([(id<SWOGLLayerProtocol>)renderable value] < self.snapshotThreasholdDepth) {
                continue;
            }
        }else if(self.snapshotMode == SWOGLViewControllerSnapshotModeBelowThreashold) {
            if ([(id<SWOGLLayerProtocol>)renderable value] > self.snapshotThreasholdDepth) {
                continue;
            }
        }else if(self.snapshotMode == SWOGLViewControllerSnapshotModeBitweenThreasholds){
            if ([(id<SWOGLLayerProtocol>)renderable value] < self.snapshotThreasholdDepth) {
                continue;
            }else if ([(id<SWOGLLayerProtocol>)renderable value] > self.snapshotThreasholdDepthLimit) {
                continue;
            }
        }else if(self.renderingMode == SWOGLViewControllerSnapshotModeAboveThreashold){
            if ([(id<SWOGLLayerProtocol>)renderable value] < self.threasholdDepth) {
                continue;
            }
        }else if(self.renderingMode == SWOGLViewControllerRenderingModeBelowThreashold){
            if ([(id<SWOGLLayerProtocol>)renderable value] > self.threasholdDepth) {
                continue;
            }
        }
        if(![renderable hidden]){
            [renderable renderWithProjectionMatrix:self.effect.transform.projectionMatrix];
        }
    }
    [[SWOGLTextureInfoReleaser instance]releaseTextureInfo];
}


-(UIImage*)snapshotBelowDepth:(float)depth{
    self.snapshotThreasholdDepth = depth;
    self.snapshotMode = SWOGLViewControllerSnapshotModeBelowThreashold;
    UIImage *res = ((GLKView*)self.view).snapshot;
    self.snapshotMode = SWOGLViewControllerSnapshotModeNone;
    return res;
}

-(UIImage*)snapshotAboveDepth:(float)depth{
    self.snapshotThreasholdDepth = depth;
    self.snapshotMode = SWOGLViewControllerSnapshotModeAboveThreashold;
    UIImage *res = ((GLKView*)self.view).snapshot;
    self.snapshotMode = SWOGLViewControllerSnapshotModeNone;
    return res;
}

-(UIImage*)snapshotFromDepth:(float)fromDepth toDepth:(float)toDepth{
    self.snapshotThreasholdDepth = fromDepth;
    self.snapshotThreasholdDepthLimit = toDepth;
    self.snapshotMode = SWOGLViewControllerSnapshotModeBitweenThreasholds;
    UIImage *res = ((GLKView*)self.view).snapshot;
    self.snapshotMode = SWOGLViewControllerSnapshotModeNone;
    return res;
}

-(float)depthRange{
    return 100;
}

-(void)finishRendering{
    if (self.paused) {
        return;
    }
    self.requestedFinishRendering = YES;
    [EAGLContext setCurrentContext:self.context];
    glFinish();

}

-(void)startRendering{
    self.requestedFinishRendering = NO;
}

@end
