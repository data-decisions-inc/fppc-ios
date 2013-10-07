//
//  FPPCSource.m
//  GiftTracker
//
//  Created by Jaime Ohm on 10/7/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSource.h"
#import "FPPCAmount.h"
#import "FPPCGift.h"
#import "FPPCAppDelegate.h"

@interface FPPCSource ()
enum kLobbyLimit {
    FPPCSOURCE_LOBBYING_LIMIT = 10,
    FPPCSOURCE_NON_LOBBYING_LIMIT = 440
};
@end

static NSDate *FPPCDate;

@implementation FPPCSource

@dynamic business;
@dynamic city;
@dynamic email;
@dynamic isLobbying;
@dynamic name;
@dynamic phone;
@dynamic state;
@dynamic street;
@dynamic street2;
@dynamic zipcode;
@dynamic total;
@dynamic limit;
@dynamic amount;

#pragma mark - KVO
#pragma 
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"gift.amount"]) {
        if ([[change valueForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting) {
            FPPCAmount *newAmount = (FPPCAmount *)object;
            [newAmount.source willChangeValueForKey:@"total"];
            [newAmount.source setTotal:nil];
            [newAmount.source didChangeValueForKey:@"total"];
        }
    }
}

#pragma mark - Custom setters and getters
#pragma
+ (NSDate *)date {
    if (!FPPCDate) FPPCDate = [[NSCalendar currentCalendar] date];
    return FPPCDate;
}
+ (void)setDate:(NSDate *)date {
    FPPCDate = date;
}

- (void)setTotal:(NSDecimalNumber *)total
{
    if (total) {
        [self willChangeValueForKey:@"total"];
        [self setPrimitiveValue:total forKey:@"total"];
        [self didChangeValueForKey:@"total"];
        [self setLimit:nil];
    } else {
        [self willChangeValueForKey:@"total"];
        [self willAccessValueForKey:@"amount"];
        NSSet *amounts = [self valueForKey:@"amount"];
        
        NSDate *date = [FPPCSource date];
        NSInteger dateFlags;
        [self willAccessValueForKey:@"isLobbying"];
        BOOL isLobbying = [[self valueForKey:@"isLobbying"] boolValue];
        [self didAccessValueForKey:@"isLobbying"];
        if (isLobbying) dateFlags = NSMonthCalendarUnit | NSYearCalendarUnit;
        else dateFlags = NSYearCalendarUnit;
        
        NSDecimalNumber *sum = [NSDecimalNumber zero];
        NSDecimalNumber *value = [NSDecimalNumber zero];
        FPPCGift *gift;
        NSDate *giftDate;
        NSDateComponents *giftDateComponents;
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components: dateFlags fromDate:date];
        for (FPPCAmount *a in amounts) {
            [a willAccessValueForKey:@"gift"];
            gift = a.gift;
            [gift willAccessValueForKey:@"date"];
            giftDate = gift.date;
            [gift didAccessValueForKey:@"date"];
            [a didAccessValueForKey:@"gift"];
            
            giftDateComponents = [[NSCalendar currentCalendar] components:dateFlags fromDate:giftDate];
            if ([giftDateComponents isEqual:dateComponents]) {
                [a willAccessValueForKey:@"value"];
                value = [a valueForKey:@"value"];
                [a didAccessValueForKey:@"value"];
                sum = [sum decimalNumberByAdding:value];
            }
        }
        [self didAccessValueForKey:@"amount"];
        
        [self setPrimitiveValue:sum forKey:@"total"];
        [self setLimit:nil];
        [self didChangeValueForKey:@"total"];
    }
}

- (void)setLimit:(NSDecimalNumber *)limit
{
    if (limit) {
        [self willChangeValueForKey:@"limit"];
        [self setPrimitiveValue:limit forKey:@"limit"];
        [self didChangeValueForKey:@"limit"];
    } else {
        [self willChangeValueForKey:@"limit"];
        [self willAccessValueForKey:@"isLobbying"];
        NSInteger max;
        if ([[self valueForKey:@"isLobbying"] boolValue])
            max = FPPCSOURCE_LOBBYING_LIMIT;
        else
            max = FPPCSOURCE_NON_LOBBYING_LIMIT;
        [self didAccessValueForKey:@"isLobbying"];
        
        [self willAccessValueForKey:@"total"];
        NSDecimalNumber *total = [self valueForKey:@"total"];
        [self didAccessValueForKey:@"total"];
        
        NSDecimalNumber *limit = [NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInteger:max] decimalValue]];
        limit = [limit decimalNumberBySubtracting:total];
        
        [self setPrimitiveValue:limit forKey:@"limit"];
        [self didChangeValueForKey:@"limit"];
    }
}

- (void)setIsLobbying:(NSNumber *)isLobbying
{
    [self willChangeValueForKey:@"isLobbying"];
    [self setPrimitiveValue:isLobbying forKey:@"isLobbying"];
    [self setLimit:nil];
    [self didChangeValueForKey:@"isLobbying"];
}

@end
