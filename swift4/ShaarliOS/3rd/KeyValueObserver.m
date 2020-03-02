//  https://github.com/objcio/issue-7-lab-color-space-explorer/blob/9551c8b6f67dd46eca91d93c0437d10ff9ee4eed/Lab%20Color%20Space%20Explorer/KeyValueObserver.m
//  KeyValueObserver.m
//  Lab Color Space Explorer
//
//  Created by Daniel Eggert on 01/12/2013.
//  Copyright (c) 2013 objc.io. All rights reserved.
//

#import "KeyValueObserver.h"

//
// Created by chris on 7/24/13.
//

#import "KeyValueObserver.h"

@interface KeyValueObserver ()
@property (nonatomic, weak) id observedObject;
@property (nonatomic, copy) NSString* keyPath;
@end

@implementation KeyValueObserver

- (id)initWithObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector options:(NSKeyValueObservingOptions)options;
{
    if (object == nil) {
        return nil;
    }
    NSParameterAssert(target != nil);
    NSParameterAssert([target respondsToSelector:selector]);
    self = [super init];
    if (self) {
        self.target = target;
        self.selector = selector;
        self.observedObject = object;
        self.keyPath = keyPath;
        [object addObserver:self forKeyPath:keyPath options:options context:(__bridge void *)(self)];
    }
    return self;
}

+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector __attribute__((warn_unused_result));
{
    return [self observeObject:object keyPath:keyPath target:target selector:selector options:0];
}

+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector options:(NSKeyValueObservingOptions)options __attribute__((warn_unused_result));
{
    return [[self alloc] initWithObject:object keyPath:keyPath target:target selector:selector options:options];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context == (__bridge void *)(self)) {
        [self didChange:change];
    }
}

- (void)didChange:(NSDictionary *)change;
{
    id strongTarget = self.target;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [strongTarget performSelector:self.selector withObject:change];
#pragma clang diagnostic pop
}

- (void)dealloc;
{
    [self.observedObject removeObserver:self forKeyPath:self.keyPath];
}

@end