//
//  FPPCSourceCell.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/6/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSourceCell.h"

@implementation FPPCSourceCell
@synthesize name, business, remainingLimit;

- (NSString *) reuseIdentifier {
    return @"FPPCSourceCell";
}

@end
