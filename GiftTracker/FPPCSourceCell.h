//
//  FPPCSourceCell.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/6/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FPPCSourceCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *name;
@property (nonatomic, strong) IBOutlet UILabel *business;
@property (nonatomic, strong) IBOutlet UILabel *remainingLimit;
@end
