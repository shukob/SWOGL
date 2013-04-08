
#import <Foundation/Foundation.h>
#import "SWOGLAnimatable.h"

typedef enum _SWOGLLayerAnimationType{
    SWOGLLayerAnimationTypeNone,
    SWOGLLayerAnimationTypeConsecutiveImages,
    SWOGLLayerAnimationTypeRectMovement,
    SWOGLLayerAnimationTypeAlphaTransition,
}SWOGLLayerAnimationType;

@interface SWOGLLayerAnimation : NSObject  <SWOGLAnimatable>
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) BOOL repeatAnimation;
@property (nonatomic, assign) SWOGLLayerAnimationType animationType;

/*
 * The contents of this property varies based on animation type
 * animationType == consecutive images -> array of (path for image | image | texture)
 *               == rect movement -> array of NSValue representing rect or point
 *               == alpha transition -> array of NSNumber representing alpha
 */
@property (nonatomic, strong) NSMutableArray* frameProperties;
+(SWOGLLayerAnimation*)animationWithType:(SWOGLLayerAnimationType)animationType;
-(id)currentProperty;
-(id)currentInterpolatedProperty;
-(void)setAnimationTexturesUsingPathList:(NSArray*)pathList;
-(id)lastProperty;
@end
