//Codes are taken from https://gist.github.com/nrub/1406810 with modification
//skonb(Shunpei Kobayashi), 2013
#import <Foundation/Foundation.h>
@protocol CMPriorityObject;
@interface CMPriorityQueue : NSObject {
@private
    // Heap itself
    CFBinaryHeapRef _heap;
}

// Returns number of items in the queue
- (NSUInteger)count;

// Returns all (sorted) objects in the queue
- (NSArray *)allObjects;

// Adds an object to the queue
- (void)addObject:(id<CMPriorityObject>)object;

// Removes all objects from the queue
- (void)removeAllObjects;

// Removes the "top-most" (as determined by the callback sort function) object from the queue
// and returns it
- (id<CMPriorityObject>)nextObject;

// Returns the "top-most" (as determined by the callback sort function) object from the queue
// without removing it from the queue
- (id<CMPriorityObject>)peekObject;

@end

@protocol CMPriorityObject <NSObject>

@property (nonatomic, assign) float value;

@end