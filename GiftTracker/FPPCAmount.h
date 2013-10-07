//
//  FPPCAmount.h
//  GiftTracker
//
//  Created by Jaime Ohm on 10/2/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FPPCGift, FPPCSource;

@interface FPPCAmount : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * value;
@property (nonatomic, retain) FPPCGift *gift;
@property (nonatomic, retain) FPPCSource *source;
- (void)addObservers;
@end
