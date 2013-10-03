//
//  FPPCSourceSearchViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/4/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSearchViewController.h"
#import "FPPCSourceCell.h"
#import "FPPCSource.h"

@protocol FPPCSourceSearchViewControllerDelegate
@optional
- (void)didAddSource:(FPPCSource *)source;
@end

@interface FPPCSourceSearchViewController : FPPCSearchViewController
@property (assign, nonatomic) IBOutlet FPPCSourceCell *sourceCell;
- (NSDecimalNumber *)giftLimitWithSource:(FPPCSource *)source forDate:(NSDate *)date;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDateComponents *dateComponents;

@property (nonatomic, strong) FPPCViewController<FPPCSourceSearchViewControllerDelegate> *delegate;

enum kGiftLimit {
    LOBBYING_LIMIT = 10,
    NON_LOBBYING_LIMIT = 440
};
@end
