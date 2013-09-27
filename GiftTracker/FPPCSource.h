//
//  FPPCSource.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/12/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FPPCAmount;

@interface FPPCSource : NSManagedObject

@property (nonatomic, retain) NSString * business;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * isLobbying;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * street2;
@property (nonatomic, retain) NSString * zipcode;
@property (nonatomic, retain) NSSet *amount;
@end

@interface FPPCSource (CoreDataGeneratedAccessors)

- (void)addAmountObject:(FPPCAmount *)value;
- (void)removeAmountObject:(FPPCAmount *)value;
- (void)addAmount:(NSSet *)values;
- (void)removeAmount:(NSSet *)values;

@end
