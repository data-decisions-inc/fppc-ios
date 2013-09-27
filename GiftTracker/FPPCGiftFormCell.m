//
//  FPPCGiftFormCell.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/11/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCGiftFormCell.h"

@implementation FPPCGiftFormCell
@synthesize name,amount;

- (NSString *) reuseIdentifier {
    return @"FPPCGiftFormCell";
}

@end
