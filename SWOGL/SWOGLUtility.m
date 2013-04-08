/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import "SWOGLUtility.h"
#import "SWOGLDisplay.h"
@implementation SWOGLUtility
+(void)setRect:(CGRect)rect toVertices:(float*)vertices{
    vertices[0] = CGRectGetMinX(rect);
    vertices[1] = CGRectGetMinY(rect);
    vertices[2] = vertices[0];
    vertices[3] = CGRectGetMaxY(rect);
    vertices[4] = CGRectGetMaxX(rect);
    vertices[5] = vertices[3];
    vertices[6] = vertices[4];
    vertices[7] = vertices[1];
    [self convertToOGLCoordinate:vertices count:4];
}


+(void)convertToOGLCoordinate:(float*)vertices count:(NSInteger)count{
    for (int i = 0; i < count; ++i) {
        vertices[i*2+1] = [[SWOGLDisplay instance]size].height - vertices[i*2+1];
    }
}

@end
