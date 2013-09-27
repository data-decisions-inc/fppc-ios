//
//  FPPCActionSheet.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/10/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 * This custom class adds a variable to ActionSheets that are displayed from a Table View cell, so that we know which cell is making the call
 */

@interface FPPCActionSheet : UIActionSheet
@property (nonatomic, strong) NSIndexPath *indexPath;
@end
