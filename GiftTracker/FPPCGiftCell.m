//
//  FPPCGiftCell.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/6/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCGiftCell.h"

@implementation FPPCGiftCell
@synthesize name, sources, totalValue, date;

- (NSString *) reuseIdentifier {
    return @"FPPCGiftCell";
}

@end
