//
//  FPPCAmount.m
//  GiftTracker
//
//  Created by Jaime Ohm on 10/2/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCAmount.h"
#import "FPPCGift.h"
#import "FPPCSource.h"


@implementation FPPCAmount

@dynamic value;
@dynamic gift;
@dynamic source;

#pragma mark - Object lifecycle
#pragma
- (void)awakeFromFetch {
    [super awakeFromFetch];
    [self addObservers];
}
- (void)awakeFromInsert {
    [super awakeFromInsert];
    [self addObservers];
}
- (void)addObservers {
    [self addObserver:self.source forKeyPath:@"gift.amount" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - Custom setters and getters
#pragma
- (void)setValue:(NSDecimalNumber *)value
{
    [self willChangeValueForKey:@"value"];
    [self setPrimitiveValue:value forKey:@"value"];
    [self didChangeValueForKey:@"value"];
    [self.source setTotal:nil];
}

@end
