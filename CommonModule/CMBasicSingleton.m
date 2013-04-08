/*The MIT License
 
Copyright (c) 2013 skonb(Shunpei Kobayashi)
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE*/

#import "CMBasicSingleton.h"
NSMutableDictionary *objectDictionary;
NSMutableDictionary *lockDictionary;
@implementation CMBasicSingleton
+(void)lock{
	@synchronized(self){
		[[lockDictionary objectForKey:NSStringFromClass(self)] lock];
	}
}
+(void)unlock{
	@synchronized(self){
		[[lockDictionary objectForKey:NSStringFromClass(self)] unlock];
	}
}
+(id)instance{
    @autoreleasepool {
    NSString *key = NSStringFromClass(self);
	@synchronized(self){
        @synchronized(objectDictionary){
            if (!objectDictionary) {
                objectDictionary = [NSMutableDictionary new];
            }
            if (![objectDictionary objectForKey:key]) {
                id this = [[self alloc]init];
                //DLog(@"Required allocating: %@", key);
                [objectDictionary setValue:this forKey:key];
//                CM_RELEASE(this );
            }
            
        }
        @synchronized(lockDictionary){
            if (!lockDictionary) {
                lockDictionary = [NSMutableDictionary new];
            }
            if (![lockDictionary objectForKey:key]){
                NSRecursiveLock *lock = [[NSRecursiveLock alloc]init];
                [lockDictionary setValue:lock forKey:key];
//                CM_RELEASE(lock );
            }
        }
	}
    id res = [objectDictionary objectForKey:key];
    [res instanceCallback];
	return res;
    }
}

+(id)reInitialize{
    if ([objectDictionary objectForKey:NSStringFromClass(self)]) {
        [objectDictionary removeObjectForKey:NSStringFromClass(self)];
    }
    if ([lockDictionary objectForKey:NSStringFromClass(self)]){
        [lockDictionary removeObjectForKey:NSStringFromClass(self)];
    }
    return [self instance];
}

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if ([objectDictionary objectForKey:NSStringFromClass(self)] == nil) {
			id instance = [super allocWithZone:zone];
			if ([objectDictionary count] == 0) {
				objectDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
			}
			[objectDictionary setObject:instance forKey:NSStringFromClass(self)];
			return instance;
		}
	}
	return nil;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}
#if CM_SHOULD_DEALLOC
- (id)retain {
	return self;
}
#endif

- (unsigned)returnCount {
	return UINT_MAX;
}

#if CM_SHOULD_DEALLOC
- (oneway void)release {
  
}
#endif

#if CM_SHOULD_DEALLOC
- (id)autorelease {
	return self;
}
#endif

-(void)dealloc{
	#if CM_SHOULD_DEALLOC
[super dealloc];
    #endif
}

-(void)instanceCallback{
    
}
@end
