//
//  FPPCAmount.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/12/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FPPCGift, FPPCSource;

@interface FPPCAmount : NSManagedObject

@property (nonatomic, retain) NSNumber * value;
@property (nonatomic, retain) NSSet *gift;
@property (nonatomic, retain) NSSet *source;
@end

@interface FPPCAmount (CoreDataGeneratedAccessors)

- (void)addGiftObject:(FPPCGift *)value;
- (void)removeGiftObject:(FPPCGift *)value;
- (void)addGift:(NSSet *)values;
- (void)removeGift:(NSSet *)values;

- (void)addSourceObject:(FPPCSource *)value;
- (void)removeSourceObject:(FPPCSource *)value;
- (void)addSource:(NSSet *)values;
- (void)removeSource:(NSSet *)values;

@end
