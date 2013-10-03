//
//  FPPCGift.h
//  GiftTracker
//
//  Created by Jaime Ohm on 10/2/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FPPCAmount;

@interface FPPCGift : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *amount;
@end

@interface FPPCGift (CoreDataGeneratedAccessors)

- (void)addAmountObject:(FPPCAmount *)value;
- (void)removeAmountObject:(FPPCAmount *)value;
- (void)addAmount:(NSSet *)values;
- (void)removeAmount:(NSSet *)values;

@end
