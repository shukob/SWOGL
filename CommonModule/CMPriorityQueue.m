/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

//Codes are taken from https://gist.github.com/nrub/1406810 with modification
//skonb(Shunpei Kobayashi), 2013

#import "CMPriorityQueue.h"

@implementation CMPriorityQueue
static const void *CMPriorityObjectRetain(CFAllocatorRef allocator, const void *ptr) {
    return CFBridgingRetain((__bridge id)(ptr));
}

static void CMPriorityObjectRelease(CFAllocatorRef allocator, const void *ptr) {
    CFBridgingRelease(ptr);
}

static CFStringRef CMPriorityObjectCopyDescription(const void* ptr) {
    NSObject *event = (__bridge NSObject *) ptr;
    CFStringRef desc = (__bridge CFStringRef) [event description];
    return desc;
}

static CFComparisonResult CMPriorityObjectCompare(const void* ptr1, const void* ptr2, void* context) {
    id<CMPriorityObject> item1 = (__bridge id<CMPriorityObject>  ) ptr1;
    id<CMPriorityObject> item2 = (__bridge id<CMPriorityObject>  ) ptr2;
    
    // In this example, we're sorting by distance property of the object
    // Objects with smallest distance will be first in the queue
    if ([item1 value] < [item2 value]) {
        return kCFCompareLessThan;
    } else if ([item1 value] == [item2 value]) {
        return kCFCompareEqualTo;
    } else {
        return kCFCompareGreaterThan;
    }
}

#pragma mark -
#pragma mark NSObject methods

- (id)init {
    if ((self = [super init])) {
        
        CFBinaryHeapCallBacks callbacks;
        callbacks.version = 0;
        
        // Callbacks to the functions above
        callbacks.retain = CMPriorityObjectRetain;
        callbacks.release = CMPriorityObjectRelease;
        callbacks.copyDescription = CMPriorityObjectCopyDescription;
        callbacks.compare = CMPriorityObjectCompare;
        
        // Create the priority queue
        _heap = CFBinaryHeapCreate(kCFAllocatorDefault, 0, &callbacks, NULL);
    }
    
    return self;
}

- (void)dealloc {
    if (_heap) {
        CFRelease(_heap);
    }
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"PriorityQueue = {%@}",
            (_heap ? [[self allObjects] description] : @"null")];
}

#pragma mark -
#pragma mark Queue methods

- (NSUInteger)count {
    return CFBinaryHeapGetCount(_heap);
}

- (NSArray *)allObjects {
    const void **arrayC = calloc(CFBinaryHeapGetCount(_heap), sizeof(void *));
    CFBinaryHeapGetValues(_heap, arrayC);
    NSArray *array = [NSArray arrayWithObjects:(__unsafe_unretained id *)(void *)arrayC
                                         count:CFBinaryHeapGetCount(_heap)];
    free(arrayC);
    return array;
}

- (void)addObject:(id<CMPriorityObject>)object {
    CFBinaryHeapAddValue(_heap, (__bridge const void *)(object));
}

- (void)removeAllObjects {
    CFBinaryHeapRemoveAllValues(_heap);
}

- (id<CMPriorityObject>)nextObject {
    id<CMPriorityObject> obj = [self peekObject];
    CFBinaryHeapRemoveMinimumValue(_heap);
    return obj;
}

- (id<CMPriorityObject>)peekObject {
    return (__bridge id<CMPriorityObject>)CFBinaryHeapGetMinimum(_heap);
}

@end