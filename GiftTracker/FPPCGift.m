//
//  FPPCGift.m
//  GiftTracker
//
//  Created by Jaime Ohm on 10/2/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCGift.h"
#import "FPPCAmount.h"
#import "FPPCSource.h"

@implementation FPPCGift

@dynamic date;
@dynamic name;
@dynamic amount;

#pragma mark - Custom setters and getters
#pragma
- (void)setDate:(NSDate *)date
{
    [self willChangeValueForKey:@"date"];
    [self setPrimitiveValue:date forKey:@"date"];
    [self didChangeValueForKey:@"date"];
    
    [self willAccessValueForKey:@"amount"];
    NSSet *amounts = self.amount;
    [self didAccessValueForKey:@"amount"];
    
    for (FPPCAmount *amount in amounts) {
        [amount willAccessValueForKey:@"source"];
        [amount.source willChangeValueForKey:@"total"];
        [amount.source setTotal:nil];
        [amount.source didChangeValueForKey:@"total"];
        [amount.source didAccessValueForKey:@"source"];
    }
}

@end
