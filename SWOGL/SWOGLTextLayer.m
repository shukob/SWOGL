/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import "SWOGLTextLayer.h"

NSInteger SWOGLTextLayerInvalidIndex = -1;
float SWOGLTextLayerDepthOffsetForLine= 1e-9;
typedef struct _SWOGLTextLayerTextStatus{
    NSInteger line;
    NSInteger offset;
}SWOGLTextLayerTextStatus;

@interface SWOGLTextLayer()
@property (nonatomic, strong) NSArray *lines;
@end
@implementation SWOGLTextLayer

-(id)init{
    if ([super init]) {
        self.userInteractionEnabled = NO;
        [self clearDisplayingProperty];
    }
    return self;
}

-(BOOL)loadTexture{
    if (!self.texture) {
        self.texture = [SWOGLTexture textureWithText:self.text size:self.contentSize font:self.font color:self.textColor options:self.options];
    }
    if (self.texture) {
      
        return YES;
    }else{
        return NO;
    }
}

-(BOOL)customTextDisplayingPropertySpecified{
    return self.textStartingIndexForDisplay != SWOGLTextLayerInvalidIndex && self.textLengthForDisplay != SWOGLTextLayerInvalidIndex;;
}

-(void)render{
    if (!self.animating && ![self customTextDisplayingPropertySpecified]) {
        [super render];
    }else{

        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        
        NSInteger animationFrame = [self currentAnimationFrame];
        if (animationFrame == SWOGLAnimatableInvalidFrame) {
            [self stopAnimation];
        }
        if (self.animating || [self customTextDisplayingPropertySpecified]) {
            SWOGLTextLayerTextStatus status = [self textStatusAtAnimationFrame:animationFrame];
            for (NSInteger line = 0; line <= status.line; ++line) {
                SWOGLTexture *texture = [self textureForLine:line];
                self.effect.texture2d0.name = texture.textureInfo.name;
                self.effect.texture2d0.enabled = YES;
                self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
                self.effect.texture2d0.target = GLKTextureTarget2D;
                self.effect.transform.modelviewMatrix = [self modelMatrixForLine:line];
                [self.effect prepareToDraw];
                TexturedQuad quad;
                NSInteger length = line == status.line ? status.offset : [[self.lines objectAtIndex:line]length];
                quad= [texture quadForRect:[self lineRectForLine:line fromIndex:0 withLength:length]];
                
                long offset = (long)&quad;
                glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (void *) (offset + offsetof(TexturedVertex, geometryVertex)));
                glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (void *) (offset + offsetof(TexturedVertex, textureVertex)));
                
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                
            }
            
        }else{
            SWOGLTexture *texture = self.texture;
            self.effect.texture2d0.name = texture.textureInfo.name;
            self.effect.texture2d0.enabled = YES;
            self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
            self.effect.texture2d0.target = GLKTextureTarget2D;
            TexturedQuad quad;
            quad= texture.quad;
            
            long offset = (long)&quad;
            glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (void *) (offset + offsetof(TexturedVertex, geometryVertex)));
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedVertex), (void *) (offset + offsetof(TexturedVertex, textureVertex)));
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        }
        glDisableVertexAttribArray(GLKVertexAttribPosition);
        glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    }
}

-(GLKMatrix4)modelMatrixForLine:(NSInteger)line{
    GLKMatrix4 mat = [super modelMatrix];
    mat = GLKMatrix4Translate(mat, 0, 0, -SWOGLTextLayerDepthOffsetForLine*line);
    return mat;
}

-(SWOGLTextLayerTextStatus)textStatusAtAnimationFrame:(NSInteger)animationFrame{
    NSInteger currentFrame = animationFrame;
    if ([self customTextDisplayingPropertySpecified]) {
        currentFrame = self.textStartingIndexForDisplay + self.textLengthForDisplay -1;
    }
    NSInteger lastLine = 0;
    for (; lastLine < self.lines.count; ++lastLine) {
        NSInteger thisLength =[[self.lines objectAtIndex:lastLine]length];
        currentFrame -=thisLength;
        if (currentFrame <= 0) {
            currentFrame += thisLength;
            break;
        }
    }
    
    SWOGLTextLayerTextStatus status;
    status.line = lastLine;
    status.offset = currentFrame;
    return status;
}

-(NSInteger)totalFrames{
    return self.text.length - self.lines.count + 1; //Subtracting newline characters count
}

-(CGRect)lineRectForLine:(NSInteger)line fromIndex:(NSInteger)from withLength:(NSInteger)length{
    CGSize size = [[[self.lines objectAtIndex:line] substringWithRange:NSMakeRange(from, length)]sizeWithFont:self.font];
    CGSize offsetSize = [[[self.lines objectAtIndex:line] substringWithRange:NSMakeRange(0, from)]sizeWithFont:self.font];
    
    CGPoint offset = CGPointMake(offsetSize.width, self.lineHeight*line);
    CGRect rect;
    rect.origin = offset;
    rect.size = size;
    return rect;
}

-(void)setFont:(UIFont *)font{
    if (_font != font) {
        _font = font;
        self.lineHeight = [@"A" sizeWithFont:self.font].height;
        [self unloadTexture];
    }
}

-(void)setText:(NSString *)text{
    if (text != _text && ![text isEqualToString:_text]) {
        _text = text;
        self.lines =[text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
        _numberOfLines = self.lines.count;
        [self unloadTexture];
    }
}

-(void)reactToEvent:(UIEvent *)event atPoint:(CGPoint)point{
    if (self.animating) {
        [self stopAnimation];
    }else{
        [self startAnimation];
    }
}

-(void)setTextColor:(GLKVector4)textColor{
    if (!GLKVector4AllEqualToVector4(_textColor, textColor)) {
        _textColor = textColor;
        [self unloadTexture];
    }
}

-(void)setContentSize:(CGSize)contentSize{
    if (!CGSizeEqualToSize(contentSize, _contentSize)) {
        _contentSize = contentSize;
        [self unloadTexture];
    }
}

-(void)clearDisplayingProperty{
    self.textLengthForDisplay = SWOGLTextLayerInvalidIndex;
    self.textStartingIndexForDisplay = SWOGLTextLayerInvalidIndex;
}

-(NSInteger)overallRequiredTextIndexForDisplay{
    return _textLengthForDisplay + _textStartingIndexForDisplay;
}

-(SWOGLTexture*)textureForLine:(NSInteger)line{
    return self.texture;
}


@end
